// Compile with ColorModel.swift, ColorCatalog.swift, ModelTool.swift,
// FavoritesStore.swift and AppRoute.swift from JColors/Models.
// No package resolution, app build or simulator is required.
// Run the executable with the repository root as its first argument.
import Combine
import Foundation

@main
struct VerifyModels {
  @MainActor
  static func main() throws {
    let files = FileManager.default
    let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? files.currentDirectoryPath)
    let fixture = files.temporaryDirectory.appendingPathComponent("JColors-\(UUID().uuidString).bundle")
    try files.createDirectory(at: fixture, withIntermediateDirectories: true)
    defer { try? files.removeItem(at: fixture) }
    let info = ["CFBundleIdentifier": "test.jcolors.catalog", "CFBundleName": "Catalog"]
    try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
      .write(to: fixture.appendingPathComponent("Info.plist"))
    for folder in ["byMonth", "byColor"] {
      for file in try files.contentsOfDirectory(at: root.appendingPathComponent("scripts/\(folder)"), includingPropertiesForKeys: nil)
        where file.pathExtension == "json" {
        try files.copyItem(at: file, to: fixture.appendingPathComponent(file.lastPathComponent))
      }
    }
    guard let bundle = Bundle(url: fixture) else { fatalError("Fixture bundle unavailable") }
    let catalog = ColorCatalog(bundle: bundle)
    let store = ModelTool(bundle: bundle, catalog: catalog)
    let allColors = store.allColors
    let ids = Set(allColors.map(\.id))
    precondition(allColors.count == 365 && ids.count == 365)
    let expectedOrder = store.allMonths.flatMap { month in
      (1...store.daysInMonths[month]).map { "\(month)_\($0)" }
    }
    precondition(allColors.map(\.id) == expectedOrder)

    // Every stored selection restores exactly, in both navigation orders.
    for color in allColors {
      precondition(store.color(id: color.id)?.id == color.id)
      guard let series = store.colorCategory(for: color) else { fatalError("Missing category") }
      for (category, chronological) in [(color.month, true), (series, false)] {
        for forward in [true, false] {
          guard let next = store.adjacentColor(to: color.id, in: category, forward: forward) else {
            fatalError("Missing neighbor")
          }
          let nextCategory = chronological ? next.month : store.colorCategory(for: next)!
          precondition(store.adjacentColor(to: next.id, in: nextCategory, forward: !forward)?.id == color.id)
        }
      }
    }
    precondition(store.adjacentColor(to: "12_31", in: "12", forward: true)?.id == "1_1")
    precondition(store.adjacentColor(to: "1_1", in: "1", forward: false)?.id == "12_31")
    precondition(store.adjacentColor(to: "2_28", in: "2", forward: true)?.id == "3_1")
    precondition(store.adjacentColor(to: "", in: "1", forward: true)?.id == "1_1")
    precondition(store.adjacentColor(to: "stale", in: "1", forward: false)?.id == "1_31")
    precondition(store.adjacentColor(to: "1_1", in: "missing", forward: true) == nil)
    for invalid in ["", "1", "1_", "_1", "1__1", "13_1", "2_29", "1_32", "01_1"] {
      precondition(store.color(id: invalid) == nil)
    }

    // Deep links resolve the exact rendered ID; unsupported URLs cannot produce a route.
    for color in allColors {
      let url = URL(string: "jcolors://color/\(color.id)")!
      precondition(AppRoute(url: url, catalog: catalog) == .color(color.id))
    }
    precondition(AppRoute(url: URL(string: "JCOLORS://COLOR/12_31")!, catalog: catalog) == .color("12_31"))
    for urlString in ["jcolors://premium", "jcolors://premium/", "JCOLORS://PREMIUM"] {
      precondition(AppRoute(url: URL(string: urlString)!, catalog: catalog) == .premium)
    }
    for urlString in [
      "https://color/1_1", "jcolors://unknown", "jcolors:color/1_1",
      "jcolors://color", "jcolors://color/", "jcolors://color/1", "jcolors://color/1__1",
      "jcolors://color/01_1", "jcolors://color/13_1", "jcolors://color/2_29", "jcolors://color/1_32",
      "jcolors://color/1_1/extra", "jcolors://color/1_1?x=1", "jcolors://color/1_1#frag",
      "jcolors://user@color/1_1", "jcolors://user:password@color/1_1", "jcolors://color:42/1_1",
      "jcolors://premium/extra", "jcolors://premium?", "jcolors://premium#frag",
    ] {
      precondition(AppRoute(url: URL(string: urlString)!, catalog: catalog) == nil,
                   "Unsupported deep link accepted: \(urlString)")
    }

    // The random selector maps all 365 integer slots, including the last day.
    precondition(Set((1...365).compactMap { store.color(dayOfYear: $0)?.id }) == ids)
    precondition(store.color(dayOfYear: 365)?.id == "12_31")
    precondition(store.color(dayOfYear: 0) == nil && store.color(dayOfYear: 366) == nil)
    let calendar = Calendar(identifier: .gregorian)
    for components in [DateComponents(year: 2024, month: 2, day: 29, hour: 12),
                       DateComponents(year: 2023, month: 12, day: 31, hour: 12)] {
      let date = calendar.date(from: components)!
      let expected = components.month == 2 ? "2_28" : "12_31"
      precondition(store.color(on: date)?.id == expected)
    }

    // The same instant can select different local dates, with Gregorian leap-day fallback.
    let formatter = ISO8601DateFormatter()
    let dateCases: [(String, String, String)] = [
      ("2025-01-01T00:30:00Z", "America/Los_Angeles", "12_31"),
      ("2025-01-01T00:30:00Z", "Asia/Taipei", "1_1"),
      ("2024-02-29T12:00:00Z", "Asia/Tokyo", "2_28"),
      ("2024-03-01T01:00:00Z", "America/Los_Angeles", "2_28"),
      ("2024-03-01T01:00:00Z", "Asia/Taipei", "3_1"),
      ("2024-03-10T09:59:59Z", "America/Los_Angeles", "3_10"),
      ("2024-03-10T10:00:00Z", "America/Los_Angeles", "3_10"),
      ("2024-11-03T08:59:59Z", "America/Los_Angeles", "11_3"),
      ("2024-11-03T09:00:00Z", "America/Los_Angeles", "11_3"),
    ]
    for (instant, zone, expectedID) in dateCases {
      precondition(catalog.color(on: formatter.date(from: instant)!, timeZone: TimeZone(identifier: zone)!)?.id == expectedID)
    }

    // Search includes names, readings and prose, and treats HEX case/#/edge whitespace equally.
    for query in ["銀朱", "ぎんしゅ", "五重塔", "E34607", "e34607", "#e34607", " \n#E34607\t"] {
      precondition(catalog.search(query: query).contains { $0.id == "1_1" })
    }
    for query in ["", " \n\t", "#", "this-color-does-not-exist"] {
      precondition(catalog.search(query: query).isEmpty)
    }
    precondition(store.search(query: "e34607").map(\.id) == ["1_1"])
    precondition(store.search(query: "ときわいろ").map(\.id) == ["1_3"])
    for color in allColors {
      for query in [color.kanji, color.ruby, color.desc, color.hex] {
        precondition(catalog.search(query: query).contains { $0.id == color.id })
      }
    }
    let matches = catalog.search(query: "色").map(\.id)
    precondition(matches.count == Set(matches).count)
    precondition(matches == expectedOrder.filter { Set(matches).contains($0) })

    // Widget callbacks can read the immutable snapshot without a MainActor hop.
    DispatchQueue.concurrentPerform(iterations: 32) { _ in
      precondition(catalog.color(id: "12_31")?.id == "12_31")
      precondition(catalog.search(query: "#e34607").map(\.id) == ["1_1"])
    }

    let suiteName = "test.jcolors.favorites.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else { fatalError("Defaults suite unavailable") }
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set(["1_2", "missing", "1_2", "2_29", "1_1", 42], forKey: FavoritesStore.storageKey)
    let favorites = FavoritesStore(defaults: defaults, catalog: catalog)
    precondition(favorites.colorIDs == ["1_2", "1_1"])
    precondition(defaults.stringArray(forKey: FavoritesStore.storageKey) == ["1_2", "1_1"])
    precondition(favorites.colors.map(\.id) == favorites.colorIDs)
    var firstWindowIDs: [String] = []
    var secondWindowIDs: [String] = []
    var publishCount = 0
    let firstWindow = favorites.$colorIDs.sink { firstWindowIDs = $0; publishCount += 1 }
    let secondWindow = favorites.$colorIDs.sink { secondWindowIDs = $0 }
    favorites.add(id: "1_3")
    precondition(firstWindowIDs == ["1_3", "1_2", "1_1"] && firstWindowIDs == secondWindowIDs)
    let countBeforeNoop = publishCount
    favorites.add(id: "1_3")
    favorites.add(id: "missing")
    favorites.remove(id: "missing")
    precondition(publishCount == countBeforeNoop)
    precondition(favorites.contains(id: "1_3"))
    favorites.toggle(id: "1_2")
    precondition(!favorites.contains(id: "1_2"))
    favorites.toggle(id: "1_2")
    precondition(favorites.colorIDs == ["1_2", "1_3", "1_1"])
    let restored = FavoritesStore(defaults: defaults, catalog: catalog)
    precondition(restored.colorIDs == favorites.colorIDs)
    for id in favorites.colorIDs { favorites.remove(id: id) }
    precondition(firstWindowIDs.isEmpty && secondWindowIDs.isEmpty && favorites.colors.isEmpty)
    precondition(FavoritesStore(defaults: defaults, catalog: catalog).colorIDs.isEmpty)
    withExtendedLifetime((firstWindow, secondWindow)) {}

    // Missing/corrupted bundled data must not crash date or navigation lookups.
    try files.removeItem(at: fixture.appendingPathComponent("1.json"))
    try Data("not JSON".utf8).write(to: fixture.appendingPathComponent("2.json"))
    let damagedStore = ModelTool(bundle: bundle)
    precondition(damagedStore.getColors(filename: "1").isEmpty)
    precondition(damagedStore.getColors(filename: "2").isEmpty)
    precondition(damagedStore.color(id: "1_1") == nil)
    precondition(damagedStore.adjacentColor(to: "", in: "1", forward: true)?.id == "3_1")
    // Previously loaded resources are retained and do not depend on another file read.
    precondition(store.getColors(filename: "1").count == 31)
    for month in 2...12 {
      try files.removeItem(at: fixture.appendingPathComponent("\(month).json"))
    }
    for color in allColors {
      precondition(catalog.color(id: color.id)?.id == color.id)
      precondition(catalog.search(query: color.hex).contains { $0.id == color.id })
    }
    precondition(catalog.allColors.count == 365)

    let start = DispatchTime.now().uptimeNanoseconds
    var count = 0
    for _ in 0..<1000 {
      count += store.getColors(filename: "green").count
    }
    let milliseconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    precondition(count == 63_000)
    print("PASS: 365 IDs, 1,460 navigation steps, search fields/order/cache, concurrent reads, Gregorian timezone/DST/leap boundaries")
    print("PASS: favorites duplicate/invalid cleanup, latest-first order, restart restoration, two-window observation, empty/no-op changes")
    print("PASS: 365 exact color deep links, premium formats, unknown/malformed routes and unsupported URL components")
    print("Cached 1,000 green lookups: \(milliseconds) ms; returned models: \(count)")
  }
}

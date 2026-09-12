// Compile with JColors/Models/ColorModel.swift and the resolved SwiftyJSON module.
// Run the executable with the repository root as its first argument.
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
    let store = ModelTool(bundle: bundle)
    let allColors = store.allMonths.flatMap { store.getColors(filename: String($0)) }
    let ids = Set(allColors.map(\.id))
    precondition(allColors.count == 365 && ids.count == 365)

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

    let start = DispatchTime.now().uptimeNanoseconds
    var count = 0
    for _ in 0..<1000 {
      count += store.getColors(filename: "green").count
    }
    let milliseconds = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    precondition(count == 63_000)
    print("PASS: 365 IDs, 1,460 reversible navigation steps, boundaries, day mapping, leap day, invalid data, cache retention")
    print("Cached 1,000 green lookups: \(milliseconds) ms; returned models: \(count)")
  }
}

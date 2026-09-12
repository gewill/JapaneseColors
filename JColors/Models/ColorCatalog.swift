import Foundation

/// An immutable snapshot of the twelve month resources, shared by the app and widget.
struct ColorCatalog: Sendable {
  static let shared = ColorCatalog()
  static let allMonths = Array(1...12)
  static let daysInMonths = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  let allColors: [ColorModel]
  private let colorsByID: [String: ColorModel]
  private let colorsByMonth: [String: [ColorModel]]
  private let searchEntries: [SearchEntry]

  init(bundle: Bundle = .main) {
    var months: [String: [ColorModel]] = [:]
    var colors: [ColorModel] = []
    var seen = Set<String>()
    for month in Self.allMonths {
      let filename = String(month)
      let validColors = Self.readColors(filename: filename, bundle: bundle).filter { color in
        guard color.month == filename,
              let day = Int(color.date), color.date == String(day),
              (1...Self.daysInMonths[month]).contains(day)
        else { return false }
        return seen.insert(color.id).inserted
      }.sorted { Int($0.date)! < Int($1.date)! }
      months[filename] = validColors
      colors.append(contentsOf: validColors)
    }
    allColors = colors
    colorsByID = Dictionary(uniqueKeysWithValues: colors.map { ($0.id, $0) })
    colorsByMonth = months
    searchEntries = colors.map(SearchEntry.init)
  }

  func getColors(filename: String) -> [ColorModel] {
    colorsByMonth[filename] ?? []
  }

  func color(id: String) -> ColorModel? {
    colorsByID[id]
  }

  func color(on date: Date, timeZone: TimeZone = .current) -> ColorModel? {
    // Keep catalog dates independent of the user's preferred calendar.
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    return color(id: "\(month)_\(month == 2 && day == 29 ? 28 : day)")
  }

  func search(query: String) -> [ColorModel] {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !query.isEmpty else { return [] }
    let hexQuery = query.hasPrefix("#") ? String(query.dropFirst()) : query
    return searchEntries.compactMap { entry in
      let textMatches = entry.text.contains { $0.contains(query) }
      let hexMatches = !hexQuery.isEmpty && entry.hex.contains(hexQuery)
      return textMatches || hexMatches ? entry.color : nil
    }
  }

  static func readColors(filename: String, bundle: Bundle) -> [ColorModel] {
    guard let url = bundle.url(forResource: filename, withExtension: "json") else { return [] }
    do {
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(ColorFile.self, from: data).colors
    } catch {
      NSLog("Unable to read bundled color resource %@: %@", filename, String(describing: error))
      return []
    }
  }

  private struct ColorFile: Decodable {
    let colors: [ColorModel]
  }

  private struct SearchEntry: Sendable {
    let color: ColorModel
    let text: [String]
    let hex: String

    init(color: ColorModel) {
      self.color = color
      text = [color.kanji, color.ruby, color.desc].map { $0.lowercased() }
      hex = color.hex.lowercased().replacingOccurrences(of: "#", with: "")
    }
  }
}

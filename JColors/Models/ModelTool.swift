import Foundation

/// App navigation keeps its existing category order; shared catalog lookups are immutable.
@MainActor
final class ModelTool {
  static let shared = ModelTool(catalog: .shared)

  private let bundle: Bundle
  private let catalog: ColorCatalog
  private var colorsBySeries: [String: [ColorModel]] = [:]

  let allSeries = ["yellow", "green", "red", "purple", "blue", "pink", "brown", "orange", "black", "gray", "white"]
  let allMonths = ColorCatalog.allMonths
  let daysInMonths = ColorCatalog.daysInMonths
  var allColors: [ColorModel] { catalog.allColors }

  init(bundle: Bundle = .main, catalog: ColorCatalog? = nil) {
    self.bundle = bundle
    self.catalog = catalog ?? ColorCatalog(bundle: bundle)
  }

  func getColors(filename: String) -> [ColorModel] {
    guard allSeries.contains(filename) else {
      return catalog.getColors(filename: filename)
    }
    if let colors = colorsBySeries[filename] { return colors }
    let colors = ColorCatalog.readColors(filename: filename, bundle: bundle)
    colorsBySeries[filename] = colors
    return colors
  }

  func color(id: String) -> ColorModel? {
    catalog.color(id: id)
  }

  func color(on date: Date) -> ColorModel? {
    catalog.color(on: date)
  }

  func search(query: String) -> [ColorModel] {
    catalog.search(query: query)
  }

  func colorCategory(for color: ColorModel) -> String? {
    allSeries.first { filename in
      getColors(filename: filename).contains { $0.id == color.id }
    }
  }

  func randomColor() -> ColorModel? {
    // Sample whole catalog days uniformly, including December 31 and DST days.
    color(dayOfYear: Int.random(in: 1...daysInMonths.reduce(0, +)))
  }

  func color(dayOfYear: Int) -> ColorModel? {
    guard (1...daysInMonths.reduce(0, +)).contains(dayOfYear) else { return nil }
    var day = dayOfYear
    for month in allMonths {
      if day <= daysInMonths[month] {
        return color(id: "\(month)_\(day)")
      }
      day -= daysInMonths[month]
    }
    return nil
  }

  func adjacentColor(to id: String, in filename: String, forward: Bool) -> ColorModel? {
    let categories = allSeries.contains(filename) ? allSeries : allMonths.map(String.init)
    guard let categoryIndex = categories.firstIndex(of: filename) else { return nil }
    let colors = getColors(filename: filename)
    if let index = colors.firstIndex(where: { $0.id == id }) {
      let nextIndex = index + (forward ? 1 : -1)
      if colors.indices.contains(nextIndex) {
        return colors[nextIndex]
      }
    } else if let color = forward ? colors.first : colors.last {
      return color
    }
    for step in 1...categories.count {
      let index = (categoryIndex + (forward ? step : -step) + categories.count) % categories.count
      let candidates = getColors(filename: categories[index])
      if let color = forward ? candidates.first : candidates.last {
        return color
      }
    }
    return nil
  }
}

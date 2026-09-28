import Foundation

/// Routes identify the color rendered by a widget, rather than re-evaluating "today".
enum AppRoute: Equatable {
  case color(String)
  case premium

  init?(url: URL, catalog: ColorCatalog = .shared) {
    guard url.scheme?.lowercased() == "jcolors",
          url.user == nil, url.password == nil, url.port == nil,
          url.query == nil, url.fragment == nil else { return nil }
    switch url.host?.lowercased() {
    case "color":
      let identifier = String(url.path.dropFirst())
      guard url.path.hasPrefix("/"), !identifier.contains("/"),
            catalog.color(id: identifier) != nil else { return nil }
      self = .color(identifier)
    case "premium":
      guard url.path.isEmpty || url.path == "/" else { return nil }
      self = .premium
    default:
      return nil
    }
  }
}

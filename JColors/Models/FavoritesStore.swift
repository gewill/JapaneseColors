import Combine
import Foundation

/// All app windows observe the same instance; the ordered IDs survive app restarts.
@MainActor
final class FavoritesStore: ObservableObject {
  static let shared = FavoritesStore()
  static let storageKey = "favoriteColorIDs"

  @Published private(set) var colorIDs: [String]

  private let defaults: UserDefaults
  private let catalog: ColorCatalog

  var colors: [ColorModel] { colorIDs.compactMap { catalog.color(id: $0) } }

  init(defaults: UserDefaults = .standard, catalog: ColorCatalog = .shared) {
    self.defaults = defaults
    self.catalog = catalog
    var seen = Set<String>()
    let savedIDs = (defaults.array(forKey: Self.storageKey) ?? []).compactMap { $0 as? String }
    colorIDs = savedIDs.filter { catalog.color(id: $0) != nil && seen.insert($0).inserted }
    if defaults.object(forKey: Self.storageKey) != nil,
       defaults.stringArray(forKey: Self.storageKey) != colorIDs {
      defaults.set(colorIDs, forKey: Self.storageKey)
    }
  }

  func contains(id: String) -> Bool {
    colorIDs.contains(id)
  }

  func toggle(id: String) {
    if contains(id: id) {
      remove(id: id)
    } else {
      add(id: id)
    }
  }

  func add(id: String) {
    guard catalog.color(id: id) != nil, !contains(id: id) else { return }
    colorIDs.insert(id, at: 0)
    persist()
  }

  func remove(id: String) {
    guard contains(id: id) else { return }
    colorIDs.removeAll { $0 == id }
    persist()
  }

  private func persist() {
    defaults.set(colorIDs, forKey: Self.storageKey)
  }
}

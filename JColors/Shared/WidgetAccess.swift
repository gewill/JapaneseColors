import Foundation
#if os(iOS) || os(macOS)
import WidgetKit
#endif

/// The app is the only writer; extensions consume the last known entitlement offline.
struct WidgetEntitlementCache {
  private static let entitlementKey = "widget.proLifetime"
  let defaults: UserDefaults

  var isPro: Bool { defaults.bool(forKey: Self.entitlementKey) }
  var hasSnapshot: Bool { defaults.object(forKey: Self.entitlementKey) != nil }

  #if !WIDGET_EXTENSION
  @discardableResult
  func seed(isPro: Bool) -> Bool {
    guard !hasSnapshot else { return false }
    return update(isPro: isPro)
  }

  @discardableResult
  func update(isPro: Bool) -> Bool {
    guard !hasSnapshot || self.isPro != isPro else { return false }
    defaults.set(isPro, forKey: Self.entitlementKey)
    return true
  }
  #endif
}

enum WidgetAccess {
  static let kind = "DailyJapaneseColor"

  private static var cache: WidgetEntitlementCache? {
    #if os(iOS) || os(macOS)
    guard let group = Bundle.main.object(forInfoDictionaryKey: "JColorsAppGroup") as? String,
          !group.isEmpty, !group.contains("$("),
          let defaults = UserDefaults(suiteName: group)
    else { return nil }
    return WidgetEntitlementCache(defaults: defaults)
    #else
    return nil
    #endif
  }

  static var isPro: Bool { cache?.isPro == true }

  #if !WIDGET_EXTENSION
  static func seed(isPro: Bool) {
    if cache?.seed(isPro: isPro) == true { reloadForCalendarChange() }
  }

  static func update(isPro: Bool) {
    if cache?.update(isPro: isPro) == true { reloadForCalendarChange() }
  }

  static func reloadForCalendarChange() {
    #if os(iOS) || os(macOS)
    WidgetCenter.shared.reloadTimelines(ofKind: kind)
    #endif
  }
  #endif
}

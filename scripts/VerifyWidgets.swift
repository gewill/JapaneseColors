import Foundation

@main
struct VerifyWidgets {
  static func main() throws {
    let resourcePath = CommandLine.arguments.dropFirst().first ?? "scripts/byMonth"
    guard let bundle = Bundle(path: URL(fileURLWithPath: resourcePath).standardizedFileURL.path) else {
      fatalError("Cannot open month resources: \(resourcePath)")
    }
    let catalog = ColorCatalog(bundle: bundle)
    precondition(catalog.allColors.count == 365)
    let parser = ISO8601DateFormatter()
    let utc = TimeZone(secondsFromGMT: 0)!

    func schedule(_ instant: String, zone: TimeZone = utc) -> [DailyColorSnapshot] {
      let now = parser.date(from: instant)!
      let result = DailyColorSchedule.entries(from: now, catalog: catalog, timeZone: zone)
      precondition(result.count == 7 && result.first?.date == now)
      precondition(result.allSatisfy { $0.color != nil })
      precondition(zip(result, result.dropFirst()).allSatisfy { $0.date < $1.date })
      let reload = DailyColorSchedule.reloadDate(from: now, timeZone: zone)
      precondition(reload == result[1].date)
      return result
    }

    let yearEnd = schedule("2026-12-29T12:00:00Z")
    precondition(yearEnd.map { $0.color!.id } == ["12_29", "12_30", "12_31", "1_1", "1_2", "1_3", "1_4"])
    let leap = schedule("2028-02-27T12:00:00Z")
    precondition(leap.map { $0.color!.id }.prefix(4) == ["2_27", "2_28", "2_28", "3_1"])
    precondition(leap[2].dateLabel == "2月29日")

    let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
    let spring = schedule("2026-03-07T08:00:00Z", zone: losAngeles)
    precondition(spring[2].date.timeIntervalSince(spring[1].date) == 23 * 60 * 60)
    let autumn = schedule("2026-10-31T07:00:00Z", zone: losAngeles)
    precondition(autumn[2].date.timeIntervalSince(autumn[1].date) == 25 * 60 * 60)
    let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    precondition(schedule("2026-12-31T23:30:00Z", zone: tokyo)[0].color?.id == "1_1")
    precondition(schedule("2026-12-31T23:30:00Z", zone: losAngeles)[0].color?.id == "12_31")

    let suiteName = "org.gewill.JapaneseColors.WidgetVerification.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let cache = WidgetEntitlementCache(defaults: defaults)
    precondition(!cache.hasSnapshot && !cache.isPro)
    precondition(cache.seed(isPro: true) && cache.isPro)
    precondition(!cache.update(isPro: true))
    // A second launch must not overwrite a newer verified shared snapshot.
    precondition(!cache.seed(isPro: false) && cache.isPro)
    let restored = WidgetEntitlementCache(defaults: UserDefaults(suiteName: suiteName)!)
    precondition(restored.hasSnapshot && restored.isPro)
    precondition(cache.update(isPro: false) && !cache.isPro)
    precondition(!cache.seed(isPro: true) && !cache.isPro)
    precondition(cache.update(isPro: true) && cache.isPro)

    print("✅ Widget schedule: seven days, year/leap/DST/time-zone boundaries; entitlement cache: seed, restore, change, revoke")
  }
}

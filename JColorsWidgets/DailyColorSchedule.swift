import Foundation

struct DailyColorSnapshot {
  let date: Date
  let color: ColorModel?
  let dateLabel: String
}

/// Calendar arithmetic keeps local midnights correct across DST and year boundaries.
enum DailyColorSchedule {
  static func entries(
    from now: Date,
    catalog: ColorCatalog = .shared,
    timeZone: TimeZone = .current
  ) -> [DailyColorSnapshot] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let today = calendar.startOfDay(for: now)
    return (0..<7).compactMap { offset in
      guard let midnight = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
      let date = offset == 0 ? now : midnight
      return DailyColorSnapshot(
        date: date,
        color: catalog.color(on: date, timeZone: timeZone),
        dateLabel: "\(calendar.component(.month, from: date))月\(calendar.component(.day, from: date))日"
      )
    }
  }

  static func reloadDate(from now: Date, timeZone: TimeZone = .current) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    // Retain seven days of fallback entries while rechecking the local time zone daily.
    return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
  }
}

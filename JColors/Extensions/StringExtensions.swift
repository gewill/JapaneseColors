import SwiftUI

extension String {
  var localizedStringKey: LocalizedStringKey {
    LocalizedStringKey(self)
  }

  /// SwifterSwift: Date object from string of date format.
  ///
  ///    "2017-01-15".date(withFormat: "yyyy-MM-dd") -> Date set to Jan 15, 2017
  ///    "not date string".date(withFormat: "yyyy-MM-dd") -> nil
  ///
  /// - Parameter format: date format.
  /// - Returns: Date object from string (if applicable).
  func date(withFormat format: String = "yyyy-MM-dd") -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.date(from: self)
  }
}

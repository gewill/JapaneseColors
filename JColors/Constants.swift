import Foundation
import SwiftUI

enum Constant {
  static let padding: CGFloat = UserInterfaceIdiom.current == .mac ? 12 : 10
  static let buttonPadding: CGFloat = 4
  static let cornerRadius: CGFloat = 20
  static let maxiPhoneScreenWidth: CGFloat = 428
  static let tabBarHeight: CGFloat = 94
  static let smallButtonSize: CGSize = .init(width: 40, height: 40)
}

enum UserInterfaceIdiom: Int {
  case unspecified = -1
  case phone = 0
  case pad = 1
  case tv = 2
  case carPlay = 3
  case mac = 5
  case watch = 6

  static var current: UserInterfaceIdiom {
    #if os(iOS)
      UserInterfaceIdiom(rawValue: UIDevice.current.userInterfaceIdiom.rawValue) ?? .unspecified
    #elseif os(macOS)
      return .mac
    #elseif os(watchOS)
      return .watch
    #elseif os(tvOS)
      return .tv
    #else
      return .unspecified
    #endif
  }
}

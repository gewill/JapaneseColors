import Foundation
import Glassfy
import SwiftUI

enum ProFeature: String, CaseIterable, Identifiable {
  case copy = "复制颜色Hex值"
  case date = "切换日期，今日和随机日期"

  var imageName: String {
    switch self {
    case .copy: return "doc.on.doc"
    case .date: return "calendar.badge.clock"
    }
  }

  var id: ProFeature { self }
}

final class IAPManager {
  enum Sku: String {
    case ios_jcolors_pro_lifetime_3
  }

  enum Permission: String {
    case pro_lifetime
  }

  enum Offering: String {
    case pro_lifetime
  }

  static let shared = IAPManager()

  private init() {}

  func configure() {
    #if DEBUG
    Glassfy.log(level: .debug)
    #endif
    Glassfy.initialize(apiKey: "1b9c9cfaeb834c89837152d6672c92f0")
  }

  func checkProLifetime(completion: @escaping (Bool) -> Void) {
    Glassfy.permissions { permissions, error in
      guard let permissions = permissions, error == nil else {
        completion(false)
        return
      }

      if let permission = permissions[Permission.pro_lifetime.rawValue],
         permission.isValid
      {
        completion(true)
      } else {
        completion(false)
      }
    }
  }

  func purchase(sku: Glassfy.Sku) {
    Glassfy.purchase(sku: sku) { transaction, error in
      guard let t = transaction, error == nil else {
        return
      }
    }
  }

  func getPermissions() {
    Glassfy.permissions { permissions, error in
      guard let permissions = permissions, error == nil else {
        return
      }
    }
  }

  func restorePurchases() {
    Glassfy.restorePurchases { permissions, error in
      guard let permissions = permissions, error == nil else {
        return
      }
    }
  }
}

import Foundation
import RevenueCat
import SwiftUI

enum ProFeature: String, CaseIterable, Identifiable {
  case copy = "复制颜色Hex值"
  case date = "切换日期，今日和随机日期"
  case universalPurchase = "通用购买项目，一次购买全平台使用"

  var imageName: String {
    switch self {
    case .copy: return "doc.on.doc"
    case .date: return "calendar.badge.clock"
    case .universalPurchase: return "purchased.circle"
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
    Purchases.logLevel = .debug
    #endif
    Purchases.configure(withAPIKey: "appl_qkcGKdlnRMjdvrsRTfqANMqWeiu")
  }

  func checkProLifetime(completion: @escaping (Bool) -> Void) {
    Purchases.shared.getCustomerInfo { customerInfo, _ in
      if let infos = customerInfo?.entitlements.active,
         let _ = infos[IAPManager.Permission.pro_lifetime.rawValue]
      {
        completion(true)
      } else {
        completion(false)
      }
    }
    Purchases.shared.restorePurchases()
  }
}

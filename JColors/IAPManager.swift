import Foundation
import RevenueCat
import SwiftUI

enum ProFeature: String, CaseIterable, Identifiable {
  case copy = "复制颜色Hex值"
  case date = "切换日期，今日和随机日期"
  case universalPurchase = "通用购买项目，一次购买全平台使用"
  #if !os(tvOS)
  case dailyColorWidget = "每日色小组件，每天遇见一色"
  #endif

  var imageName: String {
    switch self {
    case .copy: return "doc.on.doc"
    case .date: return "calendar.badge.clock"
    case .universalPurchase: return "purchased.circle"
    #if !os(tvOS)
    case .dailyColorWidget: return "square.grid.2x2"
    #endif
    }
  }

  var id: ProFeature { self }
}

final class IAPManager: NSObject, PurchasesDelegate {
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

  private override init() {
    super.init()
  }

  func configure() {
    WidgetAccess.seed(isPro: UserDefaults.standard.bool(forKey: UserDefaultsKeys.isPro.rawValue))
    guard !Purchases.isConfigured else { return }

    #if DEBUG
    Purchases.logLevel = .debug
    #endif
    Purchases.proxyURL = URL(string: "https://api.rc-backup.com/")!
    Purchases.configure(withAPIKey: "appl_qkcGKdlnRMjdvrsRTfqANMqWeiu")
    Purchases.shared.delegate = self
    checkProLifetime()
  }

  func checkProLifetime() {
    Purchases.shared.getCustomerInfo { customerInfo, _ in
      self.updateProStatus(from: customerInfo)
    }
  }

  func updateProStatus(from customerInfo: CustomerInfo?) {
    // A failed request is not evidence that an existing entitlement was revoked.
    guard let customerInfo else { return }

    let isPro = customerInfo.entitlements[Permission.pro_lifetime.rawValue]?.isActive == true
    let defaults = UserDefaults.standard
    if defaults.bool(forKey: UserDefaultsKeys.isPro.rawValue) != isPro {
      defaults.set(isPro, forKey: UserDefaultsKeys.isPro.rawValue)
    }
    WidgetAccess.update(isPro: isPro)
  }

  func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
    updateProStatus(from: customerInfo)
  }
}

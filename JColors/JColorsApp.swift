//
//  JColorsApp.swift
//  JColors
//
//  Created by will on 17/08/2023.
//

import SwiftUI

@main
struct JColorsApp: App {
  @AppStorage(UserDefaultsKeys.isPro.rawValue) var isPro: Bool = false
  @AppStorage(UserDefaultsKeys.lastCheckProDate.rawValue) var lastCheckProDate: TimeInterval = Date().yesterday.unixTimestamp

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          IAPManager.shared.configure()
          checkPro()
        }
    }
  }

  // MARK: - private methods

  func checkPro() {
    if Date().yesterday.unixTimestamp >= lastCheckProDate {
      IAPManager.shared.checkProLifetime { isPro in
        self.isPro = isPro
        lastCheckProDate = Date().unixTimestamp
      }
    }
  }
}

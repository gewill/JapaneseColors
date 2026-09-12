//
//  JColorsApp.swift
//  JColors
//
//  Created by will on 17/08/2023.
//

import SwiftUI

@main
struct JColorsApp: App {
  init() {
    IAPManager.shared.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

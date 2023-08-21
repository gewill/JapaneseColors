//
//  JColorsApp.swift
//  JColors
//
//  Created by will on 17/08/2023.
//

import SwiftUI

@main
struct JColorsApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear {
          IAPManager.shared.configure()
        }
    }
  }
}

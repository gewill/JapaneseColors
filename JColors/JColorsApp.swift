//
//  JColorsApp.swift
//  JColors
//
//  Created by will on 17/08/2023.
//

import SwiftUI

@main
struct JColorsApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var widgetCalendarKey = ""

  init() {
    IAPManager.shared.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onAppear { refreshWidgetCalendar() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
          refreshWidgetCalendar()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
          refreshWidgetCalendar()
        }
    }
    .onChange(of: scenePhase) { phase in
      if phase == .active { refreshWidgetCalendar() }
    }
  }

  private func refreshWidgetCalendar() {
    #if !os(tvOS)
    let timeZone = TimeZone.current
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let date = calendar.dateComponents([.year, .month, .day], from: .now)
    let key = "\(timeZone.identifier):\(date.year ?? 0)-\(date.month ?? 0)-\(date.day ?? 0)"
    guard widgetCalendarKey != key else { return }
    widgetCalendarKey = key
    WidgetAccess.reloadForCalendarChange()
    #endif
  }
}

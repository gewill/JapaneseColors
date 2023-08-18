//
//  ButtonStyle.swift
//  JapaneseColors
//
//  Created by will on 18/08/2023.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  let color = Color.accentColor

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
      .foregroundColor(configuration.isPressed ? color.opacity(0.5) : color)
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(configuration.isPressed ? color.opacity(0.5) : color, lineWidth: 1.5)
      )
      .padding(2)
  }
}

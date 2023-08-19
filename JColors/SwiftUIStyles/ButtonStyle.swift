//
//  ButtonStyle.swift
//  JColors
//
//  Created by will on 18/08/2023.
//

import SwiftUI

#if os(tvOS)
struct PrimaryButtonStyle: PrimitiveButtonStyle {
  @FocusState private var isFocused: Bool
  let scaleEffect: CGFloat = 1.05
  let color = Color.accentColor

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.vertical, 6)
      .padding(.horizontal, 12)
      .foregroundColor(isFocused ? color : color.opacity(0.5))
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(isFocused ? color : color.opacity(0.5), lineWidth: 3)
      )
      .padding(2)
      .scaleEffect(isFocused ? scaleEffect : 1)
      .animation(.easeOut(duration: 0.2), value: isFocused)
      .focusable()
      .focused($isFocused)
      .onTapGesture {
        configuration.trigger()
      }
  }
}
#else
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
#endif

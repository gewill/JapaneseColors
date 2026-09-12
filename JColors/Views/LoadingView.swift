//
//  LoadingView.swift
//  OpenAISwiftUI
//
//  Created by will on 04/03/width23.
//

import SwiftUI

struct LoadingView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let color: Color = .accentColor
  let width: CGFloat
  @State private var shouldAnimate = false

  var body: some View {
    let isAnimating = shouldAnimate && !reduceMotion
    HStack {
      Circle()
        .fill(color)
        .frame(width: width, height: width)
        .scaleEffect(isAnimating ? 1.0 : 0.5)
        .animation(isAnimating ? Animation.easeInOut(duration: 0.5).repeatForever() : nil, value: isAnimating)
      Circle()
        .fill(color)
        .frame(width: width, height: width)
        .scaleEffect(isAnimating ? 1.0 : 0.5)
        .animation(isAnimating ? Animation.easeInOut(duration: 0.5).repeatForever().delay(0.3) : nil, value: isAnimating)
      Circle()
        .fill(color)
        .frame(width: width, height: width)
        .scaleEffect(isAnimating ? 1.0 : 0.5)
        .animation(isAnimating ? Animation.easeInOut(duration: 0.5).repeatForever().delay(0.6) : nil, value: isAnimating)
    }
    .onAppear {
      self.shouldAnimate = true
    }
    .onDisappear {
      self.shouldAnimate = false
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Loading")
  }
}

struct LoadingView_Previews: PreviewProvider {
  static var previews: some View {
    LoadingView(width: 10)
  }
}

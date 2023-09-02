//
//  AdaptiveStack.swift
//  JColors
//
//  Created by will on 02/09/2023.
//

import SwiftUI

struct AdaptiveStack<Content: View>: View {
  @Binding var isVertical: Bool
  let horizontalAlignment: HorizontalAlignment
  let verticalAlignment: VerticalAlignment
  let spacing: CGFloat?
  let content: () -> Content

  init(isVertical: Binding<Bool>, horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
    _isVertical = isVertical
    self.horizontalAlignment = horizontalAlignment
    self.verticalAlignment = verticalAlignment
    self.spacing = spacing
    self.content = content
  }

  var body: some View {
    ZStack {
      if isVertical {
        VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
      } else {
        HStack(alignment: verticalAlignment, spacing: spacing, content: content)
      }
    }
  }
}

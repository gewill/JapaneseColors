//
//  ViewExtensions.swift
//  JapaneseColors
//
//  Created by will on 18/08/2023.
//

import SwiftUI

extension View {
  func border(_ color: Color, width: CGFloat, cornerRadius: CGFloat) -> some View {
    overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(color, lineWidth: width))
  }
}


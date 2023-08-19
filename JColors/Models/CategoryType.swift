//
//  CategoryType.swift
//  JColors
//
//  Created by will on 19/08/2023.
//

import Foundation
import SwiftUI

enum CategoryType: String, CaseIterable, Identifiable {
  case color, month
  var id: CategoryType { self }
}

enum ColorCategory: String, CaseIterable, Identifiable {
  case yellow, green, red, purple, blue, pink, brown, orange, black, gray, white
  var id: ColorCategory { self }

  var color: Color {
    switch self {
    case .yellow:
      return .yellow
    case .green:
      return .green
    case .red:
      return .red
    case .purple:
      return .purple
    case .blue:
      return .blue
    case .pink:
      return .pink
    case .brown:
      return .brown
    case .orange:
      return .orange
    case .black:
      return .black
    case .gray:
      return .gray
    case .white:
      return .white
    }
  }
}

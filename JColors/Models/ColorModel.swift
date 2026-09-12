//
//  ColorModel.swift
//  JColors
//
//  Created by will on 18/08/2023.
//

import Foundation

struct ColorModel: Identifiable, Decodable, Sendable {
  var id: String { "\(month)_\(date)" }
  let date: String
  let desc: String
  let hex: String
  let kanji: String
  let month: String
  let ruby: String
  let series: String

}

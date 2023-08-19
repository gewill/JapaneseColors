//
//  ColorModel.swift
//  JColors
//
//  Created by will on 18/08/2023.
//

import Foundation

struct ColorModel: Identifiable {
  var id: String { "\(month)_\(date)" }
  let date: String
  let desc: String
  let hex: String
  let kanji: String
  let month: String
  let ruby: String
  let series: String

  init(json: JSON) {
    date = json["date"].stringValue
    desc = json["desc"].stringValue
    hex = json["hex"].stringValue
    kanji = json["kanji"].stringValue
    month = json["month"].stringValue
    ruby = json["ruby"].stringValue
    series = json["series"].stringValue
  }
}

struct ModelTool {
  private init() {}
  static let shared = ModelTool()

  let allSeries = ["yellow", "green", "red", "purple", "blue", "pink", "brown", "orange", "black", "gray", "white"]
  let allMonths = Array(1 ... 12)
  let daysInMonths: [Int] = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  func getColors(filename: String) -> [ColorModel] {
    if let url = Bundle.main.url(forResource: filename, withExtension: "json"),
       let data = try? Data(contentsOf: url)
    {
      let json = JSON(data)
      return json["colors"].arrayValue.map { ColorModel(json: $0) }
    }
    return []
  }
}

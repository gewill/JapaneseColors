//
//  ColorModel.swift
//  JColors
//
//  Created by will on 18/08/2023.
//

import Foundation
import SwiftyJSON

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

@MainActor
final class ModelTool {
  private let bundle: Bundle
  private var colorsByFilename: [String: [ColorModel]] = [:]

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  static let shared = ModelTool()

  let allSeries = ["yellow", "green", "red", "purple", "blue", "pink", "brown", "orange", "black", "gray", "white"]
  let allMonths = Array(1 ... 12)
  let daysInMonths: [Int] = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  func getColors(filename: String) -> [ColorModel] {
    guard allSeries.contains(filename) || allMonths.contains(where: { String($0) == filename }) else {
      return []
    }
    if let colors = colorsByFilename[filename] {
      return colors
    }
    let colors: [ColorModel]
    if let url = bundle.url(forResource: filename, withExtension: "json"),
       let data = try? Data(contentsOf: url)
    {
      let json = JSON(data)
      colors = json["colors"].arrayValue.map { ColorModel(json: $0) }
    } else {
      colors = []
    }
    colorsByFilename[filename] = colors
    return colors
  }

  func color(id: String) -> ColorModel? {
    let components = id.split(separator: "_", omittingEmptySubsequences: false)
    guard components.count == 2 else { return nil }
    return getColors(filename: String(components[0])).first { $0.id == id }
  }

  func color(on date: Date) -> ColorModel? {
    // The catalog uses Gregorian dates, regardless of the user's preferred calendar.
    let calendar = Calendar(identifier: .gregorian)
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    return color(id: "\(month)_\(month == 2 && day == 29 ? 28 : day)")
  }

  func colorCategory(for color: ColorModel) -> String? {
    allSeries.first { filename in
      getColors(filename: filename).contains { $0.id == color.id }
    }
  }

  func randomColor() -> ColorModel? {
    // Sample whole catalog days uniformly, including December 31 and DST days.
    color(dayOfYear: Int.random(in: 1...daysInMonths.reduce(0, +)))
  }

  func color(dayOfYear: Int) -> ColorModel? {
    guard (1...daysInMonths.reduce(0, +)).contains(dayOfYear) else { return nil }
    var day = dayOfYear
    for month in allMonths {
      if day <= daysInMonths[month] {
        return color(id: "\(month)_\(day)")
      }
      day -= daysInMonths[month]
    }
    return nil
  }

  func adjacentColor(to id: String, in filename: String, forward: Bool) -> ColorModel? {
    let categories = allSeries.contains(filename) ? allSeries : allMonths.map(String.init)
    guard let categoryIndex = categories.firstIndex(of: filename) else { return nil }
    let colors = getColors(filename: filename)
    if let index = colors.firstIndex(where: { $0.id == id }) {
      let nextIndex = index + (forward ? 1 : -1)
      if colors.indices.contains(nextIndex) {
        return colors[nextIndex]
      }
    } else if let color = forward ? colors.first : colors.last {
      return color
    }
    for step in 1...categories.count {
      let index = (categoryIndex + (forward ? step : -step) + categories.count) % categories.count
      let candidates = getColors(filename: categories[index])
      if let color = forward ? candidates.first : candidates.last {
        return color
      }
    }
    return nil
  }
}

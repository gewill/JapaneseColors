import Foundation
import SwiftUI

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }

  static let backgroundColor = Color("BackgroundColor")
  static let separatorColor = Color("separatorColor")
}

extension Color {
  /// Chooses the higher-contrast foreground for an opaque, fixed color using WCAG sRGB luminance.
  var contrastingForegroundColor: Color {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let components = cgColor?.converted(to: colorSpace, intent: .defaultIntent, options: nil)?.components,
          components.count >= 3
    else {
      return .primary
    }

    func linearize(_ component: CGFloat) -> CGFloat {
      component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
    let luminance = 0.2126 * linearize(components[0])
      + 0.7152 * linearize(components[1])
      + 0.0722 * linearize(components[2])
    let blackContrast = (luminance + 0.05) / 0.05
    let whiteContrast = 1.05 / (luminance + 0.05)
    return blackContrast >= whiteContrast ? .black : .white
  }

  // Check if the color is light or dark, as defined by the injected lightness threshold.
  // Some people report that 0.7 is best. I suggest to find out for yourself.
  // A nil value is returned if the lightness couldn't be determined.
  func isLight(threshold: Float = 0.5) -> Bool? {
    let originalCGColor = cgColor

    // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
    // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
    let RGBCGColor = originalCGColor?.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
    guard let components = RGBCGColor?.components else {
      return nil
    }
    guard components.count >= 3 else {
      return nil
    }

    let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
    return brightness > threshold
  }
}

// Verifies the production Color extension, not a duplicate foreground selector.
import Foundation
import SwiftUI

@main
struct VerifyContrast {
  static func main() {
    let path = CommandLine.arguments.dropFirst().first ?? "scripts/byMonth"
    guard let bundle = Bundle(path: URL(fileURLWithPath: path).standardizedFileURL.path),
          let linearSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else {
      fatalError("Cannot load catalog or linear sRGB color space")
    }
    let colors = ColorCatalog(bundle: bundle).allColors
    precondition(colors.count == 365)

    // Core Graphics performs the transfer-function conversion independently of
    // the production selector's explicit sRGB linearization formula.
    func luminance(_ color: Color) -> Double {
      guard let value = color.cgColor?.converted(to: linearSpace, intent: .relativeColorimetric, options: nil),
            let rgb = value.components, rgb.count == 4 else {
        fatalError("Expected a fixed opaque RGB color")
      }
      precondition(abs(value.alpha - 1) < 0.00001)
      return Double(rgb[0]) * 0.2126 + Double(rgb[1]) * 0.7152 + Double(rgb[2]) * 0.0722
    }
    precondition(Color(hex: "000000").contrastingForegroundColor == .white)
    precondition(Color(hex: "FFFFFF").contrastingForegroundColor == .black)
    var minimum = Double.infinity
    var minimumID = ""
    for model in colors {
      let background = Color(hex: model.hex)
      let foreground = background.contrastingForegroundColor
      precondition(foreground == .black || foreground == .white, "Dynamic fallback for \(model.id)")
      let backgroundLuminance = luminance(background)
      let foregroundLuminance = luminance(foreground)
      let ratio = (max(backgroundLuminance, foregroundLuminance) + 0.05)
        / (min(backgroundLuminance, foregroundLuminance) + 0.05)
      precondition(ratio >= 4.5, "Text contrast below 4.5:1 for \(model.id): \(ratio)")
      if ratio < minimum { minimum = ratio; minimumID = model.id }
    }
    print(String(format: "PASS: 365 production foreground/background pairs >= 4.5:1; minimum %.4f:1 (%@). Full-color mode only.", minimum, minimumID))
  }
}

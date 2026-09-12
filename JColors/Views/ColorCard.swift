//
//  ColorCard.swift
//  JColors
//
//  Created by will on 19/08/2023.
//

import SwiftUI
import SwiftUIOverlayContainer

struct ColorCard: View {
  let model: ColorModel
  var onShowPremium: () -> Void = {}

  @Environment(\.overlayContainerManager) var manager
  @State private var containerName = "ColorCard-" + UUID().uuidString
  @AppStorage(UserDefaultsKeys.isPro.rawValue) var isPro: Bool = false

  var body: some View {
    let color = Color(hex: model.hex)
    VStack {
      HStack {
        Text("\(model.month).\(model.date)")
        #if os(tvOS)
          .font(.headline)
        #else
          .font(.title3)
        #endif
        Spacer()

        #if os(tvOS)
          Text(model.hex)
        #else
          Button {
            if isPro {
              #if os(iOS)
                UIPasteboard.general.string = model.hex
              #else
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(model.hex, forType: .string)
              #endif
              manager.show(containerView: Message(text: "\(model.hex)已复制", type: .success, height: 60), in: containerName)
            } else {
              onShowPremium()
            }
          } label: {
            Text(model.hex)
              .frame(minHeight: 44)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Copy color code")
          .accessibilityValue(model.hex)
        #endif
      }
      .monospacedDigit()
      Spacer()
      Text(model.kanji)
      #if os(tvOS)
        .font(.headline)
      #else
        .font(.title3)
      #endif
      Text(model.ruby)
      #if os(tvOS)
        .font(.body)
      #else
        .font(.title3)
      #endif
      Spacer()
    }
    .padding(20)
    .foregroundColor(color.contrastingForegroundColor)
    .frame(width: UserInterfaceIdiom.current == .phone ? 200 : 300, height: UserInterfaceIdiom.current == .phone ? 200 : 300)
    .background(color)
    .cornerRadius(30)
    .padding(10)
    .background(Material.ultraThinMaterial)
    .cornerRadius(40)
    .overlayContainer(containerName, containerConfiguration: ContainerConfigurationForQueueMessage())
  }
}

struct ColorCard_Previews: PreviewProvider {
  static var previews: some View {
    ColorCard(model: ColorModel(
      date: "8", desc: "这是一种略带红色的浅黄色。温柔的自然色彩令人感到宁静。",
      hex: "#FFF4D9", kanji: "薄卵色", month: "3", ruby: "うすたまごいろ", series: "黄色"
    ))
  }
}

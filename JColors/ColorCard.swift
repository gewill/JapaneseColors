//
//  ColorCard.swift
//  JColors
//
//  Created by will on 19/08/2023.
//

import SwiftUI
import SwiftUIOverlayContainer
import SwiftyJSON

struct ColorCard: View {
  let model: ColorModel
  
  @Environment(\.overlayContainerManager) var manager
  var containerName: String { "MoreSettingsView" + model.id }

  var body: some View {
    VStack {
      HStack {
        Text("\(model.month).\(model.date)")
        #if os(tvOS)
          .font(.headline)
        #else
          .font(.title3)
        #endif
        Spacer()

        Text(model.hex)
          .onTapGesture {
            #if os(tvOS)
            #elseif os(iOS)
              UIPasteboard.general.string = model.hex
            #else
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(model.hex, forType: .string)
            #endif
            manager.show(containerView: Message(text: "\(model.hex)已复制", type: .success, height: 60), in: containerName)
          }
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
    .foregroundColor(Color(hex: model.hex).isLight(threshold: 0.7) == true ? Color.black : Color.white)
    .frame(width: UserInterfaceIdiom.current == .phone ? 200 : 300, height: UserInterfaceIdiom.current == .phone ? 200 : 300)
    .background(Color(hex: model.hex))
    .cornerRadius(30)
    .padding(10)
    .background(Material.ultraThinMaterial)
    .cornerRadius(40)
    .overlayContainer(containerName, containerConfiguration: ContainerConfigurationForQueueMessage())
  }
}

struct ColorCard_Previews: PreviewProvider {
  static var previews: some View {
    ColorCard(model: ColorModel(json: JSON([
      "month": "3", "date": "8", "kanji": "薄卵色", "hex": "#FFF4D9", "cat": "动物", "series": "黄色", "ruby": "うすたまごいろ", "desc": "这是一种略带红色的浅黄色。据说在江户时代，日本开始食用鸡蛋。随着饮食文化的变化，鸡蛋逐渐变得常见，并出现了这个颜色的名称。这种温柔的自然色彩令人感到宁静。",
    ])))
  }
}

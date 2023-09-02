//
//  FullscreenColorView.swift
//  JColors
//
//  Created by will on 02/09/2023.
//

import SwiftUI
import SwiftUIOverlayContainer
import SwiftyJSON

struct FullscreenColorView: View {
  let model: ColorModel
  let didSwipeLeft: () -> Void
  let didSwipeRight: () -> Void

  @Environment(\.overlayContainerManager) var manager
  let containerName: String = "FullscreenColorView"
  @AppStorage(UserDefaultsKeys.isPro.rawValue) var isPro: Bool = false
  @State private var showingPro = false
  @State private var showingInfo = true

  var body: some View {
    ZStack(alignment: .bottom) {
      Color(hex: model.hex)
      #if os(iOS)
        .statusBarHidden()
        .ignoresSafeArea()
      #endif
        .persistentSystemOverlays(.hidden)

      if showingInfo {
        ZStack {
          VStack(spacing: 0) {
            Capsule().fill(Material.bar)
              .frame(width: 54, height: 7.5)
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
                  if isPro {
                    #if os(tvOS)
                    #elseif os(iOS)
                      UIPasteboard.general.string = model.hex
                    #else
                      NSPasteboard.general.clearContents()
                      NSPasteboard.general.setString(model.hex, forType: .string)
                    #endif
                    manager.show(containerView: Message(text: "\(model.hex)已复制", type: .success, height: 60), in: containerName)
                  } else {
                    showingPro = true
                  }
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
          HStack {
            Button(action: {
              didSwipeLeft()
            }, label: {
              Image(systemName: "arrow.left.circle.fill")
                .font(.title)
            })
            Spacer()
            Button(action: {
              didSwipeRight()
            }, label: {
              Image(systemName: "arrow.right.circle.fill")
                .font(.title)
            })
          }
          .buttonStyle(.plain)
        }
        .foregroundColor(Color(hex: model.hex).isLight(threshold: 0.7) == true ? Color.black : Color.white)
        .padding(.horizontal, 30)
        .padding(.vertical)
        .background(Material.regular)
        .cornerRadius(40)
        .frame(maxWidth: Constant.maxiPhoneScreenWidth, maxHeight: 200)
        .padding()
        .transition(.move(edge: .bottom))
        .zIndex(1)
      }
    }
    .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
      .onEnded { value in
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height

        if abs(horizontalAmount) > abs(verticalAmount) {
          print(horizontalAmount < 0 ? "left swipe" : "right swipe")
          if horizontalAmount < 0 {
            didSwipeLeft()
          } else {
            didSwipeRight()
          }
        } else {
          print(verticalAmount < 0 ? "up swipe" : "down swipe")
          withAnimation(.smooth) {
            showingInfo = verticalAmount < 0
          }
        }
      })
    .overlayContainer(containerName, containerConfiguration: ContainerConfigurationForQueueMessage())
    .sheet(isPresented: $showingPro) {
      ProView(isPresented: $showingPro)
    }
  }
}

struct FullscreenColorView_Previews: PreviewProvider {
  static var previews: some View {
    ColorCard(model: ColorModel(json: JSON([
      "month": "3", "date": "8", "kanji": "薄卵色", "hex": "#FFF4D9", "cat": "动物", "series": "黄色", "ruby": "うすたまごいろ", "desc": "这是一种略带红色的浅黄色。据说在江户时代，日本开始食用鸡蛋。随着饮食文化的变化，鸡蛋逐渐变得常见，并出现了这个颜色的名称。这种温柔的自然色彩令人感到宁静。",
    ])))
  }
}

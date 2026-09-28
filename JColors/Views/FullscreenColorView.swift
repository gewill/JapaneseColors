//
//  FullscreenColorView.swift
//  JColors
//
//  Created by will on 02/09/2023.
//

import SwiftUI
import SwiftUIOverlayContainer

struct FullscreenColorView: View {
  let model: ColorModel
  let didSwipeLeft: () -> Void
  let didSwipeRight: () -> Void
  let onShowPremium: () -> Void
  let onDismiss: () -> Void

  @Environment(\.overlayContainerManager) var manager
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var containerName = "FullscreenColorView-" + UUID().uuidString
  @AppStorage(UserDefaultsKeys.isPro.rawValue) var isPro: Bool = false
  @State private var showingInfo = true

  var body: some View {
    ZStack(alignment: .bottom) {
      Button(action: onDismiss) {
        Color(hex: model.hex)
      }
        .buttonStyle(.plain)
        .accessibilityLabel("Exit full screen")
      #if os(iOS)
        .statusBarHidden()
        .ignoresSafeArea()
      #endif
        .persistentSystemOverlays(.hidden)

      if showingInfo {
        ZStack {
          VStack(spacing: 0) {
            #if !os(tvOS)
              Capsule().fill(Material.bar)
                .frame(width: 54, height: 7.5)
                .accessibilityHidden(true)
            #endif
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
                FavoriteButton(color: model)
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
          HStack {
            Button(action: {
              didSwipeLeft()
            }, label: {
              Image(systemName: "arrow.left.circle.fill")
                .font(.title)
                .frame(minWidth: 44, minHeight: 44)
            })
            .accessibilityLabel("Previous color")
            Spacer()
            Button(action: {
              didSwipeRight()
            }, label: {
              Image(systemName: "arrow.right.circle.fill")
                .font(.title)
                .frame(minWidth: 44, minHeight: 44)
            })
            .accessibilityLabel("Next color")
          }
          .buttonStyle(.plain)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 30)
        .padding(.vertical)
        .background(Material.regular)
        .cornerRadius(40)
        .frame(maxWidth: Constant.maxiPhoneScreenWidth, maxHeight: 200)
        .padding()
        .transition(reduceMotion ? .opacity : .move(edge: .bottom))
        .zIndex(1)
      }
    }
    #if !os(tvOS)
    .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
      .onEnded { value in
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height

        if abs(horizontalAmount) > abs(verticalAmount) {
          if horizontalAmount < 0 {
            didSwipeLeft()
          } else {
            didSwipeRight()
          }
        } else {
          withAnimation(reduceMotion ? nil : .spring()) {
            showingInfo = verticalAmount < 0
          }
        }
      })
    #endif
      .overlayContainer(containerName, containerConfiguration: ContainerConfigurationForQueueMessage())
      .accessibilityAction(.escape) {
        onDismiss()
      }
    #if os(macOS)
      .background(FullscreenKeyboardNavigation(
        isEnabled: true,
        previousColor: didSwipeLeft,
        nextColor: didSwipeRight
      ))
    #endif
  }
}

#if os(macOS)
private struct FullscreenKeyboardNavigation: NSViewRepresentable {
  let isEnabled: Bool
  let previousColor: () -> Void
  let nextColor: () -> Void

  func makeNSView(context: Context) -> KeyboardView {
    let view = KeyboardView()
    updateNSView(view, context: context)
    return view
  }

  func updateNSView(_ view: KeyboardView, context: Context) {
    view.isEnabled = isEnabled
    view.previousColor = previousColor
    view.nextColor = nextColor
  }

  static func dismantleNSView(_ view: KeyboardView, coordinator: ()) {
    view.removeMonitor()
  }

  final class KeyboardView: NSView {
    var isEnabled = false
    var previousColor: () -> Void = {}
    var nextColor: () -> Void = {}
    private var monitor: Any?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      removeMonitor()
      guard window != nil else { return }
      monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self, self.isEnabled,
              let window = self.window,
              event.window === window, window.isKeyWindow,
              window.attachedSheet == nil,
              !(window.firstResponder is NSTextView),
              event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty
        else { return event }

        switch event.keyCode {
        case 123:
          self.previousColor()
          return nil
        case 124:
          self.nextColor()
          return nil
        default:
          return event
        }
      }
    }

    func removeMonitor() {
      guard let monitor else { return }
      NSEvent.removeMonitor(monitor)
      self.monitor = nil
    }
  }
}
#endif

struct FullscreenColorView_Previews: PreviewProvider {
  static var previews: some View {
    ColorCard(model: ColorModel(
      date: "8", desc: "这是一种略带红色的浅黄色。温柔的自然色彩令人感到宁静。",
      hex: "#FFF4D9", kanji: "薄卵色", month: "3", ruby: "うすたまごいろ", series: "黄色"
    ))
  }
}

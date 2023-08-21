import SwiftUI
import SwiftUIOverlayContainer

struct Message<S: ShapeStyle>: View {
  enum MessageType: String {
    case success, error, normal
  }

  init(height: CGFloat, background: S, text: LocalizedStringKey, textColor: Color) {
    self.height = height
    self.background = background
    self.text = text
    self.textColor = textColor
  }

  init(text: LocalizedStringKey, type: MessageType, background: S = Color.backgroundColor, height: CGFloat) {
    switch type {
    case .success:
      self.textColor = Color.green
    case .error:
      self.textColor = Color.pink
    case .normal:
      self.textColor = Color.primary
    }
    self.height = height
    self.background = background
    self.text = text
  }

  let height: CGFloat
  let background: S
  let text: LocalizedStringKey
  let textColor: Color

  var body: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(background)
      .frame(maxWidth: 400)
      .frame(height: height)
      .padding(.horizontal, 20)
      .overlay(
        Text(text)
          .foregroundColor(textColor)
          .font(.headline)
          .monospacedDigit()
      )
  }
}

extension Message: ContainerViewConfigurationProtocol {
  var transition: AnyTransition? {
    .move(edge: .bottom).combined(with: .opacity)
  }

  var dismissGesture: ContainerViewDismissGesture? {
    .tap
  }
}

struct MessageView_Previews: PreviewProvider {
  static var previews: some View {
    Message(height: 50, background: .white, text: "Hello world", textColor: .blue)
      .previewLayout(.sizeThatFits)
  }
}

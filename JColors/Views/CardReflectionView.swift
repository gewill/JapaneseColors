import ColorfulX
import SwiftUI

struct CardReflectionView<Content: View>: View {
  @State var translation: CGSize = .zero
  @State var isDragging = false
  @State var colors: ColorfulPreset = .neon
  let content: Content

  // MARK: - life cycle

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content()
  }

  #if !os(tvOS)
    var drag: some Gesture {
      DragGesture()
        .onChanged { value in
          translation = value.translation
          isDragging = true
        }
        .onEnded { _ in
          withAnimation {
            translation = .zero
            isDragging = false
          }
        }
    }
  #endif

  var body: some View {
    ZStack {
      ColorfulView(color: $colors)
      #if os(tvOS)
        .frame(height: 300)
      #else
        .frame(height: 200)
        .frame(maxWidth: Constant.maxiPhoneScreenWidth)
      #endif
        .overlay(
          ZStack {
            content
          }
        )
        .cornerRadius(20)
        .scaleEffect(0.9)
        .rotation3DEffect(.degrees(isDragging ? 10 : 0), axis: (x: -translation.height, y: translation.width, z: 0))
      #if !os(tvOS)
        .gesture(drag)
      #endif
    }
  }
}

struct CardReflectionView_Previews: PreviewProvider {
  static var previews: some View {
    CardReflectionView(content: {
      Text("Logo")
        .font(.title)
        .foregroundColor(.white)
    })
    .padding()
  }
}

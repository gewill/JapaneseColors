import SwiftUI

struct CardReflectionView<Content: View>: View {
  @State var translation: CGSize = .zero
  @State var isDragging = false
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
      Image("Background 1")
        .resizable()
        .aspectRatio(contentMode: .fill)
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
        .overlay(LinearGradient(colors: [.clear, .white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: UnitPoint(x: abs(translation.height)/100+1, y: abs(translation.height)/100+1)))
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .strokeBorder(.linearGradient(colors: [.clear, .white.opacity(0.75), .clear, .white.opacity(0.75), .clear], startPoint: .topLeading, endPoint: UnitPoint(x: abs(translation.width)/100+0.5, y: abs(translation.height)/100+0.5)))
        )
        .overlay(
          LinearGradient(colors: [Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 0.5152369619)), Color(#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 0.5))], startPoint: .topLeading, endPoint: .bottomTrailing)
            .blendMode(.overlay)
        )
        .cornerRadius(20)
        .background(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.black)
            .offset(y: 50)
            .blur(radius: 50)
            .opacity(0.5)
            .blendMode(.overlay)
        )
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

import SwiftUI

extension View {
  @ViewBuilder
  func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content?) -> some View {
    if let view = transform(self), !(view is EmptyView) {
      view
    } else {
      self
    }
  }
  
  func afocusable(_ isFocusable: Bool = true) -> some View {
    #if os(tvOS)
      self.focusable(isFocusable)
    #else
      self
    #endif
  }
}

import SwiftUI
import SwiftUIOverlayContainer

struct ContainerConfigurationForQueueMessage: ContainerConfigurationProtocol {
  let queueType: ContainerViewQueueType = .multiple
  let displayType: ContainerViewDisplayType = .vertical
  var spacing: CGFloat = 10
  let alignment: Alignment? = .center
  let insets: EdgeInsets = .init(top: 20, leading: 0, bottom: 20, trailing: 0)
  let maximumNumberOfViewsInMultipleMode: UInt = 3
  let delayForShowingNext: TimeInterval = 0.5
  let autoDismiss: ContainerViewAutoDismiss? = .seconds(2)
}

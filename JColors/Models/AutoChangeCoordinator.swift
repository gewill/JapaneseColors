import Combine
import Foundation

// Selection and playback preferences are shared by WindowGroup instances.
// A single reservation prevents multiple active windows from advancing them twice.
@MainActor
final class AutoChangeCoordinator: ObservableObject {
  struct Reservation: Equatable {
    let viewID: UUID
    let token = UUID()
  }

  static let shared = AutoChangeCoordinator()
  @Published private(set) var owner: Reservation?
  @Published private(set) var nextChangeDate: Date?
  @Published private var pausedWindows: Set<UUID> = []

  var isPaused: Bool { !pausedWindows.isEmpty }

  func setPaused(_ paused: Bool, for viewID: UUID) {
    if paused {
      if !pausedWindows.contains(viewID) { pausedWindows.insert(viewID) }
    } else if pausedWindows.contains(viewID) {
      pausedWindows.remove(viewID)
    }
  }

  func acquire(for viewID: UUID) -> Reservation? {
    guard owner == nil || owner?.viewID == viewID else { return nil }
    let reservation = Reservation(viewID: viewID)
    owner = reservation
    return reservation
  }

  func scheduleNextChange(for reservation: Reservation, now: Date = .now) {
    if owner == reservation {
      nextChangeDate = now.addingTimeInterval(5)
    }
  }

  func release(_ reservation: Reservation) {
    if owner == reservation {
      owner = nil
      nextChangeDate = nil
    }
  }
}

import Foundation
import Observation

@MainActor
@Observable
final class AppWindowRouter {
  static let shared = AppWindowRouter()
  var pendingShow = false
  var refreshAction: (() -> Void)?

  private init() {}

  func showSettings() {
    pendingShow = true
  }
}

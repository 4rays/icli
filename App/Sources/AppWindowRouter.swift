import Foundation
import Observation

@MainActor
@Observable
final class AppWindowRouter {
    static let shared = AppWindowRouter()
    var pendingShow = false

    private init() {}

    func showSettings() {
        pendingShow = true
    }
}

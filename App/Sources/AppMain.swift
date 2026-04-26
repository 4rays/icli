import AppKit
import SwiftUI

@main
struct ICliApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.openSettings) private var openSettings
    let router = AppWindowRouter.shared

    var body: some Scene {
        Settings {
            AppSettingsView()
        }
        .windowResizability(.contentSize)
        .onChange(of: router.pendingShow) { _, pending in
            guard pending else { return }
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
            router.refreshAction?()
            router.pendingShow = false
        }
    }
}

import AppKit
import SwiftUI

@main
struct ICliApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.openWindow) private var openWindow
    @State private var router = AppWindowRouter.shared

    var body: some Scene {
        Window("iCLI Settings", id: "settings") {
            AppSettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 390)
        .restorationBehavior(.disabled)
        .onChange(of: router.pendingShow) { _, pending in
            guard pending else { return }
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .appSettingsShouldRefresh, object: nil)
            router.pendingShow = false
        }
    }
}

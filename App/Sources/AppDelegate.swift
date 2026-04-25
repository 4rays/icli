import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var server: AppServer?
    private var isAgentLaunch: Bool {
        CommandLine.arguments.contains("--icli-agent")
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let server = try AppServer(handler: AppRequestHandler())
            try server.start()
            self.server = server

            if !isAgentLaunch {
                showSettingsWindow()
            }
        } catch {
            presentFatalError(message: error.localizedDescription)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        server?.stop()
    }

    private func showSettingsWindow() {
        AppWindowRouter.shared.showSettings()
    }

    private func presentFatalError(message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "iCLI couldn't start"
        alert.informativeText = message
        alert.runModal()
        NSApp.terminate(nil)
    }
}

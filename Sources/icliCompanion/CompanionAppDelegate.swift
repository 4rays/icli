import AppKit
import Foundation

@MainActor
final class CompanionAppDelegate: NSObject, NSApplicationDelegate {
    private var server: CompanionServer?
    private var isAgentLaunch: Bool {
        CommandLine.arguments.contains("--icli-agent")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let server = try CompanionServer(handler: CompanionRequestHandler())
            try server.start()
            self.server = server

            if !isAgentLaunch {
                CompanionSettingsWindowController.shared.show()
            }
        } catch {
            presentFatalError(message: error.localizedDescription)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        CompanionSettingsWindowController.shared.show()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        server?.stop()
    }

    private func presentFatalError(message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "iCLI couldn’t start"
        alert.informativeText = message
        alert.runModal()
        NSApp.terminate(nil)
    }
}

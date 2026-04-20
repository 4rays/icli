import AppKit
import Foundation

@MainActor
final class CompanionAppDelegate: NSObject, NSApplicationDelegate {
    private var server: CompanionServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let server = try CompanionServer(handler: CompanionRequestHandler())
            try server.start()
            self.server = server
        } catch {
            presentFatalError(message: error.localizedDescription)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        server?.stop()
    }

    private func presentFatalError(message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "iCLI Companion couldn’t start"
        alert.informativeText = message
        alert.runModal()
        NSApp.terminate(nil)
    }
}

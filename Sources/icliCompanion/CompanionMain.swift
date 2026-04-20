import AppKit

@main
struct ICliCompanionMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = CompanionAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

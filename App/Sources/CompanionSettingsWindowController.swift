import AppKit
import Foundation

@MainActor
final class CompanionSettingsWindowController: NSWindowController {
    static let shared = CompanionSettingsWindowController()

    private let remindersStatusLabel = NSTextField(labelWithString: "Checking...")
    private let calendarsStatusLabel = NSTextField(labelWithString: "Checking...")
    private let remindersButton = NSButton(title: "Request Access", target: nil, action: nil)
    private let calendarsButton = NSButton(title: "Request Access", target: nil, action: nil)

    private var remindersStatus = "not-determined"
    private var calendarsStatus = "not-determined"

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 390),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "iCLI Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingContainerView()

        super.init(window: window)

        window.contentView = makeContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        refresh()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeContentView() -> NSView {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false

        content.addArrangedSubview(makeHeader())
        content.addArrangedSubview(makePermissionsSection())
        content.addArrangedSubview(makeFooter())

        root.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -28),
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: 26),
            content.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -22),
        ])

        return root
    }

    private func makeHeader() -> NSView {
        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),
        ])

        let title = NSTextField(labelWithString: "iCLI")
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = .labelColor

        let subtitle = NSTextField(wrappingLabelWithString: "A tiny local helper that lets the terminal talk to Reminders and Calendar with a real macOS app identity.")
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabelColor

        let textStack = NSStackView(views: [title, subtitle])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 4

        let row = NSStackView(views: [icon, textStack])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        return row
    }

    private func makePermissionsSection() -> NSView {
        let title = NSTextField(labelWithString: "Permissions")
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        remindersButton.target = self
        remindersButton.action = #selector(handleRemindersButton)
        calendarsButton.target = self
        calendarsButton.action = #selector(handleCalendarsButton)

        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshButtonPressed))
        refreshButton.bezelStyle = .rounded

        let rows = NSStackView()
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 10
        rows.addArrangedSubview(makePermissionRow(
            title: "Reminders",
            statusLabel: remindersStatusLabel,
            button: remindersButton
        ))
        rows.addArrangedSubview(makePermissionRow(
            title: "Calendars",
            statusLabel: calendarsStatusLabel,
            button: calendarsButton
        ))

        let stack = NSStackView(views: [title, rows, refreshButton])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        return stack
    }

    private func makePermissionRow(
        title: String,
        statusLabel: NSTextField,
        button: NSButton
    ) -> NSView {
        let name = NSTextField(labelWithString: title)
        name.font = .systemFont(ofSize: 14, weight: .medium)

        statusLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor

        button.bezelStyle = .rounded

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [name, statusLabel, spacer, button])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.widthAnchor.constraint(equalToConstant: 464),
            name.widthAnchor.constraint(equalToConstant: 92),
            statusLabel.widthAnchor.constraint(equalToConstant: 132),
        ])
        return row
    }

    private func makeFooter() -> NSView {
        let note = NSTextField(wrappingLabelWithString: "Closing this window keeps iCLI running in the background so terminal commands can continue using the local socket. Use Activity Monitor or make uninstall if you want to stop and remove it.")
        note.font = .systemFont(ofSize: 12)
        note.textColor = .tertiaryLabelColor
        return note
    }

    private func refresh() {
        let status = CompanionAuthorization.status()
        remindersStatus = status.reminders
        calendarsStatus = status.calendars
        update(label: remindersStatusLabel, button: remindersButton, status: remindersStatus)
        update(label: calendarsStatusLabel, button: calendarsButton, status: calendarsStatus)
    }

    private func update(label: NSTextField, button: NSButton, status: String) {
        label.stringValue = displayStatus(status)
        switch status {
        case "authorized":
            label.textColor = .systemGreen
            button.title = "Granted"
            button.isEnabled = false
        case "denied", "restricted", "write-only":
            label.textColor = .systemRed
            button.title = "Open System Settings"
            button.isEnabled = true
        default:
            label.textColor = .secondaryLabelColor
            button.title = "Request Access"
            button.isEnabled = true
        }
    }

    private func displayStatus(_ status: String) -> String {
        switch status {
        case "authorized": return "Granted"
        case "not-determined": return "Not requested"
        case "write-only": return "Write only"
        default: return status.capitalized
        }
    }

    @objc private func refreshButtonPressed() {
        refresh()
    }

    @objc private func handleRemindersButton() {
        if shouldOpenSystemSettings(for: remindersStatus) {
            openPrivacySettings(anchor: "Privacy_Reminders")
            return
        }

        request(reminders: true, calendars: false)
    }

    @objc private func handleCalendarsButton() {
        if shouldOpenSystemSettings(for: calendarsStatus) {
            openPrivacySettings(anchor: "Privacy_Calendars")
            return
        }

        request(reminders: false, calendars: true)
    }

    private func request(reminders: Bool, calendars: Bool) {
        remindersButton.isEnabled = false
        calendarsButton.isEnabled = false

        Task { @MainActor in
            _ = try? await CompanionAuthorization.request(AuthRequestArgs(
                reminders: reminders,
                calendars: calendars
            ))
            refresh()
        }
    }

    private func shouldOpenSystemSettings(for status: String) -> Bool {
        status == "denied" || status == "restricted" || status == "write-only"
    }

    private func openPrivacySettings(anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private final class NSHostingContainerView: NSView {
    override var isFlipped: Bool { true }
}

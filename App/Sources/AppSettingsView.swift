import AppKit
import SwiftUI

struct AppSettingsView: View {
  @State private var remindersStatus: AuthorizationStatus
  @State private var calendarsStatus: AuthorizationStatus

  private let refreshOnAppear: Bool

  init(
    remindersStatus: AuthorizationStatus = .notDetermined,
    calendarsStatus: AuthorizationStatus = .notDetermined,
    refreshOnAppear: Bool = true
  ) {
    _remindersStatus = State(initialValue: remindersStatus)
    _calendarsStatus = State(initialValue: calendarsStatus)
    self.refreshOnAppear = refreshOnAppear
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      header
      permissions
      footer
    }
    .padding(.horizontal, 28)
    .padding(.top, 26)
    .padding(.bottom, 22)
    .frame(width: 520, height: 390, alignment: .topLeading)
    .background(Color(nsColor: .windowBackgroundColor))
    .onAppear {
      guard refreshOnAppear else { return }
      refresh()
    }
    .onReceive(NotificationCenter.default.publisher(for: .appSettingsShouldRefresh)) { _ in
      refresh()
    }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 20) {
      Image("icon")
        .resizable()
        .scaledToFit()
        .frame(width: 56, height: 56)

      VStack(alignment: .leading, spacing: 4) {
        Text("iCLI")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(.primary)

        Text(
          "Command line interface for Apple Reminders and Calendar."
        )
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
      }
    }
  }

  private var permissions: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Text("App Access")
          .font(.system(size: 16, weight: .semibold))

        Spacer()

        Button(action: refresh) {
          Image(systemName: "arrow.clockwise")
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help("Refresh permission status")
        .accessibilityLabel("Refresh permission status")
      }
      .frame(width: 464)

      VStack(alignment: .leading, spacing: 10) {
        PermissionRow(
          title: "Reminders",
          status: remindersStatus,
          action: { handleRemindersButton() }
        )
        PermissionRow(
          title: "Calendar",
          status: calendarsStatus,
          action: { handleCalendarsButton() }
        )
      }
    }
  }

  private var footer: some View {
    Text(
      "You can close this window; iCLI keeps running locally so the CLI can reach the app when needed."
    )
    .font(.system(size: 12))
    .foregroundStyle(.tertiary)
  }

  private func refresh() {
    let status = AppAuthorization.status()
    remindersStatus = status.reminders
    calendarsStatus = status.calendars
  }

  private func handleRemindersButton() {
    if shouldOpenSystemSettings(for: remindersStatus) {
      openPrivacySettings(anchor: "Privacy_Reminders")
      return
    }
    request(reminders: true, calendars: false)
  }

  private func handleCalendarsButton() {
    if shouldOpenSystemSettings(for: calendarsStatus) {
      openPrivacySettings(anchor: "Privacy_Calendars")
      return
    }
    request(reminders: false, calendars: true)
  }

  private func request(reminders: Bool, calendars: Bool) {
    Task { @MainActor in
      do {
        _ = try await AppAuthorization.request(
          AuthRequestArgs(
            reminders: reminders,
            calendars: calendars
          ))
        keepWindowVisible()
        refresh()
        await refreshAfterPermissionSettles()
      } catch {
        refresh()
        presentRequestError(error)
      }
    }
  }

  private func refreshAfterPermissionSettles() async {
    try? await Task.sleep(nanoseconds: 300_000_000)
    keepWindowVisible()
    refresh()
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    keepWindowVisible()
    refresh()
  }

  private func keepWindowVisible() {
    NSApp.keyWindow?.makeKeyAndOrderFront(nil)
    NSApp.keyWindow?.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
  }

  private func presentRequestError(_ error: Error) {
    guard let window = NSApp.keyWindow else { return }
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "iCLI couldn't request access"
    alert.informativeText = error.localizedDescription
    alert.beginSheetModal(for: window) { _ in }
  }

  private func shouldOpenSystemSettings(for status: AuthorizationStatus) -> Bool {
    status == .denied || status == .restricted || status == .writeOnly
  }

  private func openPrivacySettings(anchor: String) {
    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)")
    else {
      return
    }
    NSWorkspace.shared.open(url)
  }
}

private struct PermissionRow: View {
  let title: String
  let status: AuthorizationStatus
  let action: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(title)
        .font(.system(size: 14, weight: .medium))
        .frame(width: 92, alignment: .leading)

      Text(displayStatus)
        .font(.system(size: 13, design: .monospaced))
        .foregroundStyle(statusColor)
        .frame(width: 132, alignment: .leading)

      Spacer()

      if status != .authorized {
        Button(buttonTitle, action: action)
          .buttonStyle(.bordered)
      }
    }
    .frame(width: 464)
  }

  private var buttonTitle: String {
    switch status {
    case .denied, .restricted, .writeOnly: return "Open Settings"
    default: return "Allow"
    }
  }

  private var displayStatus: String {
    switch status {
    case .authorized: return "Allowed"
    case .notDetermined: return "Needs approval"
    case .denied: return "Blocked"
    case .restricted: return "Restricted"
    case .writeOnly: return "Limited"
    default: return "Unknown"
    }
  }

  private var statusColor: Color {
    switch status {
    case .authorized: return .green
    case .denied, .restricted, .writeOnly: return .red
    default: return .secondary
    }
  }
}

extension Notification.Name {
  static let appSettingsShouldRefresh = Notification.Name("appSettingsShouldRefresh")
}

#Preview("Settings Window") {
  AppSettingsView(
    remindersStatus: .authorized,
    calendarsStatus: .notDetermined,
    refreshOnAppear: false
  )
}

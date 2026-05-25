import AppKit
import EventKit
import SwiftUI

struct AppSettingsView: View {
  @State private var remindersStatus: AuthorizationStatus
  @State private var calendarsStatus: AuthorizationStatus
  @State private var requestError: Error?

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
      AppWindowRouter.shared.refreshAction = refresh
      guard refreshOnAppear else { return }
      refresh()
    }
    .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
      refresh()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification))
    { _ in
      refresh()
    }
    .alert(
      "iCLI couldn't request access",
      isPresented: Binding(get: { requestError != nil }, set: { if !$0 { requestError = nil } })
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(requestError?.localizedDescription ?? "")
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
    // EKEventStore.authorizationStatus can return stale notDetermined in-process after a grant.
    // Never downgrade a live non-notDetermined status — that transition is impossible in TCC.
    if status.reminders != .notDetermined || remindersStatus == .notDetermined {
      remindersStatus = status.reminders
    }
    if status.calendars != .notDetermined || calendarsStatus == .notDetermined {
      calendarsStatus = status.calendars
    }
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
        let payload = try await AppAuthorization.request(
          AuthRequestArgs(
            reminders: reminders,
            calendars: calendars
          ))
        // Use the payload directly — EKEventStore.authorizationStatus can be stale
        // immediately after the grant dialog returns, but the request return value is fresh.
        if reminders { remindersStatus = payload.reminders }
        if calendars { calendarsStatus = payload.calendars }
        keepWindowVisible()
        await refreshAfterPermissionSettles()
      } catch {
        refresh()
        presentRequestError(error)
      }
    }
  }

  private func refreshAfterPermissionSettles() async {
    try? await Task.sleep(for: .milliseconds(300))
    keepWindowVisible()
    try? await Task.sleep(for: .seconds(1))
    keepWindowVisible()
  }

  private func keepWindowVisible() {
    // Permission dialog steals focus; re-assert window visibility
    NSApp.keyWindow?.makeKeyAndOrderFront(nil)
    NSApp.keyWindow?.orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
  }

  private func presentRequestError(_ error: Error) {
    requestError = error
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

#Preview("Settings Window") {
  AppSettingsView(
    remindersStatus: .authorized,
    calendarsStatus: .notDetermined,
    refreshOnAppear: false
  )
}

import Foundation

enum PermissionResetCommand {
  static func run(format: OutputFormat) throws {
    let bundleID = "net.4rays.icli"
    for service in ["Reminders", "Calendar"] {
      let p = Process()
      p.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
      p.arguments = ["reset", service, bundleID]
      try p.run()
      p.waitUntilExit()
    }

    switch format {
    case .human:
      print("Permissions reset. Relaunch iCLI, then run 'icli permission request'.")
    case .plain:
      print("reset\ttrue")
    case .json:
      print("{\"reset\":true}")
    }
  }
}

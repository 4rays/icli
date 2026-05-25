import Foundation

enum AuthSettingsCommand {
  static func run(format: OutputFormat) async throws {
    let _: EmptyArgs = try await AppClient.shared.send(.appShowSettings)

    switch format {
    case .human:
      print("Opened iCLI settings.")
    case .plain:
      print("opened\ttrue")
    case .json:
      print("{\"opened\":true}")
    }
  }
}

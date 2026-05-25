import Foundation

enum ReminderCompleteCommand {
  static func run(args: ParsedArgs, format: OutputFormat) async throws {
    let ids = args.positionals
    guard !ids.isEmpty else {
      throw ICLIError.missingArgument("id")
    }

    let result: CountPayload = try await AppClient.shared.send(
      .reminderComplete,
      args: ReminderIDsArgs(ids: ids)
    )

    switch format {
    case .human:
      print("Completed \(result.count) reminder(s).")
    case .plain:
      print(result.count)
    case .json:
      Output.printReminders([], format: .json)
    }
  }
}

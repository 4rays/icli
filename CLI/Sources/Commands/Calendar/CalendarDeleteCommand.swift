import Foundation

enum CalendarDeleteCommand {
  static func run(args: ParsedArgs, format: OutputFormat) async throws {
    guard let id = args.positionals.first else {
      throw ICLIError.missingArgument("id")
    }

    _ = try await AppClient.shared.send(
      .calendarDelete,
      args: CalendarDeleteArgs(id: id),
      as: CountPayload.self
    )

    switch format {
    case .human:
      print("Deleted event.")
    case .plain:
      print("1")
    case .json:
      let data = try! JSONEncoder().encode(["deleted": 1])
      print(String(data: data, encoding: .utf8)!)
    }
  }
}

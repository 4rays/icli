import Foundation

enum AuthStatusCommand {
    static func run(format: OutputFormat) async throws {
        let payload: AuthStatusPayload = try await AppClient.shared.send(.authStatus)
        Output.printAuthStatus(payload, format: format)
    }
}

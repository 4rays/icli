import Foundation

struct CompanionClient: Sendable {
    static let shared = CompanionClient()

    private init() {}

    func send<Response: Decodable, Args: Encodable>(
        _ operation: CompanionOperation,
        args: Args,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        try ensureCompanionAvailable()

        let request = CompanionRequestEnvelope(
            id: UUID().uuidString,
            op: operation.rawValue,
            args: try JSONValue.encode(args)
        )
        let requestData = try CompanionCodec.makeEncoder().encode(request)
        let responseData = try performRequestWithRetry(
            requestData,
            responseTimeout: responseTimeout(for: operation)
        )
        let response: CompanionResponseEnvelope
        do {
            response = try CompanionCodec.makeDecoder().decode(CompanionResponseEnvelope.self, from: responseData)
        } catch {
            let preview = String(data: responseData.prefix(500), encoding: .utf8) ?? "<non-UTF8 response>"
            throw ICLIError.operationFailed(
                "Companion returned an invalid response (\(responseData.count) bytes): \(preview)"
            )
        }

        guard response.ok else {
            let payload = response.error ?? CompanionErrorPayload(
                code: CompanionErrorCode.internalFailure.rawValue,
                message: "Companion request failed without an error payload."
            )
            throw ICLIError.operationFailed(payload.message)
        }

        guard let result = response.result else {
            throw ICLIError.operationFailed("Companion returned an empty response for \(operation.rawValue).")
        }

        return try result.decode(Response.self)
    }

    func send<Response: Decodable>(
        _ operation: CompanionOperation,
        as responseType: Response.Type = Response.self
    ) async throws -> Response {
        try await send(operation, args: EmptyArgs(), as: responseType)
    }

    private func ensureCompanionAvailable() throws {
        let fileManager = FileManager.default
        let socketPath = CompanionPaths.socketPath(fileManager: fileManager)
        try fileManager.createDirectory(
            at: CompanionPaths.supportDirectory(fileManager: fileManager),
            withIntermediateDirectories: true
        )

        if canConnect(socketPath: socketPath) {
            return
        }

        guard let appURL = CompanionLocator.companionAppURL(fileManager: fileManager) else {
            throw ICLIError.operationFailed(
                "iCLI app not found. Reinstall icli or set ICLI_COMPANION_APP to the app bundle path."
            )
        }

        try launchCompanion(at: appURL)

        let timeout = Date().addingTimeInterval(5)
        while Date() < timeout {
            if canConnect(socketPath: socketPath) {
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        throw ICLIError.operationFailed(
            "Companion app did not become available in time."
        )
    }

    private func launchCompanion(at appURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", appURL.path, "--args", "--icli-agent"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let detail = message.map { ": \($0)" } ?? "."
            throw ICLIError.operationFailed(
                "Failed to launch iCLI app with LaunchServices\(detail)"
            )
        }
    }

    private func canConnect(socketPath: String) -> Bool {
        do {
            let fd = try openSocket(at: socketPath)
            close(fd)
            return true
        } catch {
            return false
        }
    }

    private func responseTimeout(for operation: CompanionOperation) -> TimeInterval {
        switch operation {
        case .authRequest:
            return 300
        default:
            return 30
        }
    }

    private func performRequestWithRetry(
        _ data: Data,
        responseTimeout: TimeInterval
    ) throws -> Data {
        do {
            return try performRequest(data, responseTimeout: responseTimeout)
        } catch {
            Thread.sleep(forTimeInterval: 0.15)
            try ensureCompanionAvailable()
            return try performRequest(data, responseTimeout: responseTimeout)
        }
    }

    private func performRequest(_ data: Data, responseTimeout: TimeInterval) throws -> Data {
        let fileManager = FileManager.default
        let socketPath = CompanionPaths.socketPath(fileManager: fileManager)
        let fd = try openSocket(at: socketPath)
        defer { close(fd) }

        try UnixSocket.writeAll(data, to: fd)
        if shutdown(fd, SHUT_WR) < 0 {
            throw ICLIError.operationFailed("Failed to finalize companion request: \(String(cString: strerror(errno)))")
        }

        return try UnixSocket.readAll(from: fd, timeout: responseTimeout)
    }

    private func openSocket(at path: String) throws -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw ICLIError.operationFailed("Failed to create socket: \(String(cString: strerror(errno)))")
        }
        UnixSocket.disableSigPipe(fd)

        do {
            var (address, length) = try UnixSocket.makeAddress(for: path)
            let result = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    connect(fd, sockaddrPtr, length)
                }
            }

            if result < 0 {
                let error = errno
                close(fd)
                throw ICLIError.operationFailed("Failed to connect to companion socket: \(String(cString: strerror(error)))")
            }

            return fd
        } catch {
            close(fd)
            throw error
        }
    }
}

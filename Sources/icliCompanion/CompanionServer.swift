import Darwin
import Foundation

private final class ResponseBox: @unchecked Sendable {
    var value = Data()
}

final class CompanionServer {
    private let socketPath: String
    private let handler: CompanionRequestHandler
    private var listenFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?

    init(
        handler: CompanionRequestHandler,
        socketPath: String = CompanionPaths.socketPath()
    ) throws {
        self.handler = handler
        self.socketPath = socketPath
        try FileManager.default.createDirectory(
            at: CompanionPaths.supportDirectory(),
            withIntermediateDirectories: true
        )
    }

    func start() throws {
        unlink(socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw ICLIError.operationFailed("Failed to create companion socket: \(String(cString: strerror(errno)))")
        }

        do {
            var (address, length) = try UnixSocket.makeAddress(for: socketPath)
            let bindResult = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    bind(fd, sockaddrPtr, length)
                }
            }
            guard bindResult == 0 else {
                throw ICLIError.operationFailed("Failed to bind companion socket: \(String(cString: strerror(errno)))")
            }

            guard listen(fd, 16) == 0 else {
                throw ICLIError.operationFailed("Failed to listen on companion socket: \(String(cString: strerror(errno)))")
            }

            try UnixSocket.setNonBlocking(fd)

            let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: DispatchQueue.main)
            source.setEventHandler { [weak self] in
                self?.acceptPendingConnections()
            }
            source.setCancelHandler { [socketPath] in
                close(fd)
                unlink(socketPath)
            }
            source.resume()

            self.listenFD = fd
            self.acceptSource = source
        } catch {
            close(fd)
            throw error
        }
    }

    func stop() {
        acceptSource?.cancel()
        acceptSource = nil

        if listenFD >= 0 {
            close(listenFD)
            listenFD = -1
        }

        unlink(socketPath)
    }

    private func acceptPendingConnections() {
        while true {
            let clientFD = accept(listenFD, nil, nil)
            if clientFD >= 0 {
                UnixSocket.disableSigPipe(clientFD)
                handleConnection(fd: clientFD)
                continue
            }

            if errno == EWOULDBLOCK || errno == EAGAIN {
                break
            }

            break
        }
    }

    private func handleConnection(fd: Int32) {
        let handler = self.handler
        DispatchQueue.global(qos: .userInitiated).async {
            defer { close(fd) }

            do {
                let requestData = try UnixSocket.readAll(from: fd)
                if requestData.isEmpty {
                    return
                }
                let responseData = Self.awaitResponseData(handler: handler, requestData: requestData)
                try UnixSocket.writeAll(responseData, to: fd)
            } catch {
                let response = CompanionResponseEnvelope(
                    id: UUID().uuidString,
                    ok: false,
                    result: nil,
                    error: CompanionErrorPayload(
                        code: CompanionErrorCode.internalFailure.rawValue,
                        message: error.localizedDescription
                    )
                )
                if let data = try? CompanionCodec.makeEncoder().encode(response) {
                    try? UnixSocket.writeAll(data, to: fd)
                }
            }
        }
    }

    private static func awaitResponseData(
        handler: CompanionRequestHandler,
        requestData: Data
    ) -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        let box = ResponseBox()

        Task {
            let response = await makeResponseData(handler: handler, requestData: requestData)
            box.value = response
            semaphore.signal()
        }

        semaphore.wait()
        return box.value
    }

    private static func makeResponseData(
        handler: CompanionRequestHandler,
        requestData: Data
    ) async -> Data {
        do {
            let request = try CompanionCodec.makeDecoder().decode(CompanionRequestEnvelope.self, from: requestData)
            let response = await handler.handle(request)
            return try CompanionCodec.makeEncoder().encode(response)
        } catch {
            let response = CompanionResponseEnvelope(
                id: UUID().uuidString,
                ok: false,
                result: nil,
                error: CompanionErrorPayload(
                    code: CompanionErrorCode.validationFailed.rawValue,
                    message: error.localizedDescription
                )
            )
            return (try? CompanionCodec.makeEncoder().encode(response)) ?? Data()
        }
    }
}

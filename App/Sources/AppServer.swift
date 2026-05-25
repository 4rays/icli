import Darwin
import Foundation

private final class ResponseBox: @unchecked Sendable {
  var value = Data()
}

final class AppServer {
  private let socketPath: String
  private let handler: AppRequestHandler
  private var listenFD: Int32 = -1
  private var acceptSource: DispatchSourceRead?

  init(
    handler: AppRequestHandler,
    socketPath: String = AppPaths.socketPath()
  ) throws {
    self.handler = handler
    self.socketPath = socketPath
    try FileManager.default.createDirectory(
      at: AppPaths.supportDirectory(),
      withIntermediateDirectories: true
    )
  }

  func start() throws {
    unlink(socketPath)

    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    guard fd >= 0 else {
      throw ICLIError.operationFailed(
        "Failed to create app socket: \(String(cString: strerror(errno)))")
    }

    do {
      var (address, length) = try UnixSocket.makeAddress(for: socketPath)
      let bindResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
          bind(fd, sockaddrPtr, length)
        }
      }
      guard bindResult == 0 else {
        throw ICLIError.operationFailed(
          "Failed to bind app socket: \(String(cString: strerror(errno)))")
      }

      guard listen(fd, 16) == 0 else {
        throw ICLIError.operationFailed(
          "Failed to listen on app socket: \(String(cString: strerror(errno)))")
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
        // accept() inherits O_NONBLOCK from the listen socket on macOS;
        // clear it so blocking read/write work correctly on the client fd.
        let flags = fcntl(clientFD, F_GETFL)
        if flags >= 0 { _ = fcntl(clientFD, F_SETFL, flags & ~O_NONBLOCK) }
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
        let response = AppResponseEnvelope(
          id: UUID().uuidString,
          ok: false,
          result: nil,
          error: AppErrorPayload(
            code: AppErrorCode.internalFailure.rawValue,
            message: error.localizedDescription
          )
        )
        if let data = try? AppCodec.makeEncoder().encode(response) {
          try? UnixSocket.writeAll(data, to: fd)
        }
      }
    }
  }

  private static func awaitResponseData(
    handler: AppRequestHandler,
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
    handler: AppRequestHandler,
    requestData: Data
  ) async -> Data {
    do {
      let request = try AppCodec.makeDecoder().decode(AppRequestEnvelope.self, from: requestData)
      let response = await handler.handle(request)
      return try AppCodec.makeEncoder().encode(response)
    } catch {
      let response = AppResponseEnvelope(
        id: UUID().uuidString,
        ok: false,
        result: nil,
        error: AppErrorPayload(
          code: AppErrorCode.validationFailed.rawValue,
          message: error.localizedDescription
        )
      )
      return (try? AppCodec.makeEncoder().encode(response)) ?? Data()
    }
  }
}

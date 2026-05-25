import Darwin
import Foundation

public enum UnixSocketError: Error, LocalizedError {
  case pathTooLong(String)
  case systemCall(String, Int32)

  public var errorDescription: String? {
    switch self {
    case .pathTooLong(let path):
      return "Unix socket path is too long: \(path)"
    case .systemCall(let name, let code):
      return "\(name) failed (\(code)): \(String(cString: strerror(code)))"
    }
  }
}

public enum UnixSocket {
  public static func makeAddress(for path: String) throws -> (sockaddr_un, socklen_t) {
    var address = sockaddr_un()
    let pathOffset = MemoryLayout.offset(of: \sockaddr_un.sun_path)!
    address.sun_family = sa_family_t(AF_UNIX)
    #if canImport(Darwin)
      address.sun_len = UInt8(pathOffset + path.utf8CString.count)
    #endif

    let pathBytes = Array(path.utf8CString)
    let maxLength = MemoryLayout.size(ofValue: address.sun_path)
    guard pathBytes.count <= maxLength else {
      throw UnixSocketError.pathTooLong(path)
    }

    withUnsafeMutablePointer(to: &address) { addressPointer in
      let rawPointer = UnsafeMutableRawPointer(addressPointer)
        .advanced(by: pathOffset)
      rawPointer.initializeMemory(as: CChar.self, repeating: 0, count: maxLength)
      pathBytes.withUnsafeBytes { pathBuffer in
        if let baseAddress = pathBuffer.baseAddress {
          rawPointer.copyMemory(from: baseAddress, byteCount: pathBytes.count)
        }
      }
    }

    let length = socklen_t(pathOffset + pathBytes.count)
    return (address, length)
  }

  public static func setNonBlocking(_ fd: Int32) throws {
    let flags = fcntl(fd, F_GETFL)
    if flags < 0 {
      throw UnixSocketError.systemCall("fcntl(F_GETFL)", errno)
    }

    if fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0 {
      throw UnixSocketError.systemCall("fcntl(F_SETFL)", errno)
    }
  }

  public static func disableSigPipe(_ fd: Int32) {
    #if canImport(Darwin)
      var value: Int32 = 1
      setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &value, socklen_t(MemoryLayout<Int32>.size))
    #endif
  }

  public static func readAll(from fd: Int32) throws -> Data {
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)

    while true {
      let count = read(fd, &buffer, buffer.count)
      if count > 0 {
        data.append(buffer, count: count)
        continue
      }

      if count == 0 {
        return data
      }

      if errno == EINTR {
        continue
      }

      throw UnixSocketError.systemCall("read", errno)
    }
  }

  public static func readAll(from fd: Int32, timeout: TimeInterval) throws -> Data {
    let deadline = Date().addingTimeInterval(timeout)
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)

    while true {
      let remaining = deadline.timeIntervalSinceNow
      if remaining <= 0 {
        throw UnixSocketError.systemCall("read timeout", ETIMEDOUT)
      }

      var pollFD = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
      let timeoutMS = Int32(max(1, min(remaining * 1000, Double(Int32.max))))
      let pollResult = poll(&pollFD, 1, timeoutMS)

      if pollResult == 0 {
        throw UnixSocketError.systemCall("read timeout", ETIMEDOUT)
      }

      if pollResult < 0 {
        if errno == EINTR {
          continue
        }
        throw UnixSocketError.systemCall("poll", errno)
      }

      let count = read(fd, &buffer, buffer.count)
      if count > 0 {
        data.append(buffer, count: count)
        continue
      }

      if count == 0 {
        return data
      }

      if errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK {
        continue
      }

      throw UnixSocketError.systemCall("read", errno)
    }
  }

  public static func writeAll(_ data: Data, to fd: Int32) throws {
    try data.withUnsafeBytes { rawBuffer in
      guard let base = rawBuffer.baseAddress else { return }
      var bytesWritten = 0

      while bytesWritten < data.count {
        let pointer = base.advanced(by: bytesWritten)
        let count = write(fd, pointer, data.count - bytesWritten)
        if count > 0 {
          bytesWritten += count
          continue
        }

        if count < 0 && errno == EINTR {
          continue
        }

        throw UnixSocketError.systemCall("write", errno)
      }
    }
  }
}

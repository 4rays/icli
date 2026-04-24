import Darwin
import Foundation

public enum CompanionLocator {
    public static func companionAppURL(
        executableURL: URL = currentExecutableURL(),
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> URL? {
        if let override = environment["ICLI_COMPANION_APP"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let sibling = executableURL.deletingLastPathComponent()
            .appendingPathComponent(CompanionPaths.appBundleName, isDirectory: true)
        if fileManager.fileExists(atPath: sibling.path) {
            return sibling
        }

        return nil
    }

    public static func currentExecutableURL(
        fileManager: FileManager = .default
    ) -> URL {
        if let bundleExecutable = Bundle.main.executableURL {
            return bundleExecutable.resolvingSymlinksInPath().standardizedFileURL
        }

        var size: UInt32 = 0
        _ = _NSGetExecutablePath(nil, &size)
        if size > 0 {
            var buffer = [CChar](repeating: 0, count: Int(size))
            if _NSGetExecutablePath(&buffer, &size) == 0 {
                let path = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
                return URL(fileURLWithPath: String(decoding: path, as: UTF8.self))
                    .resolvingSymlinksInPath()
                    .standardizedFileURL
            }
        }

        let rawPath = CommandLine.arguments.first ?? "icli"
        let baseURL: URL
        if rawPath.hasPrefix("/") {
            baseURL = URL(fileURLWithPath: rawPath)
        } else {
            baseURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent(rawPath)
        }

        return baseURL.resolvingSymlinksInPath().standardizedFileURL
    }
}

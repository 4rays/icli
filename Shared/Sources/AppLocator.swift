import Darwin
import Foundation

public enum AppLocator {
    public static func appURL(
        executableURL: URL = currentExecutableURL(),
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> URL? {
        if let override = environment["ICLI_APP"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        if let containingApp = containingAppBundle(for: executableURL, fileManager: fileManager) {
            return containingApp
        }

        let sibling = executableURL.deletingLastPathComponent()
            .appendingPathComponent(AppPaths.appBundleName, isDirectory: true)
        if fileManager.fileExists(atPath: sibling.path) {
            return sibling
        }

        return nil
    }

    private static func containingAppBundle(
        for executableURL: URL,
        fileManager: FileManager
    ) -> URL? {
        var current = executableURL.standardizedFileURL

        while current.path != current.deletingLastPathComponent().path {
            if current.pathExtension == "app", fileManager.fileExists(atPath: current.path) {
                return current
            }
            current.deleteLastPathComponent()
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

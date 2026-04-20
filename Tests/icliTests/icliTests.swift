import Foundation
import Testing
@testable import ICliShared
@testable import icli

@Test func companionLocatorFindsSiblingAppBundle() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let binDir = root.appendingPathComponent("bin", isDirectory: true)
    let appDir = binDir.appendingPathComponent(CompanionPaths.appBundleName, isDirectory: true)

    try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

    let resolved = CompanionLocator.companionAppURL(
        executableURL: binDir.appendingPathComponent("icli"),
        environment: [:]
    )

    #expect(resolved?.path == appDir.path)
}

@Test func jsonValueRoundTripsAuthRequestArgs() throws {
    let args = AuthRequestArgs(reminders: true, calendars: false)
    let value = try JSONValue.encode(args)
    let decoded = try value.decode(AuthRequestArgs.self)
    #expect(decoded == args)
}

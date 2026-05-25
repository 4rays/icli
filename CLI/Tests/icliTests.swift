import Foundation
import Testing

@testable import Shared

@Test func appLocatorFindsSiblingAppBundle() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  let binDir = root.appendingPathComponent("bin", isDirectory: true)
  let appDir = binDir.appendingPathComponent(AppPaths.appBundleName, isDirectory: true)

  try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

  let resolved = AppLocator.appURL(
    executableURL: binDir.appendingPathComponent("icli"),
    environment: [:]
  )

  #expect(resolved?.path == appDir.path)
}

@Test func appLocatorFindsContainingAppBundle() throws {
  let root = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
  let appDir = root.appendingPathComponent(AppPaths.appBundleName, isDirectory: true)
  let binDir =
    appDir
    .appendingPathComponent("Contents", isDirectory: true)
    .appendingPathComponent("Resources", isDirectory: true)
    .appendingPathComponent("bin", isDirectory: true)
  let executable = binDir.appendingPathComponent("icli")

  try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)
  FileManager.default.createFile(atPath: executable.path, contents: Data())

  let resolved = AppLocator.appURL(
    executableURL: executable,
    environment: [:]
  )

  #expect(resolved?.path == appDir.path)
}

@Test func appLocatorHonorsEnvironmentOverride() throws {
  let override = "/Applications/iCLI-dev.app"

  let resolved = AppLocator.appURL(
    executableURL: URL(fileURLWithPath: "/tmp/icli"),
    environment: ["ICLI_APP": override]
  )

  #expect(resolved?.path == override)
}

@Test func jsonValueRoundTripsAuthRequestArgs() throws {
  let args = AuthRequestArgs(reminders: true, calendars: false)
  let value = try JSONValue.encode(args)
  let decoded = try value.decode(AuthRequestArgs.self)
  #expect(decoded == args)
}

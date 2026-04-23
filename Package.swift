// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "icli",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "Shared",
            path: "Shared/Sources"
        ),
        .executableTarget(
            name: "icli",
            dependencies: ["Shared"],
            path: "CLI/Sources",
            exclude: [
                "Core/CalendarsStore.swift",
                "Core/DateParsing.swift",
                "Core/Models.swift",
                "Core/RemindersStore.swift",
                "Resources/Info.plist",
            ]
        ),
        .executableTarget(
            name: "icliCompanion",
            dependencies: ["Shared"],
            path: "App/Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("EventKit"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "App/Resources/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "icliTests",
            dependencies: ["icli", "Shared"],
            path: "CLI/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

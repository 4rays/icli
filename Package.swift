// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "icli",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "ICliShared",
            path: "Sources/ICliShared"
        ),
        .executableTarget(
            name: "icli",
            dependencies: ["ICliShared"],
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
            dependencies: ["ICliShared"],
            path: "Sources/icliCompanion",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("EventKit"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/icliCompanion/Resources/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "icliTests",
            dependencies: ["icli", "ICliShared"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

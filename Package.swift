// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "icli",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "icli",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .linkedFramework("EventKit"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/icli/Resources/Info.plist",
                ]),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

import ProjectDescription

extension Project {
    public static func framework(
        name: String,
        reverseDomain: String = teamReverseDomain
    ) -> Project {
        .init(
            name: name,
            settings: projectSettings,
            targets: [
                .target(
                    name: name,
                    destinations: .destinations,
                    product: .framework,
                    bundleId: "\(reverseDomain).\(name)",
                    deploymentTargets: .platforms,
                    sources: ["Sources/**"],
                    settings: .settings(
                        base: [
                            "DEFINES_MODULE": "YES",
                            "SWIFT_VERSION": "6.0",
                        ]
                    )
                )
            ]
        )
    }

    public static func commandLineTool(
        name: String,
        bundleId: String,
        dependencies: [TargetDependency] = [],
        sources: SourceFilesList = ["Sources/**"]
    ) -> Project {
        .init(
            name: name,
            settings: projectSettings,
            targets: [
                .target(
                    name: name,
                    destinations: .destinations,
                    product: .commandLineTool,
                    bundleId: bundleId,
                    deploymentTargets: .platforms,
                    sources: sources,
                    dependencies: dependencies,
                    settings: .settings(
                        base: [
                            "PRODUCT_NAME": .string(name),
                            "SWIFT_VERSION": "6.0",
                        ]
                    )
                ),
                .target(
                    name: "\(name)Tests",
                    destinations: .destinations,
                    product: .unitTests,
                    bundleId: "\(teamReverseDomain).\(name)Tests",
                    deploymentTargets: .platforms,
                    sources: ["Tests/**"],
                    dependencies: [.target(name: name)] + dependencies,
                    settings: .settings(
                        base: [
                            "SWIFT_VERSION": "6.0",
                        ]
                    )
                ),
            ],
            schemes: [
                .scheme(
                    name: name,
                    shared: true,
                    buildAction: .buildAction(targets: [TargetReference(stringLiteral: name)]),
                    testAction: .targets(["\(name)Tests"]),
                    runAction: .runAction(
                        configuration: "Debug",
                        executable: TargetReference(stringLiteral: name)
                    ),
                    archiveAction: .archiveAction(configuration: "Release"),
                    profileAction: .profileAction(
                        configuration: "Release",
                        executable: TargetReference(stringLiteral: name)
                    ),
                    analyzeAction: .analyzeAction(configuration: "Debug")
                )
            ]
        )
    }

    public static var projectSettings: Settings {
        .settings(
            configurations: [
                .debug(name: "Debug", xcconfig: .relativeToRoot("Configs/Debug.xcconfig")),
                .release(name: "Release", xcconfig: .relativeToRoot("Configs/Release.xcconfig")),
            ]
        )
    }
}

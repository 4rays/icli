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
                    product: .staticFramework,
                    bundleId: "\(reverseDomain).\(name)",
                    deploymentTargets: .platforms,
                    buildableFolders: [
                        .folder("Sources"),
                    ],
                    settings: .settings(
                        base: [
                            "DEFINES_MODULE": "YES",
                            "DEVELOPMENT_TEAM": .string(teamID),
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
        buildableFolders: [BuildableFolder] = [
            .folder("Sources"),
        ]
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
                    buildableFolders: buildableFolders,
                    dependencies: dependencies,
                    settings: .settings(
                        base: [
                            "DEFINES_MODULE": "YES",
                            "DEVELOPMENT_TEAM": .string(teamID),
                            "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path",
                            "PRODUCT_NAME": .string(name),
                            "SKIP_INSTALL": "YES",
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
                    buildableFolders: [
                        .folder("Tests"),
                    ],
                    dependencies: dependencies,
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

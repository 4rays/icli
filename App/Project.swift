import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "App",
    settings: Project.projectSettings,
    targets: [
        .target(
            name: appTarget.targetName,
            destinations: .destinations,
            product: .app,
            bundleId: "\(teamReverseDomain).icli",
            deploymentTargets: .platforms,
            infoPlist: .file(path: "Resources/Info.plist"),
            sources: ["Sources/**"],
            resources: [
                "Resources/AppIcon.icon",
            ],
            entitlements: .file(path: .relativeToRoot("icli.entitlements")),
            dependencies: [
                .project(target: "Shared", path: .relativeToRoot("Shared")),
                .sdk(name: "AppKit", type: .framework),
                .sdk(name: "EventKit", type: .framework),
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "CODE_SIGN_STYLE": "Automatic",
                    "PRODUCT_NAME": "iCLI",
                    "SWIFT_VERSION": "6.0",
                ]
            )
        )
    ],
    schemes: [
        .scheme(
            name: appTarget.targetName,
            shared: true,
            buildAction: .buildAction(targets: [appTarget]),
            runAction: .runAction(
                configuration: "Debug",
                executable: appTarget
            ),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(
                configuration: "Release",
                executable: appTarget
            ),
            analyzeAction: .analyzeAction(configuration: "Debug")
        )
    ]
)

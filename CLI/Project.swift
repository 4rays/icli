import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.commandLineTool(
    name: cliTarget.targetName,
    bundleId: "\(teamReverseDomain).icli.cli",
    dependencies: [
        .project(target: "Shared", path: .relativeToRoot("Shared")),
    ],
    sources: [
        "Sources/CommandRouter.swift",
        "Sources/icli.swift",
        "Sources/Commands/**",
        "Sources/Core/CompanionClient.swift",
        "Sources/Core/Imports.swift",
        "Sources/Core/Output.swift",
        "Sources/Core/ParsedArgs.swift",
    ]
)

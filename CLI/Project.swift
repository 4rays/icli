import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.commandLineTool(
  name: cliTarget.targetName,
  bundleId: "\(teamReverseDomain).icli.cli",
  dependencies: [
    .project(target: "Shared", path: .relativeToRoot("Shared"))
  ],
  buildableFolders: [
    .folder("Sources")
  ]
)

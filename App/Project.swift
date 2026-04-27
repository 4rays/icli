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
      infoPlist: "Info.plist",
      buildableFolders: [
        .folder("Sources"),
        .folder("Resources")
      ],
      entitlements: .file(path: .relativeToRoot("icli.entitlements")),
      scripts: [
        .post(
          script: """
          set -e
          DEST="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Resources/bin"
          mkdir -p "$DEST"
          cp "$BUILT_PRODUCTS_DIR/icli" "$DEST/icli"
          """,
          name: "Embed CLI Binary",
          inputPaths: ["$(BUILT_PRODUCTS_DIR)/icli"],
          outputPaths: ["$(BUILT_PRODUCTS_DIR)/$(CONTENTS_FOLDER_PATH)/Resources/bin/icli"]
        )
      ],
      dependencies: [
        .project(target: "Shared", path: .relativeToRoot("Shared")),
        .project(target: "icli", path: .relativeToRoot("CLI")),
        .sdk(name: "AppKit", type: .framework),
        .sdk(name: "EventKit", type: .framework)
      ],
      settings: .settings(
        base: [
          "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
          "CODE_SIGN_STYLE": "Automatic",
          "DEVELOPMENT_TEAM": .string(teamID),
          "PRODUCT_NAME": "iCLI",
          "SWIFT_VERSION": "6.0"
        ],
        configurations: [
          .debug(name: "Debug", settings: [
            "CODE_SIGN_IDENTITY": "Apple Development",
          ]),
          .release(name: "Release", settings: [
            "CODE_SIGN_IDENTITY": "Developer ID Application",
            "ENABLE_HARDENED_RUNTIME": "YES",
          ]),
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

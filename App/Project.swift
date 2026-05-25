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
            CLI="$OBJROOT/UninstalledProducts/$PLATFORM_NAME/icli"
            if [ ! -f "$CLI" ]; then
              CLI="$BUILT_PRODUCTS_DIR/icli"
            fi
            DEST="$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH/Resources/bin"
            mkdir -p "$DEST"
            cp "$CLI" "$DEST/icli"
            """,
          name: "Embed CLI Binary",
          inputPaths: [
            "$(OBJROOT)/UninstalledProducts/$(PLATFORM_NAME)/icli",
            "$(BUILT_PRODUCTS_DIR)/icli"
          ],
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
          .debug(
            name: "Debug",
            settings: [
              "CODE_SIGN_IDENTITY": "Apple Development"
            ]),
          .release(
            name: "Release",
            settings: [
              "CODE_SIGN_IDENTITY": "Developer ID Application",
              "CODE_SIGN_STYLE": "Manual",
              "DEVELOPMENT_TEAM": "RGS98ZRDY6",
              "ENABLE_HARDENED_RUNTIME": "YES",
              "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
              "PROVISIONING_PROFILE_SPECIFIER": ""
            ])
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

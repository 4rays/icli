# TODO

## Homebrew Cask Distribution

- Ship end-user releases as a signed and notarized macOS app bundle, not as a bare CLI formula.
- Make `iCLI.app` the canonical release artifact and bundle the CLI inside it, for example:

  ```text
  iCLI.app
    Contents/MacOS/icliCompanion
    Contents/Resources/bin/icli
  ```

- Publish release archives from GitHub, for example `iCLI-0.1.0.zip`.
- Distribute through a Homebrew Cask so the app bundle is installed normally and the CLI is exposed via a `binary` stanza.

  ```ruby
  cask "icli" do
    version "0.1.0"
    sha256 "..."

    url "https://github.com/4rays/icli/releases/download/v#{version}/iCLI-#{version}.zip"
    name "iCLI"
    desc "Calendar and Reminders CLI for macOS"
    homepage "https://github.com/4rays/icli"

    app "iCLI.app"
    binary "#{appdir}/iCLI.app/Contents/Resources/bin/icli", target: "icli"
  end
  ```

- Keep the local `make install` path as a developer convenience only.
- Ensure the CLI can discover the companion app both from the local dev install layout and from the Homebrew Cask app layout.
- Keep the app bundle identifier stable as `net.4rays.icli` so TCC permissions attach to the signed app identity.

# TODO

## Homebrew Cask Distribution

- Ship end-user releases as a signed and notarized macOS app bundle, not as a bare CLI formula.
- Make `iCLI.app` the canonical release artifact and bundle the CLI inside it, for example:

  ```text
  iCLI.app
    Contents/MacOS/iCLI
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
- Ensure the CLI can discover the app both from the local dev install layout and from the Homebrew Cask app layout.
- Keep the app bundle identifier stable as `net.4rays.icli` so TCC permissions attach to the signed app identity.

## DMG Distribution (Non-Homebrew Users)

- Offer a signed DMG as a secondary artifact alongside the zip — same app bundle, different container.
- DMG alone leaves CLI-in-PATH unsolved; app should offer to install the CLI on first launch:
  - Show a one-time prompt: "Install `icli` command-line tool to `/usr/local/bin`?"
  - Requires `SMJobBless` or a privileged helper, or write to `~/.local/bin` (no sudo needed, but user must have it in PATH)
  - Alternative: include an `Install CLI.command` script in the DMG for users who decline the prompt
- GitHub Releases should publish both `iCLI-{version}.zip` (for Cask) and `iCLI-{version}.dmg` (for direct download).

## Pre-Distribution Checklist

- [ ] Code sign app and CLI with Developer ID
- [ ] Notarize and staple
- [ ] CI pipeline builds release artifacts on tag push
- [ ] Homebrew tap repository set up (e.g. `4rays/homebrew-tap`)
- [ ] Version scheme decided (semver recommended)
- [ ] TCC entitlements verified on clean machine (Calendars, Reminders)

# iCLI

A command-line interface for macOS Calendar and Reminders, backed by a sandboxed app that holds the necessary TCC permissions.

## How it works

`icli` is a thin CLI that communicates with a companion macOS app (`iCLI.app`) over a local Unix socket. The app holds Calendar and Reminders entitlements; the CLI forwards commands to it and prints the results.

## Skills (Optional)

npx skills add https://github.com/4rays/xbridge

## Prerequisites

- **macOS 14 (Sonoma) or later**
- **Xcode 16 or later** — required to build the project
- **Tuist** — used to generate the Xcode workspace

  ```sh
  brew install tuist
  ```

- **`~/.local/bin` in your PATH** — the default install prefix; add the following to your shell profile if needed:

  ```sh
  export PATH="$HOME/.local/bin:$PATH"
  ```

## Install

Install via Homebrew:

```sh
brew install --cask 4rays/tap/icli
```

Build and install from source:

```sh
make install
```

This generates the workspace, builds both the app and CLI, then installs them to `~/.local/lib/icli/` with a symlink at `~/.local/bin/icli`.

On first run, macOS will prompt for Calendar and Reminders access. Grant both.

## Usage

```sh
icli calendar <subcommand>
icli reminder <subcommand>
```

## Uninstall

```sh
make uninstall
```

## Development

Generate the Xcode workspace first:

```sh
tuist generate --no-open
```

```sh
make generate   # regenerate Xcode workspace via Tuist
make build      # build without installing
make reset      # kill app, remove socket, reset TCC permissions
make clean      # delete derived data
```

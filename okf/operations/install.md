---
type: Playbook
title: Install
description: Install the icli CLI and iCLI.app from source, or via the Homebrew cask named in the README.
tags: [playbook, install]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:08:47Z }
sources:
  - id: readme
    resource: /Users/kaishin/Developer/Spikes/icli/icli/README.md
    title: README
  - id: makefile
    resource: /Users/kaishin/Developer/Spikes/icli/icli/Makefile
    title: Makefile
  - id: todo
    resource: /Users/kaishin/Developer/Spikes/icli/icli/TODO.md
    title: TODO
---

# From source

Prerequisites named in the README: macOS 14 or later, Xcode 16 or later, Tuist (`brew install tuist`), and `~/.local/bin` on `PATH`.[^readme]

`make install` generates the workspace, builds the `iCLI` and `icli` schemes in Release, then:[^makefile]

1. Kills a process named `iCLI`.
2. Removes `~/Library/Application Support/icli/icli.sock`.
3. Installs the CLI to `~/.local/lib/icli/icli`.
4. Copies `iCLI.app` to `~/.local/lib/icli/iCLI.app`.
5. Symlinks `~/.local/bin/icli` to that CLI.

`PREFIX`, `BINDIR`, and `LIBEXECDIR` override those paths. `make uninstall` kills the app, removes the socket, the symlink, and `$(LIBEXECDIR)`.[^makefile]

# Homebrew

The README gives `brew install --cask 4rays/tap/icli`.[^readme]

`TODO.md` says the intended release artifact is a signed `iCLI.app` with the CLI at `Contents/Resources/bin/icli`, published as `iCLI-<version>.zip`, and installed by a cask `binary` stanza. The checklist items for signing, notarization, CI, and the tap are unchecked. Treat that file as a plan, not as proof the cask exists.[^todo]

# Related

- [Runtime](/architecture/runtime.md)
- [Reset runtime](/operations/reset-runtime.md)

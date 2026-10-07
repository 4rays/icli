---
type: CLI
title: CLI surface
description: Top-level icli groups, aliases, global flags, and the three output formats.
tags: [cli, commands]
status: draft
generated: { by: grok/okf, at: 2026-10-07T09:40:00Z }
sources:
  - id: router
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/CommandRouter.swift
    title: CommandRouter
  - id: output
    resource: /Users/kaishin/Developer/Spikes/icli/icli/CLI/Sources/Core/Output.swift
    title: Output
  - id: skill
    resource: /Users/kaishin/Developer/Spikes/icli/icli/skills/cli/SKILL.md
    title: Agent skill
---

# Invocation

```
icli <group> <command> [options]
```

Global `--format` or `-f` is removed before routing. Accepted values are `human`, `json`, and `plain`. The default is `human`. Unknown format strings fall through to `human` because the parser uses a failable initializer.[^router][^output]

Empty args, `--help`, and `-h` print help and exit 0. `--version` and `-v` print `icli 0.2.4` and exit 0. Unknown groups print an error and help, then exit 1. Thrown errors print `Error: ...` to stderr and exit 1.[^router]

# Groups

| Group | Aliases | Role |
| --- | --- | --- |
| `reminder` | `reminders`, `r` | Apple Reminders |
| `calendar` | `calendars`, `cal`, `c` | Apple Calendar events |
| `permission` | `p` | Request or reset TCC access |
| `status` | none | Print permission status |
| `settings` | none | Open the iCLI settings window |

There is no `auth` group. `skills/cli/SKILL.md` documents the same groups as the router, including top-level `settings`.[^router][^skill]

# Output

Human output is formatted text. JSON output uses pretty-printed, sorted-key JSON with ISO 8601 dates. Plain output is tab-separated and documented per command.[^output]

`ICLI_DEBUG_APP=1` adds app diagnostics to human and JSON auth status. Plain auth status never includes them.[^output]

# Related

- [Reminder commands](/commands/reminder.md)
- [Calendar commands](/commands/calendar.md)
- [Permission commands](/commands/permission.md)

# Directory Update Log

## 2026-10-07

* **Update**: Closed the open questions against the current sources. Marketing version is `0.2.4` in both `App/Info.plist` and `icli --version`. Named calendar create throws `calendarNotFound` instead of falling back to the default calendar. Reminder-list and calendar title matching are both case- and diacritic-insensitive. `skills/cli/SKILL.md` remains the distributed agent guide and now matches the CLI.
* **Initialization**: Created the OKF bundle from repository sources. There is no database, analytics definition, dashboard, or commercial metric in this repo.
* **Decision**: Treat `CLI/Sources` and `App/Sources` as authoritative for command names and behavior. Keep `skills/cli/SKILL.md` aligned with that contract because it is the in-repo agent guide.

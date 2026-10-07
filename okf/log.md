# Directory Update Log

## 2026-10-07

* **Creation**: Added the [Accessibility and computer-use broker plan](/architecture/accessibility-broker.md), covering app-owned permissions, native UI inspection, input and screenshots, broker access controls, replay safety, and acceptance criteria.
* **Questions for maintainers**: Should computer-use access be available to every same-user process or only approved clients/sessions? What control-session contract should serialize multi-client workflows? Should UI mutations use request-ID deduplication or return outcome-unknown without automatic retries? The proposed command names and macOS permission attribution remain to be validated before implementation.
* **Update**: Closed the open questions against the current sources. Marketing version is `0.2.4` in both `App/Info.plist` and `icli --version`. Named calendar create throws `calendarNotFound` instead of falling back to the default calendar. Reminder-list and calendar title matching are both case- and diacritic-insensitive. `skills/cli/SKILL.md` remains the distributed agent guide and now matches the CLI.
* **Initialization**: Created the OKF bundle from repository sources. There is no database, analytics definition, dashboard, or commercial metric in this repo.
* **Decision**: Treat `CLI/Sources` and `App/Sources` as authoritative for command names and behavior. Keep `skills/cli/SKILL.md` aligned with that contract because it is the in-repo agent guide.

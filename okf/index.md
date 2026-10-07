---
okf_version: "0.2"
---

# iCLI

Local macOS command-line interface for Apple Reminders and Calendar. The CLI does not hold TCC permissions; a companion app does, and the two talk over a Unix socket.

# Product

* [iCLI](product/icli.md) - macOS CLI and companion app for Reminders and Calendar

# Architecture

* [Runtime](architecture/) - process split, IPC, and app discovery

# Models

* [Domain models](models/) - reminder, calendar, and authorization types exchanged over IPC

# Commands

* [CLI surface](commands/) - groups, flags, output formats, and wire operations

# Operations

* [Playbooks](operations/) - install, permissions, and local reset

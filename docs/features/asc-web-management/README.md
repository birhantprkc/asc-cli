---
description: Design notes for the original bundled browser console (asc web) that ran asc commands through a local server. Use when working on the web console's pages, inline editing or command-execution security.
---

# Web Console

A browser dashboard for App Store Connect: pick an app, browse releases, builds, TestFlight, reviews, IAPs, subscriptions, code signing, Xcode Cloud and team, and edit fields such as "What's New" inline. Each action runs a real `asc` command through a local server, and buttons follow the same state-aware affordances as the CLI (for example, "Submit for Review" only appears when the version is editable).

The `asc web` command described in the design notes is not in the current [command reference](../../commands.md); the local server is now `asc web-server` (port 8420 by default, `--port` to change it). For the browser apps you can use today, see [Web Apps](../web-apps/README.md).

## See also

[Design notes](design.md) · [Web Apps](../web-apps/README.md) · [REST API](../rest-api/README.md) · [Web server architecture](../web-server-architecture/README.md)

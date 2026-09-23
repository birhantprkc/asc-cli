---
description: Browser interfaces for asc, a visual Command Center and a terminal-style Console, backed by a local asc web-server. Use when you want to browse or run asc commands from a browser.
---

# Web Apps

Two browser-based interfaces for `asc`: the **Command Center** ([cc.asccli.app](https://cc.asccli.app/)) for visual management and the **Console** ([asccli.app/console](https://asccli.app/console)) for terminal-style command execution with clickable affordances.
Start the local server with `asc web-server` (port 8420 by default, `--port` to change it) and open either app; it detects the local server and runs real `asc` commands through it. Without a server, both apps fall back to mock mode with demo data.
Every flag: [command reference](../../commands.md#asc-web-server).

## See also

[Design notes](design.md) · [Web server architecture](../web-server-architecture/README.md) · [REST API](../rest-api/README.md) · [Command Center (React)](../command-center-react/README.md)

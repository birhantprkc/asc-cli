---
description: How asc web-server bridges the browser UI and the CLI, loads plugins and serves HTTPS. Use when running the local server for asccli.app or building a server plugin.
---

# Web Server Architecture

`asc web-server` is a single-binary Swift HTTP/WebSocket server (Hummingbird) on `localhost:8420` that the browser UI on `asccli.app` talks to. Every flag: [command reference](../../commands.md#asc-web-server).
It runs CLI commands for the browser (`POST /api/run`), lists simulators and installed plugins, and serves plugin UI files.
Plugins in `~/.asc/plugins/` can add their own routes (e.g. simulator control from ASC Pro) and affordances.
A self-signed certificate is generated at `~/.asc/server.{key,crt}` and trusted in the macOS Keychain; HTTPS listens on port 8421 so the HTTPS-hosted UI can reach it.

## See also
[Design notes](design.md) · [REST API](../rest-api/README.md) · [Plugins](../plugins/README.md) · [Command Center (React)](../command-center-react/README.md)

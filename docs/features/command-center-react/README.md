---
description: Design notes for the React + Vite + TypeScript rewrite of the Command Center web UI. Use when working on apps/asc-web/command-center or writing a plugin page for it.
---

# Command Center (React)

The Command Center is the browser UI in `apps/asc-web/command-center` (hosted at cc.asccli.app). It talks to the local `asc web-server` backend, which also exposes the REST API.
This folder holds the design for moving it from vanilla HTML/JS to React + Vite + TypeScript, organised as one self-contained folder per domain feature, with plugins able to contribute pages, widgets and sidebar items.
Nothing changes for CLI or REST users: the backend, the `/api/v1` routes and the `console/` app stay as they are.

## See also
[Design notes](design.md) · [Web server architecture](../web-server-architecture/README.md) · [REST API](../rest-api/README.md) · [Plugins](../plugins/README.md)

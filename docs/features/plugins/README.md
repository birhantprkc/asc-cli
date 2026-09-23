---
description: List, install, uninstall, and update compiled asc plugins that add commands, server routes, UI, and affordances. Use when extending asc with marketplace plugins such as ASC Pro.
---

# Plugins

Plugins are compiled `.plugin` bundles that extend asc with CLI commands, server routes, web UI, and extra affordances. They live in `~/.asc/plugins/` and are loaded at startup. Every flag: [command reference](../../commands.md#asc-plugins).

## Quick start
```bash
asc plugins market search --query hello
asc plugins install --name asc-pro
asc plugins list --pretty
```

## Workflows

### Find and install
Browsing the marketplace is covered in [Plugin Market](../market/README.md).
```bash
asc plugins market list
asc plugins market search --query <text>
asc plugins install --name asc-pro
asc plugins uninstall --name ASCPro
```

### Keep plugins up to date
`updates` pairs each installed plugin with the latest marketplace version (Sparkle appcast style); `update` reinstalls the latest and returns the new plugin record.
```bash
asc plugins updates --pretty
asc plugins update --name Hello
```

```json
{
  "data": [
    {
      "name": "Hello",
      "installedVersion": "1.0.0",
      "latestVersion": "1.2.0",
      "affordances": {
        "list": "asc plugins updates",
        "update": "asc plugins update --name Hello"
      }
    }
  ]
}
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/plugins` | `asc plugins list` |
| POST | `/api/v1/plugins` (body `{ "name": "X" }`) | `asc plugins install --name X` |
| DELETE | `/api/v1/plugins/:name` (returns `204`) | `asc plugins uninstall --name X` |
| GET | `/api/v1/plugins/market` | `asc plugins market list` |
| GET | `/api/v1/plugins/market?q=Q` | `asc plugins market search --query Q` |
| GET | `/api/v1/plugins/updates` | `asc plugins updates` |
| POST | `/api/v1/plugins/:name/update` | `asc plugins update --name X` |

```bash
curl -X POST http://localhost:8420/api/v1/plugins \
  -H 'content-type: application/json' -d '{"name":"asc-pro"}'      # marketplace id
curl "http://localhost:8420/api/v1/plugins/market?q=hello"
curl -X DELETE http://localhost:8420/api/v1/plugins/ASCPro              # installed folder name
curl http://localhost:8420/api/v1/plugins/updates
curl -X POST http://localhost:8420/api/v1/plugins/ASCPro/update
```

## Gotchas
- `update` is uninstall + reinstall of the latest marketplace version, not an in-place patch.
- The market search query is `--query` on the CLI but `?q=` over REST.
- Plugins can add affordances to built-in models; for example ASC Pro adds `stream` to booted [simulators](../simulators/README.md). Those keys only appear while the plugin is installed.

## See also
[Writing a plugin](authoring.md) · [Plugin Market](../market/README.md) · [Simulators](../simulators/README.md) · [App Shots Themes](../app-shots-themes/README.md)

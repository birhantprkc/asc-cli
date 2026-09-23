---
description: Browse, search, install and uninstall asc plugins from the tddworks/asc-registry marketplace, and publish your own plugin to it. Use when finding a plugin to install or listing a new plugin in the registry.
---

# Plugin Market

Browse, install and manage dylib plugins that extend the asc CLI and web server. Plugins are listed in the [tddworks/asc-registry](https://github.com/tddworks/asc-registry) registry, and developers add theirs by pull request. Every flag: [command reference](../../commands.md#asc-plugins).

## Quick start
```bash
asc plugins market list
asc plugins market search --query sim
asc plugins install --name asc-pro
asc plugins list
```

## Workflows

### Find, install and remove a plugin
```bash
asc plugins market list                 # browse everything
asc plugins market search --query sim   # matches name, description, categories
asc plugins install --name asc-pro      # use the marketplace "id"
asc plugins list                        # verify
asc plugins uninstall --name ASCPro     # use the installed "slug"
```

Marketplace entries show whether they are already installed, and their affordances change to match:

```json
{
  "data" : [
    {
      "id" : "asc-pro",
      "name" : "ASC Pro",
      "version" : "1.0",
      "categories" : ["simulators", "streaming"],
      "downloadURL" : "https://github.com/tddworks/asc-pro/releases/latest/download/ASCPro.plugin.zip",
      "isInstalled" : false,
      "affordances" : {
        "install" : "asc plugins install --name asc-pro",
        "listMarket" : "asc plugins market list",
        "viewRepository" : "https://github.com/tddworks/asc-pro"
      }
    }
  ]
}
```

### Publish your plugin to the registry
1. Build the plugin as a `.plugin` bundle (dylib + `manifest.json` + optional `ui/`).
2. Publish a `.plugin.zip` release asset on your GitHub repo.
3. Fork [tddworks/asc-registry](https://github.com/tddworks/asc-registry) and add an entry to `registry.json`.
4. Open a PR. Once it is merged, the plugin appears in `asc plugins market list`.

The zip must extract to a `<Name>.plugin/` directory:

```
ASCPro.plugin/
├── manifest.json   # {"name": "ASC Pro", "version": "1.0", "server": "ASCPro.dylib", "ui": ["ui/sim-stream.js"]}
├── ASCPro.dylib
└── ui/
    └── sim-stream.js   # optional web UI scripts
```

A `registry.json` entry (`id`, `name`, `version`, `description` and `downloadURL` are required; `author`, `repositoryURL` and `categories` are optional):

```json
{
  "plugins": [
    {
      "id": "asc-pro",
      "name": "ASC Pro",
      "version": "1.0",
      "description": "Simulator streaming, interaction & tunnel sharing",
      "author": "tddworks",
      "repositoryURL": "https://github.com/tddworks/asc-registry",
      "downloadURL": "https://github.com/tddworks/asc-registry/releases/latest/download/ASCPro.plugin.zip",
      "categories": ["simulators", "streaming"]
    }
  ]
}
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/plugins/market` | `asc plugins market list` |
| GET | `/api/v1/plugins/market?q=<text>` | `asc plugins market search --query <text>` |
| GET | `/api/v1/plugins` | `asc plugins list` |
| POST | `/api/v1/plugins` (body `{"name": "<id>"}`) | `asc plugins install --name` |
| DELETE | `/api/v1/plugins/:name` | `asc plugins uninstall --name` |

## Gotchas
- `install` takes the marketplace `id` (e.g. `asc-pro`), but `uninstall` takes the installed plugin's `slug`, which is its directory name (e.g. `ASCPro`).
- The REST search parameter is `q`, not `query`.
- The registry is a single file: `https://raw.githubusercontent.com/tddworks/asc-registry/main/registry.json`.
- `install` downloads the zip from `downloadURL` and extracts it into `~/.asc/plugins/`; `uninstall` deletes `~/.asc/plugins/<name>.plugin/`.
- The web app has a Plugins page with Installed and Marketplace tabs.

## See also
[plugins](../plugins/README.md)

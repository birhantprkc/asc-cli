---
description: Drive asc over HTTP with asc web-server, a HATEOAS REST API whose _links mirror the CLI affordances. Use when an agent, script or web app needs App Store Connect data over REST instead of the CLI.
---

# REST API

`asc web-server` exposes the same features as the CLI over HTTP. CLI responses carry `affordances` (ready-to-run commands); REST responses carry `_links` (href + HTTP method). Both come from the same definition on each model, so they always match. Every flag: [command reference](../../commands.md#asc-web-server).

## Quick start

```bash
asc web-server                       # port 8420 by default; --port to change
curl http://localhost:8420/api/v1    # discover every top-level resource
curl http://localhost:8420/api/v1/apps
```

## Workflows

### Discover and navigate

Start at `GET /api/v1`. It lists every top-level resource (sample trimmed):

```json
{
  "data": [
    {
      "version": "v1",
      "_links": {
        "apps":          { "href": "/api/v1/apps", "method": "GET" },
        "builds":        { "href": "/api/v1/builds", "method": "GET" },
        "certificates":  { "href": "/api/v1/certificates", "method": "GET" },
        "bundleIds":     { "href": "/api/v1/bundle-ids", "method": "GET" },
        "devices":       { "href": "/api/v1/devices", "method": "GET" },
        "profiles":      { "href": "/api/v1/profiles", "method": "GET" },
        "simulators":    { "href": "/api/v1/simulators", "method": "GET" },
        "plugins":       { "href": "/api/v1/plugins", "method": "GET" },
        "territories":   { "href": "/api/v1/territories", "method": "GET" },
        "appCategories": { "href": "/api/v1/app-categories", "method": "GET" }
      }
    }
  ]
}
```

Follow `_links` from there. Each resource carries links for the next step:

```json
{
  "id": "123",
  "name": "My App",
  "bundleId": "com.example.app",
  "_links": {
    "listVersions": { "href": "/api/v1/apps/123/versions", "method": "GET" },
    "listAppInfos": { "href": "/api/v1/apps/123/app-infos", "method": "GET" },
    "listReviews":  { "href": "/api/v1/apps/123/reviews", "method": "GET" }
  }
}
```

The same app from `asc apps list` has `"affordances": { "listVersions": "asc versions list --app-id 123", … }`.

### Common requests

```bash
curl http://localhost:8420/api/v1/apps/123
curl http://localhost:8420/api/v1/apps/123/versions
curl http://localhost:8420/api/v1/apps/123/builds
curl http://localhost:8420/api/v1/apps/123/testflight
curl http://localhost:8420/api/v1/certificates
curl http://localhost:8420/api/v1/bundle-ids
curl http://localhost:8420/api/v1/devices
curl http://localhost:8420/api/v1/profiles
curl http://localhost:8420/api/v1/simulators
curl http://localhost:8420/api/v1/plugins
curl http://localhost:8420/api/v1/territories
```

Each feature doc lists its own routes in its **REST** section.

## How affordances map to HTTP

An affordance `asc <command> <action> --<parent>-id X` becomes a link:

| CLI action | HTTP | Path shape |
|---|---|---|
| `list` | GET | collection, e.g. `/api/v1/apps/{id}/versions` |
| `get` | GET | `/api/v1/<resource>/{id}` |
| `create`, `add` | POST | collection |
| `update` | PATCH | `/api/v1/<resource>/{id}` |
| `delete`, `remove` | DELETE | `/api/v1/<resource>/{id}` |
| anything else (e.g. `submit`, `start`) | POST | `/api/v1/<resource>/{id}/{action}` |

Query parameters use the CLI flag names: `--state` → `?state=`, `--expired-only` → `?expired-only=true`.

## Gotchas

- A resource's `_links` are state-aware, exactly like CLI affordances: an action that isn't allowed in the current state has no link.
- `POST /api/run` is a legacy bridge that runs a CLI command for features without a REST route yet.
- Uses the same credentials as the CLI (`asc auth login` or environment variables).

## See also

- [Web Apps](../web-apps/README.md) — browser UIs that talk to this server
- [Web server architecture](../web-server-architecture/README.md)

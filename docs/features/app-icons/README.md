---
description: REST-only option that enriches the apps list with each app's icon as a sizable image template. Use when a client needs to render app icons from asc web-server.
---

# App Icons (REST)

`GET /api/v1/apps?include=icon` returns each app enriched with its primary build's icon asset. The icon template URL lets clients render at any size. There is no CLI equivalent.

## Quick start
```bash
asc web-server &
curl -s http://127.0.0.1:8420/api/v1/apps?include=icon | jq '.data[0].iconAsset'
```

```json
{
  "templateUrl": "https://is1-ssl.mzstatic.com/image/thumb/.../source/{w}x{h}bb.{f}",
  "width": 1024,
  "height": 1024
}
```

## Workflows

### Render the icon at a given size
Substitute `{w}`, `{h}`, `{f}` client-side. Aspect ratio is fixed by Apple's CDN (`bb` = bounded box).

| Size / format | URL result |
|---------------|------------|
| 120×120 PNG | `.../source/120x120bb.png` |
| 240×240 JPG | `.../source/240x240bb.jpg` |
| 1024×1024 PNG (original) | `.../source/1024x1024bb.png` |

Swift callers using the package get the same with `asset.url(maxSize: 120)` or `asset.url(maxSize: 240, format: "jpg")`.

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps` | `asc apps list` (no icons) |
| GET | `/api/v1/apps?include=icon` | none (REST-only), each app gets `iconAsset` |

## Gotchas
- `iconAsset` is only included with `?include=icon`; the default response never has it.
- `iconAsset` is omitted for an app with no App Store version, or whose versions have no attached build.
- Icons are fetched with one extra App Store Connect call per app (in parallel), so `?include=icon` is slower on accounts with many apps.

## See also
[REST API](../rest-api/README.md) · [web-server-architecture](../web-server-architecture/README.md)

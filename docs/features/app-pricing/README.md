---
description: List an app's price points and set its price, including making it free. Use before a first submission, which Apple refuses until the app has a price schedule.
---

# App Pricing

Set what an app costs, including making it free. Mirrors the IAP commands (`asc iap price-points list`, `asc iap prices set`). Every flag: [price-points list](../../commands.md#asc-apps-price-points-list), [prices set](../../commands.md#asc-apps-prices-set).

## Quick start

```bash
asc apps price-points list --app-id 6792459661 --output table | head -4
asc apps prices set --app-id 6792459661 --base-territory USA --price-point-id <id>
```

## Workflows

### Make an app free or paid

```bash
APP_ID=6792459661

# Free app
FREE=$(asc apps price-points list --app-id $APP_ID | jq -r '.data[] | select(.customerPrice == "0.0") | .id')
asc apps prices set --app-id $APP_ID --base-territory USA --price-point-id "$FREE"

# …or a paid app at $4.99
PAID=$(asc apps price-points list --app-id $APP_ID | jq -r '.data[] | select(.customerPrice == "4.99") | .id')
asc apps prices set --app-id $APP_ID --base-territory USA --price-point-id "$PAID"

asc versions check-readiness --version-id <VERSION_ID>   # pricingCheck now passes
```

A price point carries the command to set it:

```json
{
  "id" : "<id>",
  "appId" : "6792459661",
  "territory" : "USA",
  "customerPrice" : "0.0",
  "proceeds" : "0.0",
  "affordances" : {
    "listPricePoints" : "asc apps price-points list --app-id 6792459661 --territory USA",
    "setPrice" : "asc apps prices set --app-id 6792459661 --base-territory USA --price-point-id <id>"
  }
}
```

`prices set` returns the new schedule (`id`, `appId`, `baseTerritory`) with a `listPricePoints` affordance.

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/price-points` | `asc apps price-points list` (`--territory` → `?territory=`) |
| POST | `/api/v1/apps/:appId/prices/set` | `asc apps prices set` |

The POST body is `{"base-territory": "USA", "price-point-id": "…"}`; camelCase `baseTerritory` / `pricePointId` is also accepted.

```bash
curl 'http://localhost:8420/api/v1/apps/6792459661/price-points?territory=USA'
curl -X POST http://localhost:8420/api/v1/apps/6792459661/prices/set \
  -d '{"base-territory": "USA", "price-point-id": "<id>"}'
```

## Gotchas

- Submission is refused with "App is not eligible for submission until pricing has been set" until the app has a price schedule, so this is part of every first release.
- Apple prices apps on fixed price points per territory. You pick one point in a base territory and Apple equalizes the price everywhere else. The zero point makes the app free (the usual choice for apps that earn through in-app purchases or subscriptions).
- `--territory` defaults to `USA`. Every page is fetched, which is about 800 points per territory.
- The price point ID must come from the list for the same territory you pass as `--base-territory`.
- `prices set` replaces the app's current price schedule; there is no command to read the current schedule or schedule a future price change.

## See also

[version-check-readiness](../version-check-readiness/README.md) · [iap-subscriptions](../iap-subscriptions/README.md)

---
description: Set and inspect which territories an app, in-app purchase or subscription is sold in. Use when setting up availability for a new app or product, or finding out why a territory is blocked.
---

# App, IAP & Subscription Availability

Territory availability for apps, in-app purchases and auto-renewable subscriptions. Every flag: [app-availability](../../commands.md#asc-app-availability), [iap-availability](../../commands.md#asc-iap-availability), [subscription-availability](../../commands.md#asc-subscription-availability), [territories](../../commands.md#asc-territories).

## Quick start

```bash
asc territories list --output table
asc app-availability create --app-id <id> --all-territories --available-in-new-territories
asc iap-availability create --iap-id <id> --available-in-new-territories --territory USA --territory JPN
asc subscription-availability create --subscription-id <id> --territory USA --territory GBR
```

## Workflows

### Set up and check app availability

```bash
# Everywhere, including territories Apple adds later
asc app-availability create --app-id <id> --all-territories --available-in-new-territories

# Or only a few territories
asc app-availability create --app-id <id> --territory USA --territory JPN

# Per-territory status
asc app-availability get --app-id <id> --pretty
```

`app-availability get` is the richest view: every territory with `isAvailable`, blocking reasons (`contentStatuses`), `releaseDate` and `isPreOrderEnabled`.

```json
{
  "id": "avail-1",
  "appId": "app-42",
  "isAvailableInNewTerritories": true,
  "territories": [
    { "id": "ta-1", "territoryId": "USA", "isAvailable": true, "isPreOrderEnabled": false, "contentStatuses": ["AVAILABLE"] },
    { "id": "ta-2", "territoryId": "CHN", "isAvailable": false, "isPreOrderEnabled": false, "contentStatuses": ["CANNOT_SELL_RESTRICTED_RATING"] }
  ]
}
```

`contentStatuses` explains why a territory is blocked: `AVAILABLE`, `MISSING_RATING`, `CANNOT_SELL_RESTRICTED_RATING`, `CANNOT_SELL_GAMBLING`, `BRAZIL_REQUIRED_TAX_ID`, `ICP_NUMBER_MISSING`, and 30+ more.

### Set IAP and subscription availability

```bash
asc iap list --app-id $APP_ID
asc iap-availability get --iap-id $IAP_ID          # territories + currency codes
asc iap-availability create --iap-id $IAP_ID \
  --available-in-new-territories \
  --territory USA --territory GBR --territory DEU

asc subscriptions list --group-id $GROUP_ID
asc subscription-availability get --subscription-id $SUB_ID
asc subscription-availability create --subscription-id $SUB_ID \
  --territory USA --territory JPN
```

IAP and subscription availability lists territory IDs with currency codes:

```json
{
  "id": "avail-1",
  "iapId": "iap-42",
  "isAvailableInNewTerritories": true,
  "territories": [ { "id": "USA", "currency": "USD" }, { "id": "CHN", "currency": "CNY" } ],
  "affordances": {
    "getAvailability": "asc iap-availability get --iap-id iap-42",
    "createAvailability": "asc iap-availability create --iap-id iap-42 ...",
    "listTerritories": "asc territories list"
  }
}
```

IAPs and subscriptions also carry a `getAvailability` affordance.

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/{appId}/availability` | `app-availability get` |
| POST | `/api/v1/apps/{appId}/availability` | `app-availability create` |
| GET | `/api/v1/iap/{iapId}/availability` | `iap-availability get` |
| PATCH | `/api/v1/iap/{iapId}/availability` | `iap-availability create` |
| GET | `/api/v1/subscriptions/{subscriptionId}/availability` | `subscription-availability get` |

Bodies:
- App: `{"territory": ["USA"]}` or `{"all-territories": true}`, plus optional `"available-in-new-territories": true`.
- IAP: `{ "territoryIds": [...], "availableInNewTerritories": Bool }` — an upsert that replaces existing availability.

The IAP and subscription `GET` return a synthetic all-territory record when no availability has been configured yet.

## Gotchas

- An app whose availability was never set up (App Store Connect shows **Set Up Availability**) returns `{"data":[]}` from `app-availability get`, and the CLI prints the `create` command as a hint on stderr.
- `app-availability create` takes exactly one of `--territory` (repeatable) or `--all-territories`.
- Before release, every territory reports `CANNOT_SELL` + `AVAILABLE_FOR_SALE_UNRELEASED_APP`. That is expected until the app is live.
- `--all-territories` uses the same list as `asc territories list` (~175 territories).

## See also

- [App pricing](../app-pricing/README.md)
- [IAP & subscriptions](../iap-subscriptions/README.md)

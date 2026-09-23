# App Pricing

Set what an app costs — including making it free — from the CLI. A submission is refused with "App is not eligible for submission until pricing has been set" until an app has a price schedule, so this is part of every first release.

Apple prices apps on fixed **price points** per territory. You pick one point in a base territory; Apple equalizes the price in every other territory. The zero point makes the app free (the usual choice for apps that earn through in-app purchases or subscriptions).

Mirrors the IAP commands (`asc iap price-points list`, `asc iap prices set`).

---

## CLI Usage

### `asc apps price-points list`

```
asc apps price-points list --app-id <id> [--territory USA]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | Yes | App ID |
| `--territory` | No | Territory code; default `USA`. Every page is fetched (~800 points per territory) |

```bash
asc apps price-points list --app-id 6792459661 --output table | head -4
```

```
ID                           Territory  Customer Price  Proceeds
---------------------------  ---------  --------------  --------
eyJzIjoiNjc5MjQ1OTY2MSIs…    USA        0.0             0.0
```

```json
{
  "data" : [
    {
      "affordances" : {
        "listPricePoints" : "asc apps price-points list --app-id 6792459661 --territory USA",
        "setPrice" : "asc apps prices set --app-id 6792459661 --base-territory USA --price-point-id <id>"
      },
      "appId" : "6792459661",
      "customerPrice" : "0.0",
      "id" : "<id>",
      "proceeds" : "0.0",
      "territory" : "USA"
    }
  ]
}
```

### `asc apps prices set`

```
asc apps prices set --app-id <id> --base-territory <code> --price-point-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | Yes | App ID |
| `--base-territory` | Yes | Territory the price point belongs to, e.g. `USA` |
| `--price-point-id` | Yes | From `asc apps price-points list` for that territory |

Creates the app's price schedule (replacing the current one). Output:

```json
{
  "data" : [
    {
      "affordances" : {
        "listPricePoints" : "asc apps price-points list --app-id 6792459661 --territory USA"
      },
      "appId" : "6792459661",
      "baseTerritory" : "USA",
      "id" : "<schedule id>"
    }
  ]
}
```

---

## REST Endpoints

| Method | Path | CLI flag → REST |
|--------|------|-----------------|
| `GET` | `/api/v1/apps/{appId}/price-points` | `--territory` → `?territory=` |
| `POST` | `/api/v1/apps/{appId}/prices/set` | body `{"base-territory": "USA", "price-point-id": "…"}` (camelCase `baseTerritory` / `pricePointId` also accepted) |

```bash
curl 'http://localhost:8420/api/v1/apps/6792459661/price-points?territory=USA'
curl -X POST http://localhost:8420/api/v1/apps/6792459661/prices/set \
  -d '{"base-territory": "USA", "price-point-id": "<id>"}'
```

---

## Typical Workflow

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

---

## Architecture

```
ASCCommand                              Infrastructure                      Domain
──────────                              ──────────────                      ──────
apps price-points list ─┐
apps prices set ────────┼─▶ SDKPricingRepository ─────────────────▶ PricingRepository
AppPricingController ───┘     GET /v1/apps/{id}/appPricePoints          AppPricePoint (isFree)
                              POST /v1/appPriceSchedules                 AppPriceSchedule
```

`ASCCommand → Infrastructure → Domain`. `PricingRepository.hasPricing(appId:)` (used by `check-readiness`) lives on the same protocol.

---

## Domain Models

### `AppPricePoint`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Price point id |
| `appId` | `String` | Injected from the request |
| `territory` | `String?` | Injected from the `--territory` filter |
| `customerPrice` | `String?` | e.g. `"4.99"`, `"0.0"` |
| `proceeds` | `String?` | Developer proceeds |

Computed: `isFree` (customer price is zero). Affordances (when `territory` is known): `listPricePoints`, `setPrice`.

### `AppPriceSchedule`

`id`, `appId`, `baseTerritory`. Affordance: `listPricePoints` for the base territory.

### `PricingRepository`

```swift
@Mockable
public protocol PricingRepository: Sendable {
    func hasPricing(appId: String) async throws -> Bool
    func listPricePoints(appId: String, territory: String) async throws -> [AppPricePoint]
    func setPriceSchedule(appId: String, baseTerritory: String, pricePointId: String) async throws -> AppPriceSchedule
}
```

`App` gains a `listPricePoints` affordance (`--territory USA`).

---

## File Map

```
Sources/
├── Domain/Apps/Pricing/
│   ├── AppPricePoint.swift
│   ├── AppPriceSchedule.swift
│   ├── AppPricing+RESTRoutes.swift        # `apps price-points`, `apps prices` routes
│   └── PricingRepository.swift
├── Infrastructure/Apps/Pricing/SDKPricingRepository.swift
└── ASCCommand/Commands/Apps/
    ├── AppsPricePointsCommand.swift, AppsPricePointsList.swift
    └── AppsPricesCommand.swift, AppsPricesSet.swift

Tests/
├── DomainTests/Apps/Pricing/AppPricingTests.swift
├── InfrastructureTests/Apps/Pricing/SDKPricingRepositoryTests.swift
└── ASCCommandTests/Commands/Apps/AppPricingCommandsTests.swift, Web/RESTRoutesTests.swift
```

| Wiring file | Purpose |
|-------------|---------|
| `Sources/ASCCommand/Commands/Apps/AppsCommand.swift` | Registers `price-points` and `prices` under `apps` |
| `Sources/ASCCommand/Commands/Web/Controllers/AppPricingController.swift` | REST routes |
| `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` | Constructs `AppPricingController` |
| `Sources/Domain/Shared/RESTPathResolver.swift` | Touches `_appPricingRoutes` |

---

## API Reference

| Operation | Endpoint | SDK call | Repository method |
|-----------|----------|----------|-------------------|
| List price points | `GET /v1/apps/{id}/appPricePoints?filter[territory]=USA&limit=200` (all pages) | `APIEndpoint.v1.apps.id(id).appPricePoints.get` | `listPricePoints(appId:territory:)` |
| Set price | `POST /v1/appPriceSchedules` — relationships `app`, `baseTerritory`, `manualPrices` → inline `appPrices` `${local-app-price-1}` with `appPricePoint` | `APIEndpoint.v1.appPriceSchedules.post` | `setPriceSchedule(appId:baseTerritory:pricePointId:)` |
| Has pricing | `GET /v1/apps/{id}/appPriceSchedule` | `APIEndpoint.v1.apps.id(id).appPriceSchedule.get` | `hasPricing(appId:)` |

---

## Testing

```swift
@Test func `the zero price point makes the app free`() {
    #expect(AppPricePoint(id: "pp-0", appId: "app-1", territory: "USA", customerPrice: "0.0", proceeds: "0.0").isFree)
}
```

```bash
swift test --filter 'AppPricing|SDKPricingRepository'
```

---

## Extending

- **Read the current schedule** (`asc apps prices get`): `GET /v1/apps/{id}/appPriceSchedule?include=baseTerritory,manualPrices`, like `iap-price-schedule get`.
- **Scheduled price changes**: `AppPriceV2InlineCreate` takes `startDate`/`endDate`; add `--start-date` to `prices set`.
- **Free-app shortcut**: `asc apps prices set --app-id <id> --free`, resolving the zero point via `AppPricePoint.isFree`.

# Changelog

All notable changes to asc-swift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Submit in-app purchases and subscriptions with an app version** — `asc versions submit --version-id <id> --with-products` adds every in-app purchase and subscription that is `READY_TO_SUBMIT` with a submittable version (and its subscription group's version) to the app version's review submission and submits them together — the way first-time products must go to review — using only the public API and your API key, no iris web session. `--dry-run` lists what would be submitted and submits nothing. REST: `POST /api/v1/versions/:id/submit?with-products=true&dry-run=true` (the route `submitForReview` links pointed at now exists). See `docs/features/submit-with-products/README.md`.
- **Product versions** — `asc iap versions list --iap-id`, `asc subscriptions versions list --subscription-id` and `asc subscription-groups versions list --group-id` show each product's review versions and state; a submittable version offers `addToSubmission`. IAPs, subscriptions and groups gain a `listVersions` affordance. REST: `GET /api/v1/{iap,subscriptions,subscription-groups}/:id/versions`.
- **Build a review submission step by step** — `asc review-submissions create --app-id [--platform]` (opens or reuses the app's draft), `items add --submission-id` with one of `--version-id`, `--iap-version-id`, `--subscription-version-id`, `--subscription-group-version-id`, `items remove --item-id`, and `submit --submission-id`. REST: `POST /api/v1/apps/:appId/review-submissions`, `POST /api/v1/review-submissions/:id/items`, `DELETE /api/v1/review-submissions/items/:itemId`, `POST /api/v1/review-submissions/:id/submit`.
- **App pricing** — `asc apps price-points list --app-id [--territory USA]` lists the prices an app can be sold at (every page, ~800 per territory; the `0.0` point makes it free) and `asc apps prices set --app-id --base-territory --price-point-id` sets the app's price, which Apple equalizes worldwide. Fixes the "App is not eligible for submission until pricing has been set" refusal from the CLI. `App` gains a `listPricePoints` affordance. REST: `GET /api/v1/apps/:appId/price-points?territory=`, `POST /api/v1/apps/:appId/prices/set`. See `docs/features/app-pricing/README.md`.
- **Set up app availability** — `asc app-availability create --app-id (--territory X … | --all-territories) [--available-in-new-territories]` sets where an app is sold (App Store Connect's "Set Up Availability"), in one `POST /v2/appAvailabilities`. REST: `POST /api/v1/apps/:appId/availability`, plus `GET` for the existing read.
- **`STORAGE` performance metrics** — the new category Apple reports is mapped and usable with `perf-metrics list --metric-type STORAGE`.

### Changed
- **Dependencies updated to their latest releases**, with `Package.swift` minimums raised to match: appstoreconnect-swift-sdk 4.4.3 (was 4.2.0), Hummingbird 2.27.0, swift-argument-parser 1.8.2, TauTUI 0.2.2, SweetCookieKit 0.5.3, Mockable 0.6.4 and the rest. The `hello-plugin` example pins Hummingbird 2.27.0 to match the host.
- **Refused submissions explain why** — when Apple refuses to add an item to, or submit, a review submission, the error lists the specific reasons from Apple's `associatedErrors` (missing device screenshots, content rights declaration, App Privacy answers, pricing) instead of only "please check associated errors".

### Fixed
- **`app-availability get` on an app that was never set up** — printed a raw 404; it now returns `{"data":[]}` and a hint with the `create` command (`getAppAvailability` returns `nil`).
- **`review-submissions items list` shows what each item points at** — items never asked Apple for their relationships (`include=`), so every item showed no linked type or id, even app versions. They now show `APP_STORE_VERSION`, the new product version types and the others, with the `getVersion` affordance for app versions.

---

## [0.18.4] - 2026-09-23

### Fixed
- **`asc subscriptions prices set-batch` sends one request instead of one per territory** — it now sends a single `PATCH /v1/subscriptions/{id}` with every price inlined (`SubscriptionPriceInlineCreate`) instead of one `POST /v1/subscriptionPrices` per territory. Pricing all 175 territories took 175 sequential POSTs (over a minute per subscription), and a failure partway through left some territories priced and others not; Apple now applies the batch all-or-nothing. The REST `POST /api/v1/subscriptions/:id/prices` route benefits too, since it uses the same repository method.
- **Subscription price schedules no longer drop manual prices after the first 50** — `subscription-price-schedule get` (and the read-back after `set-batch`) fetched `/v1/subscriptions/{id}/prices` without a `limit`, so only Apple's default first page came back and the other territories were filled with the first price's equalizations, showing wrong prices where custom per-territory prices were set. It now requests `limit=200` and follows the pagination cursor.
- **The other per-territory price lists no longer stop at 50** — the same truncation affected `iap-price-schedule get` (manual prices), `iap-offer-codes prices list`, `subscription-offer-codes prices list`, `subscription-promotional-offers prices list` and `win-back-offers prices list`. They called Apple without a `limit` and read one page, so any territory past Apple's default 50 was missing. They now request `limit=200` and follow every page through a shared `APIClient.requestAllPages(_:nextCursor:)` helper, which `subscription-price-schedule get` uses too.
- **Offer price lists now show each price's territory and price point** — `iap-offer-codes prices list`, `subscription-offer-codes prices list`, `subscription-promotional-offers prices list` and `win-back-offers prices list` returned entries with only `id` and the offer ID, because Apple sends a price's territory and price point only when the request asks for them with `include=`. The requests now include both, so `territory` and the price-point ID are filled in, over CLI and REST.
- **More list commands no longer stop at Apple's first page** — `reviews list`, `devices list`, `bundle-ids list`, `profiles list` (with and without `--bundle-id-id`), `users list`, `versions list`, `builds uploads list`, `xcode-cloud builds list` and `diagnostics list` read a single page with no `limit`, so anything past Apple's default page size (50 for most endpoints, 20 for bundle IDs) was silently dropped. They now request `limit=200` and follow every page through `APIClient.requestAllPages`. On a real account, `builds uploads list` went from 50 to 122 entries and `bundle-ids list` from 20 to 85.
- **`profiles list` shows each profile's bundle ID again** — without `--bundle-id-id`, every profile came back with `bundleIdId: ""` (and a broken `listProfiles` affordance), because the bundle ID linkage is only returned when the request asks for it with `include=bundleId`. The request now includes it.

---

## [0.18.3] - 2026-09-22

### Added
- **Product Page Optimization tests** — `asc experiments list|get|create|update|start|stop|delete`, `asc experiment-treatments list|create|update|delete`, and `asc experiment-treatment-localizations list|create|delete` manage App Store product page A/B tests (ASC API `appStoreVersionExperiments` v2). A test is app-scoped; `create` takes `--name`, `--platform` and `--traffic-proportion 1-100`; `start`/`stop` map to `PATCH { started: true|false }`. New `AppStoreVersionExperiment` (+ `AppStoreVersionExperimentState` with `isEditable`/`isPendingReview`/`isApproved`/`isFinished`, and `isRunning`/`canStart` on the model), `ExperimentTreatment` and `ExperimentTreatmentLocalization` domain types in `Domain/Apps/Experiments/`, backed by `ExperimentRepository`. Affordances are state-aware: `createTreatment`/`update`/`delete` only while editable, `start` only when approved and unstarted, `stop` only while running. `App` gains a `listExperiments` affordance for discovery. REST equivalents under `/api/v1/apps/:appId/experiments`, `/api/v1/experiments/:id[/start|/stop|/experiment-treatments]`, `/api/v1/experiment-treatments/:id[/experiment-treatment-localizations]` and `/api/v1/experiment-treatment-localizations/:id` via `ExperimentsController`. See `docs/features/product-page-optimization/README.md`.

---

## [0.18.2] - 2026-07-16

### Added
- **`asc iris resolution-center get --submission-id <id> [--plain-text]`** — reads App Review's Resolution Center for a review submission: the reviewer's actual rejection message text plus structured rejection reasons (guideline section/description/code). This data has no official App Store Connect API surface (Apple's OpenAPI spec contains no `resolutionCenter*`/`reviewRejection*` paths); the command composes three iris private-API calls (`resolutionCenterThreads` → `resolutionCenterMessages?include=fromActor,rejections` → `reviewRejections`) behind cookie auth, mirroring the existing iris/official split (`asc iap submit` vs `asc iris iap-submissions`). `--plain-text` converts HTML message bodies to terminal-friendly text. New `ResolutionCenterDetail`/`ResolutionCenterMessage`/`ReviewRejectionReason` domain types and `IrisResolutionCenterRepository` in `Domain/Iris/ResolutionCenter/`. Discovery is wired via CAEOAS: `ReviewSubmission` (when `hasIssues`) and `ReviewSubmissionItem` (when `isRejected`) now expose a `getResolutionDetails` affordance pointing at the iris command — the official-API commands stay zero-iris. REST equivalent: `GET /api/v1/iris/review-submissions/:id/resolution-center?plain-text=true` via `IrisResolutionCenterController`. Attachments App Review adds to messages are listed in the detail (`attachments[]` with `fileName`/`fileSize`/`downloadUrl`) and downloadable with `--out <dir>`; downloads are gated to https on Apple/CDN hosts (`ResolutionCenterAttachment.isValidDownloadURL`). See `docs/features/resolution-center/README.md`.

---

## [0.18.1] - 2026-05-31

### Added
- **`asc sales-reports summary --from <date> --to <date>`** — aggregates daily Sales reports across a date range into a single rollup with derived metrics: `downloads` (first installs of phone/Mac apps, excluding Apple Watch `3F` redownloads), `updates`, `inAppPurchases`, `payers` (distinct SKUs with non-zero customer price), `customerSpend` (per `Customer Currency`, since `Customer Price` is in customer-local currency and cross-currency summing is meaningless), `proceeds` (per `Currency of Proceeds`, the developer's actual payout). CLI-only like the other report commands.
- **`asc sales-reports download --version <schema>`** — exposes Apple's `filter[version]` query parameter on `/v1/salesReports`. Previously omitted by `SDKReportRepository`, so Apple always returned its default schema. Invalid values now surface Apple's helpful `PARAMETER_ERROR.INVALID` message naming the latest supported version (e.g. `1_1` for `SALES/SUMMARY/DAILY`). `ReportRepository.downloadSalesReport` gains a trailing `version: String?` parameter; pass `nil` to keep the previous default behavior.
- **`asc review-submissions get --submission-id <id>` and `asc review-submissions items list --submission-id <id> [--state <ITEM_STATE>]`** — drill into a review submission to find *which* attached item Apple rejected. The new `items list` subcommand surfaces per-item state (`READY_FOR_REVIEW`/`ACCEPTED`/`APPROVED`/`REJECTED`/`REMOVED`) and the linked resource id (typically the rejected `AppStoreVersion`), so an agent can navigate from an `UNRESOLVED_ISSUES` submission to the offending version with one call. `ReviewSubmission` gains `getSubmission`/`listItems` affordances on every record and a conditional `listRejectedItems` affordance when `hasIssues == true`. New `ReviewSubmissionItem` + `ReviewSubmissionItemState` + `ReviewSubmissionItemLinkedResource` domain types in `Domain/Submissions/`; `SubmissionRepository` gains `getSubmission(id:)` and `listSubmissionItems(submissionId:)`. REST equivalents: `GET /api/v1/review-submissions/:id` and `GET /api/v1/review-submissions/:id/items?state=REJECTED` via `ReviewSubmissionsController`. Note: Apple's free-text rejection reasoning still lives only in App Store Connect's Resolution Center web UI — the public API exposes the state machine, not the narrative. See `docs/features/review-submissions/README.md`.

### Fixed
- **`asc app-availability get` no longer crashes with `PARAMETER_ERROR.INVALID` ("maximum allowable limit is '50'")** — Apple caps `include=territoryAvailabilities` on `/v1/apps/{id}/appAvailabilityV2` at 50 entries, and silently truncates relationship includes regardless. `SDKAppAvailabilityRepository.getAppAvailability` now matches the iOS-SDK multi-call pattern documented in CLAUDE.md: one call to the parent for `availableInNewTerritories` (no `include`), then a second call to the dedicated `/v2/appAvailabilities/{id}/territoryAvailabilities` endpoint with `limit: 200` for the full territory list. Added a regression test that round-trips 175 territories.

---

## [0.18.0] - 2026-05-13

### Added
- **`asc versions update` now accepts `--copyright`, `--release-type`, and `--earliest-release-date`** — closes the App Store submission gap where the version's copyright line, release type (`MANUAL` / `AFTER_APPROVAL` / `SCHEDULED`), and earliest release date could only be set via the web. The underlying `VersionRepository.updateVersion(...)` already supported these fields; the CLI now wires them through. `--version` is now optional, so any subset of these fields can be patched independently (e.g. `asc versions update --version-id v-1 --copyright "© 2026 Acme"`).

## Older releases

[0.17](docs/changelog/0.17.md) · [0.16](docs/changelog/0.16.md) · [0.1](docs/changelog/0.1.md)

[Unreleased]: https://github.com/tddworks/asc-cli/compare/v0.18.4...HEAD
[0.18.4]: https://github.com/tddworks/asc-cli/compare/v0.18.3...v0.18.4
[0.18.3]: https://github.com/tddworks/asc-cli/compare/v0.18.2...v0.18.3
[0.18.2]: https://github.com/tddworks/asc-cli/compare/v0.18.1...v0.18.2
[0.18.1]: https://github.com/tddworks/asc-cli/compare/v0.18.0...v0.18.1
[0.18.0]: https://github.com/tddworks/asc-cli/compare/v0.17.9...v0.18.0

# Submit Products with an App Version

Send in-app purchases, subscriptions and subscription groups to App Review **in the same review submission as an app version** — the way Apple requires first-time products to be reviewed — using only the public App Store Connect API and your API key.

Apple versions products the way it versions apps: every IAP, subscription and subscription group has *versions* (`/v2/inAppPurchases/{id}/versions`, `/v1/subscriptions/{id}/versions`, `/v1/subscriptionGroups/{id}/versions`). A version in `PREPARE_FOR_SUBMISSION` is sent to review by adding it as an item to a review submission, next to the app version. This replaces the iris (cookie-auth) workaround for "the first IAP must be submitted with a new app version".

Three layers of commands, from one-shot to fine-grained:

| Goal | Command |
|------|---------|
| Submit an app version and every ready product together | `asc versions submit --version-id <id> --with-products` |
| See what that would send, without submitting | `asc versions submit --version-id <id> --with-products --dry-run` |
| Build a submission item by item | `asc review-submissions create` → `items add` → `submit` |
| Find a product's submittable version | `asc iap versions list` / `asc subscriptions versions list` / `asc subscription-groups versions list` |

Requires appstoreconnect-swift-sdk **4.4.3** or later (product versions arrived in 4.4.x).

---

## CLI Usage

### `asc versions submit --with-products`

```
asc versions submit --version-id <id> [--with-products] [--dry-run]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--version-id` | Yes | App Store version to submit |
| `--with-products` | No | Also submit every IAP and subscription that is `READY_TO_SUBMIT` and has a submittable version, plus the version of each subscription group one of them belongs to |
| `--dry-run` | No | List the items that would be submitted and submit nothing (implies `--with-products`) |

Without either flag the command behaves as before (the app version alone).

What goes in, in this order:
1. the app version;
2. each `READY_TO_SUBMIT` in-app purchase's first submittable version;
3. for each subscription group with at least one `READY_TO_SUBMIT` subscription: the group's submittable version, then those subscriptions' submittable versions.

Products still `MISSING_METADATA`, or whose version is already in review or approved, are left out. The app's open draft for the platform is reused if there is one. If Apple refuses an item, the command stops **before submitting**; items added so far stay in the draft (see `asc review-submissions items list`).

```bash
asc versions submit --version-id 5b8c81cc-b230-48ae-858e-b3c598ba5bfa --with-products --dry-run --output table
```

```
Kind                        Version ID                            Product ID  Name
--------------------------  ------------------------------------  ----------  -------------------
APP_STORE_VERSION           5b8c81cc-b230-48ae-858e-b3c598ba5bfa  6792459661  1.0
IN_APP_PURCHASE_VERSION     c196c754-caa1-4969-a65b-1c76db83439e  6815067726  Unveil Pro Lifetime
SUBSCRIPTION_GROUP_VERSION  83709e0a-c2fd-4cbf-bbef-0a8cadabf29e  22406463    Unveil Pro
SUBSCRIPTION_VERSION        2da66776-9b90-46e0-9ceb-38d7e06570d8  6815067714  Unveil Pro Monthly
SUBSCRIPTION_VERSION        384e2202-dc4c-4132-9ac3-beb15973f3c2  6815067865  Unveil Pro Yearly
```

Dry-run JSON (one item shown):

```json
{
  "data" : [
    {
      "affordances" : {
        "listVersions" : "asc iap versions list --iap-id 6815067726"
      },
      "kind" : "IN_APP_PURCHASE_VERSION",
      "name" : "Unveil Pro Lifetime",
      "productId" : "6815067726",
      "versionId" : "c196c754-caa1-4969-a65b-1c76db83439e"
    }
  ]
}
```

A real run prints the submission (`state: WAITING_FOR_REVIEW`).

When Apple refuses, the error lists the reasons it gave in `meta.associatedErrors` rather than only its generic headline:

```
Error: Apple refused the review submission: This resource cannot be reviewed, please check associated errors to see why.
  - A screenshot for one of the following types is required but was not provided: APP_IPAD_PRO_3GEN_129
  - App is not eligible for submission until pricing has been set.
```

Apple server errors (5xx) are shown as they are.

### `asc iap versions list` · `asc subscriptions versions list` · `asc subscription-groups versions list`

```
asc iap versions list --iap-id <id>
asc subscriptions versions list --subscription-id <id>
asc subscription-groups versions list --group-id <id>
```

```bash
asc subscription-groups versions list --group-id 22406463 --pretty
```

```json
{
  "data" : [
    {
      "affordances" : {
        "addToSubmission" : "asc review-submissions items add --submission-id <submission-id> --subscription-group-version-id 83709e0a-c2fd-4cbf-bbef-0a8cadabf29e",
        "listVersions" : "asc subscription-groups versions list --group-id 22406463"
      },
      "id" : "83709e0a-c2fd-4cbf-bbef-0a8cadabf29e",
      "kind" : "SUBSCRIPTION_GROUP",
      "productId" : "22406463",
      "state" : "PREPARE_FOR_SUBMISSION",
      "version" : 1
    }
  ]
}
```

```
ID                                    Product ID  Kind             Version  State
------------------------------------  ----------  ---------------  -------  ----------------------
c196c754-caa1-4969-a65b-1c76db83439e  6815067726  IN_APP_PURCHASE  1        PREPARE_FOR_SUBMISSION
```

`addToSubmission` appears only while the version is submittable (`PREPARE_FOR_SUBMISSION`, `REJECTED`, `DEVELOPER_REJECTED`). IAPs, subscriptions and subscription groups all expose a `listVersions` affordance.

### `asc review-submissions create`

```
asc review-submissions create --app-id <id> [--platform ios|macos|tvos|visionos]
```

Opens a draft review submission for the app and platform (default `ios`), or returns the open one — Apple allows a single open submission (`READY_FOR_REVIEW` or `UNRESOLVED_ISSUES`) per app and platform. A draft exposes `addItem` and `submit` affordances.

### `asc review-submissions items add`

```
asc review-submissions items add --submission-id <id> \
  (--version-id <id> | --iap-version-id <id> | --subscription-version-id <id> | --subscription-group-version-id <id>)
```

Exactly one version flag. Prints the new item with a `remove` affordance.

### `asc review-submissions items remove`

```
asc review-submissions items remove --item-id <id>
```

Removes an item that hasn't been submitted (item state `READY_FOR_REVIEW`). Prints nothing.

### `asc review-submissions submit`

```
asc review-submissions submit --submission-id <id>
```

Sends the draft, with all its items, to App Review.

---

## REST Endpoints

| Method | Path | CLI equivalent | Query / body |
|--------|------|----------------|--------------|
| `POST` | `/api/v1/versions/{versionId}/submit` | `versions submit` | `--with-products` → `?with-products=true`, `--dry-run` → `?dry-run=true` |
| `GET` | `/api/v1/iap/{iapId}/versions` | `iap versions list` | — |
| `GET` | `/api/v1/subscriptions/{subscriptionId}/versions` | `subscriptions versions list` | — |
| `GET` | `/api/v1/subscription-groups/{groupId}/versions` | `subscription-groups versions list` | — |
| `POST` | `/api/v1/apps/{appId}/review-submissions` | `review-submissions create` | body `{"platform": "ios"}` |
| `POST` | `/api/v1/review-submissions/{id}/items` | `review-submissions items add` | body with exactly one of `version-id`, `iap-version-id`, `subscription-version-id`, `subscription-group-version-id` |
| `DELETE` | `/api/v1/review-submissions/items/{itemId}` | `review-submissions items remove` | — returns `{"removed":true}` |
| `POST` | `/api/v1/review-submissions/{id}/submit` | `review-submissions submit` | — |

Body keys and query names are the CLI flag names.

```bash
curl -X POST 'http://localhost:8420/api/v1/versions/5b8c81cc-b230-48ae-858e-b3c598ba5bfa/submit?with-products=true&dry-run=true'
curl -X POST http://localhost:8420/api/v1/review-submissions/487610a2-b816-45fc-bdb0-5dfe601cb8b8/items \
  -d '{"iap-version-id": "c196c754-caa1-4969-a65b-1c76db83439e"}'
```

Responses carry `_links` from the same affordances (`addToSubmission` → `POST /api/v1/review-submissions/<submission-id>/items`, `remove` → `DELETE /api/v1/review-submissions/items/{id}`, `submit` → `POST /api/v1/review-submissions/{id}/submit`).

---

## Typical Workflow

```bash
VERSION=5b8c81cc-b230-48ae-858e-b3c598ba5bfa

# 1. Products must be READY_TO_SUBMIT (metadata, pricing, review screenshot complete)
asc iap list --app-id 6792459661 --output table
asc subscriptions list --group-id 22406463 --output table

# 2. See exactly what will go to review
asc versions submit --version-id $VERSION --with-products --dry-run --output table

# 3. Submit the app version and the products together
asc versions submit --version-id $VERSION --with-products

# Step by step instead:
SUB=$(asc review-submissions create --app-id 6792459661 | jq -r '.data[0].id')
asc review-submissions items add --submission-id $SUB --version-id $VERSION
asc review-submissions items add --submission-id $SUB --iap-version-id c196c754-caa1-4969-a65b-1c76db83439e
asc review-submissions items list --submission-id $SUB --output table
asc review-submissions submit --submission-id $SUB
```

---

## Architecture

```
ASCCommand                                   Infrastructure                         Domain
──────────                                   ──────────────                         ──────
versions submit --with-products [--dry-run] ─┐
VersionSubmissionController                  ├─▶ (SubmissionPlanner, in Domain) ───▶ SubmissionPlanner.plan(for:)
                                             │                                      SubmissionPlan.submit(repo:)
iap / subscriptions / subscription-groups    │
  versions list, ProductVersionsController ──┼─▶ SDKProductVersionRepository ──────▶ ProductVersionRepository
                                             │    GET /v2/inAppPurchases/{id}/versions  ProductVersion
                                             │    GET /v1/subscriptions/{id}/versions
                                             │    GET /v1/subscriptionGroups/{id}/versions
review-submissions create / items add |      │
  remove / submit, ReviewSubmissionsController┴─▶ OpenAPISubmissionRepository ──────▶ SubmissionRepository
                                                  POST /v1/reviewSubmissions           ReviewItemTarget
                                                  POST|DELETE /v1/reviewSubmissionItems ReviewSubmissionError
                                                  PATCH /v1/reviewSubmissions/{id}
```

Dependencies flow `ASCCommand → Infrastructure → Domain`. The planning rules (which products are ready, group before its subscriptions, app version first) live in the Domain `SubmissionPlanner`, which composes the IAP, subscription group, subscription and product version repositories. `SubmissionPlan.submit(repo:)` owns the order of writes and stops before submitting on the first refusal.

---

## Domain Models

### `ProductVersion`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | Product version id |
| `productId` | `String` | Parent IAP, subscription or group id — injected from the request |
| `kind` | `ProductVersionKind` | `IN_APP_PURCHASE`, `SUBSCRIPTION`, `SUBSCRIPTION_GROUP` |
| `version` | `Int?` | Version number |
| `state` | `ProductVersionState` | See below |

Computed: `isSubmittable`, `isInReview`, `isApproved`. Affordances: `listVersions` (always), `addToSubmission` (when submittable).

### `ProductVersionState`

`PREPARE_FOR_SUBMISSION`, `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `ACCEPTED`, `APPROVED`, `REPLACED_WITH_NEW_VERSION`, `REJECTED`, `DEVELOPER_REJECTED`.

| Boolean | True for |
|---------|----------|
| `isSubmittable` | `PREPARE_FOR_SUBMISSION`, `REJECTED`, `DEVELOPER_REJECTED` |
| `isInReview` | `WAITING_FOR_REVIEW`, `IN_REVIEW` |
| `isApproved` | `ACCEPTED`, `APPROVED` |

### `ProductVersionRepository`

```swift
@Mockable
public protocol ProductVersionRepository: Sendable {
    func listInAppPurchaseVersions(iapId: String) async throws -> [ProductVersion]
    func listSubscriptionVersions(subscriptionId: String) async throws -> [ProductVersion]
    func listSubscriptionGroupVersions(groupId: String) async throws -> [ProductVersion]
}
```

### `ReviewItemTarget`

What an item sends to review: `.appStoreVersion(id)`, `.inAppPurchaseVersion(id)`, `.subscriptionVersion(id)`, `.subscriptionGroupVersion(id)`. `init?(versionId:iapVersionId:subscriptionVersionId:subscriptionGroupVersionId:)` accepts exactly one id (shared by the CLI flags and the REST body).

### `SubmissionRepository` (additions)

```swift
func createSubmission(appId: String, platform: AppStorePlatform) async throws -> ReviewSubmission  // reuses the open draft
func addItem(submissionId: String, target: ReviewItemTarget) async throws -> ReviewSubmissionItem
func removeItem(itemId: String) async throws
func submit(submissionId: String) async throws -> ReviewSubmission
```

`ReviewSubmission.isEditable` (`READY_FOR_REVIEW`, `UNRESOLVED_ISSUES`) gates its `addItem` and `submit` affordances; an item in `READY_FOR_REVIEW` offers `remove`.

### `SubmissionPlanner`, `SubmissionPlan`, `PlannedReviewItem`

`SubmissionPlanner(iapRepo:groupRepo:subscriptionRepo:productVersionRepo:).plan(for: AppStoreVersion) -> SubmissionPlan` applies the rules above. `SubmissionPlan` has `appId`, `platform`, `items: [PlannedReviewItem]` and `submit(repo:)`. `PlannedReviewItem` has `kind` (`ReviewSubmissionItemLinkedResource`), `versionId`, `productId`, `name`; affordances `getVersion` (app version) or `listVersions` (product).

### `ReviewSubmissionError`

`.refused(message:reasons:)` — thrown by `addItem` and `submit` when Apple answers 4xx; `reasons` are the details from `meta.associatedErrors`, sorted by path.

---

## File Map

```
Sources/
├── Domain/
│   ├── Apps/ProductVersions/
│   │   ├── ProductVersion.swift                 # model, kind, state, affordances
│   │   ├── ProductVersion+RESTRoutes.swift      # iap/subscriptions/subscription-groups versions routes
│   │   └── ProductVersionRepository.swift
│   └── Submissions/
│       ├── ReviewItemTarget.swift
│       ├── ReviewSubmissionError.swift
│       └── SubmissionPlan.swift                 # SubmissionPlanner, SubmissionPlan, PlannedReviewItem
├── Infrastructure/
│   ├── Apps/ProductVersions/SDKProductVersionRepository.swift
│   └── Submissions/OpenAPISubmissionRepository.swift   # createSubmission, addItem, removeItem, submit
└── ASCCommand/Commands/
    ├── IAP/IAPVersionsCommand.swift, IAPVersionsList.swift
    ├── Subscriptions/SubscriptionVersionsCommand.swift, SubscriptionVersionsList.swift
    ├── SubscriptionGroups/SubscriptionGroupVersionsCommand.swift, SubscriptionGroupVersionsList.swift
    ├── ReviewSubmissions/ReviewSubmissionsCreate.swift, ReviewSubmissionsSubmit.swift,
    │                     ReviewSubmissionItemsAdd.swift, ReviewSubmissionItemsRemove.swift
    └── Versions/VersionsSubmit.swift            # --with-products, --dry-run

Tests/
├── DomainTests/Apps/ProductVersions/ProductVersionTests.swift
├── DomainTests/Submissions/ReviewItemTargetTests.swift, SubmissionPlannerTests.swift
├── InfrastructureTests/Apps/ProductVersions/SDKProductVersionRepositoryTests.swift
├── InfrastructureTests/Submissions/SDKSubmissionRepositoryTests.swift
└── ASCCommandTests/Commands/
    ├── IAP/IAPVersionsListTests.swift, Subscriptions/SubscriptionVersionsListTests.swift,
    │   SubscriptionGroups/SubscriptionGroupVersionsListTests.swift
    ├── ReviewSubmissions/ReviewSubmissionsBuildTests.swift
    ├── Versions/VersionsSubmitTests.swift
    └── Web/RESTRoutesTests.swift
```

| Wiring file | Purpose |
|-------------|---------|
| `Sources/ASCCommand/Commands/Web/Controllers/ProductVersionsController.swift` | REST: the three `…/versions` routes |
| `Sources/ASCCommand/Commands/Web/Controllers/ReviewSubmissionsController.swift` | REST: create, items add/remove, submit |
| `Sources/ASCCommand/Commands/Web/Controllers/VersionSubmissionController.swift` | REST: `POST /versions/:id/submit` |
| `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` | Constructs the three controllers |
| `Sources/ASCCommand/ClientProvider.swift` / `Sources/Infrastructure/Client/ClientFactory.swift` | `makeProductVersionRepository` |
| `Sources/Domain/Shared/RESTPathResolver.swift` | Touches `_productVersionRoutes`; `add` resolves like `create` |
| `Sources/Domain/Shared/Affordance.swift` | `remove` maps to `DELETE` |

---

## API Reference

| Operation | Endpoint | SDK call | Repository method |
|-----------|----------|----------|-------------------|
| IAP versions | `GET /v2/inAppPurchases/{id}/versions?limit=200` | `APIEndpoint.v2.inAppPurchases.id(id).versions.get` | `listInAppPurchaseVersions(iapId:)` |
| Subscription versions | `GET /v1/subscriptions/{id}/versions?limit=200` | `APIEndpoint.v1.subscriptions.id(id).versions.get` | `listSubscriptionVersions(subscriptionId:)` |
| Group versions | `GET /v1/subscriptionGroups/{id}/versions?limit=200` | `APIEndpoint.v1.subscriptionGroups.id(id).versions.get` | `listSubscriptionGroupVersions(groupId:)` |
| Open draft | `GET /v1/reviewSubmissions?filter[app]&filter[platform]&filter[state]=READY_FOR_REVIEW,UNRESOLVED_ISSUES`, else `POST /v1/reviewSubmissions` | `APIEndpoint.v1.reviewSubmissions.get` / `.post` | `createSubmission(appId:platform:)` |
| Add item | `POST /v1/reviewSubmissionItems` (relationship `appStoreVersion`, `inAppPurchaseVersion`, `subscriptionVersion` or `subscriptionGroupVersion`) | `APIEndpoint.v1.reviewSubmissionItems.post` | `addItem(submissionId:target:)` |
| Remove item | `DELETE /v1/reviewSubmissionItems/{id}` | `APIEndpoint.v1.reviewSubmissionItems.id(id).delete` | `removeItem(itemId:)` |
| Submit | `PATCH /v1/reviewSubmissions/{id}` `{submitted: true}`, then `GET …?include=app` | `.patch` / `.get` | `submit(submissionId:)` |

Apple does not allow deleting a review submission, and cancels only submitted ones; an unused draft stays `READY_FOR_REVIEW` and is reused by the next `create`.

---

## Testing

```swift
@Test func `a ready subscription joins the plan after its group's version`() async throws {
    // … groups → [Pro], subscriptions → [Monthly (READY_TO_SUBMIT)], versions submittable
    let plan = try await repos.planner.plan(for: version)
    #expect(plan.items == [
        PlannedReviewItem(kind: .appStoreVersion, versionId: "v-1", productId: "app-1", name: "1.0"),
        PlannedReviewItem(kind: .subscriptionGroupVersion, versionId: "gv-1", productId: "grp-1", name: "Pro"),
        PlannedReviewItem(kind: .subscriptionVersion, versionId: "sv-1", productId: "sub-1", name: "Monthly"),
    ])
}
```

```bash
swift test --filter 'ProductVersion|SubmissionPlanner|ReviewItemTarget|SDKSubmissionRepository|ReviewSubmissionsBuild|VersionsSubmit'
```

---

## Extending

- **Paging products.** The planner reads up to 200 IAPs, groups and subscriptions per parent (one page); follow `nextCursor` if an app ever exceeds that.
- **Other reviewable resources.** Custom product pages, in-app events and Game Center versions can already be items; add a `ReviewItemTarget` case and a flag:

```swift
case appEvent(String)            // ReviewItemTarget
// ReviewSubmissionItemsAdd
@Option(name: .long) var appEventId: String?
```

- **Readiness.** `asc versions check-readiness` doesn't yet check what Apple checks on submission (required device screenshot sizes, content rights, App Privacy answers, pricing); `ReviewSubmissionError.refused` surfaces those today.

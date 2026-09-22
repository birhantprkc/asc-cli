# Product Page Optimization (Experiments)

App Store **Product Page Optimization** tests — run up to three alternate product pages (treatments) against the original and let the App Store split traffic between them. Apple's API calls these `appStoreVersionExperiments` (v2); the CLI uses `experiments`.

A test is app-scoped (it is not attached to a specific version) and can be created when the app is **Ready for Distribution** or **Pre-Order Ready for Distribution**. Each treatment can test an alternate app icon (`--app-icon-name`) and, per locale, its own screenshot / preview sets.

Resource hierarchy:

```
App → AppStoreVersionExperiment → ExperimentTreatment → ExperimentTreatmentLocalization
```

## 1. CLI Usage

### `asc experiments`

| Command | Required flags | Optional flags | Notes |
|---------|----------------|----------------|-------|
| `asc experiments list` | `--app-id` | `--state <STATE>`, `--limit <n>` | `--state` accepts any `AppStoreVersionExperimentState` raw value (case-insensitive) |
| `asc experiments get` | `--experiment-id` | | |
| `asc experiments create` | `--app-id`, `--name`, `--traffic-proportion <1-100>` | `--platform ios\|macos\|tvos\|visionos` (default `ios`) | Traffic proportion is validated client-side |
| `asc experiments update` | `--experiment-id` | `--name`, `--traffic-proportion` | At least one field required |
| `asc experiments start` | `--experiment-id` | | `PATCH { started: true }` |
| `asc experiments stop` | `--experiment-id` | | `PATCH { started: false }` |
| `asc experiments delete` | `--experiment-id` | | |

### `asc experiment-treatments`

| Command | Required flags | Optional flags |
|---------|----------------|----------------|
| `asc experiment-treatments list` | `--experiment-id` | `--limit <n>` |
| `asc experiment-treatments create` | `--experiment-id`, `--name` | `--app-icon-name <asset>` |
| `asc experiment-treatments update` | `--treatment-id` | `--name`, `--app-icon-name` (at least one) |
| `asc experiment-treatments delete` | `--treatment-id` | |

### `asc experiment-treatment-localizations`

| Command | Required flags | Optional flags |
|---------|----------------|----------------|
| `asc experiment-treatment-localizations list` | `--treatment-id` | `--limit <n>` |
| `asc experiment-treatment-localizations create` | `--treatment-id`, `--locale` | |
| `asc experiment-treatment-localizations delete` | `--localization-id` | |

### Examples

```bash
asc experiments list --app-id 6792459661 --pretty
asc experiments list --app-id 6792459661 --state APPROVED --output table
asc experiments create --app-id 6792459661 --name "Icon test" --platform ios --traffic-proportion 30
asc experiment-treatments create --experiment-id exp-1 --name "Blue icon" --app-icon-name AppIcon-Blue
asc experiment-treatment-localizations create --treatment-id trt-1 --locale en-US
asc experiments start --experiment-id exp-1
```

### Output samples

JSON (`--pretty`) for an editable test:

```json
{
  "data" : [
    {
      "affordances" : {
        "createTreatment" : "asc experiment-treatments create --experiment-id exp-1 --name <name>",
        "delete" : "asc experiments delete --experiment-id exp-1",
        "listSiblings" : "asc experiments list --app-id app-1",
        "listTreatments" : "asc experiment-treatments list --experiment-id exp-1",
        "update" : "asc experiments update --experiment-id exp-1"
      },
      "appId" : "app-1",
      "canStart" : false,
      "id" : "exp-1",
      "isReviewRequired" : true,
      "isRunning" : false,
      "name" : "Icon test",
      "platform" : "IOS",
      "state" : "PREPARE_FOR_SUBMISSION",
      "trafficProportion" : 30
    }
  ]
}
```

`startDate`, `endDate` and `latestControlVersionId` are omitted when nil.

Table (`--output table`):

```
ID     Name       Platform  Traffic %  State                   Started
-----  ---------  --------  ---------  ----------------------  -------
exp-1  Icon test  iOS       30         PREPARE_FOR_SUBMISSION  -
```

## 2. REST Endpoints

| Path | Method | Body / query |
|------|--------|--------------|
| `/api/v1/apps/:appId/experiments` | GET | `?state=&limit=` |
| `/api/v1/apps/:appId/experiments` | POST | `{ "name", "trafficProportion", "platform"? }` |
| `/api/v1/experiments/:experimentId` | GET | |
| `/api/v1/experiments/:experimentId` | PATCH | `{ "name"?, "trafficProportion"? }` |
| `/api/v1/experiments/:experimentId/start` | POST | |
| `/api/v1/experiments/:experimentId/stop` | POST | |
| `/api/v1/experiments/:experimentId` | DELETE | |
| `/api/v1/experiments/:experimentId/experiment-treatments` | GET | `?limit=` |
| `/api/v1/experiments/:experimentId/experiment-treatments` | POST | `{ "name", "appIconName"? }` |
| `/api/v1/experiment-treatments/:treatmentId` | PATCH | `{ "name"?, "appIconName"? }` |
| `/api/v1/experiment-treatments/:treatmentId` | DELETE | |
| `/api/v1/experiment-treatments/:treatmentId/experiment-treatment-localizations` | GET | `?limit=` |
| `/api/v1/experiment-treatments/:treatmentId/experiment-treatment-localizations` | POST | `{ "locale" }` |
| `/api/v1/experiment-treatment-localizations/:localizationId` | DELETE | |

Query-param mapping (CLI flag → REST query):

| CLI flag | REST query |
|----------|------------|
| `--state` | `?state=` |
| `--limit` | `?limit=` |

Discovery: `GET /api/v1/apps` items carry `_links.listExperiments` → `/api/v1/apps/:appId/experiments`. Each experiment's `_links` include `listTreatments`, and conditionally `update`/`delete`/`createTreatment` (editable), `start` (approved, not started) or `stop` (running).

```bash
curl "http://127.0.0.1:8420/api/v1/apps/6792459661/experiments?state=APPROVED&limit=5"
curl -X POST -H 'Content-Type: application/json' \
  -d '{"name":"Icon test","platform":"ios","trafficProportion":30}' \
  http://127.0.0.1:8420/api/v1/apps/6792459661/experiments
curl -X POST http://127.0.0.1:8420/api/v1/experiments/exp-1/start
```

## 3. Typical Workflow

```bash
APP_ID=6792459661

# 1. Create the test (app must be live / pre-order ready)
EXP=$(asc experiments create --app-id $APP_ID --name "Icon test" --traffic-proportion 30 \
      | jq -r '.data[0].id')

# 2. Add up to three treatments
TRT=$(asc experiment-treatments create --experiment-id $EXP --name "Blue icon" --app-icon-name AppIcon-Blue \
      | jq -r '.data[0].id')

# 3. Choose the locales included in the treatment
asc experiment-treatment-localizations create --treatment-id $TRT --locale en-US
asc experiment-treatment-localizations create --treatment-id $TRT --locale de-DE

# 4. Submit for review (via review-submissions) and wait for state ACCEPTED/APPROVED
asc experiments get --experiment-id $EXP | jq '.data[0] | {state, canStart}'

# 5. Start serving traffic, then stop when you have a winner (tests auto-complete after 90 days)
asc experiments start --experiment-id $EXP
asc experiments stop  --experiment-id $EXP
```

## 4. Architecture

```
┌────────────────────────── ASCCommand ───────────────────────────┐
│ Commands/Experiments/                                            │
│   ExperimentsCommand.swift (3 command groups)                    │
│   Experiments{List,Get,Create,Update,Start,Stop,Delete}.swift    │
│   ExperimentTreatments{List,Create,Update,Delete}.swift          │
│   ExperimentTreatmentLocalizations{List,Create,Delete}.swift     │
│ Commands/Web/Controllers/ExperimentsController.swift             │
└───────────────────────────────┬─────────────────────────────────┘
                                │ ExperimentRepository (protocol)
┌────────────────────────── Infrastructure ───────────────────────┐
│ Apps/Experiments/SDKExperimentRepository.swift                   │
│   injects appId / experimentId / treatmentId into every model    │
│   formats SDK `Date` → ISO-8601 strings                          │
└───────────────────────────────┬─────────────────────────────────┘
                                │ implements
┌────────────────────────────── Domain ───────────────────────────┐
│ Apps/Experiments/                                                │
│   AppStoreVersionExperiment (+ AppStoreVersionExperimentState)   │
│   ExperimentTreatment                                            │
│   ExperimentTreatmentLocalization                                │
│   ExperimentRepository (@Mockable)                               │
│   AppStoreVersionExperiment+RESTRoutes                           │
└──────────────────────────────────────────────────────────────────┘
```

Dependencies flow strictly downward. The Domain has zero I/O; the same `execute(repo:affordanceMode:)` serves both CLI and REST.

## 5. Domain Models

### `AppStoreVersionExperiment`

```swift
public struct AppStoreVersionExperiment: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String                       // injected by Infrastructure
    public let name: String
    public let platform: AppStorePlatform
    public let trafficProportion: Int              // 1–100
    public let state: AppStoreVersionExperimentState
    public let isReviewRequired: Bool
    public let startDate: String?                  // ISO-8601
    public let endDate: String?                    // ISO-8601
    public let latestControlVersionId: String?

    public var isRunning: Bool   // state.isApproved && startDate != nil && endDate == nil
    public var canStart: Bool    // state.isApproved && startDate == nil
}
```

`isRunning` and `canStart` are encoded into JSON output; nil optionals are omitted.

### `AppStoreVersionExperimentState`

| Case | Raw value | `isEditable` | `isPendingReview` | `isApproved` | `isFinished` |
|------|-----------|:---:|:---:|:---:|:---:|
| `prepareForSubmission` | `PREPARE_FOR_SUBMISSION` | ✓ | | | |
| `readyForReview` | `READY_FOR_REVIEW` | ✓ | | | |
| `waitingForReview` | `WAITING_FOR_REVIEW` | | ✓ | | |
| `inReview` | `IN_REVIEW` | | ✓ | | |
| `accepted` | `ACCEPTED` | | | ✓ | |
| `approved` | `APPROVED` | | | ✓ | |
| `rejected` | `REJECTED` | ✓ | | | |
| `completed` | `COMPLETED` | | | | ✓ |
| `stopped` | `STOPPED` | | | | ✓ |

### Affordances (state-aware)

| Key | Command | Shown when |
|-----|---------|------------|
| `listSiblings` | `experiments list --app-id` | always |
| `listTreatments` | `experiment-treatments list --experiment-id` | always |
| `createTreatment` | `experiment-treatments create --experiment-id --name <name>` | `state.isEditable` |
| `update` | `experiments update --experiment-id` | `state.isEditable` |
| `delete` | `experiments delete --experiment-id` | `state.isEditable` |
| `start` | `experiments start --experiment-id` | `canStart` |
| `stop` | `experiments stop --experiment-id` | `isRunning` |

### `ExperimentTreatment`

```swift
public struct ExperimentTreatment: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let experimentId: String   // injected by Infrastructure
    public let name: String
    public let appIconName: String?   // alternate icon asset under test
    public let promotedDate: String?  // ISO-8601, set once promoted to the live page
}
```

Affordances: `listSiblings`, `listLocalizations`, `createLocalization` (`--locale <locale>`), `update`, `delete`.

### `ExperimentTreatmentLocalization`

```swift
public struct ExperimentTreatmentLocalization: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let treatmentId: String    // injected by Infrastructure
    public let locale: String
}
```

Affordances: `listSiblings`, `delete`.

### `ExperimentRepository`

```swift
@Mockable
public protocol ExperimentRepository: Sendable {
    func listExperiments(appId: String, state: AppStoreVersionExperimentState?, limit: Int?) async throws -> PaginatedResponse<AppStoreVersionExperiment>
    func getExperiment(experimentId: String) async throws -> AppStoreVersionExperiment
    func createExperiment(appId: String, name: String, platform: AppStorePlatform, trafficProportion: Int) async throws -> AppStoreVersionExperiment
    func updateExperiment(experimentId: String, name: String?, trafficProportion: Int?, isStarted: Bool?) async throws -> AppStoreVersionExperiment
    func deleteExperiment(experimentId: String) async throws

    func listTreatments(experimentId: String, limit: Int?) async throws -> PaginatedResponse<ExperimentTreatment>
    func createTreatment(experimentId: String, name: String, appIconName: String?) async throws -> ExperimentTreatment
    func updateTreatment(treatmentId: String, name: String?, appIconName: String?) async throws -> ExperimentTreatment
    func deleteTreatment(treatmentId: String) async throws

    func listTreatmentLocalizations(treatmentId: String, limit: Int?) async throws -> [ExperimentTreatmentLocalization]
    func createTreatmentLocalization(treatmentId: String, locale: String) async throws -> ExperimentTreatmentLocalization
    func deleteTreatmentLocalization(localizationId: String) async throws
}
```

## 6. File Map

```
Sources/
├── Domain/Apps/Experiments/
│   ├── AppStoreVersionExperiment.swift
│   ├── AppStoreVersionExperiment+RESTRoutes.swift
│   ├── ExperimentTreatment.swift
│   ├── ExperimentTreatmentLocalization.swift
│   └── ExperimentRepository.swift
├── Infrastructure/Apps/Experiments/
│   └── SDKExperimentRepository.swift
└── ASCCommand/
    ├── Commands/Experiments/
    │   ├── ExperimentsCommand.swift
    │   ├── ExperimentsList.swift / Get / Create / Update / Start / Stop / Delete
    │   ├── ExperimentTreatmentsList.swift / Create / Update / Delete
    │   └── ExperimentTreatmentLocalizationsList.swift / Create / Delete
    └── Commands/Web/Controllers/ExperimentsController.swift

Tests/
├── DomainTests/Apps/Experiments/
│   ├── AppStoreVersionExperimentTests.swift
│   ├── ExperimentTreatmentTests.swift
│   └── ExperimentTreatmentLocalizationTests.swift
├── InfrastructureTests/Apps/Experiments/SDKExperimentRepositoryTests.swift
└── ASCCommandTests/Commands/Experiments/
    ├── ExperimentsTests.swift
    ├── ExperimentTreatmentsTests.swift
    └── ExperimentTreatmentLocalizationsTests.swift
```

| Wiring file | Change |
|-------------|--------|
| `Sources/Domain/Apps/App.swift` | `listExperiments` affordance on `App` |
| `Sources/Domain/Shared/RESTPathResolver.swift` | `_ = _experimentRoutes` in `ensureInitialized()` |
| `Sources/Infrastructure/Client/ClientFactory.swift` | `makeExperimentRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | `makeExperimentRepository()` |
| `Sources/ASCCommand/ASC.swift` | registers the three command groups |
| `Sources/ASCCommand/Commands/Web/RESTRoutes.swift` | wires `ExperimentsController` |
| `Tests/ASCCommandTests/Commands/Web/RESTRoutesTests.swift` | REST `_links` tests |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | `makeExperiment`, `makeExperimentTreatment`, `makeExperimentTreatmentLocalization` |

## 7. API Reference

| ASC endpoint | SDK call | Repository method |
|--------------|----------|-------------------|
| `GET /v1/apps/{id}/appStoreVersionExperimentsV2` | `APIEndpoint.v1.apps.id(_).appStoreVersionExperimentsV2.get(parameters:)` | `listExperiments` |
| `GET /v2/appStoreVersionExperiments/{id}` | `APIEndpoint.v2.appStoreVersionExperiments.id(_).get()` | `getExperiment` |
| `POST /v2/appStoreVersionExperiments` | `APIEndpoint.v2.appStoreVersionExperiments.post(_)` | `createExperiment` |
| `PATCH /v2/appStoreVersionExperiments/{id}` | `APIEndpoint.v2.appStoreVersionExperiments.id(_).patch(_)` | `updateExperiment` (also `start`/`stop` via `started`) |
| `DELETE /v2/appStoreVersionExperiments/{id}` | `APIEndpoint.v2.appStoreVersionExperiments.id(_).delete` | `deleteExperiment` |
| `GET /v2/appStoreVersionExperiments/{id}/appStoreVersionExperimentTreatments` | `….id(_).appStoreVersionExperimentTreatments.get(parameters:)` | `listTreatments` |
| `POST /v1/appStoreVersionExperimentTreatments` | `APIEndpoint.v1.appStoreVersionExperimentTreatments.post(_)` | `createTreatment` |
| `PATCH /v1/appStoreVersionExperimentTreatments/{id}` | `….id(_).patch(_)` | `updateTreatment` |
| `DELETE /v1/appStoreVersionExperimentTreatments/{id}` | `….id(_).delete` | `deleteTreatment` |
| `GET /v1/appStoreVersionExperimentTreatments/{id}/appStoreVersionExperimentTreatmentLocalizations` | `….id(_).appStoreVersionExperimentTreatmentLocalizations.get(parameters:)` | `listTreatmentLocalizations` |
| `POST /v1/appStoreVersionExperimentTreatmentLocalizations` | `APIEndpoint.v1.appStoreVersionExperimentTreatmentLocalizations.post(_)` | `createTreatmentLocalization` |
| `DELETE /v1/appStoreVersionExperimentTreatmentLocalizations/{id}` | `….id(_).delete` | `deleteTreatmentLocalization` |

Parent IDs: `listExperiments`/`createExperiment` inject the request's `appId`. Apple omits relationships from GET unless included and from PATCH always, so `getExperiment` requests `include=app` and `updateExperiment` re-reads the experiment after the PATCH (two calls) to keep `appId` populated. Treatments follow the same rule: list/create inject `experimentId` from the request; `updateTreatment` re-reads with `include=appStoreVersionExperimentV2`. An empty parent ID would silently break every `--app-id`/`--experiment-id` affordance, which is why the extra call is worth it.

## 8. Testing

```swift
@Test func `approved but unstarted experiment offers start only`() {
    let exp = MockRepositoryFactory.makeExperiment(id: "exp-1", appId: "app-1", state: .approved)
    #expect(exp.affordances["start"] == "asc experiments start --experiment-id exp-1")
    #expect(exp.affordances["stop"] == nil)
    #expect(exp.affordances["update"] == nil)
}
```

```bash
swift test --filter 'AppStoreVersionExperimentTests|ExperimentTreatmentTests|SDKExperimentRepositoryTests|ExperimentsListTests'
```

## 9. Extending

**Attach screenshot sets to a treatment localization.** ASC exposes `GET /v1/appStoreVersionExperimentTreatmentLocalizations/{id}/appScreenshotSets`, and `AppScreenshotSetCreateRequest` accepts an `appStoreVersionExperimentTreatmentLocalization` relationship. The natural next step is a `ScreenshotRepository` method that targets a treatment localization instead of a version localization:

```swift
// Domain/Apps/Versions/Localizations/ScreenshotSets/ScreenshotRepository.swift
func createScreenshotSet(treatmentLocalizationId: String, displayType: ScreenshotDisplayType) async throws -> AppScreenshotSet
```

and a `createScreenshotSet` affordance on `ExperimentTreatmentLocalization`. App preview sets follow the same shape (`…/appPreviewSets`).

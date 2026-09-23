# Xcode Cloud

Read Xcode Cloud data, manage workflows, and start CI builds through the App Store Connect API.

---

## CLI Usage

### `asc xcode-cloud products list`

List Xcode Cloud products (one per app enrolled in Xcode Cloud).

```
asc xcode-cloud products list [--app-id <id>] [--output json|table|markdown] [--pretty]
```

| Flag | Description |
|---|---|
| `--app-id` | Filter by App Store Connect app ID |
| `--output` | Output format: `json` (default), `table`, `markdown` |
| `--pretty` | Pretty-print JSON |

**Example:**

```bash
asc xcode-cloud products list --app-id 1234567890 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "abc123",
      "appId": "1234567890",
      "name": "My App",
      "productType": "APP",
      "affordances": {
        "listWorkflows": "asc xcode-cloud workflows list --product-id abc123",
        "listProducts": "asc xcode-cloud products list --app-id 1234567890"
      }
    }
  ]
}
```

**Table output:**

```
ID       Name    Type
-------- ------- ----
abc123   My App  APP
```

---

### `asc xcode-cloud workflows list`

List workflows defined for an Xcode Cloud product.

```
asc xcode-cloud workflows list --product-id <id> [--output json|table|markdown] [--pretty]
```

| Flag | Description |
|---|---|
| `--product-id` | Xcode Cloud product ID (required) |

**Example:**

```bash
asc xcode-cloud workflows list --product-id abc123 --pretty
```

**JSON output:**

```json
{
  "data": [
    {
      "id": "wf-1",
      "productId": "abc123",
      "name": "CI Build",
      "isEnabled": true,
      "isLockedForEditing": false,
      "affordances": {
        "listBuildRuns": "asc xcode-cloud builds list --workflow-id wf-1",
        "listWorkflows": "asc xcode-cloud workflows list --product-id abc123",
        "startBuild": "asc xcode-cloud builds start --workflow-id wf-1"
      }
    }
  ]
}
```

> **Note:** `startBuild` affordance only appears when `isEnabled` is `true`.

---

### `asc xcode-cloud builds list`

List build runs for a workflow.

```
asc xcode-cloud builds list --workflow-id <id> [--output json|table|markdown] [--pretty]
```

| Flag | Description |
|---|---|
| `--workflow-id` | Workflow ID (required) |

---

### `asc xcode-cloud builds get`

Get a specific build run by ID.

```
asc xcode-cloud builds get --build-run-id <id> [--output json|table|markdown] [--pretty]
```

| Flag | Description |
|---|---|
| `--build-run-id` | Build run ID (required) |

**JSON output:**

```json
{
  "data": [
    {
      "id": "run-42",
      "workflowId": "wf-1",
      "number": 42,
      "executionProgress": "COMPLETE",
      "completionStatus": "SUCCEEDED",
      "startReason": "MANUAL",
      "affordances": {
        "getBuildRun": "asc xcode-cloud builds get --build-run-id run-42",
        "listBuildRuns": "asc xcode-cloud builds list --workflow-id wf-1"
      }
    }
  ]
}
```

---

### `asc xcode-cloud builds start`

Start a new build run for a workflow.

```
asc xcode-cloud builds start --workflow-id <id> [--clean] [--output json|table|markdown] [--pretty]
```

| Flag | Description |
|---|---|
| `--workflow-id` | Workflow ID to start a build for (required) |
| `--clean` | Perform a clean build (removes derived data) |

**Example:**

```bash
asc xcode-cloud builds start --workflow-id wf-1 --clean --pretty
```

---

## Typical Workflow

```bash
# 1. Find the Xcode Cloud product for your app
asc xcode-cloud products list --app-id $(cat .asc/project.json | jq -r '.appId')

# 2. List workflows for the product
asc xcode-cloud workflows list --product-id <product-id>

# 3. Start a new build
asc xcode-cloud builds start --workflow-id <workflow-id>

# 4. Check the build status
asc xcode-cloud builds get --build-run-id <build-run-id>

# 5. List recent builds for a workflow
asc xcode-cloud builds list --workflow-id <workflow-id>
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         FEATURE: Xcode Cloud                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ASC API                   INFRASTRUCTURE               DOMAIN            │
│                                                                           │
│  GET /v1/ciProducts ─────▶ SDKXcodeCloud          ─▶ XcodeCloudProduct   │
│  GET /v1/ciProducts/{id}   ProductRepository          (appId injected     │
│                                                         from relationship) │
│                                                                           │
│  GET /v1/ciProducts/{id}  ─▶ SDKXcodeCloud        ─▶ XcodeCloudWorkflow  │
│     /workflows               WorkflowRepository       (productId injected │
│                                                         from param)       │
│                                                                           │
│  GET /v1/ciWorkflows/{id} ─▶ SDKXcodeCloud        ─▶ XcodeCloudBuildRun  │
│     /buildRuns               BuildRunRepository       (workflowId inject) │
│  GET /v1/ciBuildRuns/{id}                                                 │
│  POST /v1/ciBuildRuns                                                     │
│                                                                           │
│  ASCCommand                                                               │
│  XcodeCloudCommand (group: "xcode-cloud")                                 │
│   ├── XcodeCloudProductsCommand → XcodeCloudProductsList                 │
│   ├── XcodeCloudWorkflowsCommand → XcodeCloudWorkflowsList               │
│   └── XcodeCloudBuildsCommand                                             │
│       ├── XcodeCloudBuildsList                                            │
│       ├── XcodeCloudBuildsGet                                             │
│       └── XcodeCloudBuildsStart                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

**Layer dependency:** `ASCCommand → Infrastructure → Domain` (unidirectional).

---

## Domain Models

### `XcodeCloudProduct`

```swift
public struct XcodeCloudProduct: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String        // parent ID, injected by infrastructure
    public let name: String
    public let productType: XcodeCloudProductType
    public let createdDate: Date?   // omitted from JSON when nil
}
```

**Affordances:**

| Key | Value |
|---|---|
| `listWorkflows` | `asc xcode-cloud workflows list --product-id <id>` |
| `listProducts` | `asc xcode-cloud products list --app-id <appId>` |

### `XcodeCloudProductType`

```swift
public enum XcodeCloudProductType: String, Codable {
    case app = "APP"
    case framework = "FRAMEWORK"
}
```

### `XcodeCloudWorkflow`

```swift
public struct XcodeCloudWorkflow: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let productId: String        // parent ID, injected from request param
    public let name: String
    public let description: String?     // omitted from JSON when nil
    public let isEnabled: Bool
    public let isLockedForEditing: Bool
    public let containerFilePath: String?  // omitted from JSON when nil
}
```

**Affordances:**

| Key | Condition | Value |
|---|---|---|
| `listBuildRuns` | always | `asc xcode-cloud builds list --workflow-id <id>` |
| `listWorkflows` | always | `asc xcode-cloud workflows list --product-id <productId>` |
| `startBuild` | only when `isEnabled` | `asc xcode-cloud builds start --workflow-id <id>` |

### `XcodeCloudBuildRun`

```swift
public struct XcodeCloudBuildRun: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let workflowId: String          // parent ID, injected from request param
    public let number: Int?                // omitted from JSON when nil
    public let executionProgress: XcodeCloudBuildRunExecutionProgress
    public let completionStatus: XcodeCloudBuildRunCompletionStatus?  // nil while running
    public let startReason: XcodeCloudBuildRunStartReason?
    public let createdDate: Date?
    public let startedDate: Date?
    public let finishedDate: Date?
}
```

**Affordances:**

| Key | Value |
|---|---|
| `getBuildRun` | `asc xcode-cloud builds get --build-run-id <id>` |
| `listBuildRuns` | `asc xcode-cloud builds list --workflow-id <workflowId>` |

### `XcodeCloudBuildRunExecutionProgress`

```swift
public enum XcodeCloudBuildRunExecutionProgress: String, Codable {
    case pending = "PENDING"
    case running = "RUNNING"
    case complete = "COMPLETE"

    var isPending: Bool   // true when pending
    var isRunning: Bool   // true when running
    var isComplete: Bool  // true when complete
}
```

### `XcodeCloudBuildRunCompletionStatus`

```swift
public enum XcodeCloudBuildRunCompletionStatus: String, Codable {
    case succeeded = "SUCCEEDED"
    case failed = "FAILED"
    case errored = "ERRORED"
    case canceled = "CANCELED"
    case skipped = "SKIPPED"

    var isSucceeded: Bool  // true when succeeded
    var hasFailed: Bool    // true when failed or errored
}
```

### `XcodeCloudBuildRunStartReason`

```swift
public enum XcodeCloudBuildRunStartReason: String, Codable {
    case gitRefChange = "GIT_REF_CHANGE"
    case manual = "MANUAL"
    case manualRebuild = "MANUAL_REBUILD"
    case pullRequestOpen = "PULL_REQUEST_OPEN"
    case pullRequestUpdate = "PULL_REQUEST_UPDATE"
    case schedule = "SCHEDULE"
}
```

---

## File Map

```
Sources/
├── Domain/XcodeCloud/
│   ├── XcodeCloudProduct.swift               — struct + AffordanceProviding + XcodeCloudProductType
│   ├── XcodeCloudProductRepository.swift     — @Mockable protocol: listProducts(appId:)
│   ├── XcodeCloudWorkflow.swift              — struct + AffordanceProviding
│   ├── XcodeCloudWorkflowRepository.swift    — @Mockable protocol: listWorkflows(productId:)
│   ├── XcodeCloudBuildRun.swift              — struct + AffordanceProviding + enums
│   └── XcodeCloudBuildRunRepository.swift    — @Mockable protocol: list/get/start
├── Infrastructure/XcodeCloud/
│   ├── SDKXcodeCloudProductRepository.swift  — implements XcodeCloudProductRepository
│   ├── SDKXcodeCloudWorkflowRepository.swift — implements XcodeCloudWorkflowRepository
│   └── SDKXcodeCloudBuildRunRepository.swift — implements XcodeCloudBuildRunRepository
└── ASCCommand/Commands/XcodeCloud/
    └── XcodeCloudCommand.swift               — all 5 commands in one file

Tests/
├── DomainTests/XcodeCloud/
│   ├── XcodeCloudProductTests.swift
│   ├── XcodeCloudWorkflowTests.swift
│   └── XcodeCloudBuildRunTests.swift
├── InfrastructureTests/XcodeCloud/
│   ├── SDKXcodeCloudProductRepositoryTests.swift
│   ├── SDKXcodeCloudWorkflowRepositoryTests.swift
│   └── SDKXcodeCloudBuildRunRepositoryTests.swift
└── ASCCommandTests/Commands/XcodeCloud/
    └── XcodeCloudCommandTests.swift
```

**Wiring files modified:**

| File | Change |
|---|---|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeXcodeCloudProductRepository`, `makeXcodeCloudWorkflowRepository`, `makeXcodeCloudBuildRunRepository` |
| `Sources/ASCCommand/ClientProvider.swift` | Added matching static factory methods |
| `Sources/ASCCommand/ASC.swift` | Registered `XcodeCloudCommand` in subcommands |
| `Tests/DomainTests/TestHelpers/MockRepositoryFactory.swift` | Added `makeXcodeCloudProduct`, `makeXcodeCloudWorkflow`, `makeXcodeCloudBuildRun` |
| `Tests/DomainTests/Apps/AffordancesTests.swift` | Added affordance tests for all three models |

---

## API Reference

| Endpoint | SDK Call | Repository Method |
|---|---|---|
| `GET /v1/ciProducts` | `APIEndpoint.v1.ciProducts.get(parameters:)` | `XcodeCloudProductRepository.listProducts(appId:)` |
| `GET /v1/ciProducts/{id}/workflows` | `APIEndpoint.v1.ciProducts.id(_:).workflows.get()` | `XcodeCloudWorkflowRepository.listWorkflows(productId:)` |
| `GET /v1/ciWorkflows/{id}/buildRuns` | `APIEndpoint.v1.ciWorkflows.id(_:).buildRuns.get()` | `XcodeCloudBuildRunRepository.listBuildRuns(workflowId:)` |
| `GET /v1/ciBuildRuns/{id}` | `APIEndpoint.v1.ciBuildRuns.id(_:).get()` | `XcodeCloudBuildRunRepository.getBuildRun(id:)` |
| `POST /v1/ciBuildRuns` | `APIEndpoint.v1.ciBuildRuns.post(_:)` | `XcodeCloudBuildRunRepository.startBuildRun(workflowId:clean:)` |

**Parent ID injection:**
- `XcodeCloudProduct.appId` — injected from `CiProduct.relationships.app.data.id` (relationship data in SDK response)
- `XcodeCloudWorkflow.productId` — injected from `productId` request parameter
- `XcodeCloudBuildRun.workflowId` — injected from `workflowId` request parameter (or `relationships.workflow.data.id` for `getBuildRun`)

---

## Testing

```swift
@Test func `listed workflows include product id and affordances`() async throws {
    let mockRepo = MockXcodeCloudWorkflowRepository()
    given(mockRepo).listWorkflows(productId: .value("prod-1")).willReturn([
        XcodeCloudWorkflow(id: "wf-1", productId: "prod-1", name: "CI Build", isEnabled: true, isLockedForEditing: false),
    ])

    let cmd = try XcodeCloudWorkflowsList.parse(["--product-id", "prod-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output == """
    {
      "data" : [
        {
          "affordances" : {
            "listBuildRuns" : "asc xcode-cloud builds list --workflow-id wf-1",
            "listWorkflows" : "asc xcode-cloud workflows list --product-id prod-1",
            "startBuild" : "asc xcode-cloud builds start --workflow-id wf-1"
          },
          ...
        }
      ]
    }
    """)
}
```

```bash
swift test --filter 'XcodeCloud'
```

**37 tests across 11 suites** (domain, infrastructure, command layers).

---

## Extending

Natural next steps:

- **Cancel a build run** — `PATCH /v1/ciBuildRuns/{id}` with `cancelBuild` affordance on running builds
- **List build actions** — `GET /v1/ciBuildRuns/{id}/actions` → `XcodeCloudBuildAction` model
- **Workflow enable/disable** — `PATCH /v1/ciWorkflows/{id}` with toggle on locked/unlocked workflows
- **Filter builds by status** — add `--status` flag to `builds list` using `filterBuilds` query param

# Beta App Review

Manage TestFlight external testing beta app review submissions and review contact details.

## CLI Usage

### Submissions

#### List submissions for a build

```bash
asc beta-review submissions list --build-id <build-id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--build-id` | Yes | Build ID to filter submissions |

#### Submit a build for beta review

```bash
asc beta-review submissions create --build-id <build-id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--build-id` | Yes | Build ID to submit for beta review |

#### Get a specific submission

```bash
asc beta-review submissions get --submission-id <id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--submission-id` | Yes | Beta app review submission ID |

**Example output (JSON):**

```json
{
  "data": [
    {
      "id": "sub-1",
      "buildId": "build-42",
      "state": "WAITING_FOR_REVIEW",
      "affordances": {
        "getSubmission": "asc beta-review submissions get --submission-id sub-1",
        "listSubmissions": "asc beta-review submissions list --build-id build-42"
      }
    }
  ]
}
```

### Detail (Contact & Demo Account)

#### Get beta review detail for an app

```bash
asc beta-review detail get --app-id <app-id>
```

| Flag | Required | Description |
|------|----------|-------------|
| `--app-id` | Yes | App ID |

#### Update beta review detail

```bash
asc beta-review detail update --detail-id <id> \
  [--contact-first-name <name>] \
  [--contact-last-name <name>] \
  [--contact-phone <phone>] \
  [--contact-email <email>] \
  [--demo-account-name <name>] \
  [--demo-account-password <pass>] \
  [--demo-account-required] \
  [--notes <text>]
```

| Flag | Required | Description |
|------|----------|-------------|
| `--detail-id` | Yes | Beta app review detail ID |
| `--contact-first-name` | No | Contact first name |
| `--contact-last-name` | No | Contact last name |
| `--contact-phone` | No | Contact phone number |
| `--contact-email` | No | Contact email address |
| `--demo-account-name` | No | Demo account username |
| `--demo-account-password` | No | Demo account password |
| `--demo-account-required` | No | Flag: demo account is required |
| `--notes` | No | Review notes |

**Example output (JSON):**

```json
{
  "data": [
    {
      "id": "d-1",
      "appId": "app-1",
      "contactFirstName": "John",
      "contactLastName": "Doe",
      "contactPhone": "+1-555-0100",
      "contactEmail": "john@example.com",
      "demoAccountRequired": false,
      "affordances": {
        "getDetail": "asc beta-review detail get --app-id app-1",
        "updateDetail": "asc beta-review detail update --detail-id d-1"
      }
    }
  ]
}
```

## Typical Workflow

```bash
# 1. Upload a build
asc builds upload --file MyApp.ipa

# 2. Add the build to an external beta group
asc builds add-beta-group --build-id BUILD_ID --beta-group-id GROUP_ID

# 3. Set up beta review contact details
asc beta-review detail get --app-id APP_ID
asc beta-review detail update --detail-id DETAIL_ID \
  --contact-first-name "John" \
  --contact-last-name "Doe" \
  --contact-email "john@example.com" \
  --contact-phone "+1-555-0100"

# 4. Submit the build for beta app review
asc beta-review submissions create --build-id BUILD_ID

# 5. Check submission status
asc beta-review submissions list --build-id BUILD_ID
```

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│ ASCCommand                                               │
│  BetaReviewCommand                                       │
│    ├── submissions list/create/get                        │
│    └── detail get/update                                  │
├──────────────────────────────────────────────────────────┤
│ Infrastructure                                           │
│  SDKBetaAppReviewRepository                              │
│    ├── listSubmissions(buildId:)                          │
│    ├── createSubmission(buildId:)                         │
│    ├── getSubmission(id:)                                 │
│    ├── getDetail(appId:)                                  │
│    └── updateDetail(id:, update:)                         │
├──────────────────────────────────────────────────────────┤
│ Domain                                                   │
│  BetaAppReviewSubmission, BetaReviewState                │
│  BetaAppReviewDetail, BetaAppReviewDetailUpdate          │
│  @Mockable BetaAppReviewRepository                       │
└──────────────────────────────────────────────────────────┘
```

## Domain Models

### BetaAppReviewSubmission

```swift
public struct BetaAppReviewSubmission: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let buildId: String      // parent ID, injected by infrastructure
    public let state: BetaReviewState
    public let submittedDate: Date?

    // Semantic booleans
    public var isApproved: Bool
    public var isRejected: Bool
    public var isPending: Bool
    public var isInReview: Bool
}
```

**Affordances:** `getSubmission`, `listSubmissions`

### BetaReviewState

| Case | Raw Value |
|------|-----------|
| `waitingForReview` | `WAITING_FOR_REVIEW` |
| `inReview` | `IN_REVIEW` |
| `rejected` | `REJECTED` |
| `approved` | `APPROVED` |

### BetaAppReviewDetail

```swift
public struct BetaAppReviewDetail: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String        // parent ID, injected by infrastructure
    public let contactFirstName: String?
    public let contactLastName: String?
    public let contactPhone: String?
    public let contactEmail: String?
    public let demoAccountName: String?
    public let demoAccountPassword: String?
    public let demoAccountRequired: Bool
    public let notes: String?

    // Computed properties
    public var hasContact: Bool     // email && phone present
    public var demoAccountConfigured: Bool  // not required || credentials present
}
```

**Affordances:** `getDetail`, `updateDetail`

Custom Codable: nil optional fields are omitted from JSON output.

### BetaAppReviewDetailUpdate

All fields optional — only provided fields are sent to the API.

## File Map

```
Sources/
├── Domain/Apps/TestFlight/
│   ├── BetaAppReviewSubmission.swift    # Model + BetaReviewState enum
│   ├── BetaAppReviewDetail.swift        # Model + update struct
│   └── BetaAppReviewRepository.swift    # @Mockable protocol
├── Infrastructure/Apps/TestFlight/
│   └── SDKBetaAppReviewRepository.swift # SDK adapter
└── ASCCommand/Commands/BetaReview/
    ├── BetaReviewCommand.swift          # Parent + sub-commands
    ├── BetaReviewSubmissionsList.swift
    ├── BetaReviewSubmissionsCreate.swift
    ├── BetaReviewSubmissionsGet.swift
    ├── BetaReviewDetailGet.swift
    └── BetaReviewDetailUpdate.swift

Tests/
├── DomainTests/Apps/TestFlight/
│   ├── BetaAppReviewSubmissionTests.swift
│   └── BetaAppReviewDetailTests.swift
├── InfrastructureTests/Apps/TestFlight/
│   └── SDKBetaAppReviewRepositoryTests.swift
└── ASCCommandTests/Commands/BetaReview/
    ├── BetaReviewSubmissionsListTests.swift
    ├── BetaReviewSubmissionsCreateTests.swift
    ├── BetaReviewSubmissionsGetTests.swift
    ├── BetaReviewDetailGetTests.swift
    └── BetaReviewDetailUpdateTests.swift
```

| Wiring File | Change |
|-------------|--------|
| `ClientFactory.swift` | `makeBetaAppReviewRepository()` |
| `ClientProvider.swift` | `makeBetaAppReviewRepository()` |
| `ASC.swift` | Register `BetaReviewCommand` |

## API Reference

| Operation | Endpoint | SDK Call | Repository Method |
|-----------|----------|---------|-------------------|
| List submissions | `GET /v1/betaAppReviewSubmissions?filter[build]=` | `betaAppReviewSubmissions.get()` | `listSubmissions(buildId:)` |
| Create submission | `POST /v1/betaAppReviewSubmissions` | `betaAppReviewSubmissions.post()` | `createSubmission(buildId:)` |
| Get submission | `GET /v1/betaAppReviewSubmissions/{id}` | `betaAppReviewSubmissions.id().get()` | `getSubmission(id:)` |
| Get detail | `GET /v1/betaAppReviewDetails?filter[app]=` | `betaAppReviewDetails.get()` | `getDetail(appId:)` |
| Update detail | `PATCH /v1/betaAppReviewDetails/{id}` | `betaAppReviewDetails.id().patch()` | `updateDetail(id:, update:)` |

## Testing

```bash
swift test --filter 'BetaReview|BetaAppReview|SDKBetaAppReview'
# 33 tests in 8 suites
```

Representative test:

```swift
@Test func `listed submissions show id, buildId, state, and affordances`() async throws {
    let mockRepo = MockBetaAppReviewRepository()
    given(mockRepo).listSubmissions(buildId: .value("build-1"))
        .willReturn([
            BetaAppReviewSubmission(id: "sub-1", buildId: "build-1", state: .waitingForReview),
        ])

    let cmd = try BetaReviewSubmissionsList.parse(["--build-id", "build-1", "--pretty"])
    let output = try await cmd.execute(repo: mockRepo)

    #expect(output.contains("WAITING_FOR_REVIEW"))
    #expect(output.contains("asc beta-review submissions get --submission-id sub-1"))
}
```

## Extending

- Add `submitForBetaReview` affordance to `Build` model when build is processed and not expired
- Add beta review status check to `asc versions check-readiness`
- Support filtering submissions by state: `--state APPROVED`

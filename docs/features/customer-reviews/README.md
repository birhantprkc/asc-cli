# Customer Reviews & Review Responses Feature

Manage App Store customer reviews and developer responses via the App Store Connect API. List and inspect reviews left by users, then create or delete developer responses.

## CLI Usage

### List Reviews

List all customer reviews for an app, sorted by most recent first.

```bash
asc reviews list --app-id <APP_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--app-id` | *(required)* | App ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Examples:**

```bash
# Default JSON output
asc reviews list --app-id 123456789

# Table view
asc reviews list --app-id 123456789 --output table

# Pipe into jq to extract ratings
asc reviews list --app-id 123456789 | jq '.[].rating'
```

**Table output:**

```
ID        Rating  Title           Reviewer    Territory
--------  ------  --------------  ----------  ---------
rev-001   5       Great app!      user123     USA
rev-002   3       Needs work      reviewer7   GBR
rev-003   1       Crashed on me   angry_user  DEU
```

**JSON output (single item):**

```json
{
  "id": "rev-001",
  "appId": "123456789",
  "rating": 5,
  "title": "Great app!",
  "body": "Love using this app every day.",
  "reviewerNickname": "user123",
  "territory": "USA",
  "affordances": {
    "getResponse": "asc review-responses get --review-id rev-001",
    "respond": "asc review-responses create --review-id rev-001 --response-body \"\"",
    "listReviews": "asc reviews list --app-id 123456789"
  }
}
```

---

### Get Review

Get a single customer review by its ID.

```bash
asc reviews get --review-id <REVIEW_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--review-id` | *(required)* | Review ID |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc reviews get --review-id rev-001
```

---

### Get Review Response

Get the developer response to a customer review.

```bash
asc review-responses get --review-id <REVIEW_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--review-id` | *(required)* | Review ID (the parent review, not the response ID) |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Table output:**

```
ID        Review ID  Response Body                 State
--------  ---------  ----------------------------  ---------
resp-001  rev-001    Thank you for your feedback!   PUBLISHED
```

**JSON output:**

```json
{
  "id": "resp-001",
  "reviewId": "rev-001",
  "responseBody": "Thank you for your feedback!",
  "state": "PUBLISHED",
  "affordances": {
    "delete": "asc review-responses delete --response-id resp-001",
    "getReview": "asc reviews get --review-id rev-001"
  }
}
```

---

### Create Review Response

Create a developer response to a customer review.

```bash
asc review-responses create --review-id <REVIEW_ID> --response-body <TEXT>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--review-id` | *(required)* | Review ID to respond to |
| `--response-body` | *(required)* | Response body text |
| `--output` | `json` | Output format: `json`, `table`, `markdown` |
| `--pretty` | `false` | Pretty-print JSON |

**Example:**

```bash
asc review-responses create \
  --review-id rev-001 \
  --response-body "Thanks for the feedback! We fixed the crash in v2.1."
```

---

### Delete Review Response

Delete a developer response to a customer review.

```bash
asc review-responses delete --response-id <RESPONSE_ID>
```

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--response-id` | *(required)* | Response ID to delete |

**Example:**

```bash
asc review-responses delete --response-id resp-001
```

---

## Typical Workflow

```bash
# 1. Find your app
asc apps list --output table

# 2. List customer reviews
asc reviews list --app-id 123456789 --output table

# 3. Read a specific review
asc reviews get --review-id rev-001 --pretty

# 4. Check if there is already a response
asc review-responses get --review-id rev-001

# 5. Respond to the review
asc review-responses create \
  --review-id rev-001 \
  --response-body "Thank you! We appreciate your feedback."

# 6. If you need to revise, delete and recreate
asc review-responses delete --response-id resp-001
asc review-responses create \
  --review-id rev-001 \
  --response-body "Updated response with more detail."
```

Each response includes an `affordances` field with ready-to-run follow-up commands, so an AI agent can navigate the hierarchy without knowing the full command tree.

---

## Architecture

```
+---------------------------------------------------------------------------+
|                   Customer Reviews Feature                                |
+---------------------------------------------------------------------------+
|                                                                           |
|  ASC API                    Infrastructure             Domain             |
|  +------------------------+ +----------------------+ +-----------------+  |
|  | GET /v1/apps/{id}/     | |                      | | CustomerReview  |  |
|  |   customerReviews      |->| SDKCustomerReview    |->| (struct)        |  |
|  |                        | |   Repository         | +-----------------+  |
|  | GET /v1/               | |                      | +-----------------+  |
|  |   customerReviews/{id} |->| (implements          |->| CustomerReview  |  |
|  |                        | |  CustomerReview-      | |   Response      |  |
|  | GET /v1/               | |  Repository)          | |   (struct)      |  |
|  |   customerReviews/{id}/| |                      | +-----------------+  |
|  |   response             |->|  Maps SDK types to   | +-----------------+  |
|  |                        | |  domain types,        | | ReviewResponse  |  |
|  | POST /v1/              | |  injects parent IDs   | |   State (enum)  |  |
|  |   customerReview-      | |                      | +-----------------+  |
|  |   Responses            | +----------------------+                      |
|  |                        |                                               |
|  | DELETE /v1/            |                                               |
|  |   customerReview-      |                                               |
|  |   Responses/{id}       |                                               |
|  +------------------------+                                               |
|                                                                           |
|  +-------------------------------------------------------------------+   |
|  |  ASCCommand Layer                                                  |   |
|  |  asc reviews list --app-id <id>                                   |   |
|  |  asc reviews get --review-id <id>                                 |   |
|  |  asc review-responses get --review-id <id>                        |   |
|  |  asc review-responses create --review-id <id> --response-body <t> |   |
|  |  asc review-responses delete --response-id <id>                   |   |
|  +-------------------------------------------------------------------+   |
+---------------------------------------------------------------------------+
```

**Dependency direction:** `ASCCommand -> Infrastructure -> Domain`

The domain layer has zero dependency on the SDK or networking. Infrastructure adapts SDK types to domain types. Commands depend only on `CustomerReviewRepository` (the protocol), never on the SDK directly.

---

## Domain Models

### `CustomerReview`

A customer review left on an app in the App Store.

```swift
public struct CustomerReview: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let appId: String              // Parent ID, injected by Infrastructure
    public let rating: Int                // 1-5 star rating
    public let title: String?             // Review title
    public let body: String?              // Review body text
    public let reviewerNickname: String?  // Display name of reviewer
    public let createdDate: Date?         // When the review was posted
    public let territory: String?         // Territory code (e.g. "USA", "GBR")
}
```

**Custom Codable:** Uses `encodeIfPresent` to omit nil fields (`title`, `body`, `reviewerNickname`, `createdDate`, `territory`) from JSON output.

**Affordances:**

| Key | Command | Description |
|-----|---------|-------------|
| `getResponse` | `asc review-responses get --review-id <id>` | Get the developer response |
| `respond` | `asc review-responses create --review-id <id> --response-body ""` | Create a response |
| `listReviews` | `asc reviews list --app-id <appId>` | List all reviews for the app |

### `CustomerReviewResponse`

A developer response to a customer review.

```swift
public struct CustomerReviewResponse: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let reviewId: String           // Parent ID, injected by Infrastructure
    public let responseBody: String       // The response text
    public let lastModifiedDate: Date?    // When last edited
    public let state: ReviewResponseState // Published or pending
}
```

**Custom Codable:** Uses `encodeIfPresent` to omit nil `lastModifiedDate` from JSON output.

**Affordances:**

| Key | Command | Description |
|-----|---------|-------------|
| `delete` | `asc review-responses delete --response-id <id>` | Delete this response |
| `getReview` | `asc reviews get --review-id <reviewId>` | Get the parent review |

### `ReviewResponseState`

State enum for developer responses.

```swift
public enum ReviewResponseState: String, Sendable, Equatable, Codable {
    case published = "PUBLISHED"
    case pendingPublish = "PENDING_PUBLISH"
}
```

**Semantic booleans:**

| Property | True when |
|----------|-----------|
| `isPublished` | `== .published` |
| `isPending` | `== .pendingPublish` |

### `CustomerReviewRepository`

The DI boundary between the command layer and the API. Annotated with `@Mockable` for testing.

```swift
@Mockable
public protocol CustomerReviewRepository: Sendable {
    func listReviews(appId: String) async throws -> [CustomerReview]
    func getReview(reviewId: String) async throws -> CustomerReview
    func getResponse(reviewId: String) async throws -> CustomerReviewResponse
    func createResponse(reviewId: String, responseBody: String) async throws -> CustomerReviewResponse
    func deleteResponse(responseId: String) async throws
}
```

---

## File Map

```
Sources/
├── Domain/Apps/Reviews/
│   ├── CustomerReview.swift              # Value type: review with rating, text, affordances
│   ├── CustomerReviewResponse.swift      # Value type: developer response + ReviewResponseState
│   └── CustomerReviewRepository.swift    # @Mockable protocol
│
├── Infrastructure/Apps/Reviews/
│   └── SDKCustomerReviewRepository.swift # Maps SDK → domain, injects parent IDs
│
└── ASCCommand/Commands/Reviews/
    ├── ReviewsCommand.swift              # Parent command: asc reviews (list, get)
    ├── ReviewsList.swift                 # asc reviews list --app-id <id>
    ├── ReviewsGet.swift                  # asc reviews get --review-id <id>
    ├── ReviewResponsesCommand.swift      # Parent command: asc review-responses (get, create, delete)
    ├── ReviewResponsesGet.swift          # asc review-responses get --review-id <id>
    ├── ReviewResponsesCreate.swift       # asc review-responses create --review-id <id> --response-body <text>
    └── ReviewResponsesDelete.swift       # asc review-responses delete --response-id <id>

Tests/
├── DomainTests/Apps/Reviews/
│   ├── CustomerReviewTests.swift         # Parent ID, fields, affordances, nil-omission Codable
│   └── CustomerReviewResponseTests.swift # Parent ID, state booleans, affordances, nil-omission Codable
├── InfrastructureTests/Apps/Reviews/
│   └── SDKCustomerReviewRepositoryTests.swift  # SDK mapping + parent ID injection
├── ASCCommandTests/Commands/Reviews/
│   ├── ReviewsListTests.swift            # JSON output and argument passing
│   ├── ReviewsGetTests.swift             # JSON output and argument passing
│   ├── ReviewResponsesGetTests.swift     # JSON output and argument passing
│   ├── ReviewResponsesCreateTests.swift  # JSON output and argument passing
│   └── ReviewResponsesDeleteTests.swift  # Delete behavior
└── DomainTests/TestHelpers/
    └── MockRepositoryFactory.swift       # makeCustomerReview(), makeCustomerReviewResponse()
```

**Wiring files modified:**

| File | Change |
|------|--------|
| `Sources/Infrastructure/Client/ClientFactory.swift` | Added `makeCustomerReviewRepository(authProvider:)` |
| `Sources/ASCCommand/ClientProvider.swift` | Added `makeCustomerReviewRepository()` |
| `Sources/ASCCommand/ASC.swift` | Added `ReviewsCommand.self` + `ReviewResponsesCommand.self` |

---

## API Reference

| Endpoint | SDK call | Repository method |
|----------|----------|-------------------|
| `GET /v1/apps/{id}/customerReviews` | `.v1.apps.id(appId).customerReviews.get(parameters:)` | `listReviews(appId:)` |
| `GET /v1/customerReviews/{id}` | `.v1.customerReviews.id(reviewId).get()` | `getReview(reviewId:)` |
| `GET /v1/customerReviews/{id}/response` | `.v1.customerReviews.id(reviewId).response.get()` | `getResponse(reviewId:)` |
| `POST /v1/customerReviewResponses` | `.v1.customerReviewResponses.post(body)` | `createResponse(reviewId:responseBody:)` |
| `DELETE /v1/customerReviewResponses/{id}` | `.v1.customerReviewResponses.id(responseId).delete` | `deleteResponse(responseId:)` |

**Notes:**
- `listReviews` sorts by `-createdDate` (most recent first) via `sort: [.minuscreatedDate]`
- `getReview` injects `appId: ""` because the single-GET endpoint does not return the parent app ID
- `mapResponse` always injects `reviewId` from the request parameter into the mapped domain object
- The SDK is from [appstoreconnect-swift-sdk](https://github.com/AvdLee/appstoreconnect-swift-sdk). `SDKCustomerReviewRepository` is marked `@unchecked Sendable` because `APIProvider` predates Swift 6 concurrency.

---

## Testing

Tests follow the **Chicago school TDD** pattern: assert on state and return values, not on interactions.

### Domain model tests

```swift
@Test func `review carries appId`() {
    let review = MockRepositoryFactory.makeCustomerReview(id: "rev-1", appId: "app-42")
    #expect(review.appId == "app-42")
}

@Test func `review affordances include getResponse`() {
    let review = MockRepositoryFactory.makeCustomerReview(id: "rev-1")
    #expect(review.affordances["getResponse"] == "asc review-responses get --review-id rev-1")
}

@Test func `review omits nil fields from JSON`() throws {
    let review = MockRepositoryFactory.makeCustomerReview(
        id: "rev-1", appId: "app-1", rating: 5,
        title: nil, body: nil, reviewerNickname: nil,
        createdDate: nil, territory: nil
    )
    let data = try JSONEncoder().encode(review)
    let json = String(data: data, encoding: .utf8)!
    #expect(!json.contains("title"))
    #expect(!json.contains("body"))
}

@Test func `published state isPublished`() {
    let response = MockRepositoryFactory.makeCustomerReviewResponse(state: .published)
    #expect(response.state.isPublished)
    #expect(!response.state.isPending)
}
```

Run the tests:

```bash
swift test --filter 'CustomerReview'
# or run the full suite
swift test
```

---

## Extending

The natural next steps follow the same layer-by-layer pattern:

### Adding Update Response

```swift
// 1. Domain protocol (CustomerReviewRepository.swift)
func updateResponse(responseId: String, responseBody: String) async throws -> CustomerReviewResponse

// 2. Infrastructure SDK call
let body = CustomerReviewResponseV1UpdateRequest(...)
APIEndpoint.v1.customerReviewResponses.id(responseId).patch(body)

// 3. New subcommand in ReviewResponsesCommand
struct ReviewResponsesUpdate: AsyncParsableCommand { ... }
```

### Adding Filtering / Sorting

```swift
// Add parameters to listReviews for filtering by rating or territory
func listReviews(appId: String, rating: Int?, territory: String?, sort: ReviewSort?) async throws -> [CustomerReview]

// Pass to SDK via parameters
.get(parameters: .init(
    filterRating: rating.map { [String($0)] },
    filterTerritory: territory.map { [$0] },
    sort: [sortParam]
))
```

### Adding Pagination

```swift
// Return PaginatedResponse instead of array
func listReviews(appId: String, cursor: String?) async throws -> PaginatedResponse<CustomerReview>
```

### Pattern to Follow

1. Add method to `CustomerReviewRepository` protocol in `Sources/Domain/Apps/Reviews/`
2. Implement in `SDKCustomerReviewRepository` in `Sources/Infrastructure/Apps/Reviews/`
3. Add subcommand in `Sources/ASCCommand/Commands/Reviews/`
4. Write domain tests first (Red -> Green -> Refactor)

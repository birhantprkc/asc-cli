---
description: List and read App Store customer reviews, and create or delete developer responses. Use when triaging ratings or replying to reviewers.
---

# Customer Reviews

List and inspect reviews users leave on your app, then create or delete developer responses. Every flag: [reviews](../../commands.md#asc-reviews) · [review-responses](../../commands.md#asc-review-responses).

## Quick start
```bash
asc reviews list --app-id 123456789 --output table
asc review-responses create --review-id rev-001 --response-body "Thanks! We fixed the crash in v2.1."
```

## Workflows

### Triage and respond
```bash
# 1. List reviews (most recent first)
asc reviews list --app-id 123456789 --output table

# 2. Read one review
asc reviews get --review-id rev-001 --pretty

# 3. Check whether it already has a response
asc review-responses get --review-id rev-001

# 4. Respond
asc review-responses create --review-id rev-001 \
  --response-body "Thank you! We appreciate your feedback."
```

A review in JSON:
```json
{
  "id": "rev-001", "appId": "123456789", "rating": 5,
  "title": "Great app!", "body": "Love using this app every day.",
  "reviewerNickname": "user123", "territory": "USA",
  "affordances": {
    "getResponse": "asc review-responses get --review-id rev-001",
    "respond": "asc review-responses create --review-id rev-001 --response-body \"\"",
    "listReviews": "asc reviews list --app-id 123456789"
  }
}
```

A response in JSON:
```json
{
  "id": "resp-001", "reviewId": "rev-001",
  "responseBody": "Thank you for your feedback!", "state": "PUBLISHED",
  "affordances": {
    "delete": "asc review-responses delete --response-id resp-001",
    "getReview": "asc reviews get --review-id rev-001"
  }
}
```

### Revise a response
There is no update command; delete and recreate.
```bash
asc review-responses delete --response-id resp-001
asc review-responses create --review-id rev-001 --response-body "Updated response with more detail."
```

### Extract ratings
```bash
asc reviews list --app-id 123456789 | jq '.[].rating'
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/reviews` | `asc reviews list --app-id` |

Responses (get/create/delete) are CLI-only.

## Gotchas
- `asc review-responses get` takes the parent `--review-id`, not a response ID; `delete` takes `--response-id`.
- Response `state` is `PUBLISHED` or `PENDING_PUBLISH` (`isPublished` / `isPending`); a new response may sit in pending before Apple publishes it.
- `asc reviews get` returns an empty `appId`, because Apple's single-review endpoint doesn't return the parent app.
- Nil fields (`title`, `body`, `reviewerNickname`, `createdDate`, `territory`) are omitted from JSON rather than sent as null.
- `list` returns all reviews sorted newest first; there is no rating/territory filter or pagination yet.

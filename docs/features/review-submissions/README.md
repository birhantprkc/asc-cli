---
description: Inspect App Store review submissions, their state and which attached item Apple rejected. Use when checking review status or finding what was rejected.
---

# Review Submissions

Inspect App Store review submissions: state, rejected items, and per-item drill-in affordances. Every flag: [command reference](../../commands.md#asc-review-submissions).

A review submission is the record Apple's review queue works on. It packages one or more items, each pointing at a reviewable resource: an app version, or a version of an in-app purchase, subscription or subscription group. Building and sending a submission (`create`, `items add`, `items remove`, `submit`) is covered in [submit-with-products](../submit-with-products/README.md).

## Quick start

```bash
asc review-submissions list --app-id 1234567890 --state UNRESOLVED_ISSUES --pretty
asc review-submissions get --submission-id sub-1
asc review-submissions items list --submission-id sub-1 --state REJECTED --pretty
```

## Workflows

### Find out what Apple rejected, fix it, resubmit

```bash
APP_ID=1234567890

# 1. Did anything get rejected?
asc review-submissions list --app-id "$APP_ID" --state UNRESOLVED_ISSUES

# 2. Which item failed?
SUB_ID=$(asc review-submissions list --app-id "$APP_ID" --state UNRESOLVED_ISSUES | jq -r '.data[0].id')
asc review-submissions items list --submission-id "$SUB_ID" --state REJECTED

# 3. Fix the rejected version (read Apple's notes in Resolution Center)
VERSION_ID=$(asc review-submissions items list --submission-id "$SUB_ID" --state REJECTED \
             | jq -r '.data[0].linkedResourceId')
asc versions check-readiness --version-id "$VERSION_ID"

# 4. After fixing, resubmit
asc versions submit --version-id "$VERSION_ID"
```

A submission with issues carries `listRejectedItems`:

```json
{
  "affordances" : {
    "addItem" : "asc review-submissions items add --submission-id sub-1 --version-id <version-id>",
    "getResolutionDetails" : "asc iris resolution-center get --submission-id sub-1",
    "getSubmission" : "asc review-submissions get --submission-id sub-1",
    "listItems" : "asc review-submissions items list --submission-id sub-1",
    "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id sub-1",
    "listVersions" : "asc versions list --app-id 1234567890",
    "submit" : "asc review-submissions submit --submission-id sub-1"
  },
  "appId" : "1234567890",
  "id" : "sub-1",
  "platform" : "IOS",
  "state" : "UNRESOLVED_ISSUES"
}
```

A rejected item links straight to the version:

```json
{
  "affordances" : {
    "getResolutionDetails" : "asc iris resolution-center get --submission-id sub-1",
    "getSubmission" : "asc review-submissions get --submission-id sub-1",
    "getVersion" : "asc versions get --version-id v-9",
    "listSiblings" : "asc review-submissions items list --submission-id sub-1"
  },
  "id" : "item-1",
  "linkedResourceId" : "v-9",
  "linkedResourceType" : "APP_STORE_VERSION",
  "state" : "REJECTED",
  "submissionId" : "sub-1"
}
```

## REST

| Method | Path | CLI equivalent |
|--------|------|----------------|
| `GET` | `/api/v1/apps/{appId}/review-submissions` | `review-submissions list` (`--state` → `?state=`, `--limit` → `?limit=`) |
| `GET` | `/api/v1/review-submissions/{id}` | `review-submissions get` |
| `GET` | `/api/v1/review-submissions/{id}/items` | `review-submissions items list` (`--state` → `?state=`) |
| `POST` | `/api/v1/apps/{appId}/review-submissions` | `review-submissions create` (body `platform`) |
| `POST` | `/api/v1/review-submissions/{id}/items` | `review-submissions items add` (version flag → body key) |
| `DELETE` | `/api/v1/review-submissions/items/{itemId}` | `review-submissions items remove` |
| `POST` | `/api/v1/review-submissions/{id}/submit` | `review-submissions submit` |

```bash
curl http://localhost:8420/api/v1/review-submissions/sub-1
curl 'http://localhost:8420/api/v1/review-submissions/sub-1/items?state=REJECTED'
```

## Gotchas

- The reviewer's free-text reasoning is not in the public API; it lives only in the Resolution Center. This feature surfaces the state machine, not the narrative. See [resolution-center](../resolution-center/README.md).
- `--app-id` is required on `list` because Apple's API requires the app filter.
- Submission states: `READY_FOR_REVIEW`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `UNRESOLVED_ISSUES`, `CANCELING`, `COMPLETING`, `COMPLETE`. Omitting `--state` returns all.
- Item states: `READY_FOR_REVIEW`, `ACCEPTED`, `APPROVED`, `REJECTED`, `REMOVED`.
- `listRejectedItems` appears only when the submission is `UNRESOLVED_ISSUES`, so an agent can branch on its presence.
- `getVersion` appears on an item only when it links an `APP_STORE_VERSION`. Items can also link IAP, subscription, subscription group, custom product page, experiment, app event, background asset and Game Center versions.

## See also

[submit-with-products](../submit-with-products/README.md) · [resolution-center](../resolution-center/README.md) · [version-check-readiness](../version-check-readiness/README.md)

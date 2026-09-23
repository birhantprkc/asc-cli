---
description: Read App Review's rejection messages, guideline citations and attachments from the Resolution Center via the iris web session. Use when a review submission is UNRESOLVED_ISSUES and you need to know why.
---

# Resolution Center

Read App Review's rejection messages and structured rejection reasons from the Resolution Center, the one piece of review data the official App Store Connect API doesn't expose. Every flag: [command reference](../../commands.md#asc-iris).

## Quick start

```bash
asc review-submissions list --app-id 6787646042 --state UNRESOLVED_ISSUES
asc iris resolution-center get --submission-id <id> --plain-text --pretty
```

## Workflows

### Find out why a submission was rejected, fix it, resubmit

```bash
# 1. Which submission has issues? (official API, key auth, CI-safe)
asc review-submissions list --app-id 6787646042 --state UNRESOLVED_ISSUES

# 2. Which item did Apple reject?
asc review-submissions items list --submission-id <id> --state REJECTED

# 3. Why? (iris, browser cookies)
asc iris resolution-center get --submission-id <id> --plain-text

# 4. Fix the flagged resource (metadata, build, screenshots …), then resubmit
asc versions submit --version-id <versionId>
```

A submission with issues, and each rejected item, carries a `getResolutionDetails` affordance pointing at step 3, so an agent discovers it when it becomes useful. Output (`--plain-text --pretty`, abridged):

```json
{
  "data" : [
    {
      "affordances" : {
        "getSubmission" : "asc review-submissions get --submission-id 4d2a8cbf-…",
        "listRejectedItems" : "asc review-submissions items list --state REJECTED --submission-id 4d2a8cbf-…"
      },
      "id" : "925db205-9466-36fe-9e28-118db7ea1e4d",
      "messages" : [
        {
          "body" : "Hello, \n\nThank you for submitting the new app… Guideline 5.2.5 - Legal - Intellectual Property…",
          "createdDate" : 805814892.99,
          "fromActor" : "APPLE",
          "id" : "b813b928-…",
          "threadId" : "925db205-…"
        }
      ],
      "rejectionReasons" : [
        {
          "code" : "5.2.5",
          "descriptionText" : "Legal: Intellectual Property - Apple Products (macOS)",
          "id" : "2a68bda3-…-0",
          "section" : "5.2.5"
        }
      ],
      "submissionId" : "4d2a8cbf-875e-4d75-b086-9fa47eb67796"
    }
  ]
}
```

### Download attachments

```bash
asc iris resolution-center get --submission-id <id> --out ./rejection
```

`--out` downloads every downloadable attachment into the directory (created if missing), named by `fileName`. When a thread has attachments, the output gains an `attachments` field and a `downloadAttachments` affordance.

## REST

| Method | Path | CLI equivalent |
|--------|------|----------------|
| GET | `/api/v1/iris/review-submissions/:id/resolution-center` | `asc iris resolution-center get --submission-id <id>` |

Query-param mapping: `--plain-text` → `?plain-text=true`.

```bash
curl "http://127.0.0.1:8080/api/v1/iris/review-submissions/<id>/resolution-center?plain-text=true"
```

Discovery: `GET /api/v1/review-submissions/:id` includes `_links.getResolutionDetails` when the submission is `UNRESOLVED_ISSUES`.

## Gotchas

- Needs iris (cookie web-session) auth, not your API key: the reviewer's text and guideline citations live only behind the web UI; Apple's public API has no resolution-center paths.
- Cookies come from `asc iris auth login`, a logged-in browser (Chrome/Safari/Firefox), or `ASC_IRIS_COOKIES`. With none, the command fails fast and says so.
- `asc review-submissions *` stays on official key auth with no iris dependency; the only link is the `getResolutionDetails` affordance string.
- `No Resolution Center thread found for submission <id>` means App Review hasn't sent any messages for it yet.
- Message bodies are raw HTML unless you pass `--plain-text`.
- Over REST, attachments aren't proxied: fetch each Apple-signed `downloadUrl` directly. `--out` is CLI-only. `downloadUrl` is absent while Apple is still processing the file.
- Downloads are only allowed from https hosts on `.apple.com`, `.mzstatic.com`, `.amazonaws.com` or `.cloudfront.net`.
- The iris endpoints are undocumented; if Apple changes a field, output may break until the mapper is updated.
- Replying to App Review isn't supported.

## See also

[review-submissions](../review-submissions/README.md) · [iris](../iris/README.md)

---
description: Manage the TestFlight Beta App Description and per-locale beta metadata (feedback email, marketing and privacy URLs). Use when preparing a build for external TestFlight testers.
---

# Beta App Localizations

Manage the TestFlight **Beta App Description** and per-locale beta metadata: feedback email, marketing URL, privacy policy URL and tvOS privacy policy text. Every flag: [command reference](../../commands.md#asc-beta-app-localizations).

Apple reads this resource when deciding whether a build can open to external TestFlight testers. A missing or empty Beta App Description is the most common reason an external-testing submission fails review.

## Quick start

```bash
asc beta-app-localizations list --app-id 1234567890 --pretty
asc beta-app-localizations update --localization-id bal-1 --description "Updated beta description"
```

## Workflows

### Set the beta description for each locale

```bash
# 1. Find the app
APP_ID=$(asc apps list --output json | jq -r '.data[0].id')

# 2. List existing beta localizations (Apple auto-creates one for the primary locale)
asc beta-app-localizations list --app-id "$APP_ID" --pretty

# 3. Create or update the English beta description
EXISTING=$(asc beta-app-localizations list --app-id "$APP_ID" --output json \
  | jq -r '.data[] | select(.locale == "en-US") | .id')

if [ -z "$EXISTING" ]; then
  asc beta-app-localizations create \
    --app-id "$APP_ID" \
    --locale en-US \
    --description "Welcome to the beta — please test the new dashboard." \
    --feedback-email beta@example.com
else
  asc beta-app-localizations update \
    --localization-id "$EXISTING" \
    --description "Welcome to the beta — please test the new dashboard." \
    --feedback-email beta@example.com
fi

# 4. Add a second locale
asc beta-app-localizations create \
    --app-id "$APP_ID" \
    --locale zh-Hans \
    --description "欢迎参与测试 — 请试用新版仪表盘。" \
    --feedback-email beta@example.com
```

Each localization carries its own next steps:

```json
{
  "affordances" : {
    "delete" : "asc beta-app-localizations delete --localization-id bal-1",
    "get" : "asc beta-app-localizations get --localization-id bal-1",
    "listSiblings" : "asc beta-app-localizations list --app-id 1234567890",
    "update" : "asc beta-app-localizations update --localization-id bal-1"
  },
  "appId" : "1234567890",
  "description" : "Welcome to the beta — please test the new dashboard.",
  "feedbackEmail" : "beta@example.com",
  "id" : "bal-1",
  "locale" : "en-US"
}
```

## REST

| Method | Path | CLI equivalent |
|--------|------|----------------|
| `GET` | `/api/v1/apps/:appId/beta-app-localizations` | `asc beta-app-localizations list --app-id <id>` |
| `GET` | `/api/v1/beta-app-localizations/:localizationId` | `asc beta-app-localizations get --localization-id <id>` |

```bash
curl http://localhost:8420/api/v1/apps/1234567890/beta-app-localizations
```

## Gotchas

- Three resources are easy to confuse. `asc beta-app-localizations`: per-locale beta app description, feedback email and URLs (this doc). `asc builds update-beta-notes`: per-build "What to Test" notes. `asc beta-review detail`: app-level beta review contact info and demo account.
- `update` sends only the fields you pass; omitted fields stay unchanged on App Store Connect.
- Unset optional fields are left out of the JSON output.
- Only `list` and `get` are exposed over REST; create, update and delete are CLI-only.

## See also

[testflight](../testflight/README.md) · [beta-review](../beta-review/README.md)

---
description: Save the current project's app ID, name, bundle ID and review contact to .asc/project.json. Use when setting up a repo so agents and scripts know which app to work on without listing apps every session.
---

# asc init — Project Context

Saves the app ID, name and bundle ID (plus optional App Review contact) to `.asc/project.json` in the working directory, so agents and scripts can find the app without calling `asc apps list` every session. Every flag: [command reference](../../commands.md#asc-init).

## Quick start

```bash
cd /path/to/MyApp
asc init --pretty                          # auto-detect from *.xcodeproj
asc init --name "My App" --pretty          # or search by name
asc init --app-id 1234567890 --pretty      # or give the ID directly
```

## Workflows

### Set up once, reuse every session

```bash
# First-time setup (run once per project)
asc init --pretty
# → saves .asc/project.json

# Later sessions — read context without listing all apps
APP_ID=$(jq -r '.appId' .asc/project.json)
asc versions list  --app-id "$APP_ID"
asc builds list    --app-id "$APP_ID"
asc app-infos list --app-id "$APP_ID"
```

An agent can read `.asc/project.json` at the start of every session and skip app discovery entirely.

### Save the App Review contact

```bash
asc init --app-id 1234567890 \
  --contact-first-name Jane \
  --contact-last-name Smith \
  --contact-email jane@example.com \
  --contact-phone "+1-555-0100" \
  --pretty
```

The saved file (contact fields are omitted when not set):

```json
{
  "appId":    "1234567890",
  "appName":  "My App",
  "bundleId": "com.example.myapp",
  "contactEmail": "jane@example.com",
  "contactFirstName": "Jane",
  "contactLastName": "Smith",
  "contactPhone": "+1-555-0100"
}
```

### Output and affordances

```json
{
  "affordances": {
    "checkReadiness": "asc versions check-readiness --version-id <id>",
    "listAppInfos":   "asc app-infos list --app-id 1234567890",
    "listBuilds":     "asc builds list --app-id 1234567890",
    "listVersions":   "asc versions list --app-id 1234567890",
    "setReviewContact": "asc init --app-id 1234567890 --contact-email ... --contact-phone ..."
  },
  "appId":    "1234567890",
  "appName":  "My App",
  "bundleId": "com.example.myapp"
}
```

`setReviewContact` appears until both contact email and phone are saved; after that it becomes `updateReviewContact`.

## Gotchas

- Lookup priority: `--app-id` > `--name` > auto-detect.
- `--name` matches case-insensitively; it and auto-detect both list all your apps first. `--app-id` fetches just that app.
- Auto-detect reads literal `PRODUCT_BUNDLE_IDENTIFIER` values from `*.xcodeproj/project.pbxproj` in the current directory; values that are `$`-variable references are ignored, so use `--name` or `--app-id` in that case.
- `.asc/project.json` is written relative to the current directory. Nothing is written to App Store Connect.
- Older `project.json` files without contact fields still load.
- CLI-only; there is no REST endpoint.

## See also

- [Version review detail](../version-review-detail/README.md)
- [Check readiness](../version-check-readiness/README.md)

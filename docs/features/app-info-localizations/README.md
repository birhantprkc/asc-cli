---
description: Manage per-locale app metadata (name, subtitle, privacy policy URL and text) on the App Store listing. Use when renaming the app, setting a subtitle, or adding a new listing locale.
---

# App Info Localizations

Per-locale app metadata that applies across versions: name, subtitle, privacy policy URL, privacy choices URL and privacy policy text. Every flag: [command reference](../../commands.md#asc-app-info-localizations).

## Quick start
```bash
asc app-infos list --app-id <APP_ID> --output table
asc app-info-localizations list --app-info-id <APP_INFO_ID> --output table
asc app-info-localizations update --localization-id <LOC_ID> --name "My App" --subtitle "Do things faster"
```

## Workflows

### Update or add a locale
```bash
# 1. Get the AppInfo ID (each app typically has one)
asc app-infos list --app-id <APP_ID> --output table

# 2. See which locales exist
asc app-info-localizations list --app-info-id <APP_INFO_ID> --output table
# ID          Locale    Name            Subtitle
# loc-001     en-US     My App          Do things faster
# loc-002     zh-Hans   我的应用          更快地完成任务

# 3a. Update an existing locale (only the flags you pass change)
asc app-info-localizations update --localization-id <LOC_ID> \
  --name "New Name" \
  --subtitle "New Subtitle"

# 3b. Add a new locale (name is required on create)
asc app-info-localizations create --app-info-id <APP_INFO_ID> \
  --locale zh-Hans \
  --name "应用名称"
```

### Set the privacy policy URL
```bash
asc app-info-localizations update --localization-id loc-001 \
  --privacy-policy-url "https://example.com/privacy"
```

The `app-infos list` response links onward to localizations and age rating:

```json
{
  "data": [
    {
      "id": "info-abc123",
      "appId": "1234567890",
      "affordances": {
        "createLocalization": "asc app-info-localizations create --app-info-id info-abc123",
        "getAgeRating": "asc age-rating get --app-info-id info-abc123",
        "listAppInfos": "asc app-infos list --app-id 1234567890",
        "listLocalizations": "asc app-info-localizations list --app-info-id info-abc123",
        "updateCategories": "asc app-infos update --app-info-id info-abc123"
      }
    }
  ]
}
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/app-infos` | `asc app-infos list --app-id` |
| GET | `/api/v1/app-infos/:appInfoId/localizations` | `asc app-info-localizations list --app-info-id` |
| POST | `/api/v1/app-infos/:appInfoId/localizations` | `asc app-info-localizations create` (body `{"locale", "name"}`) |
| PATCH | `/api/v1/app-info-localizations/:localizationId` | `asc app-info-localizations update` (body uses `name`, `subtitle`, `privacyPolicyUrl`, `privacyChoicesUrl`, `privacyPolicyText`) |
| DELETE | `/api/v1/app-info-localizations/:localizationId` | `asc app-info-localizations delete --localization-id` |

## Gotchas
- These fields are app-level. Release notes, description and keywords are per version and live in [version-localizations](../version-localizations/README.md).
- Name and subtitle are limited to 30 characters each.

## See also
[app-infos](../app-infos/README.md) · [age-rating](../age-rating/README.md)

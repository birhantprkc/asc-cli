---
description: Manage app-level metadata (name, subtitle, privacy policy, categories) that persists across versions. Use when renaming an app, adding a locale's name/subtitle, or setting App Store categories.
---

# App Infos

App-level metadata (name, subtitle, privacy policy, categories) shown on the App Store listing. It persists across versions, unlike the per-version release notes in [version-localizations](../version-localizations/README.md). Every flag: [command reference](../../commands.md#asc-app-infos), [app-info-localizations](../../commands.md#asc-app-info-localizations), [app-categories](../../commands.md#asc-app-categories).

Hierarchy: `App → AppInfo → AppInfoLocalization`. Each app typically has one AppInfo.

## Quick start
```bash
APP_INFO_ID=$(asc app-infos list --app-id 1234567890 | jq -r '.data[0].id')
asc app-info-localizations list --app-info-id "$APP_INFO_ID" --output table
asc app-infos update --app-info-id "$APP_INFO_ID" --primary-category GAMES --primary-subcategory-one GAMES_ACTION
```

## Workflows

### Update names and subtitles per locale
```bash
# 1. Get the AppInfo ID (each app has one)
APP_INFO_ID=$(asc app-infos list --app-id <APP_ID> | jq -r '.data[0].id')

# 2. See what localizations already exist
asc app-info-localizations list --app-info-id "$APP_INFO_ID" --output table

# 3a. Update an existing locale
LOC_ID=$(asc app-info-localizations list --app-info-id "$APP_INFO_ID" \
  | jq -r '.data[] | select(.locale == "en-US") | .id')
asc app-info-localizations update \
  --localization-id "$LOC_ID" \
  --name "My App" \
  --subtitle "Do things faster"

# 3b. Add a new locale
asc app-info-localizations create \
  --app-info-id "$APP_INFO_ID" \
  --locale zh-Hans \
  --name "我的应用"

# 3c. Remove an unwanted locale
asc app-info-localizations delete --localization-id <LOCALIZATION_ID>
```

`update` also takes `--privacy-policy-url`, `--privacy-choices-url` and `--privacy-policy-text`.

```
ID          Locale    Name            Subtitle
----------  --------  --------------  --------------------
loc-001     en-US     My App          Do things faster
loc-002     zh-Hans   我的应用          更快地完成任务
loc-003     ja        マイアプリ         -
```

### Set categories
```bash
# Look up IDs first
asc app-categories list --platform IOS --output table

asc app-infos update \
  --app-info-id "$APP_INFO_ID" \
  --primary-category GAMES \
  --primary-subcategory-one GAMES_ACTION \
  --secondary-category UTILITIES
```

```
ID                   Platforms                  Parent ID
-------------------  -------------------------  --------
GAMES                IOS,MAC_OS,TV_OS           -
GAMES_ACTION         IOS,MAC_OS,TV_OS           -
UTILITIES            IOS,MAC_OS,TV_OS           -
```

### Navigate from AppInfo
The AppInfo JSON carries affordances to its localizations, categories and age rating:

```json
{
  "id": "info-abc123",
  "appId": "1234567890",
  "affordances": {
    "createLocalization": "asc app-info-localizations create --app-info-id info-abc123",
    "getAgeRating":      "asc age-rating get --app-info-id info-abc123",
    "listAppInfos":      "asc app-infos list --app-id 1234567890",
    "listLocalizations": "asc app-info-localizations list --app-info-id info-abc123",
    "updateCategories":  "asc app-infos update --app-info-id info-abc123"
  }
}
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/app-infos` | `asc app-infos list --app-id` |
| PATCH | `/api/v1/app-infos/:appInfoId` | `asc app-infos update --app-info-id` |
| GET | `/api/v1/app-infos/:appInfoId/localizations` | `asc app-info-localizations list` |
| POST | `/api/v1/app-infos/:appInfoId/localizations` | `asc app-info-localizations create` |
| PATCH | `/api/v1/app-info-localizations/:localizationId` | `asc app-info-localizations update` |
| DELETE | `/api/v1/app-info-localizations/:localizationId` | `asc app-info-localizations delete` |
| GET | `/api/v1/app-categories?platform=` | `asc app-categories list --platform` |
| GET | `/api/v1/app-categories/:categoryId` | `asc app-categories get --category-id` |

JSON bodies use the model field names: `primaryCategoryId`, `primarySubcategoryOneId`, … for categories; `locale`, `name` for create; `name`, `subtitle`, `privacyPolicyUrl`, `privacyChoicesUrl`, `privacyPolicyText` for update.

## Gotchas
- `update` commands only send the flags you pass (PATCH semantics); omitted fields stay unchanged.
- `name` and `subtitle` are limited to 30 characters.
- `create` is only for a locale that doesn't exist yet; use `update` for an existing one.
- The API does not return `parentId` for subcategories. Recognise them by name: `GAMES_ACTION`, `GAMES_PUZZLE` are subcategories of `GAMES`.

## See also
[age-rating](../age-rating/README.md) · [app-info-localizations](../app-info-localizations/README.md) · [version-localizations](../version-localizations/README.md)

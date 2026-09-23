---
description: Manage per-locale App Store version text such as What's New, description, keywords, promotional text and URLs. Use when writing release notes or localizing a version's store listing.
---

# Version Localizations

Per-locale content for one App Store version: What's New, description, keywords, promotional text, marketing and support URLs. Every flag: [command reference](../../commands.md#asc-version-localizations).

## Quick start
```bash
asc versions list --app-id <APP_ID> --output table
asc version-localizations list --version-id <VERSION_ID> --output table
asc version-localizations update --localization-id <LOC_ID> --whats-new "Bug fixes and performance improvements"
```

## Workflows

### Write release notes for every locale, then submit
```bash
# 1. Find the version and its localizations
asc versions list --app-id <APP_ID> --output table
asc version-localizations list --version-id <VERSION_ID> --output table

# 2. Update What's New per locale
asc version-localizations update --localization-id <EN_LOC_ID> \
  --whats-new "Bug fixes and performance improvements"
asc version-localizations update --localization-id <ZH_LOC_ID> \
  --whats-new "修复了已知问题，提升了性能"

# 3. Add a locale that doesn't exist yet
asc version-localizations create --version-id <VERSION_ID> --locale fr-FR

# 4. Screenshots hang off each localization
asc screenshot-sets list --localization-id <LOC_ID>
asc screenshots upload --set-id <SET_ID> --file ./screenshots/en-US/hero.png

# 5. Submit
asc versions submit --version-id <VERSION_ID>
```

Update several fields at once; only the ones you pass are sent:

```bash
asc version-localizations update --localization-id 9584409e-... \
  --whats-new "Bug fixes" \
  --keywords "productivity,tasks,calendar"
```

```json
{
  "data": [
    {
      "id": "9584409e-a626-46d4-9b65-4cac006f4197",
      "versionId": "74ed4466-8dc4-4ec7-b2ce-3c1bbe620964",
      "locale": "en-US",
      "whatsNew": "Bug fixes and performance improvements",
      "affordances": {
        "listLocalizations": "asc version-localizations list --version-id 74ed4466-...",
        "listScreenshotSets": "asc screenshot-sets list --localization-id 9584409e-...",
        "updateLocalization": "asc version-localizations update --localization-id 9584409e-..."
      }
    }
  ]
}
```

### Same text for all locales
```bash
for LOC_ID in $(asc version-localizations list --version-id $VERSION_ID | jq -r '.data[].id'); do
  asc version-localizations update --localization-id $LOC_ID --whats-new "Bug fixes"
done
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/versions/:versionId/localizations` | `asc version-localizations list --version-id` |

Create and update are CLI-only.

## Gotchas
- These are version-level fields. App-level name, subtitle and privacy URLs live in [app-info-localizations](../app-info-localizations/README.md).
- Empty fields are omitted from the JSON, so a missing `whatsNew` means it has not been set.
- `--keywords` is a single comma-separated string.
- There is no delete command.

## See also
[screenshots](../screenshots/README.md) · [app-previews](../app-previews/README.md) · [version-check-readiness](../version-check-readiness/README.md)

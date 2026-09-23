---
description: Manage App Clips, their default experiences, and the localized subtitles shown on App Clip cards. Use when setting up or editing an App Clip card.
---

# App Clips

List an app's App Clips, create default experiences, and add locale-specific card content. Every flag: [app-clips](../../commands.md#asc-app-clips), [app-clip-experiences](../../commands.md#asc-app-clip-experiences), [app-clip-experience-localizations](../../commands.md#asc-app-clip-experience-localizations).

## Quick start

```bash
asc app-clips list --app-id 1234567890 --pretty
asc app-clip-experiences create --app-clip-id clip-abc --action OPEN --pretty
asc app-clip-experience-localizations create --experience-id exp-xyz --locale en-US --subtitle "Order faster with your loyalty card"
```

## Workflows

### Set up a default experience with localized cards

```bash
# 1. Find the App Clip
asc app-clips list --app-id 1234567890 --pretty

# 2. Create a default experience
asc app-clip-experiences create --app-clip-id clip-abc --action OPEN --pretty

# 3. Add one localization per locale
asc app-clip-experience-localizations create \
  --experience-id exp-xyz --locale en-US --subtitle "Order faster with your loyalty card"
asc app-clip-experience-localizations create \
  --experience-id exp-xyz --locale fr-FR --subtitle "Commandez plus vite avec votre carte"

# 4. Check the result
asc app-clip-experience-localizations list --experience-id exp-xyz --pretty
```

An experience in JSON links to its localizations and to delete:

```json
{
  "id": "exp-xyz",
  "appClipId": "clip-abc",
  "action": "OPEN",
  "affordances": {
    "delete": "asc app-clip-experiences delete --experience-id exp-xyz",
    "listExperiences": "asc app-clip-experiences list --app-clip-id clip-abc",
    "listLocalizations": "asc app-clip-experience-localizations list --experience-id exp-xyz"
  }
}
```

### Remove content

```bash
asc app-clip-experience-localizations delete --localization-id loc-1
asc app-clip-experiences delete --experience-id exp-xyz
```

## REST

App Clips are CLI-only; `asc web-server` has no App Clip routes yet.

## Gotchas

- `--action` is optional and takes `OPEN`, `VIEW` or `PLAY`. When not set, `action` is omitted from the JSON; the same goes for an unset `bundleId` or `subtitle`.
- There is no `update` command: to change an experience's action or a subtitle, delete it and create it again.
- Only default experiences are supported, not advanced App Clip experiences.

## See also

[apps](../../commands.md#asc-apps)

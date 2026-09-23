---
description: Archive an Xcode project with xcodebuild, export an IPA or PKG, and optionally upload it to App Store Connect in one command. Use when going from an Xcode project to TestFlight without running xcodebuild by hand.
---

# Builds Archive & Export

Archive and export Xcode projects from the CLI, with optional upload to App Store Connect. Every flag: [command reference](../../commands.md#asc-builds-archive).

## Quick start

```bash
asc builds archive --scheme MyApp                    # IPA in .build/export/
asc builds archive --scheme MyApp --upload --app-id 123456 --version 1.0.0 --build-number 42
```

## Workflows

### Archive and export only

```bash
asc builds archive --scheme MyMacApp --platform macos
asc builds archive --scheme MyApp --workspace MyApp.xcworkspace
asc builds archive --scheme MyApp --export-method ad-hoc --output-dir dist/
```

The result points to the exported file and offers the upload as the next step:

```json
{
  "ipaPath": ".build/export/MyApp.ipa",
  "exportPath": ".build/export",
  "affordances": {
    "upload": "asc builds upload --file .build/export/MyApp.ipa"
  }
}
```

### Archive, upload and hand to TestFlight

```bash
# 1. Initialize project context
asc init

# 2. Archive, export, and upload in one command
asc builds archive --scheme MyApp --upload --app-id 123456 --version 1.2.0 --build-number 55

# 3. Add to a TestFlight beta group
asc builds add-beta-group --build-id <build-id> --beta-group-id <group-id>

# 4. Update TestFlight notes
asc builds update-beta-notes --build-id <build-id> --locale en-US --notes "New features and bug fixes"
```

With `--upload`, the output is the upload record instead:

```json
{
  "id": "up-1",
  "appId": "123456",
  "version": "1.0.0",
  "buildNumber": "42",
  "platform": "IOS",
  "state": "COMPLETE",
  "affordances": {
    "checkStatus": "asc builds uploads get --upload-id up-1",
    "listBuilds": "asc builds list --app-id 123456"
  }
}
```

## REST

Archiving runs `xcodebuild` locally, so it is CLI-only.

## Gotchas

- `--app-id`, `--version` and `--build-number` are required when you pass `--upload`.
- `--workspace` / `--project` are auto-detected when omitted; pass one if the directory has several.
- Defaults: `--platform ios`, `--configuration Release`, `--export-method app-store-connect`, `--output-dir .build`.
- The export options plist is generated for you from `--export-method`.
- Errors report the `xcodebuild` exit code and stderr, separately for the archive and the export step. The command also fails if export finishes but no `.ipa` or `.pkg` is found.

## See also

[builds-upload](../builds-upload/README.md) · [testflight](../testflight/README.md) · [xcode-cloud](../xcode-cloud/README.md)

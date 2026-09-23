---
description: Upload IPA/PKG builds, add them to TestFlight groups, set beta notes and export compliance, and link a build to a version. Use when shipping a new binary to TestFlight or the App Store.
---

# Builds Upload

Upload `.ipa` (iOS/tvOS/visionOS) or `.pkg` (macOS) builds, distribute them to TestFlight groups, set "What's New" notes, and link them to an App Store version. Every flag: [command reference](../../commands.md#asc-builds).

## Quick start
```bash
asc builds upload --app-id 123456789 --file ./MyApp.ipa --version 1.0.0 --build-number 42 --wait
asc builds list --app-id 123456789
asc versions set-build --version-id <VERSION_ID> --build-id <BUILD_ID>
```

## Workflows

### Upload, distribute, and link for release
```bash
# 1. Upload and wait for processing (platform auto-detected: .pkg → macOS, otherwise iOS)
asc builds upload --app-id 123456789 --file ./MyApp.ipa \
  --version 1.2.0 --build-number 55 --wait --pretty

# 2. Find the processed build ID
BUILD_ID=$(asc builds list --app-id 123456789 | jq -r '.data[0].id')

# 3. Add a beta group for TestFlight distribution
GROUP_ID=$(asc testflight groups list --app-id 123456789 | jq -r '.data[0].id')
asc builds add-beta-group --build-id "$BUILD_ID" --beta-group-id "$GROUP_ID"

# 4. Set "What's New" notes (creates the locale if it doesn't exist)
asc builds update-beta-notes --build-id "$BUILD_ID" --locale en-US \
  --notes "What's new in 1.2.0: Performance improvements, bug fixes."

# 5. Answer export compliance if Info.plist lacked ITSAppUsesNonExemptEncryption
asc builds set-encryption-compliance --build-id "$BUILD_ID" --uses-non-exempt-encryption false

# 6. Link the build to a version and submit
VERSION_ID=$(asc versions list --app-id 123456789 | jq -r '.data[0].id')
asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"
asc versions submit --version-id "$VERSION_ID"
```

Upload output:
```json
{
  "data": [{
    "id": "abc123", "appId": "123456789", "version": "1.0.0", "buildNumber": "42",
    "platform": "IOS", "state": "COMPLETE",
    "affordances": {
      "checkStatus": "asc builds uploads get --upload-id abc123",
      "listBuilds": "asc builds list --app-id 123456789"
    }
  }]
}
```

### Inspect or clean up upload records
```bash
asc builds uploads list --app-id 123456789
asc builds uploads get --upload-id abc123
asc builds uploads delete --upload-id abc123       # pending uploads
asc builds remove-beta-group --build-id <BUILD_ID> --beta-group-id <GROUP_ID>
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| PATCH | `/api/v1/builds/:buildId/encryption-compliance` | `asc builds set-encryption-compliance` |

```bash
curl -X PATCH http://localhost:8080/api/v1/builds/build-1/encryption-compliance \
  -H 'Content-Type: application/json' \
  -d '{"usesNonExemptEncryption": false}'
```

## Gotchas
- Upload `state` is `AWAITING_UPLOAD` / `PROCESSING` (pending), `FAILED`, or `COMPLETE`. The `listBuilds` affordance only appears once `COMPLETE`.
- `asc builds uploads get` returns an empty `appId` (ASC API limitation), so `listBuilds` is suppressed there.
- A build's affordances (`addToTestFlight`, `updateBetaNotes`, `setEncryptionCompliance`) only appear when it is usable: not `expired` and `processingState` is `VALID`.
- Missing `ITSAppUsesNonExemptEncryption` in the IPA marks the build "Missing Compliance" (`usesNonExemptEncryption` is null) and blocks TestFlight external testing. The `setEncryptionCompliance` affordance shows until you answer.
- Answering `true` starts Apple's full export-compliance flow; the `AppEncryptionDeclaration` resource isn't exposed by the CLI yet, so create it in the App Store Connect web UI.
- `update-beta-notes` is an upsert: it updates the locale's notes or creates the localization.

## See also
[TestFlight](../testflight/README.md)

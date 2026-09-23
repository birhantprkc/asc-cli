# Release Workflow

A full App Store release, from build upload to review submission. Each step links to the feature doc with the details.

```bash
# 1. Upload a build and wait for processing                         → features/builds-archive.md, builds-upload.md
# Option A: archive from the Xcode project and upload in one step
asc builds archive --scheme MyApp --upload --app-id APP_ID --version 1.2.0 --build-number 55
# Option B: upload a pre-built IPA/PKG
asc builds upload --app-id APP_ID --file ./MyApp.ipa --version 1.2.0 --build-number 55 --wait

# 2. Distribute to TestFlight                                        → features/testflight.md
GROUP_ID=$(asc testflight groups list --app-id APP_ID | jq -r '.data[0].id')
BUILD_ID=$(asc builds list --app-id APP_ID | jq -r '.data[0].id')
asc builds add-beta-group --build-id "$BUILD_ID" --beta-group-id "$GROUP_ID"
asc builds update-beta-notes --build-id "$BUILD_ID" --locale en-US --notes "What's new in 1.2.0"

# 3. Prepare the App Store version
VERSION_ID=$(asc versions list --app-id APP_ID | jq -r '.data[0].id')
asc versions set-build --version-id "$VERSION_ID" --build-id "$BUILD_ID"

# 4. Update What's New                                               → features/version-localizations.md
LOC_ID=$(asc version-localizations list --version-id "$VERSION_ID" | jq -r '.data[0].id')
asc version-localizations update --localization-id "$LOC_ID" --whats-new "Bug fixes and performance improvements"

# 5. Pre-flight check, then submit                                   → features/version-check-readiness.md
asc versions check-readiness --version-id "$VERSION_ID" --pretty
asc versions submit --version-id "$VERSION_ID"
```

**First-time in-app purchases or subscriptions?** Apple requires them to go to review with an app version. Add `--with-products` to step 5 (try `--dry-run` first): see [submit with products](features/submit-with-products.md).

**Rejected?** Find the rejected item with [review submissions](features/review-submissions.md), then read App Review's message with [resolution center](features/resolution-center.md).

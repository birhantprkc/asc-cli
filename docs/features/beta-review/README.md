---
description: Submit a build for TestFlight beta app review and manage the beta review contact and demo account details. Use when sending a build to external testers for the first time.
---

# Beta App Review

TestFlight external testing needs Apple's beta app review. Submit a build, check its review state, and keep the review contact and demo account details current. Every flag: [command reference](../../commands.md#asc-beta-review).

## Quick start
```bash
asc beta-review detail get --app-id <APP_ID>
asc beta-review submissions create --build-id <BUILD_ID>
asc beta-review submissions list --build-id <BUILD_ID>
```

## Workflows

### Send a build to external testers
```bash
# 1. Upload a build
asc builds upload --app-id APP_ID --file MyApp.ipa --version 1.0.0 --build-number 42

# 2. Add the build to an external beta group
asc builds add-beta-group --build-id BUILD_ID --beta-group-id GROUP_ID

# 3. Set the beta review contact (note the detail "id" from get)
asc beta-review detail get --app-id APP_ID
asc beta-review detail update --detail-id DETAIL_ID \
  --contact-first-name "John" \
  --contact-last-name "Doe" \
  --contact-email "john@example.com" \
  --contact-phone "+1-555-0100"

# 4. Submit for beta app review
asc beta-review submissions create --build-id BUILD_ID

# 5. Check status
asc beta-review submissions list --build-id BUILD_ID
```

A submission:

```json
{
  "data": [
    {
      "id": "sub-1",
      "buildId": "build-42",
      "state": "WAITING_FOR_REVIEW",
      "affordances": {
        "getSubmission": "asc beta-review submissions get --submission-id sub-1",
        "listSubmissions": "asc beta-review submissions list --build-id build-42"
      }
    }
  ]
}
```

### Add a demo account
```bash
asc beta-review detail update --detail-id DETAIL_ID \
  --demo-account-required \
  --demo-account-name demo_user \
  --demo-account-password "secret" \
  --notes "Log in with the demo credentials"
```

## Gotchas
- Submission `state` is one of `WAITING_FOR_REVIEW`, `IN_REVIEW`, `REJECTED`, `APPROVED`.
- The review detail belongs to the app (`detail get --app-id`), but `detail update` takes the detail's own `id`.
- `--demo-account-required` is a switch with no value, unlike `asc version-review-detail update`, which takes `true`/`false`.
- `detail update` sends only the fields you pass.
- The contact counts as complete only when both email and phone are set. A demo account counts as configured only when it is not required, or when both a name and a password are set.
- Unset fields are omitted from the JSON.
- Not exposed over REST.

## See also
[testflight](../testflight/README.md) · [builds-upload](../builds-upload/README.md) · [version-review-detail](../version-review-detail/README.md)

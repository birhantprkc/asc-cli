---
description: Set the App Review contact details, demo account credentials and reviewer notes for an App Store version. Use before submitting a version for review.
---

# Version Review Detail

The information App Review needs for a version: contact name, phone and email, demo account credentials, and notes. Setting it clears the `reviewContactCheck` warning in `asc versions check-readiness`. Every flag: [command reference](../../commands.md#asc-version-review-detail).

## Quick start
```bash
asc version-review-detail get --version-id <VERSION_ID> --pretty
asc version-review-detail update --version-id <VERSION_ID> \
  --contact-first-name Jane --contact-last-name Smith \
  --contact-email dev@example.com --contact-phone "+1-555-0100"
```

## Workflows

### Prepare review info before submitting
```bash
# 1. Find the version in PREPARE_FOR_SUBMISSION
asc versions list --app-id <APP_ID> --output table

# 2. See what is set today
asc version-review-detail get --version-id <VERSION_ID> --pretty

# 3. Set contact info
asc version-review-detail update --version-id <VERSION_ID> \
  --contact-first-name Jane \
  --contact-email dev@example.com \
  --contact-phone "+1-555-0100"

# 4. If the app needs a login, add a demo account and notes
asc version-review-detail update --version-id <VERSION_ID> \
  --demo-account-required true \
  --demo-account-name demo_user \
  --demo-account-password "secret" \
  --notes "Tap 'Get Started' then log in with the demo credentials"

# 5. reviewContactCheck should now pass
asc versions check-readiness --version-id <VERSION_ID> --pretty

# 6. Submit
asc versions submit --version-id <VERSION_ID>
```

When review info has never been set, `get` returns an empty record rather than an error:

```json
{
  "data": [
    {
      "id": "",
      "versionId": "74ed4466-...",
      "demoAccountRequired": false,
      "affordances": {
        "getReviewDetail": "asc version-review-detail get --version-id 74ed4466-...",
        "updateReviewDetail": "asc version-review-detail update --version-id 74ed4466-..."
      }
    }
  ]
}
```

Once set, the record has a real `id` and the contact fields (`contactFirstName`, `contactLastName`, `contactEmail`, `contactPhone`) appear.

## Gotchas
- `update` is an upsert: if no record exists (empty `id`) it creates one, otherwise it changes only the fields you pass and leaves the rest as they are.
- Apple returns `{"data": null}` rather than a 404 for a version with no review info. The CLI turns that into the empty record above, so check for `"id": ""` to find unset review info.
- `reviewContactCheck` needs both `contactEmail` and `contactPhone`. It is a SHOULD FIX warning in `check-readiness` and does not block submission.
- A demo account counts as configured only when `--demo-account-required` is `false`, or when both a name and a password are set.
- Unset fields are omitted from the JSON.
- `AppStoreVersion` responses carry a `getReviewDetail` affordance, so an agent can reach this command from `asc versions list`.
- Not exposed over REST.

## See also
[version-check-readiness](../version-check-readiness/README.md) · [review-submissions](../review-submissions/README.md)

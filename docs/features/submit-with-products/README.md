---
description: Send in-app purchases, subscriptions and subscription groups to App Review in the same submission as an app version. Use when submitting first-time products, which Apple requires to ride with an app version.
---

# Submit Products with an App Version

Send IAPs, subscriptions and subscription groups to App Review in the same review submission as an app version, using only the public API and your API key. Every flag: [versions](../../commands.md#asc-versions), [review-submissions](../../commands.md#asc-review-submissions), [iap](../../commands.md#asc-iap), [subscriptions](../../commands.md#asc-subscriptions), [subscription-groups](../../commands.md#asc-subscription-groups).

Apple versions products the way it versions apps: every IAP, subscription and subscription group has versions. A version in `PREPARE_FOR_SUBMISSION` goes to review by being added as an item to a review submission, next to the app version. This replaces the iris (cookie-auth) workaround for "the first IAP must be submitted with a new app version".

| Goal | Command |
|------|---------|
| Submit an app version and every ready product together | `asc versions submit --version-id <id> --with-products` |
| See what that would send, without submitting | `asc versions submit --version-id <id> --with-products --dry-run` |
| Build a submission item by item | `asc review-submissions create` → `items add` → `submit` |
| Find a product's submittable version | `asc iap versions list` / `asc subscriptions versions list` / `asc subscription-groups versions list` |

## Quick start

```bash
VERSION=ver-1
asc versions submit --version-id $VERSION --with-products --dry-run --output table
asc versions submit --version-id $VERSION --with-products
```

## Workflows

### Submit the app version and all ready products

```bash
# 1. Products must be READY_TO_SUBMIT (metadata, pricing, review screenshot complete)
asc iap list --app-id 1234567890 --output table
asc subscriptions list --group-id group-1 --output table

# 2. See exactly what will go to review
asc versions submit --version-id $VERSION --with-products --dry-run --output table

# 3. Submit the app version and the products together
asc versions submit --version-id $VERSION --with-products
```

What goes in, in this order:
1. the app version;
2. each `READY_TO_SUBMIT` in-app purchase's first submittable version;
3. for each subscription group with at least one `READY_TO_SUBMIT` subscription: the group's submittable version, then those subscriptions' submittable versions.

```
Kind                        Version ID  Product ID  Name
--------------------------  ----------  ----------  ------------
APP_STORE_VERSION           ver-1       1234567890  1.0
IN_APP_PURCHASE_VERSION     iapv-1      iap-1       Pro Lifetime
SUBSCRIPTION_GROUP_VERSION  sgv-1       group-1     Pro
SUBSCRIPTION_VERSION        subv-1      sub-1       Pro Monthly
```

A real run prints the submission (`state: WAITING_FOR_REVIEW`).

### Build a submission step by step

```bash
asc subscription-groups versions list --group-id group-1 --pretty
SUB=$(asc review-submissions create --app-id 1234567890 | jq -r '.data[0].id')
asc review-submissions items add --submission-id $SUB --version-id $VERSION
asc review-submissions items add --submission-id $SUB --iap-version-id iapv-1
asc review-submissions items list --submission-id $SUB --output table
asc review-submissions submit --submission-id $SUB
```

A product version carries an `addToSubmission` affordance while it is submittable:

```json
{
  "affordances" : {
    "addToSubmission" : "asc review-submissions items add --submission-id <submission-id> --subscription-group-version-id sgv-1",
    "listVersions" : "asc subscription-groups versions list --group-id group-1"
  },
  "id" : "sgv-1",
  "kind" : "SUBSCRIPTION_GROUP",
  "productId" : "group-1",
  "state" : "PREPARE_FOR_SUBMISSION",
  "version" : 1
}
```

`items add` takes exactly one of `--version-id`, `--iap-version-id`, `--subscription-version-id`, `--subscription-group-version-id` and prints the item with a `remove` affordance. `asc review-submissions items remove --item-id <id>` removes an item that hasn't been submitted (item state `READY_FOR_REVIEW`).

### Fix a refusal

When Apple refuses, the error lists the reasons from `meta.associatedErrors`, not only its generic headline:

```
Error: Apple refused the review submission: This resource cannot be reviewed, please check associated errors to see why.
  - A screenshot for one of the following types is required but was not provided: APP_IPAD_PRO_3GEN_129
  - App is not eligible for submission until pricing has been set.
```

| Reason | Fix |
|--------|-----|
| `contentRightsDeclaration` required | `asc apps update --app-id <id> --content-rights-declaration DOES_NOT_USE_THIRD_PARTY_CONTENT` (or `USES_THIRD_PARTY_CONTENT`) |
| Pricing not set | `asc apps price-points list --app-id <id>` then `asc apps prices set --app-id <id> --base-territory USA --price-point-id <id>` (the `0.0` point makes it free); see [app-pricing](../app-pricing/README.md) |
| App Privacy data usages not published | No public API: App Privacy answers exist only behind the web session. Publish them in App Store Connect (App Privacy) |
| Required screenshot (e.g. `APP_IPAD_PRO_3GEN_129`) missing | `asc screenshot-sets` / `asc screenshots` for that display type |

## REST

| Method | Path | CLI equivalent |
|--------|------|----------------|
| `POST` | `/api/v1/versions/{versionId}/submit` | `versions submit` (`?with-products=true`, `?dry-run=true`) |
| `GET` | `/api/v1/iap/{iapId}/versions` | `iap versions list` |
| `GET` | `/api/v1/subscriptions/{subscriptionId}/versions` | `subscriptions versions list` |
| `GET` | `/api/v1/subscription-groups/{groupId}/versions` | `subscription-groups versions list` |
| `POST` | `/api/v1/apps/{appId}/review-submissions` | `review-submissions create` (body `{"platform": "ios"}`) |
| `POST` | `/api/v1/review-submissions/{id}/items` | `review-submissions items add` (body: exactly one of `version-id`, `iap-version-id`, `subscription-version-id`, `subscription-group-version-id`) |
| `DELETE` | `/api/v1/review-submissions/items/{itemId}` | `review-submissions items remove` (returns `{"removed":true}`) |
| `POST` | `/api/v1/review-submissions/{id}/submit` | `review-submissions submit` |

Body keys and query names are the CLI flag names.

```bash
curl -X POST 'http://localhost:8420/api/v1/versions/ver-1/submit?with-products=true&dry-run=true'
curl -X POST http://localhost:8420/api/v1/review-submissions/submission-1/items \
  -d '{"iap-version-id": "iapv-1"}'
```

## Gotchas

- `--dry-run` implies `--with-products`. Without either flag, `versions submit` sends the app version alone.
- Products still `MISSING_METADATA`, or whose version is already in review or approved, are left out.
- A product version is submittable (and shows `addToSubmission`) in `PREPARE_FOR_SUBMISSION`, `REJECTED` or `DEVELOPER_REJECTED`.
- Apple allows one open submission (`READY_FOR_REVIEW` or `UNRESOLVED_ISSUES`) per app and platform; `create` and `--with-products` reuse it. `create` defaults to `--platform ios`.
- If Apple refuses an item, the command stops before submitting; items added so far stay in the draft (`asc review-submissions items list`).
- Apple doesn't allow deleting a review submission and cancels only submitted ones; an unused draft stays `READY_FOR_REVIEW` and is reused by the next `create`.
- Apple sometimes answers `500 UNEXPECTED_ERROR` instead of a refusal when adding an app version to an older, empty draft; a fresh draft returns the real reasons. Other 5xx errors are shown as they are.
- The planner reads up to 200 IAPs, groups and subscriptions per parent (one page).
- `asc versions check-readiness` doesn't check what Apple checks on submission (screenshot sizes, content rights, App Privacy, pricing); the refusal reasons surface those.

## See also

[review-submissions](../review-submissions/README.md) · [iap-subscriptions](../iap-subscriptions/README.md) · [app-pricing](../app-pricing/README.md) · [version-check-readiness](../version-check-readiness/README.md)

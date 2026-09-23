---
description: Manage the "Featured In-App Purchases" slots on an app's App Store product page. Use when promoting an IAP or subscription on the product page, or hiding/disabling a promoted slot.
---

# Promoted Purchases

The "Featured In-App Purchases" slots under an app's App Store product page. Each slot promotes either an in-app purchase or an auto-renewable subscription and goes through App Review separately. Every flag: [command reference](../../commands.md#asc-promoted-purchases).

## Quick start
```bash
asc promoted-purchases list --app-id <APP_ID>
asc promoted-purchases create --app-id <APP_ID> --iap-id <IAP_ID> --visible --enabled
```

## Workflows

### Promote a subscription, then hide it
```bash
asc promoted-purchases create --app-id <APP_ID> --subscription-id <SUB_ID> --visible --enabled
asc promoted-purchases update --promoted-id <PROMOTED_ID> --hidden
asc promoted-purchases delete --promoted-id <PROMOTED_ID>
```

`--visible` / `--hidden` set `isVisibleForAllUsers`; `--enabled` / `--disabled` set `isEnabled`. Omitting a pair leaves that field unchanged on `update`; on `create`, visibility defaults to visible.

In table output the promoted target shows as `iap:<id>` or `sub:<id>`.

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/promoted-purchases` | `asc promoted-purchases list --app-id` |

Create, update and delete are CLI-only.

## Gotchas
- `create` needs exactly one of `--iap-id` / `--subscription-id`.
- A slot's `state` is one of `APPROVED`, `REJECTED`, `PREPARE_FOR_SUBMISSION`, `WAITING_FOR_REVIEW`, `IN_REVIEW`, `DEVELOPER_ACTION_NEEDED`. `isLocked` is true while waiting for or in review; `isApproved` only for approved.
- The `update` and `delete` affordances are hidden while a slot is `WAITING_FOR_REVIEW` or `IN_REVIEW`: App Store Connect answers a change to a slot in review with a 409 conflict.

## See also
[iap-subscriptions](../iap-subscriptions/README.md)

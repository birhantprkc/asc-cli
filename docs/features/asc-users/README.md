---
description: Manage App Store Connect team members, their roles, and pending user invitations. Use when onboarding or offboarding people or changing someone's access.
---

# Users & Roles

Manage App Store Connect team members and pending user invitations, for example to revoke access automatically when someone leaves. Every flag: [users](../../commands.md#asc-users), [user-invitations](../../commands.md#asc-user-invitations).

## Quick start

```bash
asc users list --role DEVELOPER --output table
asc user-invitations invite --email new-dev@example.com --first-name Alex --last-name Smith --role DEVELOPER
asc users remove --user-id u-abc
```

## Workflows

### Onboard a new developer

```bash
asc user-invitations invite \
  --email new-hire@example.com \
  --first-name Alex \
  --last-name Smith \
  --role DEVELOPER \
  --role APP_MANAGER
```

Pending invitations show up in `asc user-invitations list`, each with a `cancel` affordance (`asc user-invitations cancel --invitation-id inv-1`).

### Promote a developer to App Manager

```bash
USER_ID=$(asc users list --role DEVELOPER | jq -r '.data[] | select(.username == "dev@example.com") | .id')
asc users update --user-id "$USER_ID" --role APP_MANAGER --role DEVELOPER
```

A team member's `updateRoles` affordance is pre-filled with their current roles:

```json
{
  "affordances": {
    "remove": "asc users remove --user-id u-1",
    "updateRoles": "asc users update --user-id u-1 --role DEVELOPER --role APP_MANAGER"
  },
  "firstName": "Jane",
  "id": "u-1",
  "isAllAppsVisible": false,
  "isProvisioningAllowed": true,
  "lastName": "Doe",
  "roles": ["DEVELOPER", "APP_MANAGER"],
  "username": "jdoe@example.com"
}
```

### Revoke access on offboarding (directory integration)

```bash
DEPARTED_EMAIL="former-employee@example.com"

USER_ID=$(asc users list | jq -r --arg email "$DEPARTED_EMAIL" \
  '.data[] | select(.username == $email) | .id')

if [ -n "$USER_ID" ]; then
  asc users remove --user-id "$USER_ID"
else
  # Check for a pending invitation
  INV_ID=$(asc user-invitations list | jq -r --arg email "$DEPARTED_EMAIL" \
    '.data[] | select(.email == $email) | .id')
  [ -n "$INV_ID" ] && asc user-invitations cancel --invitation-id "$INV_ID"
fi
```

## Gotchas

- `asc users update` replaces all of a member's roles; pass every role they should keep, one `--role` per role.
- `asc users remove` revokes access immediately.
- Team members match by `username` (their Apple ID email); invitations match by `email`.
- Roles: `ADMIN`, `FINANCE`, `ACCOUNT_HOLDER`, `SALES`, `MARKETING`, `APP_MANAGER`, `DEVELOPER`, `ACCESS_TO_REPORTS`, `CUSTOMER_SUPPORT`, `CREATE_APPS`, `CLOUD_MANAGED_DEVELOPER_ID`, `CLOUD_MANAGED_APP_DISTRIBUTION`, `GENERATE_INDIVIDUAL_KEYS`. Uppercase or lowercase is accepted.
- `--all-apps-visible` on `invite` defaults to false.
- Users and invitations are CLI-only; there are no REST routes for them.

## See also

[asc-auth](../asc-auth/README.md)

---
description: Manage TestFlight beta groups and testers, and bulk import/export testers via CSV. Use when distributing a build to testers.
---

# TestFlight

Beta groups and testers: create groups, invite and remove testers, and move testers between groups with CSV. Every flag: [command reference](../../commands.md#asc-testflight).

## Quick start

```bash
asc testflight groups list --app-id 6450406024 --pretty
asc testflight testers list --beta-group-id g-abc123 --pretty
asc testflight testers add --beta-group-id g-abc123 --email jane@example.com --first-name Jane --last-name Doe
```

## Workflows

### Create a group

```bash
# External group with public link
asc testflight groups create --app-id 6450406024 --name "External Beta" --public-link-enabled

# Internal group (team members only)
asc testflight groups create --app-id 6450406024 --name "Company Team" --internal
```

Group JSON carries next steps:

```json
{
  "id": "g-abc123",
  "appId": "6450406024",
  "name": "External Beta",
  "isInternalGroup": false,
  "publicLinkEnabled": false,
  "affordances": {
    "exportTesters": "asc testflight testers export --beta-group-id g-abc123",
    "importTesters": "asc testflight testers import --beta-group-id g-abc123 --file testers.csv",
    "listTesters": "asc testflight testers list --beta-group-id g-abc123"
  }
}
```

### Bulk add testers from CSV

```bash
cat > testers.csv <<'EOF'
email,firstName,lastName
jane@example.com,Jane,Doe
anon@example.com,,
EOF
asc testflight testers import --beta-group-id g-abc123 --file testers.csv
```

Returns the testers that were created (same shape as `testers list`).

### Copy testers from one group to another

```bash
asc testflight testers export --beta-group-id g-abc123 > testers.csv
asc testflight testers import --beta-group-id g-new456 --file testers.csv
```

### Remove a tester

Each tester in `testers list` has a `remove` affordance:

```bash
asc testflight testers remove --beta-group-id g-abc123 --tester-id t-xyz789
# Removed tester t-xyz789 from group g-abc123
```

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/testflight` | `asc testflight groups list --app-id <id>` |

## Gotchas

- CSV needs the header row `email,firstName,lastName`; names may be empty. `export` writes exactly that format, so export → import round-trips.
- Groups are external unless you pass `--internal`. `--public-link-enabled` and `--feedback-enabled` only apply to external groups.
- `testers add` invites the email and adds it to the group in one step.
- `testers remove` only takes the tester out of the group; it does not delete their account.
- Only group listing is exposed over REST; tester changes are CLI-only.

## See also

[beta-review](../beta-review/README.md) · [beta-app-localizations](../beta-app-localizations/README.md) · [builds-upload](../builds-upload/README.md)

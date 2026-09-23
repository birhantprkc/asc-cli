---
description: Manage bundle IDs, signing certificates, test devices and provisioning profiles. Use when setting up code signing for CI/CD or cleaning up expired certificates.
---

# Code Signing

The four App Store Connect code signing resources: bundle identifiers, signing certificates, test devices, and provisioning profiles.
Every flag: [bundle-ids](../../commands.md#asc-bundle-ids) · [certificates](../../commands.md#asc-certificates) · [devices](../../commands.md#asc-devices) · [profiles](../../commands.md#asc-profiles).

## Quick start

```bash
asc bundle-ids list --platform ios --pretty
asc certificates list --type IOS_DISTRIBUTION
asc profiles list --bundle-id-id <bundle-id-id> --pretty
```

## Workflows

### Set up signing for a new app (CI/CD)

```bash
# 1. Register the bundle identifier
asc bundle-ids create --name "My App" --identifier "com.example.myapp" --platform ios

# 2. Create a distribution certificate from a CSR
asc certificates create --type IOS_DISTRIBUTION --csr-path MyApp.certSigningRequest

# 3. (Development only) Register test devices
asc devices register --name "My iPhone" --udid "00000000-0000-0000-0000-000000000001" --platform ios

# 4. Look up the resource IDs for the profile
asc bundle-ids list --identifier com.example.myapp
asc certificates list --type IOS_DISTRIBUTION

# 5. Create the provisioning profile (add --device-ids for development profiles)
asc profiles create \
  --name "My App Store Profile" \
  --type IOS_APP_STORE \
  --bundle-id-id <bundle-id-id> \
  --certificate-ids <cert-id>

# 6. Verify
asc profiles list --bundle-id-id <bundle-id-id> --pretty
```

Each bundle ID comes back with ready-to-run next steps:

```json
{
  "data": [
    {
      "affordances": {
        "delete": "asc bundle-ids delete --bundle-id-id B1",
        "listProfiles": "asc profiles list --bundle-id-id B1"
      },
      "id": "B1",
      "identifier": "com.example.app",
      "name": "My App",
      "platform": "IOS"
    }
  ]
}
```

### Find and revoke expiring certificates

```bash
asc certificates list --expired-only
asc certificates list --before 2026-11-01
asc certificates revoke --certificate-id <id>
```

### Remove a bundle ID or profile

```bash
asc profiles delete --profile-id <id>
asc bundle-ids delete --bundle-id-id <id>
```

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/certificates` | `asc certificates list` |
| GET | `/api/v1/bundle-ids` | `asc bundle-ids list` |
| GET | `/api/v1/devices` | `asc devices list` |
| GET | `/api/v1/profiles` | `asc profiles list` |

`/certificates` query params match the CLI flags: `?type=`, `?limit=`, `?expired-only=true`, `?before=`. The other routes take no filters.

## Gotchas

- `--csr-path` is the safe way to pass a CSR: PEM content starts with `-----`, which breaks shell argument parsing when passed via `--csr-content`.
- `--expired-only` and `--before` are client-side filters applied after the server returns results; `--limit` is applied server-side, so combining them can return fewer rows than expected.
- `--before` accepts `YYYY-MM-DD` (midnight UTC) or full ISO8601 (`2026-11-01T00:00:00Z`); certificates without an expiration date are excluded.
- `profiles create` needs at least one certificate ID; `--device-ids` is only for development profiles.
- `profiles list --bundle-id-id` filters server-side and every profile carries its `bundleIdId`.
- There is no `devices delete` command; devices can be listed and registered only.

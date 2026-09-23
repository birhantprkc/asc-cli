---
description: Add your App Store apps to the asc community app wall on asccli.app by opening a GitHub pull request. Use when showcasing apps published with asc.
---

# App Wall

Community showcase of apps published on the App Store using asc, displayed at [asccli.app/#app-wall](https://asccli.app/#app-wall) as an auto-scrolling marquee of app cards. `asc app-wall submit` adds your entry to `homepage/apps.json` and opens a PR. Every flag: [command reference](../../commands.md#asc-app-wall).

## Quick start

```bash
export GITHUB_TOKEN="ghp_..."          # or: gh auth login
asc app-wall submit --app-id 1234567890 --developer "your-handle"
```

## Workflows

### Submit your app

```bash
# All apps by developer ID, with social links
asc app-wall submit \
  --developer "yourhandle" \
  --developer-id "1234567890" \
  --github "yourgithub" \
  --x "yourx" \
  --pretty

# Specific App Store URLs (repeat --app or --app-id for several)
asc app-wall submit \
  --developer "your-handle" \
  --app "https://apps.apple.com/us/app/my-app/id123456789"

# All modes combined
asc app-wall submit \
  --developer "your-handle" \
  --developer-id "987654320" \
  --app-id 1234567890 \
  --app "https://apps.apple.com/us/app/extra-app/id987654321"
```

The CLI forks `tddworks/asc-cli` on your behalf, adds your entry to `homepage/apps.json`, and opens a PR. The PR URL is in the output:

```json
{
  "data": [
    {
      "affordances": { "openPR": "open https://github.com/tddworks/asc-cli/pull/42" },
      "developer": "your-handle",
      "prNumber": 42,
      "prUrl": "https://github.com/tddworks/asc-cli/pull/42",
      "title": "feat(app-wall): add your-handle"
    }
  ]
}
```

### Contribute by editing apps.json directly

Each entry in `homepage/apps.json` is one object. Two modes, combinable:

```json
[
  {
    "developer": "your-github-handle",
    "developerId": "1234567890",
    "github": "your-github-handle",
    "x": "your-x-handle"
  },
  {
    "developer": "your-github-handle",
    "github": "your-github-handle",
    "apps": [
      "https://apps.apple.com/us/app/your-app/idXXXXXXXXX"
    ]
  }
]
```

| Field | Required | Description |
|-------|----------|-------------|
| `developer` | no | Display handle shown on the card (`@developer`); defaults to the App Store artist name |
| `developerId` | no | Apple developer ID; auto-fetches all your App Store apps |
| `github` | no | GitHub username; card links to `github.com/<handle>` with a GitHub icon |
| `x` | no | X/Twitter handle; card links to `x.com/<handle>` with an X icon |
| `apps` | no | Array of explicit App Store URLs for specific apps only |

`developerId` and `apps` can be combined; duplicate apps (by `trackId`) are removed automatically.

## Gotchas

- At least one of `--developer-id`, `--app-id` or `--app` is required; an entry with none has no apps to show.
- `--app-id` builds the App Store URL for you. Without `--developer`, the homepage shows the iTunes artist name.
- No App Store Connect auth is needed, only a GitHub token. Resolution order: `--github-token` → `$GITHUB_TOKEN` → `gh auth token`.
- `Developer X is already listed`: an entry with the same developer name (or developer ID / app ID when no name is given) is already in `apps.json`; check the existing PR.
- If the fork isn't ready after about 21 seconds (8 tries), the last GitHub error is shown (usually `GitHub API error (404)`); retry after a moment.
- `GitHub API error (422)` for an existing branch is safe to ignore; the command continues with that branch.
- `homepage/apps-data.json` is generated from `apps.json`; don't edit it by hand.

## See also

[Homepage pipeline](homepage-pipeline.md) (how `apps.json` becomes the marquee, `apps-data.json` format)

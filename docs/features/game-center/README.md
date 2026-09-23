---
description: Get an app's Game Center configuration and list, create or delete its achievements and leaderboards. Use when setting up Game Center for a game.
---

# Game Center

Game Center achievements and leaderboards for an app. Everything hangs off the app's Game Center detail ID.
Every flag: [command reference](../../commands.md#asc-game-center).

## Quick start

```bash
asc game-center detail get --app-id 6450000000 --pretty
asc game-center achievements list --detail-id gc-abc123
asc game-center leaderboards list --detail-id gc-abc123
```

## Workflows

### Set up achievements and leaderboards

```bash
# 1. Get the Game Center detail for your app (app-id from asc apps list)
asc game-center detail get --app-id 6450000000 --pretty

# 2. Create an achievement
asc game-center achievements create \
  --detail-id gc-abc123 \
  --reference-name "First Launch" \
  --vendor-identifier "first_launch" \
  --points 10

# 3. Create a high-score leaderboard
asc game-center leaderboards create \
  --detail-id gc-abc123 \
  --reference-name "All Time High" \
  --vendor-identifier "all_time_high" \
  --score-sort-type DESC \
  --submission-type BEST_SCORE

# 4. Verify
asc game-center achievements list --detail-id gc-abc123
asc game-center leaderboards list --detail-id gc-abc123
```

The detail response gives you the `id` to pass as `--detail-id`, plus ready-to-run next steps:

```json
{
  "data": [
    {
      "affordances": {
        "getDetail": "asc game-center detail get --app-id 6450000000",
        "listAchievements": "asc game-center achievements list --detail-id gc-abc123",
        "listLeaderboards": "asc game-center leaderboards list --detail-id gc-abc123"
      },
      "appId": "6450000000",
      "id": "gc-abc123",
      "isArcadeEnabled": false
    }
  ]
}
```

Each achievement and leaderboard carries a `delete` affordance and a link back to its list.

### Remove an achievement or leaderboard

```bash
asc game-center achievements delete --achievement-id ach-abc123
asc game-center leaderboards delete --leaderboard-id lb-abc123
```

## Gotchas

- `--score-sort-type`: `ASC` means lowest score wins, `DESC` means highest score wins.
- `--submission-type`: `BEST_SCORE` (default) tracks the player's personal best; `MOST_RECENT_SCORE` tracks their latest submission.
- `--reference-name` is internal only and not shown to players; `--vendor-identifier` must be unique (e.g. `first_steps`).
- `--show-before-earned` shows the achievement before the player earns it; `--repeatable` lets it be earned more than once.
- There are no update commands yet, and leaderboard sets are not supported.
- Game Center is CLI-only; there are no REST routes for it.

## See also

[apps](../../commands.md#asc-apps)

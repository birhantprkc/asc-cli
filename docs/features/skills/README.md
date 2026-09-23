---
description: Browse, install, update and remove the asc Claude Code agent skills. Use when setting up an AI agent to drive asc or keeping its skills current.
---

# Skills

Manage the Claude Code agent skills published in the `tddworks/asc-cli-skills` repository: browse, install, check for updates, and remove.
Every flag: [command reference](../../commands.md#asc-skills).

## Quick start

```bash
asc skills install --all
asc skills installed --pretty
```

## Workflows

### Install, keep current, and prune

```bash
asc skills list                              # browse what's available
asc skills install --name asc-cli            # one skill (no flags = all)
asc skills installed --pretty                # what you have
asc skills check                             # updates available?
asc skills update                            # re-install all skills from the repo (same as install --all)
asc skills uninstall --name asc-game-center  # remove one
```

`installed` reads `~/.claude/skills/` and returns each skill with `listSkills` and `uninstall` affordances.

```json
{
  "data" : [
    {
      "affordances" : {
        "listSkills" : "asc skills list",
        "uninstall" : "asc skills uninstall --name asc-cli"
      },
      "description" : "App Store Connect CLI skill",
      "id" : "asc-cli",
      "isInstalled" : true,
      "name" : "asc-cli"
    }
  ]
}
```

`check` prints one of:
- "All skills are up to date."
- "Skill updates are available. Run 'asc skills update' to refresh installed skills."
- "Skills CLI is not available. Install with: npm install -g skills"

## Gotchas

- `list`, `install`, `check` and `update` shell out to the `skills` npm tool (`npx skills ...`), so Node.js/`npx` must be available. `installed` and `uninstall` work directly on `~/.claude/skills/`.
- `asc skills check` saves the check time as `skillsCheckedAt` in `~/.asc/skills-config.json` on every run.
- Skills are not exposed over REST.

## See also

[plugins](../plugins/README.md)

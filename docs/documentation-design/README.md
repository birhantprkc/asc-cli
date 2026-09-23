---
description: How asc-cli docs are layered (Skill-style progressive disclosure), where each kind of content lives, and the limits CI enforces. Read before adding or restructuring any doc.
---

# Documentation Design

> Status: **adopted**, 2026-09-23. `make check-docs` enforces it in CI.

## Goal

**Reduce accidental complexity so docs are easy to change.**

Every other rule in this doc follows from that goal. Each fact has exactly one home, so a code change touches at most one doc. When choosing between two options, pick the one where *the next change touches fewer places*.

## Problem

| File | Today | Accidental complexity |
|---|---|---|
| `README.md` | 727 lines | Hand-written command reference (~400 lines) repeats `docs/features/*`, so one flag change means two edits |
| `CHANGELOG.md` | 1049 lines | Bullets average 750–1,575 chars and name internal types, file paths and SDK calls, which repeats the PR |
| `docs/features/*.md` | 45 files, ~16.9k lines | Architecture, File Map, Domain Models, Testing and Extending (~16.5k lines) restate the source and go stale when code changes |
| `CLAUDE.md` | 277 lines, loaded every session | The domain folder tree repeats `ls Sources/Domain`; feature-only checklists are loaded on every task |
| Links | 7 broken | Nothing checks them |

**Root cause:** the doc rules make every feature copy the same facts into several places (README list + README examples + 9-section doc + long changelog bullet). Copies have to be kept in sync by hand, and nothing checks that they are.

## Principle: docs load like Skills

Agent Skills stay cheap by loading content in three tiers, where each tier only *points* to the next:

| Skill tier | Loaded | asc-cli docs equivalent |
|---|---|---|
| **1. Metadata** (`name` + `description`) | Always | `README.md`, `CLAUDE.md`, the `docs/README.md` index, CHANGELOG lines |
| **2. Instructions** (`SKILL.md` body) | When needed | `docs/features/<x>/README.md`: how to use one feature |
| **3. Resources** (`references/`, `scripts/`) | On demand, by link | Topic files next to it in `docs/features/<x>/`, generated command reference |

Rules:

1. **One home per fact; tiers link, they don't copy.** Any copy is a future inconsistency.
2. **Don't write what code or `--help` already says.** Flags, file trees and model fields are read from the source, like Skill scripts that run outside the context window. A doc can't go stale about something it doesn't contain.
3. **Same shape everywhere; nothing empty.** Every feature gets the same folder shape, but no empty subfolders and no metadata fields that nothing reads.

The CLI already does this at runtime: CAEOAS affordances show only the next legal commands. The docs follow the same shape.

## Layout

```
README.md                       tier 1: pitch, install, quick start, feature table → links
CLAUDE.md                       tier 1: agent rules only (TDD gate, layers, pointers)
CONTRIBUTING.md                 tier 1: build, test, where things go → links
CHANGELOG.md                    tier 1: [Unreleased] + current minor only, one line per change → links
docs/
├── README.md                   tier 1: index, GENERATED from feature descriptions
├── documentation-design/      this design (README.md) + layout.md
├── design.md                   CAEOAS + architecture reasons (renamed from desgin.md)
├── library.md                  use as a Swift package (moved from README)
├── release.md                  end-to-end release workflow (moved from README)
├── commands.md                 tier 3: GENERATED from swift-argument-parser, never hand-edited
├── changelog/                  tier 3: one file per past minor, moved as-is, never edited
│   ├── 0.17.md
│   └── 0.1.md
└── features/                   one folder per feature, shaped like a Skill
    ├── testflight/
    │   └── README.md           tier 2: description + user guide (≤200 lines); most features stop here
    └── iap-subscriptions/
        ├── README.md           tier 2
        ├── pricing.md          tier 3: topic files, added only when README outgrows 200 lines
        ├── offer-codes.md
        └── assets/             only if the feature has images
```

File-by-file detail, written from the reader's side with a mockup of each file: [layout.md](layout.md).

Every feature is a folder with a `README.md`, in the same way every skill is a folder with a `SKILL.md`:

- **One predictable path.** A feature's docs are always at `docs/features/<x>/`, next to its skill at `skills/asc-<x>/`. Readers and agents never have to check whether a feature is a file, a folder or both.
- **Growing never moves anything.** A deep dive becomes a new file next to `README.md`. The feature doc's own path and links stay the same.
- **GitHub shows it on open.** Browsing `docs/features/testflight/` renders the README.
- **Topic files sit next to `README.md`, with no `references/` level.** That matches the `pdf` skill (`forms.md` and `reference.md` next to `SKILL.md`). `assets/` only exists when there are images.

## Tier 1: metadata

### Frontmatter: one field

```yaml
---
description: Manage beta groups and testers, import/export CSV, submit builds for beta review. Use when distributing a build to testers.
---
```

- `description` works like a Skill's: one sentence saying *what* and *when*, ≤250 chars.
- There is no `name` field, because the filename is the name. There are no other fields until something reads them.
- `make docs` builds `docs/README.md` from these lines. Adding a feature means writing one file, and the index updates itself.

### README.md (≤150 lines)

Keeps: logo/badges, one-paragraph pitch, install, 4-command quick start, one CAEOAS JSON example, the Features table (each row links to its feature doc), links to Docs index / Contributing / Changelog, Sponsors, License.

| Section today | New home |
|---|---|
| Command Reference (~400 lines) | Removed; `docs/commands.md` is generated |
| Optional iris sign-in | `docs/features/iris/README.md` |
| Authentication details | `docs/features/asc-auth/README.md` |
| Release Workflow | `docs/release.md` |
| Feature Guides list | `docs/README.md` (generated) |
| Use as a Swift Package | `docs/library.md` |
| Development | `CONTRIBUTING.md` |

### CLAUDE.md (≤100 lines)

Keeps: the TDD gate, build/test commands, the three-layer rule, a one-paragraph CAEOAS summary, and pointers.

- **Moves to the `implement-feature` skill** (loaded only while building a feature): the REST exposure checklist, doc-update rules, domain model design rules.
- **Deleted** because the code already says it: the domain folder tree and the resource hierarchy list.

### CHANGELOG.md

Answers the upgrader's questions in order: *will this break me → is my bug fixed → what's new*. Going forward:

- `Removed` / `Changed` come before `Added`; anything incompatible starts with `Breaking:` and says what to use instead.
- Each bullet starts with what the user types, says the effect rather than the implementation, and is ≤300 chars. Related fixes are merged into one bullet.
- Links point only to files that already exist. The changelog never gets detail files of its own:

  | Link | Points to | Reader gets | When |
  |---|---|---|---|
  | `→ [docs](docs/features/<x>/README.md#<section>)` | The feature doc, deep-linked to the section (e.g. `#gotchas`) | How to use it now | `Added`, `Changed`, `Breaking` — or a fix with a Gotcha to read |
  | `([#123](https://github.com/tddworks/asc-cli/pull/123))` | The PR | Why and how it changed: types, SDK calls, tests | Every bullet |

  The PR link is where the implementation detail that used to fill bullets now lives. URLs don't count toward the 300 chars.
- REST is mentioned only when a route is new, changed or removed.

```markdown
### Added
- `asc experiments`, `experiment-treatments` and `experiment-treatment-localizations` create, start and stop product-page A/B tests. REST: `/api/v1/apps/:appId/experiments`. → [docs](docs/features/product-page-optimization/README.md) ([#NN](https://github.com/tddworks/asc-cli/pull/NN))
```

Real before → after rewrites are in [layout.md](layout.md#changelogmd).

Type names, repository methods, SDK calls and file paths go in the PR, their one home, reached from the bullet's PR link.

#### Size: the current minor stays, older minors roll off

`CHANGELOG.md` is tier 1, so it has to stay small. Humans only read the top, but an agent adding an entry loads the whole file, and at 1,049 lines that means paying for 0.1.0 on every change.

- `CHANGELOG.md` holds `[Unreleased]` plus the **current minor** (today 0.18.x, ~50 lines), then an "Older releases" list linking each `docs/changelog/<minor>.md`.
- **When a new minor is released** (0.18 → 0.19), the 0.18.x sections move unchanged into `docs/changelog/0.18.md` and one link is added. This happens once per minor, not every release, and `scripts/changelog-rollover.py`, run by `scripts/promote-changelog.sh` in the release workflow, does it, so nobody decides anything. `promote-changelog.sh` also fills an empty release with "Bug fixes and improvements." before the rollover, and `scripts/test-changelog-release.sh` (run in CI) covers patch and minor releases with and without entries.
- **Archived sections are moved, never rewritten.** Past entries keep their original wording, and one version's history lives in exactly one place.
- Git history and GitHub Releases keep everything too. The archive is for people who browse, not a second source of truth.

The initial split turns today's 1,049 lines into ~60 in `CHANGELOG.md`, with `docs/changelog/0.17.md`, `0.16.md` and `0.1.md` holding the rest. The one mis-numbered heading, `0.1.74` (dated between 0.17.3 and 0.17.5, so really 0.17.4), goes into `0.17.md` with its heading unchanged. The 0.1.x line ends at 0.1.68, after which numbering continued as 0.16.9.

## Tier 2: feature doc (≤200 lines)

Written for someone *using* the feature, human or agent. It contains only what `--help` and the code can't say:

1. **Title + one-line summary**
2. **Quick start**: the 2–4 commands of the happy path
3. **Workflows**: end-to-end scripts for common jobs, with a JSON sample only where the shape isn't obvious
4. **REST endpoints**: path table + CLI flag → query param mapping + one curl example
5. **Gotchas**: Apple API limits, iris requirements, state rules ("`start` only appears when approved"), why a workaround exists
6. **See also**: `docs/commands.md#<cmd>` for all flags, topic files in the same folder, related features

There are **no flag tables**: flags change with the code, and `docs/commands.md` is generated from it. Also none of the following:
- architecture diagrams, which live once in `docs/design.md`
- file maps
- domain model field lists
- test snippets
- "Extending" stubs

If a README outgrows 200 lines, move a topic into `docs/features/<x>/<topic>.md` next to it and link to it.

**Example data:** commands and JSON samples use placeholders (`1234567890` for app IDs, `ver-1`, `sub-1`, `iap-1`, `jane@example.com`), never output copied from a real account: no real app, product or version IDs, app names, bundle IDs, handles or App Review text. `check-docs.py` flags real-looking UUIDs.

## Tier 3: resources

- **`docs/commands.md`**: generated by `make docs` from `asc --experimental-dump-help` (plugins disabled). It is the only complete flag list. Skills link to it instead of copying it (`skills/asc-cli/references/commands.md` is a follow-up in the skills repo).
- **`docs/features/<x>/<topic>.md`**: deep dives that are too long for the feature doc, such as IAP pricing, the iris SRP flow or plugin authoring.
- **`docs/features/<x>/design.md`**: contributor design notes for a subsystem that is mostly internal (command center, web server, screenshot editor). Its README stays a short user-facing summary that links here.
- **Deleted, not moved**: File Map, Domain Models, API Reference tables, Testing, Extending. The code is their one home. Anyone reading at that depth is already in the source.

## Reader paths

| Reader | Path |
|---|---|
| New user | README → quick start |
| Feature user | README table / `docs/README.md` → feature doc |
| Needs every flag | feature doc → `docs/commands.md` or `asc <cmd> --help` |
| Agent using the CLI | Skill → feature doc → CAEOAS affordances at runtime |
| Contributor | CONTRIBUTING → `docs/design.md` → code |
| Agent building a feature | CLAUDE.md → `implement-feature` skill → its references |

## Update rules (replace the table in CLAUDE.md)

| Change | Touch | Nothing else |
|---|---|---|
| New feature | `docs/features/<x>/README.md` with a `description`, one CHANGELOG line, `make docs` | README only if it's a new Features-table category |
| New or changed flag | Nothing; `make docs` regenerates `commands.md` | |
| Improvement | The affected feature doc section, one CHANGELOG line | |
| Bug fix | One CHANGELOG line; a Gotchas entry if users could hit it again | |
| Architecture rule change | `docs/design.md`; CLAUDE.md only if agents must follow it on every task | |

Skills (the `skills/` submodule) follow the same rule: they carry agent workflow and link to feature docs instead of copying command tables.

## Enforcement

`scripts/check-docs.py` in CI (`--strict` fails the build). It is kept small because it is code that also has to be maintained.

| Check | Limit |
|---|---|
| Line budgets | README ≤150, CLAUDE.md ≤100, `docs/features/*/README.md` ≤200 |
| CHANGELOG bullet length in `[Unreleased]` | ≤300 chars |
| `CHANGELOG.md` holds only `[Unreleased]` + one minor | fails once a second minor appears (rollover forgotten) |
| Every `docs/features/*/README.md` has a `description` | required |
| Relative links resolve (links inside code fences are skipped, since mockups use future paths) | all `.md` files |
| Generated files are current | `make docs && git diff --exit-code` |

When a doc goes over budget, split it. Don't raise the limit.

## Migration

Each step is its own PR, and the docs stay valid after each one.

1. **Hygiene**: fix the 7 broken links, rename `desgin.md` → `design.md`, split `CHANGELOG.md` into the current minor + `docs/changelog/`, add `scripts/check-docs.py` in report-only mode.
2. **Generation**: `make docs` builds `docs/commands.md` and `docs/README.md`.
3. **Tier 1**: slim README; add `CONTRIBUTING.md`, `docs/library.md`, `docs/release.md`.
4. **Move**: `git mv docs/features/<x>.md docs/features/<x>/README.md` for all 45 features, merging into the existing `iap-subscriptions/` and `iris/` folders. A script rewrites the links, and `scripts/check-docs.py` proves none broke. This is one mechanical PR with no content changes, so it's easy to review.
5. **Trim**: add `description`, delete flag tables and internals sections, move leftover design reasons into Gotchas. This can be parallelised per feature.
6. **CLAUDE.md**: move checklists into the `implement-feature` skill and replace the update-rules table.
7. **Enforce**: turn the CI checks from report-only into failing.

## Decisions

Each one is judged by the goal: *does the next change touch fewer places?*

| Question | Decision | Why |
|---|---|---|
| Internals sections (File Map, Domain Models, Testing, Extending) | **Delete** | They copy the code, so every refactor would need a doc edit that nobody makes |
| Flag tables in feature docs | **Delete; generate `docs/commands.md`** | Flags change with the code; generated means zero manual edits |
| Old CHANGELOG entries | **Keep the wording; new style going forward** | Rewriting history is work with no gain for future changes |
| One CHANGELOG file vs rolling archive | **Current minor in `CHANGELOG.md`, older minors in `docs/changelog/<minor>.md`** | Tier 1 must stay small for readers and agents. The rollover is one scripted move per minor, each version still lives in exactly one file, and CI catches a forgotten rollover. |
| Folder per feature vs flat file | **Folder per feature, `README.md` inside; no empty subfolders** | The rename happens once and is checked by CI. After that, every feature has one path and growing never moves a file. Mixing flat files with sibling folders would spread a feature over two places forever. |
| Frontmatter fields | **`description` only** | Every extra field has to be kept correct; the filename is already the name |
| Hand-written vs generated index | **Generated** | Adding a feature touches one file instead of two |

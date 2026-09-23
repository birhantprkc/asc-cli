# Web Console

Browser-based management dashboard for App Store Connect. Run `asc web` — no separate server, no dependencies. The web UI is bundled inside the `asc` binary and served by a built-in Hummingbird HTTP server that executes `asc` subcommands on your behalf.

## CLI Usage

### `asc web`

Start the web console and open the browser.

```
asc web [--port <port>] [--no-browser]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--port` | `8420` | Port to listen on |
| `--no-browser` | `false` | Don't auto-open the browser |

**Examples:**

```bash
asc web                        # start + open browser
asc web --port 9000            # custom port
asc web --no-browser           # headless (CI, remote SSH)
```

**Output:**
```
  ASC Web Console
  ────────────────────────────────
  Local:  http://127.0.0.1:8420
  ────────────────────────────────
  Press Ctrl+C to stop
```

---

## Typical Workflow

```bash
# 1. Make sure you're authenticated
asc auth check

# 2. Start the web console
asc web

# 3. In the browser:
#    - Select your app from the dropdown
#    - Click a version to expand → edit "What's New" inline → Save
#    - Click "Check Readiness" → fix issues
#    - Click "Submit for Review"
#    - Switch to Builds tab → see processing status
#    - Switch to another app from the dropdown → repeat
```

---

## Pages

### App Selector

Dropdown in the sidebar header. Loads all apps from your account on startup. Switching apps refreshes the current page with that app's data. Shows app name, bundle ID, and a checkmark on the selected app.

### Releases

Primary view. Versions grouped by lifecycle:

| Section | States |
|---------|--------|
| Active | Prepare, Waiting for Review, In Review, Pending Release, Processing |
| Live | Ready for Sale |
| Previous | Replaced, Removed, Rejected |

**Drill-down:** Click a version to expand its detail panel with three tabs:

- **Localizations** — Lists each locale (en-US, zh-Hans, etc.) with inline-editable fields:
  - What's New (textarea)
  - Description (textarea)
  - Keywords (text input)
  - Click "Edit" → modify → "Save" runs `asc version-localizations update --localization-id <id> --whats-new "..."`
- **Review Detail** — Inline-editable contact info and demo account settings. Runs `asc version-review-detail update` on save.
- **Actions** — All remaining CAEOAS affordances as buttons.

**State-aware buttons:** "Submit for Review" only appears when the version is editable. "Check Readiness" runs pre-flight validation.

### Builds

Table: version, build number, platform, processing state (color-coded badge), upload time (relative), affordance actions.

### TestFlight

Card grid of beta groups with tester counts, internal/external badges, and affordance links.

### Reviews

Customer reviews with star ratings, title, body, reviewer name, and response affordances.

### In-App Purchases

Table: name, product ID, type (consumable/non-consumable/non-renewing), state badge, actions.

### Subscriptions

Subscription groups with reference name, ID, and drill-down affordances.

### Code Signing

Summary cards (Bundle ID / Certificate / Profile counts) + detailed tables with name, type, platform, expiration.

### Xcode Cloud

CI products with bundle ID and workflow/build affordances.

### Team

Member table with avatar initials, name, username, role badges, and management actions.

---

## Architecture

```
Sources/ASCCommand/
├── Commands/Web/
│   ├── WebCommand.swift          CLI command: asc web [--port] [--no-browser]
│   └── WebServer.swift           Hummingbird server + StaticFileMiddleware
└── Resources/web/                Bundled frontend (served via Bundle.module)
    ├── index.html                Shell: sidebar, app selector, page mount
    └── js/
        ├── api.js                asc() wrapper — POST /api/run, parse JSON
        ├── state.js              App state (appId, apps[], platform, page) + navigation
        ├── components.js         Shared UI: badges, tables, toasts, editable fields, action handler
        └── pages/
            ├── releases.js       Version cards with drill-down detail + inline editing
            ├── builds.js         Build table with processing states
            ├── testflight.js     Beta group cards
            ├── reviews.js        Customer reviews with ratings
            ├── iap.js            In-app purchase table
            ├── subscriptions.js  Subscription group list
            ├── signing.js        Code signing resources (3 parallel fetches)
            ├── xcodecloud.js     Xcode Cloud products
            └── team.js           Team members table
```

### Three-Layer Diagram

```
┌─────────────────────────────────────────────────────┐
│  Browser (index.html + ES modules)                  │
│  ┌───────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ state.js  │  │ api.js   │  │ components.js    │ │
│  │ (routing) │  │ (fetch)  │  │ (UI + actions)   │ │
│  └───────────┘  └──────────┘  └──────────────────┘ │
│  ┌──────────────────────────────────────────────┐   │
│  │ pages/*.js  (one per domain: releases, etc.) │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────┘
                      │ POST /api/run
                      ▼
┌─────────────────────────────────────────────────────┐
│  WebServer.swift (Hummingbird)                      │
│  ┌──────────────────┐  ┌────────────────────────┐   │
│  │ StaticFileMiddle- │  │ handleRun()            │   │
│  │ ware (GET *)      │  │ → Process(asc args...) │   │
│  └──────────────────┘  └────────────────────────┘   │
└─────────────────────┬───────────────────────────────┘
                      │ subprocess
                      ▼
┌─────────────────────────────────────────────────────┐
│  asc CLI (same binary, re-invokes itself)           │
│  ASCCommand → Infrastructure → Domain               │
└─────────────────────────────────────────────────────┘
```

### Data Flow

1. User clicks "Submit for Review" button
2. `setupActionHandler` catches `.asc-action` click
3. Shows loading toast
4. `api.js` sends `POST /api/run {"command": "asc versions submit --version-id X"}`
5. `WebServer.handleRun()` spawns `Process` with same binary + args
6. Returns `{stdout, stderr, exit_code}`
7. On success: success toast + `renderPage()` re-fetches data
8. On error: error toast with message

### Inline Editing Flow

1. User hovers a field → "Edit" button appears
2. Click Edit → field becomes `<input>` or `<textarea>`
3. User modifies → clicks "Save"
4. `components.js` builds command: `asc version-localizations update --localization-id <id> --whats-new "new text"`
5. Executes via API → toast → page refresh shows updated value

### Security

- Only `asc` commands allowed (prefix check)
- Shell metacharacters blocked: `;|&$\`\\(){}[]!><`
- Direct `Process` execution (no shell)
- 1 MB request body limit
- `NO_COLOR=1` strips ANSI from output

---

## Domain Models (Frontend)

### `state.js` — Application State

```javascript
{
  page: 'releases',       // current page
  appId: '6743046579',    // selected app
  appName: 'BezelBlend',
  bundleId: 'com.onegai.bezelblend',
  platform: 'IOS',        // IOS | MAC_OS
  apps: [...]             // all apps from account
}
```

### `components.js` — Shared Vocabulary

| Component | Purpose |
|-----------|---------|
| `badge(state)` | Color-coded state badge matching `AppStoreVersionState` enum |
| `editableField(label, value, cmd, flag)` | Inline edit → save runs asc command |
| `affordanceButtons(affordances)` | Renders CAEOAS affordances as action buttons |
| `toast(message, type)` | Non-blocking notification (info/success/error/loading) |
| `setupActionHandler(refreshFn)` | Global click handler for `.asc-action`, `.edit-toggle`, `.save-field` |

### Page Modules

Each `pages/*.js` exports:
- `render()` — async, fetches data, returns HTML string
- `setupEvents(refreshFn)` — optional, registers page-specific event listeners (e.g. version expand/collapse)

---

## File Map

### Sources

```
Sources/ASCCommand/Commands/Web/WebCommand.swift       CLI entry point
Sources/ASCCommand/Commands/Web/WebServer.swift        Hummingbird server + middleware
Sources/ASCCommand/Resources/web/index.html            Frontend shell
Sources/ASCCommand/Resources/web/js/api.js             API layer
Sources/ASCCommand/Resources/web/js/state.js           State management
Sources/ASCCommand/Resources/web/js/components.js      Shared UI components
Sources/ASCCommand/Resources/web/js/pages/*.js         Page modules (9 files)
```

### Wiring

| File | Registers |
|------|-----------|
| `ASC.swift` | `WebCommand.self` in subcommands array |
| `Package.swift` | `.copy("Resources/web")` in ASCCommand resources |
| `Package.swift` | `.product(name: "Hummingbird", package: "hummingbird")` in dependencies |

---

## API Reference

| Endpoint | Method | Request | Response |
|----------|--------|---------|----------|
| `/` | GET | — | `index.html` |
| `/{path}` | GET | — | Static file from `Resources/web/` |
| `/api/run` | POST | `{"command": "asc apps list --output json"}` | `{"stdout": "...", "stderr": "...", "exit_code": 0}` |

---

## Extending

### Adding a new page

1. Create `Sources/ASCCommand/Resources/web/js/pages/mypage.js`:

```javascript
import { asc, toList } from '../api.js';
import { state } from '../state.js';
import { esc, table, empty } from '../components.js';

export async function render() {
  const data = toList(await asc(`my-resource list --app-id ${state.appId} --output json`));
  if (!data.length) return empty('Nothing found', 'Description.');
  // return HTML string
}
```

2. Add to `pages` map in `index.html`:

```javascript
const pages = {
  mypage: () => import('./js/pages/mypage.js'),
};
```

3. Add nav button to sidebar in `index.html`.

### Adding inline-editable fields

Use `editableField()` from `components.js`:

```javascript
editableField('What\'s New', localization.whatsNew,
  `asc version-localizations update --localization-id ${loc.id}`,
  '--whats-new',
  { multiline: true }
)
```

### Custom port

```bash
asc web --port 9000
```

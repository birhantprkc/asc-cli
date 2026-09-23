---
description: Design App Store screenshots (background, device bezel, text) in a browser editor, export a ZIP, and upload it in one command. Use when composing screenshots visually and importing them into a version.
---

# Screenshot Editor

A browser-based screenshot compositor. Design screenshots (background + device bezel + text layers) in a visual editor, export a ZIP, then upload it to App Store Connect with `asc screenshots import`. Every flag: [command reference](../../commands.md#asc-screenshots).

## Quick start

```bash
open homepage/editor/index.html          # design, then click Export ZIP
asc screenshots import --version-id <VERSION_ID> --from ./export.zip
```

## Workflows

### Design and upload screenshots

```bash
# 1. Find your app and version
asc apps list --output table
asc versions list --app-id <APP_ID> --output table

# 2. Design screenshots in the visual editor (no server required)
open homepage/editor/index.html
#    → compose screenshots for en-US, ja, zh-Hans
#    → click Export ZIP → saves export.zip

# 3. Upload to App Store Connect
asc screenshots import --version-id <VERSION_ID> --from ./export.zip --output table

# 4. Verify
asc screenshot-sets list --localization-id <LOC_ID> --output table
```

For each locale in the manifest, import finds or creates the localization and the screenshot set, then uploads each PNG in `order` sequence.

```
ID        File Name   Size     State
--------  ----------  -------  --------
img-001   1.png       2.8 MB   Complete
img-002   2.png       2.4 MB   Complete
```

### Using the editor

The editor has three panels: localizations and screenshot slots on the left, the canvas in the middle, the inspector (canvas size, device frame, screenshot image, background, text layers, Export ZIP) on the right.

- **Locale tabs**: each localization has independent screenshots and device settings.
- **Screenshot slots**: up to 10 per locale.
- **Canvas drag**: moves the bezel and screenshot together.
- **Text layers**: drag to reposition; edit content, size, color, weight and alignment in the inspector.
- **Zoom slider**: visual only; export always uses full output resolution.

### Export ZIP format

```
export.zip
├── manifest.json
├── en-US/
│   ├── 1.png
│   └── 2.png
└── ja/
    └── 1.png
```

```json
{
  "version": "1.0",
  "exportedAt": "2026-02-23T10:00:00Z",
  "localizations": {
    "en-US": {
      "displayType": "APP_IPHONE_67",
      "screenshots": [
        {
          "order": 1,
          "file": "en-US/1.png",
          "device": "iPhone 16 Pro - Natural Titanium - Portrait",
          "background": { "type": "gradient", "colors": ["#1a1a2e", "#0f3460"], "angle": 135 },
          "texts": [
            { "content": "Track Everything", "x": 50, "y": 15, "fontSize": 52,
              "fontWeight": "bold", "color": "#ffffff", "align": "center" }
          ]
        }
      ]
    }
  }
}
```

## Gotchas

- `asc screenshots import` reads only `displayType` and `file`; `device`, `background` and `texts` are editor metadata kept for re-editing.
- `file` paths are relative to the ZIP root.
- Import reuses the existing screenshot endpoints; nothing is exposed over REST for it.

## See also

[Design notes](design.md) (editor internals, device frames, JS modules) · [screenshots](../screenshots/README.md) · [app-shots](../app-shots/README.md)

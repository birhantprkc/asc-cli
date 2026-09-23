---
description: Browse plugin-provided visual themes and apply them to App Store screenshot templates, either per slide via AI or once-and-reuse via a cached ThemeDesign. Use when restyling app-shots with colors, backgrounds, and decorations.
---

# App Shots Themes

Visual theme presets (colors, backgrounds, floating decorations, text styling) applied on top of an [app-shots](../app-shots/README.md) template layout. Every flag: [command reference](../../commands.md#asc-app-shots).

Themes are plugin-provided: each plugin registers its own themes and its own AI backend. The CLI ships with no built-in themes, so `themes list` is empty until a theme plugin is installed.

## Quick start
```bash
asc app-shots themes list --output table
asc app-shots themes apply --theme space --template top-hero \
  --screenshot screen.png --headline "Ship Faster" > themed.html && open themed.html
```

## Workflows

### Browse and inspect
```bash
asc app-shots templates list
asc app-shots themes list
asc app-shots themes get --id space --pretty
asc app-shots themes get --id space --context   # print the AI prompt the theme produces
```

A theme in JSON:
```json
{
  "id": "space", "name": "Space",
  "description": "Cosmic backgrounds, twinkling stars, nebula colors",
  "accent": "#3b82f6",
  "aiHints": {
    "style": "cosmic and vast — deep space with luminous accents",
    "background": "deep navy-to-purple gradient suggesting a night sky or nebula",
    "floatingElements": ["twinkling stars (varying sizes)", "small planets", "comet trails"],
    "colorPalette": "deep navy, indigo, bright blue, soft purple, white star highlights",
    "textStyle": "clean, modern, light on dark — slight futuristic feel"
  },
  "affordances": {
    "detail": "asc app-shots themes get --id space",
    "listAll": "asc app-shots themes list",
    "apply": "asc app-shots themes apply --theme space --template <id> --screenshot screen.png --headline \"Your Text\""
  }
}
```

### Apply to one slide (AI restyle)
`themes apply` renders the template deterministically, then hands the HTML to the owning plugin's AI to restyle.
```bash
# Themed HTML (default)
asc app-shots themes apply --theme space --template top-hero \
  --screenshot .asc/app-shots/screen-0.png --headline "Ship Faster"

# Straight to PNG
asc app-shots themes apply --theme space --template top-hero \
  --screenshot .asc/app-shots/screen-0.png --headline "Ship Faster" \
  --preview image --image-output marketing-screen.png
```

### Design once, apply to many (one AI call)
```bash
asc app-shots themes design --id space > design.json

asc app-shots themes apply-design --design design.json --template top-hero \
  --screenshot screen-0.png --headline "Feature 1" --preview html > s0.html
asc app-shots themes apply-design --design design.json --template top-hero \
  --screenshot screen-1.png --headline "Feature 2" --preview html > s1.html
```

`design.json` uses the gallery-native palette and decoration types:
```json
{
  "palette": {
    "id": "space", "name": "Space",
    "background": "linear-gradient(135deg, #0f172a, #7c3aed)",
    "textColor": "#ffffff"
  },
  "decorations": [
    { "shape": {"label": "✨"}, "x": 0.85, "y": 0.12, "size": 0.04, "opacity": 0.6,
      "color": "#fff", "background": "rgba(255,255,255,0.1)",
      "borderRadius": "50%", "animation": "twinkle" }
  ]
}
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/app-shots/themes` | `asc app-shots themes list` |
| POST | `/api/v1/app-shots/themes/apply` | `asc app-shots themes apply` |
| POST | `/api/v1/app-shots/themes/design` | `asc app-shots themes design` |
| POST | `/api/v1/app-shots/themes/apply-design` | `asc app-shots themes apply-design` |

## Gotchas
- Layout is always deterministic; only styling comes from AI. The AI keeps text and device positions, and changes background, text colors, and adds 4-8 animated decorations.
- `themes apply` makes one AI call per slide. For a set of screenshots, use `themes design` once plus `themes apply-design` per slide (no AI calls).
- The plugin that owns a theme also owns its AI backend (Claude, Gemini, local, or plain CSS), so results vary by plugin.
- Decorations use normalized 0-1 positions and `cqi` sizing, so preview and PNG export stay proportional.
- `themes apply` defaults: `--headline "Your Headline"`, canvas 1320x2868, output `.asc/app-shots/output/screen-0.png` for `--preview image`.

## See also
[Adding themes from a plugin](authoring.md) · [App Shots](../app-shots/README.md) · [Plugins](../plugins/README.md)

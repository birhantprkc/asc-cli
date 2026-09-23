---
description: Compose App Store marketing screenshots from templates and gallery sets, preview as HTML or export PNG, and optionally enhance with Gemini. Use when turning raw app screenshots into styled store images.
---

# App Shots

Create App Store marketing screenshots. Every flag: [command reference](../../commands.md#asc-app-shots).

Two modes:

| | Gallery | Single template |
|---|---|---|
| What you do | Pick a gallery style; all shots are styled as a coordinated set (first shot = hero) | Pick a template and apply it to one screenshot |
| Output | Hero + feature screens matching an App Store gallery | One styled screenshot |
| AI enhance | Optional Gemini pass | Optional Gemini pass |

## Quick start
```bash
asc app-shots templates list --size portrait --output table
asc app-shots templates apply --id top-hero --screenshot screen-0.png \
  --headline "Ship Faster" --preview html > preview.html && open preview.html
```

## Workflows

### Single template: preview, then export
```bash
# Preview as HTML
asc app-shots templates apply --id top-hero --screenshot screen.png \
  --headline "Ship Faster" --preview html > composed.html && open composed.html

# Export to PNG (default path: .asc/app-shots/output/screen-0.png)
asc app-shots templates apply --id top-hero --screenshot screen.png \
  --headline "Ship Faster" --preview image --image-output marketing.png
```
`--subtitle` and `--tagline` add body and tagline text.

### Browse gallery styles
```bash
asc app-shots gallery-templates list --output table
asc app-shots gallery-templates get --id neon-pop --pretty
asc app-shots gallery-templates get --id neon-pop --preview > preview.html && open preview.html
```
Composing a whole gallery from your screenshots is done over REST (`POST /api/v1/app-shots/gallery/compose`, see below).

### Theme once, apply to many
Generate a theme design (palette + decorations) with one AI call, then apply it to every slide without further AI calls.
```bash
asc app-shots themes design --id luxury > design.json
asc app-shots themes apply-design --design design.json \
  --template top-hero --screenshot screen.png --headline "Ship Faster" \
  --preview html > themed.html
```
Themes are covered in [App Shots Themes](../app-shots-themes/README.md).

### Enhance with Gemini
```bash
asc app-shots config --gemini-api-key AIzaSy...   # save key
asc app-shots config                              # show
asc app-shots config --remove                     # delete

asc app-shots generate --file screen.png
asc app-shots generate --file screen.png --device-type APP_IPHONE_67
```
`--style-reference` passes a reference image for style transfer; `--prompt` overrides the Gemini prompt.

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/app-shots/templates` | `asc app-shots templates list` |
| GET | `/api/v1/app-shots/gallery-templates` | `asc app-shots gallery-templates list` |
| POST | `/api/v1/app-shots/gallery/compose` | (REST only) body: `templateId`, `screenshots` (base64 array) |
| POST | `/api/v1/app-shots/templates/apply` | `asc app-shots templates apply` |
| POST | `/api/v1/app-shots/export` | `asc app-shots export` (body: `html`, optional `width`/`height`, default 1320x2868) |
| POST | `/api/v1/app-shots/generate` | `asc app-shots generate` (body: `screenshot` base64) |

Theme routes are listed in [App Shots Themes](../app-shots-themes/README.md#rest).

## Gotchas
- The Gemini key is stored in `~/.asc/app-shots-config.json`; `--gemini-api-key` on `generate` overrides it, otherwise it falls back to env/config.
- `--device-type` on `generate` resizes output to App Store dimensions; without it the output keeps the source size.
- Sizing uses CSS `cqi` units, so the HTML preview (320px container) and the PNG export (full viewport) keep the same proportions.
- In a gallery the first screenshot becomes the hero; shots without a headline are not rendered.

## See also
[App Shots Themes](../app-shots-themes/README.md) · [Screenshots](../screenshots/README.md)

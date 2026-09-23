---
description: Run App Store Product Page Optimization tests with up to three alternate product pages (treatments). Use when A/B testing an app icon or per-locale product page against the original.
---

# Product Page Optimization (Experiments)

Run up to three alternate product pages (treatments) against the original and let the App Store split traffic between them. Apple calls these `appStoreVersionExperiments` (v2); the CLI uses `experiments`. Every flag: [command reference](../../commands.md#asc-experiments), plus [experiment-treatments](../../commands.md#asc-experiment-treatments) and [experiment-treatment-localizations](../../commands.md#asc-experiment-treatment-localizations).

Hierarchy: `App → Experiment → Treatment → Treatment localization`.

## Quick start

```bash
asc experiments list --app-id 6792459661 --state APPROVED --output table
asc experiments create --app-id 6792459661 --name "Icon test" --platform ios --traffic-proportion 30
asc experiment-treatments create --experiment-id exp-1 --name "Blue icon" --app-icon-name AppIcon-Blue
asc experiments start --experiment-id exp-1
```

## Workflows

### Run an icon test end to end

```bash
APP_ID=6792459661

# 1. Create the test (app must be live / pre-order ready)
EXP=$(asc experiments create --app-id $APP_ID --name "Icon test" --traffic-proportion 30 \
      | jq -r '.data[0].id')

# 2. Add up to three treatments
TRT=$(asc experiment-treatments create --experiment-id $EXP --name "Blue icon" --app-icon-name AppIcon-Blue \
      | jq -r '.data[0].id')

# 3. Choose the locales included in the treatment
asc experiment-treatment-localizations create --treatment-id $TRT --locale en-US
asc experiment-treatment-localizations create --treatment-id $TRT --locale de-DE

# 4. Submit for review (via review-submissions) and wait for state ACCEPTED/APPROVED
asc experiments get --experiment-id $EXP | jq '.data[0] | {state, canStart}'

# 5. Start serving traffic, then stop when you have a winner (tests auto-complete after 90 days)
asc experiments start --experiment-id $EXP
asc experiments stop  --experiment-id $EXP
```

### Reading an experiment

An editable test (`--pretty`, trimmed):

```json
{
  "affordances" : {
    "createTreatment" : "asc experiment-treatments create --experiment-id exp-1 --name <name>",
    "delete" : "asc experiments delete --experiment-id exp-1",
    "listSiblings" : "asc experiments list --app-id app-1",
    "listTreatments" : "asc experiment-treatments list --experiment-id exp-1",
    "update" : "asc experiments update --experiment-id exp-1"
  },
  "appId" : "app-1",
  "canStart" : false,
  "id" : "exp-1",
  "isRunning" : false,
  "state" : "PREPARE_FOR_SUBMISSION",
  "trafficProportion" : 30
}
```

Affordances follow the state:

| Affordance | Appears when |
|---|---|
| `listSiblings`, `listTreatments` | always |
| `update`, `delete`, `createTreatment` | editable: `PREPARE_FOR_SUBMISSION`, `READY_FOR_REVIEW`, `REJECTED` |
| `start` | `canStart`: approved (`ACCEPTED` / `APPROVED`) and not started yet |
| `stop` | `isRunning`: approved, started, not ended |

`WAITING_FOR_REVIEW` / `IN_REVIEW` are pending review; `COMPLETED` / `STOPPED` are finished. `startDate`, `endDate` and `latestControlVersionId` are omitted when nil.

## REST

| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/apps/:appId/experiments` | `experiments list` |
| POST | `/api/v1/apps/:appId/experiments` | `experiments create` |
| GET | `/api/v1/experiments/:experimentId` | `experiments get` |
| PATCH | `/api/v1/experiments/:experimentId` | `experiments update` |
| POST | `/api/v1/experiments/:experimentId/start` | `experiments start` |
| POST | `/api/v1/experiments/:experimentId/stop` | `experiments stop` |
| DELETE | `/api/v1/experiments/:experimentId` | `experiments delete` |
| GET | `/api/v1/experiments/:experimentId/experiment-treatments` | `experiment-treatments list` |
| POST | `/api/v1/experiments/:experimentId/experiment-treatments` | `experiment-treatments create` |
| PATCH | `/api/v1/experiment-treatments/:treatmentId` | `experiment-treatments update` |
| DELETE | `/api/v1/experiment-treatments/:treatmentId` | `experiment-treatments delete` |
| GET | `/api/v1/experiment-treatments/:treatmentId/experiment-treatment-localizations` | `experiment-treatment-localizations list` |
| POST | `/api/v1/experiment-treatments/:treatmentId/experiment-treatment-localizations` | `experiment-treatment-localizations create` |
| DELETE | `/api/v1/experiment-treatment-localizations/:localizationId` | `experiment-treatment-localizations delete` |

Query params: `--state` → `?state=`, `--limit` → `?limit=`. Bodies use camelCase: `{ "name", "trafficProportion", "platform"? }`, `{ "name", "appIconName"? }`, `{ "locale" }`.

Discovery: `GET /api/v1/apps` items carry `_links.listExperiments`; each experiment's `_links` follow the same state rules as the CLI affordances.

```bash
curl "http://127.0.0.1:8420/api/v1/apps/6792459661/experiments?state=APPROVED&limit=5"
curl -X POST -H 'Content-Type: application/json' \
  -d '{"name":"Icon test","platform":"ios","trafficProportion":30}' \
  http://127.0.0.1:8420/api/v1/apps/6792459661/experiments
curl -X POST http://127.0.0.1:8420/api/v1/experiments/exp-1/start
```

## Gotchas

- A test is app-scoped (not tied to a version) and can only be created when the app is **Ready for Distribution** or **Pre-Order Ready for Distribution**.
- `--traffic-proportion` must be 1–100; it is validated before any request is sent.
- `experiments update` and `experiment-treatments update` need at least one field to change.
- `start` / `stop` only appear once the test is approved; review goes through review-submissions.
- Tests auto-complete after 90 days.
- Attaching screenshot / preview sets to a treatment localization is not supported yet.

## See also

- [Review submissions](../review-submissions/README.md)
- [Screenshots](../screenshots/README.md)

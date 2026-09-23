---
description: Read power and performance metrics (launch time, hangs, memory, disk, battery) and drill into diagnostic signatures and call stacks. Use when checking an app or build for performance regressions.
---

# Power & Performance Metrics

Download power and performance metrics and diagnostic logs for an app or a build. Every flag: [perf-metrics](../../commands.md#asc-perf-metrics), [diagnostics](../../commands.md#asc-diagnostics), [diagnostic-logs](../../commands.md#asc-diagnostic-logs).

Drill-down: `perf-metrics` (app or build) → `diagnostics` (signatures for a build) → `diagnostic-logs` (call stacks for a signature).

## Quick start

```bash
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty
asc diagnostics list --build-id build-abc --diagnostic-type HANGS --pretty
asc diagnostic-logs list --signature-id sig-1 --pretty
```

## Workflows

### Investigate a slow or hanging build

```bash
# 1. App-level metrics (aggregated across versions), optionally one type
asc perf-metrics list --app-id 123456789 --pretty
asc perf-metrics list --app-id 123456789 --metric-type HANG --pretty

# 2. A specific build's metrics
asc builds list --app-id 123456789
asc perf-metrics list --build-id build-abc --metric-type LAUNCH

# 3. Diagnostic signatures for that build (recurring issues ranked by weight)
asc diagnostics list --build-id build-abc --pretty

# 4. Call stacks for one signature
asc diagnostic-logs list --signature-id sig-1 --pretty
```

Metric types: `HANG`, `LAUNCH`, `MEMORY`, `DISK`, `BATTERY`, `TERMINATION`, `ANIMATION`, `STORAGE`. Diagnostic types: `DISK_WRITES`, `HANGS`, `LAUNCHES`.

### Reading the output

A metric compares the latest value against Apple's goal:

```json
{
  "id": "123456789-LAUNCH-launchTime",
  "parentId": "123456789",
  "parentType": "app",
  "category": "LAUNCH",
  "metricIdentifier": "launchTime",
  "unit": "s",
  "latestValue": 1.5,
  "latestVersion": "2.0",
  "goalValue": 1.0,
  "affordances": { "listAppMetrics": "asc perf-metrics list --app-id 123456789" }
}
```

App metrics carry `listAppMetrics`; build metrics carry `listBuildMetrics`.

A signature's `weight` is its share of occurrences (0–100); `insightDirection` is `UP`, `DOWN` or `UNDEFINED`:

```json
{
  "id": "sig-1",
  "buildId": "build-abc",
  "diagnosticType": "HANGS",
  "signature": "main thread hang in -[UIView layoutSubviews]",
  "weight": 45.2,
  "insightDirection": "UP",
  "affordances": {
    "listLogs": "asc diagnostic-logs list --signature-id sig-1",
    "listSignatures": "asc diagnostics list --build-id build-abc"
  }
}
```

Each log entry has device, OS and app version, and a `callStackSummary` of the top 5 frames joined with ` > ` (e.g. `main > UIKit > layoutSubviews`).

## Gotchas

- `perf-metrics list` takes exactly one of `--app-id` or `--build-id`.
- Diagnostics are per build only; there is no app-level `diagnostics list`.
- Metric and log IDs are synthetic (`{parentId}-{category}-{metric}`, `{signatureId}-{product}-{log}`); they are stable for display but are not Apple IDs.
- No REST endpoints yet; these commands are CLI-only.

## See also

- [Builds upload](../builds-upload/README.md)

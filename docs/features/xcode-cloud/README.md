---
description: List Xcode Cloud products, workflows and build runs, and start CI builds. Use when triggering or checking an Xcode Cloud build from the terminal or an agent.
---

# Xcode Cloud

Read Xcode Cloud products, workflows and build runs, and start builds through the App Store Connect API. Every flag: [command reference](../../commands.md#asc-xcode-cloud).

## Quick start

```bash
asc xcode-cloud products list --app-id 1234567890 --pretty
asc xcode-cloud workflows list --product-id abc123 --pretty
asc xcode-cloud builds start --workflow-id wf-1 --pretty
```

## Workflows

### Start a build and follow it

```bash
# 1. Find the Xcode Cloud product for your app
asc xcode-cloud products list --app-id $(cat .asc/project.json | jq -r '.appId')

# 2. List workflows for the product
asc xcode-cloud workflows list --product-id <product-id>

# 3. Start a build (add --clean to remove derived data first)
asc xcode-cloud builds start --workflow-id <workflow-id>

# 4. Check the build status
asc xcode-cloud builds get --build-run-id <build-run-id>

# 5. List recent builds for a workflow
asc xcode-cloud builds list --workflow-id <workflow-id>
```

A workflow offers `startBuild` only when it is enabled:

```json
{
  "id": "wf-1",
  "productId": "abc123",
  "name": "CI Build",
  "isEnabled": true,
  "isLockedForEditing": false,
  "affordances": {
    "listBuildRuns": "asc xcode-cloud builds list --workflow-id wf-1",
    "listWorkflows": "asc xcode-cloud workflows list --product-id abc123",
    "startBuild": "asc xcode-cloud builds start --workflow-id wf-1"
  }
}
```

A build run reports progress and result separately:

```json
{
  "id": "run-42",
  "workflowId": "wf-1",
  "number": 42,
  "executionProgress": "COMPLETE",
  "completionStatus": "SUCCEEDED",
  "startReason": "MANUAL",
  "affordances": {
    "getBuildRun": "asc xcode-cloud builds get --build-run-id run-42",
    "listBuildRuns": "asc xcode-cloud builds list --workflow-id wf-1"
  }
}
```

## REST

Xcode Cloud is CLI-only; `asc web-server` has no Xcode Cloud routes yet.

## Gotchas

- There is one Xcode Cloud product per app enrolled in Xcode Cloud; `productType` is `APP` or `FRAMEWORK`.
- `startBuild` is hidden when a workflow's `isEnabled` is `false`.
- `executionProgress` is `PENDING`, `RUNNING` or `COMPLETE`. `completionStatus` is absent while the build is still running, then one of `SUCCEEDED`, `FAILED`, `ERRORED`, `CANCELED`, `SKIPPED`.
- `startReason` is one of `GIT_REF_CHANGE`, `MANUAL`, `MANUAL_REBUILD`, `PULL_REQUEST_OPEN`, `PULL_REQUEST_UPDATE`, `SCHEDULE`.
- Workflows are read-only here: you can't create, edit, enable or disable them, and you can't cancel a running build.

## See also

[builds-archive](../builds-archive/README.md) · [builds-upload](../builds-upload/README.md) · [testflight](../testflight/README.md)

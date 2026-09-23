---
description: List, boot, and shut down local iOS simulators from the CLI. Use when you need a running simulator for testing, screenshots, or streaming via the ASC Pro plugin.
---

# Simulators

Manage local iOS simulators: list, boot, and shut down. Streaming and interaction are provided by the [ASC Pro plugin](../plugins/README.md). Every flag: [command reference](../../commands.md#asc-simulators).

## Quick start
```bash
asc simulators list --output table
asc simulators boot --udid SIM-UDID-1
asc simulators shutdown --udid SIM-UDID-1
```

## Workflows

### Find a booted simulator
```bash
asc simulators list --booted --pretty
```

```json
{
  "data" : [
    {
      "id" : "SIM-UDID-1",
      "name" : "iPhone 16 Pro Max",
      "state" : "Booted",
      "runtime" : "com.apple.CoreSimulator.SimRuntime.iOS-18-2",
      "displayRuntime" : "iOS 18.2",
      "isBooted" : true,
      "affordances" : {
        "shutdown" : "asc simulators shutdown --udid SIM-UDID-1",
        "stream" : "asc simulators stream --udid SIM-UDID-1",
        "listSimulators" : "asc simulators list"
      }
    }
  ]
}
```

## REST
| Method | Path | CLI equivalent |
|---|---|---|
| GET | `/api/v1/simulators` | `asc simulators list --booted` |

## Gotchas
- Requires Xcode: everything goes through `xcrun simctl`.
- Affordances follow state: a shut-down simulator offers `boot`; a booted one offers `shutdown`; both offer `listSimulators`.
- The `stream` affordance (and the `asc simulators stream` command) only appears when the ASC Pro plugin is installed.
- The REST endpoint returns booted simulators only.
- `state` can also be `Shutting Down` or `Creating`; only `Booted` and `Shutdown` simulators are usable.

## See also
[Plugins](../plugins/README.md)

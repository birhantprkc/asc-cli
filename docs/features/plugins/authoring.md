# Writing a plugin

Plugins are compiled `.plugin` bundles (dylibs) that extend the CLI with server routes, UI components, CLI commands, and domain affordances. They are discovered from `~/.asc/plugins/` at startup.

## Bundle structure

```
~/.asc/plugins/ASCPro.plugin/
├── manifest.json              # metadata: name, version, server dylib, UI scripts
├── ASCPro.dylib               # compiled dynamic library
└── ui/
    └── sim-stream.js          # web UI scripts (loaded by command-center)
```

### manifest.json

```json
{
  "name": "ASC Pro",
  "version": "1.0",
  "server": "ASCPro.dylib",
  "ui": ["ui/sim-stream.js"]
}
```

## Plugin protocol

Plugins export a C entry point and conform to `ASCPluginBase`:

```swift
@_cdecl("ascPlugin")
public func ascPlugin() -> UnsafeMutableRawPointer {
    Unmanaged.passRetained(MyPlugin()).toOpaque()
}

public final class MyPlugin: NSObject, ASCPluginBase {
    public let name = "My Plugin"
    public var commands: [Any] { [] }

    public func configureRoutes(_ router: Any) {
        // Register HTTP/WebSocket routes
    }
}
```

## AffordanceRegistry

Plugins extend domain model affordances at runtime using structured `Affordance` values that render to both CLI commands and REST `_links`:

```swift
AffordanceRegistry.register(Simulator.self) { id, props in
    guard props["isBooted"] == "true" else { return [] }
    return [Affordance(key: "stream", command: "simulators", action: "stream", params: ["udid": id])]
}
```

This produces:
- **CLI**: `"stream": "asc simulators stream --udid <id>"`
- **REST**: `"stream": {"href": "/api/v1/simulators/<id>/stream", "method": "POST"}`

## How plugins are loaded

```
PluginLoader.discover()
  → scans ~/.asc/plugins/ for .plugin, .framework, .dylib
  → loads via dlopen/dlsym("ascPlugin")
  → returns [LoadedPlugin] with name, slug, uiScripts

ASCWebServer.buildRouter()
  → calls plugin.configureRoutes(routerPtr)
  → serves plugin UI scripts at /api/plugins/{slug}/ui/*
  → GET /api/plugins returns manifest list for web app
```

See also: [Plugins](README.md) · [Adding app-shots themes from a plugin](../app-shots-themes/authoring.md)

# Builds Archive & Export

Archive and export Xcode projects directly from the CLI, with optional upload to App Store Connect.

## CLI Usage

### `asc builds archive`

Archive an Xcode project, export an IPA/PKG, and optionally upload to App Store Connect.

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--scheme` | Yes | — | Xcode scheme to archive |
| `--workspace` | No | auto-detected | Path to `.xcworkspace` |
| `--project` | No | auto-detected | Path to `.xcodeproj` |
| `--platform` | No | `ios` | `ios`, `macos`, `tvos`, `visionos` |
| `--configuration` | No | `Release` | Build configuration |
| `--export-method` | No | `app-store` | `app-store`, `ad-hoc`, `development`, `enterprise` |
| `--output-dir` | No | `.build` | Output directory for archive and export |
| `--upload` | No | `false` | Chain into App Store Connect upload |
| `--app-id` | If `--upload` | — | App ID for upload |
| `--version` | If `--upload` | — | Version string (e.g. `1.0.0`) |
| `--build-number` | If `--upload` | — | Build number (e.g. `42`) |

#### Examples

```bash
# Basic archive + export (produces IPA in .build/export/)
asc builds archive --scheme MyApp

# Archive for macOS
asc builds archive --scheme MyMacApp --platform macos

# Archive with specific workspace
asc builds archive --scheme MyApp --workspace MyApp.xcworkspace

# Archive, export, and upload to App Store Connect
asc builds archive --scheme MyApp --upload --app-id 123456 --version 1.0.0 --build-number 42

# Ad-hoc distribution
asc builds archive --scheme MyApp --export-method ad-hoc --output-dir dist/
```

#### JSON Output (archive only)

```json
{
  "data": [
    {
      "ipaPath": ".build/export/MyApp.ipa",
      "exportPath": ".build/export",
      "affordances": {
        "upload": "asc builds upload --file .build/export/MyApp.ipa"
      }
    }
  ]
}
```

#### JSON Output (with --upload)

```json
{
  "data": [
    {
      "id": "up-1",
      "appId": "123456",
      "version": "1.0.0",
      "buildNumber": "42",
      "platform": "IOS",
      "state": "COMPLETE",
      "affordances": {
        "checkStatus": "asc builds uploads get --upload-id up-1",
        "listBuilds": "asc builds list --app-id 123456"
      }
    }
  ]
}
```

## Typical Workflow

```bash
# 1. Initialize project context
asc init

# 2. Archive, export, and upload in one command
asc builds archive --scheme MyApp --upload --app-id 123456 --version 1.2.0 --build-number 55

# 3. Add to TestFlight beta group
asc builds add-beta-group --build-id <build-id> --beta-group-id <group-id>

# 4. Update TestFlight notes
asc builds update-beta-notes --build-id <build-id> --locale en-US --notes "New features and bug fixes"
```

## Architecture

```
┌─────────────────────────────────────────────┐
│ ASCCommand                                   │
│  BuildsArchive                               │
│  ├── parse CLI flags                         │
│  ├── auto-detect workspace/project           │
│  ├── call runner.archive()                   │
│  ├── call runner.exportArchive()             │
│  └── optionally call uploadRepo.uploadBuild()│
└──────────────────┬──────────────────────────┘
                   │ depends on
┌──────────────────▼──────────────────────────┐
│ Infrastructure                               │
│  ProcessXcodeBuildRunner                     │
│  ├── archive(): Process → xcodebuild archive │
│  └── exportArchive(): Process → xcodebuild   │
│      -exportArchive + auto-generated plist   │
└──────────────────┬──────────────────────────┘
                   │ implements
┌──────────────────▼──────────────────────────┐
│ Domain                                       │
│  XcodeBuildRunner (@Mockable protocol)       │
│  ArchiveRequest, ArchiveResult               │
│  ExportRequest, ExportResult, ExportMethod   │
└─────────────────────────────────────────────┘
```

## Domain Models

### `ArchiveRequest`
| Field | Type | Description |
|-------|------|-------------|
| `scheme` | `String` | Xcode scheme name |
| `workspace` | `String?` | Path to `.xcworkspace` |
| `project` | `String?` | Path to `.xcodeproj` |
| `platform` | `BuildUploadPlatform` | Target platform |
| `configuration` | `String` | Build configuration (default: `Release`) |
| `archivePath` | `String` | Output path for `.xcarchive` |

### `ArchiveResult` (AffordanceProviding)
| Field | Type | Description |
|-------|------|-------------|
| `archivePath` | `String` | Path to created `.xcarchive` |
| `scheme` | `String` | Scheme that was archived |
| `platform` | `BuildUploadPlatform` | Platform |

Affordances: `exportArchive`

### `ExportRequest`
| Field | Type | Description |
|-------|------|-------------|
| `archivePath` | `String` | Path to `.xcarchive` to export |
| `exportPath` | `String` | Output directory for IPA/PKG |
| `method` | `ExportMethod` | Export method |

### `ExportResult` (AffordanceProviding)
| Field | Type | Description |
|-------|------|-------------|
| `ipaPath` | `String` | Path to exported `.ipa` or `.pkg` |
| `exportPath` | `String` | Export directory |

Affordances: `upload`

### `ExportMethod`
`appStore` (`app-store`), `adHoc` (`ad-hoc`), `development`, `enterprise`

### `XcodeBuildRunner` (@Mockable protocol)
- `archive(request:) -> ArchiveResult`
- `exportArchive(request:) -> ExportResult`

### `XcodeBuildError`
- `archiveFailed(exitCode:stderr:)` — xcodebuild archive exited non-zero
- `exportFailed(exitCode:stderr:)` — xcodebuild -exportArchive exited non-zero
- `noExportedBinary(exportPath:)` — no `.ipa` or `.pkg` found after export

## File Map

### Sources

```
Sources/
├── Domain/Apps/Builds/XcodeBuild/
│   └── XcodeBuildRunner.swift         # Protocol + request/result models
├── Infrastructure/Apps/Builds/XcodeBuild/
│   └── ProcessXcodeBuildRunner.swift   # Process-based implementation
└── ASCCommand/Commands/Builds/
    ├── BuildsArchive.swift             # CLI command
    └── BuildsCommand.swift             # Parent (registers archive)
```

### Tests

```
Tests/
├── DomainTests/Apps/Builds/XcodeBuild/
│   └── ArchiveExportTests.swift        # Model + affordance tests
├── InfrastructureTests/Apps/Builds/XcodeBuild/
│   └── ProcessXcodeBuildRunnerTests.swift  # Shell script integration tests
└── ASCCommandTests/Commands/Builds/
    └── BuildsArchiveTests.swift        # Command output tests
```

## Testing

```bash
# Run all archive-related tests
swift test --filter 'ArchiveExport|ProcessXcodeBuildRunner|BuildsArchive'
```

```swift
@Test func `archive shows result with export affordance`() async throws {
    let mockRunner = MockXcodeBuildRunner()
    given(mockRunner).archive(request: .any)
        .willReturn(ArchiveResult(archivePath: "/tmp/MyApp.xcarchive", scheme: "MyApp", platform: .iOS))
    given(mockRunner).exportArchive(request: .any)
        .willReturn(ExportResult(ipaPath: "/tmp/export/MyApp.ipa", exportPath: "/tmp/export"))

    let cmd = try BuildsArchive.parse(["--scheme", "MyApp", "--pretty"])
    let output = try await cmd.execute(runner: mockRunner)

    #expect(output.contains("MyApp.ipa"))
    #expect(output.contains("upload"))
}
```

## Extending

Natural next steps:
- **Version/build number injection**: Override `CFBundleShortVersionString` and `CFBundleVersion` before archiving via `agvtool` or build settings
- **Code signing override**: Add `--team-id` and `--signing-identity` flags to the export options plist
- **Archive-only mode**: `--skip-export` flag to produce `.xcarchive` without exporting
- **Clean build**: `--clean` flag to run `xcodebuild clean` before archiving

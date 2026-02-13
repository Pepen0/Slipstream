# Desktop Installers (Gold Master)

This document describes the end-user installer flow for Windows and macOS.

## Artifacts

- Windows: `Slipstream-Setup-<version>.exe`
- macOS: `Slipstream-<version>.dmg` (contains `Slipstream-<version>.pkg`)

## What gets bundled

From Flutter desktop release outputs:
- app executable/bundle
- Flutter runtime libraries
- plugin/native dependencies

Optional:
- `dashboard_server` service binary (if supplied to packaging script)
- Windows USB driver INF (`slipstream.inf`) if supplied

## Auto-start service behavior

- Windows installer task (`Auto-start local dashboard service at user logon`):
  - writes `SlipstreamDashboardService` value under
    `HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run`
  - prefers `services\\dashboard_server.exe` when present
- macOS installer:
  - installs `/Library/LaunchAgents/com.slipstream.dashboard.plist`
  - runs `/Library/Application Support/Slipstream/scripts/launch_dashboard_service.sh`
  - launch agent is bootstrapped during install when a console user is available

## Uninstall

- Windows:
  - use Add/Remove Programs entry for Slipstream
  - uninstaller removes startup entry and attempts driver cleanup
- macOS:
  - run `/Applications/Slipstream Uninstall.command`
  - removes app bundle, launch agent, and support files

## Manual local build

### Windows

```powershell
pwsh ./scripts/package/build_windows_installer.ps1 `
  -Version 1.0.0 `
  -AppBuildDir Software-code/App/build/windows/x64/runner/Release
```

Optional args:
- `-DashboardServerBin <path to dashboard_server.exe>`
- `-DriverInf <path to slipstream.inf>`
- `-SkipIscc` for staging-only test

### macOS

```bash
./scripts/package/build_macos_installer.sh \
  --version 1.0.0 \
  --app-build-dir Software-code/App/build/macos/Build/Products/Release/client.app
```

Optional arg:
- `--dashboard-server-bin <path to dashboard_server>`
- `--skip-dmg` to emit `.pkg` only

Dry-run staging test:

```bash
./scripts/package/build_macos_installer.sh --dry-run
```

# Desktop Installers (Gold Master)

This document describes the end-user installer flow for Windows and macOS.

## Artifacts

- Windows: `Slipstream-Setup-<version>.exe`
- macOS: `Slipstream-<version>.dmg` (contains `Slipstream-<version>.pkg`)

## CI release toggles (placeholders)

In `.github/workflows/desktop-packaging.yml`, use `workflow_dispatch` inputs:

- `sign_windows`
- `sign_macos`
- `notarize_macos`

These are intentionally opt-in placeholders so normal CI remains fast and secret-free.

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

Optional signing helper:

```powershell
pwsh ./scripts/package/sign_windows_installer.ps1 `
  -InstallerPath dist/windows/installer/Slipstream-Setup-1.0.0.exe `
  -CertBase64 $env:WINDOWS_SIGN_CERT_BASE64 `
  -CertPassword $env:WINDOWS_SIGN_CERT_PASSWORD
```

### macOS

```bash
./scripts/package/build_macos_installer.sh \
  --version 1.0.0 \
  --app-build-dir Software-code/App/build/macos/Build/Products/Release/client.app
```

Optional arg:
- `--dashboard-server-bin <path to dashboard_server>`
- `--skip-dmg` to emit `.pkg` only
- `--codesign-identity <identity>`
- `--installer-sign-identity <identity>`
- `--notarize --apple-id <id> --apple-team-id <team> --apple-app-password <password>`

Dry-run staging test:

```bash
./scripts/package/build_macos_installer.sh --dry-run
```

## Required secrets for placeholders

Windows signing:
- `WINDOWS_SIGN_CERT_BASE64`
- `WINDOWS_SIGN_CERT_PASSWORD`

Apple signing/notarization:
- `APPLE_SIGN_CERT_BASE64`
- `APPLE_SIGN_CERT_PASSWORD`
- `APPLE_SIGN_IDENTITY`
- optional `APPLE_INSTALLER_SIGN_IDENTITY`
- `APPLE_NOTARY_APPLE_ID`
- `APPLE_NOTARY_TEAM_ID`
- `APPLE_NOTARY_APP_PASSWORD`

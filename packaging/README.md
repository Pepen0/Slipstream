# Desktop Installation & Packaging

This folder contains the Gold Master installer pipeline for end users.

## Targets

- **Windows installer**: one-click `.exe` built with Inno Setup.
- **macOS installer**: `.pkg` wrapped inside a `.dmg`.

## Features covered

- Bundle app runtime dependencies from Flutter desktop release builds.
- Optional bundling of `dashboard_server` service binary.
- Auto-start service configuration:
  - Windows: startup registry entry (`HKCU\\...\\Run`).
  - macOS: launch agent (`/Library/LaunchAgents/com.slipstream.dashboard.plist`).
- Uninstall support:
  - Windows: Inno Setup uninstaller + cleanup scripts.
  - macOS: `/Applications/Slipstream Uninstall.command`.
- Optional Windows driver install/uninstall hooks via `pnputil`.

## Local build entrypoints

- Windows: `scripts/package/build_windows_installer.ps1`
- macOS: `scripts/package/build_macos_installer.sh`

## CI

GitHub Actions workflow: `.github/workflows/desktop-packaging.yml`

### Signing and notarization placeholders

The workflow supports opt-in signing/notarization via `workflow_dispatch` inputs:

- `sign_windows`
- `sign_macos`
- `notarize_macos`

Expected secrets/vars:

- Windows signing
  - `WINDOWS_SIGN_CERT_BASE64`
  - `WINDOWS_SIGN_CERT_PASSWORD`
  - optional repository variable `WINDOWS_SIGN_TIMESTAMP_URL`
- Apple signing/notarization
  - `APPLE_SIGN_CERT_BASE64`
  - `APPLE_SIGN_CERT_PASSWORD`
  - `APPLE_SIGN_IDENTITY`
  - optional `APPLE_INSTALLER_SIGN_IDENTITY`
  - `APPLE_NOTARY_APPLE_ID`
  - `APPLE_NOTARY_TEAM_ID`
  - `APPLE_NOTARY_APP_PASSWORD`

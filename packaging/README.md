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

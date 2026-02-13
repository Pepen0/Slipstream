# macOS Installer Assets

- `launch_dashboard_service.sh`: launchd entrypoint for the local dashboard service.
- `pkg_scripts/preinstall`: unloads prior launch agent before upgrade.
- `pkg_scripts/postinstall`: bootstraps/reloads launch agent after install.
- `uninstall_slipstream.command`: removes app, launch agent, and support files.

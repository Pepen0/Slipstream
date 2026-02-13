#!/usr/bin/env bash
set -euo pipefail

PLIST_PATH="/Library/LaunchAgents/com.slipstream.dashboard.plist"
SUPPORT_DIR="/Library/Application Support/Slipstream"
APP_PATH="/Applications/Slipstream.app"
SELF_PATH="/Applications/Slipstream Uninstall.command"

echo "Slipstream uninstall started."

CONSOLE_USER="$(stat -f%Su /dev/console || true)"
if [[ -n "$CONSOLE_USER" && "$CONSOLE_USER" != "root" ]]; then
  uid="$(id -u "$CONSOLE_USER" 2>/dev/null || true)"
  if [[ -n "$uid" ]]; then
    launchctl bootout "gui/${uid}" "$PLIST_PATH" >/dev/null 2>&1 || true
  fi
fi

if [[ -f "$PLIST_PATH" ]]; then
  sudo rm -f "$PLIST_PATH"
fi
if [[ -d "$SUPPORT_DIR" ]]; then
  sudo rm -rf "$SUPPORT_DIR"
fi
if [[ -d "$APP_PATH" ]]; then
  sudo rm -rf "$APP_PATH"
fi

echo "Slipstream was removed from this Mac."
echo "You can now close this Terminal window."

# Remove this uninstall script after successful uninstall.
if [[ -f "$SELF_PATH" ]]; then
  sudo rm -f "$SELF_PATH" || true
fi

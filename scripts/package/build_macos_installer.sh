#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]
  --version <version>            Installer version (default: SLIPSTREAM_VERSION or 0.0.0-dev)
  --app-build-dir <path>         Flutter macOS app bundle path
                                 (default: Software-code/App/build/macos/Build/Products/Release/client.app)
  --output-dir <path>            Output directory (default: dist/macos)
  --dashboard-server-bin <path>  Optional dashboard_server binary to bundle
  --codesign-identity <name>     Optional app code-sign identity
  --installer-sign-identity <n>  Optional installer package signing identity
  --notarize                      Submit built artifact to Apple notary service
  --apple-id <id>                Apple ID for notarization
  --apple-team-id <id>           Apple Team ID for notarization
  --apple-app-password <pw>      App-specific password for notarization
  --skip-dmg                     Build .pkg only
  --dry-run                      Stage files only (skip pkgbuild + dmg)
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

VERSION="${SLIPSTREAM_VERSION:-0.0.0-dev}"
APP_BUILD_DIR="Software-code/App/build/macos/Build/Products/Release/client.app"
OUTPUT_DIR="dist/macos"
DASHBOARD_SERVER_BIN="${SLIPSTREAM_DASHBOARD_SERVER_BIN:-}"
DRY_RUN="0"
SKIP_DMG="0"
CODESIGN_IDENTITY="${SLIPSTREAM_MACOS_CODESIGN_IDENTITY:-}"
INSTALLER_SIGN_IDENTITY="${SLIPSTREAM_MACOS_INSTALLER_SIGN_IDENTITY:-}"
NOTARIZE="${SLIPSTREAM_MACOS_NOTARIZE:-0}"
APPLE_ID="${SLIPSTREAM_APPLE_ID:-}"
APPLE_TEAM_ID="${SLIPSTREAM_APPLE_TEAM_ID:-}"
APPLE_APP_PASSWORD="${SLIPSTREAM_APPLE_APP_PASSWORD:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --app-build-dir)
      APP_BUILD_DIR="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --dashboard-server-bin)
      DASHBOARD_SERVER_BIN="$2"
      shift 2
      ;;
    --codesign-identity)
      CODESIGN_IDENTITY="$2"
      shift 2
      ;;
    --installer-sign-identity)
      INSTALLER_SIGN_IDENTITY="$2"
      shift 2
      ;;
    --notarize)
      NOTARIZE="1"
      shift
      ;;
    --apple-id)
      APPLE_ID="$2"
      shift 2
      ;;
    --apple-team-id)
      APPLE_TEAM_ID="$2"
      shift 2
      ;;
    --apple-app-password)
      APPLE_APP_PASSWORD="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="1"
      shift
      ;;
    --skip-dmg)
      SKIP_DMG="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

APP_BUILD_PATH="$REPO_ROOT/$APP_BUILD_DIR"
if [[ ! -d "$APP_BUILD_PATH" ]]; then
  echo "Flutter macOS app bundle not found: $APP_BUILD_PATH" >&2
  exit 1
fi

OUTPUT_PATH="$REPO_ROOT/$OUTPUT_DIR"
STAGE_ROOT="$OUTPUT_PATH/payload"
PKG_SCRIPTS_SRC="$REPO_ROOT/packaging/macos/pkg_scripts"
PKG_SCRIPTS_STAGE="$OUTPUT_PATH/pkg_scripts"
DMG_SRC="$OUTPUT_PATH/dmg-src"
PKG_PATH="$OUTPUT_PATH/Slipstream-${VERSION}.pkg"
DMG_PATH="$OUTPUT_PATH/Slipstream-${VERSION}.dmg"
MANIFEST_PATH="$OUTPUT_PATH/bundle-manifest.txt"

rm -rf "$STAGE_ROOT" "$PKG_SCRIPTS_STAGE" "$DMG_SRC" "$PKG_PATH" "$DMG_PATH"
mkdir -p "$STAGE_ROOT/Applications" \
  "$STAGE_ROOT/Library/Application Support/Slipstream/scripts" \
  "$STAGE_ROOT/Library/Application Support/Slipstream/services" \
  "$STAGE_ROOT/Library/LaunchAgents" \
  "$PKG_SCRIPTS_STAGE" \
  "$DMG_SRC"

cp -R "$APP_BUILD_PATH" "$STAGE_ROOT/Applications/Slipstream.app"

cp "$REPO_ROOT/packaging/macos/launch_dashboard_service.sh" \
  "$STAGE_ROOT/Library/Application Support/Slipstream/scripts/launch_dashboard_service.sh"
chmod +x "$STAGE_ROOT/Library/Application Support/Slipstream/scripts/launch_dashboard_service.sh"

cp "$REPO_ROOT/packaging/macos/uninstall_slipstream.command" \
  "$STAGE_ROOT/Applications/Slipstream Uninstall.command"
chmod +x "$STAGE_ROOT/Applications/Slipstream Uninstall.command"

if [[ -n "$DASHBOARD_SERVER_BIN" && -f "$DASHBOARD_SERVER_BIN" ]]; then
  cp "$DASHBOARD_SERVER_BIN" "$STAGE_ROOT/Library/Application Support/Slipstream/services/dashboard_server"
  chmod +x "$STAGE_ROOT/Library/Application Support/Slipstream/services/dashboard_server"
fi

cat > "$STAGE_ROOT/Library/LaunchAgents/com.slipstream.dashboard.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.slipstream.dashboard</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Library/Application Support/Slipstream/scripts/launch_dashboard_service.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/slipstream-dashboard.out.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/slipstream-dashboard.err.log</string>
</dict>
</plist>
PLIST

cp "$PKG_SCRIPTS_SRC/preinstall" "$PKG_SCRIPTS_STAGE/preinstall"
cp "$PKG_SCRIPTS_SRC/postinstall" "$PKG_SCRIPTS_STAGE/postinstall"
chmod +x "$PKG_SCRIPTS_STAGE/preinstall" "$PKG_SCRIPTS_STAGE/postinstall"

{
  echo "version=$VERSION"
  echo "app_build_dir=$APP_BUILD_PATH"
  echo "stage_root=$STAGE_ROOT"
  if [[ -f "$STAGE_ROOT/Library/Application Support/Slipstream/services/dashboard_server" ]]; then
    echo "dashboard_server_bundled=true"
  else
    echo "dashboard_server_bundled=false"
  fi
  echo "launch_agent=/Library/LaunchAgents/com.slipstream.dashboard.plist"
} > "$MANIFEST_PATH"

echo "Staged macOS installer payload at $STAGE_ROOT"
echo "Manifest: $MANIFEST_PATH"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run enabled; skipping pkgbuild and dmg creation."
  exit 0
fi

if ! command -v pkgbuild >/dev/null 2>&1; then
  echo "pkgbuild not found. Install Xcode command line tools." >&2
  exit 1
fi
if [[ "$SKIP_DMG" != "1" ]] && ! command -v hdiutil >/dev/null 2>&1; then
  echo "hdiutil not found." >&2
  exit 1
fi

if [[ -n "$CODESIGN_IDENTITY" ]]; then
  if ! command -v codesign >/dev/null 2>&1; then
    echo "codesign not found; unable to sign app bundle." >&2
    exit 1
  fi
  echo "Signing app bundle with identity: $CODESIGN_IDENTITY"
  codesign --force --deep --options runtime --sign "$CODESIGN_IDENTITY" \
    "$STAGE_ROOT/Applications/Slipstream.app"
  codesign --verify --deep --strict "$STAGE_ROOT/Applications/Slipstream.app"
fi

pkgbuild_args=(
  --root "$STAGE_ROOT"
  --identifier "com.slipstream.client"
  --version "$VERSION"
  --install-location "/"
  --scripts "$PKG_SCRIPTS_STAGE"
)
if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
  pkgbuild_args+=(--sign "$INSTALLER_SIGN_IDENTITY")
fi
pkgbuild "${pkgbuild_args[@]}" "$PKG_PATH"

cp "$PKG_PATH" "$DMG_SRC/"
cat > "$DMG_SRC/README.txt" <<'TXT'
Slipstream Installer

1. Open the .pkg file and follow the installer prompts.
2. Launch Slipstream from Applications.
3. If bundled, dashboard service auto-start is configured with launchd.

Uninstall:
- Run /Applications/Slipstream Uninstall.command
TXT

if [[ "$SKIP_DMG" == "1" ]]; then
  echo "Skip-dmg enabled; created package only: $PKG_PATH"
  if [[ "$NOTARIZE" == "1" ]]; then
    if [[ -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_PASSWORD" ]]; then
      echo "Notarization requested but Apple credentials are incomplete." >&2
      exit 1
    fi
    if ! command -v xcrun >/dev/null 2>&1; then
      echo "xcrun not found; unable to notarize package." >&2
      exit 1
    fi
    echo "Submitting package for notarization: $PKG_PATH"
    xcrun notarytool submit "$PKG_PATH" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --wait
    xcrun stapler staple "$PKG_PATH"
    echo "Notarization complete for package: $PKG_PATH"
  fi
  exit 0
fi

hdiutil create -volname "Slipstream Installer" -srcfolder "$DMG_SRC" -ov -format UDZO "$DMG_PATH"

echo "Created package: $PKG_PATH"
echo "Created disk image: $DMG_PATH"

if [[ "$NOTARIZE" == "1" ]]; then
  if [[ -z "$APPLE_ID" || -z "$APPLE_TEAM_ID" || -z "$APPLE_APP_PASSWORD" ]]; then
    echo "Notarization requested but Apple credentials are incomplete." >&2
    exit 1
  fi
  if ! command -v xcrun >/dev/null 2>&1; then
    echo "xcrun not found; unable to notarize dmg." >&2
    exit 1
  fi
  echo "Submitting dmg for notarization: $DMG_PATH"
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
  echo "Notarization complete for dmg: $DMG_PATH"
fi

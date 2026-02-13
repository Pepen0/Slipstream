#!/usr/bin/env bash
set -euo pipefail

SERVICE_BIN="/Library/Application Support/Slipstream/services/dashboard_server"
ADDRESS="${SLIPSTREAM_DASHBOARD_ADDRESS:-127.0.0.1:50060}"

if [[ ! -x "$SERVICE_BIN" ]]; then
  exit 0
fi

exec "$SERVICE_BIN" "$ADDRESS"

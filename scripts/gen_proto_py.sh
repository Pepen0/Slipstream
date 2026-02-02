#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
proto_root="${PROTO_ROOT:-$root/shared/protos}"
out_root="${OUT_ROOT:-$root}"
python_bin="${PYTHON_BIN:-python3}"
if ! command -v "$python_bin" >/dev/null 2>&1; then
  python_bin="python"
fi
if ! command -v "$python_bin" >/dev/null 2>&1; then
  echo "Python not found. Set PYTHON_BIN to your interpreter." >&2
  exit 1
fi

proto_file="$proto_root/telemetry/v1/telemetry.proto"
if [[ ! -f "$proto_file" ]]; then
  echo "Proto file not found: $proto_file" >&2
  exit 1
fi

"$python_bin" -m grpc_tools.protoc \
  -I "$proto_root" \
  --python_out="$out_root" \
  --grpc_python_out="$out_root" \
  "$proto_file"

mkdir -p "$out_root/telemetry/v1"
touch "$out_root/telemetry/__init__.py" "$out_root/telemetry/v1/__init__.py"

echo "Generated Python stubs under $out_root/telemetry/v1"

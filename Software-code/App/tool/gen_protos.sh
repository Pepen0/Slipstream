#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROTO_ROOT="$ROOT_DIR/../shared/protos"
OUT_DIR="$ROOT_DIR/App/lib/gen"

if ! command -v protoc >/dev/null 2>&1; then
  echo "protoc not found. Install protobuf." >&2
  exit 1
fi

export PATH="$PATH:$HOME/.pub-cache/bin"

mkdir -p "$OUT_DIR"

protoc -I "$PROTO_ROOT" \
  --dart_out=grpc:"$OUT_DIR" \
  "$PROTO_ROOT/dashboard/v1/dashboard.proto"

echo "Generated Dart gRPC files in $OUT_DIR"

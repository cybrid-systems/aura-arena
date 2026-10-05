#!/usr/bin/env bash
# M0 stack. Soft-headless arena race. No C viewport.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out"
bash "$ROOT/scripts/smoke_soft.sh"
echo "smoke: ARENA_SMOKE_OK"

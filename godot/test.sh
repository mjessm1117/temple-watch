#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
test_log=$(mktemp)
trap 'rm -f "$test_log"' EXIT
set +e
"${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path . -s tests/run.gd 2>&1 | tee "$test_log"
test_status=${PIPESTATUS[0]}
set -e
if rg -q 'SCRIPT ERROR|Parse Error' "$test_log"; then
  echo 'Godot reported a script error.' >&2
  exit 1
fi
exit "$test_status"

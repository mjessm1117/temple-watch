#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
test_log=$(mktemp)
trap 'rm -f "$test_log"' EXIT
for suite in run campaign_test story_port_test loop_test sith_test strategy_test combat7_test missions_test temple_view_test loadout_test galaxy_view_test screens_test integration_test map_art_test terrain_test; do
  set +e
  "${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path . -s "tests/$suite.gd" 2>&1 | tee "$test_log"
  test_status=${PIPESTATUS[0]}
  set -e
  if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:|[1-9][0-9]* failures' "$test_log"; then
    echo "Godot reported a failure in $suite." >&2
    exit 1
  fi
  if [ "$test_status" -ne 0 ]; then exit "$test_status"; fi
done

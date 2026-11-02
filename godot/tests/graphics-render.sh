#!/usr/bin/env bash
# Actual shader compilation, error-checked captures and per-tier GPU counters.
set -euo pipefail
cd "$(dirname "$0")/.."
test_data=$(mktemp -d)
trap 'rm -rf "$test_data"' EXIT
export XDG_DATA_HOME="$test_data"
for tier in low medium high; do
  renderer=forward_plus
  if [ "$tier" = low ]; then renderer=gl_compatibility; fi
  log="../docs/godot/tiers/render-$tier.log"
  xvfb-run -a -s '-screen 0 1366x768x24' \
    "${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --path . \
    --rendering-method "$renderer" -s res://tests/graphics_test.gd \
    -- "--graphics=$tier" --capture 2>&1 | tee "$log"
  if rg -q 'SCRIPT ERROR|Parse Error|ERROR:|[1-9][0-9]* failures' "$log"; then
    echo "Graphics rendering failed: $tier" >&2
    exit 1
  fi
  perf_log="../docs/godot/tiers/perf-$tier.log"
  xvfb-run -a -s '-screen 0 1366x768x24' \
    "${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --path . \
    --rendering-method "$renderer" -s res://tests/graphics_perf.gd \
    -- "--graphics=$tier" 2>&1 | tee "$perf_log"
  if ! grep -q 'GRAPHICS PERF:' "$perf_log" || grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$perf_log"; then
    echo "Graphics benchmark failed: $tier" >&2
    exit 1
  fi
done

#!/usr/bin/env bash
# Independent seeded campaigns per family; parallel Godot processes, no shared saves.
set -euo pipefail
cd "$(dirname "$0")"
log_dir=$(mktemp -d)
trap 'rm -rf "$log_dir"' EXIT
families=(rescue hack relay defend retaliation sabotage ambush)
pids=()
for family in "${families[@]}"; do
  "${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path . -s tests/campaign_bot.gd -- --family "$family" > "$log_dir/$family.log" 2>&1 &
  pids+=("$!")
done
status=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then status=1; fi
done
for family in "${families[@]}"; do
  cat "$log_dir/$family.log"
  if grep -qE 'SCRIPT ERROR|Parse Error|ERROR:|turn safety limit' "$log_dir/$family.log"; then status=1; fi
done
exit "$status"

#!/usr/bin/env bash
# Run the existing full balance sweep across four independent mission shards.
set -euo pipefail
cd "$(dirname "$0")/.."
logs=$(mktemp -d)
trap 'rm -rf "$logs"' EXIT
pids=()
for shard in 0 1 2 3; do
  SHARD="$shard/4" node tests/balance.test.js > "$logs/$shard.log" 2>&1 &
  pids+=("$!")
done
status=0
for shard in 0 1 2 3; do
  if ! wait "${pids[$shard]}"; then
    status=1
  fi
  cat "$logs/$shard.log"
done
exit "$status"

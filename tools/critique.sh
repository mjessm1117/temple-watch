#!/usr/bin/env bash
# Usage: ./tools/critique.sh screenshot.png [screenshot2.png ...]
set -euo pipefail
cd "$(dirname "$0")/.."
if (( $# == 0 )); then
  echo "Usage: $0 screenshot.png [screenshot2.png ...]" >&2
  exit 2
fi
prompt=$(cat tools/critique-rubric.md)
prompt+=$'\n\nUse the Read tool to view every screenshot below, then grade each one independently:\n'
for screenshot in "$@"; do
  if [[ ! -f "$screenshot" ]]; then
    echo "Missing screenshot: $screenshot" >&2
    exit 2
  fi
  prompt+="$(realpath "$screenshot")"$'\n'
done
claude -p "$prompt" --allowedTools Read

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec "${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path . -s tests/run.gd

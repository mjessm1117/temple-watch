#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
"${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path godot/ \
  -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests/unit/ --continue --ignoreHeadlessMode

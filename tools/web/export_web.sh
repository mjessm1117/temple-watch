#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
godot_bin=${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/temple-web.XXXXXXXX")
export_dir="$repo_dir/build/web"
python3 "$repo_dir/tools/web/prepare_web.py" "$work_dir/godot"
mkdir -p "$export_dir"
"$godot_bin" --headless --path "$work_dir/godot" --editor --quit > "$work_dir/import.log" 2>&1 || { cat "$work_dir/import.log"; exit 1; }
python3 "$repo_dir/tools/web/override_imports.py" "$work_dir/godot"
"$godot_bin" --headless --path "$work_dir/godot" --editor --quit > "$work_dir/reimport.log" 2>&1 || { cat "$work_dir/reimport.log"; exit 1; }
python3 "$repo_dir/tools/web/force_texture_reimport.py" "$work_dir/godot"
"$godot_bin" --headless --path "$work_dir/godot" --editor --quit > "$work_dir/final-import.log" 2>&1 || { cat "$work_dir/final-import.log"; exit 1; }
"$godot_bin" --headless --path "$work_dir/godot" --export-release Web "$export_dir/index.html" > "$work_dir/export.log" 2>&1 || { cat "$work_dir/export.log"; exit 1; }
python3 "$repo_dir/tools/web/version_service_worker.py" "$export_dir"
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "$work_dir/import.log" "$work_dir/reimport.log" "$work_dir/final-import.log" "$work_dir/export.log"; then
  echo "Web import/export reported errors. Logs: $work_dir" >&2
  exit 1
fi
printf 'Web export: %s\nBuild logs: %s\n' "$export_dir" "$work_dir"

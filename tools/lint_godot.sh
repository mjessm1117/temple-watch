#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

lint_output=$(gdlint godot/ 2>&1 || true)
format_output=$(gdformat --check godot/ 2>&1 || true)
errors=$(grep -c ': Error:' <<< "$lint_output" || true)
unformatted=$(grep -c '^would reformat ' <<< "$format_output" || true)

read -r max_errors max_unformatted < <(python3 -c 'import json; d=json.load(open("tools/lint-baseline.json")); print(d["gdlint_errors"], d["gdformat_unformatted"])')
if (( errors > max_errors || unformatted > max_unformatted )); then
  echo "FAIL: gdlint $errors/$max_errors errors; gdformat $unformatted/$max_unformatted unformatted"
  exit 1
fi
echo "PASS: gdlint $errors errors (<= $max_errors); gdformat $unformatted unformatted (<= $max_unformatted)"

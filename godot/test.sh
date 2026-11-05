#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
test_log=$(mktemp)
test_data=$(mktemp -d)
export XDG_DATA_HOME="$test_data"
trap 'rm -f "$test_log"; rm -rf "$test_data"' EXIT
run_suite() {
  local suite="$1"
  shift
  set +e
  "${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path . -s "tests/$suite.gd" "$@" 2>&1 | tee "$test_log"
  test_status=${PIPESTATUS[0]}
  set -e
  if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:|[1-9][0-9]* failures' "$test_log"; then
    echo "Godot reported a failure in $suite." >&2
    exit 1
  fi
  if [ "$test_status" -ne 0 ]; then exit "$test_status"; fi
}
# Real process restarts, with no rendering-method CLI override.
run_suite graphics_boot_test -- --save=low
run_suite graphics_boot_test -- --expect=low --save=medium
run_suite graphics_boot_test -- --expect=medium --save=high
run_suite graphics_boot_test -- --expect=high
# --- wave10 story --- # --- wave10 gear ---
for suite in run campaign_test campaign11_test gear_research_test story_port_test story_bonds_test story_night1_test story11_test villain11_battle_test loop_test sith_test strategy_test combat7_test hud_night1_test battle11_test missions_test missions11_test temple_view_test home_ui_test loadout_test galaxy_view_test screens_test integration_test map_art_test terrain_test; do
  run_suite "$suite"
done
run_suite battle12_test
run_suite mobile_web1_test
run_suite rules12_test
run_suite temple12_test --resolution 844x390 -- --phone
run_suite armory12_test
run_suite graphics_test --rendering-method gl_compatibility -- --graphics=low
run_suite graphics_test --rendering-method forward_plus -- --graphics=medium
run_suite graphics_test --rendering-method forward_plus -- --graphics=high
run_suite gfx_night1_test --rendering-method gl_compatibility -- --graphics=low
run_suite gfx_night1_test --rendering-method forward_plus -- --graphics=high
run_suite gfx13_test --rendering-method gl_compatibility -- --graphics=low
run_suite gfx13_test --rendering-method forward_plus -- --graphics=medium
run_suite gfx13_test --rendering-method forward_plus -- --graphics=high
run_suite armory13_test
run_suite home13_test --resolution 844x390 -- --phone
run_suite home13_test --resolution 1366x768
run_suite home13_test --rendering-method gl_compatibility --resolution 844x390 -- --phone --graphics=low
run_suite battle13_test --rendering-method gl_compatibility -- --graphics=low
run_suite battle14_test --rendering-method gl_compatibility -- --graphics=low
run_suite map14_test --rendering-method gl_compatibility -- --graphics=low
run_suite map14_test --rendering-method forward_plus -- --graphics=high
run_suite map14_test --rendering-method gl_compatibility --resolution 844x390 -- --battle --graphics=low
run_suite map14_test --rendering-method gl_compatibility --resolution 1366x768 -- --battle --graphics=low
run_suite home14_test --rendering-method gl_compatibility --resolution 844x390 -- --phone
run_suite home14_test --rendering-method gl_compatibility --resolution 1366x768
run_suite story14_test --rendering-method gl_compatibility -- --graphics=low
run_suite jedi15_test --rendering-method gl_compatibility -- --graphics=low

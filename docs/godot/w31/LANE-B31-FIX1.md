# B31 Fix 1 — uiart23_test overlap

## Context
B31 added portrait aim framing in `cam_combat.gd` (portrait_frame31 + portrait detection in preview()).
Gate shows 1 failure: `uiart23_test` — "odds and target selection do not overlap".
FEELCAM22 is green (373ms). All other suites pass.

## Goal
Fix the uiart23 overlap without reverting the portrait aim framing.

## Steps

1. Read `godot/tests/uiart23_test.gd`. Find the "odds and target selection do not overlap"
   assertion. Understand what screen region it expects for each element and what test resolution
   it uses.

2. Read `godot/scripts/cam_combat.gd`. Find the `portrait_frame31` function and the portrait
   detection block in `preview()`. Check what camera Z / FOV / offset it applies at portrait
   orientation. Understand how that could shift the aim overlay or target card into the other.

3. Fix: adjust `portrait_frame31()` or the portrait preview path so the aim overlay ("odds")
   and target selection card stay in their expected non-overlapping positions at the test's
   resolution. Minimal change — do not restructure the function.

4. Run the gate: `/home/jess/projects/.tools/godot/godot --headless --import 2>&1 | tail -5`
   then `bash godot/test.sh 2>&1 | tail -20`. Must exit 0, 0 SCRIPT ERRORs, 0 failures,
   Normal rescue 9–11/20.

5. If gate passes: `git add -A && git commit -m "B31: fix uiart23 overlap — portrait frame camera stays within aim safe area"`

## Boundaries
- Only touch `cam_combat.gd` (and test file if an assertion needs updating for new layout).
- Do not touch `map_art_grid.gd`, `input_controls.gd`, `enemy_presentation.gd`.
- Do not change B31's core portrait framing intent — keep shooter + target visible.
- If the test assertion is checking a layout that portrait_frame31 intentionally changes,
  update the test assertion to match the new intended layout (don't break the design to fix a test).

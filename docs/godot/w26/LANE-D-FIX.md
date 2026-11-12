# W26 Lane D Fix — hud_night1_test assertion update
Branch: w26/preview (commit 92a14a8 "Add W26 tactical move and sight previews")

## Context
Lane D committed correctly (hud_controls.gd, input_controls.gd, map_art_grid.gd, preview26_test.gd).
Two assertions in hud_night1_test.gd now mismatch Lane D's new behavior.

Failing assertions (lines ~114-116):
1. `HudControls.move_color(int(walk.ap)) == Color("60b9ff")` — "one AP movement is blue"
   Lane D changed edge color to cyan Color("65ddf5") for safe tiles.
2. `HudControls.move_fill(1).a >= 0.18 and ... a <= 0.30` — "move tile fill is legible"
   Lane D set fill alpha to MOVE_RANGE_FILL_ALPHA26 = 0.06.

## Steps
1. `git checkout w26/preview` (already there)
2. Read godot/tests/hud_night1_test.gd lines 110-120 to confirm the exact assertion text.
3. Read godot/scripts/hud_controls.gd to find the actual `move_color()` and `move_fill()` return values.
4. Update the two assertions to match the actual new values:
   - For color: update to the new 1AP color (cyan or the actual move_color return value)
   - For alpha: update the bounds to match MOVE_RANGE_FILL_ALPHA26 = 0.06 (e.g. `a >= 0.04 and a <= 0.10`)
   - If move_color() was not changed, update differently. Use what's actually in the code, not assumptions.
5. Run focused: `xvfb-run -a /home/jess/projects/.tools/godot/godot --headless --path godot -s tests/hud_night1_test.gd`
   Confirm: "HUD NIGHT1 TEST RESULTS: N checks, 0 failures"
6. Run full gate: `godot/test.sh` — must exit 0, 0 fail, 0 SCRIPT ERROR.
7. Commit on w26/preview.

## File lease
- godot/tests/hud_night1_test.gd (test assertion update ONLY — lines 114-116)

Do NOT change any implementation file. Do NOT change any other test. Do NOT change preview26_test.gd.

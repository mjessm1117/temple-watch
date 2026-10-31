# Wave 4 integration — wire the five lanes together
Read docs/godot/wave4/WAVE4.md rules (web game frozen, files <600 lines, tests, local commits only, no push, no subagents). All five lane branches are already merged on main. Read each `docs/godot/wave4/*-REPORT.md` and `docs/godot/ART.md` "Integration requests".

FILE LEASE: everything under `godot/` and `docs/godot/`.

Do every integration request:
1. FX: in game.gd call `view.set_cover(level)` after unit views refresh (2 = full cover against the most threatening visible enemy if derivable, else 1/0); Push target uses `stagger_to(destination)`; damaging hit plays `sound.play("hit")`; crit or kill calls `fx.hit_stop()`.
2. Combat: add Hunker Down to the ability bar with a hotkey, calling `mission.hunker(id)`, show hunkered state on the unit panel; draw a bright warm on-map entry marker at `mission.reinforcement_marker` (when x >= 0), refreshed after each end turn; when `mission.terrain_revision` changes after any action, rebuild terrain and play `fx.cover_chunks` at the changed tile.
3. Tests: register controls_test.gd and fx_test.gd in godot/tests/run.gd so `./godot/test.sh` runs them.
4. Art: move the Wave 4 art section into `docs/godot/wave4/art-REPORT.md`, captures into `docs/godot/shots/wave4-art-*.png`, fix links.
5. Check the integrated game for conflicts between lanes (e.g. controls' target-confirm flow vs combat's new rules, Push no-roll display, flank crit shown in the targeting panel). Fix any.

Done = `./godot/test.sh` 0 failures, no script errors. Capture 3 screenshots of the integrated game launching `res://scenes/rescue.tscn` directly (the menu scene stalls captures): move preview, targeting a flanked enemy with breakdown, reinforcement marker. Save as `docs/godot/shots/wave4-final-*.png`. Write `docs/godot/wave4/integrate-REPORT.md` (player changes, test line, screenshots, open problems). Commit on main locally.

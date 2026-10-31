# Lane: controls — XCOM-style turn flow, camera and HUD
Read WAVE4.md first; its rules apply. Branch: wave4/controls.

FILE LEASE: `godot/scripts/game.gd`, `godot/scripts/menu.gd`, `godot/scripts/settings.gd`, `godot/scenes/*.tscn`, new files `godot/scripts/hud*.gd`, `godot/scripts/camera*.gd`, `godot/scripts/input*.gd`, new test file `godot/tests/controls_test.gd` (ask for registration in run.gd via Integration requests if run.gd does not auto-discover). Split game.gd so it ends well under 600 lines.

Goal: every turn should feel like XCOM 2: fast, readable, no guesswork. Check XCOM 2 configs for timings.
- Movement: on select, show the 1-action range (blue border) and dash range (yellow border); hover shows the path, AP cost, and cover shields (half/full) at the destination; click once to preview, again (or click-and-confirm) to move.
- Targeting: choosing Shoot/Strike/Push enters target mode; Tab/Shift-Tab cycles valid targets; camera frames shooter + target; a shot panel shows hit %, crit %, and every modifier; Enter or click confirms; Esc/right-click cancels.
- Flow: after a unit spends its actions, auto-select the next unit with actions; Tab cycles squad when not targeting; end-turn warns if any unit still has actions.
- Camera: Q/E snap-rotate 90° with smooth blend, WASD/edge pan, wheel zoom, camera smoothly follows the active unit; enemy turn briefly frames each acting enemy (skippable, short).
- Hotkeys shown on the ability bar; Space skips any cinematic; nothing ever blocks input longer than needed.
- Use only public functions of mission.gd/shot.gd (another lane is changing their internals). Read data, don't reimplement rules.

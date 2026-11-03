# Wave 11 — BATTLE FEEL lane
Read docs/godot/wave11/COMMON.md first; its rules apply.

## Goal
Battles feel clearer and smoother on a 1366x768 and 1920x1080 desktop screen.

## Requirements
1. Units read bigger at default zoom: default camera framing tighter (start zoomed so a unit is ~2x its current on-screen height) and/or unit model scale up ~1.3x WITHOUT changing tile size, hit/LOS logic or overlapping neighbours. Zoom range still lets the whole map be seen when zoomed out.
2. No clipped labels anywhere in the battle HUD: ability buttons ("Momentum Surge", "Precision Strike", "Free Mira", "Interact"), unit plate, targeting panel, banners. Auto-shrink font or wrap to 2 lines; never cut text. Test every ability name in data/abilities.json against the button width.
3. Camera: smooth eased pan to the active unit at turn start and on unit select; pan to an enemy when it acts (skippable / quick, ≤0.6s); edge-pan and WASD keep working; camera never ends up inside geometry or off-map.
4. Turn flow: enemy turn plays faster (option in pause/settings: Normal / Fast; Fast default), a clear "YOUR TURN" handoff, auto-select next unit with actions left after an action (toggle), and an "end turn with units still able to act?" confirm.
5. Keep everything Night 1 added (ability bar wrapping, odds breakdown, move tiles, plate fields).

## File lease (only these)
godot/scripts/cam_combat.gd, unit_view.gd, hud_controls.gd, hud_night1.gd, hud_ability_button.gd, input_controls.gd, combat_turns.gd, combat_round.gd, combat_scene.gd, ui_motion.gd, settings.gd, combat_capture.gd, new files godot/scripts/battle11_*.gd, godot/tests/battle11_test.gd, godot/test.sh (suite line only), docs/godot/shots/wave11-battle-*.png.
game.gd: hook lines only (≤10 lines added), must stay <600.

## Tests (battle11_test.gd)
Label-fit check for every ability name at 1366 and 1920 width; camera bounds; fast enemy turn speed setting persists; auto-select next unit; end-turn confirm appears only when units can still act.

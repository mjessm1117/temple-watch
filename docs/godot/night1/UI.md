# Night 1 — Battle UI pass (XCOM-style clarity), 2026-11-02

## Goal
Make the battle screen readable and satisfying like XCOM 2: clear actions, clear odds, clear turn state. Mechanics/UX patterns only from XCOM, no copied assets.

## Context
- Godot 4.7.2: /home/jess/projects/.tools/godot/godot. Run `godot --headless --path godot --import` first.
- Battle HUD: scripts/hud_controls.gd, input_controls.gd, combat_targeting.gd (hit chance), combat_abilities.gd / abilities_engine.gd, combat_turns.gd, combat_round.gd, combat_scene.gd, cam_combat.gd. docs/XCOM2-STUDY.md has the XCOM reference notes.
- Temple home screen was just polished (docs/godot/home/) — do NOT touch campaign/temple*.gd or home_*.gd.
- Before any change: capture battle states into docs/godot/shots/night1-ui-before-*.png (idle, unit selected, targeting enemy, enemy turn) at 1366x768 and 1920x1080 using existing capture tooling (combat_capture.gd).

## Requirements
1. Ability bar: bottom-centre row of ability buttons with drawn vector icons (Godot shapes, no image downloads), hotkey number, action-point cost, cooldown overlay with turns left, greyed + tooltip reason when unusable.
2. Targeting: when aiming, show hit % and crit % big next to target, plus a hover/expand breakdown (base aim, cover, range, height, abilities, bonds) computed from the REAL combat_targeting numbers — no separate formula. Tab / Q-E cycles enemies in sight; enemy heads get small hit-% chips.
3. Unit panel: selected Jedi portrait plate (drawn), name, class, HP pips, will, actions left, status effects with icons + tooltips, bond partner.
4. Movement preview: blue (1 action) vs yellow (dash) reachable tiles, path line, cover shields at destination (full/half), flank warning (red) if destination is flanked by a visible enemy. Reuse existing reachability data.
5. Turn banner: "JEDI TURN" / "ENEMY ACTIVITY" banner with short slide animation; enemy action log line (e.g. "Sith Acolyte moves") readable for 2s.
6. Pause/Esc menu and battle Settings reachable, consistent styling with the Temple home (gold edge, dark panel). End-turn button with confirm when units still have actions.
7. Everything works at 1366x768 and 1920x1080; no overlap.

## Boundaries
- Nothing removed; every existing action/key still works. No balance or rule changes (display only).
- Plain GDScript, every file < 600 lines; new code in new files (scripts/hud_*.gd).
- No downloads, no Meshy, no network. Do not touch public/, functions/, tests/ (web frozen), worker.js, wrangler.toml, graphics/env/fx files, story files, campaign/temple*.gd.
- Do not delegate or spawn subagents.

## File lease (only these)
godot/scripts/hud_controls.gd, input_controls.gd, combat_targeting.gd (read-only except exposing a breakdown function), combat_scene.gd (only HUD wiring), combat_capture.gd, cam_combat.gd (only for target-cycle focus), new godot/scripts/hud_*.gd, battle HUD scenes under godot/scenes/ (only HUD nodes), new godot/tests/hud_night1_test.gd, godot/test.sh (add suite), docs/godot/night1/UI-REPORT.md, docs/godot/shots/night1-ui-*.png.

## Verification (all required before commit)
1. New suite hud_night1_test.gd: ability bar matches unit abilities incl. cost/cooldown/disabled reason; displayed hit% == combat_targeting result for fixture shots (cover, flank, height); breakdown sums to total; target cycling order; move preview colours match action costs; flank warning fires; turn banner shows on both turns.
2. `./godot/test.sh` exit 0, 0 SCRIPT ERROR, every suite 0 failures, Normal rescue bot 10/20.
3. After shots night1-ui-after-{idle,selected,targeting,breakdown,move,enemy-turn,pause}.png at 1920x1080 + 1366 versions of idle/targeting.
4. docs/godot/night1/UI-REPORT.md: what changed, before/after list, anything skipped and why.
5. Commit on current branch: "Night 1 UI: ability bar, hit breakdown, unit panel, move preview, turn banner". Do not push.

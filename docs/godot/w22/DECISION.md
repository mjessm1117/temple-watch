# W22 lane C — Aim and move decision UI (task tw-w22-decision)

First read /home/jess/projects/temple-watch/docs/godot/w22/COMMON.md and follow it exactly. Your lane name is `decision`, so your worktree is /home/jess/projects/tw-w22/decision on branch w22/decision, off 81c7644.

## Goal
Fix: Battle problems #2, #4, #7 (the HUD side), #13 (route) and #14. Use the audit rows for causes, files and lines.

## Work
- Movement grid: dim the far fills and emphasize the reachable edge and the hovered route. Keep the blue/amber 1-action vs 2-action split clear. Units and cover must read through the grid on the phone.
- Route: a stronger path arrow and endpoint marker.
- Odds: show the hit % big, with the target name and the top 2 modifiers (cover, flank, height) visible without an extra tap.
- Add an unmistakable FLANKED / NO COVER badge near the hit %.
- Cover shields on the hovered move tile are scaled for the phone.
- Hovered destination: preview which KNOWN enemies would see/flank you there. Use only visible enemies.
- End Turn: a compact threat chip beside the button, rendered from D's `threat_summary` (guarded; hidden if the API is missing). Show the reveal title from `reveal_info` when A frames a reveal, if a HUD hook is needed.
- Check every control at 844x390 and 390x844 against the COMMON tap/text rules.

## File lease (you may write ONLY these)
`godot/scripts/hud_controls.gd`, `godot/scripts/hud_night1.gd`, `godot/scripts/hud_phone.gd`, `godot/scripts/hud_phone_action_art.gd`, `godot/scripts/combat_targeting.gd`, `godot/scripts/input_controls.gd`, `godot/scripts/map_art_grid.gd`, new `godot/scripts/decision22_*.gd`, `godot/tests/decision22_test.gd`

Every other file is read-only. Changes needed elsewhere go under Integrate asks.

## Test
New suite `godot/tests/decision22_test.gd`, registered with one line in test.sh. It covers each Work bullet with real assertions (numbers, not just "exists").

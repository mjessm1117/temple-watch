# Wave 4 study report

## What changed for the player

No gameplay changes in this reasoning lane. [FEEL-GAP.md](FEEL-GAP.md) ranks 15 concrete gaps, ties WotC config keys to current Godot functions, separates verified observations from inference, and sizes the next fixes. The highest-impact work is ordered shot presentation, move and target confirmation, and sequential enemy-turn feedback.

## How to see it in game

Run `./godot/run.sh`, select a soldier, hover a reachable tile or spotted enemy, then choose Shoot and click a target. The hover panel shows aim, crit, graze, and cover, but the first target click commits the shot; the action camera takes 0.6 s to blend after the result is already resolved. Press Enter to observe the batched enemy turn and 1.2 s activity banner.

## Test result

**140 checks passed / 0 failed; no script errors** after regenerating the fresh worktree's Godot import cache with `/home/jess/projects/.tools/godot/godot --headless --editor --path godot --import --quit`. First run failed from missing generated GLB imports; the post-import rerun passed. Normal seeded rescue bot: 11/20 wins. A `/tmp/` headless probe measured 0.0110 s mean for 100 fresh mission plus first enemy-turn rule calls; four successive seeded turns took 0.0111–0.0647 s. These figures exclude animation and rendering.

## Screenshots

The standard screenshot command, a 90-second OpenGL compatibility attempt, a 30-second headless demo, and a 150-second overview capture all timed out during Godot rendering on this shared machine; none produced a PNG. Existing [rescue mission](../shots/rescue-mission.png) and [rescue shot](../shots/rescue-shot.png) frames are baseline images from before this study. **No new study screenshot is available.**

## Integration requests

- `godot/scripts/game.gd:_attack/_action_cam/_end_turn`: present events in temporal order; make shot impact and camera arrival agree; show every visible enemy action and support skip.
- `godot/scripts/game.gd:_unhandled_input/_show_shot/_refresh_highlights`: persistent move and target previews, confirm/cancel, target cycling, damage/armor/kill information.
- `godot/scripts/mission.gd:_wake_groups/end_turn` and `godot/scripts/ai.gd:scamper/act`: emit ordered activation, movement, attack, and result events with actual actors.
- `godot/data/rescue.json:rows/groups/reinforcement` and `godot/scripts/shot.gd:calculate/cover`: increase meaningful cover positions and route choices, make flanks visible, tune range and height curves with tests.

## Open problems

WotC runtime was not launched, so its clicks per turn, action seconds, enemy-turn seconds, and exact confirmation flow remain inferred from configs and known UI conventions. Godot visual timings are source-derived; the headless probe cannot establish frame time or a human player's pace. New screenshot capture was blocked by repeated rendering timeouts.

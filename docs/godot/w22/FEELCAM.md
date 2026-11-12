# W22 lane A — Camera and enemy pacing (task tw-w22-feelcam)

First read /home/jess/projects/temple-watch/docs/godot/w22/COMMON.md and follow it exactly. Your lane name is `feelcam`, so your worktree is /home/jess/projects/tw-w22/feelcam on branch w22/feelcam, off 81c7644.

## Goal
Fix: Battle problems #1, #3, #8, #9 (and the camera side of #12 and #11). Use the audit rows for causes, files and lines.

## Work
- Enemy turn: batch quiet or offscreen moves so they run together. Keep the camera on attacks, reveals and objective hits. Preserve event order and the tap-to-skip.
  - Target: a 4-enemy turn with 1 attack takes about 40% less wall time than at 81c7644. Measure it with the same seed before and after.
- Shorten repeat shot/reveal blends, and use one grouped camera beat for nearby enemies.
- Aim camera: score the shoulder candidates so the TARGET sits in the clear centre band at 844x390 and is not under the HUD. This must hold on the shrine map.
- Objective damage: frame the attacker and the gate together. Show the gate HP change and where the damage came from.
- Kill: a short readable beat of 0.3 s or less, then return to the board with the next ready unit in view.
- Reveal: call D's `reveal_info` (guarded) and frame the group once.
- Implement contracts 1 and 2. Call B's `cue()` guarded at hit, crit, kill, blast, alert and objective hit, and `set_music_state` at turn changes and on contact.

## File lease (you may write ONLY these)
`godot/scripts/game.gd`, `godot/scripts/cam_combat.gd`, `godot/scripts/combat_turns.gd`, `godot/scripts/enemy_presentation.gd`, `godot/scripts/cine15_shot.gd`, `godot/scripts/battle16_killcam.gd`, new `godot/scripts/feelcam22_*.gd`, `godot/tests/feelcam22_test.gd`

Every other file is read-only. Changes needed elsewhere go under Integrate asks.

## Test
New suite `godot/tests/feelcam22_test.gd`, registered with one line in test.sh. It covers each Work bullet with real assertions (numbers, not just "exists").

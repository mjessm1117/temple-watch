# W24 lane: feelcam

Read /home/jess/projects/temple-watch/docs/godot/w24/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w24/feelcam, branch w24/feelcam off aa19dd0. Test: godot/tests/feelcam24_test.gd. Proof: /home/jess/projects/tw-logs/w24/feelcam/.

Goal: the turn flows like XCOM 2: shots land with a beat, the camera returns smoothly, enemy actions say why, and input never feels dead.
- B4: replace shot/enemy-turn hard reset to board with a <=0.35 s return blend; never override a camera drag the player made during the beat (cam_combat.gd:184-195,267-274).
- B3/B9/B11: on hit trigger a 40-70 ms hit-stop + small impulse + impact24_cue("hit"); kill -> short emphasis + fall24 variant; miss -> impact24_cue("miss_near") at the near-miss point and a visible dodge, not only text (enemy_presentation.gd:159-198,184-186). All guarded.
- B6: show threat's intent_reason24 as a one-line callout on each enemy action (enemy_presentation.gd:111-140); fall back to the current title if absent.
- B8: Jedi leap presents start -> arc -> land (game.gd:201-210) using threat's leap start/end, with impact24_cue("leap_land").
- B14: one "clutch" beat (last unit standing / survive at 1 HP / cover break) - brief slow-mo or callout, max once per turn.
- K2: implement contract 1 (cancel_camera_glide24) around the tween at game.gd:298-309.
- K11: contract 2 (is_input_busy24 + signal) around game.gd:163,234-235,594-599.
- Zoom: one shared clamp constant (game.gd:563-570 says 6-65, pinch says 9-65); pick 9-65 and read cam_sensitivity from controls24.cfg for PC pan speed.
- Contracts 3 and 4 (set_battle_safe_rect24, preview_route24).
- Keep the W22 numbers: enemy turn <=1.7 s scripted path, kill cam <=0.3 s. Report before/after.

Do not delegate or spawn subagents; do the work yourself.

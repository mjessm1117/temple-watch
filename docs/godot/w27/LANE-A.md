# W27 Lane A — Opening decisions (worktree tw-w27/opening, branch w27/opening)

Read docs/godot/w27/COMMON.md first and follow it exactly. Lane prefix `w27a_`.

## Lease
godot/data/maps/relay.json, godot/data/story/data-story.json, godot/scripts/mission.gd, godot/scripts/mission_objectives.gd, godot/scripts/mission_pressure.gd, new godot/tests/opening27_test.gd, new w27a_* helpers.

## Goal (audit gaps 1, 2, 12)
Make the first three missions ask a real decision every turn instead of "walk up and shoot", without breaking Jess's mission-1 rules.
1. Mission 1 (relay gate): today all 5 allies start inside enemy sight and all 6 bot losses are a zone overrun on T2. Give the opening a protected setup choice: allies start behind gate cover, out of the west pod's sight, and the player chooses where to commit (e.g. hold the gate line vs push a flank). Add a one-turn contest recovery so one bad T1 does not lose on T2. Enemies stay in front; reinforcements still come later. Tune to 13–16/20 bot wins on Normal seeds 1–20 (now 14/20 but losses are all instant).
2. Missions 2–3: the route is defense → defense → timed hack, and the envoy timed hack is 0/20 (bot hits turn-10 limit every time). Make the three opening missions three different objective shapes (the step-2 menu already offers rescue and archive, data-story.json:2417-2430) and make the envoy mission winnable by player-equivalent play (time limit, distance, or extensions). Validate the actual campaign path, serially, missions 1→2→3.
3. Reinforcements (gap 12): the "2 IN 2T" label is the only warning. Add a setup countdown with a known entry tile so the player can set an overwatch trap. Expose `wave_entry27(m)` → {turns_left, count, entry_tiles, side} for lane C to draw, and `opening_choices27(m)` → the setup options.

## Test
opening27_test.gd: mission-1 allies out of initial enemy sight; no enemy spawns behind the squad; T2 recovery path exists; three distinct objective types on the opening route; envoy win reachable; wave_entry27/opening_choices27 shapes. Report the 20-seed table for missions 1–3 (bot wins, turns to win).

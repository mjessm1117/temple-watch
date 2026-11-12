# W24 lane: threat

Read /home/jess/projects/temple-watch/docs/godot/w24/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w24/threat, branch w24/threat off aa19dd0. Test: godot/tests/threat24_test.gd. Proof: /home/jess/projects/tw-logs/w24/threat/.

Goal: the player can see danger before committing and understand why enemies acted. Data and events only; do NOT change AI choices or rules.
- B2: contract 6 route_threat24 using exactly the per-tile overwatch rule in combat_mission.gd:175-198, plus tiles where a hidden enemy group would be revealed and whether the end tile is flanked. Test: preview result == actual reactions on 10+ scripted routes.
- B6: intent_reason24 from the reasons ai.gd:113-170 already computes (record the reason on the decision; do not alter scores).
- B7: route_segments24 (walk/vault/climb/door) from map data along the path.
- B8: abilities_engine.gd:168 leap emits start and end positions before resolving, so presentation can show the arc.
- B13: mission_pressure exposes next reinforcement {count, turns, entry_tile} for a persistent cue; reinforcement_marker shows entry point clearly.
- B14: mission.gd:138-150 cover break records cause (who/what) on the event.
- Rescue Normal must stay 9-11/20 exactly as before.

Do not delegate or spawn subagents; do the work yourself.

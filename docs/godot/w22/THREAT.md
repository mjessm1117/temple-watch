# W22 lane D — Threat and reveal data (task tw-w22-threat)

First read /home/jess/projects/temple-watch/docs/godot/w22/COMMON.md and follow it exactly. Your lane name is `threat`, so your worktree is /home/jess/projects/tw-w22/threat on branch w22/threat, off 81c7644.

## Goal
Fix: Battle problems #7 (the data side), #12, and the villain half of story problem #6. Use the audit rows for causes, files and lines.

## Work
- Implement contract 4: `threat_summary` and `reveal_info`, backed by real mission state, with unit tests on the first mission plus 2 other maps.
- Reinforcements: telegraph one turn ahead, with the entry position, count and type (data + marker).
- Villain: a named entry state (`status`: arriving, present, retreating) and a one-line intro/retreat hook. E writes the actual lines in `villain11_arc.gd` and `wave11-villain.json`. Read them guarded; fallback text is allowed.
- enemy11_plate: show the group identity (type and count) on reveal.

## File lease (you may write ONLY these)
`godot/scripts/mission_pressure.gd`, `godot/scripts/reinforcement_marker.gd`, `godot/scripts/enemy11_plate.gd`, `godot/scripts/villain11_battle.gd`, new `godot/scripts/threat22_*.gd`, `godot/tests/threat22_test.gd`

Every other file is read-only. Changes needed elsewhere go under Integrate asks.

## Test
New suite `godot/tests/threat22_test.gd`, registered with one line in test.sh. It covers each Work bullet with real assertions (numbers, not just "exists").

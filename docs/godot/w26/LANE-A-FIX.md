# W26 Lane A Fix
Read LANE-A.md first for context: docs/godot/w26/LANE-A.md

## Context
Lane A committed to w26/gate (commit aef4c43). Two tests failed in missions_test:
1. "gate announces the first wave and shows all attackers"
2. "two attackers overrun an empty gate zone"

## Task
Fix both failures in missions_test without breaking any other passing tests (440 were passing).

## Steps
1. `git checkout w26/gate`
2. `godot --headless --import`
3. Run `godot --headless --script godot/tests/missions_test.gd` to reproduce the failures with output.
4. Read godot/tests/gate26_pacing_test.gd to understand exactly what each failing test expects.
5. Read the implementations in mission.gd, mission_objectives.gd, mission_pressure.gd to find the mismatch.
6. Fix the implementation (do NOT change the test assertions — fix the code to match the test).
7. Run the full gate: `godot/test.sh` — must exit 0, 0 fail, 0 SCRIPT ERROR.
8. Commit on w26/gate.

## File lease (same as Lane A)
- godot/data/maps/relay.json
- godot/scripts/mission_objectives.gd
- godot/scripts/mission_pressure.gd
- godot/scripts/mission.gd
- godot/tests/gate26_pacing_test.gd

Do NOT edit any other file. Do NOT change test assertions.

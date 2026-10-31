# Wave 5 balance fix: combined build is too easy on Normal
Rules: docs/godot/wave4/WAVE4.md (web public/ FROZEN; GDScript <600 lines; local commit on branch wave5/integrate only; no push; no subagents).

The new rescue map (3 wide routes, maps lane) and the new skills/medpacs/revive (skills lane) were each balanced alone. Together, ./godot/test.sh fails 1 check:
Story 17/20, Normal 15/20 (band 9–12, FAIL), Hard 6/20, Legend 2/20 (legend: 14 clock losses, 232 medical uses).

Goal: all four bands pass again — Story >=14, Normal 9–12, Hard 4–7, Legend 1–3 — over the same 20 fixed seeds. Aim for Normal 10–11 so it isn't on the edge.
Lease: godot/data/difficulty.json first (per-difficulty enemy aim/HP/pod size/timer, medpac charges per difficulty are fine). Only if numbers alone can't do it: enemy placement in godot/data/rescue.json, without narrowing any route — map_test must stay green (3 routes >=3 wide, cover every <=4 steps, <=22 steps, 2 ramps).
Do NOT weaken the player's new choices (don't remove skills, revive, or the 3 routes) and keep enemy aim within ±10 of the web DIFF table (public/js/data.js).
Also check Legend: 14 clock losses with 232 medical uses means the bot heals forever instead of moving. If that's a bot policy problem (tests/ bot), fix the bot so it pushes toward the objective; note it in the report.
Done = ./godot/test.sh exits 0 with 0 failures and no SCRIPT ERROR (all 4 suites + loop test); report numbers before/after in docs/godot/wave5/balance-REPORT.md; commit "Rebalance difficulty for the new map and squad skills".

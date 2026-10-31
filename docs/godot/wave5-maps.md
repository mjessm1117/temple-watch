# Wave 5 lane: open up the rescue map (no chokepoints)
Rules: docs/godot/wave4/WAVE4.md (web frozen, files <600 lines, tests, local commit only, no push, no subagents).
FILE LEASE: godot/data/rescue.json, godot/scripts/map*.gd (new), godot/tests/map_test.gd (new, register in godot/tests/run.gd: that one line only), docs/godot/wave5/maps-REPORT.md, docs/godot/shots/wave5-maps-*.png.

Jess playtest: "maps shouldn't be so hard to get through or have choke points."
Goal: the squad can flow across the map with real choices, XCOM-style.
- At least 3 distinct routes from entry to prisoner, each at least 3 tiles wide at its narrowest. No single-tile or 2-tile gaps on any main route.
- Spread cover so every ~4 tiles along each route has a half or full cover spot; fewer long open stretches, fewer solid walls.
- High ground reachable from at least 2 ramps; keep the flank idea.
- Shorten the walk: entry to prisoner path at most ~22 steps (now 29).
- Add a map test that measures route count, narrowest width, cover spacing and path length, and fails if the rules above break.
- Keep bot win bands (20 games): Story >=14, Normal 9-12, Hard 4-7, Legend 1-3. Report actual numbers.
Done = ./godot/test.sh 0 failures, no script errors; overview screenshot launching res://scenes/rescue.tscn directly; report written; committed on main.

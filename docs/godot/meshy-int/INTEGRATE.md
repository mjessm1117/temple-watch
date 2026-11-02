# Meshy integration: wire batches 2 + 3 into battle maps (0 credits)
Goal: every battle theme shows its own Meshy cover and objective models in real missions, within the phone budget, with gameplay unchanged.
No Meshy API calls. Do not load the key. Godot 4.7.2 at /home/jess/projects/.tools/godot/godot; run `godot --headless --editor --import --quit` in godot/ first.

Context: read docs/godot/meshy3/MESHY3.md, art/meshy2-LOG.md, art/meshy3a-LOG.md, art/meshy3b-LOG.md, docs/godot/RENDER-UPGRADE.md. Today only the temple uses Meshy (props.json meshy1_models: objective = obj_terminal_v1, half_cover = cover_half_temple_v3; read by map_presentation.gd / map_art_geometry.gd).
Available models (all with _lod1): meshy2/cover_full_dock_v1, cover_half_city_v1, obj_relay_v1; meshy3/cover_full_{temple,ruins,caves,jungle,plains,snow,city}_v1, cover_half_{ruins,caves,plains,snow,dock}_v1, obj_{charge,beacon,restraint}_v1; meshy1/obj_terminal_v1, cover_half_temple_v3.
Gaps: no half cover for jungle (keep the current procedural one). Keep any other gap on its current art.

Output:
1. Data-driven per-theme mapping in props.json (theme → full_cover, half_cover; objective type → model). Map objective models to mission families by what the player does (hack/terminal, relay, sabotage plant charge, evac beacon, rescue restraint). Keep meshy1_enabled as the master switch; missing entry = current art.
2. LOD: LOD0 near, swap to _lod1 at distance with GeometryInstance3D visibility ranges (works on Compatibility renderer). Pick the distance so the default battle camera (~25 units) shows LOD0 on the near half of the board.
3. Placement: one tile, grounded on the tile's real height (wave9 raised tiles), rotate to face the cover direction where the map defines it, else a seeded random 90° turn. Nothing floats, clips through walls, or blocks unit/label readability.
4. Tests: extend map_art tests: every mapped path loads, every theme falls back cleanly when its entry is missing or meshy1_enabled is false, LOD pairs exist, budgets (LOD0 ≤3K cover / ≤4K objective, LOD1 ≤800/≤1K, textures ≤512²).
5. Budget report for the busiest mission per theme: total visible tris and draw calls at the default camera, Compatibility renderer, vs phone budget (≤300K tris, ≤150 draw calls). Unrestricted FPS on this machine.
6. Shots (1920x1080 real window, HUD on), one real mission per theme, default camera + close-up: docs/godot/shots/meshyint-<theme>.png and -<theme>-close.png. Plus one shot per objective model in its mission. Look at every shot; fix anything floating, clipped, too dark or unreadable before finishing.
7. Log: art/meshy-int-LOG.md (mapping table, tris/draw calls, FPS, any model you judged unfit in-game and left unwired, with why).

LEASE: godot/data/maps/props.json, godot/data/maps/provenance.json, godot/scripts/map_presentation.gd, godot/scripts/map_art_geometry.gd, new godot/scripts/meshy_theme_*.gd, map_art test script(s), art/meshy-int-LOG.md, docs/godot/shots/meshyint-*. Do NOT change map layouts, cover values, rules, balance, any .glb, or the web game.

Gates: ./godot/test.sh exit 0, every suite 0 failures, no SCRIPT ERROR/Parse Error/ERROR: lines, Normal rescue bot stays 10/20. Files <600 lines. Commit locally on meshy/integrate. No push, no subagents.

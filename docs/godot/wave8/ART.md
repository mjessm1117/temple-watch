# Wave 8: battle map art pass (read docs/godot/wave7/WAVE7.md common rules first)
Jess (11-01) picked: "battle map art — turn the flat grid and plain blocks into real terrain, ruins, elevation."
Branch wave8/art (worktree ~/projects/tw-wave8/art). First run `godot --headless --editor --import --quit` in godot/ (Godot 4.7.2 at /home/jess/projects/.tools/godot/godot).

LEASE:
- godot/scripts/map_presentation.gd, godot/scripts/env_art.gd, godot/scripts/combat_scene.gd (scene/terrain build parts only), godot/scripts/map_preview.gd
- godot/data/maps/themes.json, godot/data/maps/props.json
- new godot/scripts/map_art_*.gd, new godot/assets/maps/** files, godot/assets/env/**
- new godot/tests/map_art_test.gd (add it to godot/test.sh's suite list; no other test.sh change)
- docs/godot/wave8/art-REPORT.md, docs/godot/shots/wave8-art-*.png
Do NOT change map layouts (godot/data/maps/<map>.json tiles, cover, routes), rules, mission logic, AI or balance. Art reads the map data; it never changes what is walkable, what blocks sight or what gives cover.

Problem (see docs/godot/shots/wave7-final-battle-sabotage.png and wave7-missions-h_husks.png): wave 7 maps render through map_presentation.gd as a flat checkered grid with plain grey boxes; some props float or sit outside the board. The older rescue fixture renderer (env_art.gd, stone shader, wave 3/4 art) looks much better and is now only used by the rescue fixture.

Goal: every one of the 8 themes (dock, city, jungle, snow, temple, ruins, plains, caves) looks like a real place at XCOM 2 readability.
- Ground: themed textured/shaded floor per theme (stone, metal deck, mud/grass, snow, sand, cave rock), subtle per-tile variation, no checkerboard. Keep a faint tactical grid that appears on hover/move, like XCOM.
- Elevation: high-ground tiles become real raised platforms, ledges, ramps and stairs with visible sides, matching the map's height data exactly.
- Cover: half cover and full cover read instantly by silhouette (low walls, crates, rubble, sandbags vs tall walls, pillars, machinery), using the existing glb props in godot/assets/maps and env assets, themed per biome. Destructible cover shows damage states when hit/broken (combat already reports breaks).
- Walls and edges: board edges get a backdrop (cliffs, building facades, hangar walls, tree line, ice ridge) so the map does not end in a void. Out-of-bounds dressing (distant buildings, rocks, trees, ships) fills the horizon but never sits on a playable tile.
- Props: fix every floating / off-board prop. Each prop is grounded on its tile, scaled to the tile, rotated to align with neighbours. Objectives (terminals, relays, charges, prisoners, civilians, evac) get distinct, readable models plus a glow marker.
- Lighting and atmosphere per theme: key + fill light, shadows on, ambient occlusion/SSAO, fog/haze, theme sky colour, light sources from braziers/consoles/lamps, weather (snow, rain, dust, spores) from the existing weather() hook. Must hold ≥60 fps at 1920x1080 on this machine (RTX 4090) for the largest map; report fps.
- Port the good parts of env_art.gd (stone shader, materials) into the shared renderer so the rescue fixture and campaign maps share one look. One renderer, not two.
- Legal: original or CC0 art only, no XCOM assets. Record any new asset source in godot/assets/maps/provenance.json.

Gates:
- ./godot/test.sh exits 0, no failures, no SCRIPT ERROR; bands unchanged (Story ≥14, Normal 9–12, Hard 4–7, Legend 1–3) — art must not move them.
- map_art_test.gd: every map in godot/data/maps/manifest.json builds for its theme without errors; every prop AABB sits inside its tile and on the floor (no floating, no off-board); raised tiles match height data; walkable/cover/LOS data identical before and after the art build; fps sample on the largest map.
- All GDScript files < 600 lines.

Report docs/godot/wave8/art-REPORT.md: what changed per theme, fps numbers, before/after notes, and real-window 1920x1080 screenshots docs/godot/shots/wave8-art-<theme>.png for all 8 themes in battle (HUD visible), plus one close action-cam shot. Then commit locally on wave8/art. No push, no subagents.

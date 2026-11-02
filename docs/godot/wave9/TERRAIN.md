# Wave 9: terrain depth pass (read docs/godot/wave7/WAVE7.md common rules and docs/godot/wave8/art-REPORT.md first)
Jess (11-01): "keep pushing". Wave 8 gave every theme ground, backdrops and grounded props. Review of docs/godot/shots/wave8-art-*.png found three remaining problems:
1. The playable interior still reads flat: mostly one floor level with small scattered boxes.
2. Every map is ringed by the same wall, so maps feel like arenas, not places.
3. Frame pacing: the largest battle only met 60 fps p95 with CPU affinity; unrestricted runs missed.

Branch wave9/terrain (worktree ~/projects/tw-wave9/terrain, base = main). First run `godot --headless --editor --import --quit` in godot/ (Godot 4.7.2 at /home/jess/projects/.tools/godot/godot).

LEASE:
- godot/scripts/map_presentation.gd, map_art_*.gd (existing + new), env_art.gd, map_preview.gd, combat_scene.gd (scene/terrain build parts only)
- godot/data/maps/themes.json, props.json, and godot/data/maps/<map>.json ONLY for the fields `elevation` and `cover`/prop placement (see Goal 1 rules)
- godot/data/maps/balance.json only if Goal 1 moves a family out of band
- godot/assets/maps/**, godot/assets/env/**
- godot/tests/map_art_test.gd (extend), new godot/tests/terrain_test.gd (add to test.sh suite list; no other test.sh change)
- docs/godot/wave9/terrain-REPORT.md, docs/godot/shots/wave9-*.png
No changes to rules, mission logic, AI, combat code, campaign, UI screens. Web game frozen. Local commit only, no push, no subagents. GDScript files < 600 lines.

Goal 1 — real height in the playable area (data + art):
- Every campaign map in manifest.json gets at least 2 elevation tiers in use and ≥15% of walkable tiles raised (0.7 or 1.4), arranged as believable terraces, ledges, catwalks, rock shelves, temple daises, ruined upper floors — per theme. Every raised area reachable by a walkable ramp/stair tile; no route that was walkable becomes unreachable; spawn, objective, evac and entry tiles keep their reachability (path test).
- Replace "small box" cover with bigger themed cover pieces at the same cover values: full cover reads ≥1.8 tall with mass (wall sections, machinery, pillars, hull plates, boulders, tree trunks), half cover 0.7–0.9 (low walls, sandbag lines, planters, crates stacks, fallen columns). Add cover clusters so open lanes get interest, but keep the wave 5 rule: no chokepoints, ≥3 routes ≥3 wide between spawn and objective.
- Non-blocking ground dressing (rubble, debris, decals, grass tufts, puddles, snow drifts, cables) adds variety on walkable tiles without affecting walk/cover/LOS.
- High ground uses the existing elevation rules (no rule change). Re-run bands and the campaign bot after: Story ≥14, Normal 9–12, Hard 4–7, Legend 1–3; all 7 families 30–80% wins on Normal. If out of band, adjust map elevation/cover placement or balance.json, not rules.

Goal 2 — natural edges, no arena ring:
- Remove the uniform perimeter wall. Each theme gets its own edge: dock = hangar walls/landing pad drop-off with ships; city = building facades with alleys; jungle = dense tree line and roots; snow = ice ridges and drifts; temple = colonnades and terraces; ruins = broken walls, collapsed towers; plains = rolling hills and rock outcrops; caves = cave walls and stalagmites. Varied heights, gaps that show distant scenery. Still nothing on a playable tile.

Goal 3 — frame pacing:
- Largest map, 1920x1080, HUD visible, real window, default scheduling (no CPU affinity): mean ≥60 fps and p95 ≤16.7 ms. Use batching/MultiMesh, LODs/visibility ranges, shadow distance, light count limits. Report both mean and p95, with machine load noted.

Gates:
- ./godot/test.sh exits 0, no failures, no SCRIPT ERROR.
- terrain_test.gd: per map — tier counts and raised % meet Goal 1; every raised tile has a ramp-connected path from spawn; spawn/objective/evac/entry reachable; ≥3 routes ≥3 wide; props inside tiles and on their floor; nothing on playable tiles from edge dressing.
- Bands + 7-family campaign bot numbers reported and in range.
- All files < 600 lines.

Report docs/godot/wave9/terrain-REPORT.md: per theme what changed, before/after raised %, bot numbers, fps (mean + p95, unrestricted). Real-window 1920x1080 screenshots docs/godot/shots/wave9-<theme>.png for all 8 themes in battle (HUD visible, default camera) plus wave9-highground.png (soldier on a raised ledge shooting down). Then commit locally on wave9/terrain.

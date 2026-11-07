# W16 lane `jungle`: one more Meshy try at jungle half cover

## Goal
Jess rejected BOTH the old procedural jungle half cover (pale lumpy sandbag stack) and the staged v6 Meshy sandbag wall (`godot/assets/maps/meshy6/cover_half_jungle_v6.glb`). Make ONE new jungle half-cover prop with a different idea, stage it, and produce a before/after sheet. Do NOT wire it into the game — Jess approves the swap after seeing the sheet.

## Design direction (new — not sandbags)
Star Wars jungle-moon ruins (Yavin IV feel, original design, no copyrighted assets): a waist-high toppled carved stone block with a thick fallen tree trunk lying across/against it. Dark weathered grey-green stone, deep brown bark, restrained dark moss in crevices only. Solid, readable "you can hide behind this" silhouette from a high tactics camera. Fits one square tile.
Avoid: yellow, lime green, loose leaves, vines, ferns, bushes, sandbags, crates, base plate, ground plane.

## Context
- Read `docs/godot/meshy6/REPORT.md`, `docs/godot/meshy6/ledger.md`, `docs/godot/meshy6/briefs/jungle-retry.json` first: same pipeline, same harness, same fit rules.
- Tools: `tools/meshy/gen.mjs`, `tools/meshy/prop.mjs` (fit/simplify ≤1,500 tris LOD0, LOD1 ~800), `tools/meshy/contact-sheet.mjs`. Key = MESHY_KEY in /home/jess/hive/.env (never print it).
- Godot binary `/home/jess/projects/.tools/godot/godot`. New worktree: run `godot --headless --import` first.

## Credits (hard limit)
- Budget ~30, HARD CAP 40 credits. Exactly ONE preview (20) then ONE refine (10) only if the preview reads as a solid cover shape. No second preview. Record task IDs + read-only balance before/after in `docs/godot/w16/jungle/ledger.md`.
- If the preview is clearly bad, stop without refining, record it, and report.

## Output
1. `godot/assets/maps/meshy7/cover_half_jungle_v7.glb` + `_lod1.glb` (+ textures/.import), ≤1,500 / ~800 tris, floor-fit, within one tile, displays at 0.8 m like the other half covers.
2. Brief saved to `docs/godot/w16/jungle/brief.json`.
3. Before/after captures in the jungle map at 844x390 Compatibility/Low AND 1366x768: OLD procedural | v6 sandbag | v7 new. Save to `docs/godot/shots/w16-jungle-*.png` and ONE combined sheet `docs/godot/shots/w16-jungle-before-after.jpg` (labelled OLD / V6 / V7).
4. `docs/godot/w16/jungle/REPORT.md`: credits, tris, size, honest read of the result, exact one-line wiring change for later.

## Boundaries / file lease
- May write ONLY: `godot/assets/maps/meshy7/**`, `docs/godot/w16/jungle/**`, `docs/godot/shots/w16-jungle-*`, and a throwaway capture script under `docs/godot/w16/jungle/` (gitignore scratch if large).
- Do NOT edit `map_art_geometry.gd`, `props.json`, `godot/test.sh`, or any game script. Do NOT wire the prop in.
- Gate: headless import exit 0, `./godot/test.sh` exit 0, 0 SCRIPT ERROR, 0 failures, `git diff --check` clean.
- Commit locally on branch `w16/jungle` by 16:45 PT (machine restart tonight). Never push. No subagents.

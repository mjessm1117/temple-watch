# Meshy batch 3: cover for every theme + mission objectives (Jess approved ~1,000 credits, 11-01)
Read first: /home/jess/hive/skills/meshy-art-director/SKILL.md, docs/godot/meshy1/MESHY1.md, docs/godot/meshy2/MESHY2.md, art/LOG.md, art/meshy2-LOG.md (prompt lessons: what scored ≥4, what failed).
Key: `set -a; . /home/jess/hive/.env; set +a` → MESHY_KEY. Never print, log or write it.
Godot 4.7.2 at /home/jess/projects/.tools/godot/godot; run `godot --headless --editor --import --quit` in godot/ first. Reuse tools/meshy (--preview-only, --refine-preview, --submit-only/--resume, prop.mjs UV-aware simplify, contact-sheet.mjs).

Split into two lanes, each in its own worktree/branch. LANE is set in the launch prompt.
- Lane 3a (branch meshy/batch3a, ≤500 credits): full cover for temple, ruins, caves, jungle; half cover for ruins, caves, jungle. (7 assets)
- Lane 3b (branch meshy/batch3b, ≤500 credits): full cover for plains, snow, city; half cover for plains, snow, dock; objectives obj_charge (sabotage plant charge), obj_beacon (evac beacon), obj_restraint (rescue prisoner restraint/stasis cuff pod). (9 assets)
Already done elsewhere, do NOT redo: cover_half_temple (1b), cover_full_dock, cover_half_city, obj_relay (batch 2), obj_terminal (batch 1).

LEASE (generate + review only; integration later):
- art/briefs/<asset>.md/.json, art/meshy3<lane>-LOG.md, art/meshy3/ (raw, gitignored)
- godot/assets/maps/meshy3/<asset>_v1.glb (+ LOD1 + textures)
- new godot/scripts/meshy3<lane>_stage.gd (neutral review stage), docs/godot/shots/meshy3<lane>-*.png
- tools/meshy/* only for small bug fixes
Do NOT touch props.json, provenance.json, map_presentation.gd, themes, any meshy1/meshy2 file, or the other lane's files.

BUDGET per lane: hard cap 500 credits; check /v1/balance before/after (numbers only). Per asset 2 previews + 1 refine (50). Extra previews (20 each) only for an asset with no preview scoring ≥4 silhouette, max 2 per asset. If an asset still fails, stop that asset, log it, move on. Never exceed the cap. No rigging.

Specs (phone budget, docs/godot/RENDER-UPGRADE.md):
- Full cover: 1 tile, ≥1.8 units tall, blocks a standing figure. Half cover: 1 tile, 0.7–0.9 tall, wider than tall.
- Cover: LOD0 ≤3,000 tris, LOD1 ≤800, texture ≤512². Objectives: LOD0 ≤4,000, LOD1 ≤1,000, texture ≤512², emissive accent so they read as "interact here".
- NOT-list for all: no ground plate, no legs/posts/arches on half cover, no vehicles, not glossy/rounded, nothing floating.
- Theme look: match each theme's existing wall_<theme>.glb / door_<theme>.glb palette and the wave9 shots. Style: stylized, chunky, matte, readable at ~25 units. Original Star Wars-inspired; no XCOM/Lucasfilm assets or names.

LESSON from 1b/1c (11-01, corrected): the old preview renderer fit height and width separately, which faked proportions. Meshy's "low wall" B was really 2.1× wider than tall, so at 1 tile wide it is only 0.46 tall (too low); slicing the top made it worse (0.24). Rules: render previews with UNIFORM fit only (fixed in meshy1_preview.gd on meshy/batch1) and report true W:H:D. Half cover target ratio ≈ 1.1–1.4 wide : 1 tall; prompt "compact block about as wide as tall, deep footprint", not "long low wall". If a winner is too wide, trim the SIDES (vertical cuts, cap them) after uniform-fitting by height — never slice the top, never non-uniform scale. See art/LOG.md batch 1c.

Per asset loop: brief → 2 previews (different prompt angles) → render + score 1–5 (silhouette at game distance, style match, cleanliness, poly fit) → refine winner → simplify + LOD1 → place on stage beside the theme's existing wall and a temple column, default battle camera + close-up, 1920x1080 real window.
Shots: meshy3<lane>-previews.png (contact sheet, letters + scores), meshy3<lane>-stage.png, meshy3<lane>-stage-close.png.
Log every task id, credits before/after, scores, tris per LOD, verdict. Losers stay on disk labeled.

Gates: ./godot/test.sh exit 0, no failures, no SCRIPT ERROR. Files <600 lines. Commit locally on the lane branch. No push, no subagents. Web game frozen.

# Meshy batch 2: three more map models (read /home/jess/hive/skills/meshy-art-director/SKILL.md, docs/godot/meshy1/MESHY1.md, art/LOG.md first)
Jess (11-02): "do more models". Batch 1b (temple cover redo) is running in parallel on meshy/batch1 in another worktree — do NOT touch that worktree, art/LOG.md, props.json, provenance.json, map_presentation.gd or any meshy1 file.
Key: `set -a; . /home/jess/hive/.env; set +a` → MESHY_KEY. Never print, log or write it.
Branch meshy/batch2, this worktree. Run `godot --headless --editor --import --quit` in godot/ first (Godot 4.7.2 at /home/jess/projects/.tools/godot/godot). Reuse tools/meshy (--preview-only, --refine-preview, --submit-only/--resume, prop.mjs UV-aware simplify, contact-sheet.mjs).

LEASE (generation + review only; integration happens later after batch 1b merges):
- art/briefs/<asset>.md/.json for the 3 assets below, art/meshy2-LOG.md, art/meshy2/ (raw, gitignored)
- godot/assets/maps/meshy2/** (final GLBs + LODs + textures)
- new godot/scripts/meshy2_stage.gd (neutral review stage), docs/godot/shots/meshy2-*.png
- tools/meshy/* only for small bug fixes

HARD BUDGET: 200 credits. Check /v1/balance before/after (numbers only). Plan: 3 assets × (2 previews + 1 refine) = 150, plus up to 2 extra previews (40) only if an asset has no preview scoring ≥4 silhouette. Stop before exceeding 200. No rigging.

Assets (default battle camera ~25 units + action cam; phone budget per docs/godot/RENDER-UPGRADE.md):
1. `cover_full_dock` — full cover, 1 tile, ≥1.8 units tall: stacked industrial cargo containers/crate stack with straps, square chunky, gunmetal + hazard stripes. NOT rounded/glossy, no vehicle, no ground plate. LOD0 ≤3,000 tris, LOD1 ≤800, texture ≤512².
2. `cover_half_city` — half cover, 1 tile, 0.7–0.9 tall, wider than tall: low durasteel street barrier / planter block, dark violet-grey metal, thin neon strip. NOT posts, legs, arches. Same budgets.
3. `obj_relay` — relay-mission objective: chunky comms relay mast on a squat base, dish or antenna array, emissive cyan status lights, reads as "the thing to interact with". ≤4,000 tris LOD0, LOD1 ≤1,000, texture ≤512².
Style: match the existing temple columns and obj_terminal_v1 (stylized, chunky, matte, readable). Original Star Wars-inspired designs; no XCOM/Lucasfilm assets or names.

Per asset: brief → previews (different prompt angles: silhouette / material / era words) → render + score 1–5 (silhouette at game distance, style match, cleanliness, poly fit) → refine winner only → simplify to budget with LOD1 → place on meshy2_stage.gd beside obj_terminal_v1 and an existing temple column at default battle camera and close-up, 1920x1080 real window.
Shots: docs/godot/shots/meshy2-previews.png (contact sheet, letters + scores), meshy2-stage.png (all 3 finals beside existing assets, game camera), meshy2-stage-close.png.
Log every task id, credits before/after, scores, tris per LOD, verdict in art/meshy2-LOG.md. Losers stay on disk labeled.

Gates: ./godot/test.sh exit 0, no failures, no SCRIPT ERROR. Files <600 lines. Commit locally on meshy/batch2. No push, no subagents. Web game frozen.

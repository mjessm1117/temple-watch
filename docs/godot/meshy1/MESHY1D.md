# Meshy batch 1d: temple half cover by trimming the SIDES of refined B (0 credits)
Read art/LOG.md (batch 1c section) first. Refined B (refine 01a19a9e-621c-737e-85f0-7f16a1df3644, raw in art/meshy1c/) is a good low sandstone wall, but it is 2.1× wider than tall: at 1 tile wide it is only 0.46 tall. The top slice in 1c was wrong. Do the opposite.

ZERO CREDITS: no Meshy API calls at all. Do not load the key. Local geometry only.
Branch meshy/batch1, this worktree. Run `godot --headless --editor --import --quit` in godot/ first.

Steps:
1. Uniform-scale refined B (whole, not the 1c slice) so its height is 0.80 units.
2. Trim the sides with two vertical cuts (the planes facing along the wall's long axis) so the kept piece is 0.95–1.0 units wide, centered on the chunkiest courses, and keep the rubble at the foot only if it lands inside the tile. Cut along block joints where you can so the ends read as broken stone, not a saw cut. Cap the cut faces with nearby stone texture (reuse slice-cover.mjs cap logic; extend it for vertical planes rather than writing a new tool). No holes from the battle camera or action cam.
3. Ground it (min y = 0), keep depth inside the tile. UV-aware simplify: LOD0 ≤3,000 tris, LOD1 ≤800, texture ≤512².
4. Save as godot/assets/maps/meshy1/cover_half_temple_v3.glb (+ _lod1). Keep v1/v2 on disk. Point props.json meshy1_models.half_cover at v3. Terminal untouched.
5. Shots (1920x1080 real window, HUD, same mission/seed/camera as v1 and 1c): docs/godot/shots/meshy1d-cover-after.png, -after-close.png, and docs/godot/shots/meshy1d-trim.png (B whole vs v3, clay + textured, with true uniform W×H×D labels).
6. Append to art/LOG.md (cut positions, final W×H×D, tris per LOD, verdict) and provenance.json (Meshy refine + local trim).

Accept only if: 0.7–0.9 tall, ≤1 tile wide, reads at ~25 units as a chunky low stone wall a soldier crouches behind; not a cannon, not a stub, no holes. Otherwise leave half_cover empty (original cover), log why, stop.

Gates: ./godot/test.sh exit 0, no failures, no SCRIPT ERROR; map_art_test passes. Files <600 lines. Commit locally on meshy/batch1. No push, no subagents. Web game frozen.

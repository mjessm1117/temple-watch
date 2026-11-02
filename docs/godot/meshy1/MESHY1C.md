# Meshy batch 1c: temple half cover by slicing preview B (read MESHY1B.md, art/LOG.md, /home/jess/hive/skills/meshy-art-director/SKILL.md)
1b stopped at the gate: Meshy makes walls as tall as wide. Preview B (task 01a19a97-e98e-77e0-accb-22d5bdc7f98c) has the right look (big chunky sandstone courses, rubble at foot) but wrong proportions. Fix = kitbash: keep the bottom courses, drop the top. Uniform scale only, no squashing.
Key: `set -a; . /home/jess/hive/.env; set +a` → MESHY_KEY. Never print, log or write it.
Branch meshy/batch1, this worktree. Run `godot --headless --editor --import --quit` in godot/ first.

HARD BUDGET: 30 credits. Refine B once (10). Only if the refined texture is broken (smeared, wrong colors, seams at 25u), one more refine of B with a stricter texture prompt (10). No new previews, no rigging. /v1/balance before/after, numbers only.

Steps:
1. Refine preview B (texture prompt: warm matte sandstone, faint geometric carving bands, tiny worn gold trim; enable_pbr false).
2. Slice: cut the refined mesh with a horizontal plane so the kept lower part is ~1.25 wide : 1 tall (about the bottom 2–3 courses, rubble kept). Cut along block tops where possible so the top reads as a broken, uneven course, not a flat saw cut. Close the cut (cap faces using the stone texture or the nearest UVs) — no visible holes from the battle camera or action cam.
3. Fit: uniform scale to 1 tile wide, 0.7–0.9 units tall, grounded (min y = 0), inside the tile footprint. Simplify UV-aware to LOD0 ≤3,000 tris, LOD1 ≤800 tris, texture ≤512².
4. Save as godot/assets/maps/meshy1/cover_half_temple_v2.glb (v1 stays on disk). Point props.json meshy1_models.half_cover at v2. Terminal untouched.
5. Shots (1920x1080 real window, HUD, same camera as v1): docs/godot/shots/meshy1c-cover-after.png, -after-close.png, plus docs/godot/shots/meshy1c-slice.png (refined B whole vs sliced v2 side by side, clay + textured).
6. Append to art/LOG.md (task ids, credits, tris per LOD, slice height, verdict) and provenance.json (Meshy refine + local slice).

If the sliced result still reads as a wall too tall, a cannon, or has visible holes: set half_cover back to the pre-Meshy temple cover (keep the terminal on), log why, and stop.

Gates: ./godot/test.sh exit 0, no failures, no SCRIPT ERROR; map_art_test passes. Files <600 lines. Commit locally on meshy/batch1. No push, no subagents. Web game frozen.

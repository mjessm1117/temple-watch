# Meshy batch 1b: redo temple half cover (read MESHY1.md, art/LOG.md and /home/jess/hive/skills/meshy-art-director/SKILL.md first)
Jess (11-02) picked A: keep obj_terminal_v1 (Terminal B) as is; redo cover_half_temple. The v1 kitbash (fallen column on two block legs) reads like a cannon — rejected.
Key: `set -a; . /home/jess/hive/.env; set +a` → MESHY_KEY. Never print, log or write it.

Same branch meshy/batch1, this worktree. Use the existing tools/meshy tooling (--preview-only, --refine-preview, --submit-only/--resume).

HARD BUDGET: 80 credits (3 previews + 1 refine = 70 expected). Check balance before/after via /v1/balance, log numbers only. No rigging.

New design: `cover_half_temple_v2` — a LOW STACKED STONE WALL with rubble. 1 tile wide, 0.7–0.9 game units tall, wider than tall, flat-ish broken top, 2–3 courses of large carved sandstone blocks, a few fallen blocks/rubble at its foot inside the tile footprint, faint geometric carving and gold-trim hints. NOT: a column, a cannon, legs/supports, an arch, posts, a ground plate, upright shards, anything taller than wide. Matte, stylized, chunky, reads as "low cover" at ~25 units.
- 3 previews (A–C) from different prompt angles; render, look, score 1–5 (silhouette at game distance, style match vs existing temple columns, cleanliness, poly fit). If none scores ≥4 on silhouette, do NOT refine — stop and report.
- Refine only the winner. Simplify ≤3,000 tris LOD0 with UV-aware simplification; also produce LOD1 ≤800 tris (phone budget, see docs/godot/RENDER-UPGRADE.md). Texture ≤512².
- New file godot/assets/maps/meshy1/cover_half_temple_v2.glb (keep v1 on disk). Point the existing meshy1 switch for temple/ruins half cover at v2. Terminal untouched.
- Also check the stray small white squares visible in docs/godot/shots/meshy1-*-after*.png: find their source; if caused by meshy1 integration, fix; if pre-existing (e.g. hover/grid marker), say what they are in the log, don't change.
- Shots (1920x1080 real window, HUD, same camera as v1): docs/godot/shots/meshy1b-cover-after.png and -after-close.png; contact sheet docs/godot/shots/meshy1b-previews.png with letters + scores.
- Append to art/LOG.md (task ids, credits before/after, scores, verdict) and provenance.json.

Gates: ./godot/test.sh exit 0, no failures, no SCRIPT ERROR; map_art_test passes. Files <600 lines. Commit locally on meshy/batch1. No push, no subagents. Web game frozen.

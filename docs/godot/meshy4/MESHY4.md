# Meshy batch 4 — remake the weak models (Jess approved 2026-11-01, ≤300 credits)

## Goal
Replace the 4 models that look bad in-game with ones that read clearly at game distance:
1. `cover_full_temple` — currently reads as flat yellow boxes/cabinet. Want: tall broken temple wall section or a thick column pair with lintel, carved stone, same palette as the existing temple columns.
2. `cover_full_snow` — currently a plain white fridge. Want: tall ice/rock outcrop or a snow-crusted durasteel bulkhead with visible frost, dark rock or metal showing through.
3. `cover_half_snow` — currently a plain white box. Want: low snow-drift over rocks/crates, waist height, wider than tall.
4. `obj_relay` — currently a kiosk/screen on a pole. Want: comms relay mast — lattice tower with dish/antenna, base housing, small blinking light.

## Context (read first)
- Skill: /home/jess/hive/skills/meshy-art-director/SKILL.md — follow it (reference first, cheap previews, render-and-critique, refine only winners).
- Lessons: docs/godot/meshy3/MESHY3.md, docs/godot/meshy3/LANE.md, art/LOG.md. Key ones: preview renders must use UNIFORM fit (non-uniform fit faked proportions in 1c); if a model is too tall, side-trim/rescale, never top-slice.
- Tools: tools/meshy/gen.mjs, prop.mjs. Key is env MESHY_KEY (already set). Never print or commit it.
- Current wiring: godot/data/maps/props.json (theme → model mapping, LOD1 swap). Integration done in 893e4c2.

## Budget / rules
- Hard cap 300 credits total. Log balance before/after. Up to 4 previews per asset; refine only previews scoring ≥4/5 on silhouette. If none ≥4, stop on that asset and report (keep current model).
- Per model: LOD0 ≤3,000 tris, LOD1 ≤800 tris, textures ≤1024. Whole-map budget stays ≤150 draw calls, ≤300K tris (phone).
- Full cover must be visibly taller than half cover; half cover wider than tall.

## Output
- New GLBs in godot/assets/maps/meshy4/ (+ LOD1), raw downloads in art/meshy4/.
- Swap only these 4 entries in godot/data/maps/props.json; accepted ones only.
- In-game before/after screenshots (temple map, snow map, a relay mission) in docs/godot/shots/meshy4-*.png, plus a close-up stage shot per asset next to a reference (temple column).
- Append art/LOG.md + provenance.json (task ids, credits, scores, verdicts). Write docs/godot/meshy4/REPORT.md: per asset accepted/rejected + why, credits, tri counts.
- Commit on branch meshy/batch4. Do not push.

## File lease (may write ONLY these)
art/meshy4/**, art/LOG.md, provenance.json, godot/assets/maps/meshy4/**, godot/data/maps/props.json (the 4 entries), godot/scripts/meshy4_*.gd, docs/godot/meshy4/**, docs/godot/shots/meshy4-*.png, tools/meshy/** (bug fixes only, note them).
Do NOT touch: godot/project.godot, any renderer/lighting/quality/settings script (another lane owns graphics tiers), maps/layouts, balance data, web game files.
If a code change outside the lease is needed, stop and describe it in REPORT.md.

## Done when
`./godot/test.sh` exits 0 with 0 SCRIPT ERROR lines and all suites 0 failures; Normal band unchanged; budgets met; screenshots exist.

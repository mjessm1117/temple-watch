# Meshy batch 5 — snow half + jungle covers (Jess approved 2026-11-02, ≤150 credits)

## Goal
Fix the last 3 weak cover models:
1. `cover_half_snow` — still the plain white box (rejected twice). Want: waist-high snow-crusted rock pile or half-buried supply crates with dark rock/metal showing.
2. `cover_half_jungle` — never accepted (batch 3: no preview ≥4). Want: fallen mossy log on roots, or low vine-covered stone wall.
3. `cover_full_jungle` — current reads pale/washed out. Want: tall massive tree trunk with buttress roots or vine-choked ruined pillar, deep greens and browns.

## Lessons that killed earlier tries (read art/LOG.md + docs/godot/meshy4/REPORT.md)
- Half snow B failed because it was ~2:1 wide; uniform one-tile fit made it only 0.47 high. **Prompt for chunky objects about 1.3–1.6 : 1 width to height** ("compact", "waist-high", "roughly as deep as wide"), and check proportions in the preview before refining.
- Uniform fit only; side-trim if needed, never top-slice or non-uniform scale.
- Pure white/pale textures read as boxes — require dark contrast (rock, wood, metal) in the texture prompt.

## Budget / rules
- Hard cap 150 credits. Log balance before/after (start ≈ 9,625). Previews ≈ 20, refines ≈ 10. Order: half snow, half jungle, full jungle. Max 2 previews per asset first; a 3rd only if budget remains. Refine only previews scoring ≥4/5 on silhouette AND proportion.
- Follow /home/jess/hive/skills/meshy-art-director/SKILL.md. Tools tools/meshy/*. Key env MESHY_KEY — never print or commit.
- LOD0 ≤3,000 tris, LOD1 ≤800, textures ≤1024. Half cover wider than tall, full cover clearly taller than half.

## Output
- GLBs + LOD1 in godot/assets/maps/meshy5/, raw in art/meshy5/. Swap only these 3 props.json entries (accepted ones only; rejected keep current).
- Run Godot import headless before tests. Before/after in-game shots (snow map, jungle map) docs/godot/shots/meshy5-*.png + one stage close-up per asset.
- Append art/LOG.md + provenance.json. docs/godot/meshy5/REPORT.md: accepted/rejected + why, credits, tris.
- `./godot/test.sh` exit 0, 0 SCRIPT ERROR, all suites 0 failures, Normal 10/20. Commit on branch meshy/batch5. Don't push.

## File lease
art/meshy5/**, art/LOG.md, provenance.json, godot/assets/maps/meshy5/**, godot/data/maps/props.json (3 entries), godot/scripts/meshy5_*.gd, docs/godot/meshy5/**, docs/godot/shots/meshy5-*.png, tools/meshy/** (bug fixes only).
Do NOT touch anything else (two other lanes are editing campaign/story/gear code). If something outside the lease is needed, skip that asset and note it.

# Meshy batch 1

Starting balance: 11215. Hard cap: 200 credits. Planned: 8 previews × 20 + 2 refines × 10 = 180. No rigging. Pricing: https://docs.meshy.ai/en/api/pricing (2026-11-01). Live balance checked before/after every task; durable ledger in art/meshy1/ledger.json.

All eight GLBs rendered and visually inspected in neutral clay, close and at ~25 units. Preview meshes are untextured; style scores assess shape. Poly-fit scores assess simplification potential, not current compliance.

| Asset | Letter | Silhouette | Style | Cleanliness | Poly fit | Preview tris | Verdict |
|---|---|---:|---:|---:|---:|---:|---|
| obj_terminal | A | 4 | 4 | 4 | 4 | 7583 | Clear screen, thin dangling cable. |
| obj_terminal | B | 5 | 4 | 4 | 5 | 7339 | Winner: broad recessed screen, sturdy pedestal; fewer small details. |
| obj_terminal | C | 4 | 4 | 3 | 4 | 7511 | Good mass, excessive antenna and framing detail. |
| obj_terminal | D | 2 | 2 | 2 | 3 | 7596 | Distracting torus cable, poor interaction silhouette. |
| cover_half_temple | A | 2 | 2 | 1 | 2 | 8187 | Rejected: upright shards, noisy ground plate. |
| cover_half_temple | B | 2 | 3 | 3 | 3 | 8017 | Rejected: archway with thin posts, loose rocks. |
| cover_half_temple | C | 1 | 2 | 2 | 2 | 7791 | Rejected: whole building and upright columns, wrong scale language. |
| cover_half_temple | D | 3 | 4 | 4 | 4 | 7795 | Winner as kitbash source only: clean chunky masonry. Arch and plate must be removed; add local fallen carved column. |

Cover generation missed the requested fallen column in all four previews. D is selected for technical salvage, not accepted unchanged. Local kitbash will retain generated masonry and supply original carved column geometry; no additional paid previews.

## Credit ledger

| Asset | Letter | Stage | Task id | Before | After submit | Spent |
|---|---|---|---|---:|---:|---:|
| obj_terminal | A | preview | 01a19a41-a239-771f-93c0-3e9fcb3b20bc | 11215 | 11195 | 20 |
| obj_terminal | B | preview | 01a19a42-ca49-73ce-a09c-83bb310df7a2 | 11195 | 11175 | 20 |
| obj_terminal | C | preview | 01a19a43-2465-72f5-a24e-c750b9761ca8 | 11175 | 11155 | 20 |
| obj_terminal | D | preview | 01a19a43-2bc4-75c5-b318-c874a9c4f28e | 11155 | 11135 | 20 |
| cover_half_temple | A | preview | 01a19a43-329a-749a-9cdf-d222c93e9051 | 11135 | 11115 | 20 |
| cover_half_temple | B | preview | 01a19a43-396c-756d-a93b-855e461ece2b | 11115 | 11095 | 20 |
| cover_half_temple | C | preview | 01a19a43-4090-7168-98bc-0b92e1955f48 | 11095 | 11075 | 20 |
| cover_half_temple | D | preview | 01a19a43-481d-74ac-b762-3f0b0894e308 | 11075 | 11055 | 20 |
| obj_terminal | B | refine | 01a19a46-6cc4-726e-9d5d-a75c372ba7ae | 11055 | 11045 | 10 |
| cover_half_temple | D | refine | 01a19a46-73f8-7459-a1de-4083f232cef8 | 11045 | 11035 | 10 |

Final independently checked balance: **11035**; initial **11215**; spent **180/200**. Eight previews, two refines, zero rigging. No retries charged. Polling resumed from saved IDs after moving to submit-first background execution.

## Integration

Terminal B: 3,996 triangles, 512px base color and cyan-only emission. Initial position-only permissive simplification smeared UVs and was rejected after an in-game close-up; replaced with UV-aware simplification.

Cover D: 2,997 triangles. The generated arch and ground plate were removed. Retained masonry is clipped and capped; original local horizontal fluted column, broad end bands, and a geometric carved-stone texture complete the brief. This is a Meshy/local hybrid, not an unmodified successful generation. Footprint 0.98 tile, height 0.8 units.

Both use new versioned GLBs. One-line revert: set `meshy1_enabled` to `false` in `godot/data/maps/props.json`. Only visual presentation routes changed; no rules, movement, cover or LOS logic changed.

All losing previews and raw refines remain labeled under `art/meshy1/` (over 5 MB, gitignored). Committed briefs contain every prompt; this log and provenance retain every task ID. The contact sheet preserves all eight scored renders.

## Final review and validation

Viewed every preview, the labeled contact sheet, and final 1920×1080 real-window battle and close-up captures. Terminal B now reads as a cyan-screen interaction console at game distance; cover D hybrid reads as a low horizontal carved stone barrier beside the existing columns. Taste selection remains reviewable in the retained A–D variants.

`./godot/test.sh`: exit 0; all 15 suites pass, zero failures, no SCRIPT ERROR or ERROR. Final asset-specific recheck: `godot --headless --path godot -s tests/map_art_test.gd`: exit 0, 107716 checks across 62 maps, zero failures. This checks grounded bounds, tile fit, half-cover height, unchanged mission/RNG/walk/cover/LOS state, and no added collisions. Headless tests do not measure GPU FPS.

Screenshots: `docs/godot/shots/meshy1-{obj_terminal,cover_half_temple}-{before,after}.png`, plus matching `-close.png`; same deterministic mission/seed/camera per pair, HUD visible. `meshy1-previews.png` includes all eight letters and scores. Capture harness uses the same data switch per renderer instance; shipped switch stays enabled.

Reproduction: install the existing Meshy tool dependencies locally with `npm install --no-save --package-lock=false @gltf-transform/core @gltf-transform/extensions @gltf-transform/functions meshoptimizer sharp`. `gen.mjs OUT ASSET --preview-only --letter A --brief art/briefs/ASSET.json` creates a preview; `--refine-preview TASK_ID` refines a selected letter. `--submit-only` and `--resume` separate background submission/polling without duplicating paid tasks. Use one ledger writer. Never rerun paid creation for this completed batch.

Local postprocess: `temple-kitbash.mjs` then `prop.mjs ... 3000 --godot` for cover; `prop.mjs ... 4000 --godot --screen-emission` for terminal. Provenance lists source task IDs and hybrid authorship. Web-game paths unchanged; all added/modified text files below 600 lines. No push.

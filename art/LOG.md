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

## Meshy batch 1b — v2 rejected at preview gate (2026-11-01)

Jess rejected v1 as cannon-like and kept Terminal B. New brief: low stacked sandstone wall with tight rubble. Applied `/home/jess/hive/skills/meshy-art-director/SKILL.md`; inspected existing column reference and all three locally rendered clay previews, close and at ~25 units. Raw previews stay labeled in ignored `art/meshy1b/`; exact prompts and scores are committed in `art/briefs/`.

| Letter | Silhouette | Style vs columns | Cleanliness | Poly fit | Preview tris | Verdict |
|---|---:|---:|---:|---:|---:|---|
| A | 2 | 2 | 4 | 3 | 8192 | Rejected: thin upright wall, about eight courses of small bricks; lacks the broad chunky low-cover mass. |
| B | 3 | 3 | 3 | 4 | 8265 | Best alternate but rejected: roughly five to six courses, narrow upright wall silhouette, uneven protruding rubble; not the requested two or three large low courses. |
| C | 1 | 2 | 2 | 2 | 7910 | Rejected: tall architectural facade with repeated arch recesses, broad cap and vertical piers; violates the explicit NOT-list. |

Style scores assess untextured geometry; poly-fit scores estimate simplification potential, not budget compliance. **No silhouette scores >=4: no winner, no refine, no paid retry.** No v2 asset or LODs were produced, no model switch changed, and no new after shots were taken because nothing was integrated. The rejected v1 remains on disk and remains the existing switch target; Terminal B is untouched. This is a stopped art round, not an accepted replacement.

| Letter | Stage | Task id | Before | After | Spent |
|---|---|---|---:|---:|---:|
| A | preview | 01a19a97-e1f2-740e-a2d4-954303ec5755 | 11035 | 11015 | 20 |
| B | preview | 01a19a97-e98e-77e0-accb-22d5bdc7f98c | 11015 | 10995 | 20 |
| C | preview | 01a19a97-f2f1-7358-b7a8-08a3888b3a0d | 10995 | 10975 | 20 |

Independent final `/v1/balance` check: **10975**; initial **11035**; spent **60/80**. Three previews, zero refines, zero rigging. Tool supports per-brief credit and task caps; batch1b cap is 80 with at most three previews and one refine. Durable local ledger: `art/meshy1b/ledger.json`. Contact sheet: `docs/godot/shots/meshy1b-previews.png` (A–C with scores, no winner).

White squares: pre-existing **temple dust particles**, also visible in `meshy1-cover_half_temple-before.png`, not Meshy integration artifacts or hover markers. `godot/data/maps/themes.json` temple `part` selects dust (140 particles, color 16767392); `map_presentation.gd:weather` creates 0.075 × 0.075 untextured billboard QuadMeshes with unshaded material. Left unchanged as requested.

Validation: `./godot/test.sh` exit 0; all 15 suites passed, zero failures and no SCRIPT ERROR or ERROR. `map_art_test` passed (107716 checks across 62 maps). JavaScript syntax checks and `git diff --check` passed. All changed/added text files are below 600 lines. No web-game changes; no push.

## Meshy batch 1c — horizontal slice rejected; pre-Meshy cover restored (2026-11-01)

Applied `/home/jess/hive/skills/meshy-art-director/SKILL.md`. Refined only batch1b B, preview `01a19a97-e98e-77e0-accb-22d5bdc7f98c`, refine `01a19a9e-621c-737e-85f0-7f16a1df3644`. Exact texture prompt: "warm matte sandstone, faint geometric carving bands, tiny worn gold trim"; `enable_pbr: false`. No preview, retry or rigging. Source retained in ignored `art/meshy1c/`; v1 retained unchanged. Refined texture is coherent, though quite orange; no texture retry justified at game distance.

Balance before: **10845**. After submit: **10825**. After completion and independent final `/v1/balance`: **10815**. One refine, nominal task cost **10**; observed account decrease **30/30**, conservatively reserving the entire decrease against this batch. These account-wide numbers do not isolate this task's charge; other Meshy work was present in the environment. No further paid calls were made. Local ledger preserves numeric balances and task ID only, never credentials.

**Root cause of the earlier misleading gate:** `meshy1_preview.gd` fitted vertical height separately from width. B's actual source bounds are 1.897 wide × 0.884 tall × 0.949 deep: already 2.147 times wider than tall. At uniform one-tile fit it is only 0.456 tall. Horizontal slicing can only reduce that height. Fixed the preview fit and added an explicit uniform-fit option to the batch renderer, used for Meshy half cover. Terminal's existing fit and asset remain untouched.

Local `slice-cover.mjs` clips at source **y = 0.020**, **0.462951 above the original minimum**, keeping roughly three bottom courses and the foot rubble. Cut-edge loops are stitched and triangulated into 221 cap triangles; cap UVs sample a small nearby stone-texture region rather than spanning atlas islands. Uniform scale **0.516605438**, min y = 0; output **0.980 × 0.239163 × 0.485231**. UV-aware simplification produced **LOD0 3000**, **LOD1 800** triangles; both textures **512 × 512**. Files: `cover_half_temple_v2.glb` and `cover_half_temple_v2_lod1.glb`, retained as rejected candidates. LOD1 is a separate retained artifact, not wired into runtime because v2 is rejected.

**Verdict: rejected.** Battle and action-camera inspection show ankle-high rubble, failing the required 0.7–0.9 height; the horizontal cap also reads too flat/sawn. No visible cut holes in the inspected views. No nonuniform scale was used to hide this failure. Side trimming would be a different reconstruction, and was not applied without a response to the clarification. Restored the original procedural temple/ruins half cover via empty `meshy1_models.half_cover`; `meshy1_enabled` stays true and Terminal B stays on. The renderer explicitly falls through to pre-Meshy cover when that per-asset path is empty.

Real-window 1920×1080 HUD shots use the same mission, seed and camera as v1. `meshy1c-cover-candidate.png` and `-candidate-close.png` preserve the rejected slice in game; requested `meshy1c-cover-after.png` and `-after-close.png` show the final restored cover. `meshy1c-slice.png` compares whole refined B and sliced v2, clay and textured, with uniform-fit dimensions. The pre-existing white dust squares remain unchanged.

Validation: initial Godot editor import completed before generation. `./godot/test.sh` exit **0**, all **15 suites** passed, zero failures, no SCRIPT ERROR or ERROR. `map_art_test` passed both independently and in the suite: **107718 checks across 62 maps**. Added regression checks ensure uniform fitting preserves the rejected slice's real height and grounded tile bounds. JavaScript syntax and `git diff --check` pass; every added/changed text file is below 600 lines. Web-game paths, v1 GLB and Terminal B GLB unchanged. Local commit only; no push, no subagents.

## Meshy batch 1d — full-height B with side trim accepted (2026-11-01)

**Zero credits, zero Meshy API calls, no key loaded.** Reused whole refined B (`01a19a9e-621c-737e-85f0-7f16a1df3644`) from `art/meshy1c/cover_half_temple_v2.B.raw.glb`, not the rejected horizontal slice. Initial editor import passed using `/home/jess/projects/.tools/godot/godot` because `godot` was not on PATH.

Extended `tools/meshy/slice-cover.mjs` with `--sides minX maxX [height]`, preserving its horizontal mode and boundary-loop/nearby-stone-UV cap logic. Whole-source uniform scale **0.905445478** gives **1.718 × 0.800 × 0.859**. Vertical X cuts at **-0.360 and +0.620** in scaled coordinates retain a 0.980-wide strip around the chunky central courses. This placement aligns the upper right cut near a block joint and keeps the foot rubble within the tile; staggered joints prevent both planes following every course. Rejected the first -0.530/+0.450 placement because it visibly sliced the rubble. No top slicing or nonuniform stretching.

The final trim has **374 cap triangles** before simplification. Planar caps looked sawn in close-up, so cut surfaces and their shared boundary vertices receive shallow inward facets (0.012–0.042 units) with face normals, keeping the boundary sealed and the original course outline. UVs reuse nearby stone atlas samples. Grounded min y is **0**. `prop.mjs --godot` retains UV-aware simplification and 512² PNG textures; the new optional `--simplify-error=.08` lets LOD1 reach its budget (default tolerance unchanged).

| Output | True W × H × D | Triangles | Texture |
|---|---|---:|---|
| v3 LOD0 | 0.977273 × 0.788510 × 0.850067 | 3000 | 512 × 512 |
| v3 LOD1 | 0.963770 × 0.785547 × 0.849862 | 800 | 512 × 512 |

**Verdict: accepted.** Reviewed the final clay/textured comparison, battle view at roughly 25 units, and action-camera close-up: chunky upright sandstone half wall, crouching-cover height, broken ends, no visible cut holes, no cannon silhouette or ankle-high stub. `meshy1_models.half_cover` points to `cover_half_temple_v3.glb`; separate `_lod1.glb` retained. v1/v2 and Terminal B remain untouched.

Shots: `docs/godot/shots/meshy1d-cover-after.png`, `meshy1d-cover-after-close.png`, and `meshy1d-trim.png`. Real 1920×1080 Godot windows, HUD and deterministic fixture mission/seed/cameras copied from v1/1c. Final capture used a fixed-size X11 display after a Wayland window-size assertion interrupted a draft capture. Comparison labels report true uniform W×H×D, with whole B at 0.80 height and v3 at native dimensions. Pre-existing dust is unchanged.

Validation: `./godot/test.sh` exit **0**, all **15 suites** passed, zero failures and no SCRIPT ERROR or ERROR. `map_art_test` passed with the final v3 active, including grounded tile bounds, cover height and unchanged mission/RNG/cover/LOS checks; new checks cover both v3 LOD bounds. JavaScript syntax and `git diff --check` passed. Every added/changed text file is below 600 lines. Web-game files unchanged; no subagents, no push. Local commit on `meshy/batch1`.

## Meshy batch 4 — stopped at lease boundary (2026-11-01)

Applied meshy-art-director; inspected temple column and prior cover reference shots.
Five previews submitted: temple A/B/C and full snow A/B. Starting balance 9885,
final balance 9785, confirmed **100/300 credits**, no refines or rigging. Full snow C
submission was interrupted before task creation; account listing and balance
confirm no charge. All five paid GLBs and uniform-fit close/distance renders are
preserved in art/meshy4. Exact prompts, task IDs, numeric balances and per-preview
scores are in root provenance.json and art/meshy4/{ledger,scores}.json.

Temple A/B/C silhouette scores: 3/2/4. Full snow A/B: 4/3. Temple C and snow A
are provisional silhouette candidates only, not accepted replacements. Half snow
and relay were not generated. All four current mappings remain unchanged.

**Blocker:** relay blinking light cannot survive the current static GLB mesh
extraction/MultiMesh batching path. Runtime animation/material support requires
a change outside the lease. Stopped under Jess's explicit stop-and-report rule;
see docs/godot/meshy4/REPORT.md for evidence and scope needed to resume.

Six before screenshots cover temple fixture, Ilum snow and relay mission. Existing
visible-triangle/total-draw gate passes those scenes; relay total rendered primitives
314940 exceed 300K if all passes/UI are counted. No all-map compliance claim.
`./godot/test.sh`: exit 0, all 15 suites, zero failures and SCRIPT ERROR lines.
Normal/gameplay unchanged. No after screenshots, production LODs, or final stage
shots: this batch is incomplete. Local meshy/batch4 commit only; no push.

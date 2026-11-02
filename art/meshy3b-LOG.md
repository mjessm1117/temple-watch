# Meshy Lane 3b — generation and review

Branch: meshy/batch3b. Hard cap **500 credits**; actual **470**: 19 previews ×20 + 9 refines ×10. Zero rigging. Initial plan 450; snow half cover required one extra preview after A/B failed. No further paid calls. The user explicitly authorized this lane budget. Applied /home/jess/hive/skills/meshy-art-director/SKILL.md with MESHY3.md's two-preview rule, review-only lease and lane-specific logging.

Reviewed wave9 plains, snow, city and dock screenshots before writing briefs. References are the matching shipped walls, doors and temple pillar. City and dock have no wall_city.glb/wall_dock.glb in this checkout; props.json maps both to wall_metal.glb, which the stage uses. Gameplay data and routing remain unchanged.

## Preview review

All 19 original previews rendered in a real Godot window and visually inspected close and at ~25 units, with **uniform scale only**. Shape/style scores are for clay geometry; poly-fit scores estimate simplification potential, not compliance. Ratios below are true source width : height : depth with height normalized to 1.

| Asset | Letter | Silhouette | Style | Clean | Poly fit | Tris | W:H:D | Verdict |
|---|---|---:|---:|---:|---:|---:|---|---|
| cover_full_plains | A | 4 | 4 | 4 | 4 | 7385 | 0.330 / 1.000 / 0.387 | WINNER: solid sandbag tower |
| cover_full_plains | B | 3 | 3 | 4 | 4 | 7033 | 0.451 / 1.000 / 0.502 | Rejected: ground plate |
| cover_full_snow | A | 2 | 3 | 3 | 4 | 7335 | 0.500 / 1.000 / 0.502 | Rejected: open gap and feet |
| cover_full_snow | B | 4 | 4 | 4 | 5 | 6649 | 0.391 / 1.000 / 0.403 | WINNER: solid insulated stack |
| cover_full_city | A | 4 | 4 | 4 | 5 | 7061 | 0.314 / 1.000 / 0.314 | WINNER: solid armored cabinet |
| cover_full_city | B | 4 | 4 | 4 | 5 | 6756 | 0.318 / 1.000 / 0.318 | Alternate: narrow cabinet |
| cover_half_plains | A | 4 | 4 | 4 | 4 | 7931 | 1.358 / 1.000 / 1.358 | WINNER: compact masonry mass |
| cover_half_plains | B | 2 | 3 | 3 | 4 | 7851 | 2.007 / 1.000 / 2.072 | Rejected: ground plate, wide |
| cover_half_snow | A | 2 | 4 | 4 | 4 | 7298 | 2.905 / 1.000 / 2.140 | Rejected: W:H 2.91, too low |
| cover_half_snow | B | 3 | 4 | 5 | 5 | 7567 | 2.012 / 1.000 / 0.996 | Rejected: W:H 2.01, too low |
| cover_half_snow | C | 4 | 4 | 3 | 4 | 7089 | 1.677 / 1.000 / 1.222 | WINNER: remove loose shards |
| cover_half_dock | A | 3 | 4 | 5 | 5 | 7121 | 2.005 / 1.000 / 1.539 | Rejected: W:H 2.01, too low |
| cover_half_dock | B | 4 | 4 | 4 | 4 | 7395 | 1.233 / 1.000 / 1.221 | WINNER: compact cargo block |
| obj_charge | A | 4 | 4 | 4 | 4 | 7721 | 1.322 / 1.000 / 1.114 | WINNER: angled controls |
| obj_charge | B | 4 | 4 | 5 | 5 | 6946 | 1.259 / 1.000 / 0.738 | Alternate: generic case |
| obj_beacon | A | 2 | 2 | 4 | 4 | 7584 | 0.351 / 1.000 / 0.351 | Rejected: round lamp, plate |
| obj_beacon | B | 4 | 4 | 4 | 4 | 7599 | 0.580 / 1.000 / 0.587 | WINNER: armored beacon crown |
| obj_restraint | A | 3 | 2 | 4 | 4 | 7581 | 0.558 / 1.000 / 0.458 | Rejected: rounded pod |
| obj_restraint | B | 4 | 4 | 4 | 4 | 8055 | 0.460 / 1.000 / 0.314 | WINNER: attached paired cuffs |

Snow C is selected **after disclosed local cleanup**: the original contains a solid 4,123-triangle box and four detached shard clusters (762, 752, 728 and 724 triangles). Keeping the largest connected component removes only those four clusters. Clean W:H:D is 1.222 : 1 : 1.222. The cleaned preview was rendered and inspected before refinement; identical cleanup was applied to the refined source. No scaling distortion, side clipping or top slicing was needed. The original, cleaned preview, original refine and cleaned refine are all retained. See meshy3b-snow-clean.png.

Plains half A fits to 0.722 tall within a 0.98 tile footprint. Dock half B fits to 0.795 tall. Full-cover candidates are narrower than one tile (0.58–0.72 wide) and all remain 1.85 tall. These are true dimensions, not independently fitted image proportions.

## Credit ledger

Shared account balances are observations, not lane charges. Lane cost is the sum of only the task IDs below; unrelated account changes are not charged to Lane 3b. The tool checks /v1/balance before and after every paid call and reserves cost in the durable lane ledger before submission.

| Asset | Letter | Mode | Task ID | Before | After submit | Cost |
|---|---|---|---|---:|---:|---:|
| cover_full_plains | A | preview | 01a19aab-87f3-7604-b09f-cb4dc55143d8 | 10555 | 10515 | 20 |
| cover_full_plains | B | preview | 01a19aab-9081-741f-a602-95963f5af207 | 10515 | 10495 | 20 |
| cover_full_snow | A | preview | 01a19aab-98bb-74e9-bfe2-d4718005a3e2 | 10495 | 10475 | 20 |
| cover_full_snow | B | preview | 01a19aab-a0f2-7233-b435-dfb206e0c24f | 10475 | 10455 | 20 |
| cover_full_city | A | preview | 01a19aab-a884-772a-8ea4-173d9b8fcdba | 10455 | 10435 | 20 |
| cover_full_city | B | preview | 01a19aab-b17b-7516-ac25-17c39c2f4098 | 10435 | 10415 | 20 |
| cover_half_plains | A | preview | 01a19aab-b8ec-740c-b058-642c6ded728c | 10415 | 10395 | 20 |
| cover_half_plains | B | preview | 01a19aab-bfec-76de-82e7-2eca76721cb1 | 10395 | 10375 | 20 |
| cover_half_snow | A | preview | 01a19aab-c79d-711f-ae52-27673c1c23ff | 10375 | 10355 | 20 |
| cover_half_snow | B | preview | 01a19aab-d0ff-74e5-84e5-4765a50bc4b9 | 10355 | 10335 | 20 |
| cover_half_dock | A | preview | 01a19aab-e473-73bd-939c-3eed1a16bec2 | 10335 | 10315 | 20 |
| cover_half_dock | B | preview | 01a19aab-ecd5-7501-85b8-724cff476222 | 10315 | 10295 | 20 |
| obj_charge | A | preview | 01a19aab-f587-72f9-b7f2-65025ae9f190 | 10295 | 10275 | 20 |
| obj_charge | B | preview | 01a19aab-fdc3-7230-b87e-f7996f935638 | 10275 | 10255 | 20 |
| obj_beacon | A | preview | 01a19aac-0572-75a3-9f3b-98106f5c66d6 | 10255 | 10235 | 20 |
| obj_beacon | B | preview | 01a19aac-0e4e-7564-8589-f3343962a6bf | 10235 | 10215 | 20 |
| obj_restraint | A | preview | 01a19aac-16c2-75b7-86de-4d21c50a6579 | 10215 | 10195 | 20 |
| obj_restraint | B | preview | 01a19aac-1f4f-7477-b27e-d5d4d2b5bd4c | 10195 | 10175 | 20 |
| cover_half_snow | C | preview | 01a19ab0-9398-7483-aa85-0069a0269eb4 | 10015 | 9995 | 20 |
| cover_full_plains | A | refine | 01a19ab0-9f76-77c3-8665-b2ebe9b22ff4 | 9995 | 9985 | 10 |
| cover_full_snow | B | refine | 01a19ab0-a703-7129-bc18-5774500b0f2d | 9985 | 9975 | 10 |
| cover_full_city | A | refine | 01a19ab0-ae8c-77de-9c79-e485df6fc4a6 | 9975 | 9965 | 10 |
| cover_half_plains | A | refine | 01a19ab0-bbc4-750f-83d9-236ceca11941 | 9965 | 9955 | 10 |
| cover_half_dock | B | refine | 01a19ab0-c447-71e5-a541-3a580340f2cf | 9955 | 9945 | 10 |
| obj_charge | A | refine | 01a19ab0-cb4b-76da-ba09-ca9adbce6a8c | 9945 | 9935 | 10 |
| obj_beacon | B | refine | 01a19ab0-d2ed-7490-a84d-727a7277afd8 | 9935 | 9925 | 10 |
| obj_restraint | B | refine | 01a19ab0-db29-722c-a73d-66ac12f5110c | 9925 | 9915 | 10 |
| cover_half_snow | C | refine | 01a19ab3-5c4c-77d4-9975-925aaeba523a | 9895 | 9885 | 10 |

Initial balance **10555**; final independently checked balance **9885**. Lane spending **470/500**. All 28 tasks succeeded. Concurrent account usage explains the difference between the account delta and lane spending.

## Final geometry and textures

| Asset | LOD | Triangles | Width / height / depth | Texture dimensions |
|---|---:|---:|---|---|
| cover_full_plains | 0 | 2994 | 0.611 / 1.850 / 0.712 | 512×512 |
| cover_full_plains | 1 | 798 | 0.611 / 1.850 / 0.710 | 512×512 |
| cover_full_snow | 0 | 2985 | 0.720 / 1.850 / 0.745 | 512×512 |
| cover_full_snow | 1 | 800 | 0.711 / 1.850 / 0.720 | 512×512 |
| cover_full_city | 0 | 2987 | 0.580 / 1.850 / 0.580 | 512×512 |
| cover_full_city | 1 | 798 | 0.558 / 1.850 / 0.558 | 512×512 |
| cover_half_plains | 0 | 2986 | 0.980 / 0.721 / 0.980 | 512×512 |
| cover_half_plains | 1 | 798 | 0.980 / 0.720 / 0.980 | 512×512 |
| cover_half_snow | 0 | 2999 | 0.977 / 0.800 / 0.977 | 512×512 |
| cover_half_snow | 1 | 799 | 0.977 / 0.800 / 0.972 | 512×512 |
| cover_half_dock | 0 | 2992 | 0.977 / 0.794 / 0.919 | 512×512 |
| cover_half_dock | 1 | 797 | 0.970 / 0.738 / 0.890 | 512×512 |
| obj_charge | 0 | 3997 | 0.980 / 0.740 / 0.825 | 512×512, 512×512 |
| obj_charge | 1 | 996 | 0.980 / 0.729 / 0.820 | 512×512, 512×512 |
| obj_beacon | 0 | 3998 | 0.927 / 1.600 / 0.939 | 512×512, 512×512 |
| obj_beacon | 1 | 1000 | 0.926 / 1.600 / 0.937 | 512×512, 512×512 |
| obj_restraint | 0 | 3999 | 0.736 / 1.599 / 0.501 | 512×512, 512×512 |
| obj_restraint | 1 | 1000 | 0.736 / 1.597 / 0.501 | 512×512, 512×512 |

Every GLB is centered, grounded and within one tile; half-cover height is 0.7–0.9, full-cover height ≥1.8. Simplification can drop tiny upper fittings, notably dock LOD1, while retaining the required cover dimensions. All triangle and texture budgets pass. Separate LOD1 files are supplied for later integration. No collision or runtime routing changes.

Postprocess uses uniform fitting and tools/meshy/prop.mjs UV-aware simplification. Initial simplified textures stretched across seams and were replaced by closest-surface color transfer from the original fitted refine onto 512² per-triangle atlases, at both LODs. This local rebake preserves generated colors; it is not a paid texture retry. Materials use metallic 0 and roughness 0.85. Objectives have nonempty emissive masks at both LODs: cyan controls/cuffs for beacon/restraint, cyan plus amber safety/status accents for charge. Texture names are unique per asset/LOD and contain no spaces. The only shared-tool change sanitizes texture names in prop.mjs.

## Visual verdict and delivery

All final LOD0 assets and the LOD1 panel comparison were visually inspected. Plains full cover reads as a solid stone/sandbag tower; plains half cover as compact masonry with rolled sandbags. Snow assets read as pale insulated containers. City full cover has broad cyan/magenta panel accents on dark armor. Dock half cover has a compact steel mass and hazard marking. Charge has angled controls and amber accents; beacon has a prominent cyan signal/control face; restraint retains paired cuffs and cyan release accents. Generated weathering remains busier than the temple pillar and the full-cover shapes remain narrow; these limitations are visible in the review shots.

The neutral stage uses actual 1920×1080 Wayland windows with Forward+ on the RTX 4090. Battle view matches game FOV 45° and yaw/pitch 0.3/0.8 at ~25 units; close view is a 3×3 panel arrangement with each candidate beside its shipped theme wall and temple column, all uniformly scaled. This is an art review, not a phone GPU performance measurement.

- docs/godot/shots/meshy3b-previews.png: all lettered, scored original previews.
- docs/godot/shots/meshy3b-stage.png: all nine finals at battle camera.
- docs/godot/shots/meshy3b-stage-close.png: nine close comparison panels.
- docs/godot/shots/meshy3b-snow-clean.png: original C versus cleaned C, with true ratios.

Raw previews/refines, losing variants, verdict labels, durable ledger, local processing scripts and LOD1 review remain under ignored art/meshy3/3b/. The raw directory is excluded by its own local .gitignore; no other lane's files or shared ignore settings were changed. Exact prompts and scores are committed in the nine briefs.

## Validation and reproduction

Initial editor import completed before generation. Final editor import and all final stage captures contain no SCRIPT ERROR or ERROR. ./godot/test.sh exits 0: all 15 suites pass with zero failures and no SCRIPT ERROR. The final 18-GLB audit passes triangle caps, ≤512² textures, whitespace-free texture names, grounded tile bounds, required cover heights and nonempty objective emission. Node syntax checks and git diff --check pass. All changed text files are below 600 lines.

```sh
/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/meshy3b_stage.gd
/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/meshy3b_stage.gd -- --close
/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/meshy3b_stage.gd -- --close --lod1
node tools/meshy/contact-sheet.mjs art/meshy3/3b/scores.json art/meshy3/3b docs/godot/shots/meshy3b-previews.png
node art/meshy3/3b/audit.mjs
```

Generation used gen.mjs --preview-only, --refine-preview, --submit-only and --resume with one ledger writer. Do not resubmit completed paid tasks. Local steps: components.mjs (snow only), fit.mjs, prop.mjs, bake.mjs, finalize-materials.mjs. Snow uses letter C.clean for fit.mjs after preserving C.raw.glb. All helper inputs and outputs stay in this lane's raw or final directories.

Committed locally on meshy/batch3b. No push, no subagents, no gameplay integration, and no frozen web-game, meshy1/meshy2 or Lane 3a changes.

# Meshy batch 2 — generation and review

Planned: six previews ×20 + three refines ×10 = 150 credits. Hard cap 200. Up to two extra previews only when no candidate scores ≥4 silhouette. No rigging. Shared account is also used by batch 1b; batch spending is the sum of this ledger’s charged tasks, not the global balance delta. Before/after account balances are recorded numerically.

## Preview review

All six clay previews visually inspected close and at ~25 units, 45° FOV. Style scores assess shape; poly-fit scores assess simplification potential, not current compliance.

| Asset | Letter | Silhouette | Style | Cleanliness | Poly fit | Preview tris | Verdict |
|---|---|---:|---:|---:|---:|---:|---|
| cover_full_dock | A | 4 | 4 | 3 | 4 | 7687 | WINNER |
| cover_full_dock | B | 3 | 2 | 4 | 4 | 7445 | Rejected: wheels |
| cover_half_city | A | 5 | 4 | 5 | 5 | 6417 | WINNER |
| cover_half_city | B | 2 | 3 | 3 | 4 | 7222 | Rejected: feet and arch |
| obj_relay | A | 3 | 3 | 2 | 3 | 7530 | Rejected: thin mast and plate |
| obj_relay | B | 4 | 4 | 4 | 4 | 7628 | WINNER |

Dock A: stacked solid cargo mass, minor edge clutter; B has prohibited wheels. City A: continuous low block; B has feet and arch-shaped recess. Relay B: broad antenna array and squat cabinet; A has a thin fragile mast, plate, and stray geometry. Every asset has a ≥4 silhouette winner; no extra previews authorized or submitted.

## Task ledger

| Asset | Letter | Stage | Task ID | Before | After submit | Batch cost |
|---|---|---|---|---:|---:|---:|
| cover_full_dock | A | preview | 01a19a9b-01ac-73bf-8bf5-c92c895572a9 | 10975 | 10955 | 20 |
| cover_full_dock | B | preview | 01a19a9b-08d1-75ff-b9aa-86b24b19c456 | 10955 | 10935 | 20 |
| cover_half_city | A | preview | 01a19a9b-0fe7-701d-bfb8-96f2a7360d09 | 10935 | 10915 | 20 |
| cover_half_city | B | preview | 01a19a9b-18f3-7650-9221-f76e3ba8049c | 10915 | 10895 | 20 |
| obj_relay | A | preview | 01a19a9b-210d-70db-8d05-8416c06b4ee8 | 10895 | 10875 | 20 |
| obj_relay | B | preview | 01a19a9b-2876-734f-8c67-564fb88d6dfa | 10875 | 10855 | 20 |
| cover_full_dock | A | refine | 01a19a9e-5952-745e-95e8-85eddf1365d9 | 10855 | 10845 | 10 |
| cover_half_city | A | refine | 01a19a9e-60a7-7451-9437-e99d577dd1c2 | 10845 | 10835 | 10 |
| obj_relay | B | refine | 01a19a9e-6801-71d9-82a0-ce321aa17702 | 10835 | 10815 | 10 |

Starting account balance: 10975. Account balance after submissions: 10815. Batch cost: 150/200 (six previews at 20, three refines at 10). Global balance delta is 160: the shared account changed by 10 more than these tasks during the relay submission; this is not charged to this batch’s ledger. No retries, extra previews, or rigging.

## Final assets and local processing

| Asset | LOD0 tris | LOD1 tris | LOD0 size (x/y/z) | LOD1 size (x/y/z) | Texture size |
|---|---:|---:|---|---|---|
| cover_full_dock | 3000 | 795 | 0.983 / 1.849 / 0.998 | 0.979 / 1.849 / 0.981 | 512 × 512 |
| cover_half_city | 2992 | 789 | 1.000 / 0.800 / 0.411 | 0.997 / 0.800 / 0.411 | No textures; solid materials |
| obj_relay | 3995 | 998 | 0.950 / 1.800 / 0.528 | 0.902 / 1.643 / 0.512 | 512 × 512 |

All six GLBs are grounded and fit within one tile. Dock height is 1.85; city height is 0.8. Relay LOD1 removes the thin upper aerial tip (1.643 high versus 1.8 at LOD0); the broad antenna array and interaction cabinet remain. Every triangle and texture cap passes the local audit. Cyan emission is present for city and relay at both LODs (solid emissive material for city; nonempty cyan masks for relay). Metal remains matte (roughness 0.85–0.9, metallic 0).

Source refines were centered in x/z, grounded at y=0, and fitted to brief dimensions before running `prop.mjs --godot --screen-emission`. Explicit LOD1 files are supplied; no game selection or switching was wired. LOD simplification preserves the useful major silhouette but drops tiny fittings.

The initial permissive LOD reduction exposed UV stretching. Rejected intermediate appearances were replaced by local closest-surface texture transfer from the full source onto separate triangle atlases (512²), preserving the generated surface colors without crossing atlas seams. City’s broad generated cyan panel did not survive texture narrowing cleanly. Its final generated mesh instead uses a solid dark violet-grey material plus a locally authored 12-triangle cyan strip, 0.68 × 0.026 × 0.008 units, centered at y=0.43. This avoids the atlas artifacts entirely and adds no texture cost. City is a Meshy geometry/local material-and-strip hybrid; the original refine is retained. These are disclosed local postprocess changes, not another Meshy generation. Helpers and audits remain in ignored `art/meshy2/{fit,bake,city-strip,audit}.mjs`; all raw inputs and alternate previews remain on disk with per-letter verdict files.

Tool fixes are limited to batch-ledger credit accounting on shared accounts, support for three capped refines, configurable contact-sheet input/output, and strict triangle-budget enforcement with progressively relaxed attribute-aware error. The latter refuses to write an over-budget output. The fixed simplifier alone does not guarantee clean textures at aggressive LOD budgets; the rebake above is required for these LOD1s.

Final independent `/v1/balance`: 10815. Initial: 10975. Batch spending: 150/200. Account delta: 160, including the concurrent 10-credit change described above. All nine tasks completed successfully; no further paid requests.

## Review stage and reproduction

`godot/scripts/meshy2_stage.gd` is a neutral standalone review harness. It loads the three finals beside the existing `obj_terminal_v1` and temple pillar, without gameplay integration. Battle view uses the game's 45° FOV and yaw/pitch 0.3/0.8, at ~25 units; close view uses 45° at ~11 units to include all five assets. Both captures use an actual 1920×1080 Wayland window with Forward+ on the RTX 4090. This is a visual check, not a phone FPS benchmark.

```sh
/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/meshy2_stage.gd
/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/meshy2_stage.gd -- --close
/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/meshy2_stage.gd -- --close --lod1
node tools/meshy/contact-sheet.mjs art/meshy2/scores.json art/meshy2 docs/godot/shots/meshy2-previews.png
node art/meshy2/audit.mjs
```

Screenshots: `docs/godot/shots/meshy2-previews.png` (six scored candidates); `meshy2-stage.png` (battle distance); `meshy2-stage-close.png` (all finals and references). Extra LOD1 comparison remains in `art/meshy2/lod1-review.png`. Raw generation can be resumed from the recorded task IDs with `gen.mjs --resume`; do not submit these tasks again.

## Final visual verdict

Dock A: accepted for review as chunky stacked full cover, with visible straps and hazard patches; weathering is denser than the terminal reference. City A: accepted after the disclosed local material/strip correction; low solid mass, violet-grey finish, thin cyan line, no feet or arch. Relay B: accepted as an interaction objective with broad antenna array and cyan controls; LOD1 softens its small markings and drops the upper aerial tip. All LOD0 finals and the deliberately enlarged LOD1 comparison were visually inspected; LOD1 is intended for distance, not action-camera close-ups. No alternate remains silently substituted or deleted.

## Validation and delivery

`./godot/test.sh` exited 0 both before final processing and after asset import: all 15 suites report zero failures; no SCRIPT ERROR or ERROR. Final import and the battle/close/LOD1 review runs also contain no SCRIPT ERROR or ERROR. Existing engine ObjectDB leak warnings in some tests are not new failures. The local six-GLB audit passes triangle caps, ≤512² texture dimensions, tile bounds, grounding, cover heights, and nonempty relay emission. JavaScript syntax checks and `git diff --check` pass.

All changed text files are under 600 lines. Only the batch 2 lease and three small Meshy tool fixes are included. Protected batch 1 files, game routing/data/provenance, and frozen web-game paths are unchanged. Local commit on `meshy/batch2`; no push. Integration remains deferred until batch 1b merges.

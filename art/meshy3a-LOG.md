# Meshy lane 3a — generation and review

Branch `meshy/batch3a`. Seven assigned cover assets only. No integration, rigging, push, or subagents. Applied `/home/jess/hive/skills/meshy-art-director/SKILL.md` with the batch 3 two-preview rule and explicit 500-credit lane authorization.

Planned 350 credits; extra previews only after half-cover A/B silhouette failure. Hard cap 500. Spending is the sum of this lane’s task costs, independent of concurrent account activity. Starting account balance: 10815. Current lane task cost: 460.

## Preview review

Clay previews inspected close and at ~25 units using uniform scale. Scores: silhouette / style / cleanliness / poly-fit. Style assesses geometry before texture; poly-fit predicts reduction suitability, not raw compliance. True source dimensions and width:height:depth ratios are retained below.

| Asset | Letter | S | Style | Clean | Poly | Verdict |
|---|---|---:|---:|---:|---:|---|
| cover_full_temple | A | 3 | 4 | 3 | 4 | Rejected: ground plate |
| cover_full_temple | B | 4 | 4 | 4 | 4 | WINNER: solid monolith |
| cover_full_ruins | A | 3 | 3 | 3 | 4 | Rejected: ground plate |
| cover_full_ruins | B | 4 | 4 | 3 | 4 | WINNER: remove tiny loose chip |
| cover_full_caves | A | 3 | 3 | 3 | 4 | Deep central separation |
| cover_full_caves | B | 4 | 3 | 4 | 4 | WINNER: solid angular mass |
| cover_full_jungle | A | 4 | 4 | 3 | 4 | Alternate: deep seam |
| cover_full_jungle | B | 4 | 4 | 4 | 4 | WINNER: broader solid mass |
| cover_half_ruins | A | 2 | 4 | 4 | 4 | Too wide: fitted height 0.505 |
| cover_half_ruins | B | 3 | 4 | 4 | 4 | Too wide: fitted height 0.624 |
| cover_half_ruins | C | 5 | 4 | 5 | 5 | WINNER: compact solid block |
| cover_half_ruins | D | 4 | 4 | 3 | 4 | Alternate: detached chips |
| cover_half_caves | A | 2 | 3 | 3 | 4 | Too deep: fitted height 0.512 |
| cover_half_caves | B | 2 | 3 | 3 | 4 | Too wide: fitted height 0.472 |
| cover_half_caves | C | 4 | 4 | 4 | 4 | WINNER: compact chunky mass |
| cover_half_caves | D | 2 | 3 | 2 | 4 | Too wide; scattered debris |
| cover_half_jungle | A | 2 | 3 | 3 | 4 | Upright: narrower than tall |
| cover_half_jungle | B | 2 | 3 | 2 | 4 | Too deep; scattered loose rubble |
| cover_half_jungle | C | 2 | 3 | 2 | 4 | Too deep; ground skirt |
| cover_half_jungle | D | 2 | 3 | 2 | 4 | Rejected: ground plate; height 0.584 |

## Source dimensions

| Preview | W × H × D | W:H:D (H=1) | Raw tris |
|---|---|---|---:|
| cover_full_caves.A.preview.glb | 0.703 / 1.900 / 0.700 | 0.370 / 1.000 / 0.369 | 7796 |
| cover_full_caves.B.preview.glb | 0.664 / 1.900 / 0.632 | 0.349 / 1.000 / 0.333 | 7611 |
| cover_full_jungle.A.preview.glb | 0.736 / 1.898 / 0.736 | 0.388 / 1.000 / 0.388 | 7880 |
| cover_full_jungle.B.preview.glb | 0.910 / 1.899 / 0.910 | 0.479 / 1.000 / 0.479 | 7730 |
| cover_full_ruins.A.preview.glb | 0.904 / 1.900 / 0.904 | 0.476 / 1.000 / 0.476 | 7251 |
| cover_full_ruins.B.preview.glb | 0.794 / 1.899 / 0.662 | 0.418 / 1.000 / 0.349 | 7551 |
| cover_full_temple.A.preview.glb | 0.801 / 1.899 / 0.801 | 0.422 / 1.000 / 0.422 | 6313 |
| cover_full_temple.B.preview.glb | 0.979 / 1.899 / 1.030 | 0.515 / 1.000 / 0.542 | 7860 |
| cover_half_caves.A.preview.glb | 1.512 / 0.971 / 1.897 | 1.557 / 1.000 / 1.955 | 7389 |
| cover_half_caves.B.preview.glb | 1.897 / 0.895 / 1.415 | 2.120 / 1.000 / 1.581 | 7574 |
| cover_half_caves.C.preview.glb | 1.899 / 1.447 / 1.898 | 1.313 / 1.000 / 1.312 | 7883 |
| cover_half_caves.D.preview.glb | 1.899 / 1.057 / 1.897 | 1.796 / 1.000 / 1.795 | 7879 |
| cover_half_jungle.A.preview.glb | 1.436 / 1.898 / 1.446 | 0.757 / 1.000 / 0.762 | 7372 |
| cover_half_jungle.B.preview.glb | 1.867 / 0.934 / 1.898 | 2.000 / 1.000 / 2.033 | 8176 |
| cover_half_jungle.C.preview.glb | 1.897 / 0.856 / 1.896 | 2.217 / 1.000 / 2.216 | 7945 |
| cover_half_jungle.D.preview.glb | 1.897 / 1.108 / 1.898 | 1.712 / 1.000 / 1.713 | 8117 |
| cover_half_ruins.A.preview.glb | 1.899 / 0.960 / 1.290 | 1.978 / 1.000 / 1.344 | 8003 |
| cover_half_ruins.B.preview.glb | 1.899 / 1.185 / 1.430 | 1.602 / 1.000 / 1.207 | 7902 |
| cover_half_ruins.C.preview.glb | 1.899 / 1.570 / 1.540 | 1.210 / 1.000 / 0.981 | 8200 |
| cover_half_ruins.D.preview.glb | 1.897 / 1.490 / 1.392 | 1.273 / 1.000 / 0.934 | 8112 |

## Credit ledger

Account balances below are numerical snapshots, not isolated per-lane deductions. The durable ignored ledger is `art/meshy3/raw3a/ledger.json`. No credentials are stored.

| Asset | Letter | Stage | Task ID | Before | After submit | Completion | Cost |
|---|---|---|---|---:|---:|---:|---:|
| cover_full_temple | A | preview | 01a19aab-15c8-7099-aeea-5677e841bc7d | 10815 | 10795 | 10195 | 20 |
| cover_full_temple | B | preview | 01a19aab-1ee2-759c-b534-9344d9ab7bfa | 10795 | 10775 | 10175 | 20 |
| cover_full_ruins | A | preview | 01a19aab-270f-7377-8007-506e2f964b2c | 10775 | 10755 | 10175 | 20 |
| cover_full_ruins | B | preview | 01a19aab-2e5e-72f0-8157-c39d7afa81cd | 10755 | 10735 | 10175 | 20 |
| cover_full_caves | A | preview | 01a19aab-3633-774a-92a9-ae695301d512 | 10735 | 10715 | 10175 | 20 |
| cover_full_caves | B | preview | 01a19aab-3ff5-7382-9663-d9aa09f28099 | 10715 | 10695 | 10175 | 20 |
| cover_full_jungle | A | preview | 01a19aab-48be-75ef-99d9-ee5357ba1a14 | 10695 | 10675 | 10175 | 20 |
| cover_full_jungle | B | preview | 01a19aab-51b9-73fc-a0de-caa23670ef31 | 10675 | 10655 | 10175 | 20 |
| cover_half_ruins | A | preview | 01a19aab-59b9-756e-b70f-5da9dbac3b9b | 10655 | 10635 | 10175 | 20 |
| cover_half_ruins | B | preview | 01a19aab-620f-710e-ae9e-a2c82b08cd11 | 10635 | 10615 | 10175 | 20 |
| cover_half_caves | A | preview | 01a19aab-69a6-7605-84b5-fe28b4704862 | 10615 | 10595 | 10175 | 20 |
| cover_half_caves | B | preview | 01a19aab-7227-7797-b08a-e662038ea071 | 10595 | 10575 | 10175 | 20 |
| cover_half_jungle | A | preview | 01a19aab-7a1e-7682-bc2c-828754b71c12 | 10575 | 10555 | 10175 | 20 |
| cover_half_jungle | B | preview | 01a19aab-83ab-7343-a71b-f076bc14b3ce | 10555 | 10535 | 10175 | 20 |
| cover_full_temple | B | refine | 01a19aae-8d83-756b-9ce9-cb0e9c7942db | 10175 | 10165 | 9915 | 10 |
| cover_full_ruins | B | refine | 01a19aae-98b7-75e0-8864-f938fac38d33 | 10165 | 10155 | 9915 | 10 |
| cover_full_caves | B | refine | 01a19aae-a2c9-732e-b023-0f8073b9199a | 10155 | 10145 | 9915 | 10 |
| cover_full_jungle | B | refine | 01a19aae-aaac-729a-8de4-78200d353ce3 | 10145 | 10145 | 9915 | 10 |
| cover_half_ruins | C | preview | 01a19aae-b46b-749b-8fbf-fd5bd6a38a54 | 10135 | 10115 | 9915 | 20 |
| cover_half_ruins | D | preview | 01a19aae-bbbd-71f9-b95e-c20cf8ecfa25 | 10115 | 10095 | 9915 | 20 |
| cover_half_caves | C | preview | 01a19aae-c37d-77a7-9e4b-c46fcc66ce30 | 10095 | 10075 | 9915 | 20 |
| cover_half_caves | D | preview | 01a19aae-cda2-74fd-9f56-3c5a93882d22 | 10075 | 10055 | 9915 | 20 |
| cover_half_jungle | C | preview | 01a19aae-d74a-7767-abd5-eb2d981047b6 | 10055 | 10035 | 9915 | 20 |
| cover_half_jungle | D | preview | 01a19aae-e1c5-75e5-98b2-cdff162a0b98 | 10035 | 10015 | 9915 | 20 |
| cover_half_ruins | C | refine | 01a19ab2-5b26-75d6-bec8-d8d3b952792b | 9915 | 9905 | 9885 | 10 |
| cover_half_caves | C | refine | 01a19ab2-5fed-768f-8ecc-e3860b4c6572 | 9905 | 9895 | 9885 | 10 |

## Processing and review

Raw inputs, rejected alternatives, helper scripts, and numeric ledger remain under ignored `art/meshy3/`. Brief JSON and this log preserve prompts, scores and task IDs. Final geometry uses uniform fitting only; no top slicing or nonuniform stretching. Tiny disconnected debris is removed using position connectivity across UV seams.

| Final | Triangles | W × H × D | Textures | Pass |
|---|---:|---|---|---|
| cover_full_caves_v1.glb | 3000 | 0.645 / 1.850 / 0.615 | [[512, 512]] | True |
| cover_full_caves_v1_lod1.glb | 800 | 0.645 / 1.850 / 0.615 | [[512, 512]] | True |
| cover_full_jungle_v1.glb | 3000 | 0.887 / 1.850 / 0.887 | [] | True |
| cover_full_jungle_v1_lod1.glb | 800 | 0.886 / 1.850 / 0.886 | [] | True |
| cover_full_ruins_v1.glb | 3000 | 0.692 / 1.850 / 0.691 | [[512, 512]] | True |
| cover_full_ruins_v1_lod1.glb | 800 | 0.692 / 1.850 / 0.691 | [[512, 512]] | True |
| cover_full_temple_v1.glb | 3000 | 0.951 / 1.845 / 1.000 | [[512, 512]] | True |
| cover_full_temple_v1_lod1.glb | 800 | 0.951 / 1.845 / 1.000 | [[512, 512]] | True |
| cover_half_caves_v1.glb | 2992 | 1.000 / 0.762 / 0.999 | [] | True |
| cover_half_caves_v1_lod1.glb | 794 | 0.999 / 0.761 / 0.999 | [] | True |
| cover_half_ruins_v1.glb | 2999 | 0.968 / 0.800 / 0.785 | [[512, 512]] | True |
| cover_half_ruins_v1_lod1.glb | 799 | 0.968 / 0.800 / 0.781 | [[512, 512]] | True |

Neutral stage: `godot/scripts/meshy3a_stage.gd`. Theme groups show wall references, full covers and half covers; temple columns sit behind and to the side so they do not obscure the new cover. Temple wall reference is the existing `wall.glb` (there is no `wall_temple.glb`). Preview camera and reference fitting preserve aspect ratios. Final captures use an actual 1920×1080 Wayland window, Forward+, 45° FOV; battle camera yaw/pitch 0.3/0.8 at ~25 units. Close camera pulls back enough to show all four theme groups.
## Final decisions and local material repairs

- Full temple B: accepted for review. Warm gold/tan monolith with shallow decorative borders; its finish is more gilded than the carved pillar reference. Matte roughness 0.85, metallic 0.
- Full ruins B: accepted. Orange weathered stone stack. Removed the single detached 140-triangle chip before fitting; retained connected source geometry has 7,411 triangles.
- Full caves B: accepted. Dark charcoal angular monolith; its generated violet detail is subtle, and silhouette is intentionally the dominant read.
- Full jungle B: accepted after local material repair. Original generated texture stretched after reduction; a triangle-atlas rebake was also rejected. Final generated mesh uses two locally authored solid matte materials: grey-green stone with a dark green moss cap. No texture cost; no new geometry. Original refine and rejected appearance remain on disk.
- Half ruins C: accepted. Compact orange sandstone block, 0.8 tall, clearly wider than tall. No cuts or nonuniform scale.
- Half caves C: accepted after local material repair. Generated texture produced pale smeared seams after reduction. Final generated mesh uses matte charcoal and a small violet mineral corner, two local solid materials, no texture cost or new geometry. Height about 0.762; no cuts or nonuniform scale.
- Half jungle: **stopped/rejected**. None of A–D reaches silhouette 4. A is upright; B/C are too wide/deep with debris or ground skirts; D has a prohibited ground plate and only 0.584 height at one-tile uniform fit. Two extra previews exhausted. No refine, final GLB, or LOD claimed for this asset.

These two material repairs are Meshy geometry/local-material hybrids, not unchanged successful Meshy textures. No changes to props, provenance, themes, gameplay routing or collisions. The stage uses direct GLB loading; no game integration is enabled.

Total **460/500 credits**: 20 previews ×20 + 6 refines ×10. All 26 tasks succeeded. Final independent account balance **9885**; starting **10815**. The 930 account-wide decrease includes concurrent work and is not this lane’s spending. No additional submissions, retry charges or rigging.

Reproduction: `node tools/meshy/contact-sheet.mjs art/meshy3/scores3a.json art/meshy3/raw3a docs/godot/shots/meshy3a-previews.png`; stage `godot --display-driver wayland --path godot -s scripts/meshy3a_stage.gd`, add `-- --close` or `-- --close --lod1`. Local `art/meshy3/{clean3a,fit3a,jungle_material3a,caves_material3a,audit3a}.mjs` preserve postprocess details. Raw generation uses saved task IDs with `--resume`; do not resubmit paid tasks.

One preview window (ruins C) was compositor-scaled to 1365×768; its retained original PNG was uniformly normalized to 1280×720 for consistent contact-sheet cropping. Geometry fitting remained uniform throughout. The contact sheet contains all 20 lettered, scored previews, with game-distance insets.
## Validation and delivery

`./godot/test.sh` exited **0** both at baseline and after final asset import: all **15 suites** passed with zero failures, no SCRIPT ERROR, Parse Error or ERROR. Final map-art suite: **107718 checks**, zero failures. Final terrain suite: **70576 checks**, zero failures. Existing ObjectDB leak warnings are not new failures. The last material repair and stage layout were additionally imported and rendered without errors.

Independent final audit: **12/12 GLBs pass** triangle caps, ≤512² textures, one-tile x/z bounds, grounding and cover-height limits. No filenames contain spaces. The two final stage PNGs are exactly **1920×1080**. All 20 preview renders, the contact sheet, six LOD0 finals and the enlarged LOD1 comparison were visually inspected. LOD1 retains the major silhouette but visibly softens/chips carved borders and crack detail; intended for distance, not the action-camera close-up. This is not a mobile FPS benchmark.

`git diff --check` and staged lease/text-size checks pass. Every added text file is below 600 lines. Only Lane 3a briefs, log, final assets, review script and three screenshots are committed. Editor-generated untracked UID files outside the lease were removed. No protected files, other-lane assets or frozen web-game files changed. Local commit only on `meshy/batch3a`; no push. Integration remains deferred.

# Meshy batch 5 report

Two of three cover props were accepted. The jungle half cover remains unchanged because neither preview reads as the requested fallen log or low wall. The accepted snow half cover and jungle full cover change visuals only; cover and LOS rules are unchanged.

## Budget and decisions

Starting live balance: **9,625**. Final independent balance: **9,475**. Seven previews at 20 credits and one refine at 10: **150/150 credits**. No rigging or retries. Exact task IDs, prompts, per-task balances and scores are in `provenance.json` and `art/meshy5/`.

| Asset | Decision | Reason | LOD0 / LOD1 tris | Final dimensions W × H × D |
|---|---|---|---:|---|
| Snow half | **Accepted A** | Side-trimmed rock pile is 0.80 high and dark rock faces break up the former plain white box. The refine's generated texture was still nearly white, so local matte rock, ice and snow material groups replaced it. | 2,998 / 800 | 0.980 × 0.798 × 0.980 |
| Jungle half | **Rejected A/B; old mapping kept** | A is an upright stump; B fits 0.562 high and its side-trim trial leaves a box-like wall, flat apron and open boundaries. No refine or production GLB. | — | — |
| Jungle full | **Accepted A** | Compact tree trunk with visible buttress roots and dark brown/green 512² local texture replaces the washed-out pillar. It passes the 1.8 full-cover height gate and is clearly taller than the 0.80 half cover. | 2,999 / 800 | 0.980 × 1.850 × 0.980 |

The snow preview's untouched one-tile fit was only 0.586 high. A uniform 0.719 scale and four capped side cuts brought it to 0.80; no top slice or nonuniform stretching. The full jungle preview was uniformly scaled to 1.85 high and cut on four side planes to fit within one tile. A first 1.446-high uniform-fit candidate failed the map-art full-cover height gate and was discarded before final validation. No accepted texture exceeds 512²; snow uses three matte materials with no texture. The jungle full candidate was locally textured without a paid refine; its Meshy preview geometry is retained apart from uniform fit, side cuts and simplification. The source has open leaf/root boundaries; the side trim capped closed loops and skipped open chains. No visible holes appeared in the reviewed stage angle; this asset adds no collision geometry.

## Preview gate

| Asset | A silhouette / proportion | B silhouette / proportion | C silhouette / proportion |
|---|---|---|---|
| Snow half | **4 / 4 after side trim** (raw proportion 2) | 2 / 1 | 3 / 2 |
| Jungle half | 2 / 4 | 3 / 2 | — |
| Jungle full | **4 / 4** | 3 / 3 | — |

All seven previews were rendered close and at the battle review distance. The snow A side-trim render was scored before its only paid refine. Rejected previews and trim attempts remain labeled in `art/meshy5/`; the rejected jungle stage view is [here](../shots/meshy5-stage-cover_half_jungle-rejected.png).

## In-game review

Same Normal difficulty, seed 17, HUD, 1920×1080 Compatibility renderer and default battle camera per before/after pair: [Ilum before](../shots/meshy5-ilum-before.png) → [after](../shots/meshy5-ilum-after.png), [jungle before](../shots/meshy5-h_roots-before.png) → [after](../shots/meshy5-h_roots-after.png). Close-up views: [snow half](../shots/meshy5-ilum-after-half-close.png), [jungle full](../shots/meshy5-h_roots-after-close.png). Neutral stage close-ups: [snow](../shots/meshy5-stage-cover_half_snow.png), [jungle full](../shots/meshy5-stage-cover_full_jungle.png), [jungle half rejected](../shots/meshy5-stage-cover_half_jungle-rejected.png).

| Map | Visible tris before → after | Total draws before → after |
|---|---:|---:|
| Ilum snow | 100,015 → 100,025 | 97 → 105 |
| h_roots jungle | 190,921 → 192,185 | 105 → 101 |

Both captures remain under 300K visible triangles and 150 draws. llvmpipe FPS is not phone performance evidence.

## Validation

Headless Godot import completed before the final map-art check and full suite. The focused `map_art_test.gd` passed 179,392 checks across 62 maps with 0 failures. `./godot/test.sh` exited **0**: every suite reported **0 failures**, with **0 SCRIPT ERROR**, `ERROR:` or parse-error lines. Normal rescue stayed **10/20 wins (50%)**. `git diff --check` passed. The first 1.446-high jungle candidate failed map art; v3 replaced it, and the final map-art and full suite both passed.

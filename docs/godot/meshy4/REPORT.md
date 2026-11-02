# Meshy batch 4 — final report

The 2026-11-01 tech lead decision replaced the relay blink with a **steady emissive beacon**. Three replacements are integrated; half snow was rejected after final fit review. No batching, renderer, gameplay, map layout, or Normal difficulty code changed.

## Credit ledger

Starting balance **9,885**; balance at resume **9,785**; final balance **9,625**. The original five previews cost 100 credits. This continuation cost **160**: six previews at 20 and four refinements at 10. Total **260/300**, leaving 40 credits under the batch cap and 40 credits above the required 9,585 balance floor. The five paid original previews were reused; full snow C was never submitted or charged. Task IDs and per-task balances are in `art/meshy4/ledger.json` and `provenance.json`.

## Decisions and production assets

| Asset | Decision | Reason | LOD0 / LOD1 tris | Uniform in-game fit W × H × D |
|---|---|---|---:|---:|
| `cover_full_temple` | **Accepted C** | Paired fluted columns and broken lintel read clearly; warm pale sandstone matches the nearby temple columns. | 2,998 / 800 | 0.542 × 1.850 × 0.611 |
| `cover_full_snow` | **Accepted A** | Tall jagged spire has dark charcoal rock across its vertical faces, with white snow and blue ice on ledges. | 3,000 / 800 | 0.996 × 1.850 × 0.953 |
| `cover_half_snow` | **Rejected B; old mapping retained** | The intact dark-rock drift fits only 0.473 high; a 0.72-high side trim creates a flat pale face resembling the original white box. | No production LODs | Candidate: 1.000 × 0.473 × 0.891 |
| `obj_relay` | **Accepted B** | Large dish, open braced mast and base housing read as a relay. A small red amber beacon at the antenna tip has a baked emissive texture and is steady. | 2,938 / 768 | 0.486 × 1.600 × 0.556 |

All accepted production textures are 512² or smaller; the beacon mask is 1². LOD0 and LOD1 are separate GLBs under `godot/assets/maps/meshy4/`. The map batcher uses uniform fit. Snow full cover needed a small capped side trim to reach 1.85 high inside one tile; its dark rock silhouette survives the trim. The half snow winner's natural wide proportions limit its one-tile fit to **0.473** high, below the tested 0.7–0.9 cover band. A uniformly scaled, capped side-trim trial reached 0.72 but its broad pale face recreated the box problem. Both versions were rejected, and the existing half snow mapping remains. No nonuniform scaling or top slicing was used.

## Preview review

Silhouette scores use 1–5 at the close and battle review distances. Only previews scoring at least 4 were refined. Refinement did not guarantee final acceptance.

| Asset | A | B | C | Refined |
|---|---|---|---|---|
| Temple full | 3 — broad facade | 2 — open, thin legs | **4 — clear column pair** | C |
| Snow full | **4 — pointed outcrop** | 3 — architectural slab | Not submitted | A |
| Snow half | 3 — separated boulders | **4 — coherent low mound** | 2 — open center and detached pieces | B, then rejected on fit |
| Relay | 3 — small dish | **4 — dish, mast, base** | 3 — legs dominate | B |

The losing previews remain labeled in `art/meshy4/`. Detailed style, cleanliness, poly-fit scores and reasons are in `scores.json`. No preview scoring below 4 was refined.

## Before → after in the game

All six before and six after captures use seed 17, Normal difficulty, the existing HUD, default battle cameras, 1920×1080 output and the same Godot Compatibility renderer on llvmpipe. The pairs are [temple before](../shots/meshy4-fixture-before.png) → [after](../shots/meshy4-fixture-after.png), [snow before](../shots/meshy4-ilum-before.png) → [after](../shots/meshy4-ilum-after.png), and [relay before](../shots/meshy4-relay-before.png) → [after](../shots/meshy4-relay-after.png). Close camera pairs have the same names with `-close` before `.png`.

| Mission | Visible triangles before → after | Total draws before → after | Visual change |
|---|---:|---:|---|
| Temple fixture | 139,617 → 142,613 | 110 → 110 | Yellow box-like cover replaced by carved column pair. |
| Snow Ilum | 148,727 → 147,715 | 120 → 121 | White full-cover cabinets replaced by dark ice spires; half cover unchanged. |
| Relay | 177,127 → 176,070 | 121 → 122 | Kiosk replaced by dish mast with visible steady red beacon. |

Visible geometry stays below 300K triangles and total draws below 150 in all three captures. Relay's all-pass `total_primitives` counter is **313,883** after, versus **314,940** before, so it remains above 300K if that separate counter is interpreted as the phone triangle budget. The existing capture gate uses visible primitives; this pre-existing distinction is retained here. llvmpipe FPS is not phone performance evidence.

Close-up stage comparisons place each accepted asset beside the existing temple column: [temple](../shots/meshy4-stage-cover_full_temple.png), [full snow](../shots/meshy4-stage-cover_full_snow.png), [relay](../shots/meshy4-stage-obj_relay.png). The [rejected half snow candidate](../shots/meshy4-stage-cover_half_snow-rejected.png) is also preserved.

## Validation

`./godot/test.sh` exited **0**: all 15 suites reported **0 failures**, with **0 SCRIPT ERROR** lines. Map art passed 179,392 checks; the Normal rescue band stayed at 10/20 wins (50%). `git diff --check` passed. The in-game capture script exited 0 with no SCRIPT ERROR. Normal gameplay files and batching code remain unchanged.

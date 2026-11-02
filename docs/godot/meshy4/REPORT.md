# Meshy batch 4 — stopped at file-lease boundary

No replacement is accepted or integrated. All four shipped mappings remain unchanged.

The requested relay needs a **blinking light**. The current runtime in
`godot/scripts/map_art_batch.gd` collects only MeshInstance3D geometry and materials
(`collect`), frees the instantiated GLB scene (`model`), then emits static MultiMeshes
(`flush`). GLB animation players and animated nodes do not survive this path.
`meshy_theme_batch.gd` uses that same static batching for both LODs. A static emissive
texture can supply a bright dot, but cannot supply the requested blink.

Supporting the blink requires a runtime material/animation hook in the presentation
or batching path, outside this lane's lease. No such change was made. The user's
explicit instruction, “If a code change outside the lease is needed, stop and describe
it in REPORT.md,” caused the batch to stop. A follow-up needs either authorization
for that runtime hook coordinated with the graphics lane, or acceptance of a steady
emissive beacon. This is an incomplete art round, not a successful replacement batch.

## Generation and credit accounting

Reference images inspected before submission: `meshyint-temple-close.png` and
`meshy3b-stage-close.png`. Four briefs with exact A/B/C prompts are retained in
`art/meshy4/`, within the lease rather than the skill's default `art/briefs/`.
Planned spend was 280 credits with 20 reserved. Five previews were submitted before
the runtime limitation was found: temple A/B/C and full snow A/B. No refinement,
rigging, or additional submission was authorized by a visual score.

Starting balance: **9,885**. Balance after stopping submissions: **9,785**.
Confirmed spend: **100 / 300 credits**. Full snow C's local SUBMITTING reservation
was interrupted before a task ID; account task listing confirms no C task and the
balance confirms no charge. It must not be counted as a sixth paid task.
All paid task IDs and numeric balances are preserved in `art/meshy4/ledger.json`.
Already-paid downloads are retained for a future continuation; recovery makes only
read-only status/download calls and cannot submit tasks.

| Asset | Verdict | Reason | Production triangle counts |
|---|---|---|---|
| cover_full_temple | Deferred; current retained | Batch stopped before winner/refinement/integration | No new production LODs |
| cover_full_snow | Deferred; current retained | Batch stopped before winner/refinement/integration | No new production LODs |
| cover_half_snow | Not generated; current retained | Batch stopped before submission | No new production LODs |
| obj_relay | Blocked; current retained | Blinking light requires out-of-lease runtime support | No new production LODs |

No model is assigned an acceptance score without visual inspection. No paid refine
was made. No nonuniform scale or top slicing was used. Normal gameplay data,
settings, renderer, lighting and map layouts are unchanged.

## Evidence and limitations

The capture harness preserves deterministic seed 17, Normal difficulty, default
battle cameras and existing HUD. Before shots cover the temple fixture, snow Ilum
map and relay mission, with close views. No after shots or final stage comparisons
are claimed because no asset was integrated. Baseline counters are recorded in
`art/meshy4/budgets-before.json`; llvmpipe software rendering is not phone FPS evidence.
The final validation results and preview recovery status are appended below.

## Recovered preview review

All five paid previews completed and were downloaded and visually inspected in
uniform-fit close and ~25-unit clay renders. Scores are provisional geometry review;
style does not assess missing textures and poly-fit is a simplification estimate.

| Preview | Silhouette | Style | Clean | Poly fit | Raw triangles | Reason |
|---|---:|---:|---:|---:|---:|---|
| cover_full_temple A | 3 | 4 | 3 | 3 | 7520 | Carved pilasters read as temple stone, but broad facade and doorway-like recess weaken full-cover mass. |
| cover_full_temple B | 2 | 4 | 2 | 3 | 7690 | Open colonnade and thin legs; poor solid-cover silhouette. |
| cover_full_temple C | 4 | 4 | 3 | 3 | 6633 | Tall paired fluted columns and broken lintel read clearly; top debris and open centre require final fit review. |
| cover_full_snow A | 4 | 4 | 3 | 4 | 8135 | Pointed irregular rock cluster reads as an outcrop at distance; needs dark rock versus snow texture separation. |
| cover_full_snow B | 3 | 3 | 3 | 4 | 7753 | Strong vertical slab but flat split crown and broad foot remain too architectural. |

Temple C and snow A clear the preliminary silhouette threshold, but are **not
accepted or refined** because the batch stopped at the lease boundary. All other
previews fail that threshold. No further paid work is running.

Baseline visible geometry: temple 139,617 triangles / 110 total draws; snow
148,727 / 120; relay 177,127 / 121. The existing capture gate uses visible triangles
and total draws. Relay total rendered primitives are 314,940 (including other passes
and UI), above 300K if that counter is interpreted as the budget. This pre-existing
difference is recorded rather than claiming all-map budget compliance.

## Validation

`./godot/test.sh` exited **0**: all 15 suites passed, zero failures, zero SCRIPT ERROR
lines. Normal band/gameplay files are unchanged. Six before screenshots and five
uniform-fit preview renders exist. `git diff --check` passed. No production LODs,
after screenshots or final reference stage shots were produced; completion gates
are therefore **not met**. Godot editor-generated untracked UID sidecars were
removed after validation to preserve the lease. No tool bug fixes were needed.

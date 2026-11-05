# Meshy batch 6 — staged half-cover review

Seven refined candidates are staged under `godot/assets/maps/meshy6/`. No shipped prop path or renderer was changed. The seven `_lod1.glb` companions contain 786–800 triangles. Captures use each theme's mission board at the battle camera, with the shipped prop on the left and v6 on the right. The [contact sheet](../shots/meshy6-before-after.jpg) has desktop and phone comparisons for all seven themes, old above v6.

The table gives native GLB width × depth and height in metres, old → v6. The map-art loader and the A/B harness floor-fit and display half cover at **0.8 m**, so the small native-height differences do not change cover or line of sight. All staged v6 footprints stay within one tile and all LOD0 meshes stay at or below 1,500 triangles. Measurements are from `original-measure.log`, `staged-measure.log`, and `measure-city-refit.log`; the procedural jungle stack is estimated from its construction in `map_art_geometry.gd`.

| Theme | Credits | V6 triangles | Footprint old → v6 (m) | Height old → v6 (m) | Visual gate | Later wiring change |
|---|---:|---:|---|---|---|---|
| Temple | 70 | 1,494 | 0.98×0.79 → 0.96×0.95 | 0.85 → 0.80 | **Pass** — broken orange rock mound loses the slab outline; slight base lip remains. | `godot/data/maps/props.json:25`: point `half_cover` to `res://assets/maps/meshy6/cover_half_temple_v6.glb`. |
| Dock | 70 | 1,499 | 0.98×0.79 → 0.96×0.96 | 0.92 → 0.78 | **Pass** — pale salvage heap has a broken top and no repeated cuboids. | `godot/data/maps/props.json:52`: replace `half_cover` with `res://assets/maps/meshy6/cover_half_dock_v6.glb`. |
| Plains | 50 | 1,500 | 0.98×0.72 → 0.94×0.86 | 0.98 → 0.79 | **Pass** — loose light fieldstones read as an uneven mound at both sizes. | `godot/data/maps/props.json:40`: replace `half_cover` with `res://assets/maps/meshy6/cover_half_plains_v6.glb`. |
| City | 70 | 1,478 | 1.00×0.80 → 0.89×0.96 | 0.41 → 0.80 | **Pass** — dark torn machinery has an irregular outline and matches the city palette. The interrupted fit was corrected and both city captures were redone. | `godot/data/maps/props.json:48`: replace `half_cover` with `res://assets/maps/meshy6/cover_half_city_v6.glb`. |
| Ruins | 50 | 1,500 | 0.97×0.80 → 0.95×0.95 | 0.78 → 0.80 | **Pass** — orange fragmented rubble replaces repeated upright bricks. | `godot/data/maps/props.json:29`: replace `half_cover` with `res://assets/maps/meshy6/cover_half_ruins_v6.glb`. |
| Caves | 50 | 1,500 | 1.00×0.76 → 0.96×0.46 | 1.00 → 0.80 | **Pass** — narrow purple rock cluster breaks the flat square face; it is visibly slimmer than the old mass. | `godot/data/maps/props.json:33`: replace `half_cover` with `res://assets/maps/meshy6/cover_half_caves_v6.glb`; review the old-path material lift at line 75. |
| Jungle | 50 | 1,475 | about 0.92×0.61 → 0.96×0.92 | about 0.8 → 0.78 | **Fail** — the v6 silhouette is irregular, but the yellow fragmented mass reads as plant debris rather than a bag stack at desktop or phone size. Leave it staged only. | If a future candidate passes, replace the nine-bag loop in `godot/scripts/map_art_geometry.gd:137-140` with a model call for `res://assets/maps/meshy6/cover_half_jungle_v6.glb`, scoped to jungle so the Plains/Snow fallback remains. |

## Spend and provenance

Read-only starting balance: **15,150**. Seventeen previews and seven successful refines cost **410/490 authorized credits**. Last observed balance: **14,740**. The exact 24 task IDs, variants and balances are in [ledger.md](ledger.md); selected preview critiques are in [preview-review.md](preview-review.md). No further Meshy generation was submitted after those refines.

## Validation

Godot headless import passed after the restart and again after correcting the city fit. The capture script is excluded from Web export by `godot/export_presets.cfg`. All 14 PNG captures returned save code 0. `./godot/test.sh` exited **0**: every suite reported **0 failures**, with **0 SCRIPT ERROR** and **0 ERROR** lines; Normal rescue was **9/20**. `git diff --check` and `git diff --cached --check` were clean. The full output is in `gate-test.log`.

# Godot Meshy model audit — Blender 1

## Result

No shipped GLB needs a safe cleanup. No `_v2.glb` was exported or swapped into gameplay. The 13 apparent `Icosphere` helpers exist only in Blender's import-only `glTF_not_exported` collection. All 13 source GLBs have one mesh and no Icosphere node or mesh. The scan counted the actual model triangles after excluding Blender's helper. The only off-center flag, `sithHeavy`, comes from its evaluated animation pose: its rest mesh is centered (X −0.460 to +0.460 m; Y −0.383 to +0.383 m), while the posed bounds are X −0.355 to +0.415 m and Y −0.245 to +0.507 m. Moving the pivot would displace the animated figure.

`map_art_batch.gd:61-82` computes complete mesh bounds, scales props to requested size, and subtracts the horizontal center and minimum Y from their placement. `meshy2_stage.gd`, `meshy3b_stage.gd`, `meshy4_stage.gd`, and `meshy5_stage.gd` use the same AABB floor and center offset for staged props. `combat_scene.gd:47-51` loads the battle assets; `unit_view.gd:20-26` scales units without an origin offset. Unit rest geometry is centered on its origin at foot level; small negative values in the scan come from evaluated poses. `models/props` is loaded to a cache, but its `_instance_model` helper has no call site; active map props use the `assets/maps` copies. Galaxy and UI shuttle/airtaxi assets are flying vehicles, so floor alignment does not apply.

The 97-row scan is current: every GLB under `godot/assets` is represented, and no source GLB is newer than the scan. `res://../art/meshy1c` is referenced by legacy review scripts but absent in this worktree. No other GLB folder was found. No decimation was applied.

## Evidence

- [Scan](scan.csv): 97 models; 47 unflagged, 37 floor flags, 13 import-only helper flags (one also has a posed pivot flag).
- Battle-camera baseline captures: [units 1366×768](../shots/blender1-units-1366x768.png), [props 1366×768](../shots/blender1-props-1366x768.png), [units 844×390](../shots/blender1-units-844x390.png), [props 844×390](../shots/blender1-props-844x390.png). There is no valid v2 target for an after comparison, so no before/after pair or preview sheet was fabricated.
- Web PCK: 65,037,544 bytes before the Web exclude filter; 65,035,628 bytes after (−1,916 bytes). `assets/models_v2/**` and the test-only capture script are excluded. No v2 model bytes were added. The before pack included the capture script; the after pack does not.
- Godot import: exit 0. Full test and diff gate results recorded below.

## Model decisions

Bounds are width × depth × height and minimum Z in metres, as measured by Blender's evaluated mesh scan. “After” equals “before” because no model was modified.

| Model | Flag / decision | Tris before → after | Bounds before → after (m) |
|---|---|---:|---|
| `galaxy/shuttle.glb` | not standing on floor: Flying vehicle; centered origin intentional | 6360 → 6360 | 1.895 × 1.559 × 0.485; base -0.243 → same |
| `loadout/models/heavy.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10351 → 10351 | 0.845 × 0.797 × 1.771; base -0.084 → same |
| `loadout/models/jedi.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10323 → 10323 | 0.664 × 0.664 × 1.724; base -0.05 → same |
| `loadout/models/medic.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10411 → 10411 | 0.64 × 0.663 × 1.625; base -0.034 → same |
| `loadout/models/scout.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10411 → 10411 | 0.787 × 0.643 × 1.675; base -0.016 → same |
| `loadout/models/trooper.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10305 → 10305 | 0.692 × 0.655 × 1.672; base -0.029 → same |
| `maps/airtaxi.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 4351 → 4351 | 1.899 × 1.737 × 1.025; base -0.515 → same |
| `maps/barrel.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2997 → 2997 | 1.209 × 1.207 × 1.899; base -0.951 → same |
| `maps/brazier.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3000 → 3000 | 1.883 × 1.496 × 1.417; base -0.713 → same |
| `maps/console.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2820 → 2820 | 1.504 × 1.49 × 1.898; base -0.95 → same |
| `maps/container.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2136 → 2136 | 1.9 × 1.273 × 0.966; base -0.484 → same |
| `maps/crate.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2947 → 2947 | 1.898 × 1.897 × 1.868; base -0.935 → same |
| `maps/door_caves.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3005 → 3005 | 1.291 × 1.04 × 1.899; base -0.951 → same |
| `maps/door_city.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 1499 → 1499 | 0.983 × 0.266 × 1.9; base -0.951 → same |
| `maps/door_dock.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3136 → 3136 | 1.898 × 1.257 × 1.198; base -0.598 → same |
| `maps/door_jungle.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2831 → 2831 | 1.163 × 0.702 × 1.899; base -0.951 → same |
| `maps/door_plains.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3353 → 3353 | 1.426 × 0.896 × 1.897; base -0.95 → same |
| `maps/door_ruins.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3890 → 3890 | 1.898 × 1.039 × 1.115; base -0.562 → same |
| `maps/door_snow.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3341 → 3341 | 1.549 × 1.51 × 1.896; base -0.951 → same |
| `maps/door_temple.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3178 → 3178 | 1.899 × 0.987 × 1.899; base -0.95 → same |
| `maps/gantry.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 8164 → 8164 | 0.638 × 0.591 × 1.896; base -0.947 → same |
| `maps/meshy1/cover_half_temple_v1.glb` | None: No issue; leave | 2997 → 2997 | 0.96 × 0.49 × 0.8; base 0.0 → same |
| `maps/meshy1/cover_half_temple_v2.glb` | None: No issue; leave | 3000 → 3000 | 0.98 × 0.484 × 0.239; base 0.0 → same |
| `maps/meshy1/cover_half_temple_v2_lod1.glb` | None: No issue; leave | 800 → 800 | 0.98 × 0.481 × 0.239; base 0.0 → same |
| `maps/meshy1/cover_half_temple_v3.glb` | None: No issue; leave | 3000 → 3000 | 0.977 × 0.85 × 0.789; base 0.0 → same |
| `maps/meshy1/cover_half_temple_v3_lod1.glb` | None: No issue; leave | 800 → 800 | 0.964 × 0.85 × 0.786; base 0.0 → same |
| `maps/meshy1/obj_terminal_v1.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3996 → 3996 | 1.232 × 0.967 × 1.899; base -0.95 → same |
| `maps/meshy2/cover_full_dock_v1.glb` | None: No issue; leave | 3000 → 3000 | 0.983 × 0.998 × 1.849; base 0.0 → same |
| `maps/meshy2/cover_full_dock_v1_lod1.glb` | None: No issue; leave | 795 → 795 | 0.979 × 0.981 × 1.849; base 0.0 → same |
| `maps/meshy2/cover_half_city_v1.glb` | None: No issue; leave | 2992 → 2992 | 1.0 × 0.411 × 0.8; base 0.0 → same |
| `maps/meshy2/cover_half_city_v1_lod1.glb` | None: No issue; leave | 789 → 789 | 0.997 × 0.411 × 0.8; base 0.0 → same |
| `maps/meshy2/obj_relay_v1.glb` | None: No issue; leave | 3995 → 3995 | 0.95 × 0.528 × 1.8; base 0.0 → same |
| `maps/meshy2/obj_relay_v1_lod1.glb` | None: No issue; leave | 998 → 998 | 0.902 × 0.512 × 1.643; base 0.0 → same |
| `maps/meshy3/cover_full_caves_v1.glb` | None: No issue; leave | 3000 → 3000 | 0.645 × 0.615 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_caves_v1_lod1.glb` | None: No issue; leave | 800 → 800 | 0.645 × 0.615 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_city_v1.glb` | None: No issue; leave | 2987 → 2987 | 0.58 × 0.58 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_city_v1_lod1.glb` | None: No issue; leave | 798 → 798 | 0.558 × 0.558 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_jungle_v1.glb` | None: No issue; leave | 3000 → 3000 | 0.887 × 0.887 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_jungle_v1_lod1.glb` | None: No issue; leave | 797 → 797 | 0.886 × 0.886 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_plains_v1.glb` | None: No issue; leave | 2994 → 2994 | 0.611 × 0.712 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_plains_v1_lod1.glb` | None: No issue; leave | 798 → 798 | 0.611 × 0.71 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_ruins_v1.glb` | None: No issue; leave | 3000 → 3000 | 0.692 × 0.691 × 1.85; base -0.0 → same |
| `maps/meshy3/cover_full_ruins_v1_lod1.glb` | None: No issue; leave | 800 → 800 | 0.692 × 0.691 × 1.85; base -0.0 → same |
| `maps/meshy3/cover_full_snow_v1.glb` | None: No issue; leave | 2985 → 2985 | 0.72 × 0.745 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_snow_v1_lod1.glb` | None: No issue; leave | 800 → 800 | 0.711 × 0.72 × 1.85; base 0.0 → same |
| `maps/meshy3/cover_full_temple_v1.glb` | None: No issue; leave | 3000 → 3000 | 0.951 × 1.0 × 1.845; base 0.0 → same |
| `maps/meshy3/cover_full_temple_v1_lod1.glb` | None: No issue; leave | 800 → 800 | 0.951 × 1.0 × 1.845; base 0.0 → same |
| `maps/meshy3/cover_half_caves_v1.glb` | None: No issue; leave | 2992 → 2992 | 1.0 × 0.999 × 0.762; base 0.0 → same |
| `maps/meshy3/cover_half_caves_v1_lod1.glb` | None: No issue; leave | 791 → 791 | 0.999 × 0.999 × 0.761; base 0.0 → same |
| `maps/meshy3/cover_half_dock_v1.glb` | None: No issue; leave | 2992 → 2992 | 0.977 × 0.919 × 0.794; base 0.0 → same |
| `maps/meshy3/cover_half_dock_v1_lod1.glb` | None: No issue; leave | 797 → 797 | 0.97 × 0.89 × 0.738; base 0.001 → same |
| `maps/meshy3/cover_half_plains_v1.glb` | None: No issue; leave | 2986 → 2986 | 0.98 × 0.98 × 0.721; base 0.0 → same |
| `maps/meshy3/cover_half_plains_v1_lod1.glb` | None: No issue; leave | 798 → 798 | 0.98 × 0.98 × 0.72; base 0.0 → same |
| `maps/meshy3/cover_half_ruins_v1.glb` | None: No issue; leave | 2999 → 2999 | 0.968 × 0.785 × 0.8; base 0.0 → same |
| `maps/meshy3/cover_half_ruins_v1_lod1.glb` | None: No issue; leave | 799 → 799 | 0.968 × 0.781 × 0.8; base 0.0 → same |
| `maps/meshy3/cover_half_snow_v1.glb` | None: No issue; leave | 2999 → 2999 | 0.977 × 0.977 × 0.8; base 0.0 → same |
| `maps/meshy3/cover_half_snow_v1_lod1.glb` | None: No issue; leave | 799 → 799 | 0.977 × 0.972 × 0.8; base 0.0 → same |
| `maps/meshy3/obj_beacon_v1.glb` | None: No issue; leave | 3998 → 3998 | 0.927 × 0.939 × 1.6; base 0.0 → same |
| `maps/meshy3/obj_beacon_v1_lod1.glb` | None: No issue; leave | 1000 → 1000 | 0.926 × 0.937 × 1.6; base 0.0 → same |
| `maps/meshy3/obj_charge_v1.glb` | None: No issue; leave | 3997 → 3997 | 0.98 × 0.825 × 0.74; base 0.001 → same |
| `maps/meshy3/obj_charge_v1_lod1.glb` | None: No issue; leave | 996 → 996 | 0.98 × 0.82 × 0.729; base 0.005 → same |
| `maps/meshy3/obj_restraint_v1.glb` | None: No issue; leave | 3999 → 3999 | 0.736 × 0.501 × 1.599; base 0.001 → same |
| `maps/meshy3/obj_restraint_v1_lod1.glb` | None: No issue; leave | 1000 → 1000 | 0.736 × 0.501 × 1.597; base 0.001 → same |
| `maps/meshy4/cover_full_snow_v1.glb` | None: No issue; leave | 3000 → 3000 | 0.996 × 0.953 × 1.85; base 0.0 → same |
| `maps/meshy4/cover_full_snow_v1_lod1.glb` | None: No issue; leave | 800 → 800 | 0.972 × 0.924 × 1.85; base 0.0 → same |
| `maps/meshy4/cover_full_temple_v1.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2998 → 2998 | 0.556 × 0.627 × 1.899; base -0.951 → same |
| `maps/meshy4/cover_full_temple_v1_lod1.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 800 → 800 | 0.556 × 0.627 × 1.898; base -0.951 → same |
| `maps/meshy4/obj_relay_v1.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2936 → 2936 | 0.568 × 0.67 × 1.928; base -0.951 → same |
| `maps/meshy4/obj_relay_v1_lod1.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 748 → 748 | 0.553 × 0.664 × 1.928; base -0.951 → same |
| `maps/meshy5/cover_full_jungle_v3.glb` | None: No issue; leave | 2999 → 2999 | 0.98 × 0.98 × 1.85; base 0.0 → same |
| `maps/meshy5/cover_full_jungle_v3_lod1.glb` | None: No issue; leave | 799 → 799 | 0.98 × 0.98 × 1.85; base 0.0 → same |
| `maps/meshy5/cover_half_snow_v1.glb` | None: No issue; leave | 2998 → 2998 | 0.98 × 0.98 × 0.798; base 0.0 → same |
| `maps/meshy5/cover_half_snow_v1_lod1.glb` | None: No issue; leave | 800 → 800 | 0.98 × 0.98 × 0.781; base 0.0 → same |
| `maps/pillar.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2997 → 2997 | 0.593 × 0.59 × 1.9; base -0.951 → same |
| `maps/relay.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 8890 → 8890 | 0.562 × 0.562 × 1.897; base -0.951 → same |
| `maps/rubble.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2551 → 2551 | 1.827 × 1.847 × 0.589; base -0.304 → same |
| `maps/shuttle.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 6360 → 6360 | 1.895 × 1.559 × 0.485; base -0.243 → same |
| `maps/statue.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 7999 → 7999 | 0.683 × 0.668 × 1.898; base -0.951 → same |
| `maps/terminal.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2993 → 2993 | 0.343 × 0.343 × 1.898; base -0.951 → same |
| `maps/wall.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2991 → 2991 | 1.584 × 0.649 × 1.898; base -0.95 → same |
| `maps/wall_caves.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3828 → 3828 | 1.848 × 1.251 × 1.032; base -0.517 → same |
| `maps/wall_jungle.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3670 → 3670 | 1.68 × 1.893 × 0.93; base -0.467 → same |
| `maps/wall_metal.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2883 → 2883 | 1.892 × 1.627 × 0.894; base -0.449 → same |
| `maps/wall_plains.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 2782 → 2782 | 1.877 × 0.944 × 0.886; base -0.444 → same |
| `maps/wall_ruins.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3258 → 3258 | 1.898 × 1.898 × 1.256; base -0.629 → same |
| `maps/wall_snow.glb` | not standing on floor: Map/stage AABB floor offset; leave origin | 3212 → 3212 | 1.781 × 1.806 × 0.695; base -0.348 → same |
| `models/props/crate.glb` | not standing on floor: Cache copy unused; active map copy AABB offset; leave | 2947 → 2947 | 1.898 × 1.897 × 1.868; base -0.935 → same |
| `models/props/terminal.glb` | not standing on floor: Cache copy unused; active map copy AABB offset; leave | 2993 → 2993 | 0.343 × 0.343 × 1.898; base -0.951 → same |
| `models/units/agent.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 11997 → 11997 | 0.717 × 0.648 × 1.696; base -0.025 → same |
| `models/units/jedi.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10323 → 10323 | 0.664 × 0.664 × 1.724; base -0.05 → same |
| `models/units/scout.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10411 → 10411 | 0.787 × 0.643 × 1.675; base -0.016 → same |
| `models/units/sithHeavy.glb` | stray helper mesh; pivot off-center: Blender import-only Icosphere; leave GLB; posed bounds, rest pivot centered | 10244 → 10244 | 0.771 × 0.752 × 1.656; base -0.067 → same |
| `models/units/trooper.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10305 → 10305 | 0.692 × 0.655 × 1.672; base -0.029 → same |
| `temple/human.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 13743 → 13743 | 0.756 × 0.693 × 1.781; base -0.0 → same |
| `ui/airtaxi.glb` | not standing on floor: Flying vehicle; centered origin intentional | 4351 → 4351 | 1.899 × 1.737 × 1.025; base -0.515 → same |
| `ui/jedi.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10323 → 10323 | 0.664 × 0.664 × 1.724; base -0.05 → same |
| `ui/scout.glb` | stray helper mesh: Blender import-only Icosphere; leave GLB | 10411 → 10411 | 0.787 × 0.643 × 1.675; base -0.016 → same |

## Gates

`godot --headless --path godot --import`: exit 0 before and after the audit. `./godot/test.sh`: exit 0; 39 suite-result lines with 0 failures; 0 `SCRIPT ERROR`, `Parse Error`, or `ERROR:` lines. Normal rescue bot 9/20 wins, within the established 9–11/20 band (`docs/godot/wave11/COMMON.md`). Map art: 179,470 checks, 0 failures. `git diff --check`: clean. No shipped gameplay script or existing GLB changed. Local commit only; no push.

# Wave 8 — battle map art

Branch: `wave8/art`. Original procedural art and existing repository GLBs; no XCOM assets or external downloads. Map layouts, mission/rule/AI/balance files are unchanged.

## Shared renderer

`map_presentation.gd` now renders the rescue fixture and every campaign biome. `env_art.gd` is a two-line compatibility subclass, rather than a second renderer. The Wave 3/4 stone shader, weathered materials, terrace edging, arcade, banners and lamp ideas are adapted into the shared builder. Stone normal-map values are corrected to the texture's 0–1 encoding.

| Feature | Result | Implementation |
|---|---|---|
| Themed ground | Adapted | Original world-space stone, deck, earth/grass, snow, sand and cave shaders; irregular grain, subdued tile variation, broad material patches. No alternating checkerboard. |
| Tactical grid | Adapted | Faint movement-range borders reuse the HUD's exact generated range and colors in one MultiMesh. Local grid appears around hover; action camera hides the range grid. No path or AP calculations changed. |
| Elevation | Adapted | Tile centers/platform tops are exactly `Shot.elevation × 0.7`: 0, 0.7, 1.4. Visible foundations, caps and risers; stairs and industrial ramps cut into the raised tile's edge, staying within its footprint. |
| Cover silhouettes | Adapted | Full cover remains at least 1.8 units tall, including boundary tiles; half cover is 0.7–0.9 units tall. Masonry, crates, consoles, sandbags, pillars and rock vary by biome. |
| Destruction | Adapted | Nonbreaking HP loss projects black crack/scorch decals onto the prop surface without requiring a terrain revision. Existing full→half→rubble transitions rebuild the correct silhouette. Existing combat chunk effects remain. |
| Grounded props | Fixed | GLB hierarchy transforms are included once, rotated before fitting, centered horizontally and grounded by their actual transformed AABB. Neighbor runs determine cardinal alignment. |
| Objectives | Adapted | Terminals/screens, relay equipment, barrel/charge assemblies, cuffed prisoners and civilian figures have distinct silhouettes and gold/cyan rings. Completed interactions change marker color; escorts follow their existing mission position. Evac reads `spec.evac`, including the legacy fixture. |
| Horizon/edges | Adapted | Facades, arcades, ships, layered ridges and trees live outside the rule board. Foreground dressing stays lower. Tests inspect individual scenery mesh bounds, not a misleading merged perimeter AABB. |
| Atmosphere | Adapted | Theme key and fill, key shadows, SSAO, ACES, glow, sky and haze; local console/brazier/lamp/crystal lights. Existing weather hook supplies rain, snow, dust, fireflies/spores, pollen and embers. |
| Asset licensing | Preserved | Original procedural geometry/shader sources are recorded in `godot/assets/maps/provenance.json`; existing Meshy-generated asset attribution is retained. |

Imported static meshes and procedural pieces are batched by mesh/material. Repeated perimeter architecture is inexpensive native geometry. The scene builder installs a prisoner position anchor so the shared figure replaces the old plain cube without changing figure synchronization or mission logic.

## Themes and screenshots

All images are actual Vulkan Forward+ window framebuffer captures at **1920×1080**, on the existing X11/Xwayland desktop, with the battle HUD visible. They are not mockups or headless renders. `map_preview.gd` now opens the actual combat scene rather than the old capsule inspection scene. No campaign save is loaded or written.

| Theme | Ground, cover and setting | Battle screenshot |
|---|---|---|
| Dock | Brushed deck plates/tread, metal facade ribs, cargo crates, ramps, gantries, shuttle and skyline; cool fill and dust. | [sabotage](../shots/wave8-art-dock.png) |
| City | Weathered pavement, consoles and metal cover, illuminated building windows, lamps and airtaxi; rain. | [envoy](../shots/wave8-art-city.png) |
| Jungle | Mud and muted grass patches, ground tufts, sandbags, mossy masonry, layered broadleaf tree line; drifting fireflies/spores. | [h_grove](../shots/wave8-art-jungle.png) |
| Snow | Wind-shaped snow and blue ice, snow-capped rock cover, ice ridge and pines; snowfall and restrained exposure. | [ilum](../shots/wave8-art-snow.png) |
| Temple | Warm worn stone, low masonry and tall columns, terrace stairs, arcade, banners, statues and braziers. | [rescue fixture](../shots/wave8-art-temple.png) |
| Ruins | Sand ripples, stone fragments, damaged masonry, weathered colonnade, distant rock ridge and warm dust. | [archive](../shots/wave8-art-ruins.png) |
| Plains | Dry earth/grass, tufts, sandbags and rock cover; layered tree line and pollen. | [relay](../shots/wave8-art-plains.png) |
| Caves | Cool gray rock, faceted outcrops, masonry remnants, stalagmites, blue crystals and warm braziers; ember motes. | [h_husks](../shots/wave8-art-caves.png) |

[Close action-camera view](../shots/wave8-art-action-cam.png): the existing combat camera frames units at their unchanged map positions. The capture does not teleport actors or alter the layout.

Before: [Wave 7 sabotage](../shots/wave7-final-battle-sabotage.png) had a permanent checkerboard, nearly flat elevation, lowered boundary cover and randomly placed scenery. [Wave 7 caves](../shots/wave7-missions-h_husks.png) used the separate inspection UI. After: continuous biome surfaces, raised supports with access details, readable cover heights, grounded objective models, and deliberate perimeter scenery are visible through the actual battle HUD. The rescue fixture shares these same materials and construction rules.

## Validation

- Required first editor import completed with Godot **4.7.2** (`/home/jess/projects/.tools/godot/godot`).
- `./godot/test.sh`: full suite passed with zero failures and no `SCRIPT ERROR` or `ERROR:`. Final run: **14 suites, 141,662 checks**, including **139,035 art checks**.
- Baseline and post-change bot wins are identical: **Story 20/20, Normal 10/20, Hard 4/20, Legend 1/20**, within the required bands.
- `map_art_test.gd` builds **62 layouts**: all 47 manifest missions, all 14 web variants, and the temple rescue fixture. It checks every rendered floor height, prop grounding/footprint, full/half cover height, and each outside scenery component. Eight themes are exercised.
- Mission/spec/board/HP/objective/unit/RNG snapshots compare byte-for-byte before and after rendering. Walkability, elevation, directional cover and LOS queries also compare before/after for every tile.
- Independent prop fitting tests cover eight imported models at all four cardinal rotations plus an oblique angle. Damage tests exercise hit, cracked and broken states. Grid tests verify the existing HUD nodes remain intact while the batched display follows additions/removals.
- Every GDScript in the project is below 600 lines. `test.sh` changes only by adding `map_art_test` to its suite list.

## Performance

Hardware: **NVIDIA GeForce RTX 4090 Laptop GPU**, NVIDIA driver 595.99.02, Vulkan Forward+, 1920×1080, VSync disabled. Largest map: **cache, 34×34 / 1,156 tiles** (discovered from the manifest). FPS uses elapsed wall time between real process frames after warmup (3 seconds for terrain; 10 seconds for the full-battle harness); p95/p99 are frame times, not FPS. The headless suite explicitly skips GPU timing rather than reporting fictitious headless FPS.

| Largest map measurement | Frames | Mean FPS | p95 frame | p99 frame | Result |
|---|---:|---:|---:|---:|---|
| Shared renderer, CPU affinity 0–7 | 600 | **115.8** | **14.70 ms** | **15.75 ms** | Pass: mean ≥60 and p95 ≤16.67 ms |
| Full battle + HUD, CPU affinity 0–7, 10-second warmup | 1,200 | **127.1** | **16.73 ms** | **17.66 ms** | Average passes; p95 narrowly misses 16.67 ms |
| Full battle + HUD, same settings, repeat | 1,200 | **131.7** | **16.66 ms** | **17.30 ms** | **Pass**, 139 draw calls; very little p95 headroom |
| Full battle + HUD, CPU affinity 0–7, 2-second warmup, renewed CPU contention | 1,200 | 71.2 | 44.34 ms | 73.17 ms | Average passes; sustained frame-time target does not |
| Full battle + HUD, unrestricted scheduling, 2-second warmup, concurrent work | 1,200 | 123.2 | 19.57 ms | 28.50 ms | Average passes; sustained frame-time target does not |
| Full battle + HUD, unrestricted scheduling, 10-second warmup | 1,200 | 96.6 | 21.55 ms | 23.31 ms | Average passes; p95 fails; system CPU averaged 33.1%, peaked at 49.7% |

The passing renderer run used `taskset -c 0-7`: four physical performance cores and their SMT siblings on this hybrid CPU. This changes only the benchmark process's scheduling; it does not change game settings or other processes. **Both the terrain-only sample and the complete-battle repeat pass mean ≥60 FPS and p95 ≤16.67 ms with this affinity. The full-battle margin is narrow: the preceding identical run missed p95 by 0.06 ms. Unrestricted scheduling under concurrent load did not pass.**

Concurrent runs were visibly CPU-contention affected: unrelated Godot jobs occupied approximately 80–96% of every logical CPU. Those processes were not changed or stopped. Their high frame-time tails are not used as proof of sustained 60 FPS. The benchmark checks both average ≥60 FPS and p95 ≤16.67 ms.

Reproduce from repository root (use the desktop session's existing `DISPLAY` and `XAUTHORITY`):

```bash
./godot/test.sh
/home/jess/projects/.tools/godot/godot --path godot --display-driver x11 \
  --rendering-method forward_plus --resolution 1920x1080 --borderless \
  -s scripts/map_preview.gd -- --all
taskset -c 0-7 /home/jess/projects/.tools/godot/godot --path godot --display-driver x11 \
  --rendering-method forward_plus --resolution 1920x1080 --borderless \
  -s tests/map_art_test.gd -- --fps
taskset -c 0-7 /home/jess/projects/.tools/godot/godot --path godot --display-driver x11 \
  --rendering-method forward_plus --resolution 1920x1080 --borderless \
  -s scripts/map_preview.gd -- cache --fps --benchmark
```

## Integration requests

No code integration is required. The shared renderer, grid adapter, fixture compatibility entry point and damage refresh are connected inside the leased scene/terrain setup. No layout, rule, AI, balance or mission change is required.

**Performance qualification:** the passing full-battle measurement uses the documented CPU affinity. Repeat the unrestricted full-battle benchmark on an otherwise idle desktop before claiming the same frame pacing under default scheduling. No other process, global scheduler setting or persistent game preference was changed.

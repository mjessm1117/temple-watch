# Blender 2 — phone models and blocky prop quote

## Decision

Nine staged `_v2.glb` copies are ready for review; no loader was switched. Five battle units meet 5,000 triangles. Relay and shuttle meet 1,500. Gantry and statue failed that first target and pass only at gentler 4,082 and 3,999 triangles. All nine retain their battle-camera silhouette at 844×390 in the final paired captures. Phone target is Compatibility/GLES3, Low tier, 60 fps; no device frame rate was measured here.

## LODs already shipped

All 97 original GLB `.import` files set `meshes/generate_lods=true` (106/106 including the nine staged copies). Godot therefore generates lower mesh levels during import; the source triangle count is the top level, not necessarily the triangles rasterized for distant meshes. Battle sets `mesh_lod_threshold=4.0`; graphics settings multiply it by 3 on Low (12), 1.5 on Medium (6), and 1 on High (4). Godot chooses imported mesh LOD by projected size, so the exact level changes with camera distance and viewport size.

Meshy covers and objectives that have explicit `_lod1.glb` siblings use a separate distance switch: Low displays LOD1 at every distance; Medium switches at 0.6× the configured range; High at the full range. The default range is 26 units, subject to the map-size adjustment in `map_presentation.gd`. Unpaired models, including the five units and these four props, use their imported mesh LODs on all three tiers. This is why the v2 source reduction still matters for close phone views and import size.

## Model results

Every row has a four-view [preview comparison](previews/) and two live rescue-scene A/B captures at [1366×768](../shots/) and [844×390](../shots/). The captures place original left and v2 right, at the battle camera, with the same Low/Compatibility renderer. UVs, one texture/material per model, and each unit’s skin and 29 original animation clip names were retained; `verify.log` records the GLB checks. Godot also loaded 29 clips per staged unit (`animation-audit.log`). Blender’s export initially duplicated some action entries, so `verify_glb.py` retained exactly the original named clips.

| Model | Tris before → v2 | Result | Visual reason | Evidence |
|---|---:|---|---|---|
| `models/units/agent.glb` | 11,997 → 4,925 | Pass | Pass; face, armor and pose read the same at phone size. | [sheet](previews/agent-compare.png), [desktop](../shots/blender2-agent-1366x768.png), [phone](../shots/blender2-agent-844x390.png) |
| `models/units/jedi.glb` | 10,323 → 4,925 | Pass | Pass; robe and saber silhouette hold. | [sheet](previews/jedi-compare.png), [desktop](../shots/blender2-jedi-1366x768.png), [phone](../shots/blender2-jedi-844x390.png) |
| `models/units/scout.glb` | 10,411 → 4,925 | Pass | Pass; gear and body outline hold. | [sheet](previews/scout-compare.png), [desktop](../shots/blender2-scout-1366x768.png), [phone](../shots/blender2-scout-844x390.png) |
| `models/units/sithHeavy.glb` | 10,244 → 4,925 | Pass | Pass; armor silhouette holds. | [sheet](previews/sithHeavy-compare.png), [desktop](../shots/blender2-sithHeavy-1366x768.png), [phone](../shots/blender2-sithHeavy-844x390.png) |
| `models/units/trooper.glb` | 10,305 → 4,925 | Pass | Pass; helmet and armor read the same; small glove detail loss only in close preview. | [sheet](previews/trooper-compare.png), [desktop](../shots/blender2-trooper-1366x768.png), [phone](../shots/blender2-trooper-844x390.png) |
| `maps/relay.glb` | 8,890 → 1,477 | Pass | Pass; antenna and dish silhouette hold. | [sheet](previews/relay-compare.png), [desktop](../shots/blender2-relay-1366x768.png), [phone](../shots/blender2-relay-844x390.png) |
| `maps/gantry.glb` | 8,164 → 4,082 | Pass | Pass after 1,477-triangle version failed: bracing became a box. At 4,082, cross-bracing is visible. | [sheet](previews/gantry-compare.png), [desktop](../shots/blender2-gantry-1366x768.png), [phone](../shots/blender2-gantry-844x390.png) |
| `maps/statue.glb` | 7,999 → 3,999 | Pass | Pass after 1,477-triangle version failed: robe and face fragmented. At 3,999, carved outline holds. | [sheet](previews/statue-compare.png), [desktop](../shots/blender2-statue-1366x768.png), [phone](../shots/blender2-statue-844x390.png) |
| `maps/shuttle.glb` | 6,360 → 1,477 | Pass | Pass; wings, nose and tail remain legible. | [sheet](previews/shuttle-compare.png), [desktop](../shots/blender2-shuttle-1366x768.png), [phone](../shots/blender2-shuttle-844x390.png) |

## Savings

For a representative eight-figure fight (four troopers, two scouts, one Jedi, one Sith Heavy) with four temple statues, these selected meshes total **114,605 → 55,396 triangles**, saving **59,209 (51.7%)**. This is a model-instance estimate for that stated mix; it excludes terrain, other props, imported distance LOD selection, and overdraw. The nine distinct source meshes total 84,693 → 35,660 triangles; see the per-model table for exact counts.

Temporary Web PCK export, with identical project content except the nine originals replaced in an isolated export copy: **65,039,632 → 63,764,436 bytes**, a **1,275,196-byte (1.96%) decrease**. The staged `models_v2` folder remains excluded by the existing Web preset. No production source file or export preset was swapped. Raw staged GLBs are larger in aggregate (13,339,508 → 21,614,604 bytes) because Blender rewrote animation data; the measured Godot export packs imported resources differently. `export-base.log` and `export-swap.log` retain export evidence.

## Blocky props for a separate Meshy round

The [eight-theme battle-camera contact sheet](../shots/blender2-blocky-props.jpg) uses the same rescue board and camera while rebuilding art for each theme. Rank reflects how plainly rectangular the prop reads at this distance, not triangle count. The snow half-cover replacement already accepted in Meshy batch 5 is visible but omitted from the paid shortlist.

| Rank | Prop / current file | Themes seen | Why it reads as a box | Base quote |
|---:|---|---|---|---:|
| 1 | Orange rock pile — `godot/assets/maps/meshy1/cover_half_temple_v3.glb` | Temple | Layered slabs form a bright rectangular block with flat top and sides. | 50 |
| 2 | Pale half cover — `godot/assets/maps/meshy3/cover_half_dock_v1.glb` | Dock | Repeated white tile-sized cuboids dominate the board. | 50 |
| 3 | Dry stone half cover — `godot/assets/maps/meshy3/cover_half_plains_v1.glb` | Plains | Squared white stacks have a level top and regular footprint. | 50 |
| 4 | City half cover — `godot/assets/maps/meshy2/cover_half_city_v1.glb` | City | Dark rectangular crates show little silhouette variation. | 50 |
| 5 | Ruins half cover — `godot/assets/maps/meshy3/cover_half_ruins_v1.glb` | Ruins | Orange masonry reads as repeated upright bricks. | 50 |
| 6 | Cave half cover — `godot/assets/maps/meshy3/cover_half_caves_v1.glb` | Caves | Purple stone masses have flat faces and square footprints. | 50 |
| 7 | Procedural bag stack — `godot/scripts/map_art_geometry.gd:138-140` | Jungle (also a fallback in Plains/Snow) | Nine aligned oval bags form a regular rectangular stack. | 50 |

**Credit quote:** `art/LOG.md` records 20 per preview and 10 per refine in batches 1, 4 and 5; failed previews are charged, and earlier ledgers show no extra retry fee apart from another preview/refine task. Planning case: two previews plus one refine per prop = **50 each, 350 total**. Range: one preview plus one refine to three previews plus one refine = **30–70 each, 210–490 total**. A charged extra preview adds 20. No Meshy generation endpoint was called. Read-only `GET /openapi/v1/balance` with the key from `/home/jess/hive/.env` returned **15,150 credits** on 2026-11-04; this shared balance can change.

## Gates

`godot --headless --path godot --import` passed before work and after final GLB edits using `/home/jess/projects/.tools/godot/godot` (the `godot` alias is absent here). `./godot/test.sh` exited 0: 39 suite result lines with 0 failures, 0 `SCRIPT ERROR`, `Parse Error`, or `ERROR:` lines; Normal rescue was 9/20, inside its 9–11 band. `git diff --check` passed. No Meshy credits spent; no swap-in or push.

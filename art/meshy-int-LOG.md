# Meshy integration — batches 2 + 3

Local branch: `meshy/integrate`. **0 credits**, no Meshy requests, no key loaded, no push or subagents. Godot **4.7.2.stable.official.ed1daf0bf** was imported before work. Only the integration lease is changed; source GLBs, layouts, cover values, rules, balance and web files are unchanged.

## Mapping

`props.json` drives theme cover selection and objective action routing. `meshy1_enabled` gates all Meshy art, including the retained terminal. An absent theme/slot or absent model/LOD pair uses the existing fallback. Explicit barrels, consoles, rubble and unmapped operation steps retain their existing art.

| Theme | Full cover | Half cover |
|---|---|---|
| temple | meshy3/cover_full_temple_v1.glb | meshy1/cover_half_temple_v3.glb |
| ruins | meshy3/cover_full_ruins_v1.glb | meshy3/cover_half_ruins_v1.glb |
| caves | meshy3/cover_full_caves_v1.glb | meshy3/cover_half_caves_v1.glb |
| jungle | meshy3/cover_full_jungle_v1.glb | procedural (no accepted jungle half cover) |
| plains | meshy3/cover_full_plains_v1.glb | meshy3/cover_half_plains_v1.glb |
| snow | meshy3/cover_full_snow_v1.glb | meshy3/cover_half_snow_v1.glb |
| city | meshy3/cover_full_city_v1.glb | meshy2/cover_half_city_v1.glb |
| dock | meshy2/cover_full_dock_v1.glb | meshy3/cover_half_dock_v1.glb |

| Player action / mission family | Model |
|---|---|
| Hack / `hack_terminal` | Existing `meshy1/obj_terminal_v1` (legacy exception below) |
| Destroy or defend a relay / `destroy_relay`, `defend` | `meshy2/obj_relay_v1` |
| Plant charges / `sabotage` | `meshy3/obj_charge_v1` |
| Evacuate / evacuation zone in every family | `meshy3/obj_beacon_v1` |
| Release captive / `rescue`, including temple fixture | `meshy3/obj_restraint_v1` |

The restraint replaces the captive silhouette while bound; the existing escort person returns when freed. VIPs and civilians retain their person art. One beacon sits in a corner of the first evacuation tile (0.25-wide footprint, at most 0.44 high), leaving unit centres clear. Objective rings and mission state indicators remain. Charge/relay/terminal footprints are at most 0.72 wide; the restraint is at most 1.35 high.

## Placement and LOD

Both explicit LODs are uniformly fitted and independently grounded at `Shot.elevation(m, tile) * 0.7`; bounds include the entire imported transform chain. Full cover uses a 0.98-wide / 1.9-high envelope, half cover 0.98 / 0.8. Connected cover follows the direction encoded by adjacent map tiles. Isolated cover uses a repeatable quarter turn from the mission seed, name and tile, without consuming mission RNG. All parts stay inside their tile.

The temple fixture has **no interior full-cover tiles**. Its new full-cover model is therefore rendered as sparse piers on already-blocked rear/left boundary tiles, every eight tiles. No foreground wall or rule tile was added. Other plots use their existing interior full-cover tiles. Missing mapping or the master switch restores the previous boundary presentation.

Spatial MultiMeshes group like models in 16×16 tile cells. Each LOD/material pair has the same union AABB, so Godot computes the same range origin for both. LOD0 ends where `_lod1` begins, with zero margins and disabled fades: a hard visibility-range switch supported by Compatibility. The cutoff is **26 units** for the legacy temple camera (23-unit zoom), and `max(26, max(width,height) * 1.3)` for campaign plots. Those campaigns actually use 33.8–44.2-unit default zooms, rather than a universal 25-unit camera. Near board regions remain detailed at their default view; zooming in reveals LOD0. Switching occurs per spatial group to keep draw calls low.

Existing detection-border boxes caused hundreds of extra draws. `meshy_theme_markers.gd` submits their exact transforms, dimensions and colors as one MultiMesh, with no decorative marker shadows. Original rule-owned nodes remain intact and are restored when the art detaches. Meshy cover shadows remain enabled.

## Asset budgets

| Asset | LOD0 triangles | LOD1 triangles |
|---|---:|---:|
| cover_full_temple_v1 | 3,000 | 800 |
| cover_half_temple_v3 | 3,000 | 800 |
| cover_full_ruins_v1 | 3,000 | 800 |
| cover_half_ruins_v1 | 2,999 | 799 |
| cover_full_caves_v1 | 3,000 | 800 |
| cover_half_caves_v1 | 2,992 | 794 |
| cover_full_jungle_v1 | 3,000 | 800 |
| cover_full_plains_v1 | 2,994 | 798 |
| cover_half_plains_v1 | 2,986 | 798 |
| cover_full_snow_v1 | 2,985 | 800 |
| cover_half_snow_v1 | 2,999 | 799 |
| cover_full_city_v1 | 2,987 | 798 |
| cover_half_city_v1 | 2,992 | 789 |
| cover_full_dock_v1 | 3,000 | 795 |
| cover_half_dock_v1 | 2,992 | 797 |
| obj_relay_v1 | 3,995 | 998 |
| obj_charge_v1 | 3,997 | 996 |
| obj_beacon_v1 | 3,998 | 1,000 |
| obj_restraint_v1 | 3,999 | 1,000 |
| obj_terminal_v1 (legacy) | 3,996 | **Absent** |

All 19 new pairs pass the cover ≤3,000/800 or objective ≤4,000/1,000 caps. Every referenced material texture is ≤512×512 (solid materials need no textures). The legacy terminal also passes its 4,000-triangle and texture caps. Tests load the actual imported scenes and count every surface, not just file metadata.

## Exceptions and visual corrections

- **Terminal LOD1 is missing on disk**, including sibling worktrees. `obj_terminal_v1_lod1.glb` was not supplied despite the task inventory. The old terminal remains in the explicit legacy fallback; no paired LOD is claimed for it. It is excluded from new-pair assertions and separately audited at LOD0. Completing this one pair requires the missing asset; no GLB was generated or modified under this lease.
- **Jungle half cover:** upstream A–D were rejected and no final exists. The procedural half cover remains.
- **Cave cover:** initial in-game materials crushed to near black. The configured runtime lift raises full-cover texture blacks by reducing contrast (0.22 lift), and lightens the half-cover solid materials by 0.14. Duplicated meshes/materials and a ≤512² runtime texture preserve the original asset files. Both LODs receive the same correction.
- **Compatibility lighting:** reduced key/rim energy to 55% of the existing values and ambient to 80% to retain pale snow and stone detail without ACES. Forward+ lighting stays as before.
- All available supplied cover/objective geometries were accepted after these corrections. None was discarded for floating, wall intersection, or blocking labels. The terminal is unsuitable for *new paired-LOD integration* until its missing LOD arrives, not rejected on silhouette.

## Real-window performance

All **62 shipped mission layouts** passed the **≤300,000 visible triangles / ≤150 draw calls** gate at their default battle cameras. Survey maxima: **290,774 visible triangles**, **140 total draw calls**. “Busiest” below means the highest visible-triangle mission in each theme, selected from the survey.

Native **1920×1080**, HUD and normal gameplay overlays on, **Compatibility** (`gl_compatibility`), NVIDIA GeForce **RTX 4090 Laptop GPU**, OpenGL 3.3 / NVIDIA 595.99.02. Vsync disabled, `Engine.max_fps = 0`. After two seconds of settling, each row reports maxima over **600 frames**, average uncapped FPS, and the 95th-percentile frame interval.

| Theme | Busiest mission | Visible tris / 300K | Total draws / 150 | Uncapped FPS | p95 ms | All-pass primitives |
|---|---|---:|---:|---:|---:|---:|
| plains | `r_snipers` | 290,774 | 126 | 381.8 | 3.155 | 519,151 |
| dock | `web_detention_level_5` | 238,894 | 123 | 294.5 | 4.091 | 443,408 |
| city | `ilsaDrop` | 194,870 | 132 | 331.3 | 3.849 | 362,242 |
| ruins | `cache` | 250,412 | 128 | 368.4 | 5.034 | 472,325 |
| snow | `web_antenna_ridge` | 199,783 | 119 | 264.6 | 4.495 | 383,423 |
| caves | `h_husks` | 270,857 | 130 | 189.1 | 6.121 | 513,309 |
| jungle | `h_roots` | 226,766 | 132 | 332.9 | 4.033 | 405,663 |
| temple | `fixture` | 139,617 | 110 | 356.4 | 4.734 | 273,227 |

Visible triangles use the root viewport's `VIEWPORT_RENDER_INFO_TYPE_VISIBLE` primitive counter. Total draws use `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, including HUD/portrait work. The final column transparently reports `RENDER_TOTAL_PRIMITIVES_IN_FRAME`: repeated shadow/subviewport submissions make this larger than visible triangles, and it exceeds 300K in seven rows. The requested visible-triangle gate does **not** imply that all GPU passes submit fewer than 300K primitives.

The highest-draw mission can differ from the highest-triangle mission. All-theme draw maxima from the 60-frame survey:

| Theme | Mission with most draws | Total draws / 150 |
|---|---|---:|
| caves | `r_nexus` | 136 |
| city | `envoy` | 140 |
| dock | `dock` | 133 |
| jungle | `h_roots` | 134 |
| plains | `depot` | 130 |
| ruins | `archive` | 132 |
| snow | `ilum` | 120 |
| temple | `fixture` | 110 |

Scope: Normal difficulty, seed 17, initial real mission state, native default camera. These are measurements on this machine, not phone-hardware FPS results or a guarantee about every later reinforcement/effect peak. The busiest-theme sample FPS range is **189.1–381.8**.


## Screenshots and review

All **21 final PNGs** were opened and visually inspected individually at native **1920×1080**, with the real mission HUD visible. Default and close views use the same unedited mission. Ground contact, raised floors, adjacent walls, silhouette brightness and unit/label readability were checked; no remaining floating or clipping defects were observed. Cave material correction and Compatibility lighting restored readable dark and pale surfaces. Jungle half cover remains procedural.

| Theme | Real mission | Default | Close-up |
|---|---|---|---|
| plains | `r_snipers` | [PNG](../docs/godot/shots/meshyint-plains.png) | [PNG](../docs/godot/shots/meshyint-plains-close.png) |
| dock | `web_detention_level_5` | [PNG](../docs/godot/shots/meshyint-dock.png) | [PNG](../docs/godot/shots/meshyint-dock-close.png) |
| city | `ilsaDrop` | [PNG](../docs/godot/shots/meshyint-city.png) | [PNG](../docs/godot/shots/meshyint-city-close.png) |
| ruins | `cache` | [PNG](../docs/godot/shots/meshyint-ruins.png) | [PNG](../docs/godot/shots/meshyint-ruins-close.png) |
| snow | `web_antenna_ridge` | [PNG](../docs/godot/shots/meshyint-snow.png) | [PNG](../docs/godot/shots/meshyint-snow-close.png) |
| caves | `h_husks` | [PNG](../docs/godot/shots/meshyint-caves.png) | [PNG](../docs/godot/shots/meshyint-caves-close.png) |
| jungle | `h_roots` | [PNG](../docs/godot/shots/meshyint-jungle.png) | [PNG](../docs/godot/shots/meshyint-jungle-close.png) |
| temple | `fixture` | [PNG](../docs/godot/shots/meshyint-temple.png) | [PNG](../docs/godot/shots/meshyint-temple-close.png) |

| Objective | Real mission | Inspected screenshot |
|---|---|---|
| terminal | `archive` | [PNG](../docs/godot/shots/meshyint-obj-terminal.png) |
| relay | `relay` | [PNG](../docs/godot/shots/meshyint-obj-relay.png) |
| charge | `sabotage` | [PNG](../docs/godot/shots/meshyint-obj-charge.png) |
| beacon | `escort` | [PNG](../docs/godot/shots/meshyint-obj-beacon.png) |
| restraint | `rescue` | [PNG](../docs/godot/shots/meshyint-obj-restraint.png) |

The beacon occupies a deliberately small tile corner. The restraint leaves the captive ring readable and becomes the normal escort silhouette after release. The relay is grounded inside its existing raised-floor pocket; the terminal retains its legacy presentation.


## Validation and reproduction

`./godot/test.sh` exited **0**, all **15 suites** reported **0 failures**, and its log contains no `SCRIPT ERROR`, `Parse Error` or `ERROR:`. Normal rescue bot remains **10/20**. Map-art suite: **179,392 checks**, zero failures; terrain suite: **70,576 checks**, zero failures. Existing ObjectDB warnings in unrelated suites are unchanged.

The map-art extension exercises every theme, each missing full/half slot, missing whole theme, master-off equivalence, missing objectives, missing files/LOD partners, deterministic orientation, real raised-floor placement, exact LOD range pairing, material/triangle caps, captive-to-escort replacement and detection-border batching/restoration. Existing all-map checks compare mission state/RNG, passability, cover and LOS before/after rendering. Every mapped full/half class is asserted present in a real theme mission.

Capture harness: native 1920×1080 X11 window, Compatibility, HUD on. The review subclass injects each unedited shipped mission before normal game scene/UI setup and retains normal labels/overlays. It disables unattended input/edge panning only; no game save is read or written and no mission layout or unit is moved for a shot. Close captures change only the camera.

```sh
/home/jess/projects/.tools/godot/godot --headless --path godot --editor --import --quit
./godot/test.sh
# On this hybrid-GPU machine, set XAUTHORITY to the active Xwayland auth file.
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  /home/jess/projects/.tools/godot/godot --display-driver x11 \
  --rendering-method gl_compatibility --path godot -s scripts/meshy_theme_capture.gd
# A single mission: append -- --one web_detention_level_5
```

The harness surveys all 62 layouts, selects the highest visible-triangle mission per theme, measures 600 frames there, saves all 21 required PNGs and exits nonzero for a phone-budget or image-size failure. Survey data is written to `/tmp/meshyint-survey.json`; sample/budget rows are also printed.

Final audit: all changed text files are below 600 lines; all 21 PNGs are 1920×1080; `git diff --check` passes. Changes are restricted to the lease. The final capture run exited 0 with no `SCRIPT ERROR`, `Parse Error` or `ERROR:` lines. Committed locally on `meshy/integrate`; no push.

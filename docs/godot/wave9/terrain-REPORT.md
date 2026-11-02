# Wave 9 — terrain depth (pending catalog integration)

**Status: authoring work is reviewable, but the production elevation gate is blocked.** The requested lease excludes `map_catalog.gd`. Its current loader has no reader for an `elevation` field, while the unchanged gameplay rules read only `^` and `M` board characters. Permission for the minimal loader hook was requested; it has not been received. No out-of-lease file was edited. The normal terrain test deliberately fails until integration. No completion claim or local commit has been made.

The first operation was the required Godot 4.7.2 headless editor import. Work remains on `wave9/terrain`; no push or subagents.

## Terrain and cover

All 47 manifest campaign maps have authored 0/1/2 tier grids (world heights 0/0.7/1.4). Broad platforms replace isolated elevation sockets. The data adapter preserves nonwalkable cover and evac markers, and converts only existing walkable floor/rubble/elevation characters. It does not change movement, LOS, damage, high-ground bonuses or any other rule. Every map uses all three tiers in authoring validation.

Each map also receives two existing `ruin` parcel placements as cover clusters, except retaliation maps, which keep only the southern cluster so the northern civilian approach stays open. These are cover-placement edits only: plot dimensions, lanes, crossings, spawn, objectives, evac, entries, clocks and mission fields are unchanged. The existing loader still clears its three-wide routes and anchor plazas after placing parcels. Full-cover silhouettes use machinery, wall sections, pillars, trunks or boulders; half cover retains 0.7–0.9-unit silhouettes. Surface debris, grass, markings and snow drifts are batched decorative geometry with no collisions or rule changes. Raised dressing now sits on its actual floor.

Stair strips occur in broad runs. A separate graph completes any missing connections into enclosed low pockets. The test independently traverses equal-height links and the actual rendered stair endpoints, reaching every walkable tile from spawn. It checks three physically separate north/south corridors at least three tiles wide, their broad connections to spawn and objective, and no articulation-point chokepoints.

Percentages below are walkable-tile-weighted across each theme. “After” means **explicit authoring mode**, pending the loader hook.

| Theme | Campaign maps | Before raised | Authored raised | Changes / battle capture |
|---|---:|---:|---:|---|
| Dock | 8 | 2.21% | 20.23% | Two broad service decks with ramps; paired hull/machinery cover; hangar ribs and a landing-pad drop, separate apron and shuttle. [Capture](../shots/wave9-dock.png) |
| City | 7 | 2.91% | 20.11% | Raised paved concourses and service terraces; machinery and low metal barriers; staggered facades with open alley gaps. [Capture](../shots/wave9-city.png) |
| Jungle | 3 | 3.71% | 42.04% | Two irregular earth shelves, stair runs, broad tree-trunk cover and sandbags; layered trees and exposed roots. [Capture](../shots/wave9-jungle.png) |
| Snow | 1 | 3.66% | 37.56% | Overlapping ice shelves, snow drifts, capped boulders and sandbags; uneven ice ridges and pines. [Capture](../shots/wave9-snow.png) |
| Temple fixture | 0 | 8.93% | 8.93% | Existing rescue dais retained; columns, low masonry, colonnades and terraces replace the boundary ring. [Capture](../shots/wave9-temple.png) |
| Ruins | 4 | 2.82% | 19.53% | Offset upper floors with masonry stair runs; paired wall fragments and pillars; broken walls, tower fragments and the distant arcade. [Capture](../shots/wave9-ruins.png) |
| Plains | 21 | 2.54% | 42.20% | Broad rolling shelves, grass tufts, boulders and sandbag lines; low hills and separated rock outcrops. [Capture](../shots/wave9-plains.png) |
| Caves | 3 | 2.32% | 41.92% | Irregular rock shelves and stair cuts; rock/masonry cover; cave buttresses, stalagmites, distant ridges and crystals. [Capture](../shots/wave9-caves.png) |

The manifest has seven campaign themes; temple is the legacy rescue fixture, outside the map-data lease. Its authored heights remain unchanged to preserve the difficulty-band fixture. All eight themes share the revised renderer and edges.

## Natural edges

The renderer no longer draws cover meshes on the boundary rule tiles. Those tiles retain their existing blocked/LOS behavior; theme scenery sits beyond the board. Individual transformed mesh AABBs, including every rotated rock and imported submesh, are checked against the board footprint. Foreground scenery stays lower and groups leave gaps to the distant landscape. Organic ground materials now continue beyond the board instead of making a contrasting rectangular plinth.

## Validation

- Required import: exit 0.
- Existing 14 suites passed in the full suite attempt; no `SCRIPT ERROR`.
- Latest dedicated art check after cover placements: **62 layouts, 104,792 checks, 0 failures**. Includes all 47 campaign maps, 14 web variants and the temple fixture; verifies rendering leaves mission/board/HP/objective/unit/RNG state and gameplay queries unchanged.
- Authored terrain check after cover placements: **47 maps, 70,576 checks, 0 failures**. All three tiers, raised threshold, every walkable tile ramp-connected, all anchors reachable, three wide routes, props grounded and contained, scenery outside the board, no perimeter cover ring.
- Production terrain check: **64,485 checks, 94 failures**: one unloaded-elevation assertion and one raised-coverage assertion for each of 47 maps. This is the unresolved catalog dependency, not a passing gate.
- Every GDScript is below 600 lines. Data audit confirms only each map’s `elevation` and cover parcel placements changed, plus permitted Normal family tuning. `test.sh` changes only by adding `terrain_test` to its suite list.

Difficulty bands remain **Story 20/20, Normal 10/20, Hard 4/20, Legend 1/20**. These are the existing production rescue-band tests, whose fixture is unchanged.

Campaign authoring validation uses the existing factory, roster gear, combat adapter, 20 seeds and unchanged `campaign_bot.turn` policy. The `--authored` flag explicitly applies the proposed elevation board after construction, so these are provisional authoring measurements, not a substitute for rerunning `./godot/campaign-test.sh` after the catalog hook. Final post-cluster authoring numbers:

| Family | Wins / 20 | Rate | Mean turns |
|---|---:|---:|---:|
| Rescue | 10 | 50% | 5.0 |
| Hack | 11 | 55% | 8.9 |
| Relay | 14 | 70% | 8.0 |
| Defend | 15 | 75% | 12.0 |
| Retaliation | 8 | 40% | 7.1 |
| Sabotage | 15 | 75% | 7.2 |
| Ambush | 14 | 70% | 3.4 |

All seven are within 30–80% in authoring mode. Retaliation’s added northern cluster initially reduced the shortened-clock result from 8/20 to 4/20; retaining only its southern cluster restores 8/20 without changing civilian locations or rules.

Tuning was limited to families moved out of band by proposed elevations: hack clock 8→9; relay clock 6→8; retaliation civilian interval 3→2; ambush courier HP 12→16. Before those adjustments the authoring bot measured hack 5/20, relay 2/20, retaliation 18/20 and ambush 18/20. No rule or AI code changed.

## Window captures

All nine PNGs are actual 1920×1080 X11 Vulkan Forward+ window framebuffer captures, with the battle HUD visible. The theme views use the game’s default yaw 0.3 and pitch 0.8. Campaign maps use the default map-centred pivot and map-size ×1.3 zoom; the temple fixture uses its original `(9,0,17)` pivot and zoom 23. The explicit `--authored` flag previews proposed heights; normal game startup is not patched by the screenshot harness. No save is loaded or written.

[High-ground shot](../shots/wave9-highground.png): the soldier makes a legal one-action move to `(14,18)` on relay, then fires through the existing shot and impact code from tier 2 to tier 0. No actor teleport, AP grant, forced hit or rule change. The action view shows the ledge, tracer and HUD “High ground +20”; the shot deals 6 damage and consumes ammo. This is an authoring-mode battle because of the pending hook.

## Frame pacing

NVIDIA GeForce RTX 4090 Laptop GPU, driver 595.99.02; native 1920×1080 3D and HUD, Vulkan Forward+, VSync disabled. Largest map is cache, 34×34. Every listed run uses unrestricted scheduling; no `taskset`, affinity, process priority, or changes to other workloads. Mean is 1000 divided by mean elapsed process-frame time; p95 is the 95th-percentile frame time. Warmup is 10 seconds; samples contain 1,200 frames.

The renderer batches by mesh/material/role, suppresses shadows on surface details, markers and distant skyline, caps local lights at four, bounds scenery visibility to 95 units, uses imported mesh LOD threshold 4, a single 60-unit directional-shadow volume with a 2048 atlas and low shadow filtering, and half-resolution low-quality SSAO. The framebuffer remains native resolution. Battle quality settings are restored when the scene exits.

| Run | Mean fps | p95 ms | p99 ms | Load / result |
|---|---:|---:|---:|---|
| Wave 8 baseline on this worktree | 115.3 | 20.33 | 21.69 | Default scheduling; fails p95 |
| First edge/light/shadow pass | 108.8 | 18.71 | 19.91 | Fails p95 |
| Heavy competing test load | 72.9 | 38.27 | 57.79 | CPU mean 64.7%, peak 96.0%; fails |
| Authored terraces, final quality settings, before added cover parcels | **221.0** | **16.35** | 19.95 | CPU mean 21.9%, peak interval 25.5%, CPUs 0–31; passes mean and p95 |
| Final authored map, after cover placement | **244.8** | **9.10** | **15.56** | **Pass**; CPU mean 8.9%, peak interval 11.4%, CPUs 0–31; 99 draw calls |

The final geometry passes both targets with unrestricted scheduling. The samples under heavy contention remain reported above and do not pass. Production startup still needs the catalog hook; the final timing used the explicitly authored battle, not a terrain-only renderer.

## Integration request (exact call site)

In `godot/scripts/map_catalog.gd`, `static func load_map(path: String) -> Dictionary`, immediately after the existing evac stamping loop and before `data.rows = rows`, add:

```gdscript
preload("res://scripts/map_art_elevation.gd").apply(rows, data.get("elevation", []))
```

The prepared helper signature is:

```gdscript
static func apply(rows: Array[String], elevation: Array) -> void
```

This is a data-loader hook, not a rule change. Its implementation is already in the leased `map_art_elevation.gd`. Permission is needed solely because `map_catalog.gd` is outside the explicit lease. After approval: apply the hook; run production terrain/full-suite and seven-family campaign checks; repeat the real-window timing/captures without `--authored`; remove authoring-only scaffolding if no longer useful; commit locally once gates pass.

## Reproduction before integration

```bash
./godot/test.sh # expected to fail only the new production elevation gate
/home/jess/projects/.tools/godot/godot --headless --path godot \
  -s tests/terrain_test.gd -- --authored
/home/jess/projects/.tools/godot/godot --headless --path godot \
  -s tests/terrain_test.gd -- --campaign --authored
# Use the active desktop XAUTHORITY; the shell initially had a stale path.
XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.SOCGY3 \
/home/jess/projects/.tools/godot/godot --path godot --display-driver x11 \
  --rendering-method forward_plus --resolution 1920x1080 --borderless \
  -s scripts/map_preview.gd -- --all --authored
XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.SOCGY3 \
/home/jess/projects/.tools/godot/godot --path godot --display-driver x11 \
  --rendering-method forward_plus --resolution 1920x1080 --borderless \
  -s scripts/map_preview.gd -- cache --fps --benchmark --authored
```

## Per-map authored coverage

| Map | Theme | Before raised | Authored raised / walkable | Authored % |
|---|---|---:|---:|---:|
| adraasHunt | city | 1.70% | 164/763 | 21.49% |
| archive | ruins | 4.30% | 161/765 | 21.05% |
| blockade | plains | 0.69% | 362/864 | 41.90% |
| brenClinic | city | 4.30% | 114/557 | 20.47% |
| cache | ruins | 2.44% | 177/982 | 18.02% |
| depot | plains | 2.75% | 361/869 | 41.54% |
| dock | dock | 3.68% | 135/651 | 20.74% |
| envoy | city | 3.67% | 137/654 | 20.95% |
| escort | city | 1.75% | 144/741 | 19.43% |
| fort | plains | 3.94% | 411/988 | 41.60% |
| grakClan | plains | 4.88% | 278/653 | 42.57% |
| h_beacon | dock | 1.08% | 111/555 | 20.00% |
| h_buoy | dock | 0.81% | 144/739 | 19.49% |
| h_cache | dock | 3.15% | 164/763 | 21.49% |
| h_grove | jungle | 3.78% | 365/869 | 42.00% |
| h_hetzal | plains | 3.15% | 321/764 | 42.02% |
| h_husks | caves | 1.43% | 407/975 | 41.74% |
| h_outpost | plains | 1.74% | 359/861 | 41.70% |
| h_prisoners | dock | 1.50% | 174/863 | 20.16% |
| h_roots | jungle | 2.29% | 276/653 | 42.27% |
| h_salvage | plains | 4.16% | 317/745 | 42.55% |
| h_scouts | jungle | 5.05% | 273/652 | 41.87% |
| h_tempest | dock | 1.50% | 172/860 | 20.00% |
| h_valo | city | 3.20% | 148/746 | 19.84% |
| hutt | city | 2.67% | 114/558 | 20.43% |
| ilsaDrop | city | 3.35% | 185/983 | 18.82% |
| ilum | snow | 3.66% | 246/655 | 37.56% |
| r_bomb | plains | 2.76% | 364/866 | 42.03% |
| r_caves | caves | 1.75% | 314/739 | 42.49% |
| r_codes | plains | 1.89% | 314/739 | 42.49% |
| r_dump | plains | 2.32% | 239/558 | 42.83% |
| r_hospital | plains | 4.29% | 318/745 | 42.68% |
| r_muster | plains | 5.68% | 242/559 | 43.29% |
| r_nexus | caves | 3.79% | 361/867 | 41.64% |
| r_prisoners | plains | 0.92% | 278/650 | 42.77% |
| r_ravine | plains | 3.65% | 278/654 | 42.51% |
| r_seventh | plains | 0.79% | 318/761 | 41.79% |
| r_sixth | plains | 0.92% | 272/653 | 41.65% |
| r_snipers | plains | 2.44% | 408/980 | 41.63% |
| r_supply | plains | 2.29% | 274/652 | 42.02% |
| relay | plains | 1.08% | 239/557 | 42.91% |
| rescue | dock | 3.22% | 147/742 | 19.81% |
| sabotage | dock | 2.76% | 175/869 | 20.14% |
| shrine | plains | 0.92% | 277/648 | 42.75% |
| taris | ruins | 0.70% | 174/863 | 20.16% |
| thul | plains | 2.03% | 312/738 | 42.28% |
| vault | ruins | 4.25% | 144/749 | 19.23% |

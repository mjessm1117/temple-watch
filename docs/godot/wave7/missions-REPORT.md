# Wave 7 — missions and maps

Branch: `wave7/missions`. All changes are within the mission lease. No combat-lane files, frozen web sources, or existing tests were edited. No subagents were used.

The campaign bridge now resolves **47 campaign mission IDs to 47 distinct authored plots**, plus **14 web layouts** in the seeded variant pools. Every assembled map has different geometry. The original standalone `rescue.json` and its balance fixture remain in place.

**Integration is still required:** the mission rules and Interact contract work, but the existing battle HUD/input still says “Free Mira,” the battle scene still instantiates `env_art.gd`, and campaign advancement does not yet call the two-front service. Exact call sites are below. The shipped regression runner also contains one assertion requiring the fallback that this task removes; consequently `./godot/test.sh` currently exits 1, not 0.

## Feature coverage

| Source / feature | Status | Implementation / adaptation |
|---|---|---|
| XCOM recommendation #2: plot + parcel assembly | adapted | Seven authored parcel modules, rotations, plot sockets, elevated flanks, and three-wide reserved approaches; `map_catalog.gd` assembles deterministic boards. |
| #2: multiple validated routes / no chokepoints | ported | Checks two distinct full-length three-wide lanes, connecting paths, all-floor connectivity, and zero articulation vertices. Includes negative fixtures for narrow bridges, disconnected rooms, and duplicate lanes. |
| #3: objective after initial engagement, then evac | adapted | Forward objective placements and a separate evacuation phase; rescuing, copying, destroying, holding, stopping a courier, or saving civilians does not instantly win. VIP missions begin with the escort and require reaching the far evac. |
| #4: staged pods at different angles | ported | Separate approach, flank, and objective pods; web variant pod coordinates retained. Existing difficulty engagement limits still apply. |
| #4: announced reinforcement lanes | ported | Named, rotating entries prefer locations at least four tiles from the squad; arrivals are announced at least one turn ahead. Large waves split into two-member pods so they fit Story's active cap. Blocked landings retry with another announcement. |
| #7: rescue / VIP extraction | adapted | Twelve-turn clock, escort handoff, actual evac coordinates, evacuee HP and incoming damage when exposed. |
| #7: hack terminal | adapted | Nine-turn clock; copy two terminals with deterministic one-AP Interact. The optional third remains available during evacuation. Optional reward hacks are a separate risk system. |
| #7: destroy relay | adapted | Ten-turn clock starts on concealment loss; damage the relay, then evacuate. Adjacent Interact applies six damage; combat can also call the objective damage hook. |
| #7: defend | adapted | No deadline. Increasing announced waves, enemy movement/attacks against the relay, failure at zero integrity, then evac after the final wave is cleared. |
| #7: retaliation | adapted | No arbitrary deadline. Save four of six civilians; exposed waiting civilians can be lost every second enemy turn. Fail when the quota becomes impossible, then extract on success. |
| #7: sabotage | adapted | Ten turns from concealment loss; plant two charges, then bring all standing soldiers to evac. |
| #7: ambush | adapted | Eight turns to stop a courier and extract; the courier follows a route to its exit. Death, stun, or capture stops it; reaching the exit fails. |
| #15: pacing measurements | ported | Contact/objective/evac turn, traversed tiles, unused floor fraction, flank opportunities, and peak active threats are returned with battle results. These are instrumentation, not claims that every new family is balance-tuned. |
| `data-maps.js`: all 14 layouts | adapted | All original records retained in `web-layouts.json`; playable variants retain geometry, objective coordinates, pod positions, operation steps, and named entries inside a wider bypass apron. Ragged rows, sealed cells, and single-tile passages are repaired. |
| `maps.js`: arbitrary board size | ported | Width/height derive from plots, never a fixed rescue board. Current layouts span 26–34 tiles on each axis, including rectangular boards. |
| `maps.js`: reach / hold / chase / extract | ported | Operations advance on actions; uncontested holds tick at enemy-phase end; runners can escape or be stopped; extraction requires the standing squad. |
| `maps.js`: multi-edge waves and entries | adapted | Source entry names/coordinates and defense wave rosters are preserved for web variants. Phase waves always receive advance notice; immediate surprise drops are intentionally delayed. |
| `maps.js`: overwatch zones, fired/held messages | ported | Renderer exposes actual walkable, in-range, LOS-covered tiles by side. Mission logs distinguish fired overwatch and a watch that held. Overlay installation in the battle scene is pending integration. |
| `maps.js`: large-board enemy movement | adapted | Existing combat AI closes distance; mission-owned defenders instead advance on the protected relay, and couriers follow their escape route. No edits to `ai.gd`. |
| `themes.js`: eight map themes | adapted | All palettes, sky colors, fog colors, ambient/key/rim lighting, scenery choices, and particle kinds/counts are exported. Godot renderer uses native sky, lighting, particles, and scenery with adjusted light energy. |
| `props.js` / web GLBs | adapted | All 28 prop GLBs decoded and dequantized for Godot, with original textures/materials and wall-theme aliases. Decorative vegetation uses native fallback shapes. Deep water remains movement-blocking and transparent to shots; source blast walls use destructible full cover. Barrel visuals use half-cover semantics; their explosion behavior needs the combat hook below. |
| `swarm.js`: brood, chain, troop counter, Calm | adapted | Activated horrors brood every two turns, at most two husks within three tiles, six live husks total. Nearby kills provoke at most two surges per turn. Horrors cannot damage troops. Successful Beast Calm suppresses chains for the current turn. Uses existing unit rigs and original names, not new creature art. |
| `twin.js`: last two crisis steps / second squad | adapted | `mission_fronts.gd` implements unlocks, eligibility, Front A/B exclusion, B's four-unit/two-Jedi limits, deferred time, saveable state, stand-down, and one-use auto-resolution receipts. Battle bridge applies B's smaller patrol. Strategic/UI call sites remain integration work. |
| `hack.js`: safe/risky console and droid rewards | adapted | Range four, LOS, Medic/tech bonuses and 95% cap; reveal + intel, stun, temporary droid control, delayed alarm, and expiring droid aim bonus. Each optional console reward is one-use. Interface uses one AP; primary objective Interact never depends on a random reward roll. |
| Concealment start flag | ported | Per-map flag applied to initial and campaign roster soldiers; distant dormant pods cannot spot concealed soldiers. Contact, attacks, and objective/network interactions reveal the squad and trigger applicable clocks. |
| XCOM assets, source code, names, UI/audio/models | skipped | Only mechanics/design and locally inspected config values informed implementation; all assets are the repository's web props or existing Godot assets. |

The XCOM inputs were `docs/XCOM2-STUDY.md` recommendations 2/3/4/7/15, `wave4/FEEL-GAP.md`, the Wave 5 inventory/map report, and the installed WotC `share/data/xcom2-warofthechosen/xcomgame/config/defaultmissions.ini`. The shipped seven-turn recovery and twelve-turn extraction examples informed family clocks; this port uses its own board scale and tuning.

## Campaign coverage

| Family | Campaign IDs |
|---|---|
| Defend | relay, shrine, blockade, ilum, fort, r_muster, r_supply, h_outpost, grakClan |
| Rescue | rescue, taris, r_sixth, r_prisoners, h_prisoners |
| Hack terminal | envoy, archive, cache, hutt, vault, r_caves, r_codes, h_husks, h_buoy, ilsaDrop |
| Sabotage | sabotage, depot, r_dump, h_cache |
| VIP extract | escort, thul, r_ravine, h_hetzal, h_scouts |
| Destroy relay | dock, r_seventh, r_bomb, r_nexus, h_grove, h_beacon, h_roots |
| Ambush | adraasHunt, r_snipers, h_tempest |
| Retaliation | r_hospital, h_valo, h_salvage, brenClinic |

Web variants: Dantooine Crossroads, Shrine Terraces, Hold the Ford, Frozen Watchpost, Detention Level 5, Smuggler Grotto, Antenna Ridge, Rooftop Chase, Listening Post Interior, Overgrown Relay, Balmorra Fuel Farm, Refinery Stacks, Canyon Run, Deepway Tunnels.

`MapCatalog.resolve(id)` returns the unique default; an unknown ID returns an empty path rather than rescue. `select_layout(id, seed, variant = -1)` selects reproducibly from that mission's own pool. `Battle.create` uses it; optional `pending_mission.map_variant` pins an index. Operation variants report their actual family in the battle result.

## Player-visible changes and limits

Campaign battles now use different terrain, dimensions, pods, evac locations, and family rules. Rescue remains playable with the existing Free action; defense attacks the relay even when a squad retreats. Timed families no longer inherit the rescue difficulty clock. Completing a primary objective opens a pursuit/extraction phase. Existing main-scene UI cannot yet expose all these rules: Interact input, objective labels, hack choices, theme renderer, and two-front screens need the integration changes below.

The reusable map renderer and inspection window demonstrate all themes, source props, elevated terrain, objective/overwatch markers, and incoming lanes. They do not silently patch `game.gd`. Screenshot soldiers are inspection markers; the real battle still uses its existing unit views.

## Verification

- `godot --headless --path godot -s tests/missions_test.gd`: **516 checks, zero failures**, no `SCRIPT ERROR` or `ERROR:`. Covers 61 unique assembled geometries, all campaign IDs/families, two wide approaches, complete reachability, zero chokepoints, quadrant cover, elevated flanks, clear/blocked sightline spread, objective phases and failure rules, AP/adjacency, timers, waves, operations, hacks, swarm, two-front serialization/settlement, water semantics, and all 28 imported GLBs.
- `./godot/test.sh`: **exit 1** solely because `tests/loop_test.gd:170` still asserts `Battle.map_path("h_hetzal") == "res://data/rescue.json"`. Core: **367/367**; campaign: **45/45**; story: **225/225**; loop: **178/179**. No `SCRIPT ERROR`; the failing assertion emits the runner's `ERROR:`. This is an explicit remaining integration blocker, not a waived green build.
- An untracked copy at `/tmp/wave7-loop-contract.gd`, with only that assertion updated to Hetzal's real map path, passes **179/179**. The repository test was left untouched because it is outside the lease. The old rescue-only bot finishes the opening defense by losing; this verifies campaign flow, not defense balance.
- Twenty fixed-seed standalone rescue games per difficulty: **Story 20/20, Normal 10/20, Hard 4/20, Legend 1/20**, all inside the required bands. New families have deterministic rule fixtures rather than claims of matching those rescue win bands.
- Every GDScript file is under 600 lines (`mission.gd`: 567). `git diff --check` passes. The existing core suite still reports ObjectDB teardown leak warnings.
- Fresh prop import succeeds after decoding unsupported `EXT_meshopt_compression` and `KHR_mesh_quantization`; asset provenance and conversion dependency versions are in `godot/assets/maps/provenance.json`.

## Real-window screenshots

Captured from native Wayland Godot windows using Vulkan, not a headless render or a generated image:

- [Listening Post / ruins hack map](../shots/wave7-missions-archive.png)
- [Antenna Ridge / snow operation](../shots/wave7-missions-web_antenna_ridge.png)
- [Hollow Jedi / cave map with announced inbound lane](../shots/wave7-missions-h_husks.png)

Reproduce with `/home/jess/projects/.tools/godot/godot --display-driver wayland --path godot -s scripts/map_preview.gd -- archive --capture`. Substitute `web_antenna_ridge`, or `h_husks --inbound --capture`. Omitting `--capture` leaves an inspection window with an End turn button.

## Integration requests

### Combat lane: actions, objectives, and terrain

1. **Interact**: in `game.gd:_choose_action()` / input target confirmation, add a generic action for all standing player units and select from `mission.interactables() -> Array[Vector2i]`. Call `mission.interact(unit: Dictionary, tile: Vector2i) -> Dictionary`. Success returns `{ok:true, ap_cost:1, phase, message}`; rejection returns `{ok:false, reason}`. The mission spends AP itself. Do not spend AP a second time. Bypass the current class-kit/`Ability.reason` lookup for this generic action. On success call the normal `_after_action()` / `_refresh()` path.
2. **Objective HUD**: replace the rescue-only text in `hud_controls.gd:_refresh()` around line 158 with `mission.objective_status() -> Dictionary` (`label`, `phase`, `clock_trigger`, `turns_left`, `held`). `turns_left == -1` means no running deadline. In `game.gd:_refresh_figures()`, render scouted enemies from `spotted` while leaving `awake` as their AI activation state; concealed squads can scout without activating pods. Draw the prisoner only when `mission.prisoner.get("active", true)` is true. Non-VIP missions retain a defensive off-board prisoner placeholder for old code.
3. **Renderer**: in `game.gd:_build_terrain()`, instantiate `map_presentation.gd` for `mission.modern`, retaining `env_art.gd` for the standalone fixture. Both provide `build(mission: RefCounted, models: Dictionary = {}) -> void`. After environment/light creation call `apply_environment(world: WorldEnvironment, key: DirectionalLight3D, theme_name: String) -> void`; the renderer supplies its own rim light. After actions and turn playback call `refresh_markers(mission: RefCounted) -> void`. `overwatch_zones(mission) -> Array[Dictionary]` is also available if existing overlays are preferred.
4. **Variable board camera**: in `game.gd:_ready()` / initial framing, derive pivot and zoom from `mission.spec.width/height`; remove the fixed rescue-sized dust/framing assumptions. The inspection camera provides a working example.
5. **Objective damage and presentation**: validate a relay-targeted attack in combat, spend its combat AP, then call `mission.damage_objective(amount: int) -> void`. Mission event playback should handle `objective_attack`, `vip_attack`, and `reinforcement` in addition to existing move/attack/activation events. Relay Interact already supplies a functional one-AP breach option.
6. **Reward hacks**: show choices from `MissionHack.options(mission: RefCounted, unit: Dictionary, tile: Vector2i) -> Dictionary`, then call `mission.hack(unit: Dictionary, tile: Vector2i, mode: String = "safe") -> Dictionary`. The mission owns RNG, costs, effects, expiry, and alarms. Droids must expose `droid:true`; the current catalog has no dedicated droid kind. Objective terminal copying remains Interact, independently of optional console rewards.
7. **Beast Calm / barrels**: `mission.use_ability()` recognizes a successful `beastCalm` when the target is actually stunned and sets the swarm's calm turn. The combat ability catalog must provide that ability. For barrel destruction, identify source barrel positions through `mission.spec.prop_overrides` (`Vector2i -> "barrel"`) before cover becomes rubble and apply the web three-damage 3×3 explosion using combat-owned area-damage rules. Barrel placement/rendering is present; explosions are not implemented here.

### Campaign lane: two fronts and rewards

`mission_fronts.gd` is a service, not an injected monkey patch. Its functions accept the existing campaign state dictionaries.

1. In `campaign/state.gd:select_mission()` **before** the loop that applies ignored-crisis consequences, call `MissionFronts.launch(state: Dictionary, option: Dictionary, ids: Array, plan: Array) -> Dictionary`. Reject `ok:false`; if `defer_ignored:true`, defer that loop. Copy returned `fewer` into the selected pending option. `available(state, plan) -> bool`, `late_steps(plan) -> Array`, and `squad_rule(state) -> Dictionary` support the UI.
2. In `campaign/state.gd:apply_mission_result()` **after per-soldier rewards but before `advance_mission()`**, call `MissionFronts.finish(state) -> Dictionary`. If `advance:false`, preserve the current step/date and the service's Front B options; skip `refresh_options()`, which would overwrite them. When `advance:true`, apply the receipt's ignored-crisis consequences and advance once. Keep the existing debrief idempotency guard.
3. In `campaign/squad.gd` and `campaign_bridge.gd:deploy()`, honor the rule's maximum and used IDs: Front A up to six, Front B two to four, at most two Jedi, no Front A soldiers. Existing UI/flow currently insists on exactly four. Display the B-stage banner on the galaxy/debrief screens.
4. Galaxy buttons call `MissionFronts.auto_resolve(state, option_index: int, ids: Array, rng: RandomNumberGenerator) -> Dictionary` or `stand_down(state) -> Dictionary`. Apply each successful receipt once: normal mission rewards on an auto win, promotions for the XP already granted, receipt favor loss on failure, mission/ignored-crisis unrest, then one time/step advancement. Auto losses already apply stress and a ten-day wound; the campaign owner may apply its healing multiplier. Captive rescue cannot auto-resolve. `auto_odds(state, ids) -> int` supplies the preview.
5. Battle results now carry `map_id`, `family`, `metrics`, `objectives_completed`, `civilians_saved`, and `hack_intel`. Apply successful optional-hack intel/terminal bonuses in the campaign settlement. Story briefing sources are outside this lease; update their objective/goal strings to reflect the selected family and layout, particularly reclassified retaliation/ambush missions.

### Integrator: regression contract

- Add `missions_test` to the suite loop in `godot/test.sh`.
- In `godot/tests/loop_test.gd:_test_eras()` at line 170, replace the obsolete fallback assertion with:

```gdscript
check(Battle.map_path("h_hetzal") == "res://data/maps/h_hetzal.json", "Hetzal resolves to its own mission map")
```

The exact change was exercised in the temporary copy described above. Do not restore the rescue fallback to make the old assertion pass.

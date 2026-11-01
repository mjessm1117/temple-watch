# Wave 7 — combat

Branch: `wave7/combat`. Only the combat lease is changed. No web files or XCOM assets/code/text were copied. Mechanics references: `docs/XCOM2-STUDY.md`, especially recommendations 1, 5, 6, 9, 10, 14, and `docs/godot/wave4/FEEL-GAP.md`. Web sources were read directly, including all of `abilities.js` and the requested presentation modules.

## Player-visible changes

- Shots wait for a **0.60-second camera blend** before rules resolve. Space, Escape, Enter or click skips the current activity; camera-off remains available. Enemy decisions run one actor at a time, with that actor's reactions and impacts finishing before the next actor decides. Headless simulation remains synchronous; `game.animate_headless = true` enables the actual presentation timeline for tests.
- Overwatch gets its own camera and banner. Reactions inspect the first exposed tile of a route, with movement pausing for presentation. Pod reveals and scamper paths are presented in both phases.
- Targeting includes aim, cover, height, range, flank, crit, graze, normal/critical/graze damage **after armor**, shred, and ammo. Blocked lines end at the actual blocking tile. Enemy clicks preview first and confirm on a second click.
- Ranged weapons have four rounds; Reload costs one AP. Empty weapons cannot shoot or enter overwatch. Enemy weapons also reload. Weapon abilities reserve their declared ammunition.
- Jedi can Pull enemies into breakable obstacles or use Saber Breach on adjacent destructible cover. Boundary walls cannot be breached. Existing Push, armor shred, crit, graze and Hunker behavior is retained.
- Missions with `spec.concealed = true` (also accepts `spec.concealment`) start concealed. Spotted patrol detection tiles are red. An attack or entering detection breaks squad concealment and fires prepared ambush overwatch. Ordinary missions retain their existing open start.
- Legacy bond pairs enable Teamwork (one shared use per pair: transfer an AP and clear conditions) and, at level 4, Crossfire (one shared follow-up per pair). Legacy drills, +5 nearby bond aim, and level-8 +10 nearby aim/+10 will now affect battle. Campaign bond state is read, not mutated by the combat adapter.
- Missing web ability definitions and effect families are added, including explosives, Force control, saber techniques, assists and Momentum. Existing campaign ability picks are imported. Sentinel and Wayseeker have actual tactical templates. Direct-rescue kits expose additional techniques; campaign techniques use learned picks.
- HUD portraits use a closer crop. World health/armor/status labels keep a constant screen size; floating outcomes follow the camera. The ability bar scrolls, while End Turn stays visible.

## Structure

`game.gd` was split **before feature work**: scene/terrain/figure construction moved to `combat_scene.gd`. It is now below 600 lines. Combat camera, targeting, turn orchestration, ability extensions, concealment, bonds, loadout and capture helpers are separate `cam_*.gd` / `combat_*.gd` files.

`combat_mission.gd` extends the missions lane's `mission.gd`. `Mission.adopt(source, campaign_state)` preserves the already-created campaign mission, its RNG, map and unit state, then installs combat behavior. `game.gd:_ready()` uses this adapter without changing campaign-owned files. New combat state is consequently present in the real battle, not only in isolated fixtures.

## XCOM feature accounting

| Feature / feel gap | Status | Implementation or limit |
|---|---|---|
| Action camera; gap 1, recommendation 14 | ported | One camera owner, 0.60 s arrival gate, skip/off, result only after arrival/skip. |
| Target preview/confirmation; gap 2 | ported | Explicit target selection plus click/Enter confirmation; hover still explains blocked shots. |
| Movement confirmation; gap 3 | adapted | Existing pinned path/AP/cover/flank preview retained; input locks during activity. |
| Sequential enemy turns; gaps 4, 13 | ported | `combat_turns.gd` waits for each actor's event drain before invoking the next `AI.act`. |
| Activation scamper; gap 5 | ported | Reveal and route events in either phase, movement finishes before the next beat. |
| Destructible cover; rec 6 / gap 6 | adapted | Push/Pull collision, saber breach, explosives, Heavy fire and existing collapse; map density belongs to another lane. |
| Elevation/cover math; rec 1 / gap 7 | adapted | +20 elevated aim, directional 20/40 cover and existing range falloff retained. Weapon-specific XCOM range curves are not imposed on the tuned small-grid weapons. |
| Shared LOS and blocker trace; rec 5 | ported | `Shot.trace()` and `Shot.los()` share the same blocker/peek primitive. |
| Overwatch camera and interruption; gap 8 | adapted | First exposed route tile and camera beat. Existing flat −15 reaction aim is retained; a separate XCOM dash multiplier is not added. |
| Flank telegraph; gap 9 | ported | Cover direction, movement flank preview, target flank callout and crit bonus. |
| Two-beat action economy; gap 10 | adapted | Existing 3 AP, move 1 / dash 2 / shoot 2 retained to preserve the measured balance bands. AP/ammo costs are explicit. |
| Damage prediction; rec 9 / gap 11 | adapted | Normal/crit/graze damage bands after armor; shield/deflection can still reduce actual damage. No combined kill-probability estimator. |
| Crit/graze/shred | adapted | Existing +2 crit, half-damage graze band, armor mitigation and one armor shred per damaging weapon hit retained; labeled outcomes now share one timeline. |
| Concealment/ambush | ported | Mission opt-in, spotted detection tiles, route detection, squad reveal, prepared overwatch. |
| Role AI / rec 10 | adapted | Existing Jedi-hunting Sith, cover/flank/range/spread scoring and repeat-target penalty retained; lane overwatch and actual reloads are presented. |
| Hunker | adapted | Existing +30 defense and blocked flank crit retained; no extra XCOM dodge-50 roll. |
| Ammo/reload | ported | Four rounds, one-AP reload, weapon-ability costs, empty-fire guards, enemy reload. |
| Bonds in battle | adapted | Web 1–8 bonds and drills feed XCOM-style shared-charge teamwork/crossfire and proximity aim. |
| Objective route phases; gap 12 | skipped | Map/objective authoring is outside this lease; integrate the mission contract below. |
| Reinforcement direction; gap 14 | adapted | Existing spatial inbound marker retained; authored drop-site rotation remains with missions/maps. |
| Context camera; gap 15 | adapted | Shoulder, Force side framing, reveal, reaction and return; long flyovers/finale orbits omitted to keep beats brief. |
| Generic Interact | ported | Adjacent-tile targeting, one AP, defensive discovery of the mission-owned contract. Disabled on baseline maps until that API is integrated. Existing Free Mira remains usable. |

## Web presentation accounting

| Web source | Status | Port / deliberate adaptation |
|---|---|---|
| `view3d/cine.js` | adapted | Skippable shoulder, Force-side and reveal beats, off switch, camera ownership. Long intro/finale orbits and persistent browser settings omitted. |
| `view3d/forcefx.js` | adapted | Blue telekinesis, gold mind, green life, violet stasis; pull reverses wave, healing rings, barrier dome, area waves, saber techniques. Procedural Godot meshes replace Three.js primitives. |
| `view3d/effects.js` | adapted | Bolts, impact bursts, light flashes, waves, sparks, cover debris, bounded scorch marks retained/extended. No dedicated lightning, grenade-flight arc or returning thrown-blade simulation. |
| `view3d/figures.js` poses | adapted | Existing GLB aim/fire/swing/cast/hit/travel/down/get-up and cover poses retained; reload uses the procedural action fallback. Full browser bone/gear assembly is not duplicated. |
| `view3d/portraits.js` | adapted | Live Godot model portrait, close crop and current model identity; no browser canvas cache. |
| `view3d/labels.js` | adapted | World HP/armor/status labels, fixed screen size, camera-following outcome text; story speech bubbles remain with story integration. |
| `fx.js` | adapted | Ordered actor/target/route/intent/result dictionaries replace the browser wrapper bus. No game-wide monkey patches. |
| `legacy.js`, `data-legacy.js` | adapted | Pair key/level/drill representation, living-partner drill benefits, proximity and Unbreakable bonuses; battle actions use shared pair charges. |
| Web status effects | adapted | Stun, trick, disarm, root, mark, suppress, guard, hunker, shield, concealment, stable/down/revive; stable records rescue state but does not add a new bleed-out clock. |

## Balance and verification

Only new `combat_enemy_aim` fields were added to `difficulty.json`. Existing base tuning remains unchanged. The adapter applies these once to the starting enemies and newly spawned reinforcements; legacy tests instantiate the base Mission and keep their existing numbers.

| Difficulty | Base enemy aim modifier | Combat adjustment | Combat enemy modifier | New combat bot wins / 20 | Required band |
|---|---:|---:|---:|---:|---:|
| Story | −10 | 0 | −10 | 20 | 14–20 |
| Normal | +15 | −10 | +5 | 10 | 9–12 |
| Hard | +10 | −10 | 0 | 7 | 4–7 |
| Legend | +15 | −5 | +10 | 1 | 1–3 |

The combat bot uses the existing rescue policy plus a one-AP reload when empty; no seed-specific exceptions. Seeds 1–20. Original bot results remain **20 / 10 / 4 / 1**. HP, damage, clocks, engagement caps, reinforcement counts, cover and normal shot odds were not retuned.

- `./godot/test.sh`: exit 0; **367 tactical + 45 campaign + 225 story + 179 loop checks**, zero failures, no `SCRIPT ERROR`.
- `godot --headless --path godot -s tests/combat7_test.gd -- --bots`: **201 checks**, zero failures, including 80 seeded games and four balance-band assertions.
- Final focused suite: **117 checks**, zero failures (including the Ghost concealment regression and explicit two-enemy sequencing). The focused suite also explicitly exercises camera arrival, skip/off, per-actor sequencing, ammo guards, first exposed reaction tile, concealment/ambush, cover destruction, all added effect families, bond charges, and a fake implementation of the exact mission Interact contract.
- Real Godot **Wayland windows**, OpenGL compatibility renderer, not headless image mocks: [targeting](../shots/wave7-combat-targeting.png), [blocked trace](../shots/wave7-combat-blocked.png), [concealment](../shots/wave7-combat-concealment.png), [reaction camera](../shots/wave7-combat-reaction.png). The capture helper is `combat_capture.gd`; pass `--kind=... --output=/absolute/path.png`. Compatibility rendering reports the existing volumetric-fog limitation.

## Integration requests

1. **Missions:** implement `func interactables() -> Array[Vector2i]` and `func interact(unit: Dictionary, tile: Vector2i) -> Dictionary` in `mission.gd`. Return `{"ok": true}` (or `{"success": true}`) only after an objective action succeeds. Combat validates adjacency and AP, then sets AP to its pre-call value minus one; the objective implementation should mutate objectives and not charge a second action. Call sites: `combat_abilities.gd:interactables()` / `interact()`, via `Ability.tiles()` / `Ability.use()`.
2. **Missions turn lifecycle:** `combat_round.gd:begin(m)` / `finish(m)` were extracted from the baseline `Mission.end_turn()` so the real window can pause between enemy actors. Merge any new mission clock/objective/reinforcement behavior into these boundaries, or expose `Mission.begin_enemy_turn() -> void` and `Mission.finish_enemy_turn() -> void` and call those from both `CombatMission.end_turn()` and `combat_turns.gd:play()`. Do not replace the live path with a synchronous whole-turn resolve.
3. **Mission configuration:** set `spec.concealed = true` on the intended infiltration maps. Current rescue JSON intentionally remains untouched. `spec.concealment` is accepted as a boolean alias.
4. **Campaign/battle factory:** the real game already calls `CombatMission.adopt(...)` after `CampaignFlow.create_battle(7)`. Other callers that need the new rules should adopt their created Mission too. Keep adoption at one boundary; do not apply loadout/drill adjustments twice. The new combat suite uses the same adapter.
5. **Map/mission scope:** cover-density changes, new approach/evac phases and multiple authored reinforcement sites must be supplied by the map/mission lanes. Existing inbound markers continue to use `mission.reinforcement_marker`.
6. **Test runner:** append `combat7_test` to the suite list in `godot/test.sh` (not leased here). Use its `-- --bots` mode for the combat adapter's balance bands in addition to the legacy base-Mission bots.

## Web ability inventory

Every ability identifier declared in `public/js/abilities.js` is represented in the Godot ability data. Rows below distinguish a rule port from an adaptation; shared mission actions intentionally use the Interact contract instead of inventing objective state in this lane.

| Web ability | Status | Rule / reason |
|---|---|---|
| `shoot` | adapted | Existing shot math, now ammo and camera gated; destructible tiles use dedicated actions. |
| `strike` | adapted | Existing adjacent strike; no automatic dash-to-melee path. |
| `guard` | adapted | Existing defense/deflection; no new automatic adjacent saber reaction. |
| `overwatch` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `push` | ported | Existing rule retained. |
| `collapse` | ported | Existing rule retained. |
| `choke` | ported | Existing rule retained. |
| `stun` | ported | Existing rule retained. |
| `subdue` | adapted | Existing capture result retained; no extra envoy-intel rule in combat. |
| `meditate` | ported | Existing rule retained. |
| `heal` | ported | Existing rule retained. |
| `grenade` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `stabilize` | adapted | Marks stable and records rescuer; baseline downed units do not bleed out. |
| `liftUp` | adapted | Uses the existing two-HP revive convention. |
| `door` | adapted | Delegates to mission Interact; objective implementation integration required. |
| `console` | adapted | Delegates to mission Interact; objective implementation integration required. |
| `scan` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `plant` | adapted | Delegates to mission Interact; objective implementation integration required. |
| `saberThrow` | adapted | Existing ranged damage/pierce retained; simple saber trail instead of returning blade. |
| `defLine` | ported | Existing rule retained. |
| `leap` | ported | Existing rule retained. |
| `reflectM` | ported | Existing rule retained. |
| `sweep` | ported | Existing rule retained. |
| `forceHeal` | adapted | Keeps the existing friendly revive behavior as well as healing. |
| `barrier` | ported | Existing rule retained. |
| `battleMed` | ported | Existing rule retained. |
| `mindTrick` | ported | Existing rule retained. |
| `forceRevive` | ported | Existing rule retained. |
| `suppress` | ported | Existing rule retained. |
| `hunker` | adapted | Existing +30 defense and no flank crit. |
| `mark` | ported | Existing rule retained. |
| `smoke` | adapted | Existing area defense buff; no persistent volumetric smoke simulation. |
| `hack` | ported | Existing rule retained. |
| `shredder` | adapted | All existing damaging weapon hits retain one armor shred; Heavy cover damage retained. |
| `sense` | adapted | Extends concealed scouting visibility to 11; no separate hidden-horror subsystem. |
| `executioner` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `shadowStep` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `pathfinder` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `wildBond` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `beastCalm` | adapted | Creature-tagged or horror targets, shared stun rule at 75%. |
| `pull` | adapted | 90% pull, collision and breakable cover; no added falling damage. |
| `runGun` | ported | Existing rule retained. |
| `spotter` | ported | Existing rule retained. |
| `ghost` | ported | Existing rule retained. |
| `ionNade` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `holdLine` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `flurry` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `mightyBlow` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `precisionStrike` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `massHeal` | adapted | Heal and stable state; no new bleed clock. |
| `forceWave` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `stasisField` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `tremor` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `chainShot` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `shieldDrone` | adapted | Keeps the existing four-point shield rather than replacing it with directional cover. |
| `medBeacon` | adapted | Heal and stable state with mission charge. |
| `backup` | adapted | Real ally follow-up, squad turn limit; campaign bond-point gain is not written here. |
| `coverFire` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `handoff` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `moSurge` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `moRally` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `moStrike` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `snipe` | adapted | Aim/damage/crit bonus, 3 AP, one round. |
| `barrage` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `shieldWall` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `taunt` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `fanFire` | adapted | Three shots with penalties and three rounds; base weapon cost remains 2 AP. |
| `disarm` | ported | Implemented in shared ability/effect rules; validated before spending resources. |
| `protocol` | ported | Existing rule retained. |

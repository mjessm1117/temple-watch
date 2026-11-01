# Wave 7 — Temple and roster strategy

Branch: `wave7/strategy`. Sources: `WAVE7.md`, `PORT-INVENTORY.md`, `XCOM2-STUDY.md` recommendations 8 and 11 and strategy/roster evidence, `wave4/FEEL-GAP.md`, and the frozen web files listed below. Only leased files changed. No web files, XCOM code/assets, shared battle code, or other lanes were modified. No subagents and no push.

## Player-visible changes

The Temple retains its Wave 6 3D cutaway. Build now opens a stepped bay grid: select a bay, excavate it, place a wing, and fund construction. Power, specialist staffing and adjacent rooms affect production. Opening a wing shows its readiness, staff slots, power and current work. Staff figures inhabit assigned rooms; opened vaults and completed spires appear in the cutaway.

The Roster offers three monthly recruits, training-center work and squad doctrine upgrades. Soldiers return Tired, lose aim/will, and eventually become Exhausted if repeatedly deployed. Rest, healers and the Infirmary help rotation. Research includes a separate Forge project queue. Command opens Council votes, two selectable edicts and device settings. Teams offers expiring field jobs, soldier selection, detailed odds, casualty risks and operation reports. Legacy exposes personality voices, mentor relationships, secret hints/reveals and retired advisers.

**Integration boundary:** strategic behavior and Temple controls are implemented. Five/six-soldier battle launch, active learned abilities, live tactical voices/Padawan bonuses, the new Galaxy field panel and tactical settings require the explicit shared-file call sites below. The existing launch bridge still rejects squads other than four. Do not describe those tactical integrations as already playable in this lane alone.

## Feature coverage

| XCOM-style feature | Status | Implementation / adaptation |
|---|---|---|
| Build grid and excavation | adapted | Uses the web Temple's stepped bays; 5-day excavation reserves a free artisan. New rooms take 7 work days, advanced by rest or mission time. |
| Room power | ported | Starting supply 8; room draw 1–3; +4 relay upgrades. New builds reserve power. Overload pauses powered facilities. |
| Staff slots and specialists | adapted | Archivists, artisans and healers; 1 slot per room level, maximum 2, specialist matching, recruitment and reassignment. Original soldier staffing saves remain supported. |
| Adjacency | ported | Web wall-sharing geometry and all eight named link bonuses; staff doubles the bonus. Research, healing, bench XP, stress, monthly income and salvage actually pay out. |
| Infirmary and Tired soldiers | adapted | Fatigue 0–100; +38 per mission/operation, +15 if downed; Tired at 34 gives −5 aim/−10 will; Exhausted at 67 cannot deploy. Bench recovery, medical staff, rest and bacta projects matter. |
| Training center | adapted | 5 work days to retrain, unlock either of two extra ability slots, or learn an alternate early-rank ability. Passive picks affect stats; active picks exposed through the tested deployment adapter. |
| Proving-ground projects | adapted | Independent Forge queue: bacta reserve, reinforced field weave and attunement lens. Costs, research gate, artisan speed, persistence and permanent recovery/armor/Focus effects. |
| Covert operations | adapted | 2–3 unique fit soldiers, fee, stored risk/reward forecast, duration, ambush/wound/capture outcomes; capture requires rescue. Ambush is an off-screen wound outcome, not a new tactical ambush map. |
| Resistance-order policies | adapted | Four Council edicts, two active slots, one adoption per month, monthly upkeep and suspension when unpaid. Research, recovery, covert risk and salvage/Darkness tradeoffs. |
| Recruit pool | ported | Three candidates/month, Padawan in odd months; credit/recruit costs, Barracks capacity, stable candidate IDs and unique roster IDs. |
| Squad size upgrades | adapted | 4 → 5 → 6, veteran/Barracks gates, persistent purchases, loadout lineup and state validation; shared launch/spawn integration still required. |
| Per-wing staff/production/power/readiness | ported | Cutaway labels, hover details, room context, Build cards and bounded room logs; current research, engineering, training and medical activity shown. |

| Scoped web source / deferred behavior | Status | Implementation / adaptation |
|---|---|---|
| `temple-build.js`: placement/adjacency | ported | Stepped grid, excavation, placement, scaffold relocation, immutable completed placement, eight live links, staffed multipliers and room logs. |
| `temple-modules.js`: undercroft/spires | adapted | All four spires and their effects; three excavatable vaults with fixed Kyber cave, holocron and crypt discoveries. Fixed finds replace the random seven-find pool. Spires take 14 days and open at month 4/era 2. |
| `temple.js`: recruiting/quests | adapted | Monthly recruit pool and gear defaults; personal missions require their owner, pay once, retry only after advancing the story step. Family reward supplies the recruit token and hiring credits, rather than inserting an unselected soldier. |
| `temple-ui.js`: Council/recruit UI | adapted | Recruit cards, monthly Council vote with resource validation and aggregate loyalty, edict selection and veteran support. NPC seat replacement/per-seat loyalty is represented by aggregate Council loyalty. |
| `teams.js`: fatigue/detailed risk | adapted | Rank, actual leader, bonds, fatigue, missing members, difficulty and enemy/team power contribute to odds. Win wounds and loss wounds/capture/rare death; deployed team cannot recover during the same mission transit. |
| `fieldops.js`: spawning/expiry | ported | Monthly normal/covert offers, stable serial IDs, 30-day expiry, regional unrest, bounded history; active teams retain time/risk across saves. |
| `identity.js`: voices | adapted | All existing voice data, validated personality selection, event-line lookup and persistent mission quotes. Tactical speech-bubble/event playback is an integration request. |
| `identity.js`: Padawan proximity | adapted | Automatic available Knight/Master pairing and tested +10 aim within Euclidean distance 3, +1 mentor Focus on Padawan kill hook. Dynamic tactical calls remain for combat integration. |
| `legacy.js`: secrets | ported | Existing secret catalog; one-time mission/rank/down/bond/field-return hints, reveal at rank 4 or three milestones, personal-quest hook and Legacy presentation. |
| `legacy.js`: Council support | adapted | Retired Council advisers grant +5 squad aim/will once per month for 10 loyalty; generals advise once. Uses existing battle buffs, not extra NPC combatant slots. |
| `base.js` remainder | adapted | Native roster/loadout screens retain existing gear and promotion flows; new readiness, recruit, training and capacity controls; current fatigue included in mission-result summaries. Web DOM/modal wrappers are replaced by Godot controls. |
| `console.js` remainder | adapted | Command readiness counts, staff/power/12-segment Darkness readout, operation reports, room status and bounded facility logs. No duplicated scrolling browser ticker. |
| `ui-settings.js` | adapted | Device-local speed, cinematics, reduced motion, numbers, colorblind palette and tips controls. Temple motion/palette/tooltips and loadout ambient motion read them; shared tactical/UI consumers require integration below. |

The unrelated inventory entries owned by combat, missions, story, presentation and integration lanes are unchanged; their browser wrappers/assets are not silently claimed as ported here.

## Save and state contracts

The save envelope stays `{"v":2,"C":...}`. `_migrate()` calls `ensure_strategy()` after the existing story/roster migration. Old saves receive neutral fatigue, voice/lore/ability defaults, specialists, recruit candidates, spatial placement and enough relay capacity for existing rooms. Existing resources, research, roster IDs and wing levels remain intact. New queue dictionaries and operation forecasts are ordinary JSON data.

- `state.facility`: `clear`, `dig:{slot,left}`, `relay`, `build_left`, `workers:[{id,n,role,wing}]`, `next_staff`, `log`.
- `state.slots`: `{bay_id:wing_id}`. Placement uses existing `SLOTS`/`WING_HOME` tables.
- `state.mods`: `dug`, `features`, `spire`, `spire_work:{id,left}`. Existing module cooldown/battle-buff state remains in `state.modules`.
- `state.strategy`: squad upgrades, project queue/completions, training queue, edicts, monthly adoption/votes, aggregate loyalty, support reservations/use, and `team_deployed` transit reservations.
- Soldiers add `fatigue`, `ability_slots`, `extra_picks`, `voice`, `lore`, `quotes`; captured covert soldiers add `covert_captive`.
- `state.field`: existing list/log plus serial `n` and `spawn_month`; open offers contain `exp`, deployed offers contain `left`, `team`, `ch`, and snapshotted `risk`.

Time advances one day at a time inside `advance_days(days: int)`. This makes batching/reloading equivalent. Construction, training, research, engineering and field operations update before a crossed month pays income/edicts and spawns new offers. `advance_mission()` still advances `core.DAYS` (15), module cooldowns and legacy captive return counters. Covert captives do not auto-return. No new independent Darkness simulation was introduced.

### Hooks for the Sith lane

These are methods/signals on `campaign/state.gd`:

```gdscript
func ensure_strategy() -> void
func advance_days(days: int) -> void
func advance_mission() -> void
func gain(key: String, amount: int) -> void
func darkness_segments() -> int
func apply_mission_result(result: Dictionary) -> Dictionary
func field_risk(id: String, team: Array) -> Dictionary
func squad_capacity() -> int
signal month_advanced(month: int, snapshot: Dictionary)
signal mission_resolved(result: Dictionary, summary: Dictionary)
signal darkness_changed(segments: int, value: int)
```

- Connect `month_advanced` after `CampaignFlow.session()` creates/loads the campaign, and reconnect after new campaign/era replacement. Fires once for every crossed boundary, after Temple monthly accounting. Snapshot: `{day, elapsed_days, darkness_segments}`. Do not call `_month_tick()` again from the Sith subscriber.
- `darkness_segments()` is `ceil(orderDark * 12 / 100)`, clamped 0–12. It represents **Order Darkness**, not the galaxy's separate presentation estimate including personal Jedi darkness. Mutate Order Darkness through `gain("orderDark", delta)` to notify subscribers; direct dictionary assignment bypasses the signal. `gain` clamps to 0–100.
- `mission_resolved` fires after rewards, wounds, campaign time, fatigue, personal quests, pending-mission cleanup and refreshed offers. Arguments are deep copies. `summary.rows` adds `fatigue` and `readiness` and contains current wound days. Call `apply_mission_result` once per finished battle, as before. Add Sith consequences in a subscriber; do not reapply the result.
- Sith disruption can inspect `Base.power(state) -> {used,capacity}`, `Base.operational(state, wing) -> bool`, `Base.effects(state) -> Dictionary` and `Base.production(state, wing) -> String`. A power deficit pauses research/training/projects and rejects powered module actions. Relay capacity is `8 + 4 * facility.relay`.
- Rescue options expose `hostages:[roster_id,...]`. Winning the selected rescue releases those captured soldiers. `Ops.resolve(c, op, rolls:Array=[])` supports explicit four-roll fixtures; production calls omit rolls. Field resolution is idempotent once `op.st` leaves `team`.

## Integration requests

All additions named below already exist and have headless coverage. These changes belong in shared files outside this lease.

1. **Squad launch / capacity — `godot/scripts/campaign_bridge.gd:launch_squad(ids: Array) -> bool`.** Replace `ids.size() != 4` and the repeated availability loop with `strat_deployment.validate(campaign, ids, option)`. `option` is `pending_mission` when present, otherwise `state.options[state.launch_index]`. This validates uniqueness, fatigue, wounds, assignments, capacity and required quest owner. Update any shared briefing copy that still says exactly four. Until this is wired, five/six-unit lineups cannot launch.

2. **Distinct spawns and learned abilities — `godot/scripts/campaign/battle_bridge.gd:create(campaign, seed_value: int) -> RefCounted`.** Immediately after removing the default player units, call `strat_deployment.spawn_tiles(m, pending.squad.size()) -> Array[Vector2i]`; require a full result before spawning. Replace the modulo reuse of `m.spec.squad` with `tiles[i]`. After constructing each roster-backed `u`, call `strat_deployment.apply_identity(campaign, u, r) -> void`. This adds active learned picks to `u.kit`, the voice ID, mentor ID and Tired flag. It does not replace base class abilities or reapply stat bonuses. Passive perks, fatigue penalties, projects and quest bonuses already flow through `Gear.battle_stats()`.

3. **Live identity — tactical shot/event owners.** At `shot.gd:calculate(m, attacker, target, melee=false, modifier=0)`, locate the live mentor by the student's `master` roster ID and add the result of `strat_identity.proximity(campaign, padawan_id: String, distance: float, mentor_active: bool).aim` to the modifier. Use current Euclidean tile distance; do not permanently increment the unit's aim every refresh. On a credited Padawan kill, add `.kill_focus` to the living mentor's available Focus, clamped to its maximum. At `game.gd:_select` and hit/kill/down presentation events, use `strat_identity.voice_line(campaign, id: String, event: String, index: int=0) -> String`. Carry an actual memorable `quote` into that soldier's mission result to override the deterministic debrief fallback. Unavailable/dead/captured mentors give no bonus.

4. **Galaxy field panel — `godot/scripts/campaign/galaxy.gd:_field_panel() -> void`.** Replace its body with `Details.field_panel(self)`. The leased `galaxy_details.gd` now implements that function. Existing `_field`, `_toggle_field`, `_send_field` callbacks accept the strings it passes. `field_key` can be an offer ID (`fN`) or definition key; the panel resolves the selected open offer and dispatches by stable ID. Existing map pins may still pass definition keys. This replaces the obsolete menu of every operation definition, some of which are not currently offered. Temple → Teams already provides the complete functioning offer UI.

5. **Shared settings consumers.** `strat_preferences.get_value(key: String) -> Variant` and `set_value(key: String, value: Variant) -> bool` store device settings in `user://strategy-settings.cfg`, independently of campaign saves. Wire `speed` (0.5/1/2/4) into shared action/FX waits; `cine` into `game.gd:_action_cam`; `motion` into `game.gd:_glide_to/_shake` and `ui_motion.gd:_ready/_hover`; `numbers` into initial tactical Info state; `cb` into tactical faction markers; `tips` into the tutorial overlay. Temple's camera/galaxy motion, palette and room tooltips, plus loadout ambient camera motion, already consume their relevant values. Shared panel entrance tweens remain under the shared UI owner's control.

6. **Test runner — `godot/test.sh`.** Append `strategy_test` to the suite loop. The standalone file is already runnable; the runner is outside this lease.

The support system intentionally uses adviser buffs instead of extra Council NPC combatants. Adding those extra fighters would require roster-independent tactical identity, loss handling and additional spawn/selection rules; no placeholder NPC slots are sold to the player here.

## Validation and screenshots

Commands used with Godot 4.7.2:

```sh
./godot/test.sh
/home/jess/projects/.tools/godot/godot --headless --path godot -s tests/strategy_test.gd
/home/jess/projects/.tools/godot/godot --headless --path godot -s tests/temple_view_test.gd
/home/jess/projects/.tools/godot/godot --headless --path godot -s tests/loadout_test.gd
/home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility -s tests/strategy_test.gd -- --capture-strategy
```

- Existing runner: **898 checks, 0 failures**, exit 0, no `SCRIPT ERROR` (367 rules/bot, 45 campaign, 225 story, 261 loop).
- Bot wins per 20 seeds: **Story 20, Normal 10, Hard 4, Legend 1**; all required bands maintained.
- New strategy suite: **119 checks, 0 failures**; rendered capture run: **124 checks, 0 failures** including five PNG writes.
- Existing Temple view: **154 checks, 0 failures**. Existing loadout: **75 checks, 0 failures**.
- Checks cover spatial/power/staff gates, adjacency, construction and excavation, research acceleration, vault/spire effects, recruitment, Tired stats and recovery, training/projects, squad-capacity validation, six unique legal spawn tiles, field outcomes/expiry/rescue, votes/edict upkeep/support, secrets/quests/proximity/voices, active-queue save/load and daily-versus-batched time, and native page/grid controls.
- GDScript files remain below 600 lines; `git diff --check` passes. Godot printed ObjectDB shutdown warnings in some rendered/base/loadout runs (also seen in the existing loadout test), but no script errors or failed assertions.

The following are actual 1366×768 Godot window captures on `DISPLAY=:0` using the Compatibility renderer (Intel OpenGL). They use an isolated developed-Temple fixture, not the player's save:

- [3D Temple with staffed rooms, vaults and spires](../shots/wave7-strategy-temple.png)
- [Stepped build grid and power](../shots/wave7-strategy-build.png)
- [Monthly recruits and squad doctrine](../shots/wave7-strategy-roster.png)
- [Council edicts](../shots/wave7-strategy-council.png)
- [Field-team selection and risk](../shots/wave7-strategy-teams.png)

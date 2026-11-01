# Wave 7 — Sith strategy layer

Implemented on `wave7/sith`, entirely within the Sith lease. The new logic, report scene, and tests run independently. **The main campaign does not call this layer yet:** the integration pass must connect the hooks below. Tactical rival behavior and the authored stronghold/conduit objectives require the combat and missions lanes; this lane supplies their contracts, scheduling, and persistent consequences.

## Sources and feature coverage

Read `WAVE7.md`, `docs/XCOM2-STUDY.md` (especially recommendations 12–13 and section 6), `wave4/FEEL-GAP.md`, `wave5/PORT-INVENTORY.md`, the existing Godot campaign/bridge, and frozen `temple-ops.js`, `temple-prog.js`, `darkness.js`, `data-campaign.js`, and the extra operations in `data-modules.js`. XCOM input is mechanics and tuning recorded in the local design study. No XCOM code, assets, names, dialogue, or interface art were imported. Rival portraits are original GDScript drawing geometry.

| Source / feature | Status | Implementation or adaptation |
|---|---|---|
| XCOM recommendation 13: named recurring rivals | Adapted | Darth Veyra, Lord Korr Vash, Darth Nyss; two strengths and weaknesses each, identity-specific spawn records, persistent encounters. |
| Rival knowledge | Adapted | +4 per month from the study; +4 after a player victory, +8 after a setback; capped at 100. Health grows by 2 per 24 knowledge. |
| Ambush and kidnapping | Adapted | Staggered first attacks on days 14/21/28, then 28-day scheduling; ten-day response windows. At 24 knowledge, attacks become abduction attempts. Failed/ignored defense captures an eligible, unassigned unit and offers a repeatable rescue. |
| Stronghold and final pursuit | Adapted | Two field victories locate a stronghold; its defeat unlocks a final pursuit. Failed stronghold/pursuit missions can be retried. Final victory permanently removes the rival and frees their captives. Tactical maps/behaviors are integration requests. |
| Every rival defeat reveals a countermeasure | Adapted | Four authored, distinct revelations per rival: two encounters, stronghold, pursuit. Spawn records carry the practical conditional modifiers. |
| Monthly Dark Events | Adapted | One operation in months 1–2, two thereafter, with one concealed from month 3. One counter-mission choice per month; victory stops it. Other open operations land at the boundary. |
| Hidden operations | Adapted | Public operation records hide identity/effects. Reveal costs 1 Intel, or commit to a blind intercept. Uncountered threats are revealed in the report. |
| XCOM recommendation 12: reversible influence project | Adapted | Twelve Darkness segments, distinct from existing Order Darkness (0–100). Starts at 2; +1 every 30 days. Conduit victory −2, stronghold −1, final pursuit −2. |
| Escalation and recovery deadline | Adapted | Next escalation date is visible. Twelve segments start a fourteen-day last stand; any reduction cancels that deadline. Failure closes the strategic campaign. Fourteen days is Temple Watch tuning, not a claimed XCOM constant. |
| Retaliation triggers | Adapted | Countered/completed operations, ignored crises, conduit strikes, rival defeats, and 74+ rival knowledge raise pressure. Threshold 3 creates a ten-day sanctuary defense; one pending defense and a thirty-day cooldown prevent duplicate raids. |
| Month-end council report | Adapted | Immutable monthly snapshots record wins/losses, operation outcomes, ignored crises, rival knowledge/defeats, mentorship, Darkness and its next escalation. Latest report has a standalone screen. Host income/upkeep remain the host's report responsibility. |
| Web: eight base Sith ops | Ported | Fortify, snipers, surge, spies, propaganda, supply, kyber raid, bounty: original costs/effects/durations, including wounds and stress. Resource drains clamp at zero. |
| Web: additional Sith ops | Ported | Saboteurs jam two built wing actions for three missions; ritual adds 5 Order Darkness; hunter wounds the highest-rank active unit for 14 days and adds 30 stress. |
| Web: Intel counter / codebreak discount | Ported | Original per-operation Intel price, reduced by 1 with `codebreak`, minimum 1. Hidden operations must first be revealed for an Intel counter. |
| Web: two-unit covert counter | Adapted | Original 50 + 6 × summed rank odds, cap 95; +15 XP on success, +20 stress on failure. Both units unavailable while away. Resolves after next battle, or at month end before operation consequences if no battle occurs. |
| Web: modifiers expire after missions | Ported | Tactical modifier snapshot plus idempotent, unique-result-based consumption. Duplicate results cannot consume extra uses. |
| Web: mercy | Ported | Two points remove 1 personal Darkness, maximum 2 reductions per Jedi per battle. Heal/capture = 1; spare surrendered foe = 2. Unique action IDs prevent duplicate credits; no carry between battles. |
| Web: mentors / Counsel | Ported | Padawans use `state.pairs`; other Jedi can select an active rank-4+ Knight/Master. Light mentor (≤2) pulls down, dark mentor (≥7) pulls up, one per month toward mentor. Simultaneous calculation avoids roster-order effects. |
| Web: redemption remainder | Ported | One attempt per Jedi per era at Darkness ≥6; requires that Jedi deployed. Victory −4 Darkness/−20 stress; failure +1 Darkness. New eras restore eligibility. |
| Web: Gardens | Skipped (already present) | Existing `state.gd:_month_tick()` owns personal meditation and staffed Gardens; this extension deliberately does not apply those effects twice. |
| Web: five `data-campaign.js` crises | Adapted | All five definitions and exact ignore penalties included. Two rotate each month, expiring individually instead of only when a story choice advances. Existing story crisis offers remain host-owned; avoid duplicate scheduling when integrating. |
| Web unrelated research, arsenal, stress/scar UI | Skipped (outside lane) | Existing Godot systems remain read-only. Only operation consequences, mercy, mentorship, and redemption are implemented here. |

## Player-visible changes

Open `godot/scenes/sith_report.tscn` directly for a disposable, simulated month-three preview. It has three tabs: Sith Operations, Rival Dossiers, and Council Report. It does not touch campaign saves. A host can instead call `bind_state(campaign_state)` before adding it to the tree.

The persistent Darkness strip shows twelve segments, the next escalation or collapse date, and the three recovery routes. Operation controls reveal threats, spend Intel, or select a counter-mission. Mission selection emits a signal; it never invents a battle victory. The rival dossiers show portraits, strengths, weaknesses, knowledge, and every revealed countermeasure. Lower dossier details and additional missions are scrollable. The report shows the actual previous month's snapshot.

Real-window captures were taken on the available Wayland display with the compatibility renderer, at 1366×768 and 1920×1080 (the project's normal canvas scaling remains enabled):

| Screen | 1366×768 | 1920×1080 |
|---|---|---|
| Operations | [View](../shots/wave7-sith-operations.png) | [View](../shots/wave7-sith-operations-1920.png) |
| Rival dossiers | [View](../shots/wave7-sith-rivals.png) | [View](../shots/wave7-sith-rivals-1920.png) |
| Revealed counters, scrolled | [View](../shots/wave7-sith-rival-counters.png) | [View](../shots/wave7-sith-rival-counters-1920.png) |
| Council report | [View](../shots/wave7-sith-report.png) | [View](../shots/wave7-sith-report-1920.png) |

## API and persistence

```gdscript
const SithLayer = preload("res://scripts/campaign/sith_layer.gd")
var sith = SithLayer.new(state) # Dictionary, not the Campaign object
```

All extension persistence is JSON-compatible under `state.sith`: deterministic RNG, monotonic local day, rivals, operations, mission instances, modifier uses, pending events, result/action ledgers, and reports. It also changes host roster/resources for documented consequences. It never increments `state.day`, `state.month`, or `state.elapsed_days`, never accesses a scene, and never writes a save. Reconstruct it whenever the host replaces its state dictionary on load. A new extension attached to an older save starts at that save's elapsed day, without replaying past events.

| Signature | Contract |
|---|---|
| `advance_day() -> Array` | One extension day; returns newly queued events. Handles expiries, escalation, monthly processing, rival scheduling, then collapse. No-op after defeat. |
| `month_end() -> Dictionary` | Boundary-only and idempotent. Already called by `advance_day`; returns the last report on repeated calls, or `{}` before the first boundary. |
| `pending_events() -> Array`, `acknowledge(event_id: String) -> bool` | Deep-copy event queue; explicit acknowledgement, no destructive polling. |
| `mission_options() -> Array` | Deep-copy open offers, including eligible redemption missions. Each has `id`, `sith_offer_id`, `mission_id` (unique extension ID), `mission` (host template), `kind`, `deadline`, `status`, `n`, and kind-specific payload. |
| `counter(op_id: String, mission_id: String) -> bool` | Reserve this month's single counter-mission choice using its exact extension mission ID. Repeating the same choice is safe; another choice is rejected. Does not count as a victory. |
| `resolve_mission(mission_id: String, won: bool, outcome: Dictionary = {}) -> bool` | Once-only resolution of an open extension offer, before advancing time. Redemption needs `outcome.deployed: Array` of roster IDs; abduction may specify `captive_id`. Unknown, expired, completed, unselected counter missions are rejected. |
| `after_mission(result_id: String) -> bool` | Call once for **every** completed battle after applying mercy and extension mission consequences, before advancing time. Expires old modifiers/jams and resolves covert teams. Stable unique deployment/result ID required. Replaying a map needs a different result ID. |
| `operations() -> Array` | Redacted public operation snapshots. Do not display private `state.sith.ops` or raw mission dictionaries. |
| `reveal_operation(op_id: String) -> bool`, `counter_with_intel(op_id: String) -> bool` | Validates phase and budget, spends Intel, never overspends. |
| `send_team(op_id: String, unit_ids: Array) -> bool` | Exactly two distinct active, unwounded, unassigned roster units, neither in the current deployed squad. |
| `campaign_mods() -> Dictionary`, `wing_jammed(wing: String) -> bool` | Battle keys `enemyAim`, `enemyHp`, `extraEnemies`, `squadAim`; wing action availability predicate. |
| `rivals() -> Array`, `rival_for_mission(mission_id: String) -> Dictionary` | Dossier snapshots / spawn record for an open rival offer. Spawn includes identity, archetype, HP, aim, armor, strengths/weaknesses, knowledge, revealed conditional modifiers, phase, final-pursuit flag. Empty for unknown/closed/non-rival missions and eliminated rivals. |
| `project_status() -> Dictionary` | `segments`, `maximum`, `next_escalation`, `collapse_day` (−1 when inactive), `defeated`. Dates are absolute extension elapsed days: day 0 = month 1 day 1. |
| `retaliation_trigger(reason: String, pressure: int = 1) -> void` | Host-side events can contribute pressure. Extension-owned mission events already do so. |
| `mercy(unit_id: String, result_id: String, action_id: String, points: int = 1) -> int` | Returns actual Darkness reduction; counts verified successful events only, action deduplication per actor/result; rejects a result already closed by `after_mission`. |
| `set_counsel(student_id: String, mentor_id: String) -> bool` | Validated non-Padawan mentor selection; empty mentor ID clears. |
| `set_crisis_schedule(enabled: bool) -> void` | Disable the rotating crises when the host already schedules them. Cancels open rotation offers without penalties; re-enabling resumes next month. |

Other helpers are implementation utilities. The 30-day calendar follows the host. Enemy arc/time persist when `state.era` changes; redemption attempts are era-scoped. This is a continuous strategic arc, rather than the web port's operation reset per era. Do not reset the extension day when the host resets its story-era elapsed counter.

## Integration requests

1. **`state.gd:new_campaign()` and `_migrate()`**: add `const SithLayer = preload("res://scripts/campaign/sith_layer.gd")` and `var sith: RefCounted`; bind `sith = SithLayer.new(state)` after roster migration and before `refresh_options()`. Existing save serialisation already includes `state.sith`. **`advance_days(days: int)`** needs chronological daily iteration: after the host increments one day and runs its existing `_month_tick()` at a boundary, call `sith.advance_day()` exactly once. Do not add a second monthly call. Preserve host healing/research/assignment pacing when refactoring. Bulk-applying all host months before all extension days would misorder Gardens, raids, wounds, and mentorship.

2. **`state.gd:refresh_options()` and `select_mission(index: int, squad: Array = [])`**: append adapted `sith.mission_options()` and retain `sith_offer_id` in `pending_mission`. The host's `pending_mission.mission_id` must remain the **template** (`offer.mission`), since Story and Battle use it for briefing/map lookup; pass the unique **`sith_offer_id`** to Sith APIs. For `kind == "counter"`, validate/reserve `sith.counter(offer.op_id, offer.id)` before committing deployment. Replace the old bare redemption-offer block with this layer's validated offers. In the existing story campaign, call `sith.set_crisis_schedule(false)` during binding so story-owned crises retain their existing choice/ignore rules; the standalone rotation is for campaigns without that scheduler. Do not merely hide rotation offers: that would leave invisible expiry penalties. `default_squad()`/launch validation must require the redemption `unit_id` and exclude all `sith_op:` assignments.

3. **`state.gd:apply_mission_result(result: Dictionary)`**, after writing roster `dark`/status from tactical results but **before** `advance_mission()`: credit verified mercy actions using the stable deployment result ID, call `sith.resolve_mission(selected.sith_offer_id, win, {"deployed": selected.squad})` when present, then `sith.after_mission(result_id)` for every battle. This ordering prevents host result copying from overwriting redemption/mercy and stops new month-end modifiers from losing a use immediately. Preserve `pending_mission` until this completes. The existing `CampaignFlow.finish_result()` guard remains the outer once-only application guard. Store a unique deployment ID when selecting a mission; do not use the recurring template name as that ID.

4. **`state.gd:advance_days()` captive handling / `apply_mission_result()` hostage release**: units with `sith_captor` must not run the existing automatic `capT` release branch. Only their matching rescue or final rival defeat releases them. Suppress the generic hostage-release branch for extension rescue missions; `resolve_mission()` performs the scoped release and retry logic. Existing ordinary captures continue using the old behavior.

5. **`campaign/battle_bridge.gd:create(campaign, seed_value: int)`**: read `campaign.sith.campaign_mods()` before tactical setup; map `squadAim` to player aim, `enemyAim`/`enemyHp` to enemy stats, and carry `extraEnemies` to each reinforcement wave. Obtain `campaign.sith.rival_for_mission(pending.sith_offer_id)` for a rival spawn. Its numerical stat values and trait/countermeasure modifiers are supplied, but combat must implement the conditional rules (marked evasion, suppressed aim, explosive shred, disorient cancelling rally, guarded will, melee interrupting siphon, attacker aim/armor bypass). Do not add these rivals to baseline rescue-bot tests implicitly. **`modules.gd:ready(campaign, wing: String)`** must also require `not campaign.sith.wing_jammed(wing)`.

6. **Missions lane / `Mission.interact(unit, tile) -> Dictionary`, `Mission.interactables() -> Array[Vector2i]`**: create authored objective variants keyed by extension offer kind, retaining the existing host mission template for briefing. `project`: plant two conduit charges and extract; `stronghold`: destroy its focus and defeat the named rival; `pursuit`: defeat the named rival before extraction; `rescue_rival`: recover the listed `hostages`; `retaliation`: defend sanctuary/civilians before its fall. `counter` uses the chosen operation's template; `kidnap` is abduction prevention, not an already-captured-unit rescue. Report `won` only when the corresponding objectives complete. This lane does not call missing Interact methods or pretend the fallback rescue map implements these objectives.

7. **Combat successful healing/Subdue result recording and `campaign/battle_bridge.gd:result()`**: include `{unit_id, action_id, points}` mercy events with a stable per-action ID. Credit only actual HP restoration, revive/stabilize transitions, or successful captures; 2 points for sparing a surrender, otherwise 1. Forward these through request 3 after tactical `dark` has been persisted. Do not award another copy in a tactical wrapper. Add roster Counsel controls using `set_counsel()`; existing Padawan pairing should populate `state.pairs[padawan_id] = master_id`.

8. **`galaxy.gd:_build()` / `_show_details()` and campaign scene navigation**: add a Sith Intelligence entry to `res://scenes/sith_report.tscn`, bind the live dictionary before `_ready`, connect `state_changed` to host save, `close_requested` to the prior screen, and `mission_requested(offer: Dictionary)` to the existing briefing/squad route with the adapted offer. `galaxy_map.gd:refresh_signals()` and `galaxy_details.gd:region_panel()` should consume `sith.operations()` instead of the inert imported `state.ops.list`. Respect redaction. Surface `pending_events()` at the Temple, acknowledge after showing, open the Council Report for its event, and route `campaign_defeat` to the loss flow. Block further campaign deployment/rest after `project_status().defeated`; the layer itself already refuses advancement/results.

9. **`godot/test.sh`**: add `sith_test` to its suite list. This lane cannot change the shared runner under its lease; the suite is directly runnable now.

## Validation

- `/home/jess/projects/.tools/godot/godot --headless --path godot -s tests/sith_test.gd`: **499 checks, 0 failures**, no SCRIPT ERROR. Includes all twelve monthly reports, daily active/idle year simulations, all three complete pursuit arcs, every operation effect, both covert-team outcomes, expiry/retry/idempotency, mercy/mentors/redemption, three UI tabs at both sizes, real UI mutations, and deterministic JSON round-trip at day 180. JSON numeric key normalization and canonical mission ordering have explicit annual regression coverage.
- `./godot/test.sh`: **367 combat + 45 campaign + 225 story + 179 loop checks, 0 failures**, exit 0, no SCRIPT ERROR. Bot wins: **Story 20/20, Normal 10/20, Hard 4/20, Legend 1/20**, identical before and after this lane. The pre-existing combat suite reports 12 ObjectDB exit leaks in both runs; no new suite reports leaks.
- Real-window harness: `godot --path godot --display-driver wayland --rendering-method gl_compatibility -s scripts/campaign/sith_capture.gd` and the same command with `-- wide`. All screenshots saved successfully; inspected the resulting images. The display environment prints EGL/X11 fallback diagnostics; the Wayland window renders successfully on Mesa Intel.
- All new GDScript files are below 600 lines. No shared gameplay/source files, frozen web files, or existing assets changed. No external dependencies, saves, pushes, or subagents.

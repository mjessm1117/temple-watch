# Wave 7 integration

Branch: `wave7/integrate`. Integrated lanes: missions `27b837e`, combat `fea3c8d`, Sith `f2e640a`, strategy `daba301`. Godot 4.7.2. All changes are within the integration lease; the web game is unchanged. No subagents or push.

## Player-visible changes

A new campaign now owns the Sith layer, introduces its intelligence panel, advances its daily clock alongside the Temple, and opens the Council Report at month end. Galaxy exposes live Dark Events, one counter-operation choice, rival operations and their follow-up arcs, field-team offers, and the shadow conduit. The header distinguishes **Order Darkness /100** from **Sith Darkness /12** and shows the next escalation day. Save migration supplies missing Sith state; advancing to a new era starts its strategic clock again.

Deployments use their authored maps, themes, props, concealment, deadlines and objectives. Interact frees prisoners, copies terminals, plants charges, breaches relays and saves civilians. Optional safe/risky console rewards remain separate from copying the primary terminal; security droids on hack maps can be controlled. Relays accept weapon fire, barrels explode, beasts can be calmed, reinforcement markers announce arrivals, and objective completion switches the HUD to extraction. Escort movement can use any free extraction tile; couriers now move their authored mobility.

Named rivals appear with live stats and countermeasures. Strongholds require both the focus and rival to fall, pursuits require defeating the rival before extraction, abduction prevention escorts a still-free target, rival rescues release only matching captives, and retaliation uses civilian rescue objectives. Temple jams, mission modifiers, mercy, Counsel and mentor pairing affect the actual campaign.

Squad doctrine launches five or six soldiers on distinct tiles, including learned and trained abilities. Fatigue/wounds, covert captures and rescues, live Padawan proximity/focus, personality lines and remembered debrief quotes cross the battle boundary. Voice lines are the lane's text dialogue, not new recorded speech. Tactical speed, action camera, reduced motion, initial Info, faction colors and tutorial preferences have shared consumers.

The action bar keeps core actions visible and expands techniques separately. Nearby unit labels are suppressed around higher-priority labels, with compact numeric HP. Temple room labels are sparse by default and expand on hover. Galaxy map labels favor the selected/hovered operation. Late eligible crisis choices launch two fronts with separate squads, deferred time advancement, a Front B banner, auto-resolution and stand-down controls.

## Integration request ledger

Every numbered request below refers to the matching lane report's **Integration requests** section. All are wired; no requested integration is skipped. Implementation adaptations are stated explicitly.

| Lane / request | Status | Wiring / resolution |
|---|---|---|
| Missions combat 1 — Interact | wired | Generic action and keyboard 5 call mission targets/Interact through the live ability path; mission owns the single AP charge. |
| Missions combat 2 — HUD, scouting, prisoner | wired | Family status/clock/phase in HUD, spotted enemies render independently of activation, inactive prisoners stay off-screen. |
| Missions combat 3 — renderer | wired | Modern scenes build `map_presentation`, apply theme lighting and refresh objective/overwatch/inbound markers; legacy fixture keeps its renderer. |
| Missions combat 4 — camera | wired | Board dimensions determine initial framing; edge scroll excludes HUD panels. |
| Missions combat 5 — objective fire/events | wired | Validated relay weapon action spends two AP and one round; objective/VIP/reinforcement events have live playback. |
| Missions combat 6 — reward hacks/droids | wired | Safe/risky techniques expose `MissionHack.options` and call mission-owned RNG/cost/effects; authored hack maps contain a droid-tagged security unit using an existing model. |
| Missions combat 7 — Calm/barrels | wired | Successful Beast Calm reaches mission swarm state; destroyed barrels apply three damage in a 3×3 area and can chain. |
| Missions campaign 1 — front launch | wired | `select_mission` calls `Fronts.launch` before ignore consequences and preserves `fewer`/deferral. |
| Missions campaign 2 — front settlement | wired | `Fronts.finish` precedes advancement; Front A preserves date, step and Front B choices; final receipt advances once. |
| Missions campaign 3 — squads/banner | wired | Doctrine capacity, Front B max four/min two/max two Jedi and used-ID exclusion apply in loadout and launch; galaxy/debrief show the second front. |
| Missions campaign 4 — auto/stand down | wired | Galaxy controls use service receipts, rewards/promotions/favor/unrest and one advancement; captive rescues cannot auto-resolve. |
| Missions campaign 5 — result/briefing | wired | Map/family/metrics/objective/civilian/hack fields cross bridge; successful hack intel is settled; briefing resolves selected layout/family. |
| Missions regression — runner | wired | `missions_test` is required by `test.sh`. |
| Missions regression — obsolete fallback | wired | Hetzal assertion now requires its own authored map, with no fallback reinstated. |
| Combat 1 — Interact contract | wired | Reconciled with missions' final contract: objective code charges AP; combat validates and delegates without charging twice. Test mock follows that contract. |
| Combat 2 — lifecycle | wired | Shared mission begin/actor/finish methods serve both synchronous tests and asynchronous live turn playback. |
| Combat 3 — concealment | wired | Authored flag initializes combat concealment; mission interaction and reveal clocks update it together. |
| Combat 4 — adoption boundary | wired | Campaign factory returns adopted combat missions; adoption is idempotent, preventing duplicate loadout/drill adjustments. |
| Combat 5 — map scope/inbound | wired | Authored terrain, entry sites, phases and mission-owned pending waves render in real battle. |
| Combat 6 — runner/bots | wired | `combat7_test` joins runner; adapter rescue bands also checked with `-- --bots`. |
| Sith 1 — lifecycle/save | wired | New/migrated campaign binds layer; host days and monthly host effects run chronologically; `advance_day` invokes its own idempotent `month_end`, without a duplicate call. |
| Sith 2 — offers/counters | wired | Stable `sith_offer_id` remains distinct from template ID, counters reserve the chosen event, redemption requires its soldier, assignments exclude unavailable units; story owns crisis scheduling. |
| Sith 3 — settlement ordering | wired | Tactical darkness/status first, verified mercy then Sith result then `after_mission`, all before time advancement; deployment serial supplies unique result IDs. |
| Sith 4 — captives | wired | Sith captives bypass automatic release and generic rescue; matching extension outcomes handle release/retry. Covert captives retain their ordinary rescue path. |
| Sith 5 — battle modifiers/rivals/jams | wired | Squad/enemy stats and extra reinforcements consume modifiers; named rival conditional evasion, suppression, shred, rally interruption, will, siphon interruption and learned counters execute; jams gate modules. |
| Sith 6 — objectives by offer | wired | Project→two-charge sabotage; stronghold→relay plus rival; pursuit→rival plus evac; rescue→scoped hostages; kidnap→VIP prevention; retaliation→civilian family; counter→operation template. |
| Sith 7 — mercy/Counsel/pairs | wired | Only actual heal/revive/stabilize/capture changes produce unique mercy actions; surrender captures score two. Counsel filters eligible masters; recruits acquire identity/pairing. |
| Sith 8 — galaxy/navigation/events/loss | wired | Live-bound dossier saves changes, returns to campaign screens and routes offers through briefing/loadout. Signals and risk consume live operations and respect redaction. Temple shows then acknowledges notices; Council Report opens automatically; defeat blocks rest/deploy and returns to menu. |
| Sith 9 — runner | wired | `sith_test` joins required runner. |
| Strategy 1 — squad capacity | wired | Shared launch validates availability, capacity, assignments, fatigue, wounds and required owners. |
| Strategy 2 — distinct spawns/abilities | wired | Factory uses `spawn_tiles` and `apply_identity`; active learned/trained picks join class abilities without reapplying passive stats. |
| Strategy 3 — live identity | wired | Aim queries current mentor distance/availability, Padawan kills restore living mentor focus, select/hit/down/kill produce identity lines and actual result quotes. |
| Strategy 4 — field panel | wired | Galaxy delegates to `Details.field_panel`, using stable IDs for currently open offers. |
| Strategy 5 — preferences | wired | Shared camera/action/FX/unit animation timing, reduced motion, initial Info, marker palette and tutorial consumers use device preferences. |
| Strategy 6 — runner | wired | `strategy_test` joins required runner. |

The strategy lane's adviser-buff support model is retained; this integration does not introduce additional Council NPC combatants. Rival/security units reuse existing models. These are inherited presentation choices, not omitted integration requests.

## Validation

Initial required import: `/home/jess/projects/.tools/godot/godot --headless --editor --import --quit` in `godot/` completed successfully.

Final commands:

```sh
./godot/test.sh
/home/jess/projects/.tools/godot/godot --headless --path godot -s tests/combat7_test.gd -- --bots
./godot/campaign-test.sh
```

`./godot/test.sh` exited **0**: **2,627 checks, zero failures**, no `SCRIPT ERROR`, parse error or `ERROR:`. All eight requested standalone suites run individually inside that gate. Counts: rules/bots 367; campaign 45; story 225; loop 348; Sith 499; strategy 119; combat 118; missions 516; Temple 154; loadout 75; galaxy 62; screens 38; integration 61. The additional adapter-bot run passed 202 checks. `./godot/campaign-test.sh` exited **0**, with 140 completed battles and no safety stops. All GDScript files are below 600 lines (largest: 589); `git diff --check` passes.

`integration_test` exercises the real campaign/scene route: new state → day 30 → automatic Council Report; a live galaxy counter selection → briefing; five-soldier loadout → actual battle; UI Interact → two sabotage objectives → evac phase. It also checks six unique spawns, learned/trained skills, live mentorship, stronghold result progression, modifiers, captives, two fronts, verified mercy, reward hacking, droids, barrels and relay ammunition/AP. The Interact UI check uses an explicit adjacent-position fixture; the separate campaign bot walks and fights normally without teleports or synthetic outcomes.

Test fixture updates account for initial Sith offers/notifications and the new single-charge Interact contract. Existing story, codex-return, mission and action assertions remain in place. The runner still rejects nonzero exits, errors, parse errors, script errors and failure counts.

### Rescue fixture bands (20 games each)

| Difficulty | Required wins | Base mission | Combat adapter |
|---|---:|---:|---:|
| Story | ≥14 | 20 | 20 |
| Normal | 9–12 | 10 | 10 |
| Hard | 4–7 | 4 | 7 |
| Legend | 1–3 | 1 | 1 |

### Campaign families — Normal, 20 seeds each

The new campaign bot launches through `Campaign.select_mission` → `Battle.create` → `CombatMission`, walks, fights, interacts and extracts using real rules, then applies `Battle.result` to the campaign. Each seed starts with the ordinary four-soldier Normal roster; authored layout variant 0 gives a reproducible sample. This measures seven representative layouts, not every generated layout or advanced roster. A 60-turn safety stop is a test failure, not a scored defeat.

| Family | Mission | Wins | Win rate | Mean turns |
|---|---|---:|---:|---:|
| Rescue | rescue | 8/20 | 40% | 5.0 |
| Hack | archive | 14/20 | 70% | 8.1 |
| Relay | dock | 9/20 | 45% | 6.5 |
| Defend | relay | 16/20 | 80% | 12.2 |
| Retaliation | r_hospital | 16/20 | 80% | 9.7 |
| Sabotage | sabotage | 13/20 | 65% | 7.3 |
| Ambush | adraasHunt | 9/20 | 45% | 2.9 |

Early samples exposed genuine rule defects (blocked first evacuation tile, courier mobility incorrectly charged per tile) and bot defects (hidden-enemy filtering, defense scouting and leaving extraction to chase enemies). These were corrected before final results. Initial uncorrected family samples were rescue 2/20, hack 19/20, relay 20/20, defend 0/20, retaliation 10/20, sabotage 20/20 and ambush 20/20; they are diagnostic baselines, not a controlled tuning comparison.

Normal-only family tuning lives in `godot/data/maps/balance.json`: rescue deadline 5; hack 8; relay deadline 6/integrity 24; defense integrity 36; sabotage 6 turns after reveal; courier mobility 7/base HP 12; retaliation civilian pressure every three turns. These changes apply to authored mission families, leaving the standalone rescue fixture and its required difficulty bands intact. Other difficulties retain their authored tuning. Final family checks enforce the requested 30–80% interval.

## Real-window screenshots

Captured from a native 1366×768 Godot Wayland window using the Compatibility renderer on Mesa Intel, with `scripts/wave7_capture.gd`. The isolated developed review save is deleted afterward; it uses day 30 and one unlocked squad doctrine to expose the requested screens. No composite/mock UI or player's save is used.

- [Galaxy: Sith operations, counter mission and both Darkness scales](../shots/wave7-final-galaxy.png)
- [Sabotage map: five soldiers, concealment and grouped tactical HUD](../shots/wave7-final-battle-sabotage.png)
- [Five-soldier loadout](../shots/wave7-final-loadout-five.png)
- [Temple build grid](../shots/wave7-final-temple-build.png)
- [Monthly Council Report](../shots/wave7-final-council.png)

Capture command:

```sh
/home/jess/projects/.tools/godot/godot --display-driver wayland --rendering-method gl_compatibility --path godot -s scripts/wave7_capture.gd
```

All five image writes returned success. The display environment emits EGL/X11 fallback diagnostics before selecting Intel; some existing headless suites emit ObjectDB shutdown leak warnings. These are separate from assertion/script errors and are not hidden by the runners.

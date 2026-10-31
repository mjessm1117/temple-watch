# Wave 5 integration report

## What Jess can play

The desktop entry (`godot/run.sh`, project main scene `menu.tscn`) now runs the full loop: difficulty → New Campaign → Temple → Galaxy → mission briefing and approach → four-soldier selection → battle → story debrief → saved results → Temple. Continue is disabled without a valid save. Direct Rescue remains available with its original four-unit roster.

The Temple has working navigation to roster, research, build, arsenal, teams, legacy, Codex and Galaxy. Due Council events, monthly votes and Temple conversations open with actionable choices and return to the hub. Codex has an explicit return button. Rest 7 days advances recovery, research and the calendar; a wounded roster cannot permanently block deployment. Completed era bosses expose “Begin the next era.” All three era plans, including the intervening year jumps, supply offers.

Deployment selects exactly four fit, unassigned roster members. Doc Bren is selectable as a Medic; no edit to `rescue.json` was needed. Names, roster IDs, classes, rank/perk stats, supported gear stats, class kits and wing buffs reach combat. Briefing approaches modify the battle, and eligible squad conversations interrupt turns 2–3 after enemy presentation finishes. Encounters and used abilities unlock Codex entries. The action bar hides other classes’ actions and retains unavailable kit actions with their reasons.

Battle results track kills, captures, revives and Darkness against roster IDs. Debrief records story flags and bonds once; completing its choice applies XP, rewards, promotions and recovery, saves, and returns to the Temple. The persisted stage prevents duplicate result application and resumes an unfinished debrief after Continue. Downed soldiers become Wounded on both wins and losses; they do not become dead or captured merely because their HP reached zero. Explicit death status is still respected. This follows this wave’s downed/Wounded requirement; the frozen web’s explicit-death and wound calculations are in `public/js/campaign.js::applyResults`, while its ordinary loss/capture and bleeding rules are not introduced into this rescue prototype.

Campaign state, including story, bonds, pending scenes and results, remains in `user://campaign.json`. New campaign replaces that save. Continue during a battle returns to squad selection and restarts that deployment; it does not restore tactical positions.

## Verification

`./godot/test.sh`: **805 checks passed / 0 failures; no SCRIPT ERROR**:

- Core combat, controls, FX, skills, presentation and balance: 356.
- Campaign: 45.
- Story port: 225.
- End-to-end loop and integration regressions: 179.

Fixed seeds 1–20, direct Rescue roster, unchanged difficulty data:

| Difficulty | Wins / 20 | Required band |
| --- | ---: | ---: |
| Story | 19 | ≥14 |
| Normal | 12 | 9–12 |
| Hard | 6 | 4–7 |
| Legend | 2 | 1–3 |

The loop test drives the actual menu and scene handlers, picks Dig in, selects Kira/Tor/Ilsa/Doc, and lets the same tactical bot used by the balance suite finish the battle. It deliberately downs Tor through the combat damage API as a casualty fixture, then tests revive/Wounded, debrief resume, single result application, save/load and recovery through the Temple’s rest button. Separate checks cover total squad loss, kill credit, arsenal/wing modifiers, era migration and every era-plan offer. It uses an isolated `user://loop-test-<pid>.json`, not the player’s save.

The runner registers campaign, story and loop suites as separate headless processes and uses `grep`, not `rg`. It rejects nonzero exits, failure counts, `ERROR:` and `SCRIPT ERROR`. All GDScript files are below 600 lines; `game.gd` is 567 lines. Flow and battle bridging live in `campaign_bridge.gd` and `campaign/battle_bridge.gd`.

## Visual pass and captures

All captures were produced by the real menu → Temple → Galaxy → briefing → squad → battle → debrief flow, not by opening the destination scenes directly. No flow stall or direct-scene fallback occurred. The capture driver invokes the real buttons/handlers and the battle bot. Panels use the battle’s dark blue, teal, gold and pale text palette and the same default font. Narrative/decision columns and Codex categories scroll independently; arsenal selectors wrap; Galaxy signals use numbered pins to avoid colliding mission names.

Required 1366×768 captures:

- [Menu](../shots/wave5-loop-menu.png)
- [Temple](../shots/wave5-loop-temple.png)
- [Galaxy](../shots/wave5-loop-galaxy.png)
- [Briefing](../shots/wave5-loop-briefing.png)
- [Battle with Medic selected](../shots/wave5-loop-battle.png)
- [Debrief](../shots/wave5-loop-debrief.png)

Also captured [squad selection](../shots/wave5-loop-squad.png) and [Codex](../shots/wave5-loop-codex.png). The corresponding `wave5-loop-*-1920.png` files verify the same flow at 1920×1080. Xvfb captures use Compatibility rendering; Godot reports that volumetric fog requires Forward+, so these captures omit that effect. The desktop launcher retains Forward+.

## Remaining placeholders and boundaries

The maps lane was still running. Its `godot/data/rescue.json`, `godot/scripts/map*.gd` and `godot/tests/map_test.gd` were not edited. A mission-specific JSON map is selected when it has the supported rescue-map schema; otherwise the Detention Line rescue objective resolves the strategic mission. The briefing and deployment screen state the actual rescue objective. Strategic briefing/debrief prose still describes the original mission. Bespoke defense, boss, clue and other mission objectives are not claimed as implemented.

These mission IDs currently use the rescue map:

- Era 1: `adraasHunt`, `archive`, `blockade`, `cache`, `depot`, `dock`, `envoy`, `escort`, `fort`, `hutt`, `ilum`, `relay`, `sabotage`, `shrine`, `taris`, `thul`, `vault`.
- Era 2: `r_bomb`, `r_caves`, `r_codes`, `r_dump`, `r_hospital`, `r_muster`, `r_nexus`, `r_prisoners`, `r_ravine`, `r_seventh`, `r_sixth`, `r_snipers`, `r_supply`.
- Era 3: `h_beacon`, `h_buoy`, `h_cache`, `h_grove`, `h_hetzal`, `h_husks`, `h_outpost`, `h_prisoners`, `h_roots`, `h_salvage`, `h_scouts`, `h_tempest`, `h_valo`.

Guardian, Consular, Soldier, Scout and Medic have the skills lane’s complete tactical kits. Other roster classes retain their own class/rank/gear stats but use the shared Guardian or Soldier tactical kit for now; squad selection labels this. Their additional class-specific actions are not implemented here. Only gear modifiers understood by current combat rules have tactical effects. No new unit models were added.

Approach and squad-beat effects are connected. Finale `hurtBoss` requires an actual tagged boss, and `lock` is retained as map metadata; neither has a target in the rescue fallback. That map also has no clue terminal or droid, so Scan Clue/Combat Protocol remain unavailable there. Campaign and story lane limitations outside this loop (cloud sync, spatial Temple, personal mission UI, full service records and advanced web-only systems) remain as described in their reports.

## Exact manual test

1. Double-click the existing desktop shortcut, or run `./godot/run.sh` from the repository. Select Story, then New Campaign. Resolve the opening Council choices to reach the Temple.
2. Visit Roster, Research, Build, Arsenal, Teams and Legacy. Open Codex, then Return to Temple.
3. Open Galaxy, select Relay Aurek-7 and press Mission Briefing. Choose Dig in.
4. In deployment, deselect Sgt. Rhal Dax and select Doc Bren. Keep Kira, Tor and Ilsa; deploy with four selected.
5. Play the Detention Line rescue: move toward Mira, use Free Mira beside her, and escort her back to the blue evacuation tiles. Select Doc to inspect his kit; unavailable actions show why. End turns with Enter. Complete any squad dialogue when offered.
6. At mission end, choose the debrief response. Return through due Temple conversations. Inspect roster XP, kills and wounds, then use Rest 7 days until a wounded soldier recovers.
7. Return to Main Menu and choose Continue Campaign. Verify the roster and story progress remain. Direct Rescue still starts the original standalone mission.

Automated gate: `./godot/test.sh`.

Reproduce the flow captures without changing the player save:

```sh
xvfb-run -a -s '-screen 0 1920x1080x24' /home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility -s tests/loop_test.gd -- --capture-loop
xvfb-run -a -s '-screen 0 1920x1080x24' /home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility -s tests/loop_test.gd -- --capture-loop --large
```

Changes are local to `wave5/integrate`. No push, subagents, frozen web edits or maps-lane edits.

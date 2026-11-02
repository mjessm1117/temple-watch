# Wave 10 lane B — story choices and bonds

Branch `wave10/story`; no web source changed. The campaign already routed briefing, mid-mission, debrief and Temple scenes through `CampaignFlow` and serialized the shared campaign Dictionary. This lane fills gaps in those paths and makes saved bonds visible.

## Audit before changes

| Area | Existed and what the player saw | New | Skipped or retained |
|---|---|---|---|
| Story data and screens | `story_engine.gd` read the exported era 1–3 missions, saga, Temple life, Codex, and chain specifications. `story_screen.gd` rendered choices, consequences and trust on briefing/dialogue screens. `CampaignFlow` already launched these screens. | Two small JSON tables add 8 comms events, 12 Temple talks, 10 pair talks and fallback debrief choices. The same screen renders them. | Existing web text and era stories remain authoritative; their lossless JSON exports are untouched. |
| Briefing | 7 approach groups in `data-saga.json`, including `_` for other missions; the default “As briefed” option had no effect. | “As briefed” grants 1 Intel. All 47 mission IDs across six families have at least two briefing options. | Existing approaches and battle effects retained. |
| Mid-mission | 8 named squad beats in era 1; only eligible cast/foe combinations appeared. | 8 additional data-driven comms events cover rescue, defend, investigate, sabotage, escort and assault. A mission without an eligible named beat shows one on turn 2–3. Choices grant Favor or Intel, set a record flag and apply a small battle effect. | No extra event after the one-per-mission beat. |
| Debrief | 15 saga aftermath scenes, with choices for some mission outcomes. | A win/loss fallback gives two choices after every mission without a named aftermath. Each grants a resource and records a flag. Two existing aftermath options with no effect now grant 1 Favor. | Named aftermath prose and decisions retained. |
| Temple | 21 cast talks and Council/story events; talk choices changed trust and campaign state. | 12 more talks become available after the named talks or in later eras. Ten pair talks unlock at bond levels 1–3; each grants 3 cohesion. One existing no-effect talk option now grants 1 Favor. | Council votes and existing trust rules retained. |
| Legacy and bonds | `legacy.json` contained 9 drills, 5 backstories, 9 secrets, 13 voices and 10 deed kinds. `legacy.gd` stored levels 1–8 at thresholds 8/10/12/14/16/18/20/22. `combat_bonds.gd` gave Teamwork at level 1 and Crossfire at level 4, with nearby aim perks. A Temple Legacy card listed pairs by roster ID. | Adjacent Jedi gain 1 cohesion per player turn, even before level 1; Teamwork assist gains 4; rescue saves retain their 15-point story reward. Level 2 adds 5 will and level 3 adds 2 crit in battle. A death or Darkness 8+ gives an active Jedi partner −5 will and queues a Temple grief choice once. Old saves gain missing bond fields. | Existing 1–8 levels, drills, proximity aim and level-4 Crossfire retained. No WotC training timer was copied. |
| Old web and design references | `darkness.js` described Jedi Darkness recovery and drift; `base.js` showed squad/debrief rows and bond notices; `campaign.js` resolved rewards, injuries and death; `data-campaign.js` defined the six-person starting roster and resources. Wave 5 report documented the port; Wave 7 report documented combat perks. `XCOM2-STUDY.md` recorded WotC cohesion thresholds 0/30/80/160 and level perks. | Godot keeps its existing faster eight-level scale and adds visible growth in each campaign loop. | The four web files were read only. No film or game text was copied into new prose. |

`story.json`, `saga.json`, `story-era2.json`, `story-era3.json`, `temple-life.json` and `spec-chains.json` are archival exports; the playable tables are in the corresponding `data-*.json` records. The original 21 talks, 8 beats and 15 aftermath scenes are reused before generic fallbacks when eligible.

## What the player sees

- Briefing options show resource and battle tradeoffs before deployment. A comms decision appears during a mission when a named beat does not; the debrief always has an outcome decision.
- Temple talks show short conversation choices. Pair talks name both Jedi and show their bond level and cohesion. A lost partner produces a later Temple scene.
- The roster and loadout cards name each bonded partner and level. The battle HUD repeats the selected Jedi's bond and draws a cyan link between living bonded partners. The line follows the camera.
- Cohesion and choice state live in the campaign save. Level thresholds are 8, 18 and 30 cumulative points for levels 1–3; levels 4–8 keep the existing rules. The level 1 Teamwork action, level 2 will, level 3 crit, and level 4 Crossfire are the battle unlocks.

## Verification

- `story_bonds_test.gd`: **452 checks, 0 failures**; checks all 47 mission briefings/debriefs, new choice and battle effects, pair unlocks, adjacency and assist cohesion, save/load, loss response and old-save migration. It is registered in `godot/test.sh`.
- `./godot/test.sh`: exit **0**, all suites **0 failures**, **0 SCRIPT ERROR**. Normal rescue bot **10/20** wins, within the required 9–11 band. Campaign test **45 checks, 0 failures**; mission families test **516 checks, 0 failures**.
- Six 1920×1080 captures from real Godot screens: [briefing](../shots/wave10-story-briefing.png), [mid-mission](../shots/wave10-story-mid.png), [debrief](../shots/wave10-story-debrief.png), [Temple talk](../shots/wave10-story-talk.png), [roster](../shots/wave10-story-roster.png), [battle bond line](../shots/wave10-story-battle.png).

The screenshot helper is `godot/scripts/story/wave10_capture.gd`. The battle capture uses a seeded campaign with two bonded Jedi and centers the camera on them.

# Wave 10 lane C — gear and research

## Audit before this lane

| Source | Existing rule/data | Player could use or see before | This lane |
|---|---|---|---|
| `research.json` | 36 `RESEARCH` entries, five `RES_TREE` branches, class `TREES` | Temple Research showed a long branch list with one active project, prerequisite errors and prices; no queue, link diagram or completion payoff card | Added dependency lines, compact status, queue, day gate, and an unlocked card with the actual payoff. Class progression remains separate. |
| `gear.json` | Three weapon styles, eight armor options, three saber styles, 24 weapon/armor/saber modules, `MK_RES`, `MK_COST`, `MK_N`, `EVO` | Module Mk I–III could be purchased in squad loadout. Weapon/saber styles and armor options had separate room/research gates but no mark ladder. | Each weapon, saber and wearable armor option now has Mk I–III stats; the old styles and saves remain valid. Beskar now has its missing research gate and slots. |
| `gear.gd`, `progression.gd` | Purchasing, module fitting, stat calculation, rank perks | Battles used style and module stats. Several research descriptions had no deployed effect. | Added base/armor mark purchases and stats, research combat effects, and campaign enemy scaling. Rank code is unchanged. |
| `loadout_*.gd` | Squad Arsenal purchase controls and live cards | Mark upgrades showed cost and research lock; no full stat comparison | Added before/after aim, damage, HP, armor and slots, including equipped modules. Cards show primary and armor marks. |
| `strat_base.gd`, `strat_ops.gd`, `state.gd` | Archives power/staff speed, persistent active research, Forge engineering projects | Existing project progress saved; no research queue or unlock notice | Queue and last unlock migrate into the same v2 save. Forge engineering projects remain independent. |
| `temple_rooms.gd`, `temple_view.gd`, Temple UI | Archives and Forge rooms, station panels | Archives opened the flat Research list; Forge opened Arsenal without a mark comparison | Archives shows a dependency tree and queue; Forge room shows mark prices and comparisons for the selected soldier. |
| `docs/godot/wave7/strategy-REPORT.md`, `docs/XCOM2-STUDY.md` | Spatial Temple, staffed speed, proving-ground work and strategic pacing notes | Strategy systems provided room power and daily ticks | Reused the daily tick and staff multipliers; research remains distinct from engineering work. |
| Read-only web `public/js/data-campaign.js`, `base.js` | Wing definitions and squad/debrief flow | Reference for the native port, not runtime code | No web files changed. The mark and research reference definitions also live in `public/js/data-arsenal.js` and `temple-prog.js`. |

## Research projects

All 36 existing projects remain. Prerequisite arrows and the payoff description are shown on the Archives page. Queue entries must follow prerequisite order. One project runs at a time; queued costs are paid when the project starts. A project waits in the queue if the Archives lack power, a day gate has not arrived, or resources are short. Queued studies can be removed; removing a prerequisite also removes dependent entries. Completion writes an unlocked card and a Command log entry.

| Branch | Projects, in display order |
|---|---|
| Weapons (8) | Weapon smithing; Targeting visors; Tibanna gas chargers; Refit line Mk II; Heavy ordnance; SpecForce program; Refit line Mk III; Repeating blasters |
| Armor (7) | Cortosis weave; Durasteel alloys; Personal shields; Reflec coating; Armorsmith Mk II; Mandalorian iron; Armorsmith Mk III |
| Lightsabers (7) | Kyber lore; Ataru katas; Djem So drills; Saber smithing Mk II; Niman discipline; Juyo, the forbidden form; Saber smithing Mk III |
| Force (7) | Master curriculum; Beast lore; Holocron studies; Force wards; Trials of mastery; The Living Force; Nameless studies |
| Logistics (7) | Field medicine; Imperial codebreaking; Logistics; Bacta tanks; Sith tactics; Supply contracts; Holonet relays |

Visible outcomes use the existing item/form/room gates plus combat stats, medkits, grenades, XP, Intel, Kyber, price reductions and evolution. `beastLore` and `namelessLore` grant their aim on missions containing horrors. `holonet` grants one Intel after a win. Every project can be completed, and every project appears in exactly one branch.

## Pacing and costs

| Milestone | Earliest campaign day | Research work and cost | Forge cost per item | Effect |
|---|---:|---|---|---|
| Mk I | 0 | Starting equipment and options | Existing style/armor purchase prices | Existing base stats and slots |
| Weapon Mk II | 75 | Weapon smithing 15 d/60 Cr → Refit line Mk II 20 d/80 Cr | 40 Cr | +1 damage and +3 aim on each weapon style |
| Armor Mk II | 75 | Durasteel alloys 15 d/60 Cr → Armorsmith Mk II 20 d/80 Cr | 40 Cr | +1 HP on each armor option |
| Saber Mk II | 75 | Kyber lore 20 d/60 Cr → Saber smithing Mk II 20 d/80 Cr | 40 Cr | +1 damage and +5 deflect on each saber style |
| Mk III | 210 and era 2 | Corresponding Mk III project: 25 d/140 Cr; saber also 1 Intel | 90 Cr from Mk II | +2 total damage for weapon/saber; armor +1 total HP and +1 armor |

Day gates let players prepare a queue while keeping Mk II near the fifth mission and Mk III near the late campaign. Archives level 2 and archivists accelerate research but do not bypass day or era gates. Costs are paid from the same resources as other Temple work; Armory staff and Supply contracts discount Forge credit costs. Existing weapon/saber styles still improve damage and slots separately.

Enemies in campaign battles gain +1 HP and +3 aim at day 120 or era 2, then +2 HP, +6 aim and +1 damage at day 240 or era 3. Starting rescue bot settings and standalone combat fixtures are unaffected.

## Verification

`gear_research_test.gd` checks the entire prerequisite graph, all 36 completions, every base/armor line and all 24 module mark upgrades with live stats, queue order/cancellation, v2 save/load and old-save migration. The rendered capture run adds seven checks, including clicking the real Forge button; both runs have zero failures.

The full `./godot/test.sh` run exited 0 with no `SCRIPT ERROR` and zero failures in every suite. The rescue bot held **Story 20/20, Normal 10/20, Hard 4/20, Legend 1/20**. Campaign, strategy, Temple view, loadout and tactical suites remained in their existing bands; Normal meets the 9–11/20 target. The focused gear suite passed 346 checks after queue cancellation coverage.

These are 1366×768 Godot Compatibility renderer captures under Xvfb using an isolated developed Temple fixture:

- [Archives research tree with active work and queue](../shots/wave10-gear-research-tree.png)
- [Project completion and unlocked payoff](../shots/wave10-gear-research-unlocked.png)
- [Forge before upgrade](../shots/wave10-gear-forge-before.png) and [after upgrade](../shots/wave10-gear-forge-after.png)
- [Squad loadout with Mk III saber and robes](../shots/wave10-gear-loadout-mkiii.png)

All changed GDScript and JSON files are under 600 lines. `git diff --check` passes. No web files or copyrighted assets were changed.

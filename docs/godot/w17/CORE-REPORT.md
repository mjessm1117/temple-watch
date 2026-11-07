# Wave 17 class core

## Built

- Fifteen class files and one rank table. Soldier power starts at 100, Padawan at 50, early Knight at 90, Master at 260, and Grand Master at 420. Only one living Grand Master may promote at a time.
- Existing tactical kits and ability definitions are loaded through `godot/scripts/class_registry.gd`. The class files copy shipped ability values. The legacy `godot/data/abilities.json` remains the general ability catalog and now adds only the universal `masterAction` ability.
- `godot/scripts/ability_chains.gd` handles enemy and ally tags, consume-before-apply ordering, optional effect lists, three-pip squad Momentum, and one free action claim per turn. Tag rules cover aim, crit, cover, defense, movement, reactions, shield, Force cost, damage, burning, and taunt targeting. Existing abilities have no chain metadata, so old battles retain their numbers and behavior.
- Campaign units track up to three paths, with second path at Knight or Sergeant and third at Master or Captain. Jedi/soldier blends are rejected. Cross-trained abilities are explicit picks. Secondary abilities are capped at rank 4; a primary Knight's secondary paths reach rank 5.
- Masters may mentor two Padawans. A mentored Padawan earns 50% more XP and carries one taught ability. On mentor death, pupils receive a half-power signature legacy; a Temple memorial and news entry are saved. A Grand Master dying without trained Padawans adds 2 Order Darkness.
- Barracks Jedi recruits join at Padawan rank 1 with strike, guard/deflect, and two Focus; soldiers join as Recruit rank 1 with their current full kit and gear. Old version 1 and 2 campaign saves migrate new fields.
- A full-screen promotion view shows rank, tier, power, blend slots, primary picks, cross-training, mentor selection, and inherited legacies. It uses the existing touch scroll container. At 844×390 and 667×375, visible tap targets meet 44 px.

## Lane data contract

Jedi files: `godot/data/classes/jedi/{guardian,knight,duelist,sage,consular,sentinel,wayseeker}.json`.

Soldier files: `godot/data/classes/soldier/{trooper,heavy,sniper,scout,medic,tech,droid,officer}.json`. Campaign `Soldier` maps to `trooper`. Rank and tier data, including Padawan `starting_kit` and `starting_focus`, live in `godot/data/classes/ranks.json`.

Each class file is one JSON object with `schema: 1`, string `id`, `name`, `side` (`jedi` or `soldier`), `role`, `signature` ability ID, array `branches`, boolean `implemented`, string `unit_kind`, arrays `kit`, `passives`, `bonus_kit`, `bonus_passives`, object `tree`, and object `abilities`. `tree` has the existing `trunk` and `specs` shape: rank strings map to arrays of ability IDs; each spec has `sig` and later rank arrays. Stub classes have empty kit, passives, tree, and abilities. Later Jedi and soldier lanes edit only their own class files.

`abilities` maps unique ability IDs to definitions. An active definition uses `name`, `target`, `effect`, `cost`, optional `ap`, `range`, `focus`, `damage`, `chance`, charges, cooldown, and other effect parameters. Passive definitions use `passive: true` and may omit `target`. Legacy `effect` names still execute. New effects can add `effects: [{"type":"damage|heal|shield|focus|action|status|tag", "target":"target|self|all_enemies|all_allies|area_enemies|area_allies", "amount":N}]`. A `chain` object may include `consume` and `apply` arrays; each entry is a tag string or `{ "tag": "MARKED", "target": "target|self|all_enemies|all_allies|area_enemies|area_allies", "preserve": false, "bonus": [effect objects] }`. Consumption happens before application, so a skill cannot consume its own newly applied tag.

HUD lane reads `unit.combo_tags` (tag to source unit ID), `mission.chain_momentum` (0–3), and `mission.chain_strike_used_turn`. It may call `AbilityChains.claim_momentum_strike(mission, unit)` through `godot/scripts/ability_chains.gd`. Existing combat `mission.momentum` remains a separate meter for older abilities.

## Verification and captures

`godot/tests/core17_test.gd` checks class schema, legacy ability values and kits, power curve, blend restrictions, chains, Momentum, Master action, hiring, promotion, old saves, mentor effects, phone tap sizes, and touch scrolling. Capture source: `godot/tests/core17_capture.gd`.

- [Promotion 844×390](core/promotion-844x390.png)
- [Promotion 667×375](core/promotion-667x375.png)
- [Padawan hire at the barracks](core/barracks-padawan-hire.png)
- [Guard used in battle](core/battle-guard-ability.png)

## Known gaps

- Knight, Duelist, and Sage are valid class stubs. Later lanes supply the 91 Jedi and 104 soldier abilities, path capstones, Grand Master signatures, and Droid modules. Heavy and other Wave 17 soldier paths still use their existing proxy kits.
- The existing named starting roster is preserved for battle compatibility; Tor remains a Padawan in this wave. New Jedi recruits always start as Padawans.
- The HUD lane still needs tag icons, chain callouts, and Momentum pips. Master aura grants aim within three tiles; later balance work can tune its magnitude.

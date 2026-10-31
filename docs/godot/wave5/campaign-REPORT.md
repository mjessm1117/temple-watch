# Wave 5 campaign lane report

## Player-facing result

Directly opening `res://scenes/temple.tscn` shows a desktop command console with roster, promotion choices, research, construction, arsenal, strike teams, and legacy records. The Galaxy station opens `res://scenes/galaxy.tscn`, where the current mission offers appear as map pins and briefings. Mouse and keyboard work in both scenes (Temple 1–7/G; Galaxy arrows/Enter/Escape). Launch prepares the selected mission and emits `mission_launch_requested(mission_id, squad_ids, option)`; the signal is the battle integration boundary.

Campaign state saves locally to `user://campaign.json`. `state.gd::apply_mission_result(result: Dictionary)` records rewards, casualties, captures, kills, XP, promotions, wounds, bonds, unrest, time and new offers, then returns a debrief summary. Accepted result fields: `mission_id`, `win`, `story`, `units` (each `{id, status, hp, max_hp, downed, hurt, kills, captures, dark}`), optional `rewards`, `intel`, `loot_credits`, and `order_dark`. Call once per finished mission, then `save()`. `select_mission(index, squad_ids)` prepares a mission and stores its squad. `modules.gd::take_next_battle_buffs(campaign)` consumes the wing buffs prepared for the next battle.

## Ported in this lane

- JSON tables exported from the frozen web source: 11 classes, ranks 1–10 and their `RANK_GAIN`, 8 wings, 36 research projects, 11 class trees, 197 perk entries, 8 armor types, 8 modules in each weapon/armor/saber pool, 14 planets, 14 field ops, 11 Sith op definitions, 9 legacy drills, 13 voices and the 7 initial mission briefings. The final class, rank and tree tables include the additions made by `data-skills.js` after `data-trees.js` in web load order.
- Campaign state, local save/load, month/day/week clock, stipend, upkeep, troop pay, wing construction, staffing, training, recovery, research prerequisites and completion, and rank promotion stats.
- Armory purchases, weapon/saber tiers, armor, utility kits, saber forms, installed modules and Mk upgrades, plus unit evolution rules in `gear.gd`.
- Galaxy mission offers for the web `PLAN` steps, ignored-crisis penalties, region unrest, a default squad, strike team formation and auto resolution, field-op odds/deployment/resolution, and darkness recovery in Gardens.
- Wing actions and cooldowns, bonds and drills, retirement, nicknames, deeds, fallen legends, and a battle-result handoff.

## Deferred or integration dependent

- The later Era 2 and Era 3 story plans and mission maps are owned by the story and maps lanes. The campaign picker currently has the web Era 1 opening plan of three steps. The Godot battle still has only `rescue.json`, so other offered missions cannot launch until their mission scenes and shared launch path exist.
- The web Temple's spatial cutaway, bay placement/adjacency, spires and undercroft vaults; Council votes and black market; recruit candidates and personal quests; Sith counter operations; lore secrets and Council support; battle voice playback and Padawan proximity; mercy-driven Darkness changes; field-op spawning/expiry; fatigue and exact enemy-power risk calculation are deferred. Their source tables are present where relevant; this lane does not claim those rules as active.
- Web cloud save sync remains deferred. Local saves use the same campaign version (`v:2`) but are Godot files, not a browser-localStorage compatibility format.

See [PORT-INVENTORY.md](PORT-INVENTORY.md) for every `public/js/` file, its line count and lane status.

## Tests and screenshots

- `godot --headless --path godot -s tests/campaign_test.gd`: **45 checks, 0 failures**, no `SCRIPT ERROR`. Covers save/load, exact research and construction costs/timing, wound recovery, `RANK_GAIN`, offers, mission results, gear, teams, wing actions, bonds and all Temple station scenes.
- `./godot/test.sh`: **203 checks, 0 failures**, no `SCRIPT ERROR`; Normal rescue bot 11/20 wins. Local 3D imports were generated with `godot --headless --path godot --editor --quit` before the clean rerun.
- [Temple hub](../shots/wave5-campaign-temple.png) and [Galaxy](../shots/wave5-campaign-galaxy.png) were captured at 1920×1080 by launching each scene directly with `scripts/campaign/capture.gd` under `xvfb-run`.

## Integration requests

1. `godot/scripts/menu.gd`, `_ready()`: add a **New Campaign** button. Its handler should instantiate `res://scripts/campaign/state.gd` with the selected difficulty, call `save()`, then call `get_tree().change_scene_to_file("res://scenes/temple.tscn")`. Add a **Continue Campaign** button that loads `user://campaign.json` and opens the same scene when loading succeeds. Keep the current direct Rescue button for the existing single-mission mode.
2. `godot/scripts/mission.gd`, `_init()`: accept a mission data path or mission ID instead of hardcoding `res://data/rescue.json`; use the story/maps lanes' mission catalog as it arrives. `godot/scripts/game.gd`, `_ready()`: read the selected campaign squad IDs and assign each player's `rid` to the corresponding battle unit before the first turn. `godot/scripts/campaign/galaxy.gd`, `mission_launch_requested`: connect the signal to that shared battle launcher. Until then, the signal intentionally stops at a visible preparation stub.
3. `godot/scripts/game.gd`, `_refresh()` or the first result transition: guard against duplicate application, build a result dictionary from the battle units using the schema above, call `Campaign.load_save()`, `apply_mission_result(result)`, `save()`, and return to `res://scenes/temple.tscn`. Use the campaign mission ID and `rid` mapping from request 2. Set `story` from the pending option and pass battle rewards only when the mission supplies an override.
4. `godot/test.sh`: after the existing `tests/run.gd` process succeeds, run `"${GODOT_BIN:-/home/jess/projects/.tools/godot/godot}" --headless --path . -s tests/campaign_test.gd` and fail on a nonzero exit or `SCRIPT ERROR`. This registers the leased standalone campaign suite in the shared test gate without editing `godot/tests/run.gd`.
5. Story lane integration: store its story-state Dictionary inside campaign `state` and call its `start_briefing`, `start_debrief`, and era-transition APIs at the launch/result boundaries; extend `refresh_options()` with Era 2/3 plans after those missions exist.

## Open problems

The mission launch and return path needs the shared file changes above. The direct scenes and strategy rules are usable and saveable, but a full campaign playthrough is blocked by the current one-mission battle build and missing later-era maps.

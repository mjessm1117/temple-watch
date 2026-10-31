# Combat lane report

## Player changes

- Directional half and full cover now creates a real flank: an exposed side gives +50 critical chance, shown in the shot breakdown. Hunkering costs the remaining AP, gives +30 defense, and cancels flank critical chance until the next player turn.
- A height advantage gives +20 aim. A two-level vantage shoots over one tier of cover. Destructible cover has HP: a full barricade falls to half cover, then to rubble after sustained damage; Push, explosions, and Heavy hits damage cover.
- Enemy pods scamper for cover when discovered and cannot fire on that reveal turn. Engagement caps are 4/6/6/99. Hard and Legend field stronger pod compositions including Sith acolytes, Heavy units, and Agents. The eastern high ground now has a ramp and the map retains two routes through the central wall.
- Reinforcements announce an exact tile one turn before landing. The mission exposes `reinforcement_marker` for the HUD to draw.

## How to see it

Start the rescue mission. Hover a target behind cover from its protected side, then move to its exposed side and compare the crit and modifier lines. Use Force Push against a barricade to degrade it. Approach the central wall from either opening, and climb the eastern ramp at (16,9). On turn 4, the log announces the turn 5 entry tile.

## Verification

`./godot/test.sh`: **164 checks, 0 failures**, with no script errors. Fixed-seed rescue bot, seeds 1–20: Story **18/20**, Normal **11/20**, Hard **4/20**, Legend **1/20**. All requested bands pass. The installed WotC configs supplied 20/40 cover, +20 height aim, +30 Hunker defense, 50 flank crit, and 4/6/6/99 engagement caps (`defaultgamecore.ini`, `defaultgamedata_characterstats.ini`, `defaultai.ini`). Difficulty aim modifiers are within ±10 of the frozen web table.

Screenshot: [Combat rescue](../shots/wave4-combat-rescue.png), captured from `res://scenes/rescue.tscn` at 1366×768.

## New public functions and data

`RescueMission.hunker(id)`, `damage_cover(tile, damage)`, and `explode(center, damage, radius)` are new. `reinforcement_marker` is a `Vector2i` (`(-1,-1)` when absent); `terrain_revision` increments when cover changes tier. Existing `game.gd` function signatures remain intact.

## Integration requests

- `godot/scripts/game.gd`: add Hunker to the ability bar and key handling; call `mission.hunker(selected_id)` and refresh the selected unit/status display. Show the hunkered state on the unit panel.
- `godot/scripts/env_art.gd` or `godot/scripts/game.gd`: draw a prominent warm entry marker at `mission.reinforcement_marker` while its x is nonnegative. Refresh it after `mission.end_turn()`; remove it on arrival.
- `godot/scripts/game.gd`: after a shot, compare `mission.terrain_revision` before and after `mission.shot(...)`. If changed, call `_build_terrain()` and play `fx.cover_chunks(...)` at the changed tile. Push already rebuilds cover.

## Open problems

The current game UI has no Hunker control or on-map reinforcement marker until the integration requests land. Heavy-hit cover damage changes the rule grid immediately, but its model may remain stale until terrain rebuild. The bot is a simple objective runner; the reported win bands describe those 20 fixed seeds, not human play.

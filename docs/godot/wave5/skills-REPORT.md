# Wave 5 skills lane report

## Player changes

The four rescue soldiers now have class kits in `godot/data/units.json`, with costs, ranges, charges, cooldowns, and effects in `godot/data/abilities.json`. `abilities_engine.gd` validates targets and spends resources for all of the new actions. Guardian protects allies and can leap, throw, collapse cover, and sweep. Consular heals, revives, shields, and controls foes. Soldier suppresses and fires twice. Scout marks, gains an action, and takes a high risk shot. The Medic class and kit are implemented in the unit catalog; adding that class to the rescue roster needs the map lane's JSON edit below.

Every current squad member starts with two Medpacs. Any adjacent ally can Revive a downed soldier for 1 AP. Force Heal revives within three tiles; a Medic has Medkit and ranged Revive Stim. A downed soldier lies on the field, cannot act, and is excluded from enemy targeting. The mission ends only when the full squad is down or the evacuation clock expires. Downed or revived soldiers remain Wounded, and the result panel names them. Healing displays the actual restored HP in green with a burst and light FX.

The ability bar shows class actions, hotkeys, AP cost, charges, cooldown, and the reason an action is unavailable. Enemy and ally targets can be cycled; targeted actions use preview and confirm. Enemy AI prioritizes a visible healer when choices are otherwise comparable. The rescue bot uses healing and revive.

## Web ability mapping

Source: frozen `public/js/abilities.js` (`AB` table and `defineAbility`), `public/js/data-campaign.js` (`CLASS` and `BASE_KIT`), and `docs/specs/combat.md` §2. The names below are the Godot action names; each row gives the web source ID. Web end turn actions spend remaining AP in Godot.

| Kit | Godot ability | Web source ID | Adaptation |
|---|---|---|---|
| Shared | Shoot, Strike, Push, Overwatch, Hunker Down | `shoot`, `strike`, `push`, `overwatch`, `hunker` | Uses Godot AP, LOS, directional cover, and presentation. |
| Shared | Medpac | `heal` / Medkit | Two charges per squad member; 4 HP or revive at 2 HP, adjacent or self. |
| Shared | Revive | `liftUp` | Always available during the mission, adjacent, 1 AP, 2 HP. |
| Jedi | Guard, Meditate, Choke, Subdue | `guard`, `meditate`, `choke`, `subdue` | Choke records Darkness; Subdue captures a weakened or stunned foe. |
| Guardian | Saber Throw | `saberThrow` | 4–5 damage at range 5; can pierce a second aligned foe. |
| Guardian | Defensive Line, Reflect Mastery | `defLine`, `reflectM` | Passive adjacent defense and Guard reflection. |
| Guardian | Force Leap, Collapse, Saber Sweep | `leap`, `collapse`, `sweep` | Leap grants +15 on the next Strike; Collapse turns a wall into rubble. |
| Consular | Stun, Force Heal, Force Barrier | `stun`, `forceHeal`, `barrier` | Force Heal has a one turn cooldown and revives at 2 HP per the playtest choice. |
| Consular | Battle Meditation, Mind Trick, Force Revive | `battleMed`, `mindTrick`, `forceRevive` | Force Revive is once per mission at 4 HP. |
| Soldier | Suppress, Rapid Fire, Rally | `suppress`, `rapidFire`, `rally` | Suppress fires on a pinned mover; Rally clears stun and disarm. |
| Scout | Mark, Run & Gun, Deadeye, Spotter, Ghost | `mark`, `runGun`, `deadeye`, `spotter`, `ghost` | Spotter and Ghost are passives. |
| Medic | Medkit, Smoke, Hack | `heal`, `smoke`, `hack` | Hack opens `k` or `D` tiles. |
| Medic | Hack Droid, Revive Stim, Combat Protocol | `hack` droid target, `reviveStim`, `protocol` | Droids can be stunned by Hack or damaged through cover by Protocol. |
| Medic | Shield Drone, Scan Clue | `shieldDrone`, `scan` | Scan Clue needs a `q` terminal; rescue has none. |

## How to see it

Launch `res://scenes/rescue.tscn` directly. Select a squad member and use the ability bar or its numbered/F-key shortcut. Damage a soldier, then use Medpac or the Consular's Force Heal; a downed soldier can be revived by an adjacent ally. The Wounded flag appears on that soldier's panel and on the mission result.

Captures from the scene at 1366×768:

- [Ability bar](../shots/wave5-skills-bar.png)
- [Force Heal](../shots/wave5-skills-heal.png)
- [Downed and revived soldier](../shots/wave5-skills-revive.png)

## Verification

`./godot/test.sh`: **356 checks passed / 0 failed; no script errors**. The suite exercises all 31 active class abilities plus resource spending, healing caps, ranged and adjacent revive, Wounded, AI healer targeting, passive effects, and full squad loss. The bot uses heal and revive.

| Difficulty | Wins / 20 | Medical uses |
|---|---:|---:|
| Story | 19 | 33 |
| Normal | 12 | 100 |
| Hard | 6 | 104 |
| Legend | 2 | 160 |

All four fixed-seed results are inside the requested bands. The bot ran seeds 1–20 on the current four member rescue roster.

## Integration requests

- `godot/data/rescue.json`, `squad`: replace the current array with the exact JSON below, subject to the map lane confirming `(8,22)` is passable and free in its revised rescue map. This makes the implemented Medic class playable in the mission. Re-run the bot bands after adding a fifth squad member; the counts above use the current four member roster.

```json
"squad": [
  ["guardian", 4, 22],
  ["consular", 5, 22],
  ["soldier", 6, 22],
  ["scout", 7, 22],
  ["medic", 8, 22]
]
```

## Open problems

- Rescue has no `q` clue terminal or droid enemy, so Scan Clue and Combat Protocol are exercised by synthetic tests but have no target on this mission.
- Rally clears control statuses. Its web stabilization clause has no effect because downed soldiers never bleed out in this playtest rule set.
- Wounded is a mission result flag. There is no campaign recovery system yet.

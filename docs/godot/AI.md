# Rescue mission AI and difficulty

## Enemy behavior

`godot/scripts/ai.gd` owns enemy movement and target decisions. It uses `ShotRules.calculate` for both candidate attacks and executed attacks; cover, line of sight, range, and height use the same rules as the player shot preview. Destination scores consider directional cover against every visible squad member, exposed flanks, preferred weapon range, height, nearby allies, and player overwatch lanes. A badly hurt enemy moves toward distance and cover first. Target choice values hit chance, a likely kill, a flank, and Jedi priority for the Sith warrior, while reducing the score of a target already attacked this turn.

Troopers seek protected firing lanes and enter overwatch when they cannot shoot. Heavies and agent snipers favor range and high ground. The new Sith Acolyte closes on Jedi, uses a saber strike in melee, and can spend Focus on Push against a covered target. This unit has a temporary `sithHeavy` model until a dedicated model is available.

When a group is revealed, its members make a free defensive move to cover. They do not attack during that reveal if it happens on the enemy turn. A group already visible to the squad waits while engaging it would exceed the difficulty's active attacker cap. Deaths free cap slots, allowing a waiting group to engage later. Reinforcements are announced one turn before they land and use the same cap.

## Difficulty

Jess chooses a difficulty on the new **Temple Watch** menu. `RescueSettings.difficulty` survives a rescue scene reload, so Restart keeps the choice. The mission constructor reads it; `game.gd` needs no hook. The table lists effective Godot values. Enemy HP and aim are offsets from each unit's base stats. The clock is the last playable turn.

| Difficulty | Enemy aim | Enemy HP | Extra per group | Active cap | Turn clock | Reinforcements | Player aim |
|---|---:|---:|---:|---:|---:|---:|---:|
| Story | −25 | −2 | 0 | 4 | 18 | 0 | +20 |
| Normal | −20 | −1 | 0 | 6 | 17 | 1 | +25 |
| Hard | −15 | −1 | 1 | 6 | 16 | 1 | +20 |
| Legend | −15 | 0 | 1 | 99 | 16 | 1 | +20 |

The initial values came from the frozen web `DIFF` table: enemy aim −10/+5/+10/+15, HP −1/0/0/+1, extras 0/0/1/1, and player assist +10/+10/0/0. The Godot rescue uses a larger map and a weak objective focused bot, so aim, HP, clock, and reinforcement counts were tuned in `difficulty.json` to reach the requested bands. The 4/6/6/99 engagement caps and extra enemy counts remain from the XCOM study and web table. The web rescue variant also has an aim override of +19; this was treated as source context, not added on top of the Godot values.

## Verification

`./godot/test.sh` runs the rules, AI, difficulty, menu, presentation, and 20 seeded bot games at each difficulty; it fails if Godot reports a script error. The latest full run: **140 checks, 0 failures, 0 script errors**.

| Difficulty | Bot wins | Win rate |
|---|---:|---:|
| Story | 15/20 | 75% |
| Normal | 11/20 | 55% |
| Hard | 5/20 | 25% |
| Legend | 1/20 | 5% |

These are deterministic results for this particular bot and seeds 1–20. They are a balance signal, not a player win rate.

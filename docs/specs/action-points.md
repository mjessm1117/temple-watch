# Action Points, assists, momentum (Chat R, wave 9, 2026-10-23)

Jess's calls (ask-form, 2026-10-23): full move per AP, attack cost by weapon, all four assists, "noticeable" buffs. Then: every trooper class distinct (medic always has a medpack, tank armor + tank tools, sniper ability, heavy armor + heavy damage, a pistol fighter with quick shots).

Reference: Star Wars Zero Company gives each operator 3 AP; movement and attacks both cost AP by distance/weapon; Overwatch ends the turn; "Call for Backup" is a free once-a-turn ally follow-up; "Advantage" is a squad meter (+1 per hit, max 10) spent on extra actions. Sources: EA Help "turn-based tactics and combat basics" (help.ea.com) and turnbasedlovers.com preview. Sourced, Med-High confidence (exact per-tile/per-weapon numbers not published).

## Rules (numbers in `AP`, data.js)
| Rule | Value |
|---|---|
| AP per unit per turn | 3 (enemies too) |
| Move | 1 AP per full move (`mob` tiles). Blue tiles = 1 AP, gold = 2–3 |
| Shoot | pistols 1 AP (Gunslinger), rifles 2 AP (everyone else) |
| Strike (saber) | 1 AP adjacent, 2 AP if it dashes in |
| Force powers | Focus cost ≥3 → 2 AP, else 1 AP |
| Fixed costs | grenade 2, Meditate 2, Collapse 2, Suppress 2, Deadeye 3, Snipe 3, Barrage 3, Fan the Hammer 2 |
| Ends the turn | Overwatch, Guard, Hunker Down, Hold the Line |
| Chains | kill refunds stay +1 AP, capped at 3 |

Code: `apOf(u,k,g)` / `apOk` / `apText` in turns.js; `exec()` charges AP. Move zones in input.js (`moveZones`, `moveCost`).

## Assists and momentum (every unit)
| Ability | Cost | Effect |
|---|---|---|
| Call Backup | free, once a turn for the squad | best-placed ranged ally shoots your target (−10 aim, −1 dmg); bond point |
| Covering Fire | 1 AP (ranged) | target −30 aim until your next turn |
| Hand Off | 1 AP, once a turn per unit | ally within 4 gets +1 AP |
| Momentum | squad meter 0–10 | +1 per hit on an enemy, +1 more per kill |
| Surge | 3 momentum | this unit +1 AP (once a turn per unit) |
| Rally | 5 momentum | squad +10 aim until your next turn |
| Fire Support | 8 momentum | 3×3 strafing run, 3–5 damage, breaks cover, spares allies |

## Troopers (battle-time, `waveKit` in turns.js)
- All troopers: +1 HP, +5 aim, armor-piercing (hits on armored targets aren't reduced; the pip still breaks).
- Medic: never runs dry (restocks 1 medkit at turn start when empty). Heal kit always in the bar.
- Scout (sniper): **Snipe** 3 AP: +15 aim, +2 damage, +20 crit.
- Heavy: +1 damage; **Barrage** 3 AP: 3×3, 3–5 to every enemy, breaks half cover, every other turn.
- Shieldbearer (tank): **Shield Wall** 1 AP (self + adjacent allies +20 defense), **Draw Fire** 1 AP (enemies prefer you, +40 targeting score).
- Defender (Jedi tank): **Draw Fire**.
- **Gunslinger** (new pistol class, name invented [N]): 1-AP pistol shots; **Fan the Hammer** 2 AP (3 shots, −15 aim, −1 dmg). Tree: Duelist / Outlaw. Perks: Quick Draw (first shot −1 AP), Hit and Run (flank attack refunds 1 AP once a turn), Fast Hands.

## Starting Jedi powers (+1 damage or +10%)
Push 100% and slams deal 3 · Choke 90%, 5–6 · Stun 85% · Force Heal 4 · Saber Throw 4–5.

## Enemies (`eTurn` in ai.js)
3 AP. Strong shot (65+) from where it stands, else move (up to 2 moves) then attack. 1-AP fighters (melee, lightning) may attack twice. A gunner who fired with AP left and stands in the open ducks back to cover.

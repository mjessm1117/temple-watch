# Maps & Tactics (Chat M, wave 5, 2026-10-17)

Jess's notes: missions felt flat, one kill zone, terrain/angles didn't matter, overwatch never seemed to fire. His pick: **all three styles plus more; variety is key. Keep the old 13 maps and add new ones.**

## What changed
| Area | Rule | Where |
|---|---|---|
| Board size | Any size. `W`/`H` follow `S.grid` (getters in `state.js`). 2D board and overlay resize; 3D already builds from the grid. | state.js, maps.js |
| Angles | A full wall right in front of the shooter blocks the shot. A unit in full cover can lean out (peek) from a free side tile, so you shoot around corners and wall ends, not through the middle of a wall. | rules.js `los` |
| Entry points | `entries:[[x,y,'name']]`: waves and reinforcements enter from several edges, rotated, announced a turn ahead (red hatched tiles + "Next turn: N hostiles from the east ridge"). | maps.js |
| Operations | `type:'op'` + `phases`: **reach** (any squad member in zone), **hold** (N turns with someone inside and no enemy inside), **chase** (stop a runner before the red exit; if he escapes, the mission fails), **extract** (everyone on evac). Each step can call a wave. Threat past `par` works as for other types. | maps.js |
| Overwatch | Amber tiles show every overwatch zone (enemy snipers' zones in red). An **OVERWATCH** call-out with a ring pops when it fires. If nothing walked into it, the log says "Overwatch held: nothing moved through X's sight." | maps.js, view3d |
| Big maps | `big:1`: an enemy with nobody in range advances on the squad (or crowds the zone being held) instead of idling. | maps.js `tileScore` |

Overwatch finding: the engine always fired (bot logs). On the live game it was easy to miss because the shot looked like any other shot and most enemies shoot from where they stand (they only trigger overwatch when they *move* through sight). The zones + call-out + "held" line make both cases visible.

## New maps (10, added as extra random layouts of existing crises)
| Crisis | Map | Size | Style | Smart-bot win (Normal, 8–10 games) |
|---|---|---|---|---|
| Shrine (Defend) | Dantooine Crossroads | 18×14 | Battlefield, 4 entries | ~60% |
| Shrine | Shrine Terraces | 16×16 | Battlefield, high ledges vs low paths | ~50–85% (noisy) |
| Shrine | Hold the Ford | 16×15 | Op: reach → hold 2 → extract, river with one crossing | ~50% |
| Rescue | Detention Level 5 | 15×16 | Close quarters; walk the prisoner back out | ~60% |
| Archive (Investigate) | Antenna Ridge | 17×20 | Op: take ridge → hold uplink → extract | ~65% |
| Archive | Rooftop Chase | 20×14 | Op: chase the courier → extract | ~50% |
| Archive | Listening Post Interior | 19×15 | Close quarters, stealth start, 3 wings | ~60% |
| Sabotage | Balmorra Fuel Farm | 20×14 | Two roads: catwalk high road vs canal banks | ~50% |
| Sabotage | Refinery Stacks | 18×15 | Vertical: ledges see over walls | ~75% |
| Escort | Canyon Run | 12×17 | Two roads: exposed ridge vs covered floor | ~50% |

Bot variance at 8–10 games is about ±15 points. Re-measure with `GAMES=20 node tests/balance.test.js`.

## Data format (data-maps.js)
```js
{style:'op', type:'op', n:'Name', where:'…', big:1, par:9, theme:'snow', stealth:0, patrol:{},
 map:[…rows…], start:[[x,y]×6], foes:[[type,x,y,pod?]], entries:[[x,y,'name']],
 phases:[{k:'reach',n:'…',at:[x,y],r:1},
         {k:'hold',n:'…',at:[x,y],r:2,turns:2,zn:'ridge',wave:['trooper','trooper']},
         {k:'chase',n:'…',foe:['courier',x,y],exit:[x,y],exitN:'speeder'},
         {k:'extract',n:'…',wave:[…]}]}
```
An alt inherits every field of its base mission, so set `waves:null`, `stealth:0`, `patrol:{}` when the base has them and the new map shouldn't.

## Next ideas
Destructible routes (blow a wall to open a flank), night maps with sight radius, a second chase type (protect a runner), Era 2 versions of the new maps (`ruusanOf`).

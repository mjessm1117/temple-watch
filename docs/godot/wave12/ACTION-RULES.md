# Wave 12 action rules

Each unit starts its turn with **2 actions**. A normal move within mobility costs 1 action; a dash within twice mobility costs 2. A turn ending action sets the actor’s remaining actions to 0. Free actions stay free.

The movement ring data comes from `reach_tiles(unit, 1)` for blue tiles and `reach_tiles(unit, 2)` for the yellow dash extension. Enemy units use the same movement and attack costs.

Mission interactions use 1 action and leave any remaining action available. Reward hacks use 1 action. Attacking a relay uses 1 action and ends the turn. These three actions are assembled by the combat mission at runtime rather than stored in `abilities.json`.

| Ability | Actions | Ends turn |
|---|---:|:---:|
| Move (`move`) | 1 | No |
| Shoot (`shoot`) | 1 | Yes |
| Strike (`strike`) | 1 | Yes |
| Push (`push`) | 1 | Yes |
| Free Mira (`free`) | 1 | No |
| Overwatch (`overwatch`) | 1 | Yes |
| Hunker Down (`hunker`) | 1 | No |
| Medpac (`medpac`) | 1 | No |
| Revive (`revive`) | 1 | No |
| Guard (`guard`) | 1 | No |
| Meditate (`meditate`) | 1 | No |
| Saber Throw (`saberThrow`) | 1 | Yes |
| Force Leap (`leap`) | 1 | No |
| Saber Sweep (`sweep`) | 1 | Yes |
| Stun (`stun`) | 1 | Yes |
| Force Heal (`forceHeal`) | 1 | No |
| Force Barrier (`barrier`) | 1 | No |
| Battle Meditation (`battleMed`) | 1 | Yes |
| Mind Trick (`mindTrick`) | 1 | Yes |
| Force Revive (`forceRevive`) | 1 | No |
| Suppress (`suppress`) | 1 | Yes |
| Rapid Fire (`rapidFire`) | 1 | Yes |
| Rally (`rally`) | 1 | No |
| Mark (`mark`) | 1 | Yes |
| Run & Gun (`runGun`) | 0 | No |
| Deadeye (`deadeye`) | 1 | Yes |
| Medkit (`heal`) | 1 | No |
| Smoke (`smoke`) | 1 | Yes |
| Hack (`hack`) | 1 | Yes |
| Revive Stim (`reviveStim`) | 1 | No |
| Combat Protocol (`protocol`) | 1 | Yes |
| Shield Drone (`shieldDrone`) | 1 | No |
| Choke (`choke`) | 1 | Yes |
| Subdue (`subdue`) | 1 | Yes |
| Collapse (`collapse`) | 1 | Yes |
| Defensive Line (`defLine`) | 0 | No |
| Reflect Mastery (`reflectM`) | 0 | No |
| Spotter (`spotter`) | 0 | No |
| Ghost (`ghost`) | 0 | No |
| Hack Droid (`hackDroid`) | 1 | Yes |
| Scan Clue (`scan`) | 1 | No |
| Reload (`reload`) | 1 | No |
| Interact (`interact`) | 1 | No |
| Force Pull (`pull`) | 1 | Yes |
| Saber Breach (`breach`) | 1 | Yes |
| Grenade (`grenade`) | 1 | Yes |
| Ion Grenade (`ionNade`) | 1 | Yes |
| Stabilize (`stabilize`) | 1 | No |
| Pick Up (`liftUp`) | 1 | No |
| Open Door (`door`) | 1 | No |
| Use Console (`console`) | 1 | No |
| Plant Charge (`plant`) | 1 | No |
| Shadow Step (`shadowStep`) | 1 | No |
| Beast Calm (`beastCalm`) | 1 | Yes |
| Hold the Line (`holdLine`) | 1 | Yes |
| Disarm (`disarm`) | 1 | Yes |
| Force Bind (`root`) | 1 | Yes |
| Flurry (`flurry`) | 1 | Yes |
| Mighty Blow (`mightyBlow`) | 1 | Yes |
| Precision Strike (`precisionStrike`) | 1 | Yes |
| Mass Heal (`massHeal`) | 1 | No |
| Med Beacon (`medBeacon`) | 1 | No |
| Force Wave (`forceWave`) | 1 | Yes |
| Stasis Field (`stasisField`) | 1 | Yes |
| Tremor (`tremor`) | 1 | Yes |
| Chain Shot (`chainShot`) | 1 | Yes |
| Covering Fire (`coverFire`) | 1 | Yes |
| Hand Off (`handoff`) | 1 | No |
| Call Backup (`backup`) | 0 | No |
| Momentum Surge (`moSurge`) | 0 | No |
| Momentum Rally (`moRally`) | 0 | No |
| Fire Support (`moStrike`) | 0 | No |
| Snipe (`snipe`) | 1 | Yes |
| Barrage (`barrage`) | 1 | Yes |
| Shield Wall (`shieldWall`) | 1 | No |
| Draw Fire (`taunt`) | 1 | No |
| Fan the Hammer (`fanFire`) | 1 | Yes |
| Bond: Teamwork (`bondAid`) | 1 | No |
| Bond: Crossfire (`bondStrike`) | 1 | Yes |
| Shredder (`shredder`) | 0 | No |
| Sense (`sense`) | 0 | No |
| Executioner (`executioner`) | 0 | No |
| Pathfinder (`pathfinder`) | 0 | No |
| Wild Bond (`wildBond`) | 0 | No |
| Force Lightning (`lordLightning11`) | 1 | Yes |

# Temple Watch — Combat Spec (Chat A)

Written 2026-10-12. Owner: Chat A. Feeds the Coordinator (Chat E). Numbers fit the v0.1 engine scale (HP 4–10, aim 60–80, cover 20/40, Focus max 4, 2 actions).

## 0. Decisions (lead)

| # | Decision | Source |
|---|---|---|
| D1 | **Normal = ~85% win rate for a skilled player.** | Jess, 2026-10-12 |
| D2 | **Soft pressure, no hard timers.** Waiting makes things worse (more enemies, hostage hurt, bonus lost). Never instant-fail on turn count, except Defend's own clock (survive N turns = the win). | Jess |
| D3 | **Permanent death is rare.** Target ~1 death per 8–10 missions on Normal (estimate). Death = story moment. | Jess |
| D4 | Downed units can't be finished off by normal enemies. Only bleed-out, Force horrors (Jedi only), or losing the mission kills/captures. | Chat A, from D3 |
| D5 | Force horrors **only damage Force users**. Troops are immune and are the counter. AI horrors ignore troops. | README lock |
| D6 | 3 ranks to start (R1 on recruit, R2, R3). Each class: 2 base + 4 rank abilities. XP curve lives in spec B. | Chat A |
| D7 | Every class gets one "make the turn interesting" tool: a choice between safe and greedy. | Chat A |
| D8 | Keep team turns for v0.2. Initiative switch designed in §7, behind a flag. | README lock |

Confidence labels: **[S]** sourced/canon fact, **[I]** inference, **[E]** estimate, **[N]** invented for this game.

---

## 1. Core rule changes (engine-level)

| Rule | v0.1 | v0.2 proposal | Why |
|---|---|---|---|
| Bleed-out | 3 turns | **Easy 6 / Normal 4 / Hard 3 / Legend 2** | D3 |
| Downed targeting | Enemies skip downed (already) | Lock it in. Exception: horror vs downed Jedi (§3) | D4 |
| Stabilize | Medkit only (revive) | New action **Stabilize**: any adjacent ally, 1 action, stops bleed (no revive). | Makes deaths rare without making Medic mandatory |
| Mission loss | Downed = captured | Downed/alive-but-left = **Captured** → rescue (§6). Dead stays dead. | D3 + capture lock |
| Aim assist | none | Easy/Normal: each consecutive miss on the same unit +10 aim, resets on hit. Hidden. [S: XCOM 2 uses hidden aim assist on lower difficulties, med confidence] | Fights "95% miss" rage |
| Graze | none | **No.** Classic hit/miss per README lock. | Lock |
| Crit | Flank 50% +2 | Keep. Add base crit stat per class (Scout 15, others 0–10). Crit = +2 dmg. | Depth |
| Cover destruction | Grenade clears half cover | Add: 4+ dmg explosions turn **full** cover tile adjacent → rubble (half). | Terrain play |
| Elevation | none | **Defer to v0.3.** Height would need map rework. | Scope |
| Concealment | none | Mission start concealed if map flag `stealth:true`. Breaks on attack, being seen within 4, or alarm. | Assault/investigate missions |

---

## 2. Ability kits

Costs: **A** = actions (End = ends turn), **F** = Focus. Range in tiles (Euclid, like v0.1). Rank = when unlocked.

### 2.1 Jedi — shared base (all paths)
Strike, Guard, Meditate, Subdue, Push (as v0.1). Path picks the rest. Choke stays available to any Jedi at R2 as a dark-side option (Darkness +2).

### 2.2 Jedi paths

**Guardian** — front line, protector. [S: Guardian/Consular/Sentinel are the three Jedi branches in Legends/Old Republic games, high confidence]

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Saber Throw | R1 | 2F, End | 5, LOS | 3–4 dmg, ignores cover, can hit 2 enemies on a line. |
| Defensive Line | R1 | passive | adj | Adjacent allies +15 defense. |
| Force Leap | R2 | 1F, 1A | 6 | Jump over units/half cover to a tile; next Strike this turn +15 aim. |
| Reflect Mastery | R2 | passive | — | Guard reflect chance 40→65%; reflected bolt can be aimed at any enemy in 6. |
| Collapse | R3 | 3F, End | 5 | v0.1 Collapse; damage 3→4. |
| Saber Sweep | R3 | 2F, End | adj | Strike every adjacent enemy at −10 aim. |

**Consular** — Force support, control.

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Stun | R1 | 2F, End | 5 | v0.1. |
| Force Heal | R1 | 2F, 1A | 3 | Heal 3, or stabilize a downed ally (no revive). |
| Force Barrier | R2 | 2F, 1A | 4 | One ally counts as full cover from all sides until your next turn. |
| Battle Meditation | R2 | 3F, End | 6 radius | Allies +10 aim, enemies −10 aim until your next turn. Concentration: breaks if you're hit. [S: Battle Meditation is canon, high] |
| Mind Trick | R3 | 3F, End | 5 | Non-Force, non-droid enemy fights for you 1 turn. 70%. No Darkness. |
| Force Revive | R3 | 4F, End | adj | Revive a downed ally at 4 HP. Once per mission. |

**Sentinel** — skirmisher, detection, finisher.

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Sense | R1 | passive | 8 | Reveals hidden/concealed enemies and enemy intent (next action shown on token) within 8. |
| Disarm | R1 | 2F, End | 5 | Target can't shoot next turn (can move/melee). 80%. |
| Flurry | R2 | 1F, End | adj | Two Strikes on one target, each −10 aim. |
| Shadow Step | R2 | 1F, 1A | 5 | Teleport-dash; become concealed until you attack. |
| Executioner | R2 | passive | — | +25 aim vs targets at ≤50% HP. |
| Saber Throw | R3 | 2F, End | 5 | Same as Guardian's. |

**Wayseeker** — wanderer, terrain and beasts. [S: "Wayseeker" = High Republic-era Jedi who act outside Council direction, high confidence. Using it for an Old Republic class is an anachronism — **[N] rename to "Pathfinder" before Ruusan era, or unlock path only in High Republic.** Default: unlock in High Republic.]

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Throw | R1 | 2F, End | 6 | v0.1 Throw, crate range 4→6. |
| Pathfinder | R1 | passive | — | +1 move, ignores hazard tiles' move penalty. |
| Beast Calm | R2 | 2F, End | 5 | Creature/horror loses next turn. 75% (horrors 50%). |
| Force Pull | R2 | 1F, 1A | 6 | Pull enemy up to 3 tiles toward you, out of cover. |
| Tremor | R3 | 3F, End | 5 | 3×3: half cover → rubble, enemies 2 dmg, knocked out of overwatch. |
| Wild Bond | R3 | passive | — | Start missions at full Focus. Meditate gives +3. |

### 2.3 Troop classes

**Soldier** (Republic trooper / Temple Guard variant)

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Shoot, Overwatch | base | — | 8 | v0.1. |
| Suppress | R1 | End | 8 | Target −30 aim; if it moves, you take a free shot. |
| Hunker Down | R1 | End | — | +30 defense, immune to flank crits, until next turn. |
| Rapid Fire | R2 | End, 1 cooldown | 8 | Two shots at −15 aim. |
| Rally | R3 | 1A | 4 radius | Clear stun/disarm on allies; downed ally in range stabilizes. |

**Scout** (sniper/recon). Base crit 15.

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Shoot, Overwatch | base | — | 11 | v0.1. |
| Mark | R1 | 1A | 11 | Target: allies +15 aim vs it until it dies or your next turn. |
| Run & Gun | R1 | free, once/2 turns | — | Dash (double move) then still shoot. |
| Deadeye | R2 | End | 11 | +3 dmg, −20 aim. |
| Spotter | R2 | passive | — | Allies can shoot enemies the Scout sees (squadsight). |
| Ghost | R3 | passive | — | Concealment regained once per mission after a kill. |

**Medic/Tech**

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Shoot, Medkit | base | — | 6 / adj | v0.1 (2 kits). |
| Smoke Grenade | R1 | 1A, 1/mission | 6 | 3×3: allies +20 defense for 2 turns. |
| Hack | R1 | End | 4 | Consoles/doors/turrets (§4). Droids: 60% stun 1 turn. |
| Revive Stim | R2 | 1A | 2 | Revive downed at 2 HP from range 2. Uses a kit. |
| Combat Protocol | R2 | End | 8, no LOS | Droids only: 3 dmg, ignores cover. |
| Shield Drone | R3 | 1A, 1/mission | adj | Ally absorbs next 4 dmg. |

**Heavy**

| Ability | Rank | Cost | Range | Effect |
|---|---|---|---|---|
| Shoot, Grenade | base | — | 7 / 6 | v0.1 (2 nades). |
| Suppress | R1 | End | 7 | Same as Soldier. |
| Shredder | R1 | passive | — | Hits remove 1 armor (§3) and half cover the target stands behind. |
| Ion Grenade | R2 | uses a nade | 6 | 3×3: droids 4 dmg + stun; organics 1. |
| Rocket | R3 | End, 1/mission | 9 | 3×3, 4 dmg, destroys all cover incl. full. Allies hit too. |
| Hold the Line | R3 | End | 7 | Overwatch that fires at every enemy that moves in range (−15 each). |

### 2.4 Per-rank stat gains
| Rank | HP | Aim | Other |
|---|---|---|---|
| R2 | +1 | +5 | Jedi +1 max Focus |
| R3 | +1 | +5 | Jedi deflect +10; troops +1 kit/nade |

### 2.5 JSON — abilities (new/changed only; v0.1 keys unchanged)
```json
{"abilities":[
{"id":"saberThrow","name":"Saber Throw","f":2,"end":1,"range":5,"dmg":[3,4],"chance":85,"ignoreCover":1,"pierce":2,"paths":["Guardian","Sentinel"],"rank":{"Guardian":1,"Sentinel":3}},
{"id":"defLine","name":"Defensive Line","passive":1,"auraDef":15,"auraRange":1,"paths":["Guardian"],"rank":1},
{"id":"leap","name":"Force Leap","f":1,"ap":1,"range":6,"jump":1,"nextStrikeAim":15,"paths":["Guardian"],"rank":2},
{"id":"reflectMastery","name":"Reflect Mastery","passive":1,"reflect":65,"aimReflect":1,"paths":["Guardian"],"rank":2},
{"id":"sweep","name":"Saber Sweep","f":2,"end":1,"range":1.5,"allAdj":1,"aimMod":-10,"paths":["Guardian"],"rank":3},
{"id":"forceHeal","name":"Force Heal","f":2,"ap":1,"range":3,"heal":3,"stabilize":1,"paths":["Consular"],"rank":1},
{"id":"barrier","name":"Force Barrier","f":2,"ap":1,"range":4,"coverAll":40,"turns":1,"paths":["Consular"],"rank":2},
{"id":"battleMed","name":"Battle Meditation","f":3,"end":1,"radius":6,"allyAim":10,"foeAim":-10,"concentration":1,"paths":["Consular"],"rank":2},
{"id":"mindTrick","name":"Mind Trick","f":3,"end":1,"range":5,"chance":70,"turnSide":1,"notTags":["force","droid"],"paths":["Consular"],"rank":3},
{"id":"forceRevive","name":"Force Revive","f":4,"end":1,"range":1.5,"revive":4,"perMission":1,"paths":["Consular"],"rank":3},
{"id":"sense","name":"Sense","passive":1,"reveal":8,"intent":1,"paths":["Sentinel"],"rank":1},
{"id":"disarm","name":"Disarm","f":2,"end":1,"range":5,"chance":80,"status":"disarmed","paths":["Sentinel"],"rank":1},
{"id":"flurry","name":"Flurry","f":1,"end":1,"range":1.5,"hits":2,"aimMod":-10,"paths":["Sentinel"],"rank":2},
{"id":"shadowStep","name":"Shadow Step","f":1,"ap":1,"range":5,"teleport":1,"conceal":1,"paths":["Sentinel"],"rank":2},
{"id":"executioner","name":"Executioner","passive":1,"aimVsHalf":25,"paths":["Sentinel"],"rank":2},
{"id":"pathfinder","name":"Pathfinder","passive":1,"mob":1,"ignoreHazardMove":1,"paths":["Wayseeker"],"rank":1},
{"id":"beastCalm","name":"Beast Calm","f":2,"end":1,"range":5,"chance":75,"chanceHorror":50,"tags":["creature","horror"],"status":"stunned","paths":["Wayseeker"],"rank":2},
{"id":"pull","name":"Force Pull","f":1,"ap":1,"range":6,"pull":3,"paths":["Wayseeker"],"rank":2},
{"id":"tremor","name":"Tremor","f":3,"end":1,"range":5,"area":1,"dmg":[2,2],"rubble":1,"cancelOW":1,"paths":["Wayseeker"],"rank":3},
{"id":"wildBond","name":"Wild Bond","passive":1,"startFull":1,"meditate":3,"paths":["Wayseeker"],"rank":3},
{"id":"stabilize","name":"Stabilize","ap":1,"range":1.5,"stopBleed":1,"all":1},
{"id":"suppress","name":"Suppress","end":1,"foeAim":-30,"reactShot":1,"classes":["Soldier","Heavy"],"rank":1},
{"id":"hunker","name":"Hunker Down","end":1,"def":30,"noFlank":1,"classes":["Soldier"],"rank":1},
{"id":"rapidFire","name":"Rapid Fire","end":1,"shots":2,"aimMod":-15,"cooldown":1,"classes":["Soldier"],"rank":2},
{"id":"rally","name":"Rally","ap":1,"radius":4,"clear":["stunned","disarmed"],"stabilize":1,"classes":["Soldier"],"rank":3},
{"id":"mark","name":"Mark","ap":1,"range":11,"allyAim":15,"classes":["Scout"],"rank":1},
{"id":"runGun","name":"Run & Gun","free":1,"cooldown":1,"dash":1,"classes":["Scout"],"rank":1},
{"id":"deadeye","name":"Deadeye","end":1,"dmgMod":3,"aimMod":-20,"classes":["Scout"],"rank":2},
{"id":"spotter","name":"Spotter","passive":1,"squadsight":1,"classes":["Scout"],"rank":2},
{"id":"ghost","name":"Ghost","passive":1,"reconcealOnKill":1,"perMission":1,"classes":["Scout"],"rank":3},
{"id":"smoke","name":"Smoke Grenade","ap":1,"range":6,"area":1,"def":20,"turns":2,"perMission":1,"classes":["Medic"],"rank":1},
{"id":"hack","name":"Hack","end":1,"range":4,"droidStun":60,"classes":["Medic"],"rank":1},
{"id":"reviveStim","name":"Revive Stim","ap":1,"range":2,"revive":2,"usesKit":1,"classes":["Medic"],"rank":2},
{"id":"protocol","name":"Combat Protocol","end":1,"range":8,"noLos":1,"dmg":[3,3],"tags":["droid"],"classes":["Medic"],"rank":2},
{"id":"shieldDrone","name":"Shield Drone","ap":1,"range":1.5,"shield":4,"perMission":1,"classes":["Medic"],"rank":3},
{"id":"shredder","name":"Shredder","passive":1,"shred":1,"breakHalf":1,"classes":["Heavy"],"rank":1},
{"id":"ionNade","name":"Ion Grenade","usesNade":1,"range":6,"area":1,"dmgDroid":4,"dmgOther":1,"stunDroid":1,"classes":["Heavy"],"rank":2},
{"id":"rocket","name":"Rocket","end":1,"range":9,"area":1,"dmg":[4,4],"breakFull":1,"perMission":1,"classes":["Heavy"],"rank":3},
{"id":"holdLine","name":"Hold the Line","end":1,"owAll":1,"aimMod":-15,"classes":["Heavy"],"rank":3}
]}
```

---

## 3. Enemy rosters

New stat fields: **armor** (flat dmg reduction, min 1 dmg), **tags** (`droid`, `force`, `creature`, `horror`). Horror rule: `damage = 0` vs targets without tag `force`. AI ignores non-Force targets.

| Era | Unit | HP | Aim | Mob | Dmg | Range | Signature behavior | Lore |
|---|---|---|---|---|---|---|---|---|
| **Old Republic ~3,600 BBY** | Sith Trooper | 4 | 65 | 5 | 2–4 | 8 | v0.1 | [S] Sith Empire troopers, SWTOR era, high |
| | Sith Heavy | 6 | 60 | 4 | 3–4 | 7 | v0.1 + armor 1 | [N] |
| | Imperial Agent | 5 | 80 | 5 | 4–5 | 11 | Starts concealed; Snipe vs exposed targets +20 | [S] Imperial Intelligence agents, high |
| | Sith Acolyte | 8 | 75 | 6 | 4–5 | melee | v0.1 (lightning, hunts Jedi) | [N] |
| | Terentatek (horror) | 14 | 80 | 6 | 5–7 | melee | Only hurts Force users; Consumes a downed adjacent Jedi at end of enemy turn | [S] Legends beast that hunts Force users, med-high |
| **Ruusan ~1,000 BBY** | Brotherhood Trooper | 5 | 65 | 5 | 2–4 | 8 | Fanatic: never surrenders below 2 HP; +10 aim near a Sith Lord | [S] Kaan's Brotherhood of Darkness army, Legends, med |
| | Sith Marauder | 9 | 75 | 6 | 4–6 | melee | Rage: +1 dmg each time it's hit | [N] archetype |
| | Sith Lord (elite) | 12 | 80 | 5 | 4–6 | melee/5 | Lightning + Force Push; Thought Shield: −50% Force dmg | [S] Brotherhood fielded many Sith Lords, med |
| | Mercenary Sniper | 5 | 75 | 4 | 4–5 | 11 | Overwatch every turn it doesn't shoot | [N] |
| | Sith Spawn (horror) | 10 | 75 | 5 | 4–6 | melee | Only hurts Force users; Spawns from a dark-side nexus tile every 3 turns until nexus destroyed | [N] |
| **High Republic ~380–230 BBY** | Nihil Raider | 4 | 60 | 6 | 2–4 | 7 | Gas mask: immune to smoke/gas; hit-and-run (shoots then moves) | [S] Nihil marauders, canon, high |
| | Nihil Storm (elite) | 8 | 70 | 5 | 3–5 | 8 | Gas Grenade: 3×3 hazard, 1 dmg/turn, 3 turns | [S] "Storms" are Nihil leaders, high |
| | Nihil Path-Runner | 5 | 65 | 8 | 2–3 | 6 | Bypasses map edge: appears behind your line on turn of arrival | [I] from Nihil "Paths" hyperspace routes, med |
| | Drengir (horror-creature) | 10 | 70 | 3 | 3–5 | melee 2 | Vines: roots a target (can't move) 1 turn. Hurts everyone (not a "horror"; tag `creature`) | [S] Drengir are sentient carnivorous plants, high |
| | Nameless (horror) | 12 | 85 | 6 | 6–8 | melee | Only hurts Force users; Fear aura: Jedi within 3 lose 1 Focus/turn and can't use Force powers | [S] Nameless prey on Force users; non-Force-sensitive people are unaffected, high |
| **Clone Wars ~22–19 BBY** | B1 Battle Droid | 3 | 55 | 5 | 2–3 | 8 | Squads of 4; +10 aim per other B1 within 2 (max +20) | [S] high |
| | B2 Super Droid | 7 | 60 | 4 | 3–4 | 7 | Armor 2; ignores cover-seeking, walks straight in | [S] high |
| | Droideka | 6 | 70 | 7 rolling / 0 deployed | 3–5 | 8 | Deployed: shield absorbs 6 dmg/turn; must roll (mob 7) or deploy, not both | [S] droideka shields, high |
| | Commando Droid | 5 | 75 | 6 | 3–4 | melee/7 | Starts concealed; ambushes medics | [S] high |
| | Dark Acolyte (elite) | 9 | 75 | 6 | 4–5 | melee/5 | Saber Throw + Choke; flees at ≤3 HP (can be captured) | [S] Dooku's Dark Acolytes, Legends, med |
| | Nightsister Revenant (horror) | 8 | 70 | 5 | 4–5 | melee | Only hurts Force users; returns once at 4 HP unless killed by a Force power | [I] Nightsister undead, canon Clone Wars, med-low |

Raiders/pirates (any era, side missions): use Old Republic trooper stats with tag `raider`, surrender at ≤3 HP (60%).

### 3.1 JSON — enemies
```json
{"enemies":{
"or_trooper":{"era":"or","n":"Sith Trooper","sym":"T","hp":4,"aim":65,"mob":5,"dmg":[2,4],"range":8,"init":8},
"or_heavy":{"era":"or","n":"Sith Heavy","sym":"H","hp":6,"aim":60,"mob":4,"dmg":[3,4],"range":7,"armor":1,"nades":1,"init":6},
"or_agent":{"era":"or","n":"Imperial Agent","sym":"I","hp":5,"aim":80,"mob":5,"dmg":[4,5],"range":11,"conceal":1,"snipeExposed":20,"init":14},
"or_acolyte":{"era":"or","n":"Sith Acolyte","sym":"A","hp":8,"aim":75,"mob":6,"dmg":[4,5],"range":1.5,"deflect":20,"guardDef":20,"tags":["force"],"lightning":[3,4],"init":13},
"or_terentatek":{"era":"or","n":"Terentatek","sym":"Ω","hp":14,"aim":80,"mob":6,"dmg":[5,7],"range":1.5,"tags":["horror","creature"],"forceOnly":1,"consumeDowned":1,"init":12},
"ru_trooper":{"era":"ru","n":"Brotherhood Trooper","sym":"T","hp":5,"aim":65,"mob":5,"dmg":[2,4],"range":8,"noSurrender":1,"auraFromTag":"sithLord","auraAim":10,"init":8},
"ru_marauder":{"era":"ru","n":"Sith Marauder","sym":"M","hp":9,"aim":75,"mob":6,"dmg":[4,6],"range":1.5,"deflect":25,"tags":["force"],"rageOnHit":1,"init":14},
"ru_lord":{"era":"ru","n":"Sith Lord","sym":"L","hp":12,"aim":80,"mob":5,"dmg":[4,6],"range":1.5,"deflect":30,"tags":["force","sithLord","elite"],"lightning":[3,5],"push":1,"forceResist":50,"init":15},
"ru_sniper":{"era":"ru","n":"Mercenary Sniper","sym":"S","hp":5,"aim":75,"mob":4,"dmg":[4,5],"range":11,"autoOW":1,"init":10},
"ru_spawn":{"era":"ru","n":"Sith Spawn","sym":"Ω","hp":10,"aim":75,"mob":5,"dmg":[4,6],"range":1.5,"tags":["horror"],"forceOnly":1,"nexusSpawn":3,"init":11},
"hr_raider":{"era":"hr","n":"Nihil Raider","sym":"N","hp":4,"aim":60,"mob":6,"dmg":[2,4],"range":7,"gasImmune":1,"hitRun":1,"init":11},
"hr_storm":{"era":"hr","n":"Nihil Storm","sym":"S","hp":8,"aim":70,"mob":5,"dmg":[3,5],"range":8,"gasImmune":1,"gasNade":{"area":1,"dot":1,"turns":3,"uses":1},"tags":["elite"],"init":12},
"hr_runner":{"era":"hr","n":"Nihil Path-Runner","sym":"R","hp":5,"aim":65,"mob":8,"dmg":[2,3],"range":6,"spawnRear":1,"init":16},
"hr_drengir":{"era":"hr","n":"Drengir","sym":"D","hp":10,"aim":70,"mob":3,"dmg":[3,5],"range":2,"tags":["creature"],"root":1,"init":5},
"hr_nameless":{"era":"hr","n":"Nameless","sym":"Ω","hp":12,"aim":85,"mob":6,"dmg":[6,8],"range":1.5,"tags":["horror","creature"],"forceOnly":1,"fearAura":{"r":3,"focusDrain":1,"blockForce":1},"init":13},
"cw_b1":{"era":"cw","n":"B1 Battle Droid","sym":"b","hp":3,"aim":55,"mob":5,"dmg":[2,3],"range":8,"tags":["droid"],"swarmAim":{"r":2,"per":10,"max":20},"squad":4,"init":6},
"cw_b2":{"era":"cw","n":"B2 Super Droid","sym":"B","hp":7,"aim":60,"mob":4,"dmg":[3,4],"range":7,"armor":2,"tags":["droid"],"ignoreCover":1,"init":5},
"cw_droideka":{"era":"cw","n":"Droideka","sym":"K","hp":6,"aim":70,"mob":7,"dmg":[3,5],"range":8,"tags":["droid"],"shield":6,"rollOrDeploy":1,"init":12},
"cw_commando":{"era":"cw","n":"Commando Droid","sym":"C","hp":5,"aim":75,"mob":6,"dmg":[3,4],"range":7,"tags":["droid"],"conceal":1,"preferClass":"Medic","init":13},
"cw_acolyte":{"era":"cw","n":"Dark Acolyte","sym":"A","hp":9,"aim":75,"mob":6,"dmg":[4,5],"range":1.5,"deflect":25,"tags":["force","elite"],"saberThrow":[3,4],"choke":[3,4],"fleeAt":3,"init":14},
"cw_revenant":{"era":"cw","n":"Nightsister Revenant","sym":"Ω","hp":8,"aim":70,"mob":5,"dmg":[4,5],"range":1.5,"tags":["horror"],"forceOnly":1,"reviveOnce":4,"killedByForcePerma":1,"init":10}
}}
```

### 3.2 AI additions
| Behavior | Rule |
|---|---|
| Horror targeting | Score only `force` targets; path through troops; prefer downed Jedi (consume). |
| Elite retreat | Elites at ≤30% HP move to max cover away from Jedi. |
| Swarm (B1) | Stay within 2 of another B1. |
| Concealed units | Don't move until a player unit is within 6 or they get a ≥70 shot. |
| Hostage pressure | In Rescue, 1 enemy per turn may target the hostage instead (see §5). |
| Difficulty tag | Legend: AI may target downed troops' adjacent allies with grenades; Easy: AI never focus-fires one target with >2 units per turn. |

---

## 4. Map interactables & events

| Object | Glyph | Cover | Interaction | Effect |
|---|---|---|---|---|
| Explosive barrel | `x` | half | Shoot it (auto-hit) / Push into enemy / Throw | 3×3, 3 dmg, sets fire 2 turns. |
| Door | `d` / `D` (locked) | full when closed | Adjacent, 1A open/close; locked needs Hack or Strike (2 strikes) | Blocks LOS. |
| Console | `k` | half | Hack (Medic) or adjacent Jedi 1A at 50% | Opens locked doors, disables turret, or calls the objective. |
| Turret | `t` | — | Hack → turns friendly 3 turns | HP 6, aim 70, 3–4 dmg, auto-overwatch. |
| Shield generator | `g` | full | Destroy (HP 6) | Enemies within 3 count as full cover. |
| Fire tile | `f` | — | Spreads 1 tile/turn to crates | 2 dmg entering or ending turn there. |
| Gas tile | `~` | — | from Nihil | 1 dmg/turn, −20 aim inside. |
| Dark nexus | `n` | — | Destroy: Jedi adjacent 2A | Jedi on it: +1 Focus/turn, Darkness +1/turn. Spawns horrors (Ruusan). |
| Collapsing ceiling | `!` | — | Triggers on Collapse/explosion nearby | Becomes rubble, 3 dmg below. |
| Beacon | `b` | half | Enemy activates (1 turn) | Reinforcements arrive in 2 turns. Destroy (HP 4) to cancel. |
| Evac zone | `E` | — | — | Units here at end of turn leave the map (Rescue/Investigate). |

**Events** (map JSON `events: [{turn|trigger, do}]`):
- `alarm`: first shot or concealment break → +1 enemy group at map edge in 2 turns.
- `reinforce`: timed drop (soft-pressure engine, §5).
- `collapse`: scripted wall falls, opening a flank.
- `ambush`: concealed group activates when a player enters a zone.

```json
{"tiles":{"x":{"n":"Barrel","cover":"half","hp":1,"explode":{"area":1,"dmg":3,"fire":2}},
"d":{"n":"Door","cover":"full","toggle":1},"D":{"n":"Locked door","cover":"full","unlock":["hack","console","strike2"]},
"k":{"n":"Console","cover":"half","use":["hack","jedi50"]},"t":{"n":"Turret","hp":6,"aim":70,"dmg":[3,4],"autoOW":1,"hackTurns":3},
"g":{"n":"Shield gen","cover":"full","hp":6,"aura":{"r":3,"cover":40}},"f":{"n":"Fire","dmg":2,"spread":1},
"~":{"n":"Gas","dot":1,"aimMod":-20},"n":{"n":"Dark nexus","focus":1,"dark":1,"destroyAp":2},
"!":{"n":"Weak ceiling","dmg":3,"becomes":"r"},"b":{"n":"Beacon","cover":"half","hp":4,"reinforceIn":2},"E":{"n":"Evac"}}}
```

---

## 5. Mission types (soft pressure)

Pressure engine (all types): **Threat** starts 0, +1 per turn after a par turn. Each Threat step triggers the type's penalty. Shown to player as a bar. No turn-count fail.

| Type | Win | Lose | Par turn | Threat penalty (per step) | Bonus |
|---|---|---|---|---|---|
| **Rescue / Protect** | Hostage (VIP: 6 HP, can move 4 if freed) reaches Evac, or all enemies down | Hostage dies; all squad down | 5 | +1 reinforcement group every 2 steps; at step 1+ one enemy/turn may shoot the hostage (aim 50) | Rescue by par: +Senate Favor / +Recruit |
| **Investigate** | Scan 3 clue terminals (Jedi/Medic adjacent 1A each) and evac ≥1 unit carrying data | All squad down | 6 | Each step: one clue destroyed (enemies wipe data) — need 2 of 3 min; reinforcements every 2 steps | All 3 clues: +2 Intel; capture an elite: +1 Intel |
| **Assault** | Kill/capture target elite or destroy target object | All squad down; target escapes via Evac (elite flees at step 3) | 6 | Elite moves 2 tiles toward escape per step; at step 3 it reaches the exit | Capture the elite instead of killing: +Intel, story flag |
| **Defend** (v0.1) | Survive N turns or wipe last wave | Objective HP 0; all squad down | n/a — the clock is the win | Waves scripted | Objective ≥75%: +Credits |

Captures in missions: any enemy at ≤50% HP or stunned/surrendered can be Subdued (v0.1). Elites need stunned/surrender. Horrors and droids can't be captured (droids can be Hacked for 1 Intel when destroyed by Hack/Ion: "salvage").

---

## 6. Captures → rescue missions

| Rule | Value |
|---|---|
| When a unit is captured | Mission lost with it downed or alive on the map; or (Legend only) downed unit adjacent to 2+ enemies at turn end. |
| Clock | Rescue crisis appears on galaxy map immediately; **3 missions/months** to answer (spec B sets the unit of time). |
| Ignored | Troop: killed. Jedi: rolls **Turned** (dark side, returns as an elite enemy with their own stats + Darkness) if Darkness ≥5, else killed. Story flag either way. |
| Rescue map | Prison/transport. Prisoner starts in a locked cell (`D`); 1 Hack or console to open; prisoner at half HP, no gear (pistol 2–3 dmg, range 6); must reach Evac. Rescue type rules apply, par 5. |
| On success | Prisoner returns with −1 aim scar for 2 missions (troops) or +1 Darkness (Jedi), and +1 bond with rescuers (spec C). |
| Captured enemies (yours) | Each = 1 Intel; elites = 2 + interrogation story event (spec C). |

---

## 7. Initiative turn order (later switch; flag `turnMode:'initiative'`)

| Rule | Spec |
|---|---|
| Order | Each round, every unit rolls `init + d6`. Highest acts first. Ties: player side first. |
| Timeline UI | Strip of tokens above the board, next 8 actors. Enemy intents shown for the next actor only. |
| Actions | Same 2 actions per activation. |
| Delay | "Wait": move yourself to after the next enemy actor (once per round). |
| Overwatch/Guard | Last until the unit's next activation (unchanged meaning). |
| Status timing | Stun = skip next activation. Bleed-out ticks at the unit's own activation slot. |
| Waves | Spawn at round start, roll into the order. |
| Code impact [I] | `endTurn` loops over a sorted queue of all units instead of `enemies()`; player input enabled only when queue head is a player unit. Est. ~80–120 lines. |
| Recommendation | Ship team turns in v0.2. Test initiative as a toggle in v0.3 with the same bot; keep whichever gives the better smart-bot win spread. |

---

## 8. Difficulty & balance targets

Jess's target: **skilled human wins ~85% on Normal.** The bot is the measuring stick, not the target. Current smart-ish bot (`test-smart.js`, guard/overwatch-heavy) wins ~25–35% on v0.1 [S: README + handoff].

Bot-to-human gap assumption **[E, low-med confidence]**: a decent scripted bot plays ~20–30 points below a skilled human in XCOM-likes. So targets:

| Difficulty | Skilled human win (target) | Smart-bot win band | Permadeaths per mission (bot, avg) | Knobs |
|---|---|---|---|---|
| Story (Easy) | ~97% | 75–90% | ≤0.05 | Enemy HP −1, enemy aim −10, bleed 6, aim assist, +1 kit |
| **Normal** | **~85%** | **55–70%** | **≤0.12** (≈1 per 8–10) | Base stats, bleed 4, aim assist |
| Hard | ~60% | 30–45% | ≤0.3 | Enemy aim +5, +1 enemy per wave, bleed 3, no aim assist |
| Legend | ~35% | 10–25% | ≤0.6 | Enemy HP +1, aim +10, +1 enemy per wave, bleed 2, captures on adjacent-downed |

```json
{"difficulty":{
"story":{"enemyHp":-1,"enemyAim":-10,"extraPerWave":0,"bleed":6,"aimAssist":10,"bonusKit":1,"botBand":[75,90],"deathsPerMission":0.05},
"normal":{"enemyHp":0,"enemyAim":0,"extraPerWave":0,"bleed":4,"aimAssist":10,"bonusKit":0,"botBand":[55,70],"deathsPerMission":0.12},
"hard":{"enemyHp":0,"enemyAim":5,"extraPerWave":1,"bleed":3,"aimAssist":0,"bonusKit":0,"botBand":[30,45],"deathsPerMission":0.3},
"legend":{"enemyHp":1,"enemyAim":10,"extraPerWave":1,"bleed":2,"aimAssist":0,"bonusKit":0,"captureAdjDowned":1,"botBand":[10,25],"deathsPerMission":0.6}
}}
```

### 8.1 How to test (Coordinator)
1. Upgrade `test-smart.js` bot to v0.2 "smart bot": per unit, score every (move tile × action) pair = expected damage dealt − expected damage taken next enemy turn (use `hitChance` + cover), plus objective weight (hostage/evac/clue distance). Take the best. Medic stabilizes/revives first. [I: one-ply greedy is enough to separate difficulties; ~60 lines]
2. Run **200 games per difficulty per mission** (40 is too few: ±15-pt noise at 95% CI; 200 ≈ ±7) [S: binomial CI math, high].
3. Log: win %, permadeaths/mission, avg turn of end, avg relay/hostage HP, abilities used count (any ability <2% use = dead design, flag it).
4. Pass = win % inside band **and** deaths ≤ target. Fail → adjust knobs in this order: enemy count, enemy aim, player HP, bleed turns. One knob per run.
5. Also keep the passive bot: it must win **<40% on Normal** (otherwise the game doesn't need thought).
6. Re-tune after Jess plays 3+ missions; his real results override the bot bands.

---

## 9. What the Coordinator should build first (v0.2 combat cut)

Ranked by value/cost **[I]**:
1. Bleed 4 + Stabilize + capture-on-loss (D3/D4) — tiny, fixes lethality.
2. Difficulty JSON + knobs + 200-game test harness.
3. Interactables: barrel, door/locked door, console, evac, beacon.
4. Mission types Rescue + Investigate + Threat bar (Defend exists).
5. Abilities: Guardian + Consular full kits, troop R1 abilities (Suppress, Hunker, Mark, Smoke, Hack, Shredder).
6. Old Republic roster add: Imperial Agent + Terentatek (tests horror rule).
7. Later: Sentinel/Wayseeker, other eras' rosters, initiative toggle.

## 10. Open items for other specs
- Spec B: XP per rank, rank timing, when Sentinel/Wayseeker unlock, mission-time unit for rescue clock.
- Spec C: Turned-Jedi story, interrogation events, bond bonuses from rescues.
- Spec D: icons for armor, Threat bar, timeline strip, `Ω` horror token, intent arrows.

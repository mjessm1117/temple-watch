/* Temple modules data (Coordinator, 2026-10-21): wing actions, excavation, bay features. Tune here. Logic: temple-modules.js. [Default] numbers, first pass.

   Wing actions: one per wing, used from its room. cd = missions before it's ready again (wing level 2+ = 1 less, min 1).
   cost = resources spent. Effects: 'now' happen at once; 'next' buffs ride into the next battle (shown in the briefing, logged at deploy). */
const MOD_ACTS={
 medical:{n:'Bacta Rush',ic:'medic',cd:3,cost:{credits:30},now:'heal',desc:'Fully heal the most wounded unit now (level 2: the two most wounded).'},
 training:{n:'Live-fire Drill',ic:'mark',cd:2,cost:{credits:20},next:{aim:5},desc:'Next battle: whole squad +5 aim.'},
 forge:{n:'Attune Sabers',ic:'kyber',cd:2,cost:{kyber:1},next:{jdmg:1},desc:'Next battle: every Jedi +1 damage.'},
 armory:{n:'Field Kits',ic:'hunker',cd:2,cost:{credits:25},next:{tarmor:1,kit:1},desc:'Next battle: troopers +1 armor pip and +1 grenade or medkit.'},
 comms:{n:'Intercept',ic:'scan',cd:2,cost:{},now:'intel',desc:'+3 Intel now from Sith traffic.'},
 archives:{n:'Study the Enemy',ic:'st_crit',cd:2,cost:{credits:15},next:{crit:10},desc:'Next battle: whole squad +10% crit.'},
 gardens:{n:'Retreat',ic:'calm',cd:3,cost:{},now:'calm',desc:'Every unit −20 stress; the darkest Jedi sheds 1 Darkness.'},
 barracks:{n:'Muster Call',ic:'guard',cd:3,cost:{credits:20},now:'recruit',desc:'+1 Recruit now.'}};

// Growth (Jess 2026-10-21: up and out). Terraces open as the Order grows (whichever comes first); the annexes widen the base later.
const TIER_OPEN={m:{wings:3,month:3},t:{wings:5,month:6},a:{month:5,era:2}};
const TIER_WHY={m:'Opens after 3 wings or month 3',t:'Opens after 5 wings or month 6',a:'Opens in month 5 or Era 2'};

// Spires: the four towers around the Council spire. Big late builds, one at a time. Names: Legends Jedi Temple towers [Medium confidence].
// eff keys: research (days per mission), stress (removed per mission), xp (per deployed unit per mission), will (in battle), month {res:n}.
const SPIRES={
 sp0:{n:'Tower of First Knowledge',ic:'scan',eff:{research:4,month:{intel:1}},tip:'Research +4 days per mission, +1 Intel a month.'},
 sp1:{n:'Tower of Reassurance',ic:'calm',eff:{stress:8,will:5},tip:'Every unit sheds 8 stress per mission; squads get +5 will in battle.'},
 sp2:{n:'Tower of Reconciliation',ic:'relay',eff:{month:{favor:3}},tip:'+3 Senate Favor a month: the Order mediates for the Republic.'},
 sp3:{n:'Tower of Guidance',ic:'mark',eff:{xp:5},tip:'Every unit you deploy gains 5 more XP per mission.'}};
const SPIRE_COST={credits:350,kyber:2},SPIRE_TIME=2,SPIRE_OPEN={month:4,era:2};

// Undercroft: 3 vaults under the base hall, dug once each (one mission) for a rare find. A find pays while its wing stands anywhere (no wing listed = always). [N] flavour
const UNDER_DIG={u0:60,u1:100,u2:140};
const BAY_FEAT={
 kyber2:{n:'Great Kyber cave',ic:'kyber',wings:['forge'],tip:'With the Kyber Forge built: +2 Kyber a month.',month:{kyber:2}},
 holocron:{n:'Holocron chamber',ic:'scan',wings:['archives'],tip:'With the Archives built: research +6 days per mission. Found: +4 Intel.',research:6,found:{intel:4}},
 crypt:{n:'Jedi crypt',ic:'calm',wings:[],tip:'Order Darkness −1 a month. The old masters rest easy.',month:{orderDark:-1}},
 spring:{n:'Hot spring',ic:'stabilize',wings:[],tip:'Wounded heal 2 more days and everyone sheds 3 stress per mission.',heal:2,stress:3},
 guard:{n:'Old Temple Guard barracks',ic:'guard',wings:['barracks'],tip:'With the Barracks built: +1 Recruit a month.',month:{recruits:1}},
 cache:{n:'Forgotten arms cache',ic:'hunker',wings:['armory'],tip:'With the Armory built: +10 Credits per won mission. Found: +40 Credits.',winCr:10,found:{credits:40}},
 hall:{n:'Old sparring hall',ic:'strike',wings:['training'],tip:'With the Training Salle built: units who sit out a mission gain 4 XP.',bench:4}};
const UNDER_POOL=['holocron','crypt','spring','guard','cache','hall'];   // + one Great Kyber cave guaranteed

// New Sith schemes (merged into SITH_OPS; counter with Intel or a team as usual). Custom effects run in temple-modules.js opHits wrap. [N]
Object.assign(SITH_OPS,{
 saboteurs:{n:'Temple saboteurs',intel:2,jam:2,desc:'If ignored: saboteurs jam 2 wing actions for 3 missions.'},
 ritual:{n:'Dark ritual',intel:3,res:{orderDark:5},desc:'If ignored: Order Darkness +5.'},
 hunter:{n:'Sith hunter',intel:3,hunt:1,desc:'If ignored: a hunter stalks your best unit (wounded 14 days, +30 stress).'}});

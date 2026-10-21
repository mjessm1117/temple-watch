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

// Excavation: sublevel 1 is open from the start. Deeper bays are rock until dug. One dig at a time; a dig takes one mission.
const DIG_COST={1:0,2:40,3:80,4:140,5:220};
// Deeper floors open later in the campaign (whichever comes first). Until then they are hidden.
const DEEP_OPEN={4:{month:5,era:2},5:{month:10,era:2}};
// Bay features: rolled once per bay (seeded by campaign), revealed when the bay is dug. Bonus applies only with a matching wing on top. [N] flavour
const BAY_FEAT={
 kyber:{n:'Kyber vein',ic:'kyber',wings:['forge'],tip:'Kyber Forge here: +1 Kyber a month.',month:{kyber:1}},
 vault:{n:'Sealed Jedi vault',ic:'scan',wings:['archives'],tip:'Archives here: research +3 days per mission. Digging it out: +2 Intel.',research:3,found:{intel:2}},
 spring:{n:'Hot spring',ic:'stabilize',wings:['medical','gardens'],tip:'Medical or Gardens here: wounded heal 2 more days and everyone sheds 3 stress per mission.',heal:2,stress:3},
 hall:{n:'Old sparring hall',ic:'strike',wings:['training'],tip:'Training here: units who sit out a mission gain 4 XP.',bench:4},
 cache:{n:'Forgotten arms cache',ic:'hunker',wings:['armory'],tip:'Armory here: +10 Credits per won mission. Digging it out: +30 Credits.',winCr:10,found:{credits:30}},
 antenna:{n:'Deep relay mast',ic:'relay',wings:['comms'],tip:'Comms here: +1 Intel a month.',month:{intel:1}},
 rubble:{n:'Collapsed tunnel',ic:'collapse',wings:[],tip:'Nothing special. Salvage paid for part of the dig: +20 Credits.',found:{credits:20}}};
// Rare finds, deep floors only.
Object.assign(BAY_FEAT,{
 kyber2:{n:'Great Kyber cave',ic:'kyber',wings:['forge'],tip:'Kyber Forge here: +2 Kyber a month.',month:{kyber:2}},
 holocron:{n:'Holocron chamber',ic:'scan',wings:['archives'],tip:'Archives here: research +6 days per mission. Digging it out: +4 Intel.',research:6,found:{intel:4}},
 crypt:{n:'Jedi crypt',ic:'calm',wings:['gardens'],tip:'Gardens here: Order Darkness −1 a month. The old masters rest easy.',month:{orderDark:-1}},
 barracks2:{n:'Old Temple Guard barracks',ic:'guard',wings:['barracks'],tip:'Barracks here: +1 Recruit a month.',month:{recruits:1}}});
const DEEP_FEAT_POOL=['kyber2','holocron','crypt','barracks2','spring','rubble'];
const BAY_FEAT_POOL=['kyber','vault','spring','hall','cache','antenna','rubble','rubble'];

// New Sith schemes (merged into SITH_OPS; counter with Intel or a team as usual). Custom effects run in temple-modules.js opHits wrap. [N]
Object.assign(SITH_OPS,{
 saboteurs:{n:'Temple saboteurs',intel:2,jam:2,desc:'If ignored: saboteurs jam 2 wing actions for 3 missions.'},
 ritual:{n:'Dark ritual',intel:3,res:{orderDark:5},desc:'If ignored: Order Darkness +5.'},
 hunter:{n:'Sith hunter',intel:3,hunt:1,desc:'If ignored: a hunter stalks your best unit (wounded 14 days, +30 stress).'}});

/* Combat data: difficulty knobs, enemies, missions (maps, waves, rewards). Tune numbers here. Spec: docs/specs/combat.md */
// Board size (Chat M, wave 5): maps can be any size. 10×12 until state.js swaps these for getters that follow S.grid.
Object.defineProperty(window,'W',{value:10,configurable:true,writable:true});Object.defineProperty(window,'H',{value:12,configurable:true,writable:true});
// Map legend: # wall · O objective (relay/shrine) · d door · D locked door  = full cover, blocks movement
//             c crate · x barrel · k console · q clue terminal · Q scanned clue = half cover, blocks movement
//             r rubble (half cover, walkable) · . floor · _ open door · E evac zone
//             ^ raised ground (elev 1, walkable) · M high ledge (elev 2; reach it from ^, a 2-level step is a cliff)
// B2 wave 7: every enemyAim +5 (bot won ~75% on Normal after graze/hack/melee charge/wing buffs; band 55–70).
const DIFF={
 story: {n:'Story', enemyHp:-1,enemyAim:-5,extra:0,bleed:6,assist:10,bonusKit:1,income:1.3},
 normal:{n:'Normal',enemyHp:0, enemyAim:5,  extra:0,bleed:4,assist:10,bonusKit:0,income:1},
 hard:  {n:'Hard',  enemyHp:0, enemyAim:10, extra:1,bleed:3,assist:0, bonusKit:0,income:.85},
 legend:{n:'Legend',enemyHp:1, enemyAim:15, extra:1,bleed:2,assist:0, bonusKit:0,income:.7}};
const FOES={
 trooper:{desc:'Standard rifleman: 4 HP, range 8. Seeks cover and flanks.',n:'Sith Trooper',ic:'e_trooper',hp:4,aim:65,mob:5,dmg:[2,4],range:8,init:8},
 heavy:{desc:'6 HP, 1 armor, one grenade. Its hits strip cover and armor.',n:'Sith Heavy',ic:'e_heavy',hp:6,aim:60,mob:4,dmg:[3,4],range:7,armor:1,nades:1,shredder:1,init:6},
 agent:{desc:'Sniper (range 11) who starts hidden and gets +20 aim on targets out of cover. Spotted within 4 tiles, or when it fires.',n:'Imperial Agent',ic:'e_agent',hp:5,aim:80,mob:5,dmg:[4,5],range:11,hid:1,snipe:20,init:14},
 acolyte:{desc:'Dark-side melee fighter: deflects bolts and throws Force lightning (range 5). Hunts Jedi. Can’t be captured.',n:'Sith Acolyte',ic:'e_acolyte',hp:8,aim:75,mob:6,dmg:[4,5],range:1.5,deflect:20,guardDef:20,force:1,lightning:[3,4],noCap:1,init:13},
 terentatek:{tags:['creature'],desc:'Force horror, 14 HP. Only hurts Jedi; troops are immune. Devours a Jedi left down and unstabilized beside it.',n:'Terentatek',ic:'e_horror',hp:14,aim:80,mob:6,dmg:[5,7],range:1.5,horror:1,noCap:1,init:12},
 envoy:{desc:'The traitor envoy. Weak; surrenders easily. Capture him for intel.',n:'Envoy Saresh',ic:'e_envoy',hp:4,aim:50,mob:5,dmg:[1,2],range:6,envoy:1,init:9}};
// Generic hostage when no captured unit needs rescue.
const VIP={n:'Aide Mira Tal',cls:'VIP',ic:'vip',hp:6,aim:50,mob:4,dmg:[1,2],range:6,init:5,abil:['stabilize','door']};
const MISSIONS={
 relay:{n:'Relay Aurek-7',where:'Outpost Aurek-7 · Sith frontier',type:'defend',story:1,theme:'plains',turns:8,obj:20,objName:'Relay',lastWave:5,
  map:["^^......^^","..#....#..",".c..cc..c.","....##....",".c......c.","##.c..c.##","....cc....",".#......#.",".c.c..c.c.","^^c.##..^^","M^.cOOc.^M",".........."],
  waves:{1:['trooper','trooper','trooper'],3:['trooper','trooper','heavy'],5:['acolyte','trooper','trooper']},
  start:[[2,11],[6,9],[2,8],[9,9],[4,11],[5,8]],
  brief:'Imperial Sith troopers are closing on a frontier hyperspace relay. Hold it for 8 turns until the fleet arrives. Three waves are expected.',
  goal:'Hold the relay for 8 turns. The fleet is coming.',
  win:'The Republic fleet drops out of hyperspace. The relay held.',lose:'The relay fell. The Sith now hold the hyperlane toward the Core.',
  reward:{credits:80},bonus:{credits:40},bonusTxt:'Relay above 75%'},
 shrine:{n:'Dantooine Shrine',where:'Pilgrim shrine · Dantooine',type:'defend',theme:'plains',turns:6,obj:16,objName:'Shrine',lastWave:4,
  map:["..........",".c^^##^^c.","....cc....","#..c..c..#",".c......c.","...#..#...",".c..cc..c.","..........",".c.c..c.c.","...#OO#...","....OO....",".........."],
  waves:{1:['trooper','trooper','heavy'],2:['terentatek','trooper'],4:['trooper','heavy','trooper']},
  start:[[2,10],[7,10],[3,11],[6,11],[1,9],[8,9]],
  brief:'Sith troopers are raiding a kyber shrine. Pilgrims swear something else came with them: a beast that hunts Jedi. Hold for 6 turns.',
  goal:'Hold the shrine for 6 turns. The Terentatek can only hurt Jedi, and it devours a downed Jedi left unstabilized for a turn. Troops are your shield.',
  win:'The pilgrims come out of hiding. The shrine stands.',lose:'The shrine is looted. The pilgrims scatter.',
  reward:{kyber:1,credits:60},bonus:{credits:30},bonusTxt:'Shrine above 75%'},
 rescue:{n:'Ord Mantell Depot',where:'Supply depot · Ord Mantell',type:'rescue',par:5,theme:'dock',patrol:{1:[[2,4],[6,4],[6,7],[2,7]]},
  map:["..c....c..","...####...",".c.#..#k..","...#D##...",".x......c.","..c.cc.x..","#^^....c.#",".c^.##..c.","....cc..^^",".c......c.","....c.c...","EE......EE"],
  hostage:[5,2],foes:[['trooper',2,4,1],['trooper',6,4,1],['heavy',5,0,2],['agent',8,1]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  brief:'Sith raiders hold a prisoner in a locked cell. A Medic can Hack the door from 4 tiles; a Jedi can try the console. Then walk the prisoner to an evac zone (E).',
  goal:'Open the cell (Hack or console), then get the prisoner to an evac zone. Threat rises after turn 5; at Threat 6 they fly the prisoner out.',
  win:'The prisoner is out. The shuttle lifts off under fire.',lose:'The prisoner is lost.',
  reward:{credits:90,favor:5},bonus:{recruits:1},bonusTxt:'Done by turn 5'},
 envoy:{n:"The Envoy's Trail",where:'Lower city · Coruscant',type:'investigate',story:1,theme:'city',par:6,
  map:["q.c.#..c.q","....#.....",".c..d..x..",".#.##..##.","^..c...c.^",".x...q....","..c##..c..","....#....x",".c..d..c..","..........",".c..cc..c.","EE......EE"],
  foes:[['trooper',2,1],['trooper',7,1],['heavy',6,0],['agent',8,4],['envoy',5,1]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  brief:'A Republic envoy is leaking the peace-talk schedule. Scan his data terminals (Jedi or Medic, adjacent). Once 2 are copied, anyone who reaches an evac zone gets the data out. Capture him if you can.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. Threat rises after turn 6: terminals get wiped, and at Threat 6 the trail goes cold.',
  win:'The data is out. The Council reads it that night.',lose:'The trail goes cold.',
  reward:{credits:70},bonus:{intel:2},bonusTxt:'All 3 terminals'}};

// ---- Wave 2 (Chat H): tile table, map variants, new mission types ----
// Every tile: name, cover (0 none · 1 half · 2 full), h = 3D height for the view (half 1, full 2), walk, breaks = what one blast/Heavy hit turns it into.
// The 2D board can borrow an old look with `as`.
const TILES={
 '.':{n:'Floor',desc:'Open ground. No cover.',cover:0,h:0,walk:1},'_':{n:'Open door',desc:'An open doorway. No cover.',cover:0,h:0,walk:1},E:{n:'Evac zone',desc:'Units here can extract once the objective is done.',cover:0,h:0,walk:1},
 r:{n:'Rubble',desc:'Half cover you can stand on.',cover:1,h:.5,walk:1},
 '^':{n:'Raised ground',desc:'Raised ground: +15 aim on lower targets, and their cover counts 10 less. One level up from the floor.',cover:0,h:0,elev:1,walk:1,ramp:1},M:{n:'High ledge',desc:'High ledge, two levels up: the best firing spot, and you can see over walls. Climb to it from raised ground.',cover:0,h:0,elev:2,walk:1},
 c:{n:'Crate',desc:'Half cover. Explosions and Heavies break it into rubble.',cover:1,h:1,breaks:'r'},h:{n:'Broken wall',desc:'Half cover. One more blast turns it to rubble.',cover:1,h:1,breaks:'r',as:'c'},
 x:{n:'Barrel',desc:'Half cover that explodes when shot or blasted: 3 damage in a 3×3.',cover:1,h:1},k:{n:'Console',desc:'Half cover. Use it to unlock the doors.',cover:1,h:1},q:{n:'Data terminal',desc:'Half cover. Scan it to copy the data.',cover:1,h:1},Q:{n:'Copied terminal',desc:'Half cover. Already copied.',cover:1,h:1},
 b:{n:'Alarm beacon',desc:'Half cover. An enemy beside it can call reinforcements; shoot it (4 HP) to stop that.',cover:1,h:1,as:'k'},C:{n:'Charge site',desc:'Half cover. Plant a charge here.',cover:1,h:1,as:'q'},X:{n:'Armed charge',desc:'Half cover. An armed charge; enemy techs may defuse it.',cover:1,h:1,as:'qd'},
 '#':{n:'Wall',desc:'Full cover. Blocks movement and sight.',cover:2,h:2},B:{n:'Blast wall',desc:'Full cover until an explosion cracks it into a broken wall.',cover:2,h:2,breaks:'h',as:'w'},
 O:{n:'Objective',desc:'The objective. Full cover; enemies shoot it.',cover:2,h:2},d:{n:'Door',desc:'Full cover. Open it with 1 action.',cover:2,h:2},D:{n:'Locked door',desc:'Full cover. Hack or use a console to open.',cover:2,h:2}};
const BEACON_HP=4;
// Escort VIPs (free from the start; walk them to an evac zone).
const ESCORTS={
 senator:{n:'Senator Ondo Ral',cls:'VIP',ic:'vip',hp:6,aim:50,mob:3,dmg:[1,2],range:6,init:5,abil:['stabilize','door']},
 defector:{n:'Lt. Corin Varn',cls:'VIP',ic:'vip',hp:7,aim:60,mob:4,dmg:[2,3],range:6,init:6,abil:['stabilize','door']}};
// Map variants: a crisis picks the base map or one of `alts` at random. Alts only swap the layout (map, start, foes, hostage, where).
MISSIONS.shrine.alts=[{where:'Grove terraces · Dantooine',theme:'jungle',
 map:["..........",".c^^B^^c..","....c.....",".B.x...B..","......c...",".c.B..B.c.","..........",".h..cc..h.","..c....c..","...#OO#...","...cOOc...",".........."],
 start:[[2,10],[7,10],[2,11],[7,11],[1,9],[8,9]]}];
MISSIONS.rescue.alts=[{where:'Cliffside cell block · Ord Mantell',
 map:["^^......^^",".c..cc..c.","...####...",".k.#..#.x.","...##D#...",".B......B.","...c..c...",".h..x...h.","...B..B...",".c..cc..c.","..........","EE..c...EE"],
 hostage:[4,3],theme:'ruins',foes:[['trooper',2,1,1],['trooper',7,1,1],['trooper',2,4,2],['heavy',5,6,2],['agent',8,6]],patrol:{2:[[2,6],[7,6],[7,8],[2,8]]},
 start:[[3,11],[5,11],[6,11],[7,11],[2,10],[7,10]]}];
Object.assign(MISSIONS,{
 archive:{n:'The Listening Post',where:'Imperial listening post · Balmorra',type:'investigate',par:6,theme:'ruins',stealth:1,patrol:{2:[[8,3],[8,7],[3,7],[3,3]]},
  map:["..q#......","...#.c..#q",".c.B....h.","....x..^^.",".h..##..h.","....q.....",".c.B..B.c.","^^......^^",".x..cc..c.","..........",".c..h..c..","EE......EE"],
  foes:[['trooper',1,1,1],['trooper',6,1,2],['heavy',5,3,3],['agent',7,6],['trooper',8,3,2]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[8,10]],
  alts:[{where:'Data vault · Nar Shaddaa',
   map:["...c..c...",".q..##..q.","##d#..#d##","^^......^^",".B.x..b.B.","...h..h...",".c..q...c.","...h..B...",".h.^..^.h.","..c.cc.c..","..........","EE......EE"],
   theme:'city',foes:[['trooper',2,0,1],['trooper',7,0,1],['heavy',5,3,2],['agent',9,5]],patrol:{1:[[2,3],[7,3]]},start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]]}],
  brief:'An Imperial post is reading Republic fleet traffic. Copy its data terminals (Jedi or Medic, adjacent), then get anyone to an evac zone. Blast walls crack under explosions.',
  goal:'Scan 2 of 3 terminals, then reach an evac zone. Threat rises after turn 6: terminals get wiped. Shoot alarm beacons before they call help.',
  win:'The fleet codes are ours. Navy Intelligence owes the Order a favor.',lose:'The post burns its data. The trail goes cold.',
  reward:{credits:60,intel:1},bonus:{intel:2},bonusTxt:'All 3 terminals'},
 sabotage:{n:'Fuel Depot Strike',where:'Imperial fuel depot · Balmorra',type:'sabotage',par:7,need:2,field:['plant'],theme:'dock',stealth:1,patrol:{2:[[6,5],[2,8],[8,8]]},
  map:["EE.#..#.EE","E..#..#..E","...h..h...",".c..xx..c.",".C..##..C.",".h..^^..h.","...c..b...",".B..cc..B.","^^......^^",".c.h..h.c.","..........","..c....c.."],
  foes:[['trooper',2,2,1],['trooper',7,2,1],['heavy',4,1,1],['trooper',6,5,2],['agent',9,6],['trooper',8,8,2],['trooper',3,8,2]],reinforce:['trooper','heavy'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  alts:[{where:'Ion cannon battery · Balmorra',
   map:["EE......EE","E..c..c..E",".B.#..#.B.",".C.#..#.C.",".x......x.","..h.C..h..",".c..BB..c.","^^......^^",".B.c..c.B.","..........",".c..x...c.",".........."],
   theme:'plains',foes:[['trooper',4,1,1],['trooper',7,1,1],['trooper',5,4,2],['agent',0,5],['trooper',2,7,2]],patrol:{2:[[2,7],[7,7],[5,4]]},start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]]}],
  brief:'The Empire fuels its Balmorra fleet from this depot. Plant charges on 2 sites (anyone, adjacent, 1 action), then get every standing squad member onto the far evac zone. The charges blow when you are clear.',
  goal:'Plant 2 charges (adjacent, 1 action), then get everyone still standing onto the north evac zone. Threat rises after turn 7: techs defuse an armed charge each step.',
  win:'The depot goes up behind you. The Balmorra fleet sits dry for a month.',lose:'The depot holds. The fleet sails on schedule.',
  reward:{credits:80,favor:3},bonus:{credits:40},bonusTxt:'Done by turn 7'},
 escort:{n:'The Senator\'s Walk',where:'Lower city · Coruscant',type:'escort',theme:'city',par:6,vip:'senator',
  map:["..c....EEE","....B.....",".h..x..b^^","...B..h...",".c....B.c.","...cc.....",".B.....h..","...x.c....",".c....B.c.","...h......","^^......^^",".c..cc..c."],
  hostage:[4,10],foes:[['trooper',2,1],['trooper',6,1],['heavy',5,3],['agent',9,3],['trooper',8,6],['trooper',0,6]],reinforce:['trooper','trooper'],
  start:[[2,10],[3,10],[5,10],[6,10],[1,9],[7,9]],
  alts:[{where:'Ravine crossing · Ord Mantell',vip:'defector',theme:'caves',
   map:["EE..c.....","E...B..c..","..h...x...","###d##..##","^^......^^",".c.B..c.B.","....x.....",".h..##..h.","..........","##..B.###.","..........",".c..cc..c."],
   hostage:[5,10],foes:[['trooper',6,0],['trooper',9,2],['heavy',2,4],['agent',8,4],['trooper',5,6]],
   start:[[2,10],[3,10],[6,10],[7,10],[0,11],[9,10]]}],
  brief:'Someone the Empire wants dead must reach a shuttle at the far evac zone. They take one move a turn on your phase. Keep them alive.',
  goal:'Walk the VIP to an evac zone. Threat rises after turn 6: more hunters arrive and they shoot the VIP on sight.',
  win:'The shuttle lifts off with its passenger.',lose:'The Empire gets its kill.',
  reward:{credits:70,favor:6},bonus:{recruits:1},bonusTxt:'Done by turn 6'}});

// ---- Wave 3 (Chat X): statuses (for tooltips/codex), default mission themes, tactics numbers.
const STATUS={
 stunned:{n:'Stunned',desc:'Loses its next turn. Easier to capture and to hit (+30).'},
 surrender:{n:'Surrendered',desc:'Has given up. Subdue it for intel; killing it darkens the Order.'},
 down:{n:'Down',desc:'Bleeding out. Stabilize or revive before the counter hits 0.'},
 guard:{n:'Guard',desc:'Deflects more bolts and strikes enemies that come adjacent.'},
 overwatch:{n:'Overwatch',desc:'Fires at the first enemy that moves in sight (−15 aim; no penalty during an ambush).'},
 suppressed:{n:'Suppressed',desc:'−30 aim; moving draws a free shot.'},
 marked:{n:'Marked',desc:'Everyone gets +15 aim against it.'},
 hunker:{n:'Hunkered',desc:'+30 defense and no flank crits until its next turn.'},
 barrier:{n:'Barrier',desc:'Counts as full cover from every side.'},
 disarmed:{n:'Disarmed',desc:'Can’t shoot, throw or use lightning next turn. Can still move and strike.'},
 rooted:{n:'Rooted',desc:'Can’t move on its next turn.'},
 shield:{n:'Shielded',desc:'A shield soaks the next points of damage.'},
 concealed:{n:'Concealed',desc:'Enemies haven’t seen you. Stay out of red tiles; your first attack is an Ambush (+20 aim).'},
 panic:{n:'Panicked',desc:'Fear takes over next turn: freezes, runs for cover, or fires wildly.'},
 highground:{n:'High ground',desc:'+15 aim against lower targets, whose cover counts 10 less.'},
 stable:{n:'Stabilized',desc:'Down but no longer bleeding out.'},
 tricked:{n:'Mind-tricked',desc:'Will attack its own side on its next turn.'}};
// Missions without a theme (other chats' files) fall back here; the view reads S.theme.
const THEME_OF={dock:'dock',blockade:'plains',cache:'ruins',hutt:'city'};
// Timed loot drops (turns.js). w = weight. desc = what picking it up does.
const LOOT={intel:{n:'Intel cache',w:3,desc:'+1 Intel.'},credits:{n:'Credit chit',w:3,desc:'10–25 Credits after the mission.'},
 kit:{n:'Medkit',w:3,desc:'+1 medkit for this mission.'},nade:{n:'Grenade',w:2,desc:'+1 grenade for this mission.'},
 cell:{n:'Focus cell',w:2,desc:'+2 Focus (Jedi) or +2 HP (troops).'}};
// Assault Threat text when the mission doesn't set escape/near/push.
const ASSAULT_TXT={_:{escape:'The target gets away.',near:'The target is about to get away.',push:'The target pulls back.'},
 r_bomb:{escape:'The thought bomb fires.',near:'The ritual is almost complete. Next turn it fires.',push:'Kaan\'s Lords chant louder.'},
 r_nexus:{escape:'The nexus erupts.',near:'The nexus is about to erupt.',push:'The nexus pulses.'}};
// Per-map balance (Chat X): enemy aim/HP offsets so the weak test bot wins ~55–70% on Normal. Key 'id:variant' (or 'id' for all variants).
// extra/fewer = add/remove that many of the mission's rank-and-file foe.
const TUNE={
 "relay:0":{aim:-7},
 "rescue:0":{aim:8},
 "envoy:0":{aim:3,hp:1,extra:2},
 "archive:0":{aim:12,hp:2},
 "archive:1":{aim:-5},
 "sabotage:1":{aim:8,hp:1,extra:1},
 "escort:0":{aim:13},
 "escort:1":{aim:10,hp:1},
 "blockade:0":{aim:-12,hp:-1},
 "cache:0":{aim:15,hp:2,extra:1},
 "hutt:0":{aim:15,hp:2},
 "dock:0":{aim:-15},
 "vault:0":{aim:-18},
 "ilum:0":{aim:10},
 "adraasHunt:0":{aim:0},
 "taris:0":{aim:2,hp:1,extra:3},
 "thul:0":{aim:5,hp:1},
 "thul:1":{aim:13},
 "depot:1":{aim:10,hp:2,extra:1},
 "fort:0":{aim:15,hp:1,extra:2},
 "fort:1":{aim:10,hp:1,extra:2},
 "r_ravine:0":{aim:20,hp:2,extra:1},
 "r_caves:0":{aim:10,hp:1},
 "r_bomb:0":{aim:-6},
 "r_hospital:0":{aim:10,hp:1},
 "r_snipers:0":{aim:15,hp:1,extra:3},
 "r_dump:0":{aim:7},
 "depot:0":{aim:5},
 "shrine:0":{aim:3},
 "r_nexus:0":{aim:10},
 "shrine:1":{aim:0},
 // Wave 6 maps (Chat M2): new biome layouts.
 "shrine:5":{aim:-10},"fort:5":{aim:-10},"rescue:3":{aim:10,hp:1,extra:1},"taris:3":{aim:10,hp:1,extra:1},"archive:5":{aim:10,hp:1,extra:1}};

/* Combat data: difficulty knobs, enemies, missions (maps, waves, rewards). Tune numbers here. Spec: docs/specs/combat.md */
const W=10,H=12;
// Map legend: # wall · O objective (relay/shrine) · d door · D locked door  = full cover, blocks movement
//             c crate · x barrel · k console · q clue terminal · Q scanned clue = half cover, blocks movement
//             r rubble (half cover, walkable) · . floor · _ open door · E evac zone
const DIFF={
 story: {n:'Story', enemyHp:-1,enemyAim:-10,extra:0,bleed:6,assist:10,bonusKit:1,income:1.3},
 normal:{n:'Normal',enemyHp:0, enemyAim:0,  extra:0,bleed:4,assist:10,bonusKit:0,income:1},
 hard:  {n:'Hard',  enemyHp:0, enemyAim:5,  extra:1,bleed:3,assist:0, bonusKit:0,income:.85},
 legend:{n:'Legend',enemyHp:1, enemyAim:10, extra:1,bleed:2,assist:0, bonusKit:0,income:.7}};
const FOES={
 trooper:{n:'Sith Trooper',ic:'e_trooper',hp:4,aim:65,mob:5,dmg:[2,4],range:8,init:8},
 heavy:{n:'Sith Heavy',ic:'e_heavy',hp:6,aim:60,mob:4,dmg:[3,4],range:7,armor:1,nades:1,shredder:1,init:6},
 agent:{n:'Imperial Agent',ic:'e_agent',hp:5,aim:80,mob:5,dmg:[4,5],range:11,hid:1,snipe:20,init:14},
 acolyte:{n:'Sith Acolyte',ic:'e_acolyte',hp:8,aim:75,mob:6,dmg:[4,5],range:1.5,deflect:20,guardDef:20,force:1,lightning:[3,4],noCap:1,init:13},
 terentatek:{n:'Terentatek',ic:'e_horror',hp:14,aim:80,mob:6,dmg:[5,7],range:1.5,horror:1,noCap:1,init:12},
 envoy:{n:'Envoy Saresh',ic:'e_envoy',hp:4,aim:50,mob:5,dmg:[1,2],range:6,envoy:1,init:9}};
// Generic hostage when no captured unit needs rescue.
const VIP={n:'Aide Mira Tal',cls:'VIP',ic:'vip',hp:6,aim:50,mob:4,dmg:[1,2],range:6,init:5,abil:['stabilize','door']};
const MISSIONS={
 relay:{n:'Relay Aurek-7',where:'Outpost Aurek-7 · Sith frontier',type:'defend',story:1,turns:8,obj:20,objName:'Relay',lastWave:5,
  map:["..........","..#....#..",".c..cc..c.","....##....",".c......c.","##.c..c.##","....cc....",".#......#.",".c.c..c.c.","..c.##....","...cOOc...",".........."],
  waves:{1:['trooper','trooper','trooper'],3:['trooper','trooper','heavy'],5:['acolyte','trooper','trooper']},
  start:[[3,9],[6,9],[2,8],[9,9],[4,11],[5,8]],
  brief:'Imperial Sith troopers are closing on a frontier hyperspace relay. Hold it for 8 turns until the fleet arrives. Three waves are expected.',
  goal:'Hold the relay for 8 turns. The fleet is coming.',
  win:'The Republic fleet drops out of hyperspace. The relay held.',lose:'The relay fell. The Sith now hold the hyperlane toward the Core.',
  reward:{credits:80},bonus:{credits:40},bonusTxt:'Relay above 75%'},
 shrine:{n:'Dantooine Shrine',where:'Pilgrim shrine · Dantooine',type:'defend',turns:6,obj:16,objName:'Shrine',lastWave:4,
  map:["..........",".c..##..c.","....cc....","#..c..c..#",".c......c.","...#..#...",".c..cc..c.","..........",".c.c..c.c.","...#OO#...","....OO....",".........."],
  waves:{1:['trooper','trooper'],2:['terentatek'],4:['trooper','heavy']},
  start:[[2,10],[7,10],[3,11],[6,11],[1,9],[8,9]],
  brief:'Sith troopers are raiding a kyber shrine. Pilgrims swear something else came with them: a beast that hunts Jedi. Hold for 6 turns.',
  goal:'Hold the shrine for 6 turns. The Terentatek can only hurt Jedi, and it devours a downed Jedi left unstabilized for a turn. Troops are your shield.',
  win:'The pilgrims come out of hiding. The shrine stands.',lose:'The shrine is looted. The pilgrims scatter.',
  reward:{kyber:1,credits:60},bonus:{credits:30},bonusTxt:'Shrine above 75%'},
 rescue:{n:'Ord Mantell Depot',where:'Supply depot · Ord Mantell',type:'rescue',par:5,
  map:["..c....c..","...####...",".c.#..#k..","...#D##...",".x......c.","..c.cc.x..","#......c.#",".c..##..c.","....cc....",".c......c.","....c.c...","EE......EE"],
  hostage:[5,2],foes:[['trooper',2,4],['trooper',6,4],['heavy',5,0],['agent',8,1]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  brief:'Sith raiders hold a prisoner in a locked cell. A Medic can Hack the door from 4 tiles; a Jedi can try the console. Then walk the prisoner to an evac zone (E).',
  goal:'Open the cell (Hack or console), then get the prisoner to an evac zone. Threat rises after turn 5; at Threat 6 they fly the prisoner out.',
  win:'The prisoner is out. The shuttle lifts off under fire.',lose:'The prisoner is lost.',
  reward:{credits:90,favor:5},bonus:{recruits:1},bonusTxt:'Done by turn 5'},
 envoy:{n:"The Envoy's Trail",where:'Lower city · Coruscant',type:'investigate',story:1,par:6,
  map:["q.c.#..c.q","....#.....",".c..d..x..","##.##..##.","...c...c..",".x...q....","..c##..c..","....#....x",".c..d..c..","..........",".c..cc..c.","EE......EE"],
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
 '.':{n:'Floor',cover:0,h:0,walk:1},'_':{n:'Open door',cover:0,h:0,walk:1},E:{n:'Evac zone',cover:0,h:0,walk:1},
 r:{n:'Rubble',cover:1,h:.5,walk:1},
 c:{n:'Crate',cover:1,h:1,breaks:'r'},h:{n:'Broken wall',cover:1,h:1,breaks:'r',as:'c'},
 x:{n:'Barrel',cover:1,h:1},k:{n:'Console',cover:1,h:1},q:{n:'Data terminal',cover:1,h:1},Q:{n:'Copied terminal',cover:1,h:1},
 b:{n:'Alarm beacon',cover:1,h:1,as:'k'},C:{n:'Charge site',cover:1,h:1,as:'q'},X:{n:'Armed charge',cover:1,h:1,as:'qd'},
 '#':{n:'Wall',cover:2,h:2},B:{n:'Blast wall',cover:2,h:2,breaks:'h',as:'w'},
 O:{n:'Objective',cover:2,h:2},d:{n:'Door',cover:2,h:2},D:{n:'Locked door',cover:2,h:2}};
const BEACON_HP=4;
// Escort VIPs (free from the start; walk them to an evac zone).
const ESCORTS={
 senator:{n:'Senator Ondo Ral',cls:'VIP',ic:'vip',hp:6,aim:50,mob:3,dmg:[1,2],range:6,init:5,abil:['stabilize','door']},
 defector:{n:'Lt. Corin Varn',cls:'VIP',ic:'vip',hp:7,aim:60,mob:4,dmg:[2,3],range:6,init:6,abil:['stabilize','door']}};
// Map variants: a crisis picks the base map or one of `alts` at random. Alts only swap the layout (map, start, foes, hostage, where).
MISSIONS.shrine.alts=[{where:'Grove terraces · Dantooine',
 map:["..........",".c..B..c..","....c.....",".B.x...B..","......c...",".c.B..B.c.","..........",".h..cc..h.","..c....c..","...#OO#...","...cOOc...",".........."],
 start:[[2,10],[7,10],[2,11],[7,11],[1,9],[8,9]]}];
MISSIONS.rescue.alts=[{where:'Cliffside cell block · Ord Mantell',
 map:["..........",".c..cc..c.","...####...",".k.#..#.x.","...##D#...",".B......B.","...c..c...",".h..x...h.","...B..B...",".c..cc..c.","..........","EE..c...EE"],
 hostage:[4,3],foes:[['trooper',2,1],['trooper',7,1],['trooper',2,4],['heavy',5,6],['agent',8,6]],
 start:[[3,11],[5,11],[6,11],[7,11],[2,10],[7,10]]}];
Object.assign(MISSIONS,{
 archive:{n:'The Listening Post',where:'Imperial listening post · Balmorra',type:'investigate',par:6,
  map:["..q#....#.","...#.c..#q",".c.B....B.","....x.....",".h..##..h.","....q.....",".c.B..B.c.","..........",".x..cc..c.","..........",".c..h..c..","EE......EE"],
  foes:[['trooper',1,1],['trooper',6,1],['heavy',5,3],['agent',7,6],['trooper',8,3]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[8,10]],
  alts:[{where:'Data vault · Nar Shaddaa',
   map:["...c..c...",".q..##..q.","##d#..#d##","..........",".B.x..b.B.","...h..h...",".c..q...c.","...B..B...",".h......h.","..c.cc.c..","..........","EE......EE"],
   foes:[['trooper',2,0],['trooper',7,0],['heavy',5,3],['agent',9,5]],start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]]}],
  brief:'An Imperial post is reading Republic fleet traffic. Copy its data terminals (Jedi or Medic, adjacent), then get anyone to an evac zone. Blast walls crack under explosions.',
  goal:'Scan 2 of 3 terminals, then reach an evac zone. Threat rises after turn 6: terminals get wiped. Shoot alarm beacons before they call help.',
  win:'The fleet codes are ours. Navy Intelligence owes the Order a favor.',lose:'The post burns its data. The trail goes cold.',
  reward:{credits:60,intel:1},bonus:{intel:2},bonusTxt:'All 3 terminals'},
 sabotage:{n:'Fuel Depot Strike',where:'Imperial fuel depot · Balmorra',type:'sabotage',par:7,need:2,field:['plant'],
  map:["EE.#..#.EE","E..#..#..E","...B..B...",".c..xx..c.",".C..##..C.",".h......h.","...c..b...",".B..cc..B.","..........",".c.h..h.c.","..........","..c....c.."],
  foes:[['trooper',2,2],['trooper',7,2],['heavy',4,1],['trooper',6,5],['agent',9,6],['trooper',8,8]],reinforce:['trooper','heavy'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  alts:[{where:'Ion cannon battery · Balmorra',
   map:["EE......EE","E..c..c..E",".B.#..#.B.",".C.#..#.C.",".x......x.","..h.C..h..",".c..BB..c.","..........",".B.c..c.B.","..........",".c..x...c.",".........."],
   foes:[['trooper',4,1],['trooper',7,1],['heavy',5,4],['agent',0,5],['trooper',2,7]],start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]]}],
  brief:'The Empire fuels its Balmorra fleet from this depot. Plant charges on 2 sites (anyone, adjacent, 1 action), then get every standing squad member onto the far evac zone. The charges blow when you are clear.',
  goal:'Plant 2 charges (adjacent, 1 action), then get everyone still standing onto the north evac zone. Threat rises after turn 7: techs defuse an armed charge each step.',
  win:'The depot goes up behind you. The Balmorra fleet sits dry for a month.',lose:'The depot holds. The fleet sails on schedule.',
  reward:{credits:80,favor:3},bonus:{credits:40},bonusTxt:'Done by turn 7'},
 escort:{n:'The Senator\'s Walk',where:'Lower city · Coruscant',type:'escort',par:6,vip:'senator',
  map:["..c....EEE","....B.....",".h..x..b..","...B..h...",".c....B.c.","...cc.....",".B.....h..","...x.c....",".c....B.c.","...h......","..........",".c..cc..c."],
  hostage:[4,10],foes:[['trooper',2,1],['trooper',6,1],['heavy',5,3],['agent',9,3],['trooper',8,6],['trooper',0,6]],reinforce:['trooper','trooper'],
  start:[[2,10],[3,10],[5,10],[6,10],[1,9],[7,9]],
  alts:[{where:'Ravine crossing · Ord Mantell',vip:'defector',
   map:["EE..c.....","E...B..c..","..h...x...","###d##..##","..........",".c.B..c.B.","....x.....",".h..##..h.","..........","##..B.###.","..........",".c..cc..c."],
   hostage:[5,10],foes:[['trooper',6,0],['trooper',9,2],['heavy',2,4],['agent',8,4],['trooper',5,6]],
   start:[[2,10],[3,10],[6,10],[7,10],[0,11],[9,10]]}],
  brief:'Someone the Empire wants dead must reach a shuttle at the far evac zone. They take one move a turn on your phase. Keep them alive.',
  goal:'Walk the VIP to an evac zone. Threat rises after turn 6: more hunters arrive and they shoot the VIP on sight.',
  win:'The shuttle lifts off with its passenger.',lose:'The Empire gets its kill.',
  reward:{credits:70,favor:6},bonus:{recruits:1},bonusTxt:'Done by turn 6'}});

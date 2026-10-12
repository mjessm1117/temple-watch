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
 heavy:{n:'Sith Heavy',ic:'e_heavy',hp:6,aim:60,mob:4,dmg:[3,4],range:7,armor:1,nades:1,init:6},
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
  goal:'Open the cell (Hack or console), then get the prisoner to an evac zone. Threat rises after turn 5.',
  win:'The prisoner is out. The shuttle lifts off under fire.',lose:'The prisoner is lost.',
  reward:{credits:90,favor:5},bonus:{recruits:1},bonusTxt:'Done by turn 5'},
 envoy:{n:"The Envoy's Trail",where:'Lower city · Coruscant',type:'investigate',story:1,par:6,
  map:["q.c.#..c.q","....#.....",".c..d..x..","##.##..##.","...c...c..",".x...q....","..c##..c..","....#....x",".c..d..c..","..........",".c..cc..c.","EE......EE"],
  foes:[['trooper',2,1],['trooper',7,1],['heavy',6,0],['agent',8,4],['envoy',5,1]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  brief:'A Republic envoy is leaking the peace-talk schedule. Scan his data terminals (Jedi or Medic, adjacent). Once 2 are copied, anyone who reaches an evac zone gets the data out. Capture him if you can.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. Threat rises after turn 6: terminals get wiped.',
  win:'The data is out. The Council reads it that night.',lose:'The trail goes cold.',
  reward:{credits:70},bonus:{intel:2},bonusTxt:'All 3 terminals'}};

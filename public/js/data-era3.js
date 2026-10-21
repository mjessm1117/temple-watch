/* Era 3 data: the High Republic (~232–230 BBY), 12 missions in 3 Acts, one boss per Act. Logic: story-era3.js. Pattern: data-era2.js.
   Loads after data-era2.js; adds to FOES, MISSIONS, CRISES, ESCORTS, EVENTS, COUNCIL_SEATS, STORY_RECRUITS, FLAG_LINES, EPI, CODEX, TUNE.
   Tables defined later in the load order (SEATS, GUESTS, PLANETS, FIELD_PLANETS, REDEEM_TXT) get their Era 3 rows in story-era3.js.
   Lore confidence (Disney canon, "C"): Great Hyperspace Disaster at Hetzal, 232 BBY (High); Starlight Beacon dedicated by Chancellor Lina Soh, 232 BBY (Med);
   Nihil attack on the Republic Fair at Valo ~231 BBY (Med); Starlight Beacon falls ~230 BBY (Med); Marchion Ro, Eye of the Nihil (High); Lourna Dee, a Tempest Runner (High);
   the Great Progenitor leads the Drengir (High); Nameless creatures prey on Force users and leave Jedi as dust-like husks (High); the Leveler is Ro's Nameless (High);
   Orla Jareni is a Wayseeker (High). [N] = our invention. Tone (Jess 2026-10-21): a golden age that cracks. */
const ERA3={n:'High Republic',bby:232,next:'Clone Wars · ~22 BBY',
 shard:{t:'A third shard',text:'The sealed vision stirs. A great light hangs over a frontier world, and falls. Jedi stand in the wreck, afraid of something they cannot see. The fire on the Temple steps is no longer far.'},
 jump:'Nearly eight centuries pass. The Sith are a story for children. The Republic is reaching for the frontier with Jedi beside it: Starlight Beacon is lit, and Chancellor Lina Soh calls it an age of light and life. Then a ship breaks apart in hyperspace.',
 carry:{credits:.3,favorTo:50,orderDark:.5,warChest:200},   // same as Era 2 (spec B §1.4) [Default]
 eraModMax:2};   // +1 foe HP per lost era boss so far, cap +2 (spec B: +1 tier per lost boss, cap +2)
const ACTS3={2:{t:'A year passes',text:'A year of fighting the Nihil in the dark between stars. The Senate still calls it an age of light. The Jedi have stopped saying it.'},
 3:{t:'Another year',text:'Another year. Jedi come home from the frontier quiet, and some do not come home at all. Something out there eats the Force.'}};
const SHARDS3={2:'The vision returns: a fair on a green world, banners burning, and a masked man watching from the smoke.',
 3:'The vision is clear now: a station of light falling into a sea, and Jedi turned to dust where they stood.'};

// High Republic roster (spec A §3). Signature behaviors live in story-era3.js: hitRun, gas, pathJump, root, seed, dread, pathEscape, eyeMark.
// 3D looks come from kindOf (view3d/units.js) via icon/flags: e_raider→Nihil masked trooper ('sith'), e_heavy→'sithHeavy', e_agent→'agent', horror or e_horror→'beast'.
Object.assign(FOES,{
 nihil_raider:{n:'Nihil Raider',ic:'e_raider',hp:4,aim:62,mob:6,dmg:[2,4],range:7,hitRun:1,init:11,
  desc:'Hit and run: after it shoots, it dashes back toward cover.'},
 nihil_storm:{n:'Nihil Storm',ic:'e_heavy',hp:8,aim:70,mob:5,dmg:[3,5],range:8,nades:1,gas:1,elite:1,init:12,
  desc:'Nihil officer. One gas grenade: anyone it catches chokes (−15 aim for 2 turns).'},
 path_runner:{n:'Nihil Path-Runner',ic:'e_agent',hp:5,aim:65,mob:7,dmg:[2,3],range:6,pathJump:2,init:16,
  desc:'Rides a secret hyperspace Path. Not here on turn 1; drops in behind your squad on turn 2.'},
 drengir:{n:'Drengir',ic:'e_horror',hp:10,aim:70,mob:3,dmg:[3,5],range:1.5,root:1,noCap:1,init:5,
  desc:'Carnivorous plant. Hurts everyone. A vine hit roots the target: it cannot move next turn.'},
 nameless:{n:'Nameless',ic:'e_horror',hp:12,aim:80,mob:6,dmg:[5,7],range:1.5,horror:1,dread:1,noCap:1,init:13,
  desc:'Force horror: only hurts Jedi; troops are immune. Dread: Jedi within 3 tiles aim −15 and lose 1 Focus each enemy turn.'},
 great_progenitor:{n:'The Great Progenitor',ic:'e_horror',hp:16,aim:70,mob:2,dmg:[4,6],range:1.5,armor:1,root:1,seed:3,boss:1,noCap:1,init:6,
  desc:'Drengir hive mother. Armor 1, roots what it hits, and a new Drengir sprouts beside it every 3 turns. Defeat it to win.'},
 lourna_dee:{n:'Lourna Dee',ic:'e_agent',hp:13,aim:80,mob:6,dmg:[4,5],range:6,armor:1,pathEscape:3,boss:1,noCap:1,init:15,
  desc:'Tempest Runner of the Nihil. Armor 1. The first time she drops to half HP she Path-jumps across the field and heals 3. Defeat her to win.'},
 lourna_ret:{n:'Lourna Dee',ic:'e_agent',hp:10,aim:80,mob:6,dmg:[4,5],range:6,armor:1,noCap:1,elite:1,init:15,
  desc:'She got away from you once. She came back for the Eye\'s big night.'},
 marchion_ro:{n:'Marchion Ro',ic:'e_heavy',hp:14,aim:78,mob:5,dmg:[4,5],range:8,armor:2,eyeMark:15,boss:1,noCap:1,init:14,
  desc:'The Eye of the Nihil. Armor 2. Whoever he shoots is Marked: every Nihil gets +15 aim against them until his next turn. Defeat him to win.'},
 leveler:{n:'The Leveler',ic:'e_horror',hp:16,aim:85,mob:6,dmg:[6,8],range:1.5,armor:1,horror:1,dread:1,noCap:1,init:13,
  desc:'Ro\'s Nameless. Only hurts Jedi; troops are immune and must carry this fight. Dread aura (3 tiles): Jedi aim −15, lose 1 Focus a turn.'},
 root_mother:{n:'Drengir Root-Mother',ic:'e_horror',hp:14,aim:0,mob:0,dmg:[0,0],range:0,armor:1,seed:3,boss:1,noCap:1,init:1,
  desc:'A Drengir bloom anchored in the soil. Does not move or attack; a Drengir sprouts beside it every 3 turns. Destroy it to win.'}});

// Escort VIPs.
Object.assign(ESCORTS,{
 hz_survivor:{n:'Survivor Ona Teff',cls:'VIP',ic:'vip',hp:6,aim:50,mob:3,dmg:[1,2],range:6,init:5,abil:['stabilize','door']},   // [N]
 pathfinder:{n:'Pathfinder Jory Calm',cls:'VIP',ic:'vip',hp:6,aim:60,mob:4,dmg:[2,3],range:6,init:6,abil:['stabilize','door']}});   // [N]

// Reskin an Era 1 (or Era 2) mission for the High Republic: mirrored layout (flip:false keeps it), foe types swapped, alts dropped. Same idea as ruusanOf.
const HR_FOES={trooper:'nihil_raider',heavy:'nihil_storm',agent:'path_runner',mando:'nihil_raider',envoy:'nihil_raider',acolyte:'nihil_storm',terentatek:'drengir',
 bh_trooper:'nihil_raider',bh_marauder:'nihil_storm',bh_sniper:'nihil_raider',sith_spawn:'drengir',sith_lord:'nihil_storm',nexus_core:'root_mother'};
function hrOf(id,x){const B=MISSIONS[id],f=t=>HR_FOES[t]||t,o={alts:[],era:3,quote:undefined,...x},fl=x.flip===false?X=>X:X=>W-1-X;
 const M=x.flip===false?{...B,story:0,...o}:mirrorMission(B,o);
 if(!x.foes&&B.foes)M.foes=B.foes.map(([t,X,Y,...r])=>[f(t),fl(X),Y,...r]);
 if(!x.reinforce&&B.reinforce)M.reinforce=B.reinforce.map(f);
 if(!x.waves&&B.waves){M.waves={};for(const k in B.waves)M.waves[k]=B.waves[k].map(f)}
 if(!x.patrol&&B.patrol){M.patrol={};for(const k in B.patrol)M.patrol[k]=B.patrol[k].map(([X,Y])=>[fl(X),Y])}
 return M}

Object.assign(MISSIONS,{
 // ── Act I (232 BBY): the Great Disaster ──
 h_hetzal:{n:'Hetzal Fragments',where:'Impact fields · Hetzal',type:'escort',story:1,era:3,theme:'plains',par:6,vip:'hz_survivor',
  map:["EE..c...EE","E...c..c.E",".h..r...h.","..r...x...",".c..##..c.","....rr....","#.c....c.#","..x.rr..h.",".h......c.","..c.r..r..","..........",".c..cc..c."],
  hostage:[4,10],foes:[['nihil_raider',0,2],['nihil_raider',8,3],['nihil_storm',4,5],['path_runner',6,1],['nihil_raider',3,6]],reinforce:['nihil_raider','nihil_raider'],
  start:[[2,10],[3,10],[5,10],[6,10],[0,9],[7,10]],
  brief:'A starship broke apart in hyperspace. Its pieces are still falling on Hetzal at lightspeed. Masked raiders are already looting the wreck fields. Walk a survivor to the evac at the north end.',
  goal:'Walk the survivor to an evac zone (E). Raiders shoot and dash back to cover. A Path-Runner drops in behind you on turn 2. Threat rises after turn 6.',
  win:'The survivor is out. Marshal Avar Kriss asks who your squad is.',lose:'The impact fields swallow the last transport.',
  reward:{credits:70,recruits:1},bonus:{favor:4},bonusTxt:'Done by turn 6'},
 h_grove:{n:'The Progenitor\'s Grove',where:'Drengir grove · Wild Space',type:'assault',story:1,era:3,theme:'jungle',par:7,bossKey:'great_progenitor',
  push:'The grove thickens.',near:'The grove is about to swallow the valley. Next turn you must pull out.',escape:'The grove closes over the valley.',
  map:["c...^^...c","..c....c..",".r..rr..r.","..h....h..",".c..##..c.","....c.....",".x......x.","..c.rr.c..",".h......h.","...c..c...",".c......c.",".........."],
  foes:[['great_progenitor',4,1],['drengir',2,2],['drengir',7,2],['drengir',5,5]],reinforce:['drengir'],
  start:[[3,11],[4,11],[5,11],[6,11],[1,11],[8,11]],
  brief:'The Drengir are waking: plants that think, hunt, and eat. Their hive mother, the Great Progenitor, has rooted in a valley of farms. Cut her out before the grove spreads.',
  goal:'Defeat the Great Progenitor (16 HP, armor 1). A Drengir sprouts beside her every 3 turns, and vine hits root you in place. Threat rises after turn 7.',
  win:'The Progenitor withers. The grove goes quiet, then brown.',lose:'The grove swallows the valley. The farmers do not come back.',
  reward:{credits:100,kyber:1},bonus:{favor:4},bonusTxt:'Done by turn 7'},
 // ── Act II (231 BBY): the Nihil ──
 h_valo:{n:'The Fair at Valo',where:'Republic Fair grounds · Valo',type:'defend',story:1,era:3,theme:'city',turns:7,obj:20,objName:'Chancellor\'s pavilion',lastWave:5,
  map:["....##....",".c......c.","...x..c...",".^^....^^.","..c.##.c..","h........h","...c..c...",".B..rr..B.","..c....c..","....^^....","..cOOOOc..",".........."],
  waves:{1:['nihil_raider','nihil_raider','nihil_raider'],3:['nihil_raider','path_runner','nihil_storm'],5:['nihil_storm','nihil_raider','nihil_raider']},
  start:[[3,9],[6,9],[2,9],[7,9],[2,11],[7,11]],
  brief:'The Republic Fair: a whole world dressed up to show the frontier what the Republic can be. The Nihil came to burn it. Hold the Chancellor\'s pavilion for 7 turns while the crowds get out.',
  goal:'Hold the pavilion for 7 turns. Path-Runners drop in behind your line; Storms throw choking gas.',
  win:'The pavilion stands. Lina Soh walks out of the smoke and thanks every one of you by name.',lose:'The pavilion burns on every holonet in the galaxy.',
  reward:{credits:90,favor:6},bonus:{credits:30},bonusTxt:'Pavilion above 75%'},
 h_tempest:{n:'The Tempest Runner',where:'Nihil hideout · Wild Space',type:'assault',story:1,era:3,theme:'dock',par:6,bossKey:'lourna_dee',
  push:'Lourna\'s crew spins up the Path engines.',near:'Her ship is almost ready to jump. Next turn she is gone.',escape:'Lourna Dee jumps to hyperspace.',
  map:["..c.##.c..",".c..##..c.","....^^....",".x.c..c.x.","..r....r..",".c.B..B.c.","..........","..h.cc.h..",".c......c.","...r..r...",".c..cc..c.",".........."],
  foes:[['lourna_dee',5,2],['nihil_storm',2,4],['nihil_raider',8,4],['nihil_raider',1,6],['path_runner',6,0]],reinforce:['nihil_raider','nihil_raider'],
  start:[[3,11],[4,11],[5,11],[6,11],[1,11],[8,11]],
  brief:'Intel from Valo points to a Nihil hideout at the edge of Wild Space and one of the three Tempest Runners: Lourna Dee. Take her down before her ship jumps.',
  goal:'Defeat Lourna Dee (13 HP, armor 1). At half HP she Path-jumps away once and heals. Threat rises after turn 6; at Threat 6 she escapes.',
  win:'Lourna Dee goes down hard. The Nihil lose a Tempest.',lose:'Her ship jumps. She will remember your faces.',
  reward:{credits:110,intel:2},bonus:{favor:4},bonusTxt:'Done by turn 6'},
 // ── Act III (230 BBY): the Eye and the Leveler ──
 h_husks:{n:'The Hollow Jedi',where:'Abandoned outpost · Wild Space',type:'investigate',story:1,era:3,theme:'caves',par:6,
  map:["##..q..###","#..c.....#","#.q....c.#","##..##..##","#...c....#","#.x.#..q.#","##..#.r.##","#.c....c.#","#..h..h..#","##.....###","#.c.rr.c.#","EE......EE"],
  foes:[['nameless',3,4],['nihil_raider',1,2],['nihil_raider',8,2],['nihil_storm',6,4]],reinforce:['nihil_raider','nihil_raider'],
  start:[[3,11],[4,11],[5,11],[6,11],[3,10],[6,10]],
  brief:'Three Jedi went into this outpost. Their comlinks still answer. They are standing in the corridors, gray as stone, and they crumble when touched. Copy the outpost logs and find out what did this.',
  goal:'Scan 2 of 3 terminals (Jedi or Medic, adjacent), then reach an evac zone. All 3 tells you more. The Nameless only hurts Jedi: send troops first.',
  win:'The logs name it: a Nameless. Ro keeps one on a leash.',lose:'The outpost goes dark with you still in it.',
  reward:{credits:70,intel:2},bonus:{intel:1},bonusTxt:'All 3 terminals'},
 // Era boss: the Fall of Starlight. Assault: defeat Ro before Threat 6. The Leveler only hurts Jedi. Lourna returns if she escaped in Act II.
 h_beacon:{n:'The Fall of Starlight',where:'Starlight Beacon · Outer Rim',type:'assault',story:1,era:3,theme:'dock',bossKey:'marchion_ro',
  push:'Another section of the station goes dark.',near:'Starlight is losing orbit. Next turn it falls.',escape:'Starlight Beacon falls.',
  get par(){const f=typeof C!=='undefined'&&C?C.flags:{};return 6+(f.e3_leveler_found?1:0)+(f.e3_beacon_warned?1:0)},
  map:["..c.##.c..",".c..MM..c.","....^^....",".x.B..B.x.","..........","#.c.cc.c.#","....rr....",".h......h.","...c..c...",".B......B.","..c.^^.c..",".........."],
  get foes(){const f=[['marchion_ro',4,1],['leveler',5,3],['nihil_storm',2,4],['nihil_raider',7,4],['nihil_raider',1,6]],F=typeof C!=='undefined'&&C?C.flags:{};
   if(F.e3_lourna_escaped)f.push(['lourna_ret',8,0]);return f},
  reinforce:['nihil_raider','path_runner'],start:[[3,11],[4,11],[5,11],[6,11],[1,11],[8,11]],
  brief:'The Nihil are inside Starlight Beacon. The station is failing, and something on board is turning Jedi to dust. Marchion Ro is here to watch it fall. Stop him while Starlight can still be saved.',
  goal:'Defeat Marchion Ro (14 HP, armor 2) before Threat 6, when Starlight falls. The Leveler only hurts Jedi: troops are immune. Ro Marks whoever he shoots.',
  win:'Ro falls on his own station. Starlight holds its orbit.',lose:'Starlight Beacon falls.',
  reward:{credits:120,kyber:1},bonus:{favor:5},bonusTxt:'Done by the par turn'},
 // ── Crises ──
 h_roots:{...MISSIONS.r_nexus,n:'The Root-Mother',where:'Overgrown farmland · Hetzal',era:3,theme:'jungle',bossKey:'root_mother',quote:undefined,
  push:'The roots spread.',near:'The roots are about to reach the town.',escape:'The roots take the town.',
  foes:[['root_mother',5,1],['drengir',4,2],['nihil_raider',2,4],['nihil_raider',7,4],['drengir',5,4]],reinforce:['nihil_raider','nihil_raider'],
  brief:'A Drengir bloom has rooted in farmland. It grows a new Drengir every few turns. Nihil scavengers are picking through what is left. Destroy the Root-Mother.',
  goal:'Destroy the Root-Mother (14 HP, armor 1). A Drengir sprouts beside it every 3 turns. Threat rises after turn 7.',
  win:'The bloom dies. The town keeps its fields.',lose:'The roots take the town.',reward:{credits:60,kyber:1},bonus:{intel:1},bonusTxt:'Done by turn 7'},
 h_salvage:hrOf('shrine',{n:'Emergence Salvage',where:'Wreck site · Hetzal',theme:'plains',objName:'Salvage crane',
  waves:{1:['nihil_raider','nihil_raider','nihil_raider'],2:['nihil_storm','nihil_raider'],4:['nihil_raider','path_runner','nihil_storm']},
  brief:'Republic crews are pulling a fallen hull out of a field before it can kill anyone else. The Nihil want what is inside. Hold the crane for 6 turns.',
  goal:'Hold the salvage crane for 6 turns. Path-Runners drop in behind you.',
  win:'The hull comes up empty of Nihil.',lose:'The Nihil strip the wreck.',reward:{credits:60,recruits:1},bonus:{favor:3},bonusTxt:'Crane above 75%'}),
 h_scouts:hrOf('escort',{n:'The Lost Pathfinder',where:'Survey camp · Valo',theme:'jungle',vip:'pathfinder',
  brief:'A Republic pathfinder mapped a Nihil Path and lived. The Nihil know it. Get him to the shuttle.',
  win:'The pathfinder\'s charts reach the Republic.',lose:'The charts burn with the camp.',reward:{credits:70,intel:1},bonus:{recruits:1},bonusTxt:'Done by turn 6'}),
 h_cache:hrOf('sabotage',{n:'Path Engine Cache',where:'Nihil depot · Wild Space',theme:'dock',
  foes:[['nihil_raider',7,2,1],['nihil_raider',2,2,1],['nihil_storm',5,1,1],['nihil_raider',3,5,2],['nihil_raider',1,8,2],['path_runner',0,6]],reinforce:['nihil_raider','nihil_raider'],
  brief:'The Nihil hide their Path engines here, the secret that lets them strike anywhere. Plant charges on 2 sites, then get every standing squad member onto the evac zone.',
  win:'The cache goes up. The Nihil jump less often for a while.',lose:'The cache holds.',reward:{credits:80,favor:3},bonus:{credits:40},bonusTxt:'Done by turn 7'}),
 h_prisoners:hrOf('rescue',{flip:false,n:'Nihil Prison Barge',where:'Prison barge · Outer Rim',theme:'dock',hostN:'Padawan Reath Coll',
  brief:'The Nihil hold a prisoner on a barge. A Medic can Hack the cell door from 4 tiles; a Jedi can try the console. Then walk the prisoner to an evac zone (E).',
  win:'The prisoner is out.',lose:'The prisoner is lost.',reward:{credits:80,favor:4},bonus:{recruits:1},bonusTxt:'Done by turn 5'}),
 h_buoy:hrOf('archive',{n:'Nihil Comm Buoy',where:'Relay station · Outer Rim',theme:'dock',
  brief:'A relay is passing Nihil orders between Storms. Copy its terminals (Jedi or Medic, adjacent), then get anyone to an evac zone.',
  win:'The Storms\' orders are ours for a month.',lose:'The relay wipes itself.',reward:{credits:60,intel:2},bonus:{intel:1},bonusTxt:'All 3 terminals'}),
 h_outpost:hrOf('relay',{n:'Frontier Outpost',where:'Republic outpost · Valo',theme:'plains',objName:'Outpost',
  waves:{1:['nihil_raider','nihil_raider'],3:['nihil_raider','nihil_raider','nihil_storm'],5:['nihil_raider','path_runner','nihil_raider']},
  brief:'A Republic outpost is the only beacon for twenty systems of settlers. Nihil raiders want it dark. Hold it for 8 turns.',
  goal:'Hold the outpost for 8 turns. Path-Runners drop in behind you.',win:'The outpost stays lit.',lose:'The outpost goes dark.',reward:{credits:80},bonus:{credits:30},bonusTxt:'Outpost above 75%'})});
// Extra guards so the reused layouts aren't walkovers.
MISSIONS.h_prisoners.foes.push(['nihil_storm',6,6],['nihil_raider',9,8]);
MISSIONS.h_hetzal.foes.push(['nihil_storm',5,0],['nihil_raider',2,1]);
MISSIONS.h_scouts.foes.push(['nihil_raider',8,0],['nihil_storm',5,4]);

// Per-map balance (E3 owns these rows). Same format as data.js TUNE. Target: weak test bot wins ~55–70% on Normal.
Object.assign(TUNE,{"h_hetzal:0":{aim:25,hp:3,extra:2},"h_grove:0":{aim:15,hp:2,extra:1},"h_valo:0":{aim:15,hp:1,extra:1},"h_tempest:0":{aim:15,hp:2,extra:1},
 "h_husks:0":{aim:15,hp:2,extra:1},"h_beacon:0":{aim:8,hp:1},"h_roots:0":{aim:25,hp:3,extra:1},"h_salvage:0":{aim:12,hp:1,extra:1},"h_scouts:0":{aim:15,hp:2,extra:1},
 "h_cache:0":{aim:20,hp:3,extra:1},"h_prisoners:0":{aim:20,hp:2,extra:1},"h_buoy:0":{aim:28,hp:2,extra:1},"h_outpost:0":{aim:12,hp:1,extra:1}});

Object.assign(CRISES,{
 h_roots:{n:'The Root-Mother',kind:'Assault',src:'Jedi',mission:'h_roots',text:'A Drengir bloom is growing new Drengir in a farm valley.',ignore:{favor:-3,orderDark:4}},
 h_salvage:{n:'Emergence salvage',kind:'Defend',src:'Senate',mission:'h_salvage',text:'Nihil raiders are hitting a Republic crew pulling a fallen hull out of a field.',ignore:{favor:-5}},
 h_scouts:{n:'The lost pathfinder',kind:'Escort',src:'Senate',mission:'h_scouts',text:'A pathfinder who mapped a Nihil Path is pinned in his camp.',ignore:{favor:-5}},
 h_cache:{n:'Path engine cache',kind:'Sabotage',src:'Jedi',mission:'h_cache',text:'Blow the cache that lets the Nihil jump anywhere.',ignore:{favor:-3}},
 h_prisoners:{n:'Nihil prison barge',kind:'Rescue',src:'Jedi',mission:'h_prisoners',text:'A Padawan is held on a Nihil prison barge.',ignore:{favor:-3,orderDark:4}},
 h_buoy:{n:'Nihil comm buoy',kind:'Investigate',src:'Jedi',mission:'h_buoy',text:'A relay is passing Nihil orders. Copy them and get out.',ignore:{favor:-3}},
 h_outpost:{n:'Frontier outpost',kind:'Defend',src:'Senate',mission:'h_outpost',text:'Raiders are closing on the only beacon for twenty systems.',ignore:{favor:-5}}});

// Era 3 plan (swapped in for PLAN by story-era3.js): Act I (232) · A year passes · Act II (231) · A year passes · Act III (230, Starlight).
// years:1 is special-cased in story-era3.js (story.js treats years ≤1 as the default 5-year jump).
const PLAN3=[
 {story:'h_hetzal'},{crises:['h_salvage','h_roots']},{crises:['h_scouts','h_buoy']},{story:'h_grove'},
 {years:1,act:2},
 {crises:['h_outpost','h_prisoners']},{story:'h_valo'},{crises:['h_cache','h_salvage','h_roots']},{story:'h_tempest'},
 {years:1,act:3},
 {crises:['h_buoy','h_scouts','h_prisoners']},{story:'h_husks'},{crises:['h_cache','h_outpost','h_roots']},{story:'h_beacon'}];

// Fresh Era 3 squad, with the first Wayseeker. [N]
const ERA3_ROSTER=[
 {n:'Knight Sava Orrin',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['saberThrow','leap'],col:'#62b3ff',age:30},
 {n:'Tem Ruhl',cls:'Wayseeker',title:'Padawan',col:'#72e0a4',age:18},
 {n:'Sgt. Dace Morrow',cls:'Soldier',age:34},{n:'Kiri Vass',cls:'Scout',age:26},{n:'Doc Halden Pree',cls:'Medic',age:44},{n:'Bruk Tannar',cls:'Heavy',age:31}];

// Council cameos (spec C §6). Veter = Consular stance (patience, the Order's nerve); Gios = Guardian stance (face it head on).
Object.assign(COUNCIL_SEATS,{veter:{n:'Grand Master Pra-Tre Veter',loyalty:60},gios:{n:'Master Stellan Gios',loyalty:60}});
// Rare recruit (max 1 canon rare per era): Orla Jareni, a Wayseeker with a white double-bladed saber (C, High). Age [N].
Object.assign(STORY_RECRUITS,{orla:{n:'Orla Jareni',cls:'Wayseeker',title:'Knight',rank:2,xp:30,picks:['pathfinder','tremor'],col:'#f2f2f2',age:38}});

// Era 3 events (spec C §3). trigger.era:3 keeps them in this era. Choices that follow a Council voice say whose way.
EVENTS.push(
 {id:'e3_light_life',trigger:{type:'era_start',era:3},text:'Chancellor Lina Soh wants Jedi on Starlight Beacon, her great work on the frontier. Master Veter worries the Order is becoming the Republic\'s lantern.',
  choices:[{label:'Gios\'s way: send Knights',effects:{favor:6,loyalty:{seat:'gios',n:10},loyalty_2:{seat:'veter',n:-10}}},{label:'Veter\'s way: a few, as guests',effects:{orderDark:-4,loyalty:{seat:'veter',n:10}}}]},
 {id:'e3_pathfinders',trigger:{type:'month',min:1,era:3},text:'Republic pathfinders want Jedi escorts to map new hyperlanes after the Disaster. Glory, risk, and Senate goodwill.',
  choices:[{label:'Send escorts',effects:{favor:3,chance:.75,fail:{wound:{who:'squad_leader',turns:2}}}},{label:'Temple first',effects:{credits:40}}]},
 {id:'e3_orla',trigger:{type:'after_mission',min:2,era:3},text:'Orla Jareni, a Wayseeker who answers to no Council, offers her white blade to your strike teams. "For a while. Until the Force says otherwise."',
  choices:[{label:'Welcome her',effects:{recruit:'orla',flag:'orla_joined',loyalty:{seat:'veter',n:-10}}},{label:'Let her walk her path',effects:{loyalty:{seat:'veter',n:10},kyber:1}}]},
 {id:'e3_grappa',trigger:{type:'flag',flag:'e3_grove_done',era:3},text:'Mother Grappa, a Hutt, offers a crop poison that kills Drengir. Her price: Jedi look away from her spice ships for a year.',
  choices:[{label:'Take the deal',effects:{kyber:1,credits:60,orderDark:4}},{label:'Refuse the Hutt',effects:{favor:2}}]},
 {id:'e3_yoda',trigger:{type:'act',min:2,era:3},text:'Master Yoda, already centuries old, comes to the Temple between journeys. He offers a season of teaching.',
  choices:[{label:'Teach the young',effects:{unitDark:{who:'jedi_highestDark',n:-2},recruits:1}},{label:'Counsel the Council',effects:{orderDark:-6,loyalty:{seat:'veter',n:10}}}]},
 {id:'e3_ro_name',trigger:{type:'flag',flag:'e3_ro_named',era:3},text:'A Nihil taken at Valo names their leader: Marchion Ro, the Eye. The Senate wants proof before it acts.',
  choices:[{label:'Gios\'s way: hunt him now',effects:{intel:2,loyalty:{seat:'gios',n:10},orderDark:4}},{label:'Veter\'s way: give the Senate proof',effects:{favor:5,intel:-1,loyalty:{seat:'veter',n:10},flag:'e3_beacon_warned'}}]},
 {id:'e3_hole',trigger:{type:'act',min:3,era:3},text:'A Wayseeker felt something empty on the frontier. Like the Force had a hole in it. The Council does not want to hear it.',
  choices:[{label:'Study it',effects:{intel:1,flag:'e3_hole_studied'}},{label:'Bury the report',effects:{shadow:1}}]},
 // Ruusan echoes (read Era 2's outcome).
 {id:'e3_bane_line',trigger:{type:'all',era:3,all:[{type:'era_start',era:3},{type:'flag',flag:'rule_of_two',era:3}]},
  text:'A Nihil Storm\'s accounts show payments in coin no bank has ever issued. Someone outside the Nihil is feeding them. [N]',
  choices:[{label:'Follow the coin',effects:{intel:2,credits:-40,flag:'e3_sith_hint'}},{label:'Pirates are pirates',effects:{shadow:1}}]},
 {id:'e3_bane_vault',trigger:{type:'all',era:3,all:[{type:'era_start',era:3},{type:'flag',flag:'e2_bane_captured',era:3}]},
  text:'Bane died in a Jedi cell centuries ago. His holocron is still in the Temple vault, and a Padawan says it has started to whisper. [N]',
  choices:[{label:'Seal it deeper',effects:{orderDark:-4}},{label:'Study it',effects:{intel:3,unitDark:{who:'jedi_random',n:2}}}]});

const STORY_TEXT3={
 groveWin:'The Great Progenitor withers. Drengir everywhere fall still.',groveLose:'The grove spreads. Drengir blooms will dog this era.',
 tempest:{dead:'Lourna Dee will never run another Tempest.',escaped:'Lourna Dee jumped away. She will be back.'},
 bossWin:'Ro falls on Starlight. The station holds its orbit, and the Jedi stand a little straighter.',
 bossLose:'Starlight Beacon falls into the sea. The age of light ends in one night.',
 eraWin:'Starlight still shines. The frontier is wounded, but it is the Republic\'s frontier.',
 eraLose:'The light went out over the frontier. The Order draws inward and is afraid.',
 darkWarn:'The Order is drifting. Fear of the dark is making it hard.'};
Object.assign(FLAG_LINES,{e3_hetzal_saved:'You pulled survivors out of the Hetzal impact fields.',e3_grove_done:'You went into the Progenitor\'s grove.',
 e3_progenitor_down:'The Great Progenitor died in her grove.',e3_valo_held:'The Chancellor\'s pavilion held at Valo.',e3_ro_named:'A captured Nihil named the Eye: Marchion Ro.',
 e3_lourna_dead:STORY_TEXT3.tempest.dead,e3_lourna_escaped:STORY_TEXT3.tempest.escaped,e3_leveler_found:'You read the outpost logs: you knew what the Leveler was.',
 e3_beacon_saved:'Starlight Beacon did not fall. In canon it fell into the sea of Eiram.',e3_beacon_fell:'Starlight Beacon fell, as it did in canon.',
 e3_ro_down:'Marchion Ro died on Starlight. In canon he lived to burn more of the frontier.',orla_joined:'Orla Jareni walked with your strike teams.',
 e3_sith_hint:'You followed strange coin from the Nihil to someone else. The trail went cold.',e3_beacon_warned:'You gave the Senate proof about Ro before Starlight.'});
Object.assign(EPI,{
 h_hetzal:{win:'The survivor holds Avar Kriss\'s hand the whole way up.',lose:'Hetzal counts its dead in the millions.'},
 h_grove:{win:'Farmers come back to the valley. They burn everything green, just to be sure.',lose:'The valley is a grove now. Nothing in it is a farm.'},
 h_valo:{win:'The Fair goes on, the next day, smaller and braver.',lose:'Valo will be remembered for the smoke.'},
 h_tempest:{win:'Her crew surrenders one by one. None of them will say where the Eye is.',lose:'The hideout is empty by the time the Republic arrives.'},
 h_husks:{win:'The Council reads the logs and orders them sealed.',lose:'Three more Jedi gray and crumble in the dark.'},
 h_beacon:{win:'The beacon still burns over the frontier. Some nights it is the only light.',lose:'The sea of Eiram glows for a week.'}});
Object.assign(MISSIONS.h_hetzal,{quote:'“We are all the Republic.” — Chancellor Lina Soh'});   // C, Med (her rallying phrase; wording recalled)
Object.assign(MISSIONS.h_grove,{quote:'“It is a garden. It is hungry.” — Master Stellan Gios [N]'});
Object.assign(MISSIONS.h_valo,{quote:'“Light and life. Today we show them both.” — Chancellor Lina Soh [N]'});
Object.assign(MISSIONS.h_tempest,{quote:'“A Tempest Runner does not run.” — overheard, Nihil channel [N]'});
Object.assign(MISSIONS.h_husks,{quote:'“Something out there eats the Force. Find out what.” — Grand Master Pra-Tre Veter [N]'});
Object.assign(MISSIONS.h_beacon,{quote:'“For light and life.” — Jedi of the High Republic (C, High)'});

// Codex lore, merged into CODEX. ≤280 chars, spec C §9 voice. Canon unless tagged [N].
const ERA3_LORE={
 enemy:{nihil_raider:{lore:'Masked marauders who strike from hyperspace and are gone before help arrives. They share loot by Tempest, Storm and Cloud. (C, High)'},
  nihil_storm:{lore:'A Storm commands a band of Nihil Clouds. Their gas masks are half armor, half warning. (C, High; gas grenade [N])'},
  path_runner:{lore:'The Nihil fly secret hyperspace Paths no one else can compute. That is how they appear behind you. (Paths: C, High)'},
  drengir:{lore:'Sentient carnivorous plants, one hive mind, very old and very hungry. They call their prey "meat". (C, High)'},
  nameless:{lore:'Creatures that feed on the Force. Near one, a Jedi feels terror and loses the Force; what is left turns gray and crumbles. Troops feel nothing. (C, High)'},
  great_progenitor:{lore:'The oldest Drengir, root of the hive. Every Drengir hears her. (C, High)'},
  lourna_dee:{lore:'A Twi\'lek Tempest Runner of the Nihil, ruthless even by Nihil standards. (C, High; her fight here [N])'},
  lourna_ret:{lore:'Lourna Dee, back for the Eye. She never forgets a face. [N]'},
  marchion_ro:{lore:'The Eye of the Nihil, an Evereni who hides his true aim behind a helmet. He wants the Jedi broken, not dead. (C, High)'},
  leveler:{lore:'The Nameless that Marchion Ro keeps on a leash. Jedi called it the Leveler. (C, High)'},
  root_mother:{lore:'A Drengir bloom left to grow becomes a nursery. [N]'}},
 character:{veter:{lore:'Pra-Tre Veter, a Grand Master of the Order in this age. Patient, careful, thinking of the Order\'s nerve more than its glory. (C, Med)'},
  gios:{lore:'Stellan Gios, a Jedi Master who joins the High Council around 231 BBY. The face of the Order on the frontier. (C, High; seat date Med)'},
  kriss:{lore:'Avar Kriss, Jedi Master, hero of Hetzal and Marshal of Starlight Beacon. She hears the Force as a song. (C, High)'},
  soh:{lore:'Lina Soh, Chancellor of the Republic. Starlight Beacon and the Republic Fair are her Great Works. (C, High)'},
  orla:{lore:'Orla Jareni, a Wayseeker: a Jedi who walks her own path outside the Council. Her saber is white and double-bladed. (C, High)'},
  yoda:{lore:'Yoda, born ~896 BBY, is already a Master of centuries here. (C, High on his age; his role in this era Med)'},
  grappa:{lore:'Mother Grappa, a Hutt who did business with Drengir and Jedi alike. (C, Med)'},
  ro:{lore:'Marchion Ro. In canon he survives Starlight and goes on to wall off part of the frontier. (C, High)'},
  lourna:{lore:'Lourna Dee, Tempest Runner. In canon she spends time in Republic custody under a false name. (C, Med)'}},
 mission:{h_hetzal:{lore:'232 BBY: the Legacy Run broke apart in hyperspace and its pieces emerged at lightspeed across the Hetzal system. (C, High)'},
  h_grove:{lore:'The Drengir woke on the frontier soon after the Disaster. The Jedi fought them world by world. (C, High; this grove [N])'},
  h_valo:{lore:'The Republic Fair on Valo, a showcase of Lina Soh\'s Republic, was attacked by the Nihil. (C, High; ~231 BBY, Med)'},
  h_tempest:{lore:'The Nihil were led by three Tempest Runners under the Eye. (C, High; this raid [N])'},
  h_husks:{lore:'Jedi taken by the Nameless were left as gray husks that crumbled to dust. (C, High; this outpost [N])'},
  h_beacon:{lore:'Starlight Beacon, the Republic\'s great station on the frontier, was sabotaged by the Nihil and fell ~230 BBY. (C, Med on date)'},
  h_roots:{lore:'A Drengir bloom left alone grows more Drengir. [N]'},h_salvage:{lore:'For months after the Disaster, wreckage kept emerging from hyperspace. Salvage was a war of its own. (C, Med)'},
  h_scouts:{lore:'Republic pathfinders mapped new hyperlanes after the Disaster, and the Nihil hunted them. (C, Med)'},h_cache:{lore:'Path engines let the Nihil compute jumps no one else could. (C, High; this cache [N])'},
  h_prisoners:{lore:'The Nihil held Jedi prisoners to trade, break, or feed to something worse. [N]'},h_buoy:{lore:'Nihil orders moved Tempest to Storm to Cloud. [N]'},
  h_outpost:{lore:'Frontier outposts were the Republic\'s promise made of durasteel. [N]'}},
 planet:{hetzal:{lore:'A frontier system struck by the Great Hyperspace Disaster in 232 BBY. (C, High)'},
  valo:{lore:'Host of the Republic Fair, a frontier world dressed up to show the galaxy the Republic. (C, High)'},
  starlight:{lore:'Starlight Beacon: a station built to light the frontier for ships and the Jedi. (C, High)'},
  wildspace:{lore:'The dark between charted lanes. The Nihil call it home. (C, Med)'}}};
if(typeof CODEX!=='undefined')for(const [k,v] of Object.entries(ERA3_LORE)){CODEX[k]=CODEX[k]||{};for(const [id,o] of Object.entries(v))if(!CODEX[k][id])CODEX[k][id]=o}
for(const id of ['h_salvage','h_roots'])MISSION_LORE[id]=['hetzal'];for(const id of ['h_outpost','h_scouts'])MISSION_LORE[id]=['valo'];
for(const id of ['h_cache','h_husks','h_prisoners','h_buoy'])MISSION_LORE[id]=['wildspace'];
Object.assign(MISSION_LORE,{h_hetzal:['hetzal',['kriss','soh']],h_grove:['wildspace',['gios']],h_valo:['valo',['soh','gios']],h_tempest:['wildspace',['lourna']],h_beacon:['starlight',['ro','kriss']]});
Object.assign(EVENT_LORE,{e3_light_life:['soh','veter','gios'],e3_orla:['orla'],e3_grappa:['grappa'],e3_yoda:['yoda'],e3_ro_name:['ro','veter','gios'],e3_hole:['veter']});

/* Era 2 data: Ruusan (~1,003–1,000 BBY). Spec: docs/specs/story.md §2 Era 2, combat.md §3 (Ruusan roster), campaign.md §1.4 (era jump).
   Loads after data-story.js; adds to FOES, MISSIONS, CRISES, ESCORTS, EVENTS, COUNCIL_SEATS, STORY_RECRUITS, FLAG_LINES. Logic: story-era2.js.
   Lore confidence (Legends): Army of Light vs Brotherhood of Darkness on Ruusan ~1,000 BBY (High); thought bomb killed Hoth and Kaan (High);
   Bane survived and founded the Rule of Two (High); Farfalla led the Jedi after (High); Johun Othone built the Ruusan memorial (High). */
const ERA2={n:'Ruusan',bby:1003,next:'High Republic · ~232 BBY',
 shard:{t:'A second shard',text:'The sealed vision stirs again. One Sith walks out of a storm of darkness alone. A voice says: always two. The fire on the Temple steps burns a little brighter.'},
 jump:'Twenty-six centuries pass. The Sith Empire is gone, and the Sith came back anyway. The Order is an army now: Lord Hoth\'s Army of Light against Lord Kaan\'s Brotherhood of Darkness, on a green world called Ruusan.',
 // Era jump (spec B §1.4). warChest = Army of Light funds on arrival [Default, not in spec].
 carry:{credits:.3,favorTo:50,orderDark:.5,warChest:200},
 eraMod:1};   // +1 HP to every Era 2 foe if Malgus was not stopped (spec B: +1 enemy tier per lost boss)

// Ruusan roster (spec A §3). Engine flags handled in story-era2.js: lordAura, fanatic, rage, autoOW, nexus.
Object.assign(FOES,{
 bh_trooper:{n:'Brotherhood Trooper',ic:'e_trooper',hp:5,aim:65,mob:5,dmg:[2,4],range:8,fanatic:1,lordAura:10,init:8,
  desc:'Fanatic: never surrenders. +10 aim within 4 tiles of a Sith Lord.'},
 bh_marauder:{n:'Sith Marauder',ic:'e_acolyte',hp:9,aim:75,mob:6,dmg:[4,6],range:1.5,deflect:25,guardDef:25,force:1,rage:1,noCap:1,init:14,
  desc:'Melee duelist. Rage: +1 damage each time it is hit (max +3).'},
 sith_lord:{n:'Sith Lord',ic:'e_acolyte',hp:12,aim:80,mob:5,dmg:[4,6],range:1.5,deflect:30,guardDef:30,force:1,lightning:[3,5],sithLord:1,noCap:1,init:15,
  desc:'Elite duelist with Force lightning. Brotherhood troopers near it aim better.'},
 bh_sniper:{n:'Mercenary Sniper',ic:'e_agent',hp:5,aim:75,mob:4,dmg:[4,5],range:11,autoOW:1,init:10,
  desc:'Long range. Goes on overwatch every turn it does not shoot.'},
 sith_spawn:{n:'Sith Spawn',ic:'e_horror',hp:10,aim:75,mob:5,dmg:[4,6],range:1.5,horror:1,noCap:1,init:11,
  desc:'Force horror: only hurts Jedi. Troops are immune and are the counter.'},
 nexus:{n:'Dark Nexus',ic:'darkness',hp:8,aim:0,mob:0,dmg:[0,0],range:0,armor:1,force:1,noCap:1,nexus:3,init:1,
  desc:'A wound in the Force. Does not move or attack; spawns a Sith Spawn beside it every 3 turns until destroyed.'},
 nexus_core:{n:'Heart of the Nexus',ic:'darkness',hp:14,aim:0,mob:0,dmg:[0,0],range:0,armor:1,force:1,noCap:1,nexus:3,boss:1,init:1,
  desc:'The cave\'s dark heart. Spawns a Sith Spawn every 3 turns. Destroy it to win.'},
 kaan:{n:'Lord Kaan',ic:'e_acolyte',hp:14,aim:80,mob:5,dmg:[4,6],range:1.5,deflect:30,guardDef:30,force:1,lightning:[3,5],armor:1,sithLord:1,noCap:1,boss:1,init:16,
  desc:'Dark Lord of the Brotherhood. Lightning, a hard saber, armor 1. Defeat him to break the ritual.'},
 bane:{n:'Darth Bane',ic:'e_acolyte',hp:12,aim:80,mob:5,dmg:[5,6],range:1.5,deflect:35,guardDef:35,force:1,lightning:[3,4],armor:2,sithLord:1,bane:1,init:15,
  desc:'Hidden target. Armor 2. Can be captured if stunned or beaten down. Watches from the ridge and fights only units next to him. Walks away on turn 4.'}});

// Escort VIPs for Ruusan.
Object.assign(ESCORTS,{
 johun:{n:'Johun Othone (wounded)',cls:'VIP',ic:'vip',hp:6,aim:60,mob:3,dmg:[2,3],range:1.5,init:6,abil:['stabilize','door']},
 courier:{n:'Courier Ryl Danu',cls:'VIP',ic:'vip',hp:6,aim:55,mob:4,dmg:[1,2],range:6,init:6,abil:['stabilize','door']}});

// Reskin an Era 1 mission for Ruusan: mirrored layout, foe types swapped, Era 1 alts dropped.
const RU_FOES={trooper:'bh_trooper',heavy:'bh_marauder',agent:'bh_sniper',mando:'bh_trooper',envoy:'bh_trooper'};
function ruusanOf(id,extra){const M=mirrorMission(MISSIONS[id],{alts:[],era:2,...extra});
 if(!extra.foes&&M.foes)M.foes=M.foes.map(([t,x,y])=>[RU_FOES[t]||t,x,y]);if(!extra.reinforce&&M.reinforce)M.reinforce=M.reinforce.map(t=>RU_FOES[t]||t);return M}

Object.assign(MISSIONS,{
 // S1 (spec C): Rescue → built as escort: walk the wounded Knight to the evac.
 r_ravine:{n:'Ravine of the Wounded',where:'Field hospital ravine · Ruusan',type:'escort',story:1,era:2,theme:'plains',par:6,vip:'johun',
  map:["EE...c..EE","E..c...c.E","..h....h..",".c..B..x..","....rr....","#..c..c..#","..x....c..",".h..BB..h.","..........",".c.r..r.c.","..........","..c.cc.c.."],
  hostage:[4,10],foes:[['bh_trooper',1,2],['bh_trooper',8,3],['bh_marauder',5,5],['bh_sniper',6,1],['bh_trooper',3,6]],reinforce:['bh_trooper','bh_trooper'],
  start:[[2,10],[3,10],[5,10],[6,10],[0,9],[7,10]],
  brief:'A Brotherhood sweep is coming down the ravine. Lord Hoth\'s wounded are still in it, and one of them is his young Knight, Johun Othone. Walk him to the evac at the north end.',
  goal:'Walk Johun to an evac zone (E). Threat rises after turn 6: more troopers arrive and they shoot the wounded on sight.',
  win:'The wounded are out. Johun Othone asks to join your strike teams.',lose:'The ravine falls silent.',
  reward:{credits:70,recruits:1},bonus:{favor:4},bonusTxt:'Done by turn 6'},
 // S2: investigate the caves. All 3 tablets = you also spot a lone Sith leaving (Bane).
 r_caves:{n:"Kaan's Caves",where:'Cave network · Ruusan',type:'investigate',story:1,era:2,theme:'caves',par:6,
  map:["###....q##","#..#..#..#","#.q....c.#","##..##..##","#...q....#","#.x.#..c.#","##..#.r.##","#.c....c.#","#..h..h..#","##.....###","#.c.rr.c.#","EE......EE"],
  foes:[['bh_trooper',1,2],['bh_trooper',8,2],['bh_marauder',5,4],['bh_sniper',5,0],['sith_spawn',3,6]],reinforce:['bh_trooper','bh_trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[3,10],[6,10]],
  brief:'A prisoner says the Brotherhood is gathering in the caves. Copy the ritual tablets (Jedi or Medic, adjacent), then get anyone to an evac zone. Something in the dark only hunts Jedi.',
  goal:'Scan 2 of 3 tablets, then reach an evac zone. All 3 reveals more. Threat rises after turn 6: tablets get smashed. The Sith Spawn only hurts Jedi.',
  win:'The tablets are out. The Council reads them twice.',lose:'The caves collapse behind you. Whatever Kaan plans stays secret.',
  reward:{credits:60,intel:2},bonus:{intel:1},bonusTxt:'All 3 tablets'},
 // S3 boss: The Thought Bomb. Assault: defeat Kaan before Threat 6. Bane appears only with flag e2_bane_seen.
 r_bomb:{n:'The Thought Bomb',where:'Kaan\'s ritual ground · Ruusan',type:'assault',story:1,era:2,theme:'plains',bossKey:'kaan',
  get par(){return 6+(typeof C!=='undefined'&&C&&C.flags.e2_bomb_known?2:0)},
  map:["..c.##.c..",".c..##..c.","....##....",".x..c..x..","..r....r..",".c.B..B.c.","..........","..h.cc.h..",".c......c.","...r..r...",".c..cc..c.",".........."],
  get foes(){const f=[['kaan',6,2],['bh_marauder',3,3],['bh_trooper',1,4],['bh_trooper',8,4]];
   if(typeof C!=='undefined'&&C&&C.flags.e2_bane_seen)f.push(['bane',9,1]);return f},
  reinforce:['bh_trooper','bh_marauder'],start:[[3,11],[4,11],[5,11],[6,11],[1,11],[8,11]],
  brief:'Kaan has gathered his Lords to unleash a thought bomb, a ritual that could wipe out Jedi and Sith alike. Lord Hoth is walking into the caves to stop him. Break the ritual first: defeat Kaan.',
  goal:'Defeat Lord Kaan before Threat 6, when the bomb fires. If Darth Bane is here: kill or capture him BEFORE Kaan falls, or he walks away. He watches from the ridge and walks away on turn 4.',
  win:'Kaan falls. The ritual breaks before it begins. Lord Hoth walks out of the caves alive.',lose:'The thought bomb fires. Hoth and Kaan are gone in the same breath.',
  reward:{credits:120,kyber:1},bonus:{favor:5},bonusTxt:'Done by the par turn'},
 // Crises
 r_hospital:ruusanOf('shrine',{n:'The Field Hospital',where:'Army of Light field hospital · Ruusan',theme:'plains',objName:'Hospital',
  waves:{1:['bh_trooper','bh_trooper'],2:['bh_marauder','bh_trooper'],4:['bh_trooper','sith_lord']},
  brief:'Brotherhood raiders are coming for an Army of Light field hospital. Hold it for 6 turns while the healers move the wounded.',
  goal:'Hold the hospital for 6 turns. A Sith Lord leads the last wave; troopers near him aim better.',
  win:'The healers get everyone out.',lose:'The hospital burns.',reward:{credits:60,recruits:1},bonus:{favor:3},bonusTxt:'Hospital above 75%'}),
 r_nexus:{n:'The Spawn Pit',where:'Dark-side cave · Ruusan',type:'assault',era:2,theme:'caves',par:7,bossKey:'nexus_core',
  map:["##..##..##","#..c..c..#","#.r....r.#","##.#..#.##","#........#","#.c.##.c.#","#...#....#","##.r..r.##","#.c....c.#","#..h..h..#","#........#","##......##"],
  foes:[['nexus_core',5,1],['sith_spawn',4,2],['bh_marauder',5,4],['bh_trooper',2,4],['bh_trooper',7,4],['bh_sniper',8,1]],reinforce:['bh_trooper','bh_trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  brief:'A dark-side nexus is breeding Sith Spawn in the caves. Spawn only hurt Jedi. Send troops in front and destroy the nexus heart.',
  goal:'Destroy the Heart of the Nexus (14 HP, armor 1). It spawns a Sith Spawn every 3 turns. Threat rises after turn 7; at Threat 6 it erupts.',
  win:'The nexus goes dark. The cave is only a cave again.',lose:'The nexus erupts. Spawn pour into the hills.',
  reward:{credits:50,kyber:1},bonus:{intel:1},bonusTxt:'Done by turn 7'},
 r_snipers:ruusanOf('escort',{n:'Run the Gauntlet',where:'Ridge trail · Ruusan',theme:'plains',vip:'courier',
  brief:'Lord Farfalla\'s courier carries the Army\'s battle plans. Mercenary snipers hold the ridge. Get the courier to the shuttle.',
  win:'The plans reach Farfalla.',lose:'The plans are lost on the ridge.',reward:{credits:70,favor:4},bonus:{recruits:1},bonusTxt:'Done by turn 6'}),
 r_dump:ruusanOf('sabotage',{n:'The Munitions Dump',where:'Brotherhood munitions dump · Ruusan',theme:'plains',
  brief:'Kaan\'s army runs on this dump. Plant charges on 2 sites (anyone, adjacent, 1 action), then get every standing squad member onto the evac zone.',
  win:'The dump goes up behind you. The Brotherhood fights hungry for a month.',lose:'The dump holds.',reward:{credits:80,favor:3},bonus:{credits:40},bonusTxt:'Done by turn 7'})});

Object.assign(CRISES,{
 r_hospital:{n:'Raid on the field hospital',kind:'Defend',src:'Army of Light',mission:'r_hospital',text:'Brotherhood raiders are closing on a hospital full of wounded Jedi.',ignore:{recruits:-1,orderDark:4}},
 r_nexus:{n:'The spawn pit',kind:'Assault',src:'Jedi',mission:'r_nexus',text:'Scouts found a cave where the dark side is breeding horrors. Only troops can stand near them.',ignore:{orderDark:4}},
 r_snipers:{n:'Courier on the ridge',kind:'Escort',src:'Army of Light',mission:'r_snipers',text:'Farfalla\'s courier is pinned under sniper fire with the Army\'s plans.',ignore:{favor:-5}},
 r_dump:{n:'Brotherhood munitions dump',kind:'Sabotage',src:'Army of Light',mission:'r_dump',text:'Blow the dump that feeds Kaan\'s army.',ignore:{favor:-5}}});

// Era 2 mission plan (swapped in for PLAN by story-era2.js): S1 → crisis → S2 → crisis → boss.
const PLAN2=[{story:'r_ravine'},{crises:['r_hospital','r_nexus']},{story:'r_caves'},{crises:['r_snipers','r_dump']},{story:'r_bomb'}];

// Fresh Era 2 squad. Everyone from Era 1 is a Legend or forgotten by now.
const ERA2_ROSTER=[
 {n:'Lord Ressa Vaun',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['leap'],col:'#ffd166',age:31},
 {n:'Kell Darrow',cls:'Consular',title:'Padawan',col:'#8fe3ff',age:17},
 {n:'Sgt. Bo Hallan',cls:'Soldier',age:36},{n:'Mira Tesk',cls:'Scout',age:24},{n:'Doc Ilo Venn',cls:'Medic',age:41},{n:'Rusk Abernath',cls:'Heavy',age:29}];

// Council cameos (spec C §6).
Object.assign(COUNCIL_SEATS,{hoth:{n:'Lord Hoth',loyalty:60},farfalla:{n:'Lord Valenthyne Farfalla',loyalty:60}});
// Rare recruits. Johun Othone: Hoth's Padawan, later Knight (Legends, High on role; age invented).
Object.assign(STORY_RECRUITS,{
 johun:{n:'Johun Othone',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['reflectM'],col:'#7fd99a',age:22},
 redeemed_apprentice:{n:'Tarn Vel',cls:'Consular',title:'Padawan',rank:1,xp:0,picks:[],col:'#c9b6ff',age:19,dark:4}});

// Era 2 events (spec C §3). trigger.era:2 keeps them out of Era 1. Order Darkness ×4, loyalty ×10 (0–100 scales).
EVENTS.push(
 {id:'e2_lord_titles',trigger:{type:'era_start',era:2},text:'Army of Light Jedi call themselves Lords and give orders like generals. Some Masters hate it.',
  choices:[{label:'Keep the titles',effects:{recruits:2,orderDark:4}},{label:'Drop them',effects:{loyalty:{seat:'hoth',n:-10},orderDark:-4}}]},
 {id:'e2_deserter',trigger:{type:'month',min:1,era:2},text:'A Brotherhood apprentice walks into camp, unarmed, asking for mercy.',
  choices:[{label:'Accept him',effects:{recruit:'redeemed_apprentice',chance:.7,fail:{wound:{who:'squad_leader',turns:2}}}},{label:'Imprison him',effects:{intel:2}},{label:'Turn him away',effects:{}}]},
 {id:'e2_child_soldiers',trigger:{type:'after_mission',min:2,era:2},text:'Villages are sending their teenagers to fight for the Army of Light. You need the numbers.',
  choices:[{label:'Send them home',effects:{recruits:-1,favor:1}},{label:'Rear duties only',effects:{recruits:1}}]},
 {id:'e2_cave_whispers',trigger:{type:'flag',flag:'e2_caves_done',era:2},text:'A Jedi back from the caves can\'t stop hearing a voice. It promises strength.',
  choices:[{label:'Halls of Healing',effects:{wound:{who:'jedi_highestDark',turns:2},unitDark:{who:'jedi_highestDark',n:-2}}},{label:'Listen to it',effects:{unitDark:{who:'jedi_highestDark',n:2},intel:2}}]},
 {id:'e2_farfalla',trigger:{type:'month',min:2,era:2},text:'Lord Farfalla wants to pull the army back to save lives. Lord Hoth wants one last push.',
  choices:[{label:'Back Hoth',effects:{loyalty:{seat:'hoth',n:10},loyalty_2:{seat:'farfalla',n:-10},flag:'e2_push'}},{label:'Back Farfalla',effects:{loyalty:{seat:'farfalla',n:10},recruits:1}}]},
 {id:'e2_bane_rumor',trigger:{type:'flag',flag:'e2_bane_seen',era:2},text:'Scouts saw a Sith walk away from Kaan\'s camp before the end. Nobody else cares.',
  choices:[{label:'Assign trackers',effects:{intel:-1,flag:'e2_bane_tracked'}},{label:'Focus on Kaan',effects:{}}]});

// Bane outcome → Vision (spec C §1): dead −3 · captured −2 · escapes +1. Tracked: his escape is noted but still +1.
const BANE={leaves:4,dead:{shadow:-3,flag:'e2_bane_dead',line:'Darth Bane died on Ruusan. No one is left to teach the Rule of Two.'},
 captured:{shadow:-2,flag:'e2_bane_captured',line:'Darth Bane sits in a Jedi cell. The Sith line has no teacher.'},
 escaped:{shadow:1,flag:'e2_bane_escaped',line:'One Sith walked away from Ruusan. Always two, he says.'}};
const STORY_TEXT2={
 bossWin:'Kaan fell before the ritual. Lord Hoth lives, and takes a Council seat.',
 bossLose:'The thought bomb fired. Hoth is gone; the Army of Light buries its Lords.',
 eraWin:'The Brotherhood is broken. The Order begins to put down its Lord titles.',
 eraLose:'Ruusan is a graveyard. The Order rebuilds, quieter and more afraid.',
 darkWarn:'The Order is drifting. The Army of Light liked being an army.'};
Object.assign(FLAG_LINES,{e2_bomb_known:'You read the ritual tablets: you knew about the thought bomb.',e2_bane_seen:'Your scouts saw a lone Sith walk away from the caves.',
 e2_hoth_lives:'Lord Hoth survived Ruusan. In canon he died in the thought bomb.',e2_bomb_fired:'The thought bomb fired, as it did in canon.',
 e2_bane_dead:BANE.dead.line,e2_bane_captured:BANE.captured.line,e2_bane_escaped:BANE.escaped.line,e2_bane_tracked:'Trackers followed the lone Sith into the hills.'});

// Codex lore (merged into CODEX when L's data-codex.js is loaded). ≤280 chars, spec C §9 voice. Legends unless noted.
const ERA2_LORE={
 enemy:{bh_trooper:{lore:'Kaan\'s foot soldiers. They believe their Lords will make them more than human. Most die believing it.'},
  bh_marauder:{lore:'Sith who gave up everything but the fight. Every wound makes them hit harder.'},
  sith_lord:{lore:'The Brotherhood made everyone with a red blade a Lord. Kaan said it made them equal. It made them many.'},
  bh_sniper:{lore:'Hired guns from the Outer Rim. They don\'t care who wins Ruusan as long as someone pays.'},
  sith_spawn:{lore:'Dark-side things that crawl out where the Force is wounded. Blasters bother them. Jedi feed them.'},
  nexus:{lore:'A place where too much hate soaked into the ground. The Force sours around it.'},
  nexus_core:{lore:'The oldest, deepest wound in the caves. Destroy it and the Spawn stop coming.'},
  kaan:{lore:'Skere Kaan, Dark Lord of the Brotherhood. Charismatic, reckless, and out of options. (Legends, High)'},
  bane:{lore:'A Sith who thinks Kaan\'s army is a mistake. He may be planning to let it die. (Legends, High)'}},
 character:{hoth:{lore:'Lord Hoth leads the Army of Light. A blunt soldier who never wanted to be one. (Legends, High)'},
  farfalla:{lore:'Valenthyne Farfalla, a Lord of the Army of Light. Flamboyant, and the one who leads the Jedi after Ruusan. (Legends, High)'},
  johun:{lore:'Johun Othone, Hoth\'s student. In canon he builds the Ruusan memorial. (Legends, High)'}},
 mission:{r_ravine:{lore:'Ruusan\'s ravines filled with the wounded of seven battles.'},r_caves:{lore:'Kaan\'s Lords met in the caves to plan their last move.'},
  r_bomb:{lore:'The thought bomb: a ritual that drew in every Force user nearby and did not let go. (Legends, High)'}},
 planet:{ruusan:{lore:'A green Mid Rim world that hosted seven battles between the Army of Light and the Brotherhood of Darkness. (Legends, High)'}}};

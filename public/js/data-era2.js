/* Era 2 data: Ruusan (~1,006–1,000 BBY), 12 missions in 3 Acts. Spec: docs/specs/story.md §2 Era 2, combat.md §3 (Ruusan roster), campaign.md §1.4 (era jump).
   Loads after data-story.js and data-codex.js; adds to FOES, MISSIONS, CRISES, ESCORTS, EVENTS, COUNCIL_SEATS, STORY_RECRUITS, FLAG_LINES, EPI, CODEX. Logic: story-era2.js.
   Lore confidence (Legends): Army of Light vs Brotherhood of Darkness, seven battles of Ruusan, ending ~1,000 BBY (High); Brotherhood founded ~1,006 BBY (Med);
   thought bomb killed Hoth and Kaan (High); Bane survived and founded the Rule of Two (High); Farfalla led the Jedi after (High);
   Johun Othone was Hoth's student and built the Ruusan memorial (High). [N] = our invention. */
const ERA2={n:'Ruusan',bby:1006,next:'High Republic · ~232 BBY',
 shard:{t:'A second shard',text:'The sealed vision stirs again. One Sith walks out of a storm of light alone. A voice says: always two. The fire on the Temple steps burns a little brighter.'},
 jump:'Twenty-six centuries pass. The Sith Empire is gone, and the Sith came back anyway. The Order is an army now: Lord Hoth\'s Army of Light against Lord Kaan\'s Brotherhood of Darkness. The war is drifting toward a green world called Ruusan.',
 // Era jump (spec B §1.4). warChest = Army of Light funds on arrival [Default, not in spec].
 carry:{credits:.3,favorTo:50,orderDark:.5,warChest:200},
 eraMod:1};   // +1 HP to every Era 2 foe if Malgus was not stopped (spec B: +1 enemy tier per lost boss)
// Years pass text and Act shards for Era 2 (swapped into ACTS/SHARDS while Era 2 runs).
const ACTS2={2:{t:'Years pass',text:'Three years of war. The Army of Light and the Brotherhood trade worlds and bodies. Both sides start calling Ruusan the place it ends.'},
 3:{t:'The last battles',text:'Three more years. Six battles on Ruusan and nobody has won. Kaan is losing, and losing men do desperate things.'}};
const SHARDS2={2:'The vision returns: a cave mouth full of light, and Jedi and Sith walking into it together.',
 3:'The vision is clear now: one Sith walking away from a storm of light. Behind him, nobody is left to follow.'};

// Ruusan roster (spec A §3). Engine flags (Chat X: rules.js/ai.js): lordAura, fanatic, rage, autoOW, nexus, bane.
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
 vorr:{n:'Lord Vorr',ic:'e_acolyte',hp:12,aim:80,mob:5,dmg:[4,6],range:1.5,deflect:30,guardDef:30,force:1,lightning:[3,4],armor:1,sithLord:1,noCap:1,boss:1,init:15,
  desc:'Kaan\'s field commander. Lightning and a hard saber, armor 1. Defeat him to break the line.'},  // [N]
 kaan:{n:'Lord Kaan',ic:'e_acolyte',hp:14,aim:80,mob:5,dmg:[4,6],range:1.5,deflect:30,guardDef:30,force:1,lightning:[3,5],armor:1,sithLord:1,noCap:1,boss:1,init:16,
  desc:'Dark Lord of the Brotherhood. Lightning, a hard saber, armor 1. Defeat him to break the ritual.'},
 bane:{n:'Darth Bane',ic:'e_acolyte',hp:12,aim:80,mob:5,dmg:[5,6],range:1.5,deflect:35,guardDef:35,force:1,lightning:[3,4],armor:2,sithLord:1,bane:1,init:15,
  desc:'Hidden target. Armor 2. Can be captured if stunned or beaten down. Watches from the ridge and fights only units next to him. Walks away on turn 4.'}});

// Escort VIPs for Ruusan.
Object.assign(ESCORTS,{
 johun:{n:'Johun Othone (wounded)',cls:'VIP',ic:'vip',hp:6,aim:60,mob:3,dmg:[2,3],range:1.5,init:6,abil:['stabilize','door']},
 courier:{n:'Courier Ryl Danu',cls:'VIP',ic:'vip',hp:6,aim:55,mob:4,dmg:[1,2],range:6,init:6,abil:['stabilize','door']}});

// Reskin an Era 1 mission (or one of its alt layouts) for Ruusan: mirrored layout (flip:false keeps it as is), foe types swapped, pods and patrol routes kept, Era 1 alts dropped.
const RU_FOES={trooper:'bh_trooper',heavy:'bh_marauder',agent:'bh_sniper',mando:'bh_trooper',envoy:'bh_trooper',acolyte:'bh_marauder',terentatek:'sith_spawn'};
function ruusanOf(id,x,alt){const B=alt!=null?{...MISSIONS[id],...MISSIONS[id].alts[alt]}:MISSIONS[id],f=t=>RU_FOES[t]||t,o={alts:[],era:2,quote:undefined,...x},fl=x.flip===false?X=>X:X=>W-1-X;
 const M=x.flip===false?{...B,story:0,...o}:mirrorMission(B,o);
 if(!x.foes&&B.foes)M.foes=B.foes.map(([t,X,Y,...r])=>[f(t),fl(X),Y,...r]);
 if(!x.reinforce&&B.reinforce)M.reinforce=B.reinforce.map(f);
 if(!x.waves&&B.waves){M.waves={};for(const k in B.waves)M.waves[k]=B.waves[k].map(f)}
 if(!x.patrol&&B.patrol){M.patrol={};for(const k in B.patrol)M.patrol[k]=B.patrol[k].map(([X,Y])=>[fl(X),Y])}
 return M}

Object.assign(MISSIONS,{
 // ── Act I (~1,006 BBY) ──
 r_muster:{n:'The Muster',where:'Army of Light landing field · Ruusan',type:'defend',story:1,era:2,theme:'plains',turns:7,obj:20,objName:'Landing beacon',lastWave:5,
  map:["..........","..c....c..",".x..##..c.","....^^....",".c......c.","##.c..c.##","....^^....",".h......h.","..c.cc.c..","^........^","...cOOc...",".........."],
  waves:{1:['bh_trooper','bh_trooper','bh_trooper'],3:['bh_trooper','bh_marauder','bh_sniper'],5:['sith_lord','bh_marauder','bh_trooper']},
  start:[[3,9],[6,9],[2,9],[7,9],[4,11],[5,11]],
  brief:'Lord Hoth is landing his army on Ruusan, and the Brotherhood knows it. Hold the landing beacon for 7 turns so the transports can find the field.',
  goal:'Hold the landing beacon for 7 turns. A Sith Lord leads the last wave; troopers near him aim better.',
  win:'The transports come down. The Army of Light is on Ruusan.',lose:'The beacon goes dark. Half the transports scatter.',
  reward:{credits:80},bonus:{credits:30},bonusTxt:'Beacon above 75%'},
 r_ravine:{n:'Ravine of the Wounded',where:'Field hospital ravine · Ruusan',type:'escort',story:1,era:2,theme:'plains',par:6,vip:'johun',
  map:["EE...c..EE","E..c...c.E","..h....h..",".c..B..x..","....rr....","#..c..c..#","..x....c..",".h..BB..h.","..........",".c.r..r.c.","..........","..c.cc.c.."],
  hostage:[4,10],foes:[['bh_trooper',1,2],['bh_trooper',8,3],['bh_marauder',5,5],['bh_sniper',6,1],['bh_trooper',3,6]],reinforce:['bh_trooper','bh_trooper'],
  start:[[2,10],[3,10],[5,10],[6,10],[0,9],[7,10]],
  brief:'A Brotherhood sweep is coming down the ravine. Lord Hoth\'s wounded are still in it, and one of them is his student, Johun Othone. Walk him to the evac at the north end.',
  goal:'Walk Johun to an evac zone (E). Threat rises after turn 6: more troopers arrive and they shoot the wounded on sight.',
  win:'The wounded are out. Hoth will remember who saved his student.',lose:'The ravine falls silent.',
  reward:{credits:70,recruits:1},bonus:{favor:4},bonusTxt:'Done by turn 6'},
 // ── Act II (~1,003 BBY) ──
 r_caves:{n:"Kaan's Caves",where:'Cave network · Ruusan',type:'investigate',story:1,era:2,theme:'caves',par:6,
  map:["###....q##","#..#..#..#","#.q....c.#","##..##..##","#...q....#","#.x.#..c.#","##..#.r.##","#.c....c.#","#..h..h..#","##.....###","#.c.rr.c.#","EE......EE"],
  foes:[['bh_trooper',1,2],['bh_trooper',8,2],['bh_marauder',5,4],['bh_sniper',5,0],['sith_spawn',3,6]],reinforce:['bh_trooper','bh_trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[3,10],[6,10]],
  brief:'A prisoner says the Brotherhood is gathering in the caves. Copy the ritual tablets (Jedi or Medic, adjacent), then get anyone to an evac zone. Something in the dark only hunts Jedi.',
  goal:'Scan 2 of 3 tablets, then reach an evac zone. All 3 reveals more. Threat rises after turn 6: tablets get smashed. The Sith Spawn only hurts Jedi.',
  win:'The tablets are out. The Council reads them twice.',lose:'The caves collapse behind you. Whatever Kaan plans stays secret.',
  reward:{credits:60,intel:2},bonus:{intel:1},bonusTxt:'All 3 tablets'},
 r_sixth:{n:'The Sixth Battle',where:'Brotherhood stockade · Ruusan',type:'rescue',story:1,era:2,theme:'plains',par:5,hostN:'Lord Tarsus Vell',
  map:[".c..^^..c.","...#..#...",".k.#..#.x.","...##D#...",".c......c.","..^....^..","#..c..c..#",".h..##..h.","..........",".c..cc..c.","....^^....","EE......EE"],
  hostage:[5,2],foes:[['bh_trooper',2,4],['bh_trooper',7,4],['bh_marauder',4,5],['bh_sniper',7,0],['bh_trooper',6,8]],reinforce:['bh_trooper','bh_trooper'],
  start:[[3,11],[4,11],[5,11],[6,11],[2,10],[7,10]],
  brief:'The sixth battle went badly. Kaan\'s men dragged an Army of Light Lord, Tarsus Vell, into a stockade. A Medic can Hack the cell door from 4 tiles; a Jedi can try the console. Then get him to an evac zone (E).',
  goal:'Open the cell (Hack or console), then get the prisoner to an evac zone. Threat rises after turn 5; at Threat 6 they march him to Kaan.',
  win:'Lord Vell is out. He owes the Temple his life.',lose:'Lord Vell is gone. Kaan will make an example of him.',
  reward:{credits:90,favor:5},bonus:{recruits:1},bonusTxt:'Done by turn 5'},
 // ── Act III (~1,000 BBY) ──
 r_seventh:{n:'The Seventh Battle',where:'Kaan\'s line · Ruusan',type:'assault',story:1,era:2,theme:'plains',par:6,bossKey:'vorr',
  push:'Lord Vorr\'s line is holding.',near:'The line is about to hold for good. Next turn the attack fails.',escape:'The Army of Light falls back.',
  map:["..c.^^.c..",".c..MM..c.","....^^....",".x.B..B.x.","..........","#.c.cc.c.#","....rr....",".h......h.","...c..c...",".B......B.","..c.^^.c..",".........."],
  foes:[['vorr',4,1],['bh_marauder',2,2],['bh_trooper',1,4],['bh_trooper',8,4],['bh_sniper',5,0]],reinforce:['bh_trooper','bh_marauder'],
  start:[[3,11],[4,11],[5,11],[6,11],[1,11],[8,11]],
  brief:'The seventh battle of Ruusan. Lord Vorr holds the high ground over Kaan\'s line. Break him and the Army of Light can push through.',
  goal:'Defeat Lord Vorr on the high ledge. Threat rises after turn 6; at Threat 6 the attack fails. Barrels (x) explode when shot.',
  win:'Vorr falls. Kaan\'s line breaks and his army runs for the caves.',lose:'The line holds. The Army of Light counts its dead.',
  reward:{credits:100,kyber:1},bonus:{favor:4},bonusTxt:'Done by turn 6'},
 // S3 boss: The Thought Bomb. Assault: defeat Kaan before Threat 6. Bane is there if you saw him (caves, all 3 tablets) or tracked him.
 r_bomb:{n:'The Thought Bomb',where:'Kaan\'s ritual ground · Ruusan',type:'assault',story:1,era:2,theme:'plains',bossKey:'kaan',
  push:'Kaan\'s Lords chant louder.',near:'The ritual is almost complete. Next turn it fires.',escape:'The thought bomb fires.',
  get par(){const f=typeof C!=='undefined'&&C?C.flags:{};return 6+(f.e2_bomb_known?2:0)+(f.e2_hoth_goes?1:0)},
  map:["..c.##.c..",".c..##..c.","....##....",".x..c..x..","..r....r..",".c.B..B.c.","..........","..h.cc.h..",".c......c.","...r..r...",".c..cc..c.",".........."],
  get foes(){const f=[['kaan',6,2],['bh_marauder',3,3],['bh_trooper',1,4],['bh_trooper',8,4]],F=typeof C!=='undefined'&&C?C.flags:{};
   if(F.e2_bane_seen||F.e2_bane_tracked)f.push(['bane',9,1]);return f},
  reinforce:['bh_trooper','bh_marauder'],start:[[3,11],[4,11],[5,11],[6,11],[1,11],[8,11]],
  brief:'Kaan has gathered his Lords to unleash a thought bomb, a ritual that could wipe out Jedi and Sith alike. Lord Hoth is walking into the caves to stop him. Break the ritual first: defeat Kaan.',
  goal:'Defeat Lord Kaan before Threat 6, when the bomb fires. If Darth Bane is here: kill or capture him BEFORE Kaan falls, or he walks away on turn 4.',
  win:'Kaan falls. The ritual breaks before it begins.',lose:'The thought bomb fires.',
  reward:{credits:120,kyber:1},bonus:{favor:5},bonusTxt:'Done by the par turn'},
 // ── Crises ──
 r_hospital:ruusanOf('shrine',{n:'The Field Hospital',where:'Army of Light field hospital · Ruusan',theme:'plains',objName:'Hospital',
  waves:{1:['bh_trooper','bh_trooper','bh_trooper'],2:['bh_marauder','bh_trooper'],4:['bh_trooper','sith_lord']},
  brief:'Brotherhood raiders are coming for an Army of Light field hospital. Hold it for 6 turns while the healers move the wounded.',
  goal:'Hold the hospital for 6 turns. A Sith Lord leads the last wave; troopers near him aim better.',
  win:'The healers get everyone out.',lose:'The hospital burns.',reward:{credits:60,recruits:1},bonus:{favor:3},bonusTxt:'Hospital above 75%'}),
 r_nexus:{n:'The Spawn Pit',where:'Dark-side cave · Ruusan',type:'assault',era:2,theme:'caves',par:7,bossKey:'nexus_core',
  push:'The nexus pulses.',near:'The nexus is about to erupt.',escape:'The nexus erupts.',
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
  foes:[['bh_trooper',7,2,1],['bh_trooper',2,2,1],['bh_marauder',5,1,1],['bh_trooper',3,5,2],['bh_trooper',1,8,2],['bh_sniper',0,6]],reinforce:['bh_trooper','bh_trooper'],
  brief:'Kaan\'s army runs on this dump. Plant charges on 2 sites (anyone, adjacent, 1 action), then get every standing squad member onto the evac zone.',
  win:'The dump goes up behind you. The Brotherhood fights hungry for a month.',lose:'The dump holds.',reward:{credits:80,favor:3},bonus:{credits:40},bonusTxt:'Done by turn 7'}),
 r_prisoners:ruusanOf('rescue',{flip:false,n:'The Prison Hulk',where:'Brotherhood prison camp · Ruusan',theme:'plains',hostN:'Healer Amma Rin',
  brief:'The Brotherhood holds Army of Light prisoners in a locked cell. A Medic can Hack the door from 4 tiles; a Jedi can try the console. Then walk the prisoner to an evac zone (E).',
  win:'The prisoner is out.',lose:'The prisoner is lost.',reward:{credits:80,favor:4},bonus:{recruits:1},bonusTxt:'Done by turn 5'}),
 r_codes:ruusanOf('archive',{n:'Brotherhood Codes',where:'Brotherhood signal camp · Ruusan',theme:'plains',
  brief:'A Brotherhood signal camp runs Kaan\'s orders to his Lords. Copy its terminals (Jedi or Medic, adjacent), then get anyone to an evac zone.',
  win:'Kaan\'s orders are ours for a month.',lose:'The camp burns its codes.',reward:{credits:60,intel:2},bonus:{intel:1},bonusTxt:'All 3 terminals'}),
 r_supply:ruusanOf('relay',{n:'The Supply Line',where:'Army of Light supply post · Ruusan',theme:'plains',objName:'Supply post',
  brief:'Brotherhood raiders want the supply post that feeds Hoth\'s front. Hold it for 8 turns until the convoy rolls out.',
  waves:{1:['bh_trooper','bh_trooper'],3:['bh_trooper','bh_trooper','bh_marauder'],5:['bh_trooper','bh_trooper','bh_trooper']},
  goal:'Hold the supply post for 8 turns.',win:'The convoy rolls out. The front eats.',lose:'The supplies burn.',reward:{credits:80},bonus:{credits:30},bonusTxt:'Post above 75%'})});

// Extra guards so the reused Era 1 layouts aren't walkovers.
MISSIONS.r_prisoners.foes.push(['bh_marauder',6,6],['bh_trooper',9,8]);
MISSIONS.r_snipers.foes.push(['bh_sniper',8,0],['bh_marauder',5,4]);

// Per-map balance for Ruusan (Chat R owns these rows; they replace Chat X's earlier r_ rows in TUNE, data.js). Same format: enemy aim/HP offsets,
// extra/fewer rank-and-file foes. Target: weak test bot wins ~55–70% on Normal. Measured 16–30 bot games each on the wave-3 engine.
Object.assign(TUNE,{"r_muster:0":{aim:10},"r_ravine:0":{aim:25,hp:3,extra:1},"r_caves:0":{aim:0,hp:1},"r_sixth:0":{aim:10,extra:1},"r_seventh:0":{aim:8},
 "r_hospital:0":{aim:1},"r_dump:0":{aim:12,hp:1},"r_prisoners:0":{aim:-8},"r_codes:0":{aim:15,hp:1},"r_supply:0":{aim:-2}});

Object.assign(CRISES,{
 r_hospital:{n:'Raid on the field hospital',kind:'Defend',src:'Army of Light',mission:'r_hospital',text:'Brotherhood raiders are closing on a hospital full of wounded Jedi.',ignore:{recruits:-1,orderDark:4}},
 r_nexus:{n:'The spawn pit',kind:'Assault',src:'Jedi',mission:'r_nexus',text:'Scouts found a cave where the dark side is breeding horrors. Only troops can stand near them.',ignore:{orderDark:4}},
 r_snipers:{n:'Courier on the ridge',kind:'Escort',src:'Army of Light',mission:'r_snipers',text:'Farfalla\'s courier is pinned under sniper fire with the Army\'s plans.',ignore:{favor:-5}},
 r_dump:{n:'Brotherhood munitions dump',kind:'Sabotage',src:'Army of Light',mission:'r_dump',text:'Blow the dump that feeds Kaan\'s army.',ignore:{favor:-5}},
 r_prisoners:{n:'The prison hulk',kind:'Rescue',src:'Army of Light',mission:'r_prisoners',text:'A healer of the Army of Light is held in a Brotherhood camp.',ignore:{favor:-3,orderDark:4}},
 r_codes:{n:'Brotherhood signal camp',kind:'Investigate',src:'Jedi',mission:'r_codes',text:'A camp is relaying Kaan\'s orders. Copy them and get out.',ignore:{favor:-3}},
 r_supply:{n:'The supply line',kind:'Defend',src:'Army of Light',mission:'r_supply',text:'Raiders are closing on the post that feeds Hoth\'s front.',ignore:{favor:-5}}});

// Era 2 plan (swapped in for PLAN by story-era2.js): Act I (1,006) · Years pass +3 · Act II (1,003) · Years pass +3 · Act III (1,000, the thought bomb).
const PLAN2=[
 {story:'r_muster'},{crises:['r_hospital','r_snipers']},{story:'r_ravine'},{crises:['r_dump','r_codes']},
 {years:3,act:2},
 {crises:['r_nexus','r_prisoners']},{story:'r_caves'},{crises:['r_supply','r_snipers']},{story:'r_sixth'},
 {years:3,act:3},
 {crises:['r_dump','r_hospital','r_codes']},{story:'r_seventh'},{crises:['r_nexus','r_prisoners','r_supply']},{story:'r_bomb'}];

// Fresh Era 2 squad. Everyone from Era 1 is a Legend or forgotten by now. [N]
const ERA2_ROSTER=[
 {n:'Lord Ressa Vaun',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['saberThrow','leap'],col:'#ffd166',age:31},
 {n:'Kell Darrow',cls:'Consular',title:'Padawan',col:'#8fe3ff',age:17},
 {n:'Sgt. Bo Hallan',cls:'Soldier',age:36},{n:'Mira Tesk',cls:'Scout',age:24},{n:'Doc Ilo Venn',cls:'Medic',age:41},{n:'Rusk Abernath',cls:'Heavy',age:29}];

// Council cameos (spec C §6). Loyalty 0–100; ≥70 unlocks their favor events.
Object.assign(COUNCIL_SEATS,{hoth:{n:'Lord Hoth',loyalty:60},farfalla:{n:'Lord Valenthyne Farfalla',loyalty:60}});
// Rare recruits. Johun Othone: Hoth's student (Legends, High on role; age [N]). Only joins if you saved him AND Hoth trusts you (loyalty ≥70).
Object.assign(STORY_RECRUITS,{
 johun:{n:'Johun Othone',cls:'Guardian',title:'Knight',rank:3,xp:80,picks:['defLine','reflectM','sweep'],col:'#7fd99a',age:22},
 redeemed_apprentice:{n:'Tarn Vel',cls:'Consular',title:'Padawan',rank:1,xp:0,picks:[],col:'#c9b6ff',age:19,dark:4}});  // [N]

// Era 2 events (spec C §3). trigger.era:2 keeps them out of Era 1 (sub-triggers of `all` need it too). Extra trigger: loyal{seat,min}.
// Hoth = Guardian stance (bold, front line); Farfalla = Consular stance (mercy, saving lives). Choices name whose way they follow.
EVENTS.push(
 {id:'e2_lord_titles',trigger:{type:'era_start',era:2},text:'Army of Light Jedi call themselves Lords and give orders like generals. Some Masters hate it.',
  choices:[{label:'Hoth\'s way: keep the titles',effects:{recruits:2,orderDark:4,loyalty:{seat:'hoth',n:10}}},{label:'Farfalla\'s way: drop them',effects:{orderDark:-4,loyalty:{seat:'farfalla',n:10},loyalty_2:{seat:'hoth',n:-10}}}]},
 {id:'e2_deserter',trigger:{type:'month',min:1,era:2},text:'A Brotherhood apprentice walks into camp, unarmed, asking for mercy.',
  choices:[{label:'Accept him',effects:{recruit:'redeemed_apprentice',chance:.7,fail:{wound:{who:'squad_leader',turns:2}}}},{label:'Imprison him',effects:{intel:2}},{label:'Turn him away',effects:{}}]},
 {id:'e2_hoth_charge',trigger:{type:'after_mission',min:2,era:2},text:'Lord Hoth wants your strike teams at the front of his next charge. "A Lord leads from the front."',
  choices:[{label:'Hoth\'s way: lead the charge',effects:{favor:3,loyalty:{seat:'hoth',n:10},chance:.6,fail:{wound:{who:'squad_leader',turns:2},loyalty:{seat:'hoth',n:10}}}},
   {label:'Farfalla\'s way: scout instead',effects:{intel:2,loyalty:{seat:'farfalla',n:10},loyalty_2:{seat:'hoth',n:-10}}}]},
 {id:'e2_child_soldiers',trigger:{type:'after_mission',min:3,era:2},text:'Villages are sending their teenagers to fight for the Army of Light. You need the numbers.',
  choices:[{label:'Farfalla\'s way: send them home',effects:{recruits:-1,favor:1,loyalty:{seat:'farfalla',n:10}}},{label:'Rear duties only',effects:{recruits:1}}]},
 {id:'e2_farfalla_amnesty',trigger:{type:'act',min:2,era:2},text:'Farfalla wants to offer Brotherhood troopers amnesty if they lay down their arms. Hoth calls it a trick that will get Jedi killed.',
  choices:[{label:'Farfalla\'s way: offer amnesty',effects:{recruits:2,orderDark:-4,loyalty:{seat:'farfalla',n:10},loyalty_2:{seat:'hoth',n:-10}}},
   {label:'Hoth\'s way: no terms for Kaan\'s army',effects:{credits:40,orderDark:4,loyalty:{seat:'hoth',n:10},loyalty_2:{seat:'farfalla',n:-10}}}]},
 {id:'e2_cave_whispers',trigger:{type:'flag',flag:'e2_caves_done',era:2},text:'A Jedi back from the caves can\'t stop hearing a voice. It promises strength.',
  choices:[{label:'Halls of Healing',effects:{wound:{who:'jedi_highestDark',turns:2},unitDark:{who:'jedi_highestDark',n:-2}}},{label:'Listen to it',effects:{unitDark:{who:'jedi_highestDark',n:2},intel:2}}]},
 {id:'e2_farfalla',trigger:{type:'month',min:4,era:2},text:'Lord Farfalla wants to pull the army back to save lives. Lord Hoth wants one last push.',
  choices:[{label:'Hoth\'s way: one last push',effects:{loyalty:{seat:'hoth',n:10},loyalty_2:{seat:'farfalla',n:-10},flag:'e2_push'}},{label:'Farfalla\'s way: pull back',effects:{loyalty:{seat:'farfalla',n:10},loyalty_2:{seat:'hoth',n:-10},recruits:1}}]},
 {id:'e2_hoth_student',trigger:{type:'all',era:2,all:[{type:'flag',flag:'e2_johun_saved',era:2},{type:'loyal',seat:'hoth',min:70,era:2}]},
  text:'Hoth trusts you now. He offers you the student you pulled out of the ravine: Johun Othone, a Knight with a long memory.',
  choices:[{label:'Take Johun',effects:{recruit:'johun',flag:'johun_joined'}},{label:'He belongs at his master\'s side',effects:{loyalty:{seat:'hoth',n:10},flag:'e2_johun_hoth'}}]},
 {id:'e2_farfalla_healers',trigger:{type:'loyal',seat:'farfalla',min:70,era:2},text:'Farfalla sends his own healers to the Temple, no strings attached. "Use them where they save the most."',
  choices:[{label:'Keep them at the Temple',effects:{recruits:2}},{label:'Send them to the front',effects:{favor:4}}]},
 {id:'e2_bane_rumor',trigger:{type:'all',era:2,all:[{type:'act',min:3,era:2},{type:'notFlag',flag:'e2_bane_seen',era:2}]},text:'Scouts saw a Sith walk away from Kaan\'s camp at night. Nobody else cares.',
  choices:[{label:'Assign trackers',effects:{intel:-1,flag:'e2_bane_tracked'}},{label:'Focus on Kaan',effects:{}}]},
 {id:'e2_hoth_last',trigger:{type:'flag',flag:'e2_seventh_done',era:2},text:'If the ritual starts, Hoth will walk into Kaan\'s caves himself. Farfalla begs him not to.',
  choices:[{label:'Hoth\'s way: he goes in',effects:{flag:'e2_hoth_goes',loyalty:{seat:'hoth',n:10}}},{label:'Farfalla\'s way: he waits outside',effects:{flag:'e2_hoth_waits',loyalty:{seat:'farfalla',n:10}}}]});

// Bane outcome (spec C §1): dead −3 · captured −2 · escapes +1 Vision. Era 3 reads C.flags.e2_bane_* / rule_of_two and C.eras[1].bane.
const BANE={leaves:4,dead:{shadow:-3,flag:'e2_bane_dead',line:'Darth Bane died on Ruusan. No one is left to teach the Rule of Two.'},
 captured:{shadow:-2,flag:'e2_bane_captured',line:'Darth Bane sits in a Jedi cell. The Sith line has no teacher.'},
 escaped:{shadow:1,flag:'e2_bane_escaped',line:'One Sith walked away from Ruusan. Always two, he says.'}};
const STORY_TEXT2={
 bossWin:'Kaan fell before the ritual. Lord Hoth lives, and takes a Council seat.',
 bossLose:'The thought bomb fired. Hoth is gone; the Army of Light buries its Lords.',
 bossLoseHothOut:'The thought bomb fired. Hoth waited outside, as Farfalla asked, and lives to bury his Lords.',
 eraWin:'The Brotherhood is broken. The Order begins to put down its Lord titles.',
 eraLose:'Ruusan is a graveyard. The Order rebuilds, quieter and more afraid.',
 darkWarn:'The Order is drifting. The Army of Light liked being an army.'};
Object.assign(FLAG_LINES,{e2_bomb_known:'You read the ritual tablets: you knew about the thought bomb.',e2_bane_seen:'Your scouts saw a lone Sith walk away from the caves.',
 e2_hoth_lives:'Lord Hoth survived Ruusan. In canon he died in the thought bomb.',e2_bomb_fired:'The thought bomb fired, as it did in canon.',
 e2_bane_dead:BANE.dead.line,e2_bane_captured:BANE.captured.line,e2_bane_escaped:BANE.escaped.line,e2_bane_tracked:'Trackers followed the lone Sith into the hills.',
 e2_johun_saved:'You pulled Johun Othone out of the ravine.',johun_joined:'Johun Othone fought under your command.',e2_vell_saved:'Lord Tarsus Vell came home from the stockade.',
 e2_vorr_down:'Lord Vorr fell in the seventh battle.',e2_hoth_goes:'Hoth walked into the caves himself.',e2_hoth_waits:'Farfalla kept Hoth out of the caves.'});
// Debrief epilogue and Council briefing lines (spec C §9 voice). [N]
Object.assign(EPI,{
 r_muster:{win:'Hoth walks the field shaking hands. He remembers every name.',lose:'Half the army lands in the wrong valley.'},
 r_ravine:{win:'Johun asks your name twice so he won\'t forget it.',lose:'Hoth reads the list of the dead himself.'},
 r_caves:{win:'The tablets describe something no one on the Council wants to say out loud.',lose:'Whatever Kaan is planning, he plans it in the dark.'},
 r_sixth:{win:'Lord Vell can\'t hold a saber yet. He holds a cup of caf and doesn\'t let go.',lose:'Kaan sends Vell\'s saber back. Only the saber.'},
 r_seventh:{win:'Kaan\'s army runs for the caves. Nobody asks why the caves.',lose:'Six battles became seven. Nobody has won any of them.'},
 r_bomb:{win:'Two armies walk off Ruusan. One of them is much smaller.',lose:'The caves are a crater. The silence after is the loudest thing on Ruusan.'}});
Object.assign(MISSIONS.r_muster,{quote:'“Hold the light, and the rest of us will find it.” — Lord Hoth'});
Object.assign(MISSIONS.r_ravine,{quote:'“Bring my student home. Bring them all home.” — Lord Hoth'});
Object.assign(MISSIONS.r_caves,{quote:'“Kaan is afraid. Find out of what.” — Lord Farfalla'});
Object.assign(MISSIONS.r_seventh,{quote:'“One more battle. It is always one more battle.” — Lord Farfalla'});
Object.assign(MISSIONS.r_bomb,{quote:'“If Kaan wants a storm, he can have one. I will be standing in it.” — Lord Hoth'});

// Codex lore, merged into CODEX (data-codex.js, Chat L). ≤280 chars, spec C §9 voice. Legends unless tagged [N].
const ERA2_LORE={
 enemy:{bh_trooper:{lore:'Kaan\'s foot soldiers. They believe their Lords will make them more than human. Most die believing it.'},
  bh_marauder:{lore:'Sith who gave up everything but the fight. Every wound makes them hit harder.'},
  sith_lord:{lore:'The Brotherhood made everyone with a red blade a Lord. Kaan said it made them equal. It made them many.'},
  bh_sniper:{lore:'Hired guns from the Outer Rim. They don\'t care who wins Ruusan as long as someone pays.'},
  sith_spawn:{lore:'Dark-side things that crawl out where the Force is wounded. Blasters bother them. Jedi feed them.'},
  nexus:{lore:'A place where too much hate soaked into the ground. The Force sours around it.'},
  nexus_core:{lore:'The oldest, deepest wound in the caves. Destroy it and the Spawn stop coming.'},
  vorr:{lore:'Kaan\'s field commander, a soldier first and a Sith second. He holds high ground the way other men hold grudges. [N]'},
  kaan:{lore:'Skere Kaan, Dark Lord of the Brotherhood. Charismatic, reckless, and out of options. (Legends, High)'},
  bane:{lore:'A Sith who thinks Kaan\'s army is a mistake. He may be planning to let it die. (Legends, High)'}},
 character:{hoth:{lore:'Lord Hoth leads the Army of Light. A blunt soldier who never wanted to be one. In canon he dies in the thought bomb. (Legends, High)'},
  farfalla:{lore:'Valenthyne Farfalla, a Lord of the Army of Light. Flamboyant, merciful, and the one who leads the Jedi after Ruusan. (Legends, High)'},
  johun:{lore:'Johun Othone, Hoth\'s student. In canon he survives Ruusan and builds its memorial. (Legends, High)'},
  kaan:{lore:'Lord Kaan built the Brotherhood of Darkness by making every Sith a Lord. Equality, he called it. It made the Sith easy to count. (Legends, High)'},
  bane:{lore:'Darth Bane. In canon he walks away from Ruusan, the only Sith left, and writes the Rule of Two. (Legends, High)'},
  tarn_vel:{lore:'A Brotherhood apprentice who walked into a Jedi camp with his hands open. Nobody is sure yet whether he meant it. [N]'},
  vell:{lore:'Lord Tarsus Vell, an Army of Light Lord taken in the sixth battle. Loud, brave, and very glad to be alive. [N]'}},
 mission:{r_muster:{lore:'The Army of Light came to Ruusan in transports, lit down by a single beacon. [N]'},
  r_ravine:{lore:'Ruusan\'s ravines filled with the wounded of seven battles.'},r_caves:{lore:'Kaan\'s Lords met in the caves to plan their last move.'},
  r_sixth:{lore:'The sixth battle of Ruusan went to the Brotherhood. Its prisoners went to Kaan. (battle count: Legends, High; details [N])'},
  r_seventh:{lore:'The seventh and last battle of Ruusan. Kaan\'s army broke and fled into the caves. (Legends, High)'},
  r_bomb:{lore:'The thought bomb: a ritual that drew in every Force user nearby and did not let go. (Legends, High)'},
  r_hospital:{lore:'The Army of Light ran its hospitals in tents, close enough to the front to hear it. [N]'},
  r_nexus:{lore:'Ruusan\'s caves held old dark-side wounds. The Spawn came from somewhere. [N]'},
  r_snipers:{lore:'Kaan paid mercenaries in plunder. The ridges of Ruusan were full of them. [N]'},
  r_dump:{lore:'An army of Lords still needs blaster gas. Kaan kept his in one place. [N]'},
  r_prisoners:{lore:'The Brotherhood took prisoners to break them, and sometimes to turn them. [N]'},
  r_codes:{lore:'Kaan gave his orders by courier and by signal. The signals were faster, and easier to steal. [N]'},
  r_supply:{lore:'Hoth\'s army ate what the convoys brought. When the convoys stopped, so did the army. [N]'}},
 planet:{ruusan:{lore:'A green Mid Rim world that hosted seven battles between the Army of Light and the Brotherhood of Darkness. (Legends, High)'}}};
if(typeof CODEX!=='undefined')for(const [k,v] of Object.entries(ERA2_LORE)){CODEX[k]=CODEX[k]||{};for(const [id,o] of Object.entries(v))if(!CODEX[k][id])CODEX[k][id]=o}
// Codex unlocks: mission → [planet, [characters]]; event → [characters] (L's MISSION_LORE / EVENT_LORE in data-story.js).
for(const id of ['r_muster','r_caves','r_sixth','r_hospital','r_nexus','r_snipers','r_dump','r_prisoners','r_codes','r_supply'])MISSION_LORE[id]=MISSION_LORE[id]||['ruusan'];
Object.assign(MISSION_LORE,{r_ravine:['ruusan',['johun','hoth']],r_seventh:['ruusan',['hoth','farfalla']],r_bomb:['ruusan',['kaan','hoth','bane']]});
Object.assign(EVENT_LORE,{e2_lord_titles:['hoth','farfalla'],e2_hoth_charge:['hoth'],e2_farfalla_amnesty:['farfalla','hoth'],e2_farfalla:['farfalla','hoth'],
 e2_hoth_student:['hoth','johun'],e2_farfalla_healers:['farfalla'],e2_bane_rumor:['bane'],e2_hoth_last:['hoth','farfalla'],e2_deserter:['tarn_vel']});

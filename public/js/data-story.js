/* Story data (Era 1, ~3,660 BBY): vision shard, events, Years pass rules, Darth Malgus boss map, era-end text. Spec: docs/specs/story.md
   Loads after data.js and data-campaign.js; adds to their tables (FOES, MISSIONS, CRISES, PLAN) at load time. Logic lives in story.js. */
const ERA1={n:'Old Republic',bby:3660,next:'Ruusan · ~1,000 BBY',
 // Vision shard shown at era start (spec C §1). Lore: Legends, Temple sacked ~3,653 BBY (Med-High).
 shard:{t:'A shard of the vision',text:'Meditating again, the Council sees more: fire on the Temple steps, a red blade in a scarred hand, a treaty signed in smoke.'}};
// The Vision meter (`shadow`, 0–10, start 6): how strongly the vision is coming true. Lower is better.
const SHADOW={start:6,word:v=>v<=3?'faint':v<=6?'clear':'certain'};

// Enemies added for the story. Lore: Darth Malgus led the strike on the Temple (Legends, High).
Object.assign(FOES,{
 malgus:{n:'Darth Malgus',ic:'e_acolyte',hp:14,aim:80,mob:5,dmg:[4,6],range:1.5,deflect:30,guardDef:30,force:1,lightning:[3,4],armor:1,noCap:1,boss:1,init:15},
 // Mandalorian clans fought for the Empire in the Great War (Legends, Med).
 mando:{n:'Mandalorian Merc',ic:'e_trooper',hp:6,aim:70,mob:6,dmg:[3,5],range:8,armor:1,init:12}});

// Mirror a map left↔right so reused layouts feel new.
function mirrorMission(M,extra){const flip=a=>a&&a.map(p=>typeof p[0]==='string'?[p[0],W-1-p[1],p[2]]:[W-1-p[0],p[1]]);
 return{...M,map:M.map.map(r=>r.split('').reverse().join('')),start:flip(M.start),foes:flip(M.foes),hostage:M.hostage&&[W-1-M.hostage[0],M.hostage[1]],story:0,...extra}}

Object.assign(MISSIONS,{
 blockade:mirrorMission(MISSIONS.relay,{n:'Supply Lane Hydian',theme:'plains',where:'Convoy depot · Hydian Way',objName:'Convoy',
  waves:{1:['mando','trooper','trooper'],3:['mando','trooper','heavy'],5:['mando','mando','trooper']},
  brief:'Mandalorian clans in Imperial pay are hitting a Republic supply convoy. Hold the depot for 8 turns until the Navy escort arrives.',
  goal:'Hold the convoy for 8 turns. Mandalorians are armored and hit hard.',
  win:'The escort arrives. The convoy gets through.',lose:'The convoy burns. The lane stays closed.',
  reward:{credits:90,favor:3},bonus:{credits:30},bonusTxt:'Convoy above 75%'}),
 cache:mirrorMission(MISSIONS.envoy,{n:'Listening Post Besh',theme:'ruins',where:'Abandoned listening post · Inner Rim',foes:[['trooper',7,1],['trooper',2,1],['heavy',3,0],['agent',1,4]],
  brief:'An Imperial listening post is tracking Republic fleet moves. Scan its terminals (Jedi or Medic, adjacent), then get anyone to an evac zone.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. Threat rises after turn 6.',
  win:'The intercepts are out. The Navy changes course.',lose:'The post wipes itself. The trail goes cold.',
  reward:{credits:60,intel:1},bonus:{intel:2},bonusTxt:'All 3 terminals'}),
 hutt:mirrorMission(MISSIONS.envoy,{n:'Spice Ledger',theme:'city',where:'Hutt warehouse · Nar Shaddaa',foes:[['trooper',7,1],['mando',2,1],['trooper',3,0],['agent',1,4]],
  brief:'The Hutt broker keeps his kyber deals on warehouse terminals. Copy the ledgers and get out. His Mandalorian guards will not make it easy.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. Threat rises after turn 6.',
  win:'The ledgers are out, and so are his crystals.',lose:'The warehouse locks down.',
  reward:{credits:50,kyber:2},bonus:{intel:1},bonusTxt:'All 3 terminals'}),
 // Era 1 boss (spec C §2, S3). Assault: defeat Malgus before Threat 6, when he reaches the Temple lifts.
 dock:{n:'Docking Ring Nine',where:'Docking Ring Nine · Coruscant',type:'assault',story:1,boss:'malgus',eraBoss:1,theme:'dock',
  escape:'Malgus reaches the Temple lifts.',near:'Malgus is at the lift doors. Next turn he is inside.',push:'Malgus pushes toward the Temple lifts.',
  get par(){const f=typeof C!=='undefined'&&C?C.flags:{};return 6+(f.e1_strike_known?2:0)+(f.e1_eleena_tracked?1:0)},
  map:["###....###","..#....#..",".c..cc..c.","...x..x...","##.c..c.##","..........",".c.#..#.c.","...c..c...",".x......x.","..c.##.c..","..........","..c....c.."],
  foes:[['malgus',4,1],['heavy',5,0],['trooper',2,2],['trooper',7,2]],reinforce:['trooper','trooper'],
  start:[[3,11],[4,10],[5,10],[6,11],[1,10],[8,10]],
  brief:'While the treaty is signed on Alderaan, Darth Malgus lands at Docking Ring Nine with a strike team. His target is the Temple. Stop him here.',
  goal:'Defeat Darth Malgus. Threat rises after the par turn; at Threat 6 he reaches the Temple lifts. Barrels (x) explode when shot.',
  win:'Malgus falls on the docking ring. The Temple never sees him.',lose:'Malgus breaks through to the Temple.',
  reward:{credits:120,kyber:1},bonus:{favor:5},bonusTxt:'Done by the par turn'}});

Object.assign(CRISES,{
 blockade:{n:'Mandalorians on the Hydian Way',kind:'Defend',src:'Senate request',mission:'blockade',
  text:'Clans in Imperial pay are choking a Republic supply lane. The Navy asks for Jedi.',ignore:{favor:-8}},
 cache:{n:'Imperial listening post',kind:'Investigate',src:'Jedi',mission:'cache',
  text:'A Sentinel sensed Imperial slicers in an old Republic post. Something is tracking the fleet.',ignore:{orderDark:4}},
 hutt:{n:'Hutt kyber broker',kind:'Investigate',src:'Jedi',mission:'hutt',
  text:'A Hutt is selling Ilum-grade crystals to anyone. His ledgers name the buyers.',ignore:{}}});

// v0.2b flow (spec B §8.1): … envoy → YEARS PASS → crisis → crisis → Malgus.

// Years pass (+5 years) rules (spec B §1.5). Retire chances are percent per jump.
const YEARS={jump:5,  // default; each {years:n} plan step sets its own jump
recruits:3,
 retire(r,jedi){const a=r.age;if(jedi)return a>=85?100:a>=75?50:a>=65?20:0;return a>=55?100:a>=50?60:a>=40?25:0},
 trialsFail:{dark:7,chance:50},
 // Start ages for the opening roster; anyone else gets a class range.
 ages:{'Kira Venn':29,'Tor Saalen':17,'Sgt. Rhal Dax':47,'Ilsa Myr':26,'Doc Bren':38,'Grak Ordo':33},
 range:{Padawan:[14,19],Knight:[22,40],troop:[20,35]},
 roles:{staff:'Staff a wing',teach:'Teach the next recruit',relic:'Leave a relic to the Archive'}};

// Recruitable canon characters from events. Satele Shan: young Knight here, Grand Master by ~3,645 BBY (Legends, Med on her age).
const STORY_RECRUITS={
 satele_shan:{n:'Satele Shan',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['reflectM'],col:'#9fd4ff',age:24}};

// Random events, Era 1 (spec C §3). Order Darkness is 0–100 here, so spec C's +1 becomes +4.
// Effect keys: credits intel kyber favor recruits orderDark shadow unitDark{who,n} loyalty{seat,n} flag recruit wound{who,turns} mission chance fail
// Triggers: era_start · month{min} · after_mission{min} · stat{key,op,val} · flag{flag}
const EVENTS=[
 {id:'e1_gnost_archive',trigger:{type:'era_start'},text:'Master Gnost-Dural asks to copy the Archives to a hidden colony, in case the Temple falls.',
  choices:[{label:'Approve the copy',effects:{credits:-40,flag:'archive_backup'}},{label:"The Temple won't fall",effects:{loyalty:{seat:'gnost',n:-10}}}]},
 {id:'e1_kyber_trade',trigger:{type:'month',min:1},text:'A Hutt broker has Ilum-grade crystals. His price: look away from his spice run.',
  choices:[{label:'Buy, look away',effects:{kyber:2,orderDark:4,flag:'e1_hutt_deal'}},{label:'Refuse',effects:{}},{label:'Seize them',effects:{mission:'hutt',favor:-1}}]},
 {id:'e1_mando_blockade',trigger:{type:'month',min:2},text:'Mandalorians in Imperial pay are choking a supply lane. The Navy asks for Jedi. The Senate asks you to stay out.',
  choices:[{label:'Send a squad',effects:{mission:'blockade',favor:-1}},{label:'Pay the clans off',effects:{credits:-60,favor:1}},{label:'Ignore it',effects:{favor:-2}}]},
 {id:'e1_treaty_vote',trigger:{type:'flag',flag:'e1_strike_known'},text:'You know the strike is coming. Warn the Senate, and maybe the Empire\'s spies, or keep it inside the Order?',
  choices:[{label:'Warn the Senate',effects:{favor:2,intel:-1}},{label:'Keep it secret',effects:{flag:'e1_ambush_ready',favor:-1}}]},
 {id:'e1_satele',trigger:{type:'after_mission',min:3},text:'A young Knight, Satele Shan, asks to join your strike teams. Her master, Kao Cen Darach, disagrees.',
  choices:[{label:'Take her',effects:{recruit:'satele_shan',flag:'satele_joined',loyalty:{seat:'darach',n:-10}}},{label:'Respect her master',effects:{loyalty:{seat:'darach',n:10}}}]},
 {id:'e1_prisoner_offer',trigger:{type:'stat',key:'intel',op:'>=',val:3},text:'A captured Imperial officer offers names of Republic traitors in exchange for a ship.',
  choices:[{label:'Deal',effects:{intel:2,favor:-1,flag:'e1_traitors'}},{label:'Hand him to the Navy',effects:{favor:1}},{label:'Make him talk',effects:{intel:3,unitDark:{who:'jedi_random',n:2}}}]}];
const COUNCIL_SEATS={gnost:{n:'Gnost-Dural',loyalty:60},darach:{n:'Kao Cen Darach',loyalty:60},zym:{n:'Grand Master Zym',loyalty:60}};

// Debrief / era-end lines (spec C §9: one line of result, one of cost).
const STORY_TEXT={
 bossWin:'You stopped the shuttle. The treaty was still signed in smoke.',
 bossLose:'Malgus reached the Temple steps before the Guard drove him off. The Temple is scarred: a wing lost a level.',
 ambush:'Your ambush was ready: Malgus lands already wounded.',
 adraas:'Adraas fell on Alderaan: one fewer squad came with Malgus.',guards:'Temple Guards hold the docking ring: no reinforcements reach Malgus.',
 eraWin:'The Temple stands. The Empire got its treaty, but not its lesson.',
 eraLose:'The Temple stands, scarred. The Senate wonders what the Jedi are for.',
 darkWarn:'The Order is drifting. Some Masters speak of a Dark Council.'};
// "What history changed" recap: flag → line.
const FLAG_LINES={e1_strike_known:'The envoy talked: you knew the strike was coming.',e1_ambush_ready:'You kept the warning inside the Order and set an ambush.',
 archive_backup:'A copy of the Archives sleeps on a hidden colony.',e1_traitors:'Names of Republic traitors sit in your files.',
 boss_or_won:'Darth Malgus fell at Docking Ring Nine.',temple_scarred:'The Temple was scarred. In canon it was sacked.'};

// ═══ Wave 3 (Chat L): Era 1 becomes a full era. 3 Acts, 12 missions, 3,660 → 3,653 BBY. ═══
// Lore: Treaty of Coruscant signed on Alderaan as Malgus and Adraas sack the Temple, 3,653 BBY (Legends, Med-High).
// Satele Shan and Jace Malcom fight Malgus at Alderaan in the same war (Legends, High). Their missions here are [N] invented.
FOES.adraas={n:'Lord Adraas',ic:'e_acolyte',hp:11,aim:75,mob:5,dmg:[4,5],range:1.5,deflect:25,guardDef:20,force:1,lightning:[3,4],noCap:1,boss:1,init:14}; // [L H] Malgus's co-commander

Object.assign(MISSIONS,{
 // Act II story: Gnost-Dural's arc. Ossus is a ruined Jedi archive world (Legends, High); this expedition is [N].
 vault:{n:"Gnost-Dural's Vault",where:'Archive ruins · Ossus',type:'investigate',story:1,par:6,theme:'ruins',
  map:["..q.#..#q.",".h..#..#..","..c....c..","B.#.hh.#.B","...r..r...",".c..q...c.","..B....B..",".r..cc..r.","...h..h...",".c......c.","..c.r..c..","EE......EE"],
  stealth:1,foes:[['trooper',1,2,1],['trooper',8,2,2],['agent',5,1],['heavy',5,4,2],['acolyte',3,1,1]],patrol:{2:[[8,2],[8,4],[6,4],[6,2]]},reinforce:['trooper','trooper'],
  start:[[2,11],[3,11],[4,11],[5,11],[6,11],[7,11]],
  brief:'You start concealed: pods patrol the ruins. Master Gnost-Dural found a sealed vault in the Ossus ruins: records from the last time the Sith struck at the Jedi. Imperial agents found it too. Scan the terminals (Jedi or Medic, adjacent), then reach evac.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. A Sith Acolyte guards the vault. Threat rises after turn 6.',
  win:'The records come home. Gnost-Dural reads all night.',lose:'The vault burns. Whatever it knew is ash.',
  reward:{credits:60,intel:2,kyber:1},bonus:{intel:2},bonusTxt:'All 3 terminals',winFlag:'e1_vault_read'},
 // Act II story: Jace Malcom's arc. Ilum = kyber world (Legends/Canon, High); this battle is [N].
 ilum:{n:'The Cave Mouth',where:'Crystal caves · Ilum',type:'defend',story:1,turns:8,obj:18,objName:'Cave mouth',lastWave:5,theme:'snow',
  map:["..........","..B....B..",".c..h...c.","...c..c...","#..r..r..#",".c.B..B.c.","....cc....",".h......h.","..c.##.c..",".r.c..c.r.","...#OO#...","....OO...."],
  waves:{1:['trooper','trooper','trooper'],3:['mando','trooper','heavy'],5:['acolyte','trooper','trooper']},
  start:[[2,10],[7,10],[4,9],[5,9],[1,11],[8,11]],
  brief:'Sith raiders want the Ilum crystal caves. Sgt. Jace Malcom’s platoon is all that holds the mouth, and it is thin. Hold for 8 turns until his relief lands.',
  goal:'Hold the cave mouth for 8 turns. Three waves; the last brings a Sith Acolyte.',
  win:'Relief lands in the snow. The caves stay quiet.',lose:'The raiders reach the crystals. Ilum goes dark for a generation.',
  reward:{credits:70,kyber:2},bonus:{favor:4},bonusTxt:'Cave mouth above 75%',winRecruit:'jace_malcom',winFlag:'jace_joined'},
 // Act III story: Satele Shan's arc. Adraas and Malgus led the sack together (Legends, High); this strike is [N].
 adraasHunt:{n:'Shadow of Adraas',where:'Embassy hangar · Alderaan',type:'assault',story:1,boss:'adraas',par:6,theme:'city',
  escape:'Adraas reaches his shuttle and is gone.',near:'Adraas is at his shuttle ramp.',push:'Adraas falls back toward his shuttle.',
  map:["##..##..##","...c..c...",".B......B.","...h..h...",".c..xx..c.","...B..B...",".h......h.","..c.##.c..",".x......x.","...c..c...",".B......B.",".........."],
  stealth:1,foes:[['adraas',4,1,1],['trooper',2,2,1],['trooper',7,2,2],['agent',9,3],['mando',5,3,2]],patrol:{2:[[7,2],[7,5],[4,5],[4,2]]},reinforce:['trooper','mando'],
  start:[[2,11],[3,11],[4,11],[5,11],[6,11],[7,11]],
  brief:'You start concealed. While the delegates talk, Lord Adraas waits in an embassy hangar for a signal. Satele Shan wants him taken off the board before it comes. Defeat him before he reaches his shuttle.',
  goal:'Defeat Lord Adraas. Threat rises after turn 6; at Threat 6 he escapes. Barrels (x) explode when shot.',
  win:'Adraas falls in the hangar. One blade fewer for the strike.',lose:'Adraas gets away. He will be at Malgus’s side.',
  reward:{credits:90,intel:2},bonus:{favor:4},bonusTxt:'Done by the par turn',winFlag:'e1_adraas_down',loseFlag:'e1_adraas_free'},
 // Crisis variants (mirrored layouts, new places). All [N].
 taris:mirrorMission(MISSIONS.rescue,{n:'Reclamation Camp',where:'Refugee camp · Taris',theme:'ruins',
  brief:'Sith raiders grabbed a Republic relief officer from a Taris refugee camp. Open the cell (Hack or console), then walk her to an evac zone (E).',
  win:'The officer is out. The camp gets its medicine.',lose:'The officer is gone. The camp goes hungry.',reward:{credits:70,favor:4}}),
 thul:mirrorMission(MISSIONS.escort,{n:'The Thul Heir',where:'Estate grounds · Alderaan',theme:'plains',
  brief:'Imperial agents want a young heir of House Thul dead before the talks. Walk her to the shuttle at the far evac zone.',
  win:'The heir reaches the talks. House Thul owes the Order.',lose:'The heir dies on her own lawn. Alderaan blames the Jedi.',reward:{credits:80,favor:6}}),
 depot:mirrorMission(MISSIONS.sabotage,{n:'Forward Depot Cresh',where:'Imperial forward depot · Mid Rim',theme:'plains',
  win:'The depot burns. The Imperial push stalls a month.',lose:'The depot holds. The push comes on time.'}),
 fort:mirrorMission(MISSIONS.shrine,{n:'Fort Garnik',where:'Hill fort · Ord Mantell',objName:'Fort',theme:'plains',
  waves:{1:['trooper','trooper'],2:['mando'],4:['trooper','heavy']},
  brief:'A Republic hill fort on Ord Mantell is under Mandalorian and Sith attack. Hold it for 6 turns until the garrison regroups.',
  goal:'Hold the fort for 6 turns. Mandalorians are armored and hit hard.',
  win:'The garrison regroups. The hill stays Republic.',lose:'The fort falls. Ord Mantell burns again.',reward:{credits:70,favor:3}})});

Object.assign(CRISES,{
 taris:{n:'Taken at the Taris camp',kind:'Rescue',src:'Civilian',mission:'taris',text:'Raiders took the relief officer who keeps a refugee camp alive.',ignore:{favor:-3,orderDark:4}},
 thul:{n:'The Thul heir',kind:'Escort',src:'Senate request',mission:'thul',text:'An Alderaanian heir is marked for death before the peace talks.',ignore:{favor:-8}},
 depot:{n:'Forward depot',kind:'Sabotage',src:'Navy request',mission:'depot',text:'An Imperial depot feeds the next push. Blow it and get out.',ignore:{favor:-5}},
 fort:{n:'Fort Garnik under siege',kind:'Defend',src:'Navy request',mission:'fort',text:'Mandalorians and Sith troopers are storming a Republic hill fort.',ignore:{favor:-5}}});

// The plan: Act I (3,660) · Years pass +3 · Act II (3,657) · Years pass +4 · Act III (3,653, the year of the treaty).
PLAN.length=0;PLAN.push(
 {story:'relay'},{crises:['rescue','shrine','archive']},{story:'envoy'},{crises:['hutt','blockade']},
 {years:3,act:2},
 {crises:['sabotage','cache']},{story:'vault'},{crises:['escort','fort']},{story:'ilum'},
 {years:4,act:3},
 {crises:['taris','depot']},{story:'adraasHunt'},{crises:['thul','blockade','archive']},{story:'dock'});
// Text for each Years pass jump, by the Act it opens.
const ACTS={2:{t:'Years pass',text:'Three years go by. The war cools into a cold peace that no one trusts. Wounds heal. Padawans face the Trials. Some veterans hang up their gear.'},
 3:{t:'The year of the treaty',text:'Four more years. Envoys gather on Alderaan to sign a peace. The Council’s vision has never been clearer. Whatever is coming, it comes this year.'}};
// Shard shown at the start of each Act (spec C §1 style). The Act I shard is ERA1.shard.
const SHARDS={2:'The vision returns: Jedi bodies on the Temple steps, and a treaty table on a green world.',
 3:'The vision is clear now: a shuttle at a docking ring, a scarred Sith Lord, and the Temple doors open.'};

Object.assign(STORY_RECRUITS,{
 jace_malcom:{n:'Jace Malcom',cls:'Soldier',rank:2,xp:30,picks:['rapidFire'],col:'#e0bd78',age:31}}); // age [N], Low

// Debrief epilogue: one line of cost, after the result (spec C §9).
const EPI={
 relay:{win:'Three of them didn’t come home to the frontier.',lose:'The fleet arrived to a burned-out relay.'},
 envoy:{win:'Saresh will never serve the Senate again. Nobody thanks you for it.',lose:'Somewhere, the schedule still leaks.'},
 rescue:{win:'The depot burns behind you. So does the trust of the local militia.',lose:'An empty cell, still warm.'},
 shrine:{win:'The pilgrims light candles for the Jedi. And for the troopers who held the line.',lose:'The crystals are gone. The shrine will sing no more.'},
 archive:{win:'The Navy got its codes. Imperial Intelligence will want to know who took them.'},
 sabotage:{win:'The sky over Balmorra burns orange for a week.'},escort:{win:'The senator will vote for peace. He will not thank you either.'},
 blockade:{win:'The convoy is through. The clans will remember the Jedi who stopped them.'},
 cache:{win:'The intercepts are good. The Empire is moving more ships than it admits.'},hutt:{win:'The Hutt will remember this. Hutts always remember.'},
 vault:{win:'Gnost-Dural reads the records twice, then asks to see the Grand Master alone.',lose:'Gnost-Dural says nothing on the flight home. He does not need to.'},
 ilum:{win:'Jace Malcom buries four of his platoon in the snow, then asks how he can serve.',lose:'The caves are silent. Malcom’s platoon held to the last.'},
 adraasHunt:{win:'Satele says nothing about the treaty. She is thinking about the one Sith left.',lose:'The hangar smells of ozone. Adraas has gone to join Malgus.'},
 taris:{win:'The camp eats tonight.'},thul:{win:'House Thul will speak for the Jedi at the talks.',lose:'Alderaan’s nobles close their doors to the Order.'},
 depot:{win:'The push stalls. Somewhere, an Imperial officer is shot for it.'},fort:{win:'The hill is Republic. For now.'},
 dock:{win:'The treaty was still signed in smoke.',lose:'The Temple stands, scarred. Grand Master Zym walks the burned halls alone.'}};
// Briefing line from the Council, shown with the mission brief (spec C §9 voice). [N]
const QUOTES={relay:'“Hold the relay. The fleet needs the lane open.” — Grand Master Zym',envoy:'“Somebody is selling the peace. Find out who.” — Kao Cen Darach',
 vault:'“The last time the Sith struck at a Temple, they did it while we talked.” — Gnost-Dural',ilum:'“No Jedi blade without Ilum. Hold it.” — Grand Master Zym',
 adraasHunt:'“Two of them will come. Let us make it one.” — Satele Shan',dock:'“This is the vision. Change it.” — Grand Master Zym'};
for(const k in QUOTES)if(MISSIONS[k])MISSIONS[k].quote=QUOTES[k];

// Era 1 events, wave 3. Extra trigger types: act{min} · all:[triggers] · notFlag{flag}. Order Darkness is 0–100 (spec C ×4).
EVENTS.push(
 {id:'e1_refugees',trigger:{type:'month',min:2},text:'Refugees from Taris ask to camp in the Temple gardens. The Senate says it sets a bad example.',
  choices:[{label:'Take them in',effects:{credits:-40,favor:-2,recruits:1,flag:'e1_refugees_in'}},{label:'Send them to the Senate',effects:{favor:1}},{label:'Turn them away',effects:{orderDark:4}}]},
 {id:'e1_senate_audit',trigger:{type:'after_mission',min:2},text:'A Senate committee wants an account of every credit the Order spends on the war.',
  choices:[{label:'Open the books',effects:{credits:-30,favor:4}},{label:'Refuse',effects:{favor:-4}}]},
 {id:'e1_ilum_call',trigger:{type:'act',min:2},text:'A Republic sergeant, Jace Malcom, sends a blunt signal from Ilum: Sith scouts are circling the crystal caves.',
  choices:[{label:'Send kyber money',effects:{credits:-30,kyber:1}},{label:'Tell him help is coming',effects:{favor:1}}]},
 {id:'e1_defector',trigger:{type:'after_mission',min:4},text:'An Imperial agent wants to defect. She says she knows how the Empire talks to its strike teams.',
  choices:[{label:'Bring her in',effects:{chance:0.6,intel:3,flag:'e1_defector',fail:{wound:{who:'squad_leader',turns:2},intel:1}}},{label:'Hand her to the SIS',effects:{favor:2}}]},
 {id:'e1_gnost_warning',trigger:{type:'flag',flag:'e1_vault_read'},text:'Gnost-Dural’s records show the old Sith struck at a Temple during peace talks. He thinks it will happen again.',
  choices:[{label:'Tell the whole Council',effects:{flag:'e1_strike_known',loyalty:{seat:'gnost',n:10}}},{label:'Seal the records',effects:{intel:2,loyalty:{seat:'gnost',n:-10}}}]},
 {id:'e1_mando_duel',trigger:{type:'month',min:4},text:'A Mandalorian champion holds a Republic pilot. He will trade her for a duel with your best Jedi.',
  choices:[{label:'Accept the duel',effects:{chance:0.5,favor:4,flag:'e1_mando_honor',fail:{wound:{who:'jedi_highestDark',turns:2}}}},{label:'Decline',effects:{favor:-2}}]},
 {id:'e1_revenge',trigger:{type:'after_mission',min:6},text:'A young Jedi lost friends in the last fight. They want the next mission to be about payback.',
  choices:[{label:'Counsel patience',effects:{unitDark:{who:'jedi_highestDark',n:-2}}},{label:'Let them burn',effects:{unitDark:{who:'jedi_highestDark',n:2},intel:1}}]},
 {id:'e1_jace_satele',trigger:{type:'all',all:[{type:'flag',flag:'satele_joined'},{type:'flag',flag:'jace_joined'}]},text:'Satele Shan and Jace Malcom are seen together more than the Code would like. Darach asks you to step in.',
  choices:[{label:'Look away',effects:{favor:1,loyalty:{seat:'darach',n:-10}}},{label:'Remind her of the Code',effects:{loyalty:{seat:'darach',n:10},orderDark:-4}}]},
 {id:'e1_zym_treaty',trigger:{type:'act',min:3},text:'Grand Master Zym will back the treaty, even its terms that pull Jedi off Imperial-claimed worlds.',
  choices:[{label:'Back Zym',effects:{favor:4,orderDark:-4,loyalty:{seat:'zym',n:10}}},{label:'Oppose the terms',effects:{favor:-3,flag:'e1_opposed_treaty',loyalty:{seat:'zym',n:-10}}}]},
 {id:'e1_eleena',trigger:{type:'act',min:3},text:'Scouts saw a Twi’lek, Eleena Daru, buying shuttle codes for Coruscant. She travels with Darth Malgus.',
  choices:[{label:'Track her',effects:{intel:-1,flag:'e1_eleena_tracked'}},{label:'Let her go',effects:{}}]},
 {id:'e1_docks',trigger:{type:'after_mission',min:9},text:'The Temple Guard captain asks for credits to post guards at the Coruscant docking rings.',
  choices:[{label:'Pay for the posts',effects:{credits:-60,flag:'e1_docks_guarded'}},{label:'The Temple comes first',effects:{}}]},
 {id:'e1_padawan_doubt',trigger:{type:'act',min:3},text:'A Padawan asks why the Order makes peace with the people who burned their homeworld.',
  choices:[{label:'Answer honestly',effects:{unitDark:{who:'jedi_random',n:-1}}},{label:'Tell them to obey',effects:{unitDark:{who:'jedi_random',n:1},favor:1}}]});
Object.assign(FLAG_LINES,{e1_vault_read:'Gnost-Dural recovered the Ossus records.',jace_joined:'Jace Malcom fought for the Order.',satele_joined:'Satele Shan fought under your command.',
 e1_adraas_down:'Lord Adraas fell on Alderaan.',e1_adraas_free:'Lord Adraas escaped to join the strike.',e1_defector:'An Imperial agent changed sides.',
 e1_opposed_treaty:'You spoke against the treaty’s terms.',e1_eleena_tracked:'You tracked Eleena Daru to Malgus’s shuttle.',e1_docks_guarded:'Temple Guards watched the docking rings.'});

// ═══ Wave 3 follow-up (Chat L): planets & characters for the Codex, flag-aware briefs/debriefs, event chains, barks, epilogues ═══
// Codex: which planet and characters each mission reveals (codexSee). Ids match CODEX.planet / CODEX.character.
const MISSION_LORE={shrine:['dantooine'],rescue:['ordMantell',['mira']],envoy:['coruscant',['saresh']],archive:['balmorra'],sabotage:['balmorra'],
 escort:['coruscant',['ondo']],blockade:['hydianWay'],hutt:['narShaddaa'],dock:['coruscant',['malgus']],vault:['ossus',['gnost']],ilum:['ilum',['jace']],
 adraasHunt:['alderaan',['adraas','satele']],taris:['taris'],thul:['alderaan',['thulHeir']],fort:['ordMantell'],
 r_ravine:['ruusan'],r_caves:['ruusan'],r_bomb:['ruusan'],r_hospital:['ruusan'],r_nexus:['ruusan'],r_snipers:['ruusan'],r_dump:['ruusan']};
// Characters met in Council events.
const EVENT_LORE={e1_gnost_archive:['gnost'],e1_satele:['satele','darach'],e1_ilum_call:['jace'],e1_gnost_warning:['gnost'],e1_jace_satele:['satele','jace','darach'],
 e1_zym_treaty:['zym'],e1_eleena:['eleena','malgus'],e1_hutt_collects:['narShaddaa'],e1_refugee_pilot:['taris']};

// Brief additions: first matching flag wins, appended to the mission brief. [N]
const BRIEF_IF={
 dock:[['e1_eleena_tracked','Eleena Daru’s shuttle codes tell you exactly where he lands. You have an extra turn.'],['e1_strike_known','You knew this was coming. Your squad is in place early.'],['e1_hutt_sold','The Hutt sold Malgus the ring’s patrol schedule. He knows where you are.']],
 adraasHunt:[['e1_vault_read','Gnost-Dural’s records name the signal Adraas is waiting for. Strike before it comes.']],
 vault:[['archive_backup','Gnost-Dural is calm. A copy of the Archives already sleeps somewhere safe.']],
 ilum:[['e1_hutt_deal','Some of the raiders carry Hutt-sold Ilum crystals. Your deal paid for their sabers.']],
 envoy:[['e1_traitors','The traitor names from the Imperial officer point here too.']]};
// Debrief variants: checked before EPI; [flag, win line, lose line]. [N]
const DEBRIEF_IF={
 dock:[['temple_scarred',null,'The Temple stands, scarred. The Archive copy you approved means the records survive.'],['e1_adraas_down','Malgus fought alone at the end. Adraas never came.',null]],
 ilum:[['satele_joined','Satele Shan stays behind to help Malcom bury his dead. Darach notices.',null]],
 adraasHunt:[['e1_eleena_tracked','Adraas is gone. Eleena’s trail still leads to Coruscant.',null]],
 vault:[['e1_strike_known','The records match the envoy’s confession. Gnost-Dural stops sleeping.',null]]};

// Delayed consequences: Act I choices pay off in Act III.
EVENTS.push(
 {id:'e1_hutt_collects',trigger:{type:'all',all:[{type:'act',min:3},{type:'flag',flag:'e1_hutt_deal'}]},text:'The Hutt from Act I is back. He wants your help with a Senate hearing, or he sells what he knows about the docking rings to the Empire.',
  choices:[{label:'Help him',effects:{favor:-6,orderDark:4}},{label:'Pay him off',effects:{credits:-80}},{label:'Let him sell',effects:{flag:'e1_hutt_sold'}}]},
 {id:'e1_archive_copy',trigger:{type:'all',all:[{type:'act',min:3},{type:'flag',flag:'archive_backup'}]},text:'The hidden Archive copy sends word: the keepers found a holocron the Temple thought was lost.',
  choices:[{label:'Bring it home',effects:{intel:2,kyber:1}},{label:'Leave it hidden',effects:{shadow:-1}}]},
 {id:'e1_traitor_purge',trigger:{type:'all',all:[{type:'act',min:3},{type:'flag',flag:'e1_traitors'}]},text:'One name from the Imperial officer’s list now runs docking control on Coruscant.',
  choices:[{label:'Arrest him quietly',effects:{favor:2,flag:'e1_docks_guarded'}},{label:'Feed him false schedules',effects:{intel:2,flag:'e1_strike_known'}}]},
 {id:'e1_refugee_pilot',trigger:{type:'all',all:[{type:'act',min:3},{type:'flag',flag:'e1_refugees_in'}]},text:'A Taris refugee you sheltered years ago is now a freighter pilot. She saw a Sith shuttle filing false papers for Coruscant.',
  choices:[{label:'Thank her and listen',effects:{flag:'e1_strike_known',intel:1}},{label:'Offer her a place',effects:{recruits:1,favor:1}}]},
 {id:'e1_mando_debt',trigger:{type:'all',all:[{type:'act',min:3},{type:'flag',flag:'e1_mando_honor'}]},text:'The Mandalorian champion you dueled sends a fighter. "You beat him clean. Clan Ordo pays its debts."',
  choices:[{label:'Accept the fighter',effects:{recruit:'varra_ordo'}},{label:'Release the debt',effects:{favor:2}}]});
STORY_RECRUITS.varra_ordo={n:'Varra Ordo',cls:'Heavy',rank:2,xp:30,col:'#c9d27a',age:34}; // Clan Ordo is Legends (High); Varra is [N]
Object.assign(FLAG_LINES,{e1_hutt_sold:'A Hutt sold the docking schedule to the Empire.',e1_refugees_in:'You sheltered Taris refugees in the Temple gardens.',
 e1_mando_honor:'A Jedi beat a Mandalorian champion in a fair duel.'});

// In-battle barks (spec C §9: one line, no speeches). Keyed by recruit trait; 'jedi' and 'troop' are the fallbacks. [N]
const BARKS={
 jedi:{kill:['It’s done.','Rest now.','Forgive me.'],down:['Keep... going...','I can still feel you.'],crit:['There.','Opening.'],panic:['I can’t... the dark is loud.','Not like this.']},
 troop:{kill:['Target down.','One less.','Got him.'],down:['Medic!','I’m hit, I’m hit!'],crit:['Right through the plate.','Clean hit.'],panic:['I’m done, I’m done!','Where’s the evac?']},
 steady:{kill:['Next.','Target down. Moving.'],down:['Still here. Barely.'],crit:['Breathe. Squeeze.'],panic:['Hold it together... I can’t.']},
 reckless:{kill:['Who’s next?','Too easy!'],down:['Worth it.'],crit:['Did you see that?'],panic:['Get me out of here!']},
 compassionate:{kill:['I’m sorry.','He had a family. They all do.'],down:['Help the others first.'],crit:['End it quick.'],panic:['Too many of us are hurt.']},
 ambitious:{kill:['Write that one down.','Count it.'],down:['This isn’t how my story ends.'],crit:['Watch and learn.'],panic:['This wasn’t the plan!']},
 curious:{kill:['Interesting armor. Was.'],down:['Huh. That’s a lot of blood.'],crit:['Found the weak seam.'],panic:['What is that thing?']}};
// Named heroes speak their own lines. [N] characterization
const HERO_BARKS={'Jace Malcom':{kill:['Stay down.','That’s for Ilum.'],down:['Not today.'],crit:['Bullseye.'],panic:['Pull back! Pull back!']},
 'Satele Shan':{kill:['Go to the Force.'],down:['I’m all right. Move!'],crit:['Now.'],panic:['Steady... steady.']},
 'Kira Venn':{kill:['Hold the line.'],down:['Don’t wait for me.'],crit:['Opening!'],panic:['I see the Temple burning...']}};

// Era-end epilogue card per surviving unit: first matching rule writes the line. [N]
const EPILOGUE=[
 [r=>r.status==='retired'&&r.relic,r=>`Left a relic to the Archive. Padawans still argue about what it means.`],
 [r=>r.status==='retired',r=>`Retired at ${r.age}. ${r.role||'Lives quietly'}.`],
 [r=>CLASS[r.cls]&&CLASS[r.cls].jedi&&(r.dark||0)>=7,r=>`Walks close to the dark. The Council watches ${r.n} and says nothing.`],
 [r=>r.n==='Satele Shan',r=>`Follows the treaty to Tython. Some say she will lead the Order one day.`],   // [L H] Satele becomes Grand Master
 [r=>r.n==='Jace Malcom',r=>`Goes back to the front. The Republic will need soldiers like him for a long time.`],   // [L H] Malcom becomes Supreme Commander
 [r=>(r.scars||[]).length>0,r=>`Carries the war home in ${(r.scars||[]).length>1?'more than one scar':'a scar'}, and serves anyway.`],
 [r=>(r.kills||0)>=12,r=>`${r.kills} enemies fell to ${r.n}. The Senate gives a medal. ${r.n} gives it to the Archive.`],
 [r=>CLASS[r.cls]&&CLASS[r.cls].jedi&&r.title==='Master',r=>`Takes a seat on the Council, and a Padawan of their own.`],
 [r=>CLASS[r.cls]&&CLASS[r.cls].jedi&&r.title==='Knight',r=>`A Knight now. Teaches the younglings what the war cost.`],
 [r=>CLASS[r.cls]&&CLASS[r.cls].jedi,r=>`Still a Padawan, still learning. Some lessons only peace can teach.`],
 [r=>(r.missions||0)>=8,r=>`${r.missions} missions. The Temple Guard asks for ${r.n} by name.`],
 [r=>true,r=>`Survived the war. Goes home to a planet that never knew how close it came.`]];

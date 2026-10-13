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
 blockade:mirrorMission(MISSIONS.relay,{n:'Supply Lane Hydian',where:'Convoy depot · Hydian Way',objName:'Convoy',
  waves:{1:['mando','trooper','trooper'],3:['mando','trooper','heavy'],5:['mando','mando','trooper']},
  brief:'Mandalorian clans in Imperial pay are hitting a Republic supply convoy. Hold the depot for 8 turns until the Navy escort arrives.',
  goal:'Hold the convoy for 8 turns. Mandalorians are armored and hit hard.',
  win:'The escort arrives. The convoy gets through.',lose:'The convoy burns. The lane stays closed.',
  reward:{credits:90,favor:3},bonus:{credits:30},bonusTxt:'Convoy above 75%'}),
 cache:mirrorMission(MISSIONS.envoy,{n:'Listening Post Besh',where:'Abandoned listening post · Inner Rim',foes:[['trooper',7,1],['trooper',2,1],['heavy',3,0],['agent',1,4]],
  brief:'An Imperial listening post is tracking Republic fleet moves. Scan its terminals (Jedi or Medic, adjacent), then get anyone to an evac zone.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. Threat rises after turn 6.',
  win:'The intercepts are out. The Navy changes course.',lose:'The post wipes itself. The trail goes cold.',
  reward:{credits:60,intel:1},bonus:{intel:2},bonusTxt:'All 3 terminals'}),
 hutt:mirrorMission(MISSIONS.envoy,{n:'Spice Ledger',where:'Hutt warehouse · Nar Shaddaa',foes:[['trooper',7,1],['mando',2,1],['trooper',3,0],['agent',1,4]],
  brief:'The Hutt broker keeps his kyber deals on warehouse terminals. Copy the ledgers and get out. His Mandalorian guards will not make it easy.',
  goal:'Scan 2 of 3 terminals, then get anyone to an evac zone. Threat rises after turn 6.',
  win:'The ledgers are out, and so are his crystals.',lose:'The warehouse locks down.',
  reward:{credits:50,kyber:2},bonus:{intel:1},bonusTxt:'All 3 terminals'}),
 // Era 1 boss (spec C §2, S3). Assault: defeat Malgus before Threat 6, when he reaches the Temple lifts.
 dock:{n:'Docking Ring Nine',where:'Docking Ring Nine · Coruscant',type:'assault',story:1,boss:'malgus',
  get par(){return 6+(typeof C!=='undefined'&&C&&C.flags.e1_strike_known?2:0)},
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
PLAN.push({years:1},{crises:['blockade','rescue']},{crises:['cache','shrine']},{story:'dock'});

// Years pass (+5 years) rules (spec B §1.5). Retire chances are percent per jump.
const YEARS={jump:5,recruits:3,
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
  choices:[{label:'Buy, look away',effects:{kyber:2,orderDark:4}},{label:'Refuse',effects:{}},{label:'Seize them',effects:{mission:'hutt',favor:-1}}]},
 {id:'e1_mando_blockade',trigger:{type:'month',min:2},text:'Mandalorians in Imperial pay are choking a supply lane. The Navy asks for Jedi. The Senate asks you to stay out.',
  choices:[{label:'Send a squad',effects:{mission:'blockade',favor:-1}},{label:'Pay the clans off',effects:{credits:-60,favor:1}},{label:'Ignore it',effects:{favor:-2}}]},
 {id:'e1_treaty_vote',trigger:{type:'flag',flag:'e1_strike_known'},text:'You know the strike is coming. Warn the Senate, and maybe the Empire\'s spies, or keep it inside the Order?',
  choices:[{label:'Warn the Senate',effects:{favor:2,intel:-1}},{label:'Keep it secret',effects:{flag:'e1_ambush_ready',favor:-1}}]},
 {id:'e1_satele',trigger:{type:'after_mission',min:3},text:'A young Knight, Satele Shan, asks to join your strike teams. Her master, Kao Cen Darach, disagrees.',
  choices:[{label:'Take her',effects:{recruit:'satele_shan',loyalty:{seat:'darach',n:-10}}},{label:'Respect her master',effects:{loyalty:{seat:'darach',n:10}}}]},
 {id:'e1_prisoner_offer',trigger:{type:'stat',key:'intel',op:'>=',val:3},text:'A captured Imperial officer offers names of Republic traitors in exchange for a ship.',
  choices:[{label:'Deal',effects:{intel:2,favor:-1,flag:'e1_traitors'}},{label:'Hand him to the Navy',effects:{favor:1}},{label:'Make him talk',effects:{intel:3,unitDark:{who:'jedi_random',n:2}}}]}];
const COUNCIL_SEATS={gnost:{n:'Gnost-Dural',loyalty:60},darach:{n:'Kao Cen Darach',loyalty:60},zym:{n:'Grand Master Zym',loyalty:60}};

// Debrief / era-end lines (spec C §9: one line of result, one of cost).
const STORY_TEXT={
 bossWin:'You stopped the shuttle. The treaty was still signed in smoke.',
 bossLose:'Malgus reached the Temple steps before the Guard drove him off. The Temple is scarred: a wing lost a level.',
 ambush:'Your ambush was ready: Malgus lands already wounded.',
 eraWin:'The Temple stands. The Empire got its treaty, but not its lesson.',
 eraLose:'The Temple stands, scarred. The Senate wonders what the Jedi are for.',
 darkWarn:'The Order is drifting. Some Masters speak of a Dark Council.'};
// "What history changed" recap: flag → line.
const FLAG_LINES={e1_strike_known:'The envoy talked: you knew the strike was coming.',e1_ambush_ready:'You kept the warning inside the Order and set an ambush.',
 archive_backup:'A copy of the Archives sleeps on a hidden colony.',e1_traitors:'Names of Republic traitors sit in your files.',
 boss_or_won:'Darth Malgus fell at Docking Ring Nine.',temple_scarred:'The Temple was scarred. In canon it was sacked.'};

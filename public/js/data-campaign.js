/* Campaign data: classes, ranks, ability trees, wings, economy, the mission plan. Spec: docs/specs/campaign.md §5, combat.md §2 */
// Rank-1 stats per class. Rank gains above 1 come from RANK_GAIN (cumulative). Sentinel/Wayseeker paths: spec A §2.2.
const CLASS={
 Guardian:{jedi:1,hp:6,aim:75,mob:5,dmg:[4,6],range:1.5,deflect:35,dodge:10,guardDef:70,maxF:4,init:14,will:70,desc:'Front-line Jedi. Tough, protects allies, best at holding ground.'},
 Consular:{jedi:1,hp:5,aim:75,mob:5,dmg:[3,4],range:1.5,deflect:25,dodge:10,guardDef:50,maxF:4,init:12,will:75,desc:'Force support. Heals, shields and controls the fight.'},
 Sentinel:{jedi:1,hp:5,aim:75,mob:6,dmg:[4,5],range:1.5,deflect:30,dodge:15,guardDef:60,maxF:4,crit:10,init:15,will:70,desc:'Skirmisher Jedi. Fast, precise, finishes wounded enemies.'},
 Wayseeker:{jedi:1,hp:5,aim:72,mob:6,dmg:[3,5],range:1.5,deflect:30,dodge:15,guardDef:55,maxF:5,init:13,will:75,lockEra:3,desc:'Wandering Jedi who reshape the battlefield. Unlocks in the High Republic era.'},
 Soldier:{hp:9,armor:1,aim:70,mob:5,dmg:[4,6],range:8,init:10,will:55,desc:'Republic trooper. Reliable rifle, suppression and overwatch.'},
 Scout:{hp:7,armor:1,aim:80,mob:6,dmg:[5,7],range:11,crit:15,init:15,will:50,desc:'Long-range marksman. Marks targets and lands critical hits.'},
 Medic:{hp:8,armor:1,aim:65,mob:5,dmg:[3,4],range:6,kits:2,init:9,will:55,desc:'Field medic and tech. Revives the fallen and hacks consoles.'},
 Heavy:{hp:10,armor:2,aim:60,mob:4,dmg:[4,6],range:7,nades:2,init:7,will:60,desc:'Heavy weapons. Grenades, rockets and armor-shredding fire.'},
 // Tanks (Chat Q, wave 5; names invented [N]). Defender = Soresu-style Jedi who soaks hits; Shieldbearer = trooper in heavy plate with a riot shield.
 Defender:{jedi:1,hp:8,armor:1,aim:70,mob:4,dmg:[3,5],range:1.5,deflect:35,guardDef:85,maxF:4,init:10,will:80,desc:'Tank Jedi. Soresu defense: soaks hits, counters, shelters allies.'},
 Shieldbearer:{hp:12,armor:3,aim:65,mob:4,dmg:[3,5],range:6,init:8,will:70,desc:'Tank trooper. Heavy plate and a riot shield: holds the line, covers allies.'}};
// Stat rework (Jess, wave 5): troopers wear real armor and hit harder; Jedi are frailer but deflect and dodge (dodge = enemy aim −N, power.js).
// Always-known abilities per class (besides the Jedi/troop basics in campaign.js abilFor).
const BASE_KIT={Medic:['heal','scan','hack'],Heavy:['grenade'],Shieldbearer:['hunker']};
// Skill trees (trunk → 2 specializations at rank 3 → ranks 4–7) and cross-training live in data-trees.js.
// XP to reach each rank (spec B §5.1).
const RANKS=[{xp:0},{xp:30},{xp:80},{xp:160},{xp:280},{xp:450},{xp:700}];
// Stat gains on reaching a rank (ranks 2–3 match v0.2; 4–7 per spec B §5.1, trimmed so R7 isn't untouchable).
const RANK_GAIN={2:{hp:1,aim:5,will:3,jedi:{maxF:1}},3:{hp:1,aim:5,will:3,jedi:{deflect:10},troop:{kits:1,nades:1}},4:{hp:1,aim:5,will:3},
 5:{aim:5,will:3,jedi:{maxF:1}},6:{hp:1,will:3,troop:{kits:1,nades:1}},7:{aim:5,will:5,jedi:{deflect:10}}};
const XP={survive:10,kill:5,capture:8,story:10};
// Wings (spec B §2). cost[l] = price to reach level l. req[l] = research needed for that level. staff = bonus while a unit staffs the one slot.
const WINGS={
 medical:{n:'Medical Halls',cost:[0,150,200,350],req:[0,0,0,'bacta'],up:[0,10,15,15],eff:['Not built','Wounds heal 1.5× faster','Wounds heal 2× faster; grave wounds halved','Bacta tanks: wounds heal 2.5× faster; resting here treats one wound scar'],staff:'+25% healing speed',desc:'Heals wounds between missions. Assign wounded units to Recover here.'},
 training:{n:'Training Salle',cost:[0,150,250],req:[0,0,'curriculum'],up:[0,10,15],eff:['Not built','+10% XP from missions; bench units here to train','+20% XP from missions; training gives 2× XP'],staff:'+10% more XP from missions',desc:'Faster XP for the whole roster, and a place to train benched units.'},
 forge:{n:'Kyber Forge',cost:[0,200,300],up:[0,15,15],eff:['Not built','Craft tier 2 sabers','Craft tier 3 sabers (trait slot)'],staff:'Saber crafts cost 1 less Kyber',desc:'Crafts better lightsabers from Kyber crystals.'},
 armory:{n:'Armory',cost:[0,200,300],up:[0,15,15],eff:['Not built','Military blasters (T2, 1 mod), medium armor, utility gear','Elite blasters (T3, 2 mods), heavy armor'],staff:'Troop gear costs 20% less',desc:'Better blasters, armor, mods and utility gear.'},
 comms:{n:'Comms Hub',cost:[0,150],up:[0,10],eff:['Not built','See crisis rewards before you choose'],staff:'+1 Intel per month',desc:'Intelligence: see rewards in advance and gather Intel.'},
 archives:{n:'Archives',cost:[0,250,300],up:[0,10,10],eff:['Not built','Research one project at a time','Research 50% faster'],staff:'+25% research speed',desc:'Research: new gear, saber forms, abilities and wing upgrades.'},
 gardens:{n:'Meditation Gardens',cost:[0,150,250],up:[0,5,10],eff:['Not built','Meditating units shed stress fast; Jedi shed 1 Darkness a month','Meditation can also heal a trauma; Jedi shed 2 Darkness a month'],staff:'All units shed 5 more stress per mission; Order Darkness −1 a month',desc:'Removes stress and Darkness, and at level 2 treats traumas.'},
 barracks:{n:'Barracks',cost:[0,0,200,300],req:[0,0,0,'logistics'],up:[0,5,5,5],eff:['Not built','Roster cap 10','Roster cap 14','Roster cap 18'],cap:[0,10,14,18],staff:'+1 Recruit per month',desc:'Houses the roster. Higher levels raise the roster cap.'}};
const CAPTIVE=2;          // missions until an ignored captive escapes home on their own
const WOUND={light:3,serious:10,grave:40,graveL2:20};
const DAYS=15;            // days that pass per mission
const MISSION_CR=0.6;      // mission credit rewards × this (data.js rewards stay as written) [Tuned wave 3]
const STIPEND=[60,1.5];   // monthly Senate stipend = (a + b×Favor) × difficulty income. Spec B said 100+2×Favor; cut so credits stay tight [Tuned wave 3]
const TROOP_PAY=7,HIRE_COST=30,TRAIN_XP=12;   // TRAIN_XP = XP per mission period benched in the Training Salle [Default]
const START_RES={credits:500,intel:0,kyber:1,favor:50,recruits:2};
const START_ROSTER=[
 {n:'Kira Venn',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['saberThrow','leap'],col:'#62b3ff'},
 {n:'Tor Saalen',cls:'Consular',title:'Padawan',col:'#72e0a4'},
 {n:'Sgt. Rhal Dax',cls:'Soldier'},{n:'Ilsa Myr',cls:'Scout'},{n:'Doc Bren',cls:'Medic'},{n:'Grak Ordo',cls:'Heavy'}];
const RECRUIT_NAMES=['Bryn Kallo','Daro Vesk','Ina Quell','Mako Strand','Tal Reyes','Juno Pell','Ferra Dask','Oren Kade','Sev Morran','Lio Brask'];
// Crises offered on the galaxy list. Pick one; the others expire with their ignore penalty.
const CRISES={
 archive:{n:'Imperial listening post',kind:'Investigate',src:'Navy request',mission:'archive',text:'An Imperial post is reading our fleet traffic. Copy its data and get out.',ignore:{favor:-5}},
 sabotage:{n:'Strike the fuel depot',kind:'Sabotage',src:'Senate request',mission:'sabotage',text:'Blow the depot fuelling the Balmorra fleet. Plant 2 charges, then extract.',ignore:{favor:-8}},
 escort:{n:'Get the senator out',kind:'Escort',src:'Senate request',mission:'escort',text:'A senator marked for death must reach a shuttle across hostile ground.',ignore:{favor:-8}},
 rescue:{n:'Hostages at Ord Mantell',kind:'Rescue',src:'Senate request',mission:'rescue',
  text:'Sith raiders seized a Senate aide at a supply depot. The Senate wants her back.',ignore:{favor:-8}},
 shrine:{n:'Beast at the Dantooine shrine',kind:'Defend',src:'Civilian',mission:'shrine',
  text:'Pilgrims report Sith troopers, and something that hunts Jedi, closing on a kyber shrine.',ignore:{favor:-3,orderDark:4}}};
// v0.2a slice: S1 story → pick a crisis → S2 story. v0.2b adds Years pass and the Docking Ring Nine boss.
const PLAN=[{story:'relay'},{crises:['rescue','shrine','archive']},{story:'envoy'}];
const RES_NAMES={credits:'Credits',intel:'Intel',kyber:'Kyber',favor:'Senate Favor',recruits:'Recruits',orderDark:'Order Darkness'};

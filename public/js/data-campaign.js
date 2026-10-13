/* Campaign data: classes, ranks, ability kits, wings, economy, the v0.2a mission plan. Spec: docs/specs/campaign.md */
// Rank-1 stats per class. Each rank above 1: +1 HP, +5 aim; Jedi +1 max Focus at R2, +10 deflect at R3; troops +1 kit/grenade at R3.
const CLASS={
 Guardian:{jedi:1,hp:8,aim:75,mob:5,dmg:[4,6],range:1.5,deflect:20,guardDef:70,maxF:4,init:14},
 Consular:{jedi:1,hp:6,aim:75,mob:5,dmg:[3,4],range:1.5,deflect:10,guardDef:50,maxF:4,init:12},
 Soldier:{hp:7,aim:70,mob:5,dmg:[3,5],range:8,init:10},
 Scout:{hp:5,aim:80,mob:6,dmg:[4,6],range:11,crit:15,init:15},
 Medic:{hp:6,aim:65,mob:5,dmg:[2,3],range:6,kits:2,init:9},
 Heavy:{hp:8,aim:60,mob:4,dmg:[3,5],range:7,nades:2,init:7}};
// Rank 1 = always known. Ranks 2 and 3 = pick ONE of the two. Troop picks mix spec A abilities (temple-kits.js) and stat perks (PERKS in temple-data.js).
const KITS={
 Guardian:{1:['saberThrow','defLine'],2:['leap','reflectM'],3:['collapse','sweep']},
 Consular:{1:['stun','forceHeal'],2:['barrier','battleMed'],3:['mindTrick','forceRevive']},
 Soldier:{1:['suppress','hunker'],2:['rapidFire','flakVest'],3:['rally','veteran']},
 Scout:{1:['mark'],2:['deadeye','longshot'],3:['killshot','fieldcraft']},
 Medic:{1:['heal','smoke','hack','scan'],2:['reviveStim','fieldKit'],3:['combatMedic','traumaBag']},
 Heavy:{1:['grenade','suppress','shredder'],2:['bandolier','flakVest'],3:['rocket','juggernaut']}};
const RANKS=[{xp:0},{xp:30},{xp:80}];
const XP={survive:10,kill:5,capture:8,story:10};
// Wings (spec B §2). cost[l] = price to reach level l. staff = bonus while a unit is assigned to the wing's one staff slot.
const WINGS={
 medical:{n:'Medical Halls',cost:[0,150,200],up:[0,10,15],eff:['Not built','Wounds heal 1.5× faster','Wounds heal 2× faster; grave wounds halved'],staff:'+25% healing speed'},
 training:{n:'Training Salle',cost:[0,150],up:[0,10],eff:['Not built','+10% XP from missions; bench units here to train'],staff:'+10% more XP from missions'},
 forge:{n:'Kyber Forge',cost:[0,200,300],up:[0,15,15],eff:['Not built','Craft tier 2 sabers','Craft tier 3 sabers (trait slot)'],staff:'Saber crafts cost 1 less Kyber'},
 armory:{n:'Armory',cost:[0,200,300],up:[0,15,15],eff:['Not built','Military blasters (T2, 1 mod) and heavy armor','Elite blasters (T3, 2 mods)'],staff:'Troop gear costs 20% less'},
 comms:{n:'Comms Hub',cost:[0,150],up:[0,10],eff:['Not built','See crisis rewards before you choose'],staff:'+1 Intel per month'},
 barracks:{n:'Barracks',cost:[0,0,200,300],up:[0,5,5,5],eff:['Not built','Roster cap 10','Roster cap 14','Roster cap 18'],cap:[0,10,14,18],staff:'+1 Recruit per month'}};
const WOUND={light:3,serious:10,grave:40,graveL2:20};
const DAYS=15;            // days that pass per mission
const TROOP_PAY=5,HIRE_COST=30,TRAIN_XP=12;   // TRAIN_XP = XP per mission period benched in the Training Salle [Default]
const START_RES={credits:300,intel:0,kyber:1,favor:50,recruits:2};
const START_ROSTER=[
 {n:'Kira Venn',cls:'Guardian',title:'Knight',rank:2,xp:30,picks:['leap'],col:'#62b3ff'},
 {n:'Tor Saalen',cls:'Consular',title:'Padawan',col:'#72e0a4'},
 {n:'Sgt. Rhal Dax',cls:'Soldier'},{n:'Ilsa Myr',cls:'Scout'},{n:'Doc Bren',cls:'Medic'},{n:'Grak Ordo',cls:'Heavy'}];
const RECRUIT_NAMES=['Bryn Kallo','Daro Vesk','Ina Quell','Mako Strand','Tal Reyes','Juno Pell','Ferra Dask','Oren Kade','Sev Morran','Lio Brask'];
// Crises offered on the galaxy list. Pick one; the others expire with their ignore penalty.
const CRISES={
 rescue:{n:'Hostages at Ord Mantell',kind:'Rescue',src:'Senate request',mission:'rescue',
  text:'Sith raiders seized a Senate aide at a supply depot. The Senate wants her back.',ignore:{favor:-8}},
 shrine:{n:'Beast at the Dantooine shrine',kind:'Defend',src:'Civilian',mission:'shrine',
  text:'Pilgrims report Sith troopers, and something that hunts Jedi, closing on a kyber shrine.',ignore:{favor:-3,orderDark:4}}};
// v0.2a slice: S1 story → pick a crisis → S2 story. v0.2b adds Years pass and the Docking Ring Nine boss.
const PLAN=[{story:'relay'},{crises:['rescue','shrine']},{story:'envoy'}];
const RES_NAMES={credits:'Credits',intel:'Intel',kyber:'Kyber',favor:'Senate Favor',recruits:'Recruits',orderDark:'Order Darkness'};

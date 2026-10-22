/* Arsenal data (Coordinator, 2026-10-22): gear modules Mk I–III, slots by tier, the 5-branch research tree, unit evolution. Logic: arsenal.js.
   Jess 2026-10-22: slots grow by tier (3 → 5), gear evolves Mk I→III, tech evolves by era, units evolve; ~35 projects in 5 branches.
   Numbers are first pass [Default]. mk[i] = the stat bonus at Mk i+1 (replaces, not adds). Loads after temple-prog.js. */

// Slots: weapons, armor and sabers hold 3 modules at tier 1 rising to 5 at tier 3. "No armor" = a webbing harness with 2.
[3,4,5].forEach((n,i)=>{if(WEAPONS[i])WEAPONS[i].slots=n;if(SABERS[i])SABERS[i].slots=n});
WEAPONS[1].desc='+1 damage, 4 module slots.';WEAPONS[2].desc='+1 more damage, +5 aim, 5 module slots.';WEAPONS[0].desc='Issue rifle. 3 module slots.';
Object.assign(ARMOR,{
 beskar:{n:'Beskar plate',cost:140,who:'troop',res:'beskar',need:['armory',2],mod:{hp:2,armor:2,mob:-1},desc:'+2 HP, +2 armor, −1 move. Mandalorian iron.'},
 masterRobes:{n:'Master’s robes',cost:120,who:'jedi',res:'armMk3',mod:{hp:2,armor:1,will:10},desc:'+2 HP, +1 armor, +10 will.'}});
const ARMOR_SLOTS={none:2,light:3,robes:3,medium:4,armoredRobes:4,heavy:5,beskar:5,masterRobes:5};
for(const [k,a] of Object.entries(ARMOR))a.slots=ARMOR_SLOTS[k]||3;

// Module pools. who = troop | jedi (blank = anyone). res = research needed. need = [wing, level].
const W_MODS={
 scope:{n:'Scope',cost:25,mk:[{aim:8},{aim:10},{aim:14}]},
 barrel:{n:'Long barrel',cost:25,mk:[{range:2},{range:2,aim:3},{range:3,aim:5}]},
 cell:{n:'Power cell',cost:25,mk:[{dmgHi:1},{dmgHi:1,crit:5},{dmg:1,dmgHi:1}]},
 gyro:{n:'Gyro stabilizer',cost:30,need:['armory',1],mk:[{aim:3,will:5},{aim:5,will:10},{aim:8,will:10}]},
 stock:{n:'Stock',cost:30,res:'eliteMods',mk:[{aim:5,crit:5},{aim:8,crit:5},{aim:10,crit:10}]},
 trigger:{n:'Hair trigger',cost:30,res:'eliteMods',mk:[{crit:10},{crit:15},{crit:20}]},
 tibanna:{n:'Tibanna charger',cost:40,res:'tibanna',mk:[{dmg:1,aim:-5},{dmg:1},{dmg:1,crit:5}]},
 bipod:{n:'Bipod',cost:30,res:'tibanna',mk:[{aim:10,mob:-1},{aim:12,mob:-1},{aim:12}]}};
const AMODS={
 padding:{n:'Shock padding',cost:25,mk:[{hp:1},{hp:1,will:5},{hp:2}]},
 servos:{n:'Servo joints',cost:30,need:['armory',1],mk:[{dodge:3},{mob:1},{mob:1,dodge:5}]},
 damper:{n:'Neural damper',cost:25,mk:[{will:10},{will:15},{will:20,aim:3}]},
 bandolier:{n:'Bandolier',cost:30,who:'troop',mk:[{nades:1},{nades:1,aim:3},{nades:2}]},
 medpouch:{n:'Med pouch',cost:30,who:'troop',mk:[{kits:1},{kits:1,will:5},{kits:2}]},
 plating:{n:'Durasteel plates',cost:45,res:'alloys',mk:[{hp:1},{armor:1},{armor:1,hp:1}]},
 reflec:{n:'Reflec coating',cost:40,res:'reflec',mk:[{dodge:5},{dodge:8},{dodge:12}]},
 wards:{n:'Warding sigils',cost:40,res:'wards',mk:[{aimVsHorror:10},{aimVsHorror:15,will:5},{aimVsHorror:20,will:10}]}};
const SMODS={
 matrix:{n:'Crystal matrix',cost:30,mk:[{deflect:5},{deflect:8},{deflect:12}]},
 emitter:{n:'Focusing emitter',cost:30,mk:[{aim:5},{aim:8},{aim:10}]},
 grip:{n:'Balanced grip',cost:25,mk:[{dodge:5},{dodge:8},{dodge:10}]},
 swift:{n:'Lightweight hilt',cost:35,res:'ataru',mk:[{dodge:3},{mob:1},{mob:1,dodge:5}]},
 pearl:{n:'Krayt pearl',cost:45,res:'kyberLore',mk:[{will:10},{maxF:1},{maxF:1,will:10}]},
 dcell:{n:'Diatium cell',cost:40,res:'saberMk2',mk:[{dmgHi:1},{dmgHi:1,crit:5},{dmg:1,dmgHi:1}]},
 gate:{n:'Energy gate',cost:35,res:'saberMk2',mk:[{crit:5},{crit:10},{crit:15}]},
 shroud:{n:'Shroud ring',cost:35,res:'saberMk2',mk:[{guardDef:10},{guardDef:15},{guardDef:20}]}};
// The old 5 weapon mods keep their keys so saves and presets still work.
for(const k of Object.keys(MODS))delete MODS[k];Object.assign(MODS,W_MODS);
const MODPOOL={w:MODS,a:AMODS,s:SMODS};
const GFX_N={aim:'aim',dmg:'damage',dmgHi:'max damage',range:'range',crit:'% crit',hp:'HP',armor:'armor',mob:'move',dodge:'dodge',will:'will',
 deflect:'deflect',guardDef:'deflect on Guard',maxF:'max Focus',kits:'medkit',nades:'grenade',aimVsHorror:'aim vs horrors'};
const gfxTxt=m=>Object.entries(m||{}).map(([k,v])=>`${v>0?'+':'−'}${Math.abs(v)}${k==='crit'?'':' '}${GFX_N[k]||k}`).join(', ');
for(const P of Object.values(MODPOOL))for(const m of Object.values(P)){m.mod=m.mk[0];m.tip=gfxTxt(m.mk[0]);m.desc=`Mk I ${m.tip} · Mk II ${gfxTxt(m.mk[1])} · Mk III ${gfxTxt(m.mk[2])}.`}

// Gear evolution: Mk II and Mk III upgrades per gear line. Price is for each step (Armory staff discount applies).
const MK_RES={w:['gunMk2','gunMk3'],a:['armMk2','armMk3'],s:['saberMk2','saberMk3']};
const MK_COST=[0,40,90];   // to reach Mk II, Mk III
const MK_N=['','Mk I','Mk II','Mk III'];

// Research tree: 5 branches. era = earliest era it can start (tech evolves by era). Old keys keep their numbers.
Object.assign(RESEARCH,{
 tibanna:{n:'Tibanna gas chargers',days:15,cost:{credits:60},need:['eliteMods'],desc:'Unlocks the Tibanna charger and Bipod weapon modules.'},
 gunMk2:{n:'Refit line Mk II',days:20,cost:{credits:80},need:['eliteMods'],desc:'Weapon modules can be upgraded to Mk II.'},
 ordnance:{n:'Heavy ordnance',days:15,cost:{credits:60},need:['visors'],desc:'Every Heavy carries +1 grenade.'},
 eliteProgram:{n:'SpecForce program',days:25,cost:{credits:120,intel:2},need:['gunMk2'],desc:'Troopers at rank 4+ can evolve into an elite class.'},
 gunMk3:{n:'Refit line Mk III',days:25,cost:{credits:140},need:['gunMk2'],era:2,desc:'Weapon modules can be upgraded to Mk III.'},
 repeaters:{n:'Repeating blasters',days:30,cost:{credits:160,intel:2},need:['gunMk3'],era:3,desc:'Every trooper +1 damage.'},
 alloys:{n:'Durasteel alloys',days:15,cost:{credits:60},desc:'Unlocks the Durasteel plates armor module.'},
 reflec:{n:'Reflec coating',days:20,cost:{credits:80},need:['alloys'],desc:'Unlocks the Reflec coating armor module.'},
 armMk2:{n:'Armorsmith Mk II',days:20,cost:{credits:80},need:['alloys'],desc:'Armor modules can be upgraded to Mk II.'},
 beskar:{n:'Mandalorian iron',days:25,cost:{credits:120,intel:1},need:['armMk2'],desc:'Unlocks Beskar plate for troopers (Armory 2).'},
 armMk3:{n:'Armorsmith Mk III',days:25,cost:{credits:140},need:['armMk2'],era:2,desc:'Armor modules can be upgraded to Mk III. Unlocks Master’s robes for Jedi.'},
 saberMk2:{n:'Saber smithing Mk II',days:20,cost:{credits:80},need:['kyberLore'],desc:'Saber modules can be upgraded to Mk II. Unlocks Diatium cell, Energy gate and Shroud ring.'},
 saberMk3:{n:'Saber smithing Mk III',days:25,cost:{credits:140,intel:1},need:['saberMk2'],era:2,desc:'Saber modules can be upgraded to Mk III.'},
 wards:{n:'Force wards',days:20,cost:{credits:60,intel:1},need:['beastLore'],desc:'Unlocks the Warding sigils armor module.'},
 mastery:{n:'Trials of mastery',days:25,cost:{credits:100,intel:2},need:['holocron'],desc:'Jedi at rank 4+ can evolve into an advanced path.'},
 livingForce:{n:'The Living Force',days:25,cost:{credits:100,intel:2},need:['mastery'],era:2,desc:'Every Jedi +10 will and +5 deflect.'},
 namelessLore:{n:'Nameless studies',days:30,cost:{credits:120,intel:3},need:['wards'],era:3,desc:'+10 more aim against horrors for every unit.'},
 supply:{n:'Supply contracts',days:20,cost:{credits:120},need:['logistics'],era:2,desc:'All gear and modules cost 15% less.'},
 holonet:{n:'Holonet relays',days:25,cost:{credits:100,intel:2},need:['codebreak'],era:3,desc:'+1 Intel after every won mission.'}});
const RES_TREE=[
 {n:'Weapons',ic:'shoot',ids:['eliteMods','visors','tibanna','gunMk2','ordnance','eliteProgram','gunMk3','repeaters']},
 {n:'Armor',ic:'hunker',ids:['armorWeave','alloys','shields','reflec','armMk2','beskar','armMk3']},
 {n:'Lightsabers',ic:'kyber',ids:['kyberLore','ataru','djemSo','saberMk2','niman','juyo','saberMk3']},
 {n:'Force',ic:'calm',ids:['curriculum','beastLore','holocron','wards','mastery','livingForce','namelessLore']},
 {n:'Logistics',ic:'scan',ids:['fieldMed','codebreak','logistics','bacta','sithTactics','supply','holonet']}];

// Unit evolution: rank 4+, one-time, permanent. Names invented [N] unless noted; SpecForce = Republic special forces in SWTOR (Legends, Med confidence).
const EVO={
 Guardian:{n:'Battlemaster',mod:{hp:1,dmg:1,deflect:10}},Consular:{n:'Jedi Seer',mod:{maxF:1,will:15,aim:5}},
 Sentinel:{n:'Shadow',mod:{crit:10,mob:1,dodge:5}},Wayseeker:{n:'Pathwalker',mod:{mob:1,maxF:1,dodge:5}},Defender:{n:'Bulwark',mod:{hp:1,armor:1,guardDef:15}},
 Soldier:{n:'SpecForce Commando',mod:{hp:1,aim:5,dmg:1}},Scout:{n:'Recon Ace',mod:{aim:5,crit:10,range:1}},Medic:{n:'Field Surgeon',mod:{kits:1,hp:1,will:10}},
 Heavy:{n:'Siege Trooper',mod:{nades:1,armor:1,dmgHi:1}},Shieldbearer:{n:'Vanguard',mod:{hp:2,armor:1}}};
for(const e of Object.values(EVO))e.desc=gfxTxt(e.mod)+'.';
const EVO_RANK=4,EVO_COST={credits:150,intel:2};

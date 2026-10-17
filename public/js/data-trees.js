/* Skill trees (Chat F · Skill Trees, 2026-10-16). Spec: docs/specs/trees.md.
   Shape per class: trunk ranks 1–2 (pick 1 of 2) → rank 3 picks one of two specializations (its signature skill comes with it,
   permanent) → ranks 4–7 pick 1 of 2 inside that spec. Cross-training (multiclass) borrows trunk skills from a second class.
   Ids live in AB (abilities) or PERKS (stat picks). Tune here.
   Lore: Sage/Shadow (Consular) and Vanguard (Trooper) = SWTOR advanced classes [S, High]. Weapon Master/Watchman = KotOR II
   prestige classes [S, High]. Other spec names are invented for the game [N]. */

// New stat picks for the spec branches. Every entry has a one-sentence mechanical desc.
Object.assign(PERKS,{
 gAegis:{name:'Aegis',ic:'guard',desc:'+2 HP, +10 Guard deflect and +10 will.',mod:{hp:2,guardDef:10,will:10}},
 gLastStand:{name:'Last Stand',ic:'hunker',desc:'+4 HP.',mod:{hp:4}},
 gWMFocus:{name:'Blade Focus',ic:'strike',desc:'+1 damage and +10 aim.',mod:{dmg:1,aim:10}},
 gWMStorm:{name:'Bladestorm',ic:'sweep',desc:'+1 damage, +1 move and +15% crit chance.',mod:{dmg:1,mob:1,crit:15}},
 cSageLight:{name:'Inner Light',ic:'meditate',desc:'+2 HP, +10 will and +5 deflect.',mod:{hp:2,will:10,deflect:5}},
 cSageEmpathy:{name:'Empathy',ic:'medic',desc:'+1 max Focus and +2 HP.',mod:{maxF:1,hp:2}},
 cSageAvatar:{name:'Vessel of the Force',ic:'meditate',desc:'+2 max Focus.',mod:{maxF:2}},
 cShWhisper:{name:'Whisper Strike',ic:'strike',desc:'+10 aim and +10% crit chance.',mod:{aim:10,crit:10}},
 cShVeil:{name:'Shadow Veil',ic:'conceal',desc:'+1 move and +15 deflect.',mod:{mob:1,deflect:15}},
 cShMaster:{name:'Master of Shadows',ic:'strike',desc:'+2 damage and +1 max Focus.',mod:{dmg:2,maxF:1}},
 sWatchSense:{name:'Watchful',ic:'mark',desc:'+15 aim and +10 will.',mod:{aim:15,will:10}},
 sWatchJudge:{name:'Judgment',ic:'strike',desc:'+2 damage and +15% crit chance.',mod:{dmg:2,crit:15}},
 sDancer:{name:'Dancer',ic:'leap',desc:'+1 move and +10 deflect.',mod:{mob:1,deflect:10}},
 sDanceFlow:{name:'Flow',ic:'flurry',desc:'+5 aim and +15% crit chance.',mod:{aim:5,crit:15}},
 sDanceWhirl:{name:'Whirlwind',ic:'sweep',desc:'+1 damage and +1 move.',mod:{dmg:1,mob:1}},
 sDanceStorm:{name:'Storm of Blades',ic:'flurry',desc:'+2 damage and +1 move.',mod:{dmg:2,mob:1}},
 wBeastHide:{name:'Thick Hide',ic:'hunker',desc:'+2 HP and +1 armor.',mod:{hp:2,armor:1}},
 wBeastPack:{name:'Pack Sense',ic:'mark',desc:'+10 aim and +10 will.',mod:{aim:10,will:10}},
 wBeastKing:{name:'Lord of Beasts',ic:'strike',desc:'+3 HP and +1 damage.',mod:{hp:3,dmg:1}},
 wEarthRoot:{name:'Rooted',ic:'guard',desc:'+1 armor and +10 will.',mod:{armor:1,will:10}},
 wEarthStone:{name:'Stoneskin',ic:'hunker',desc:'+2 HP and +5 deflect.',mod:{hp:2,deflect:5}},
 wEarthReach:{name:'Long Reach',ic:'pull',desc:'+1 max Focus and +10 aim.',mod:{maxF:1,aim:10}},
 wEarthWorld:{name:'One with the World',ic:'meditate',desc:'+2 max Focus and +1 armor.',mod:{maxF:2,armor:1}},
 soSgtDrill:{name:'Drill Sergeant',ic:'guard',desc:'+5 aim, +1 HP and +10 will.',mod:{aim:5,hp:1,will:10}},
 soSgtHero:{name:'Hero of the Line',ic:'hunker',desc:'+3 HP, +1 armor and +20 will.',mod:{hp:3,armor:1,will:20}},
 soVanCharge:{name:'Charge',ic:'dash',desc:'+1 move and +1 damage.',mod:{mob:1,dmg:1}},
 soVanPlate:{name:'Assault Plate',ic:'hunker',desc:'+1 armor and +2 HP.',mod:{armor:1,hp:2}},
 soVanShred:{name:'Point Blank',ic:'shoot',desc:'+1 damage and +10% crit chance.',mod:{dmg:1,crit:10}},
 soVanStorm:{name:'Stormbreaker',ic:'shoot',desc:'+2 damage and +1 move.',mod:{dmg:2,mob:1}},
 scSnStill:{name:'Stillness',ic:'mark',desc:'+10 aim and +2 range.',mod:{aim:10,range:2}},
 scSnOneShot:{name:'One Shot',ic:'shoot',desc:'+2 damage and +20% crit chance.',mod:{dmg:2,crit:20}},
 scInfShadow:{name:'Slip Away',ic:'conceal',desc:'+1 move and +15% crit chance.',mod:{mob:1,crit:15}},
 scInfKnife:{name:'Close Work',ic:'shoot',desc:'+1 damage and +10 aim.',mod:{dmg:1,aim:10}},
 scInfPhantom:{name:'Phantom',ic:'dash',desc:'+2 move and +2 HP.',mod:{mob:2,hp:2}},
 scInfStrike:{name:'First Strike',ic:'shoot',desc:'+2 damage and +1 move.',mod:{dmg:2,mob:1}},
 mSurgCalm:{name:'Calm Hands',ic:'medic',desc:'+2 HP and +20 will.',mod:{hp:2,will:20}},
 mSurgMiracle:{name:'Miracle Worker',ic:'medic',desc:'+3 medkits.',mod:{kits:3}},
 mTechArmor:{name:'Rigged Armor',ic:'hunker',desc:'+1 armor and +1 HP.',mod:{armor:1,hp:1}},
 mTechOverclock:{name:'Overclocked Blaster',ic:'shoot',desc:'+10 aim and +1 damage.',mod:{aim:10,dmg:1}},
 mTechDrones:{name:'Drone Swarm',ic:'drone',desc:'+2 medkits and +1 armor.',mod:{kits:2,armor:1}},
 hDemoExtra:{name:'Extra Charges',ic:'grenade',desc:'+1 grenade and +1 range.',mod:{nades:1,range:1}},
 hDemoBlast:{name:'Shaped Charges',ic:'grenade',desc:'+1 damage and +1 grenade.',mod:{dmg:1,nades:1}},
 hDemoSapper:{name:'Sapper',ic:'grenade',desc:'+2 grenades.',mod:{nades:2}},
 hDemoBig:{name:'Big Gun',ic:'shoot',desc:'+2 damage and +1 range.',mod:{dmg:2,range:1}},
 hBulTaunt:{name:'Draw Fire',ic:'guard',desc:'+2 HP and +20 will.',mod:{hp:2,will:20}},
 hBulFort:{name:'Fortress',ic:'hunker',desc:'+2 armor and +2 HP.',mod:{armor:2,hp:2}}});

// trunk: ranks 1–2. specs: two per class; sig = rank-3 skill that comes with the spec; 4–7 = pick 1 of 2.
const TREES={
 Guardian:{trunk:{1:['saberThrow','defLine'],2:['leap','reflectM']},specs:{
  protector:{n:'Protector',ic:'guard',desc:'Shields the squad and holds the line.',sig:'barrier',4:['gIron','gBulwark'],5:['collapse','gWarden'],6:['forceWave','gAegis'],7:['gUnbreakable','gLastStand']},
  weaponMaster:{n:'Weapon Master',ic:'strike',desc:'Lives in melee and cuts through crowds.',sig:'sweep',4:['gDuelist','gVanguard'],5:['mightyBlow','flurry'],6:['precisionStrike','gWMFocus'],7:['gMasterBlade','gWMStorm']}}},
 Consular:{trunk:{1:['stun','forceHeal'],2:['barrier','battleMed']},specs:{
  sage:{n:'Sage',ic:'medic',desc:'Healer. Keeps everyone standing.',sig:'forceRevive',4:['massHeal','cResolve'],5:['cWellspring','cSageLight'],6:['cSeer','cSageEmpathy'],7:['cMaster','cSageAvatar']},
  shadow:{n:'Shadow',ic:'conceal',desc:'Controls minds and strikes unseen.',sig:'mindTrick',4:['pull','shadowStep'],5:['forceWave','cShWhisper'],6:['stasisField','cShVeil'],7:['cShMaster','disarm']}}},
 Sentinel:{trunk:{1:['flurry','sense'],2:['shadowStep','sExecutioner']},specs:{
  watchman:{n:'Watchman',ic:'mark',desc:'Hunter and investigator. Finishes the wounded.',sig:'executioner',4:['disarm','sHunter'],5:['sGhost','sWatchSense'],6:['precisionStrike','spotter'],7:['sUntouchable','sWatchJudge']},
  bladeDancer:{n:'Blade Dancer',ic:'flurry',desc:'Fast, mobile, always moving.',sig:'saberThrow',4:['sEdge','sDancer'],5:['sweep','sDanceFlow'],6:['leap','sDanceWhirl'],7:['sBlademaster','sDanceStorm']}}},
 Wayseeker:{trunk:{1:['pathfinder','wildBond'],2:['tremor','barrier']},specs:{
  beastwarden:{n:'Beastwarden',ic:'calm',desc:'Tames creatures and horrors.',sig:'beastCalm',4:['wStalker','forceHeal'],5:['wBond','wBeastHide'],6:['wSeer','wBeastPack'],7:['wPrimal','wBeastKing']},
  earthshaper:{n:'Earthshaper',ic:'tremor',desc:'Bends the ground and drags enemies around.',sig:'pull',4:['saberThrow','wEarthRoot'],5:['forceWave','wEarthStone'],6:['collapse','wEarthReach'],7:['stasisField','wEarthWorld']}}},
 Soldier:{trunk:{1:['suppress','hunker'],2:['rapidFire','flakVest']},specs:{
  sergeant:{n:'Sergeant',ic:'guard',desc:'Leader. Rallies and steadies the squad.',sig:'rally',4:['holdLine','soSteel'],5:['mark','soSgtDrill'],6:['smoke','soTough'],7:['soCommander','soSgtHero']},
  vanguard:{n:'Vanguard',ic:'dash',desc:'Assault trooper. Closes in and hits hard.',sig:'chainShot',4:['veteran','soVanCharge'],5:['soMarksman','soVanPlate'],6:['runGun','soVanShred'],7:['soLegend','soVanStorm']}}},
 Scout:{trunk:{1:['mark','scEagle'],2:['deadeye','longshot']},specs:{
  sniper:{n:'Sniper',ic:'mark',desc:'Long range. One shot, one kill.',sig:'spotter',4:['killshot','scSniper'],5:['scAssassin','scSnStill'],6:['scDeadly','chainShot'],7:['scLegend','scSnOneShot']},
  infiltrator:{n:'Infiltrator',ic:'conceal',desc:'Moves unseen and strikes first.',sig:'runGun',4:['fieldcraft','ghost'],5:['scSurvivor','scInfShadow'],6:['smoke','scInfKnife'],7:['scInfPhantom','scInfStrike']}}},
 Medic:{trunk:{1:['smoke','mDrilled'],2:['reviveStim','fieldKit']},specs:{
  surgeon:{n:'Field Surgeon',ic:'medic',desc:'Saves lives. More kits, steadier hands.',sig:'medBeacon',4:['traumaBag','mSurgeon'],5:['mStoic','mFieldSurgeon'],6:['rally','mSurgCalm'],7:['mAngel','mSurgMiracle']},
  tech:{n:'Combat Tech',ic:'drone',desc:'Drones, armor and a sharper blaster.',sig:'shieldDrone',4:['combatMedic','mTechArmor'],5:['mMarksman','mark'],6:['suppress','mTechOverclock'],7:['mVeteran','mTechDrones']}}},
 Heavy:{trunk:{1:['suppress','shredder'],2:['bandolier','flakVest']},specs:{
  demolitionist:{n:'Demolitionist',ic:'grenade',desc:'Explosives expert. Rockets and more grenades.',sig:'rocket',4:['ionNade','hDemoExtra'],5:['hHeavyWeapons','hDemoBlast'],6:['hGunner','hDemoSapper'],7:['hWarlord','hDemoBig']},
  bulwark:{n:'Bulwark',ic:'hunker',desc:'Walking cover. Soaks fire and holds ground.',sig:'holdLine',4:['juggernaut','hBrute'],5:['hBulwark','hunker'],6:['chainShot','hBulTaunt'],7:['hTitan','hBulFort']}}}};

// Cross-training (multiclass). Free, gated by the Training Salle: L1 = 1 borrowed skill from rank 4, L2 = a 2nd from rank 6.
// Jedi may cross-train in any class; troops only in other troop classes (no Force). Borrowable = the second class's trunk (ranks 1–2).
// NOGUN: troop skills that need a blaster or kits, so a Jedi can't borrow them.
const XTRAIN={minRank:[4,6],noGun:['suppress','rapidFire','deadeye','longshot','scEagle','bandolier','reviveStim','fieldKit']};

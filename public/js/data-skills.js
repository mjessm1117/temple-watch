/* Skills overhaul (Chat Q, wave 5). Loads after data-trees.js. Engine for fx: power.js. Spend/UI: skills.js. Spec: docs/specs/trees.md §Skill points.
   - Skill points (SP): buy a second (or third) option at any rank you've already picked. Units start with SKILL.start SP,
     earn 1 per SKILL.xpPer XP, 1 per veteran rank (8–10), 1 at bond levels in SKILL.bond.
   - Every rank now offers 3 choices: the third is a mechanic, not a stat bump.
   - fx = combat effects applied in power.js (numbers add up across skills):
     openAim/openDmg first hit each mission · lowAim/lowDmg at half HP or less · closeAim/closeDmg within 4 · farAim/farDmg 7+ away
     expAim/expDmg vs targets out of cover · eliteAim/eliteDmg vs elites and bosses · adjAim with an ally adjacent · auraAim allies within 3 (you too)
     dodge enemies −aim vs you · ward adjacent allies take −1 damage · riposte melee attackers take N · lastStand survive one killing blow at 1 HP
     regen +HP each turn · focusStart Focus at mission start · healPlus heals +N · nadeDmg grenades/rockets +N
     killFocus/killHeal/killMove/killDmg on a kill (move cap +2, damage cap +3 per mission)
     chain = kills refund 1 action, up to N times a turn (chainMelee: melee kills only · chainFar: kills 5+ tiles away only) */
const SKILL={start:1,xpPer:80,vet:1,bond:[4,8],chainR:5};
// Veteran ranks 8–10: no new tree row; each gives a stat bump and a skill point to finish the tree.
RANKS.push({xp:1000},{xp:1350},{xp:1750});
Object.assign(RANK_GAIN,{8:{hp:1,will:5},9:{aim:5,will:5},10:{hp:1,will:5,jedi:{maxF:1},troop:{kits:1,nades:1}}});

const FX_N={openAim:'First hit aim',openDmg:'First hit dmg',lowAim:'Aim when hurt',lowDmg:'Dmg when hurt',closeAim:'Aim ≤4 tiles',closeDmg:'Dmg ≤4 tiles',
 farAim:'Aim 7+ tiles',farDmg:'Dmg 7+ tiles',expAim:'Aim vs no cover',expDmg:'Dmg vs no cover',eliteAim:'Aim vs elites',eliteDmg:'Dmg vs elites',adjAim:'Aim beside ally',
 auraAim:'Squad aim (3 tiles)',dodge:'Dodge',ward:'Ward allies',riposte:'Counter',lastStand:'Last stand',regen:'Regen/turn',focusStart:'Start Focus',healPlus:'Heals',
 nadeDmg:'Blast dmg',killFocus:'Focus per kill',killHeal:'Heal per kill',killMove:'Move per kill',killDmg:'Dmg per kill',chain:'Chain kills',chainMelee:'Melee chain',chainFar:'Sniper chain'};

// Third options. Ids are new; ic from icons.js.
Object.assign(PERKS,{
 // trunks
 gChallenge:{name:'Riposte',ic:'strike',desc:'Enemies that hit you in melee take 1 damage. +5 Guard.',mod:{guardDef:5},fx:{riposte:1}},
 gStalwart:{name:'Stalwart',ic:'guard',desc:'Once per mission, a killing blow leaves you at 1 HP instead. +1 HP.',mod:{hp:1},fx:{lastStand:1}},
 cSerene:{name:'Serene',ic:'meditate',desc:'Start missions with +1 Focus. Your heals restore +1 HP.',fx:{focusStart:1,healPlus:1}},
 cPresence:{name:'Presence',ic:'sense',desc:'You and allies within 3 tiles get +5 aim.',fx:{auraAim:5}},
 sSwift:{name:'Swift Kill',ic:'dash',desc:'Each kill gives +1 move for the mission (max +2).',fx:{killMove:1}},
 sHunterMark:{name:'Hunter’s Mark',ic:'mark',desc:'+15 aim and +1 damage against elites and bosses.',fx:{eliteAim:15,eliteDmg:1}},
 wLiving:{name:'Living Force',ic:'meditate',desc:'Regain 1 HP at the start of each turn.',fx:{regen:1}},
 wWind:{name:'Wind-walker',ic:'leap',desc:'+1 move. Enemies get −10 aim against you.',mod:{mob:1},fx:{dodge:10}},
 soBreach:{name:'Breach',ic:'shoot',desc:'Your first hit each mission: +15 aim, +2 damage.',fx:{openAim:15,openDmg:2}},
 soAdrenaline:{name:'Adrenaline',ic:'st_dmg',desc:'At half HP or less: +10 aim and +1 damage.',fx:{lowAim:10,lowDmg:1}},
 scFlanker:{name:'Flanker',ic:'shoot',desc:'+10 aim and +1 damage against targets out of cover.',fx:{expAim:10,expDmg:1}},
 scEvasive:{name:'Evasive',ic:'conceal',desc:'Enemies get −15 aim against you.',fx:{dodge:15}},
 mTriage:{name:'Triage Kit',ic:'medic',desc:'+1 medkit. Your heals restore +1 HP.',mod:{kits:1},fx:{healPlus:1}},
 mHardy:{name:'Hard to Kill',ic:'guard',desc:'Once per mission, a killing blow leaves you at 1 HP instead.',fx:{lastStand:1}},
 hCoverMe:{name:'Cover Me',ic:'guard',desc:'Allies next to you take 1 less damage.',fx:{ward:1}},
 hPayload:{name:'Payload',ic:'grenade',desc:'+1 grenade. Grenades and rockets deal +1 damage.',mod:{nades:1},fx:{nadeDmg:1}},
 // Guardian
 gpBastion:{name:'Bastion',ic:'guard',desc:'Allies next to you take 1 less damage. +1 HP.',mod:{hp:1},fx:{ward:1}},
 gpBeacon:{name:'Beacon of the Order',ic:'sense',desc:'You and allies within 3 tiles get +5 aim. +10 will.',mod:{will:10},fx:{auraAim:5}},
 gpUndying:{name:'Undying',ic:'meditate',desc:'Survive one killing blow at 1 HP; regain 1 HP each turn.',fx:{lastStand:1,regen:1}},
 gpLiving:{name:'Living Shield',ic:'guard',desc:'Enemies −15 aim against you; allies next to you take 1 less damage.',fx:{dodge:15,ward:1}},
 gwForm:{name:'Opening Form',ic:'strike',desc:'Your first hit each mission: +20 aim, +2 damage.',fx:{openAim:20,openDmg:2}},
 gwWind:{name:'Second Wind',ic:'medic',desc:'Each kill heals you 2.',fx:{killHeal:2}},
 gwCounter:{name:'Counter-cut',ic:'strike',desc:'Enemies that hit you in melee take 2 damage.',fx:{riposte:2}},
 gwRampage:{name:'Rampage',ic:'sweep',desc:'Melee kills refund an action, up to 3 times a turn. Each kill +1 damage (max +3).',fx:{chainMelee:3,killDmg:1}},
 // Consular
 csTouch:{name:'Healing Touch',ic:'medic',desc:'Heals restore +1 HP. Start missions with +1 Focus.',fx:{healPlus:1,focusStart:1}},
 csCalm:{name:'Calm Center',ic:'meditate',desc:'You and allies within 3 tiles get +5 aim. +10 will.',mod:{will:10},fx:{auraAim:5}},
 csWard:{name:'Warding Light',ic:'guard',desc:'Allies next to you take 1 less damage.',fx:{ward:1}},
 csEternal:{name:'Light Eternal',ic:'meditate',desc:'Survive one killing blow at 1 HP. Start missions with +2 Focus.',fx:{lastStand:1,focusStart:2}},
 chUnseen:{name:'Unseen Strike',ic:'strike',desc:'Your first hit each mission: +20 aim, +3 damage.',fx:{openAim:20,openDmg:3}},
 chFade:{name:'Fade',ic:'conceal',desc:'Enemies get −15 aim against you.',fx:{dodge:15}},
 chFeed:{name:'Feed on Fear',ic:'mark',desc:'Each kill restores 2 Focus.',fx:{killFocus:2}},
 chCascade:{name:'Cascade',ic:'stunned',desc:'Kills refund an action, up to 2 times a turn. +15 aim, +2 damage vs elites.',fx:{chain:2,eliteAim:15,eliteDmg:2}},
 // Sentinel
 swTrack:{name:'Tracker',ic:'mark',desc:'+15 aim and +1 damage against targets out of cover.',fx:{expAim:15,expDmg:1}},
 swNerve:{name:'Steel Nerve',ic:'guard',desc:'At half HP or less: +15 aim and +1 damage. +10 will.',mod:{will:10},fx:{lowAim:15,lowDmg:1}},
 swDuel:{name:'Duelist’s Eye',ic:'strike',desc:'+10 aim and +2 damage against elites and bosses.',fx:{eliteAim:10,eliteDmg:2}},
 swInquis:{name:'Inquisitor',ic:'sense',desc:'+15 aim vs Force users, +20 vs horrors. Kills refund an action, once a turn.',aimVs:{force:15,horror:20},fx:{chain:1}},
 sbBlur:{name:'Blur',ic:'leap',desc:'Enemies get −15 aim against you.',fx:{dodge:15}},
 sbCombo:{name:'Combo',ic:'flurry',desc:'Each kill: +1 damage for the mission (max +3).',fx:{killDmg:1}},
 sbRiposte:{name:'Riposte Dance',ic:'strike',desc:'Enemies that hit you in melee take 2 damage.',fx:{riposte:2}},
 sbStorm:{name:'Whirling Rampage',ic:'sweep',desc:'Melee kills refund an action, up to 3 times a turn; each kill heals 1.',fx:{chainMelee:3,killHeal:1}},
 // Wayseeker
 wbPack:{name:'Pack Hunter',ic:'mark',desc:'+10 aim when an ally is next to you.',fx:{adjAim:10}},
 wbHide:{name:'Mending Hide',ic:'hunker',desc:'Regain 1 HP at the start of each turn.',fx:{regen:1}},
 wbHowl:{name:'Rallying Howl',ic:'sense',desc:'You and allies within 3 tiles get +5 aim.',fx:{auraAim:5}},
 wbAlpha:{name:'Alpha',ic:'strike',desc:'Kills refund an action, up to 2 times a turn; each kill heals 2.',fx:{chain:2,killHeal:2}},
 weFault:{name:'Fault Line',ic:'tremor',desc:'+2 damage against targets out of cover.',fx:{expDmg:2}},
 weStone:{name:'Stone Ward',ic:'guard',desc:'Allies next to you take 1 less damage.',fx:{ward:1}},
 weAnchor:{name:'Anchored',ic:'hunker',desc:'Survive one killing blow at 1 HP.',fx:{lastStand:1}},
 weMountain:{name:'The Mountain',ic:'guard',desc:'Enemies −10 aim against you; regain 1 HP each turn.',fx:{dodge:10,regen:1}},
 // Soldier
 sgCover:{name:'Cover Formation',ic:'guard',desc:'Allies next to you take 1 less damage.',fx:{ward:1}},
 sgOrders:{name:'Orders',ic:'mark',desc:'You and allies within 3 tiles get +5 aim.',fx:{auraAim:5}},
 sgStand:{name:'Last Man Standing',ic:'hunker',desc:'Survive one killing blow at 1 HP.',fx:{lastStand:1}},
 sgVictory:{name:'Lead from the Front',ic:'shoot',desc:'Kills refund an action, once a turn. Each kill heals 2. +20 will.',mod:{will:20},fx:{chain:1,killHeal:2}},
 svRush:{name:'Momentum',ic:'dash',desc:'Each kill gives +1 move for the mission (max +2).',fx:{killMove:1}},
 svBrawl:{name:'Brawler',ic:'strike',desc:'Enemies that hit you in melee take 2 damage.',fx:{riposte:2}},
 svFury:{name:'Fury',ic:'st_dmg',desc:'At half HP or less: +2 damage.',fx:{lowDmg:2}},
 svRampage:{name:'Rampage',ic:'shoot',desc:'Kills within 4 tiles refund an action, up to 3 times a turn.',fx:{chainMelee:3,closeAim:5}},
 // Scout
 ssPerch:{name:'Perch',ic:'mark',desc:'+10 aim and +1 damage against targets 7+ tiles away.',fx:{farAim:10,farDmg:1}},
 ssExposed:{name:'Exposed',ic:'shoot',desc:'+2 damage against targets out of cover.',fx:{expDmg:2}},
 ssBigGame:{name:'Big Game',ic:'mark',desc:'+15 aim and +2 damage against elites and bosses.',fx:{eliteAim:15,eliteDmg:2}},
 ssStreak:{name:'Back to Back',ic:'shoot',desc:'Kills 5+ tiles away refund an action, up to 3 times a turn. First shot each mission +20 aim.',fx:{chainFar:3,openAim:20}},
 siVanish:{name:'Vanish',ic:'conceal',desc:'Enemies get −15 aim against you.',fx:{dodge:15}},
 siKnife:{name:'Knife Work',ic:'strike',desc:'+15 aim and +1 damage within 4 tiles.',fx:{closeAim:15,closeDmg:1}},
 siHunt:{name:'Hunter',ic:'dash',desc:'Each kill: +1 move (max +2) and heal 1.',fx:{killMove:1,killHeal:1}},
 siSabo:{name:'Saboteur',ic:'grenade',desc:'+20 aim against droids. Grenades +1 damage. Kills refund an action, once a turn.',aimVs:{droid:20},fx:{nadeDmg:1,chain:1}},
 // Medic
 mdHands:{name:'Steady Hands',ic:'medic',desc:'Your heals restore +1 HP.',fx:{healPlus:1}},
 mdCover:{name:'Medical Cover',ic:'guard',desc:'Allies next to you take 1 less damage.',fx:{ward:1}},
 mdLast:{name:'Not Today',ic:'hunker',desc:'Survive one killing blow at 1 HP.',fx:{lastStand:1}},
 mdMiracle:{name:'Miracle',ic:'medic',desc:'+1 medkit. Your heals restore +2 HP.',mod:{kits:1},fx:{healPlus:2}},
 mtDroid:{name:'Droid Breaker',ic:'shoot',desc:'+20 aim against droids.',aimVs:{droid:20}},
 mtPlate:{name:'Deflector Plate',ic:'hunker',desc:'+1 armor. Enemies get −10 aim against you.',mod:{armor:1},fx:{dodge:10}},
 mtOver:{name:'Overcharge',ic:'shoot',desc:'+2 damage against targets out of cover.',fx:{expDmg:2}},
 mtNet:{name:'Tactical Net',ic:'drone',desc:'You and allies within 3 tiles get +5 aim; allies next to you take 1 less damage.',fx:{auraAim:5,ward:1}},
 // Heavy
 hdHeavy:{name:'Heavy Ordnance',ic:'grenade',desc:'Grenades and rockets deal +1 damage.',fx:{nadeDmg:1}},
 hdShock:{name:'Shockwave',ic:'grenade',desc:'+1 range; +1 damage against targets out of cover.',mod:{range:1},fx:{expDmg:1}},
 hdBuster:{name:'Bunker Buster',ic:'shoot',desc:'+2 damage against elites and bosses.',fx:{eliteDmg:2}},
 hdArmageddon:{name:'Armageddon',ic:'grenade',desc:'+2 grenades; blasts +1 damage. Kills refund an action, once a turn.',mod:{nades:2},fx:{nadeDmg:1,chain:1}},
 hbWall:{name:'Wall',ic:'guard',desc:'Allies next to you take 1 less damage.',fx:{ward:1}},
 hbSpite:{name:'Spite',ic:'strike',desc:'Enemies that hit you in melee take 2 damage.',fx:{riposte:2}},
 hbIron:{name:'Iron Will',ic:'hunker',desc:'Survive one killing blow at 1 HP; regain 1 HP each turn.',fx:{lastStand:1,regen:1}},
 hbAnchor:{name:'Anchor',ic:'guard',desc:'+1 armor. You and allies within 3 tiles get +5 aim.',mod:{armor:1},fx:{auraAim:5}}});

// Put the third option on every trunk rank (1–2) and spec rank (4–7). Order = [rank 1, rank 2] for trunks, [4,5,6,7] for specs.
(function(){const T3={Guardian:['gChallenge','gStalwart'],Consular:['cSerene','cPresence'],Sentinel:['sSwift','sHunterMark'],Wayseeker:['wLiving','wWind'],
 Soldier:['soBreach','soAdrenaline'],Scout:['scFlanker','scEvasive'],Medic:['mTriage','mHardy'],Heavy:['hCoverMe','hPayload']};
 const S3={protector:['gpBastion','gpBeacon','gpUndying','gpLiving'],weaponMaster:['gwForm','gwWind','gwCounter','gwRampage'],
  sage:['csTouch','csCalm','csWard','csEternal'],shadow:['chUnseen','chFade','chFeed','chCascade'],
  watchman:['swTrack','swNerve','swDuel','swInquis'],bladeDancer:['sbBlur','sbCombo','sbRiposte','sbStorm'],
  beastwarden:['wbPack','wbHide','wbHowl','wbAlpha'],earthshaper:['weFault','weStone','weAnchor','weMountain'],
  sergeant:['sgCover','sgOrders','sgStand','sgVictory'],vanguard:['svRush','svBrawl','svFury','svRampage'],
  sniper:['ssPerch','ssExposed','ssBigGame','ssStreak'],infiltrator:['siVanish','siKnife','siHunt','siSabo'],
  surgeon:['mdHands','mdCover','mdLast','mdMiracle'],tech:['mtDroid','mtPlate','mtOver','mtNet'],
  demolitionist:['hdHeavy','hdShock','hdBuster','hdArmageddon'],bulwark:['hbWall','hbSpite','hbIron','hbAnchor']};
 for(const [c,L] of Object.entries(T3)){const T=TREES[c];if(!T)continue;[1,2].forEach((k,i)=>{if(!T.trunk[k].includes(L[i]))T.trunk[k].push(L[i])})}
 for(const T of Object.values(TREES))for(const [id,s] of Object.entries(T.specs)){const L=S3[id];if(L)[4,5,6,7].forEach((k,i)=>{if(!s[k].includes(L[i]))s[k].push(L[i])})}})();

// Bond techniques: picked once a bond reaches BOND_TECH_AT; work when both partners deploy (power.js reads u.pairs).
const BOND_TECH_AT=5;
const BOND_TECH={
 crossfire:{n:'Crossfire',desc:'+15 aim against enemies within 4 tiles of your partner.'},
 backToBack:{n:'Back to Back',desc:'Enemies get −15 aim against you while your partner is next to you.'},
 angel:{n:'Guardian Angel',desc:'Once per mission, with your partner within 4 tiles, a killing blow leaves you at 1 HP.'},
 rhythm:{n:'Battle Rhythm',desc:'When your partner kills, you heal 1, gain 1 Focus, and your next kill this turn refunds an action.'}};

// ── Tank classes (wave 5, Jess): trees + their own perks. shelter = enemies −N aim against allies next to you. ──
Object.assign(PERKS,{
 tkGuardPost:{name:'Guard Post',ic:'guard',desc:'Enemies get −10 aim against allies next to you.',fx:{shelter:10}},
 tkFortress:{name:'Fortress',ic:'hunker',desc:'+1 armor and +2 HP.',mod:{armor:1,hp:2}},
 tkColossus:{name:'Colossus',ic:'guard',desc:'Survive one killing blow at 1 HP; regain 2 HP each turn; allies next to you take 1 less damage.',fx:{lastStand:1,regen:2,ward:1}},
 tkParry:{name:'Parry',ic:'strike',desc:'+15 deflect. Enemies that hit you in melee take 1 damage.',mod:{deflect:15},fx:{riposte:1}},
 tkRedirect:{name:'Redirect',ic:'guard',desc:'+10 deflect. Enemies get −10 aim against you.',mod:{deflect:10},fx:{dodge:10}},
 tkWall:{name:'Wall of Light',ic:'guard',desc:'+15 deflect.',mod:{deflect:15}},
 tkSoresu:{name:'Soresu Master',ic:'guard',desc:'+20 deflect, enemies −10 aim against you, melee attackers take 2.',mod:{deflect:20},fx:{dodge:10,riposte:2}},
 tkShieldWall:{name:'Shield Wall',ic:'guard',desc:'Enemies get −15 aim against allies next to you.',fx:{shelter:15}},
 tkBastion:{name:'Living Bastion',ic:'hunker',desc:'+2 armor. Allies next to you take 1 less damage.',mod:{armor:2},fx:{ward:1}}});
TREES.Defender={trunk:{1:['defLine','saberThrow','gChallenge'],2:['leap','gStalwart','tkGuardPost']},specs:{
 bastion:{n:'Bastion',ic:'sp_protector',desc:'Unmovable. Soaks fire and shelters allies.',sig:'barrier',4:['gIron','gpBastion','tkFortress'],5:['collapse','gAegis','gpBeacon'],6:['forceWave','gpUndying','tkShieldWall'],7:['gUnbreakable','gpLiving','tkColossus']},
 soresu:{n:'Soresu',ic:'sp_weaponMaster',desc:'Perfect defense. Deflects, dodges, counters.',sig:'reflectM',4:['tkParry','gBulwark','chFade'],5:['gwCounter','sbBlur','tkRedirect'],6:['precisionStrike','tkWall','gLastStand'],7:['tkSoresu','sUntouchable','gwRampage']}}};
TREES.Shieldbearer={trunk:{1:['hunker','suppress','hCoverMe'],2:['flakVest','mHardy','tkGuardPost']},specs:{
 phalanx:{n:'Phalanx',ic:'sp_bulwark',desc:'Shield line. Everyone behind you lives.',sig:'holdLine',4:['juggernaut','hbWall','tkShieldWall'],5:['hBulwark','hbIron','rally'],6:['smoke','hTitan','tkFortress'],7:['hbAnchor','soSgtHero','tkBastion']},
 breacher:{n:'Breacher',ic:'sp_vanguard',desc:'Shield-first assault. Kicks the door and keeps going.',sig:'chainShot',4:['soVanPlate','svBrawl','soBreach'],5:['svFury','veteran','hBrute'],6:['runGun','soVanCharge','svRush'],7:['soLegend','svRampage','hWarlord']}}};
Object.assign(SPEC_TRAITS,{
 bastion:{n:'Immovable',desc:'+1 armor and +10 will.',mod:{armor:1,will:10}},
 soresu:{n:'Form III',desc:'+15 deflect; enemies get −5 aim against you.',mod:{deflect:15},fx:{dodge:5}},
 phalanx:{n:'Shield Line',desc:'Allies next to you take 1 less damage; +10 will.',mod:{will:10},fx:{ward:1}},
 breacher:{n:'Breach and Clear',desc:'+15 aim and +1 damage within 4 tiles.',fx:{closeAim:15,closeDmg:1}}});
FX_N.shelter='Shelter allies';
// Class icons (icons.js injected its symbols already, so add these to the same sprite). Shapes: shield+saber, riot shield.
Object.assign(ICONS,{defender:'M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6zM12 7v10M9 12h6',shieldbearer:'M5 3h14v10c0 4-3 7-7 8-4-1-7-4-7-8zM9 8h6M9 12h6'});
(function(){const sp=document.querySelector('svg symbol')&&document.querySelector('svg symbol').parentNode;if(!sp)return;
 for(const k of ['defender','shieldbearer'])if(!sp.querySelector('#i-'+k))sp.insertAdjacentHTML('beforeend',`<symbol id="i-${k}" viewBox="0 0 24 24"><path d="${ICONS[k]}"/></symbol>`)})();

// ── Melee (power.js): a melee hit on a melee fighter may be answered. Force user vs Force user = blade lock (always answered). ──
const MELEE={counter:20,lock:60,counterDmg:'low'};   // counter % for non-Force melee defenders; counter hits for the defender's low damage roll

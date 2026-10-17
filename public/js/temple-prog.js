/* Progression & gear data (wave 3, Chat P): tree perks for ranks 4–7, tree abilities the engine lacked, utility gear, crystals, saber forms,
   research, Sith ops, stress and scars. Every entry has a one-sentence mechanical `desc`. Logic + screens: temple-ops.js. Tune numbers here.
   Lore tags: saber Forms I–VII names = Legends, High confidence. Cortosis = Legends, Med. Everything else is invented for the game [N]. */

// --- Tree stat picks (ranks 4–7). `mod` adds to battle stats (see addMod in temple.js). will/aimVsHorror are plain fields read by the engine (Chat X).
Object.assign(PERKS,{
 gIron:{name:'Iron Body',ic:'guard',desc:'+1 HP and +10 will.',mod:{hp:1,will:10}},
 gDuelist:{name:'Duelist',ic:'strike',desc:'+5 aim and +10% crit chance.',mod:{aim:5,crit:10}},
 gBulwark:{name:'Bulwark',ic:'hunker',desc:'+1 armor and +10 deflect while on Guard.',mod:{armor:1,guardDef:10}},
 gVanguard:{name:'Vanguard',ic:'leap',desc:'+1 move and +1 damage.',mod:{mob:1,dmg:1}},
 gWarden:{name:'Warden',ic:'guard',desc:'+15 deflect.',mod:{deflect:15}},
 gUnbreakable:{name:'Unbreakable',ic:'hunker',desc:'+2 HP and +1 armor.',mod:{hp:2,armor:1}},
 gMasterBlade:{name:'Master Blade',ic:'strike',desc:'+1 damage and +15% crit chance.',mod:{dmg:1,crit:15}},
 cResolve:{name:'Resolve',ic:'guard',desc:'+2 HP and +10 will.',mod:{hp:2,will:10}},
 cWellspring:{name:'Wellspring',ic:'meditate',desc:'+1 max Focus and +5 deflect.',mod:{maxF:1,deflect:5}},
 cSeer:{name:'Battle Seer',ic:'mark',desc:'+10 aim and +1 move.',mod:{aim:10,mob:1}},
 cMaster:{name:'Master of the Force',ic:'meditate',desc:'+1 max Focus and +2 HP.',mod:{maxF:1,hp:2}},
 sExecutioner:{name:'Killer Instinct',ic:'strike',desc:'+5 aim and +15% crit chance.',mod:{aim:5,crit:15}},
 sEdge:{name:'Keen Edge',ic:'strike',desc:'+1 damage.',mod:{dmg:1}},
 sGhost:{name:'Ghost Step',ic:'leap',desc:'+1 move and +10% crit chance.',mod:{mob:1,crit:10}},
 sHunter:{name:'Hunter',ic:'mark',desc:'+15 aim.',mod:{aim:15}},
 sBlademaster:{name:'Blademaster',ic:'strike',desc:'+2 damage and +15% crit chance.',mod:{dmg:2,crit:15}},
 sUntouchable:{name:'Untouchable',ic:'guard',desc:'+20 deflect and +1 armor.',mod:{deflect:20,armor:1}},
 wStalker:{name:'Stalker',ic:'mark',desc:'+5 aim and +10% crit chance.',mod:{aim:5,crit:10}},
 wBond:{name:'Wild Bond',ic:'meditate',desc:'+1 max Focus and +10 will.',mod:{maxF:1,will:10}},
 wSeer:{name:'Far Sight',ic:'mark',desc:'+10 aim.',mod:{aim:10}},
 wPrimal:{name:'Primal',ic:'strike',desc:'+2 damage and +1 move.',mod:{dmg:2,mob:1}},
 soTough:{name:'Tough',ic:'hunker',desc:'+2 HP.',mod:{hp:2}},
 soMarksman:{name:'Marksman',ic:'mark',desc:'+10 aim and +2 range.',mod:{aim:10,range:2}},
 soSteel:{name:'Nerves of Steel',ic:'guard',desc:'+1 armor and +15 will.',mod:{armor:1,will:15}},
 soIronWill:{name:'Iron Will',ic:'guard',desc:'+2 HP and +20 will.',mod:{hp:2,will:20}},
 soCommander:{name:'Commander',ic:'guard',desc:'+10 aim, +3 HP, +1 armor and +1 move.',mod:{aim:10,hp:3,armor:1,mob:1}},
 soLegend:{name:'Living Legend',ic:'shoot',desc:'+2 damage and +10% crit chance.',mod:{dmg:2,crit:10}},
 scEagle:{name:'Eagle Eye',ic:'mark',desc:'+2 range and +5 aim.',mod:{range:2,aim:5}},
 scSniper:{name:'Sniper',ic:'mark',desc:'+10 aim.',mod:{aim:10}},
 scAssassin:{name:'Assassin',ic:'shoot',desc:'+20% crit chance.',mod:{crit:20}},
 scSurvivor:{name:'Survivor',ic:'hunker',desc:'+2 HP.',mod:{hp:2}},
 scDeadly:{name:'Deadly',ic:'shoot',desc:'+1 damage.',mod:{dmg:1}},
 scLegend:{name:'Ghost of the Rim',ic:'shoot',desc:'+2 damage and +10% crit chance.',mod:{dmg:2,crit:10}},
 mDrilled:{name:'Drilled',ic:'shoot',desc:'+5 aim and +1 HP.',mod:{aim:5,hp:1}},
 mSurgeon:{name:'Surgeon',ic:'medic',desc:'+1 medkit and +1 HP.',mod:{kits:1,hp:1}},
 mStoic:{name:'Stoic',ic:'guard',desc:'+2 HP and +10 will.',mod:{hp:2,will:10}},
 mFieldSurgeon:{name:'Field Surgeon',ic:'medic',desc:'+2 medkits.',mod:{kits:2}},
 mMarksman:{name:'Sharpshooting Medic',ic:'shoot',desc:'+10 aim and +1 damage.',mod:{aim:10,dmg:1}},
 mAngel:{name:'Angel of Mercy',ic:'medic',desc:'+2 medkits and +2 HP.',mod:{kits:2,hp:2}},
 mVeteran:{name:'Veteran Medic',ic:'hunker',desc:'+1 armor, +1 move and +10 aim.',mod:{armor:1,mob:1,aim:10}},
 hBrute:{name:'Brute',ic:'hunker',desc:'+2 HP.',mod:{hp:2}},
 hBulwark:{name:'Walking Bulwark',ic:'hunker',desc:'+1 armor and +10 will.',mod:{armor:1,will:10}},
 hGunner:{name:'Steady Gunner',ic:'shoot',desc:'+10 aim.',mod:{aim:10}},
 hHeavyWeapons:{name:'Heavy Weapons',ic:'shoot',desc:'+1 damage and +1 range.',mod:{dmg:1,range:1}},
 hTitan:{name:'Titan',ic:'hunker',desc:'+3 HP.',mod:{hp:3}},
 hWarlord:{name:'Warlord',ic:'grenade',desc:'+2 damage and +1 grenade.',mod:{dmg:2,nades:1}}});
for(const p of Object.values(PERKS)){p.desc=p.desc||p.tip;p.tip=p.tip||p.desc}

// --- Tree abilities the engine didn't have yet. Added only if AB lacks them, so Chat X's versions win. Ids are stable.
// Tree abilities (flurry … medBeacon) now live in abilities.js (Chat X).
for(const a of Object.values(AB))if(!a.desc&&a.tip)a.desc=a.tip;

// --- Gear (spec B §5.3–5.4, extended). need = [wing, level]; res = research id that unlocks it. who = troop | jedi | any.
const UTIL=window.UTILITY={none:{n:'Empty',cost:0,desc:'No utility item.'},
 frag:{n:'Frag grenade',cost:30,mod:{nades:1},give:'grenade',desc:'+1 grenade; gives the Grenade ability to anyone.'},
 medpac:{n:'Medpac',cost:30,mod:{kits:1},give:'heal',desc:'+1 medkit; gives the Medkit ability to anyone.'},
 boots:{n:'Servo boots',cost:40,need:['armory',1],mod:{mob:1},desc:'+1 move.'},
 visor:{n:'Targeting visor',cost:50,res:'visors',mod:{aim:5,crit:5},desc:'+5 aim and +5% crit chance.'},
 shield:{n:'Personal shield',cost:60,res:'shields',mod:{armor:1},desc:'+1 armor: every hit does 1 less (min 1).'}};
// Crystal = saber color + a small stat (spec D colors). Recolor freely in the Armory.
const CRYSTAL_FX=window.GEAR={blue:{n:'Blue',mod:{aim:5},desc:'Steady: +5 aim.'},green:{n:'Green',mod:{deflect:5,guardDef:5},desc:'Calm: +5 deflect, +5 more on Guard.'},
 yellow:{n:'Yellow',mod:{crit:10},desc:'Keen: +10% crit chance.'},violet:{n:'Violet',mod:{dmgHi:1},desc:'Fierce: +1 max damage.'},white:{n:'White',mod:{will:10,deflect:5},desc:'Pure: +10 will, +5 deflect.'}};
// Lightsaber forms: one stance per Jedi, one passive each. Forms I–III known from the start; IV–VII need research.
const FORMS={
 shiiCho:{n:'Shii-Cho (Form I)',mod:{hp:1,deflect:5},desc:'Basic form: +1 HP, +5 deflect.'},
 makashi:{n:'Makashi (Form II)',mod:{aim:10},desc:'Dueling precision: +10 aim.'},
 soresu:{n:'Soresu (Form III)',mod:{deflect:15,guardDef:10,dmgHi:-1},desc:'Pure defense: +15 deflect, +10 on Guard, −1 max damage.'},
 ataru:{n:'Ataru (Form IV)',res:'ataru',mod:{mob:1,crit:5},desc:'Acrobatic: +1 move, +5% crit chance.'},
 djemSo:{n:'Djem So (Form V)',res:'djemSo',mod:{dmg:1,deflect:-5},desc:'Power: +1 damage, −5 deflect.'},
 niman:{n:'Niman (Form VI)',res:'niman',mod:{maxF:1,will:5},desc:'Balanced: +1 max Focus, +5 will.'},
 juyo:{n:'Juyo (Form VII)',res:'juyo',mod:{dmg:1,crit:15},dark:1,desc:'Ferocious: +1 damage, +15% crit; the user gains 1 Darkness after every mission.'}};

// --- Research (Archives wing): one project at a time; days tick 15 per mission (×1.5 at Archives 2, ×1.25 staffed).
const RESEARCH={
 ataru:{n:'Ataru katas',days:15,cost:{credits:40},desc:'Unlocks the Ataru saber form.'},
 djemSo:{n:'Djem So drills',days:15,cost:{credits:40},desc:'Unlocks the Djem So saber form.'},
 niman:{n:'Niman discipline',days:20,cost:{credits:60},need:['ataru'],desc:'Unlocks the Niman saber form.'},
 juyo:{n:'Juyo, the forbidden form',days:30,cost:{credits:80,intel:1},need:['djemSo'],dark:4,desc:'Unlocks the Juyo saber form. Order Darkness +4.'},
 fieldMed:{n:'Field medicine',days:15,cost:{credits:60},desc:'Every Medic carries +1 medkit.'},
 bacta:{n:'Bacta tanks',days:25,cost:{credits:120},need:['fieldMed'],desc:'Unlocks Medical Halls level 3.'},
 curriculum:{n:'Master curriculum',days:25,cost:{credits:100},desc:'Unlocks Training Salle level 2.'},
 holocron:{n:'Holocron studies',days:25,cost:{intel:2},need:['curriculum'],desc:'+10% XP from every mission.'},
 eliteMods:{n:'Weapon smithing',days:15,cost:{credits:60},desc:'Unlocks the Stock and Hair trigger weapon mods.'},
 visors:{n:'Targeting visors',days:15,cost:{credits:60},desc:'Unlocks the Targeting visor utility item.'},
 shields:{n:'Personal shields',days:25,cost:{credits:100,intel:1},need:['visors'],desc:'Unlocks the Personal shield utility item.'},
 armorWeave:{n:'Cortosis weave',days:20,cost:{credits:80},desc:'Unlocks Armored robes for Jedi.'},
 kyberLore:{n:'Kyber lore',days:20,cost:{credits:60},desc:'+1 Kyber now; saber crafts cost 1 less Kyber.'},
 codebreak:{n:'Imperial codebreaking',days:20,cost:{intel:2},desc:'Countering a Sith op with Intel costs 1 less.'},
 sithTactics:{n:'Sith tactics',days:30,cost:{intel:3},need:['codebreak'],desc:'+5 aim for every unit.'},
 beastLore:{n:'Beast lore',days:20,cost:{credits:40,intel:1},desc:'+10 aim against horrors; horror traumas are half as likely.'},
 logistics:{n:'Logistics',days:20,cost:{credits:100},desc:'Unlocks Barracks level 3.'}};

// --- Sith ops (spec B Threat, simplified): 1 op a month (2 from month 3). Counter with Intel, or send a 2-unit team (misses the next mission).
// Ignored by the next month: `mod` feeds campaignMods() for `missions` missions; `res` hits at once; `hurt` wounds a random unit.
const SITH_OPS={
 fortify:{n:'Fortified garrisons',intel:2,mod:{enemyHp:1},missions:2,desc:'If ignored: enemies get +1 HP for 2 missions.'},
 snipers:{n:'Sharpshooter cadre',intel:2,mod:{enemyAim:5},missions:2,desc:'If ignored: enemies get +5 aim for 2 missions.'},
 surge:{n:'Troop surge',intel:3,mod:{extraEnemies:1},missions:2,desc:'If ignored: +1 enemy per wave for 2 missions.'},
 spies:{n:'Spy ring',intel:2,mod:{squadAim:-5},missions:2,desc:'If ignored: your squads get −5 aim for 2 missions.'},
 propaganda:{n:'Holonet propaganda',intel:1,res:{favor:-6},desc:'If ignored: Senate Favor −6.'},
 supply:{n:'Supply raids',intel:1,res:{credits:-80},desc:'If ignored: Credits −80.'},
 kyberRaid:{n:'Kyber raid',intel:2,res:{kyber:-1},desc:'If ignored: Kyber −1.'},
 bounty:{n:'Bounty on the Order',intel:2,hurt:1,desc:'If ignored: an assassin wounds a random unit (10 days, +20 stress).'}};
const OPS={teamBase:50,perRank:6,max:95,xp:15,failStress:20};

// --- Stress (0–100) and scars. Stress rises in missions and falls at rest; scars stay until treated.
const STRESS={base:3,light:3,serious:6,grave:10,allyDied:8,horror:8,lost:4,bench:15,rest:15,calm:40,gardensStaff:5,shaken:50,breaking:80};
const STRESS_LV=[{n:'Steady',at:0,mod:{},desc:'No stress effects.'},{n:'Shaken',at:50,mod:{aim:-5,will:-10},desc:'−5 aim, −10 will.'},
 {n:'Breaking',at:80,mod:{aim:-10,will:-20},desc:'−10 aim, −20 will. Rest them.'}];
const SCARS={
 oldWound:{n:'Old wound',kind:'wound',mod:{hp:-1},desc:'−1 HP.'},
 shakyHand:{n:'Shaky hand',kind:'wound',mod:{aim:-5},desc:'−5 aim.'},
 badLeg:{n:'Bad leg',kind:'wound',mod:{mob:-1},desc:'−1 move.'},
 fearsHorrors:{n:'Fears horrors',kind:'trauma',mod:{aimVsHorror:-10},desc:'−10 aim against horrors.'},
 guilt:{n:'Survivor’s guilt',kind:'trauma',mod:{will:-15},desc:'−15 will.'},
 nightmares:{n:'Nightmares',kind:'trauma',stressX:1.5,desc:'Gains 50% more stress.'},
 anger:{n:'Burning anger',kind:'trauma',mod:{crit:10,will:-10},dark:1,desc:'+10% crit, −10 will; a Jedi gains 1 Darkness after every mission.'}};
const SCAR={grave:40,trauma:30,breaking:25,max:3,treat:35};  // % chances; treat = per period meditating in Gardens 2 (traumas) or resting in Medical 3 (wounds)

// Statuses for describe('status',id) / Codex: stress levels and scars (STATUS lives in data.js; we only add rows).
if(typeof STATUS!=='undefined'){Object.assign(STATUS,{stress:{n:'Stress',desc:'0–100. Missions add it; benching, Medical and the Gardens remove it. 50+ Shaken, 80+ Breaking.'},
 shaken:{n:'Shaken',desc:STRESS_LV[1].desc},breaking:{n:'Breaking',desc:STRESS_LV[2].desc},scar:{n:'Scar',desc:'A lasting wound or trauma. Medical 3 treats wounds; Gardens 2 treats traumas.'}});
 for(const [k,v] of Object.entries(SCARS))STATUS[k]={n:v.n,desc:v.desc}}

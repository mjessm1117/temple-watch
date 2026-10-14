/* Temple data: troop stat perks, gear, saber crafting, recruit pools, traits, personal quests, Council seats.
   Specs: docs/specs/campaign.md §2, §5 · docs/specs/combat.md §2.3 · docs/specs/story.md §6–7. Tune numbers here. */

// Stat-only rank picks for troops (spec A has one ability per troop rank; the second option is ours [Default]). `mod` adds to battle stats.
const PERKS={
 flakVest:{name:'Flak Vest',ic:'hunker',tip:'+1 armor: every hit on this unit does 1 less (min 1).',mod:{armor:1}},
 veteran:{name:'Veteran',ic:'guard',tip:'+10 aim and +1 HP.',mod:{aim:10,hp:1}},
 longshot:{name:'Long Shot',ic:'mark',tip:'+2 range and +10% crit chance.',mod:{range:2,crit:10}},
 killshot:{name:'Killshot',ic:'shoot',tip:'+1 damage on every shot.',mod:{dmg:1}},
 fieldcraft:{name:'Fieldcraft',ic:'evac',tip:'+1 move and +1 HP.',mod:{mob:1,hp:1}},
 fieldKit:{name:'Field Kit',ic:'medic',tip:'+1 medkit every mission.',mod:{kits:1}},
 combatMedic:{name:'Combat Medic',ic:'shoot',tip:'+10 aim and +1 damage.',mod:{aim:10,dmg:1}},
 traumaBag:{name:'Trauma Bag',ic:'medic',tip:'+2 medkits every mission.',mod:{kits:2}},
 bandolier:{name:'Bandolier',ic:'grenade',tip:'+1 grenade every mission.',mod:{nades:1}},
 juggernaut:{name:'Juggernaut',ic:'hunker',tip:'+2 HP and +1 armor.',mod:{hp:2,armor:1}}};

// Troop gear (spec B §5.4). Tiers upgrade in order. need = [wing, level]. Prices for armor and mods are ours [Default].
const WEAPONS=[{n:'Standard blaster',slots:0,desc:'Issue rifle. No mod slots.'},
 {n:'Military blaster',cost:50,need:['armory',1],mod:{dmg:1},slots:1,desc:'+1 damage, 1 mod slot.'},
 {n:'Elite blaster',cost:120,need:['armory',2],mod:{dmg:1,aim:5},slots:2,desc:'+1 more damage, +5 aim, 2 mod slots.'}];
// Armor sets. who = troop | jedi | any; res = research needed (temple-prog.js).
const ARMOR={none:{n:'No armor',cost:0,who:'any',desc:'Nothing extra.'},
 light:{n:'Light armor',cost:30,who:'troop',mod:{hp:1},desc:'+1 HP.'},
 medium:{n:'Medium armor',cost:50,who:'troop',need:['armory',1],mod:{hp:1,armor:1},desc:'+1 HP, +1 armor.'},
 heavy:{n:'Heavy armor',cost:80,who:'troop',need:['armory',2],mod:{hp:2,armor:1,mob:-1},desc:'+2 HP, +1 armor, −1 move.'},
 robes:{n:'Battle robes',cost:30,who:'jedi',mod:{hp:1},desc:'+1 HP.'},
 armoredRobes:{n:'Armored robes',cost:70,who:'jedi',res:'armorWeave',mod:{hp:1,armor:1},desc:'+1 HP, +1 armor.'}};
const MODS={scope:{n:'Scope',cost:25,mod:{aim:10},tip:'+10 aim'},barrel:{n:'Long barrel',cost:25,mod:{range:2},tip:'+2 range'},
 cell:{n:'Power cell',cost:25,mod:{dmgHi:1},tip:'+1 max damage'},stock:{n:'Stock',cost:30,res:'eliteMods',mod:{aim:5,crit:5},tip:'+5 aim, +5% crit'},
 trigger:{n:'Hair trigger',cost:30,res:'eliteMods',mod:{crit:10},tip:'+10% crit'}};
for(const m of Object.values(MODS))m.desc=m.tip+'.';
// Lightsabers (spec B §5.3). Each tier adds to the one before (our reading of the table).
const SABERS=[{n:'Training saber',desc:'Base damage.'},
 {n:'Attuned saber',kyber:2,cost:60,need:['forge',1],mod:{dmg:1,deflect:5},desc:'+1 damage, +5 deflect.'},
 {n:'Master-forged saber',kyber:4,cost:120,need:['forge',2],mod:{dmg:1,deflect:10},trait:1,desc:'+1 more damage, +10 deflect, and a trait slot.'}];
const SABER_TRAITS={focused:{n:'Focused',mod:{maxF:1},tip:'+1 max Focus'},swift:{n:'Swift',mod:{mob:1},tip:'+1 move'},
 warden:{n:'Guardian',mod:{guardDef:10},tip:'+10 deflect while on Guard'}};
// Crystal = ring color (spec D). Purple avoids the Darkness role color.
const CRYSTALS={blue:'#62b3ff',green:'#72e0a4',yellow:'#f2d36b',violet:'#c58cff',white:'#e6eef6'};
const TROOP_COLS=['#e0bd78','#d9a05b','#9fc6d6','#c9d27a','#d6a3a3'];

// Recruits (spec B §5.5). Traits nudge stats; origins are flavor.
const TRAITS={steady:{n:'Steady',tip:'+5 aim',mod:{aim:5}},reckless:{n:'Reckless',tip:'+1 move, −5 aim',mod:{mob:1,aim:-5}},
 compassionate:{n:'Compassionate',tip:'+1 HP',mod:{hp:1}},ambitious:{n:'Ambitious',tip:'+10% XP',xp:1.1},curious:{n:'Curious',tip:'+1 Intel after every won mission',intel:1}};
const ORIGINS={jedi:['Temple-raised','Late found'],troop:['Republic Army','Temple Guard','Hired']};
const SPECIES=['Human','Twi\'lek','Mirialan','Zabrak','Togruta','Kel Dor','Rodian'];
const AGES={Padawan:[14,19],Knight:[22,40],troop:[20,35]};
const JEDI_NAMES=['Vela Sorn','Arin Taal','Quin Vasro','Myra Kell','Teo Lanris','Shae Orrin','Bastil Rhe','Nim Calder'];

// Bonds (spec C §7): +1 level per revive, or per 3 missions survived together. Level effects reach battle via battleUnit().
const BOND={missions:3,aim:5,max:3,fear:2};   // fear = missions of −10 aim after a level-3 partner dies

// Personal quests (spec C §7): offered once a unit reaches rank 2; shown in the crisis list; the unit must deploy.
const QUESTS={
 crystal:{n:'The crystal calls',who:'jedi',mission:'shrine',text:'{n} hears a kyber crystal singing at a shrine, and Sith boots closing in.',res:{kyber:1},mod:{aim:5},txt:'+1 Kyber; {n} bonds with the crystal: +5 aim'},
 whisper:{n:'A dark whisper',who:'dark',mission:'shrine',text:'{n} keeps hearing a voice that promises strength. Face it at the old shrine.',dark:-4,txt:'{n} silences the voice: Darkness −4'},
 master:{n:'The fallen master',who:'jedi',needLegend:1,mission:'rescue',text:'{n} learns their old master’s things were taken by raiders. Get them back.',mod:{hp:1,aim:5},txt:'{n} carries the master’s relic: +1 HP, +5 aim'},
 family:{n:'Lost family',who:'troop',mission:'rescue',text:'{n}’s brother was seized by Sith raiders. {n} asks to go.',recruit:1,mod:{hp:1},txt:'The brother joins up (free recruit); {n} +1 HP'},
 debt:{n:'Old debt',who:'troop',mission:'rescue',text:'A Hutt broker holds a debt over {n}. Settle it the Jedi way: free his captive.',res:{credits:120},txt:'+120 Credits'},
 home:{n:'Homeworld burns',who:'any',mission:'shrine',text:'Raiders are torching {n}’s home village. Hold the line until the militia comes.',res:{favor:6,intel:2},txt:'+6 Senate Favor, +2 Intel'}};

// Council (spec B §4, spec C §6). Display only in v0.2: seat perks and votes are not active yet.
const COUNCIL=[
 {n:'Grand Master Zym',seat:'Master of the Order',stance:'Guardian',perk:'+5 aim for Jedi in assaults',lore:'Legends · date Med'},
 {n:'Gnost-Dural',seat:'Keeper of the Archives',stance:'Sentinel',perk:'+1 Intel per mission',lore:'Legends · date High; Council seat is our invention'},
 {n:'Kao Cen Darach',seat:'Council Master',stance:'Consular',perk:'+5 Favor on Senate crises',lore:'Legends · date Med'},
 {n:'Vacant'},{n:'Vacant'},{n:'Vacant'},{n:'Vacant'}];

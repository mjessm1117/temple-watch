/* Temple life data (wave 3 follow-up, Chat P): Council seats + votes, Hutt black market, service-record quotes, recruit looks, pairing, presets.
   Logic + screens: temple-life.js. Spec B §4 (Council), §5.5 (recruit fields). Tune numbers here.
   Lore tags: Zym, Gnost-Dural, Kao Cen Darach = Legends/SWTOR, High confidence they exist ~3,640 BBY; stances are ours [Med].
   Lord Hoth + Valenthyne Farfalla lead the Army of Light at Ruusan = Legends, High; Farfalla's stance is ours [Low]. Votes and market items are invented [N]. */

// Council seats by era. stance picks how they vote and which perk they give. Loyalty lives in C.story.loyal[id] (story.js events change it too).
const SEATS={
 zym:{n:'Grand Master Zym',era:1,stance:'Guardian',chair:1},gnost:{n:'Gnost-Dural',era:1,stance:'Sentinel'},darach:{n:'Kao Cen Darach',era:1,stance:'Consular'},
 hoth:{n:'Lord Hoth',era:2,stance:'Guardian',chair:1},farfalla:{n:'Lord Valenthyne Farfalla',era:2,stance:'Consular'}};
// Seat perks while seated; doubled at loyalty ≥ COUNCIL_RULES.double.
const STANCE_PERK={Guardian:{desc:'+5 aim for every Jedi.',jediAim:5},Consular:{desc:'+5 Senate Favor after each won Senate crisis.',senateFavor:5},
 Sentinel:{desc:'+1 Intel after each won mission.',winIntel:1},Wayseeker:{desc:'Order Darkness −1 each month.',monthDark:-1}};
const COUNCIL_RULES={seats:7,start:60,agree:5,dissent:-15,resign:25,double:80,replaceFavor:10,replaceOthers:-5,appointRank:5};

// Council matters, one a month. Each member votes for the first option its stance `pleases`. effects: credits intel kyber favor recruits orderDark stress (every active unit).
const VOTES={
 refugees:{n:'Refugees from Taris',text:'A hundred thousand refugees crowd Coruscant’s lower levels. The Senate asks the Order to help.',opts:[
  {t:'Fund relief convoys',fx:{credits:-100,favor:6},pleases:['Consular']},{t:'Send Knights to keep order',fx:{favor:2,stress:5},pleases:['Guardian']},{t:'Leave it to the Senate',fx:{favor:-4},pleases:['Sentinel']}]},
 defector:{n:'An Imperial defector',text:'An Imperial officer offers fleet codes for safe passage and a payout.',opts:[
  {t:'Pay him',fx:{credits:-80,intel:3},pleases:['Sentinel']},{t:'Hand him to the Senate',fx:{favor:5},pleases:['Consular']},{t:'Refuse: it is a trap',fx:{},pleases:['Guardian']}]},
 guard:{n:'Fortify the Temple',text:'Masters argue the Temple is too exposed. Hire Temple Guard, or trust the Force.',opts:[
  {t:'Hire Temple Guard',fx:{credits:-120,recruits:2},pleases:['Guardian']},{t:'Trust in the Force',fx:{orderDark:-2},pleases:['Consular','Wayseeker']}]},
 frontline:{n:'Jedi on the front lines',text:'The Senate wants Jedi leading Republic battalions.',opts:[
  {t:'Agree',fx:{favor:8,orderDark:2},pleases:['Guardian']},{t:'Refuse: we are not an army',fx:{favor:-6},pleases:['Consular','Wayseeker']},{t:'Send observers only',fx:{favor:2,intel:1},pleases:['Sentinel']}]},
 acolyte:{n:'A captured acolyte',text:'A young Sith acolyte sits in the Temple cells. What do we do with her?',opts:[
  {t:'Try to redeem her',fx:{credits:-40,orderDark:-3},pleases:['Consular','Wayseeker']},{t:'Interrogate her hard',fx:{intel:3,orderDark:4},pleases:['Sentinel']},{t:'Hand her to the Republic',fx:{favor:4},pleases:['Guardian']}]},
 caravan:{n:'The Ilum caravan',text:'A kyber shipment can be bought for the Order before the Senate claims it.',opts:[
  {t:'Buy the shipment',fx:{credits:-100,kyber:1},pleases:['Guardian','Wayseeker']},{t:'Let the Senate have it',fx:{favor:4},pleases:['Consular']}]},
 expedition:{n:'An archive expedition',text:'Archivists found coordinates to a lost Jedi outpost.',opts:[
  {t:'Fund the expedition',fx:{credits:-90,intel:2},pleases:['Sentinel','Wayseeker']},{t:'Postpone it',fx:{},pleases:['Guardian']}]},
 hutts:{n:'Hutt protection',text:'A Hutt clan offers “protection” for Republic convoys near the Temple’s supply lanes.',opts:[
  {t:'Pay the tribute',fx:{credits:-80,intel:1},pleases:['Sentinel']},{t:'Report them to the Senate',fx:{favor:3},pleases:['Consular']},{t:'Refuse',fx:{credits:-30},pleases:['Guardian']}]},
 memorial:{n:'A memorial for the fallen',text:'The war has taken many. Some ask for a memorial in the Temple gardens.',opts:[
  {t:'Build a memorial',fx:{credits:-60,stress:-10},pleases:['Consular','Wayseeker']},{t:'Hold a vigil',fx:{stress:-4},pleases:['Guardian','Sentinel']}]},
 tithe:{n:'The Senate audit',text:'Senators question what the Order does with its stipend.',opts:[
  {t:'Open the books (pay auditors)',fx:{credits:-70,favor:5},pleases:['Consular']},{t:'Refuse the audit',fx:{favor:-5},pleases:['Guardian','Wayseeker']},{t:'Leak their own spending',fx:{intel:-1,favor:2},pleases:['Sentinel']}]},
 initiates:{n:'Older initiates',text:'Force-sensitive teens beyond the usual age ask to train.',opts:[
  {t:'Admit them',fx:{recruits:1,orderDark:1},pleases:['Guardian','Wayseeker']},{t:'Keep the tradition',fx:{favor:2},pleases:['Consular','Sentinel']}]},
 spies:{n:'Spies in the Senate',text:'Intel suggests an Imperial spy in a senator’s office.',opts:[
  {t:'Run a counter-op',fx:{credits:-60,intel:2},pleases:['Sentinel']},{t:'Warn the Chancellor',fx:{favor:3},pleases:['Consular','Guardian']}]}};

// Hutt black market: MARKET.stock items each month. Every buy costs Senate Favor −MARKET.favor. unlock = gear id that becomes buyable in the Armory.
const MARKET={stock:3,favor:2};
const MARKET_ITEMS={
 kyber:{n:'Smuggled kyber',cost:110,fx:{kyber:1,orderDark:1},desc:'+1 Kyber. Order Darkness +1.'},
 codes:{n:'Stolen Imperial codes',cost:70,fx:{intel:2},desc:'+2 Intel.'},
 bacta:{n:'Black-market bacta',cost:80,heal:10,desc:'Every wounded unit heals 10 days now.'},
 merc:{n:'Mandalorian mercenary',cost:160,merc:3,desc:'Hire a rank-3 trooper (needs a free roster slot).'},
 beskar:{n:'Beskar plates',cost:150,unlock:'beskar',desc:'Unlocks Beskar armor in the Armory.'},
 stims:{n:'Combat stims',cost:60,unlock:'stims',desc:'Unlocks Combat stims (utility) in the Armory.'},
 cortosis:{n:'Cortosis weave sample',cost:100,unlock:'armoredRobes',desc:'Unlocks Armored robes for Jedi without research.'},
 shard:{n:'Sith holocron shard',cost:90,fx:{intel:3,orderDark:3},desc:'+3 Intel. Order Darkness +3.'},
 writs:{n:'Forged Senate writs',cost:90,fx:{favor:8},desc:'+8 Senate Favor (the −2 for dealing with Hutts still applies).'},
 hunter:{n:'Bounty hunter contract',cost:120,stopOp:1,desc:'Stops one open Sith op.'},
 calm:{n:'Meditation incense',cost:50,stress:-10,desc:'Every active unit loses 10 stress.'}};

// Service record quotes, picked on notable moments. {n} = unit name. Kept short: the record shows the last 3.
const SAY_LINES={
 kill:{jedi:['The Force guided the blade.','I take no joy in it.','Stand down, or fall.'],troop:['Target down.','That one’s for the Temple.','Next!']},
 down:{jedi:['Not… yet.','There is no death…'],troop:['Medic!','I’m hit, I’m hit!']},
 promo:{jedi:['I will be worthy of it.','The Council asks much. I will give it.'],troop:['Didn’t do it for the stripes.','Drinks are on me.']},
 scar:{jedi:['I still feel it, some nights.','Pain is a teacher.'],troop:['Doc says it won’t heal right.','Souvenir from the Sith.']},
 freed:{jedi:['They could not break me.'],troop:['Took you long enough.']}};

// Recruit editor: looks are a free-text style hint for the 3D view (F may read r.look).
const LOOKS={jedi:['Hooded robe','Open robe','Battle tunic','Armored robe','Traveler’s cloak'],troop:['Full helmet','Bare head','Field cap','Visor','Hood']};
const BIO_MAX=140;

// Master–Padawan pairing: a Knight or Master (rank ≥ PAIR.rank) takes one Padawan. Starts a bond; the Padawan earns extra XP when both deploy.
const PAIR={rank:3,xp:8,bond:2};   // bond = starting bond level (1–8 scale)
const PRESET_MAX=6;

// Black-market gear (unlocked by MARKET_ITEMS.unlock). Added to the Armory tables.
Object.assign(ARMOR,{beskar:{n:'Beskar armor',cost:120,who:'troop',market:1,mod:{hp:2,armor:2,mob:-1},desc:'+2 HP, +2 armor, −1 move.'}});

/* Temple building data (Chat T2): sublevel slots, adjacency bonuses, room-log limits. Tune here.
   Wing levels, costs and effects stay in data-campaign.js (WINGS). Logic: temple-build.js. */

// The Temple as a ziggurat (Jess 2026-10-21: it grows up and out, not down). Wings go on terraces; the 4 spires are separate late builds;
// the undercroft is 3 vaults you dig for rare finds (no wings there). x = horizontal position in bays (rows shift half a bay as the ziggurat narrows).
// row 0 = upper terrace (2 bays), 1 = middle (3), 2 = base hall (4) + 2 annexes that widen it later, 3 = undercroft.
const TIER_N={t:'Upper terrace',m:'Middle terrace',b:'Base hall',a:'Annex',u:'Undercroft vault',sp:'Spire'};
const SLOTS=[];{const add=(tier,row,xs,wing)=>xs.forEach((x,i)=>SLOTS.push({id:tier+i,tier,row,x,wing,n:`${TIER_N[tier]} ${i+1}`,sn:`${tier.toUpperCase()}${i+1}`}));
 add('t',0,[1,2],1);add('m',1,[.5,1.5,2.5],1);add('b',2,[0,1,2,3],1);add('a',2,[-1,4],1);add('u',3,[.5,1.5,2.5],0);add('sp',-1,[-.5,.5,2.5,3.5],0)}
const BAYS=['West','Center','East'];   // legacy name list (old code paths)

// Where each wing goes when the game places it for you (old saves, Build with no bay picked) and the bay is free. [Default]
const WING_HOME={training:'b0',barracks:'b1',medical:'b2',forge:'b3',armory:'m0',comms:'m1',gardens:'m2',archives:'t1'};
const WING_SHORT={medical:'Medical',training:'Training',forge:'Forge',armory:'Armory',comms:'Comms',archives:'Archives',gardens:'Gardens',barracks:'Barracks'};

// Adjacency (XCOM 2 style). A pair works when both wings are built (level 1+) and share a wall.
// Staff either wing of the pair and the bonus doubles. k = effect key, applied in temple-build.js:
//  heal: wound days removed per mission · research: research days added per mission · stress: stress removed from every unit per mission
//  bench: XP for each active unit that sat out the mission · intel / credits: per month · winCr: credits per won mission
const ADJ=[
 {a:'medical',b:'gardens',n:'Recovery Ward',k:'heal',v:3,tip:'Wounded units heal {v} extra days per mission.'},
 {a:'gardens',b:'archives',n:'Still Minds',k:'research',v:3,tip:'Research gains {v} extra days of progress per mission.'},
 {a:'archives',b:'comms',n:'Signals Library',k:'intel',v:1,tip:'+{v} Intel per month.'},
 {a:'comms',b:'armory',n:'Quartermaster Net',k:'credits',v:15,tip:'+{v} Credits per month.'},
 {a:'armory',b:'forge',n:'Shared Smithy',k:'winCr',v:10,tip:'+{v} Credits per won mission from salvaged parts.'},
 {a:'forge',b:'training',n:'Saber Forms',k:'bench',v:3,tip:'Every unit that sits out a mission gains {v} XP.'},
 {a:'training',b:'barracks',n:'Drill Yard',k:'bench',v:2,tip:'Every unit that sits out a mission gains {v} more XP.'},
 {a:'barracks',b:'medical',n:'Infirmary Bunks',k:'stress',v:4,tip:'Every unit sheds {v} stress per mission.'}];
const ADJ_STAFF_X=2;   // staffed pair multiplier

// Room log: entries kept per wing (newest first).
const WLOG_MAX=12;

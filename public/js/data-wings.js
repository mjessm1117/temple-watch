/* Temple building data (Chat T2): sublevel slots, adjacency bonuses, room-log limits. Tune here.
   Wing levels, costs and effects stay in data-campaign.js (WINGS). Logic: temple-build.js. */

// The sublevels under the Temple: 3 floors × 3 bays. id = 's'+floor+bay. Adjacent = same floor next bay, or same bay next floor.
const SLOT_ROWS=5,SLOT_COLS=3,BAYS=['West','Center','East'];
const SLOTS=[];for(let f=1;f<=SLOT_ROWS;f++)for(let b=0;b<SLOT_COLS;b++)SLOTS.push({id:'s'+f+b,f,b,n:`Sublevel ${f} · ${BAYS[b]}`,sn:`SL${f} ${BAYS[b][0]}`});

// Where each wing goes when the game places it for you (old saves, Build with no slot picked) and the slot is free.
// The ring around the center bay lets all 8 pairs below touch; the center bay is left open. [Default]
const WING_HOME={medical:'s10',gardens:'s11',archives:'s12',comms:'s22',armory:'s32',forge:'s31',training:'s30',barracks:'s20'};
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

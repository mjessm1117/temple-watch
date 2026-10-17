/* Temple floor plan (Chat J · UI). The left rail of the Temple screen: each room opens its tab (and its wing card).
   Rooms are data; a tab no room claims still gets a button in the footer. Styles: css/ui.css (.tmap). */
let ROOM='war',ROOM_TAB='roster';
const ROOMS=[
 // id, name, one-line purpose, wing, tab, icon, grid cell
 {id:'council',n:'Council Chamber',s:'Council',d:'The masters vote, argue and appoint.',tab:'council',ic:'sense',g:'cn'},
 {id:'archives',n:'Archives',d:'Research gear, saber forms and Force lore.',wing:'archives',tab:'research',ic:'scan',g:'ar'},
 {id:'comms',n:'Comms Hub',d:'Track Sith operations and the Intel they cost.',wing:'comms',tab:'ops',ic:'beacon',g:'co'},
 {id:'war',n:'War Room',d:'Choose where the Order fights next.',ic:'relay',g:'wr'},
 {id:'training',n:'Training Salle',s:'Training',d:'Bench units here to train between missions.',wing:'training',tab:'roster',ic:'strike',g:'tr'},
 {id:'armory',n:'Armory',d:'Weapons, armor, mods and loadouts.',wing:'armory',tab:'armory',ic:'shoot',g:'am'},
 {id:'gardens',n:'Meditation Gardens',s:'Gardens',d:'Quiet ground where stress and trauma ease.',wing:'gardens',tab:'roster',ic:'meditate',g:'ga'},
 {id:'forge',n:'Kyber Forge',s:'Forge',d:'Craft and tune lightsabers.',wing:'forge',tab:'armory',ic:'kyber',g:'fo'},
 {id:'medical',n:'Medical Halls',s:'Medical',d:'Wounded units recover here.',wing:'medical',tab:'roster',ic:'stabilize',g:'me'},
 {id:'barracks',n:'Barracks',d:'Your people: ranks, skills, bonds and assignments.',wing:'barracks',tab:'roster',ic:'guard',g:'ba'},
 {id:'hangar',n:'Hangar',d:'New troopers and Padawans report here.',tab:'recruit',ic:'evac',g:'ha'},
 {id:'under',n:'Undercity',d:'Contraband from below the Temple. No questions asked.',tab:'market',ic:'conceal',g:'un'},
 {id:'works',n:'Temple Works',d:'Every wing at a glance: build and upgrade.',tab:'wings',ic:'collapse'}];
const roomOf=id=>ROOMS.find(r=>r.id===id)||ROOMS[3];
// Picks the room for a tab other code switched to (e.g. a roster "Gear" button opens the Armory).
const roomForTab=t=>({roster:'barracks',armory:'armory',wings:'works',research:'archives',ops:'comms',council:'council',market:'under',recruit:'hangar'})[t];
function setRoom(id){const r=roomOf(id);ROOM=r.id;if(r.tab)TAB=ROOM_TAB=r.tab;else ROOM_TAB=TAB}
function curRoom(){if(TAB!==ROOM_TAB){ROOM_TAB=TAB;const r=roomForTab(TAB);ROOM=r||'tab:'+TAB}
 if(ROOM.startsWith('tab:')){const t=TABS.find(x=>x[0]===TAB);return {id:ROOM,n:t?t[1]:'Temple',d:'',tab:TAB}}return roomOf(ROOM)}

// One short status line per room. Every lookup is guarded: other chats own most of this state.
function roomLine(r){try{const cnt=a=>C.roster.filter(x=>x.status==='active'&&x.assign===a).length;
 if(r.wing&&!C.wings[r.wing])return C.build===r.wing?'Under construction':`Build · ${WINGS[r.wing].cost[1]} Cr`;
 if(r.wing&&C.build===r.wing)return 'Upgrading';
 switch(r.id){
  case 'war':return `${C.options.length} mission${C.options.length===1?'':'s'} waiting`;
  case 'council':return typeof members==='function'?`${members().length} masters seated`:'In session';
  case 'archives':{const R=C.research;return R&&R.cur&&RESEARCH[R.cur]?RESEARCH[R.cur].n:'No project'}
  case 'comms':return C.ops&&C.ops.list?`${C.ops.list.length} Sith op${C.ops.list.length===1?'':'s'} tracked`:'Listening';
  case 'training':return `${cnt('train')} training`;
  case 'gardens':return `${cnt('calm')} meditating`;
  case 'medical':{const w=C.roster.filter(x=>x.status==='active'&&x.wound).length;return w?`${w} wounded`:'Beds empty'}
  case 'barracks':return `Roster ${rosterCount()}/${rosterCap()}`;
  case 'forge':return `${C.res.kyber} Kyber`;
  case 'armory':return `${C.res.credits} Credits`;
  case 'hangar':return 'New faces monthly';
  case 'under':return 'Open after dark'}}catch(e){}return ''}

function templeMapHTML(pend){const cur=curRoom().id;
 const lv=r=>{if(!r.wing)return '';const l=C.wings[r.wing],mx=WINGS[r.wing].cost.length-1;return `<span class="lv" aria-label="Level ${l} of ${mx}">${Array.from({length:mx},(_,i)=>`<i class="${i<l?'on':''}"></i>`).join('')}</span>`};
 const tile=r=>{const off=r.wing&&!C.wings[r.wing],badge=r.id==='barracks'&&pend?`<em title="${pend} unit${pend>1?'s':''} can rank up">${pend}</em>`:'';
  return `<button type="button" title="${r.n}" class="room ${r.id===cur?'on':''} ${off?'off':''}" data-room="${r.id}" style="grid-area:${r.g}" aria-pressed="${r.id===cur}">${icon(r.ic)}<b>${r.s||r.n}</b>${lv(r)}<small>${roomLine(r)}</small>${badge}</button>`};
 const claimed=new Set(ROOMS.map(r=>r.tab)),extra=TABS.filter(([k])=>!claimed.has(k));
 return `<div class="tplan">${ROOMS.filter(r=>r.g).map(tile).join('')}</div>
 <div class="tfoot"><button type="button" data-room="works" class="${cur==='works'?'on':''}">All wings</button>${extra.map(([k,n])=>`<button type="button" data-tab="${k}" class="${TAB===k&&cur.startsWith('tab:')?'on':''}">${n}</button>`).join('')}${window.codexOpen?'<button type="button" id="hubCx" title="Codex (C)">Codex</button>':''}${window.settingsOpen?'<button type="button" id="hubSet">Settings</button>':''}</div>`}

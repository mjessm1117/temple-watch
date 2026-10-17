/* Squad & Legacy (Chat Q, wave 5). Data: data-legacy.js. Spec: docs/specs/legacy.md.
   1 Bonds 1–8: points (bondPts) + a drill pick per level, shared by both partners; level 8 = Unbreakable.
   2 Lore: every unit has a backstory and a hidden secret; hints unlock as they grow; the reveal unlocks a personal mission.
   3 Retirement: retire to a Council seat, or as a General posted to a region (field ops there +odds, Unrest capped).
   4 Council support: Council masters (and Generals, once) join battles in extra slots.
   State: C.bonds[k]={lvl,n,dr,offer,owed}; r.lore={bg,sec,t:[[trigger,partner]],rev}; C.gen={unitId:region}; C.leg={rest:{id:step},gf:[ids]}.
   Hooks (wrappers): templeAfterMission, templeAdvance, resolveField, fieldOdds, addUnrest, questOptions, recordHTML, councilTab, lifeClick,
   squadScreen, launchMission, startMission, applyResults. temple.js calls ensureLegacy, legacyMods, bondOffer; story.js calls legRoleBtns/retireTo. */

function ensureLegacy(){if(!C)return;
 if(C.bondV!==2){const map=[0,2,4,6];for(const v of Object.values(C.bonds||{})){v.lvl=map[v.lvl]!=null?map[v.lvl]:Math.min(BOND.max,v.lvl);v.n=0}C.bondV=2}
 for(const v of Object.values(C.bonds||{})){v.dr=v.dr||[];if(v.offer===undefined)v.offer=null;v.owed=v.owed||0}
 C.gen=C.gen||{};C.leg=C.leg||{};C.leg.rest=C.leg.rest||{};C.leg.gf=C.leg.gf||[];
 const used=C.roster.map(r=>r.lore&&r.lore.sec);for(const r of C.roster)if(!r.lore){r.lore=newLore(r,used);used.push(r.lore.sec)}}

// ── 1. Bonds ──
const bondNeed=l=>BOND.need[l]!=null?BOND.need[l]:Infinity;
const bondOf=(a,b)=>C.bonds[bkey(a,b)];
function bondPts(a,b,pts,why,out){if(!a||!b||a===b||!pts||!unit(a)||!unit(b))return;/* Council masters (not on the roster) don't bond */const k=bkey(a,b),v=C.bonds[k]=C.bonds[k]||{lvl:0,n:0,dr:[],offer:null,owed:0};
 const o=out||{bonds:[]};v.n=(v.n||0)+pts;
 while(v.lvl<BOND.max&&v.n>=bondNeed(v.lvl)){v.n-=bondNeed(v.lvl);bondUp(a,b,why,o,1)}if(v.lvl>=BOND.max)v.n=0;
 if(!out&&o.bonds.length&&C.news)C.news.push(...o.bonds)}
// A level-up owes one drill pick; the offer (3 random drills) waits in the Roster until picked. Level 8 gives Unbreakable instead.
function rollDrills(v){const pool=Object.keys(DRILLS).filter(d=>DRILLS[d].min<=v.lvl&&(DRILLS[d].pts||!v.dr.includes(d))),o=[];
 while(pool.length&&o.length<3)o.push(pool.splice(Math.floor(Math.random()*pool.length),1)[0]);return o}
function bondOffer(v){v.dr=v.dr||[];if(v.lvl>=BOND.max)return;v.owed=(v.owed||0)+1;if(!v.offer)v.offer=rollDrills(v)}
function pickDrill(k,d){const v=C.bonds[k];if(!v||!v.offer||!v.offer.includes(d))return;const D=DRILLS[d],[a,b]=k.split('|');
 v.owed=Math.max(0,(v.owed||1)-1);v.offer=null;if(D.mod)v.dr.push(d);
 if(D.pts&&v.lvl<BOND.max)bondPts(a,b,Math.ceil(bondNeed(v.lvl)*D.pts),'worked it out');
 if(v.owed&&!v.offer)v.offer=rollDrills(v);
 const A=unit(a),B=unit(b);if(A&&B){lifeLog(A,`${D.n} with ${B.n}`);lifeLog(B,`${D.n} with ${A.n}`)}saveGame()}
// battleUnit → templeMods → here: every drill on every living bond, plus Unbreakable.
function legacyMods(u,r){for(const [k,v] of Object.entries(C.bonds||{})){const [a,b]=k.split('|');if(a!==r.id&&b!==r.id)continue;
 const p=unit(a===r.id?b:a);if(!p||p.status==='dead')continue;for(const d of v.dr||[])if(DRILLS[d]&&DRILLS[d].mod)addMod(u,DRILLS[d].mod);
 if(v.lvl>=BOND.max)u.will=(u.will||0)+BOND_MAX_PERK.will}}

// ── 2. Lore ──
function newLore(r,used){const J=isJedi(r),org=BACKSTORY[r.origin]?r.origin:(J?'Temple-raised':'Republic Army');
 const ok=Object.keys(SECRETS).filter(k=>{const w=SECRETS[k].who;return w==='any'||w===(J?'jedi':'troop')}),fresh=ok.filter(k=>!(used||[]).includes(k));
 return{bg:org+'#'+Math.floor(Math.random()*BACKSTORY[org].length),sec:pickOne(fresh.length?fresh:ok),t:[],rev:0}}
const fill=(s,r,p)=>s.replace(/\{n\}/g,r.n).replace(/\{p\}/g,p||'a friend');
function bgText(r){const [o,i]=(r.lore.bg||'').split('#'),L=BACKSTORY[o]||[];return L[+i]?fill(L[+i],r):''}
// A milestone unlocks the next hint once. 3 hints (or the reveal rank) → the secret is out and its personal mission is offered.
function loreTick(r,key,p){const L=r.lore;if(!L||L.rev||L.t.some(t=>t[0]===key))return;const S0=SECRETS[L.sec];if(!S0)return;
 L.t.push([key,p||'']);const h=fill(S0.hints[L.t.length-1],r,p);lifeLog(r,'Learned: '+h);C.news.push(`<b>${r.n}</b>: ${h}`);
 if(L.t.length>=S0.hints.length)loreReveal(r)}
function loreReveal(r){const L=r.lore,S0=SECRETS[L.sec];if(!L||L.rev||!S0)return;L.rev=1;const t=fill(S0.reveal,r);
 lifeLog(r,'Secret: '+t);C.news.push(`<b class="up">${r.n}'s secret is out.</b> ${t}`);
 const Q=C.quests[r.id];if(r.status==='active'&&QUESTS[S0.quest]&&(!Q||Q.st==='offer'))C.quests[r.id]={q:S0.quest,st:'offer',sec:L.sec}}
function loreAfterMission(dep){for(const {r,u} of dep){if(u.vip||r.status!=='active'||!r.lore)continue;
 if(r.missions>=3)loreTick(r,'m3');if(u.downed)loreTick(r,'down');if(r.rank>=3)loreTick(r,'r3');
 const b=bondsOf(r).find(b=>b.lvl>=4);if(b)loreTick(r,'bond',b.n);if(r.rank>=LEGACY.revealRank)loreReveal(r)}}
function loreHTML(r){const L=r.lore;if(!L)return'';const S0=SECRETS[L.sec],left=S0?S0.hints.length-L.t.length:0;
 return `<div class="lore"><b class="eyebrow">Story</b><p>${bgText(r)}</p>
 ${L.t.map((t,i)=>`<p class="flag">${fill(S0.hints[i],r,t[1])} <small class="muted">${HINT_TRIGGERS[t[0]]||''}</small></p>`).join('')}
 ${L.rev?`<p><b class="up">Secret · ${S0.n}:</b> ${fill(S0.reveal,r)}</p>`:`<small class="muted">${left} more thing${left===1?'':'s'} to learn. Unlocks as they serve, rank up, bond, survive close calls. All out at rank ${LEGACY.revealRank}.</small>`}</div>`}

// ── 3. Retirement: Council or General ──
const genRegions=()=>REGIONS.filter(g=>g[0]!=='unknown');
const genOf=reg=>Object.keys(C.gen||{}).map(unit).find(r=>r&&r.status==='retired'&&C.gen[r.id]===reg);
const canCouncil=r=>isJedi(r)&&r.rank>=LEGACY.councilRank&&members().length<RC.seats;
// Shared by Years pass (story.js) and voluntary retirement. Returns the role text.
function retireTo(r,role,reg){ensureLife();ensureLegacy();
 if(role==='council'&&canCouncil(r)&&!C.life.appointed.includes(r.id)){C.life.appointed.push(r.id);loyMap()[r.id]=RC.start;C.news.push(`${r.n} takes a seat on the Council.`);return 'Sits on the Jedi Council'}
 if(role==='general'){C.gen[r.id]=REG_N[reg]?reg:null;return `General${REG_N[reg]?' of the '+REG_N[reg]:''}`}return ''}
function legRoleBtns(r){return `${isJedi(r)?`<button type="button" data-role="${r.id}:council" ${canCouncil(r)?'':'disabled'} title="${canCouncil(r)?'Takes an open Council seat':'Needs rank '+LEGACY.councilRank+'+ and an open seat'}">Council seat</button>`:''}
 ${genRegions().map(g=>`<button type="button" data-role="${r.id}:general:${g[0]}">General · ${g[1]}</button>`).join('')}`}
function retireUnit(id,role,reg){const r=unit(id);if(!r||r.status!=='active'||r.rank<LEGACY.retireRank||(r.assign&&/^(op|field):/.test(r.assign)))return;
 if(role==='council'&&!canCouncil(r))return;for(const k in C.staff)if(C.staff[k]===id)delete C.staff[k];r.assign=null;r.status='retired';
 r.role=retireTo(r,role,reg);lifeLog(r,'Retired: '+r.role);if(typeof archive==='function')archive(r,`Retired at ${r.age||'?'}. ${r.role}.`);
 C.news.push(`${r.n} retires: ${r.role}.`);saveGame()}
function retireHTML(r){if(r.status==='retired')return `<p class="muted">Retired · ${r.role||''}${C.gen[r.id]!==undefined?` · <span>${genPostBtns(r)}</span>`:''}</p>`;
 if(r.status!=='active'||r.rank<LEGACY.retireRank)return '';
 return `<details class="ret"><summary>Retire ${r.n}…</summary><p class="muted">Leaves the squad for good. A Council seat gives a vote and a perk; a General guards a region (field ops there +${LEGACY.genField}%, Unrest can't rise above ${LEGACY.genCap}). Both can still join big battles.</p>
 <div class="picks">${isJedi(r)?`<button type="button" data-act="retire:${r.id}:council" ${canCouncil(r)?'':'disabled'}>Retire to the Council</button>`:''}
 ${genRegions().map(g=>`<button type="button" data-act="retire:${r.id}:${g[0]}">General · ${g[1]}</button>`).join('')}</div></details>`}
const genPostBtns=r=>genRegions().map(g=>`<button type="button" class="${C.gen[r.id]===g[0]?'on':''}" data-act="genpost:${r.id}:${g[0]}">${g[1]}</button>`).join('');
function generalsHTML(){const G=Object.keys(C.gen||{}).map(unit).filter(r=>r&&r.status==='retired');
 return `<h3>Generals</h3>${G.length?G.map(r=>`<div class="seat"><b>${r.n}</b> <span class="muted">${r.cls} · rank ${r.rank}</span><div>Posted to: ${REG_N[C.gen[r.id]]||'nowhere'}</div><div class="picks">${genPostBtns(r)}</div></div>`).join('')
  :'<p class="muted">No Generals yet. Retire a rank '+LEGACY.retireRank+'+ unit from the Roster (or at Years pass) to make one.</p>'}`}

// ── 4. Council support in battle ──
let LEG_PICK=[],LEG_GO=null;
function legKind(o){const M=MISSIONS[o.mission]||{};return M.boss||M.eraBoss?'boss':o.story?'story':'any'}
function legPool(o){ensureLife();const kind=legKind(o),rest=C.leg.rest,P=[];
 for(const m of members()){if((rest[m.id]||0)>C.step)continue;
  if(m.unit){const r=unit(m.id);if(!r||r.status!=='retired'||r.wound)continue;P.push({id:m.id,n:m.n,cls:r.cls,rank:r.rank,kind:'seat'})}
  else P.push({id:m.id,n:m.n,cls:m.stance,rank:LEGACY.masterRank,kind:'npc'})}
 if(kind!=='any')for(const [id] of Object.entries(C.gen||{})){const r=unit(id);if(r&&r.status==='retired'&&!r.wound&&!C.leg.gf.includes(id)&&!P.some(p=>p.id===id))P.push({id,n:r.n,cls:r.cls,rank:r.rank,kind:'gen'})}
 return P}
function legHTML(o){const kind=legKind(o),max=LEGACY.slots[kind],P=legPool(o);if(!P.length)return '';
 const note=kind==='boss'?`Boss: up to ${max} free.`:kind==='story'?`Story mission: ${max} free slot.`:`${max} slot; costs that master ${LEGACY.loyCost} loyalty.`;
 return `<div class="legsup"><b class="eyebrow">Council support</b> <small class="muted">${note} Extra slots on top of the squad. If one falls, their seat is lost and the Council is shaken. Generals can fight once.</small>
 <div class="picks">${P.map(p=>`<button type="button" class="${LEG_PICK.includes(p.id)?'on':''}" data-cm="${p.id}">${p.n} · ${p.cls} R${p.rank}${p.kind==='gen'?' · General':p.kind==='npc'?'':' · your Master'}${kind==='any'?` · loyalty ${loyOf(p.id)}`:''}</button>`).join('')}</div></div>`}
const _squadScreenQ=squadScreen;
squadScreen=function(i,keep){if(!keep)LEG_PICK=[];_squadScreenQ(i,keep);const o=C.options[i],m=$('#modal'),box=m.querySelector('.sqbox'),end=box&&box.querySelector('.endrow');if(!o||!end)return;
 const ok=legPool(o).map(p=>p.id);LEG_PICK=LEG_PICK.filter(id=>ok.includes(id));end.insertAdjacentHTML('beforebegin',legHTML(o));
 const prev=m.onclick;m.onclick=ev=>{const b=ev.target.closest('[data-cm]');if(!b)return prev&&prev(ev);const id=b.dataset.cm,max=LEGACY.slots[legKind(o)];
  LEG_PICK=LEG_PICK.includes(id)?LEG_PICK.filter(x=>x!==id):LEG_PICK.length<max?[...LEG_PICK,id]:LEG_PICK;squadScreen(i,1)}};
// A Council master who isn't one of your units: built like a roster unit of their stance at LEGACY.masterRank, first option at every rank.
function masterEntry(id){const s=SEATS[id],cls=CLASS[s.stance]?s.stance:'Guardian',r={id:'cm_'+id,n:s.n,cls,rank:LEGACY.masterRank,title:'Master',col:'#f2e6b8',
 picks:[],spec:null,gear:{w:0,armor:'none',mods:[],saber:Math.min(2,SABERS.length-1),trait:null},bonus:{},fear:0,dark:0,stress:0,scars:[],log:[],quotes:[]};
 for(let k=1;k<=r.rank;k++){const op=treeOpts(r,k);if(!op.length)break;r.picks.push(op[0]);if(k===3)r.spec=Object.keys(TREES[cls].specs).find(n=>TREES[cls].specs[n].sig===op[0])}return r}
const _launchQ=launchMission;
launchMission=function(i,ids){const o=C.options[i],kind=o&&legKind(o),P=o?legPool(o):[];
 LEG_GO=LEG_PICK.map(id=>P.find(p=>p.id===id)).filter(Boolean).slice(0,kind?LEGACY.slots[kind]:0);LEG_PICK=[];
 for(const p of LEG_GO){C.leg.rest[p.id]=C.step+LEGACY.rest+1;if(kind==='any'&&p.kind!=='gen')addLoy(p.id,-LEGACY.loyCost);if(p.kind==='gen')C.leg.gf.push(p.id)}
 try{_launchQ(i,ids)}finally{LEG_GO=null}};
const _startQ=startMission;
startMission=function(id,sq,o){_startQ(id,sq,o);if(!LEG_GO||!LEG_GO.length||!S)return;
 for(const p of LEG_GO){const spot=freeNear();if(!spot)break;const base=p.kind==='npc'?battleUnit(masterEntry(p.id)):battleUnit(unit(p.id));
  const u=mk({...base,cm:p.kind==='npc'?p.id:null,legacy:p.kind},'p',{x:spot[0],y:spot[1]});S.units.push(u);log(`${p.n} joins the fight.`,'good')}
 if(typeof render==='function')render()};
function freeNear(){const st=S.M.start||[],seen=new Set(),q=st.map(p=>[p[0],p[1]]);
 while(q.length){const [x,y]=q.shift(),k=x+','+y;if(seen.has(k))continue;seen.add(k);if(!inb(x,y))continue;
  if(PASS(tile(x,y))&&!unitAt(x,y))return[x,y];if(seen.size>200)break;for(const [dx,dy] of [[0,1],[1,0],[0,-1],[-1,0]])q.push([x+dx,y+dy])}return null}
// After the fight: a fallen Council master empties their seat and shakes the rest. (Your own units fall the normal way; their seat empties too.)
const _applyQ=applyResults;
applyResults=function(win){const fell=S?S.units.filter(u=>u.side==='p'&&u.legacy&&u.legacy!=='gen'&&u.status==='dead').map(u=>({n:u.n,cm:u.cm})):[];
 const out=_applyQ(win);if(!fell.length)return out;ensureLife();
 for(const f of fell){if(f.cm&&!C.life.gone.includes(f.cm)){C.life.gone.push(f.cm);C.legends.push({n:f.n,cls:'Council master',how:'Fell beside the squad',where:S.M.n})}
  for(const m of members())addLoy(m.id,LEGACY.fallLoy);C.news.push(`<span class="bad">${f.n} fell in battle. Their Council seat is empty.</span> The Council is shaken: loyalty ${LEGACY.fallLoy} each.`);
  out.rows.push({n:f.n,xp:0,fate:'One with the Force · Council seat lost',rank:0,dark:null})}
 saveGame();return out};

// ── Hooks into the rest of the Temple ──
const _afterQ=templeAfterMission;
templeAfterMission=function(dep,win,o,out){_afterQ(dep,win,o,out);loreAfterMission(dep)};
const _advQ=templeAdvance;
templeAdvance=function(){_advQ();const g={};for(const r of C.roster)if(r.status==='active'&&['train','rest','calm'].includes(r.assign))(g[r.assign]=g[r.assign]||[]).push(r.id);
 for(const L of Object.values(g))for(let i=0;i<L.length;i++)for(let j=i+1;j<L.length;j++)bondPts(L[i],L[j],BOND.den,'time at the Temple')};
const _resolveQ=resolveField;
resolveField=function(o){_resolveQ(o);const T=(o.team||[]).filter(id=>{const r=unit(id);return r&&r.status==='active'});if(o.st!=='done')return;
 for(let i=0;i<T.length;i++){loreTick(unit(T[i]),'field');for(let j=i+1;j<T.length;j++)bondPts(T[i],T[j],BOND.field,'field op together')}};
const _oddsQ=fieldOdds;
fieldOdds=function(k,team,planet){const R=_oddsQ(k,team,planet),reg=planet&&PLANETS[planet]&&PLANETS[planet].reg,g=reg&&C.gen&&genOf(reg);
 if(!g||!R.why.length)return R;R.why.push([`General ${g.n}`,LEGACY.genField]);const raw=R.why.reduce((s,w)=>s+w[1],0);R.ch=Math.max(FIELD.min,Math.min(FIELD.max,raw));return R};
const _unrestQ=addUnrest;
addUnrest=function(reg,n,why){if(n>0&&reg&&C&&C.gen&&genOf(reg)){const room=LEGACY.genCap-unrestOf(reg);if(room<=0)return;n=Math.min(n,room)}_unrestQ(reg,n,why)};
const _questOptsQ=questOptions;
questOptions=function(){return _questOptsQ().map(o=>{const Q=o.quest&&C.quests[o.quest],S0=Q&&Q.sec&&SECRETS[Q.sec],r=o.quest&&unit(o.quest);
 return S0&&r?{...o,n:`${S0.n} · ${r.n}`,kind:'Secret',text:fill(S0.ask,r)}:o})};
const _recordQ=recordHTML;
recordHTML=function(r){ensureLegacy();return loreHTML(r)+bondsHTML(r)+_recordQ(r)+retireHTML(r)};
function bondsHTML(r){const L=Object.entries(C.bonds||{}).filter(([k])=>k.split('|').includes(r.id)).map(([k,v])=>({k,v,p:unit(k.split('|').find(x=>x!==r.id))})).filter(x=>x.p&&x.p.status!=='dead'&&(x.v.lvl||x.v.n));
 if(!L.length)return '';L.sort((a,b)=>b.v.lvl-a.v.lvl||b.v.n-a.v.n);
 return `<div class="bonds"><b class="eyebrow">Bonds</b>${L.map(({k,v,p})=>{const nd=bondNeed(v.lvl),pct=v.lvl>=BOND.max?100:Math.round(100*v.n/nd);
  return `<div class="bondrow"><div><b>${p.n}</b> · Bond ${v.lvl}/${BOND.max} <small class="muted">${v.lvl>=BOND.max?BOND_MAX_PERK.n+': '+BOND_MAX_PERK.desc:`${v.n}/${nd} to next`}</small>
  <div class="bbar"><i style="width:${pct}%"></i></div>${v.dr.length?`<small>Drills: ${v.dr.map(d=>DRILLS[d].n+' ('+DRILLS[d].desc+')').join(' · ')}</small>`:''}</div>
  ${v.offer?`<div class="picks">Pick a drill (both keep it): ${v.offer.map(d=>`<button type="button" data-act="drill:${k}:${d}" title="${DRILLS[d].desc}">${DRILLS[d].n} · ${DRILLS[d].desc}</button>`).join('')}</div>`:''}</div>`}).join('')}
  <small class="muted">Bond levels: ${BOND.aimAt}+ aim near each other · ${BOND.reactAt}+ answer when the other is hit · ${BOND.griefAt}+ a death hits hard · ${BOND.max} Unbreakable.</small></div>`}
const _councilQ=councilTab;
councilTab=function(){return _councilQ()+generalsHTML()};
const _lifeClickQ=lifeClick;
lifeClick=function(a,x,y){
 if(a==='drill'){pickDrill(x,y);return true}   // data-act="drill:<bond key a|b>:<drill>"
 if(a==='retire'){retireUnit(x,y==='council'?'council':'general',y==='council'?null:y);return true}
 if(a==='genpost'){const r=unit(x);if(r&&r.status==='retired'&&REG_N[y]){C.gen[x]=y;C.news.push(`General ${r.n} now guards the ${REG_N[y]}.`);saveGame()}return true}
 return _lifeClickQ(a,x,y)};

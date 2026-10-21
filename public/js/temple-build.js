/* Temple building (Chat T2): the cutaway's sublevel slots, wing placement, adjacency bonuses and each wing's room log.
   Data: data-wings.js. Draws into the Temple rail via templeMapHTML (temple-map.js). Styles: css/temple.css.
   Wraps (keeps the originals): buildWing (campaign.js), templeAdvance + templeMonth (temple.js), applyResults. */

// ── State ── C.slots {slotId:wing} · C.wlog {wing:[{d,t,c}]} · C.wsnap (last-seen state, for the log diff)
const slotOf=k=>C.slots&&Object.keys(C.slots).find(s=>C.slots[s]===k);
const slotById=id=>SLOTS.find(s=>s.id===id);
const nearSlots=id=>{const s=slotById(id);return SLOTS.filter(o=>Math.abs(o.f-s.f)+Math.abs(o.b-s.b)===1).map(o=>o.id)};
const freeSlots=()=>SLOTS.map(s=>s.id).filter(id=>!C.slots[id]&&(typeof slotOpen!=='function'||slotOpen(id)));
const wingUp=k=>(C.wings[k]||0)>0;
const pairsOf=k=>ADJ.filter(p=>p.a===k||p.b===k);
const partner=(p,k)=>p.a===k?p.b:p.a;

// Pairs that would touch if wing k sat in slot id (ignores level). Used to rank slots and preview links.
function linksAt(k,id){const near=nearSlots(id).map(s=>C.slots[s]).filter(Boolean);return pairsOf(k).filter(p=>near.includes(partner(p,k)))}
function bestSlot(k){const f=freeSlots();if(!f.length)return null;
 return f.map(id=>({id,sc:linksAt(k,id).length*10+(WING_HOME[k]===id?1:0)})).sort((a,b)=>b.sc-a.sc)[0].id}

function ensureSlots(){if(!C)return;C.slots=C.slots||{};C.wlog=C.wlog||{};
 const seen=new Set();for(const s of Object.keys(C.slots)){const k=C.slots[s];if(!slotById(s)||!WINGS[k]||seen.has(k))delete C.slots[s];else seen.add(k)}
 // Old saves: built wings (and the one under construction) drop into sensible slots.
 for(const k of Object.keys(WINGS))if((wingUp(k)||C.build===k)&&!slotOf(k)){const h=WING_HOME[k],s=h&&!C.slots[h]?h:bestSlot(k);if(s)C.slots[s]=k}}

// ── Adjacency ──
function pairOn(p){const sa=slotOf(p.a),sb=slotOf(p.b);return !!(sa&&sb&&wingUp(p.a)&&wingUp(p.b)&&nearSlots(sa).includes(sb))}
const pairMult=p=>C.staff&&(C.staff[p.a]||C.staff[p.b])?ADJ_STAFF_X:1;
const pairVal=p=>p.v*pairMult(p);
const pairTip=(p,v)=>p.tip.replace('{v}',v==null?pairVal(p):v);
const livePairs=()=>ADJ.filter(pairOn);
const adjSum=key=>livePairs().filter(p=>p.k===key).reduce((s,p)=>s+pairVal(p),0);

// Per-mission bonuses (from templeAdvance). Bench XP needs to know who deployed: set by the applyResults wrap.
let WB_DEP=null,WB_CTX='';
function adjAdvance(){const L=livePairs();if(!L.length)return;const got=[];
 const heal=adjSum('heal');if(heal){let n=0;for(const r of C.roster)if(r.status==='active'&&r.wound>0){r.wound=Math.max(0,r.wound-heal);n++}if(n)got.push(`${n} wounded healed ${heal} extra days`)}
 const rs=adjSum('research'),R=C.research;if(rs&&R&&R.cur&&C.wings.archives){R.prog+=rs;got.push(`research +${rs} days`)}
 const st=adjSum('stress');if(st&&typeof addStress==='function'){for(const r of C.roster)if(r.status==='active'&&r.stress>0){try{addStress(r,-st)}catch(e){r.stress=Math.max(0,r.stress-st)}}got.push(`all units −${st} stress`)}
 const bx=adjSum('bench');if(bx&&WB_DEP){let n=0;for(const r of C.roster)if(r.status==='active'&&!WB_DEP.has(r.id)){r.xp+=bx;n++;if(typeof promote==='function'&&promote(r))C.news.push(`${r.n} reached Rank ${r.rank} drilling at the Temple. Choose a new skill in the Roster.`)}if(n)got.push(`${n} benched units +${bx} XP`)}
 if(got.length)C.news.push(`Temple links: ${got.join(', ')}.`)}
function adjMonth(){const i=adjSum('intel'),c=adjSum('credits');if(i)gain('intel',i);if(c)gain('credits',c);
 if(i||c)C.news.push(`Temple links: ${[i&&`+${i} Intel`,c&&`+${c} Credits`].filter(Boolean).join(', ')}.`)}

// ── Room log ──
function wlogDate(){const by=C.story&&C.story.bby;return `${by?Number(by).toLocaleString('en-US')+' BBY · ':''}Mo ${C.month}`}
function wlog(k,t,c){if(!C.wlog||!WINGS[k])return;const L=C.wlog[k]=C.wlog[k]||[];L.unshift({d:wlogDate(),t,c:c||''});if(L.length>WLOG_MAX)L.length=WLOG_MAX}
const builtWings=()=>Object.keys(WINGS).filter(wingUp);
const homeOf=pref=>pref.find(k=>wingUp(k))||null;   // first built wing in a preference list

// Diff what changed since last look and write it into the right rooms. Safe to call any time.
function wingSync(){if(!C)return;ensureSlots();const P=C.wsnap,ctx=WB_CTX?` (${WB_CTX})`:'';
 const now={era:C.era||1,bby:C.story&&C.story.bby||0,lv:{...C.wings},staff:{...(C.staff||{})},u:{}};
 for(const r of C.roster)now.u[r.id]={n:r.n,rk:r.rank,st:r.status,w:r.wound>0?1:0};
 C.wsnap=now;if(!P){for(const k of builtWings())if(!(C.wlog[k]||[]).length)wlog(k,'Opened before the records began.','yr');return}
 if(P.era!==now.era){for(const k of builtWings())wlog(k,`Centuries pass. The ${WINGS[k].n} still stands at level ${C.wings[k]}.`,'yr');return}
 if(P.bby&&now.bby&&now.bby<P.bby)for(const k of builtWings())wlog(k,`Years pass. Now ~${Number(now.bby).toLocaleString('en-US')} BBY.`,'yr');
 for(const k of Object.keys(WINGS)){const a=P.lv[k]||0,b=now.lv[k]||0;
  if(b>a)wlog(k,a?`Upgraded to level ${b}: ${WINGS[k].eff[b]}`:`Construction done. The ${WINGS[k].n} opens.`,'up');
  else if(b<a)wlog(k,`Fell back to level ${b}.`,'bad');
  const sa=P.staff[k],sb=now.staff[k];if(sa!==sb){const o=sa&&unit(sa),n=sb&&unit(sb);
   if(o)wlog(k,`${o.n} ${o.status==='retired'?'retires from':o.status==='dead'?'is gone from':'leaves'} the staff post.`);
   if(n)wlog(k,`${n.n} takes the staff post${n.status==='retired'?' in retirement':''}.`,'up')}}
 for(const r of C.roster){const o=P.u[r.id];if(!o)continue;
  if(o.st!=='dead'&&r.status==='dead'){const k=homeOf(['barracks']);if(k)wlog(k,`${r.n}'s bunk is empty. Fell${ctx}.`,'dead');const t=homeOf(['gardens','archives']);if(t)wlog(t,`A candle for ${r.n}.`,'dead')}
  else if(o.st==='active'&&r.status==='captured'){const k=homeOf(['comms','barracks']);if(k)wlog(k,`${r.n} taken by the Sith${ctx}.`,'bad')}
  else if(o.st==='captured'&&r.status==='active'){const k=homeOf(['medical','barracks']);if(k)wlog(k,`${r.n} came home from the cells.`,'good')}
  else if(o.st==='active'&&r.status==='retired'){const k=homeOf(['barracks']);if(k)wlog(k,`${r.n} hangs up the blaster for good.`.replace('the blaster',isJedi(r)?'the saber':'the blaster'))}
  if(r.status==='active'){if(!o.w&&r.wound>0){const k=homeOf(['medical']);if(k)wlog(k,`${r.n} admitted: ${r.wound} days${ctx}.`)}
   if(r.rank>o.rk){const k=homeOf(['training','barracks']);if(k)wlog(k,`${r.n} made Rank ${r.rank}${ctx}.`,'up')}}}}

// ── Placement ──
// A new wing can be moved for free while it is still scaffolding (level 0, under construction).
const movable=k=>k&&C.build===k&&!wingUp(k);
function placeWing(k,id){ensureSlots();if(C.slots[id]||!WINGS[k])return false;const cur=slotOf(k);
 if(cur&&!movable(k))return false;if(cur)delete C.slots[cur];C.slots[id]=k;
 if(cur)wlog(k,`Builders moved the dig to ${slotById(id).n}.`);return true}
function buildAt(k,id){if(slotOf(k)||C.slots[id])return;C.slots[id]=k;buildWing(k);if(C.build!==k)delete C.slots[id]}

// ── Cutaway (the left rail) ──
let MOVE=null;   // wing being moved (scaffold only)
function linkHTML(p,s1,s2,prev){const A=slotById(s1),B=slotById(s2),h=A.f===B.f,f=Math.min(A.f,B.f),b=Math.min(A.b,B.b);
 const row=h?f*2-1:f*2,col=h?b*2+2:b*2+1;
 return `<i class="lnk ${h?'h':'v'} ${prev?'prev':''} ${!prev&&pairMult(p)>1?'x2':''}" style="grid-row:${row};grid-column:${col}" title="${p.n}: ${pairTip(p)}"></i>`}
function cutawayHTML(pend,cur){try{wingSync()}catch(e){ensureSlots()}const mv=MOVE&&movable(MOVE)?MOVE:null;if(!mv)MOVE=null;
 const room=(id,cls,extra)=>{const r=roomOf(id);return `<button type="button" class="room ${cls||''} ${r.id===cur?'on':''}" data-room="${r.id}" title="${r.n}" aria-pressed="${r.id===cur}">${icon(r.ic)}<b>${r.s||r.n}</b><small>${roomLine(r)}</small>${extra||''}</button>`};
 const cells=SLOTS.filter(s=>typeof slotOpen!=='function'||slotOpen(s.id)).map(s=>{const k=C.slots[s.id],pos=`grid-row:${s.f*2-1};grid-column:${s.b*2+1}`;
  if(!k){const pv=mv?linksAt(mv,s.id):[],sel=cur==='slot:'+s.id,D=typeof slotDeco==='function'?slotDeco(s.id):{cls:'',html:''};
   if(D.cls&&!mv)return `<button type="button" class="slot ${D.cls} ${sel?'on':''}" style="${pos}" data-slot="${s.id}" title="${s.n}">${D.html}</button>`;
   return `<button type="button" class="slot ${mv?'tgt':''} ${sel?'on':''}" style="${pos}" data-slot="${s.id}" title="${s.n}: ${mv?'move the dig here':'empty · build a wing here'}">${mv?`<b>Move here</b><small>${pv.length?pv.map(p=>p.n).join(', '):'no links'}</small>`:`<b>+</b><small>${s.sn}</small>`}</button>`}
  const r=roomOf(k),l=C.wings[k],mx=WINGS[k].cost.length-1,bld=C.build===k,badge=k==='barracks'&&pend?`<em title="${pend} unit${pend>1?'s':''} can rank up">${pend}</em>`:'',st=C.staff&&C.staff[k]&&unit(C.staff[k]);
  const RD=typeof roomDeco==='function'?roomDeco(k):{cls:'',html:''};
  return `<button type="button" class="room wingrm ${!l?'bld':bld?'upg':''} ${RD.cls} ${k===cur?'on':''}" style="${pos}" data-room="${k}" title="${WINGS[k].n} · ${s.n}" aria-pressed="${k===cur}">${icon(r.ic)}<b>${WING_SHORT[k]||r.n}</b>
   <span class="lv" aria-label="Level ${l} of ${mx}">${Array.from({length:mx},(_,i)=>`<i class="${i<l?'on':''}"></i>`).join('')}</span><small>${!l?'Building…':bld?'Upgrading…':st?st.n.split(' ')[0]:roomLine(r)}</small>${st?'<span class="stf" title="Staffed"></span>':''}${badge}${RD.html}</button>`}).join('');
 const links=[];for(const p of ADJ)if(pairOn(p)){const a=slotOf(p.a),b=slotOf(p.b);links.push(linkHTML(p,a,b))}
 if(mv)for(const s of freeSlots())for(const p of linksAt(mv,s))links.push(linkHTML(p,s,slotOf(partner(p,mv)),1));
 return `<div class="tcut">
 <svg class="tspires" viewBox="0 0 300 64" preserveAspectRatio="none" aria-hidden="true"><path d="M0 64 L28 40 L272 40 L300 64Z" class="zig"/>
  <path d="M40 40 V14 L44 6 L48 14 V40 M252 40 V14 L256 6 L260 14 V40 M100 40 V20 L104 12 L108 20 V40 M192 40 V20 L196 12 L200 20 V40 M144 40 V8 L150 0 L156 8 V40" class="spire"/></svg>
 <div class="tzig">${room('council','crown')}<div class="tgr">${room('war','wr')}${room('hangar','hg')}</div></div>
 <div class="tsurf"><span>Surface</span><span>Sublevels</span></div>
 <div class="tsub">${cells}${links.join('')}</div>
 ${room('under','deep')}</div>
 ${mv?`<p class="tmove">${icon('relay')} Moving the ${WINGS[mv].n} dig. Pick a lit slot. <button type="button" data-act="nomove">Cancel</button></p>`:''}`}

// ── Room panel extras: location, links, room log ──
function wingSideHTML(k){ensureSlots();const s=slotOf(k),L=pairsOf(k),log=(C.wlog&&C.wlog[k])||[];
 const lk=L.map(p=>{const o=partner(p,k),on=pairOn(p),touch=s&&slotOf(o)&&nearSlots(s).includes(slotOf(o)),x=on&&pairMult(p)>1;
  return `<li class="${on?'on':''}"><b>${p.n}</b> <small>with ${WINGS[o].n}</small> · ${pairTip(p)}${x?' <span class="up">×2 staffed</span>':''}
   <small class="muted">${on?(x?'':' Staff either wing to double it.'):touch?' Shares a wall: works once both are built.':` Needs the ${WINGS[o].n} next door.`}</small></li>`}).join('');
 const mv=movable(k)?`<button type="button" data-act="move:${k}" ${freeSlots().length?'':'disabled'}>Move the dig</button>`:'';
 return `<div class="wside"><div class="wloc">${icon('collapse')} <b>${s?slotById(s).n:'Not placed yet'}</b> ${mv}</div>
 <h3 class="eyebrow">Adjacency</h3><ul class="adj">${lk}</ul>
 <h3 class="eyebrow">Room log</h3>${log.length?`<ol class="wlog">${log.map(e=>`<li class="${e.c}"><span>${e.d}</span>${e.t}</li>`).join('')}</ol>`:'<p class="muted">Nothing has happened here yet.</p>'}</div>`}

// Empty slot picked: what can go here, and what it would link to.
function slotPanelHTML(id){const s=slotById(id),busy=C.build;
 const opts=Object.keys(WINGS).filter(k=>!wingUp(k)&&!slotOf(k)).map(k=>{const w=WINGS[k],c=w.cost[1],lk=linksAt(k,id),req=w.req&&w.req[1];
  return `<div class="wing"><div><b>${w.n}</b> <small>${c} Cr</small><p>${w.eff[1]}</p><p class="muted">${lk.length?`Links here: ${lk.map(p=>`<b>${p.n}</b> (${pairTip(p,p.v)})`).join(' · ')}`:'No links in this spot.'}</p></div>
  <button type="button" data-act="buildat:${k}:${id}" ${busy||C.res.credits<c||(req&&!researched(req))?'disabled':''}>Build here · ${c} Cr</button></div>`}).join('');
 return `<p class="muted">${s.n}. Excavated rock, waiting for a wing. Wings that share a wall with their partner earn a bonus.${busy?` <span class="warn">One build at a time: the ${WINGS[busy].n} is under way.</span>`:''}</p>${opts||'<p class="muted">Every wing is built or being built.</p>'}`}

// Clicks from the Temple screen. Returns true when handled.
function buildClick(ev){const sl=ev.target.closest('[data-slot]');
 if(sl){const id=sl.dataset.slot;if(MOVE&&movable(MOVE)){if(placeWing(MOVE,id)){setRoom(MOVE);saveGame()}MOVE=null}else{ROOM='slot:'+id}return true}
 const b=ev.target.closest('[data-act]');if(!b||b.disabled)return false;const [a,x,y]=b.dataset.act.split(':');
 if(a==='move'){MOVE=x;return true}if(a==='nomove'){MOVE=null;return true}
 if(a==='buildat'){buildAt(x,y);if(C.build===x)setRoom(x);return true}return false}

// ── Wraps ──
const _bwT2=buildWing;
buildWing=function(k,...rest){ensureSlots();const had=slotOf(k),lv=C.wings[k],s=had||bestSlot(k);if(!s)return;
 _bwT2(k,...rest);if(C.build!==k)return;if(!had)C.slots[s]=k;
 wlog(k,lv?`Work begins on level ${lv+1}.`:`Ground broken in ${slotById(slotOf(k)).n}.`,'up')};
const _taT2=templeAdvance;templeAdvance=function(){_taT2();try{adjAdvance();wingSync()}catch(e){console.error(e)}};
const _tmT2=templeMonth;templeMonth=function(){_tmT2();try{adjMonth()}catch(e){console.error(e)}};
const _arT2=applyResults;
applyResults=function(win){const M=S&&S.M;try{ensureSlots();wingSync()}catch(e){}
 WB_DEP=new Set(S?S.units.filter(u=>u.side==='p'&&u.rid).map(u=>u.rid):[]);WB_CTX=M&&M.n||'';
 let out;try{out=_arT2(win);if(win){const c=adjSum('winCr');if(c){gain('credits',c,out&&out.res);C.news.push(`Shared Smithy salvage: +${c} Credits.`)}}
  const k=homeOf(['comms']);if(k&&M)wlog(k,`${M.n}: ${win?'won':'lost'}.`,win?'good':'bad');wingSync()}
 finally{WB_DEP=null;WB_CTX=''}return out};

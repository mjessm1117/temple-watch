/* Temple modules (Coordinator, 2026-10-21): wing actions, excavation + bay features, a living cutaway. Data: data-modules.js.
   State C.mods = {cd:{wing:missions}, next:{aim,jdmg,tarmor,kit,crit}, dug:{slot:1}, digging:slot|null, feat:{slot:key}}.
   Growth (2026-10-21): terraces open with wings/time, 4 spires (C.mods.spire, C.mods.spireB), undercroft vaults (C.mods.dug/feat/digging).
   Hooks used by temple-build.js: slotDeco(id), roomDeco(k). Wraps: wingSideHTML, slotPanelHTML, buildClick, buildAt, bestSlot,
   templeAdvance, templeMonth, applyResults, startMission. */

function ensureMods(){if(!C)return null;ensureSlots();const M=C.mods=C.mods||{cd:{},next:{},dug:{},digging:null,feat:{}};
 M.spire=M.spire||{};M.open=M.open||{};
 // Undercroft finds: one Great Kyber cave plus two others, rolled once per campaign.
 const U=SLOTS.filter(s=>s.tier==='u');if(!U.every(s=>BAY_FEAT[M.feat[s.id]])){const pool=[...UNDER_POOL].sort(()=>Math.random()-.5),k=Math.floor(Math.random()*U.length);
  U.forEach((s,i)=>M.feat[s.id]=i===k?'kyber2':pool.pop())}
 return M}
const wingCount=()=>Object.keys(WINGS).filter(k=>(C.wings[k]||0)>0).length;
// A tier is open by growth (wings built) or time (month / era); a bay that already holds a wing always shows.
function tierOpen(t){const o=TIER_OPEN[t];if(!o||!C)return true;return (o.wings&&wingCount()>=o.wings)||(o.month&&C.month>=o.month)||(o.era&&(C.era||1)>=o.era)}
const slotOpen=id=>{const s=slotById(id);return !!s&&(s.tier==='sp'||s.tier==='u'||tierOpen(s.tier)||!!(C.slots&&C.slots[id]))};
const bayDug=id=>{const s=slotById(id);if(!s)return false;if(s.tier!=='u')return true;const M=ensureMods();return !!(M&&M.dug[id])};
const bayFeat=id=>{const M=ensureMods(),s=slotById(id);return M&&s&&s.tier==='u'&&M.dug[id]?BAY_FEAT[M.feat[id]]:null};
// Finds that pay right now: dug, and their wing (if any) is built somewhere.
function bayLive(){const M=ensureMods(),out=[];if(!M)return out;for(const s of SLOTS.filter(s=>s.tier==='u')){const f=bayFeat(s.id);if(f&&(!f.wings.length||f.wings.some(wingUp)))out.push({s,k:f.wings.find(wingUp)||null,f})}return out}
// Spires count as finds for the per-mission / monthly payouts.
const spireLive=()=>Object.keys(SPIRES).filter(k=>C&&C.mods&&C.mods.spire[k]);
const baySum=key=>bayLive().reduce((n,x)=>n+(x.f[key]||0),0)+spireLive().reduce((n,k)=>n+(SPIRES[k].eff[key]||0),0);
const spireOpen=()=>C&&(C.month>=SPIRE_OPEN.month||(C.era||1)>=SPIRE_OPEN.era);

// ── Wing actions ──
const modCd=k=>Math.max(1,MOD_ACTS[k].cd-((C.wings[k]||0)>=2?1:0));
const modReady=k=>{const M=ensureMods();return !!(M&&MOD_ACTS[k]&&wingUp(k)&&!(M.cd[k]>0))};
const modPay=c=>Object.entries(c||{}).every(([r,n])=>(C.res[r]||0)>=n);
const modCost=c=>Object.entries(c||{}).map(([r,n])=>`${n} ${({credits:'Cr',kyber:'Kyber',intel:'Intel',recruits:'Recruits',favor:'Favor'})[r]||r}`).join(' + ')||'free';
function modUse(k){const A=MOD_ACTS[k],M=ensureMods();if(!A||!modReady(k)||!modPay(A.cost))return;
 for(const [r,n] of Object.entries(A.cost))gain(r,-n);let msg='';
 if(A.now==='heal'){const L=C.roster.filter(r=>r.status==='active'&&r.wound>0).sort((a,b)=>b.wound-a.wound).slice(0,(C.wings.medical||0)>=2?2:1);
  for(const r of L)r.wound=0;msg=L.length?`${L.map(r=>r.n).join(' and ')} back on their feet.`:'No one needed it. The bacta keeps.'}
 else if(A.now==='intel'){gain('intel',3);msg='+3 Intel.'}
 else if(A.now==='calm'){for(const r of C.roster)if(r.status==='active'){try{addStress(r,-20)}catch(e){r.stress=Math.max(0,(r.stress||0)-20)}}
  const j=C.roster.filter(r=>r.status==='active'&&isJedi(r)&&r.dark>0).sort((a,b)=>b.dark-a.dark)[0];if(j)j.dark--;msg=`Stress eases across the Temple${j?`; ${j.n} sheds 1 Darkness`:''}.`}
 else if(A.now==='recruit'){gain('recruits',1);msg='+1 Recruit.'}
 if(A.next){for(const [s,v] of Object.entries(A.next))M.next[s]=(M.next[s]||0)+v;msg='Ready for the next battle.'}
 M.cd[k]=modCd(k);C.news.push(`${A.n}: ${msg}`);wlog(k,`${A.n}. ${msg}`,'up');saveGame()}
const NEXT_TXT={aim:v=>`+${v} aim`,jdmg:v=>`Jedi +${v} damage`,tarmor:v=>`troopers +${v} armor`,kit:v=>`troopers +${v} grenade/medkit`,crit:v=>`+${v}% crit`};
const modNext=()=>{const N=(C&&C.mods&&C.mods.next)||{};return Object.entries(N).filter(([,v])=>v).map(([k,v])=>NEXT_TXT[k](v)).join(', ')};

// Battle: queued buffs land on the squad at deploy, then clear.
const _smTM=startMission;startMission=function(...a){const r=_smTM.apply(this,a);try{const W=baySum('will');if(W&&S)for(const u of S.units.filter(u=>u.side==='p'&&u.rid))u.will=(u.will||0)+W;const N=C&&C.mods&&C.mods.next;if(N&&S&&Object.values(N).some(Boolean)){
  for(const u of S.units.filter(u=>u.side==='p'&&u.rid&&!u.vip)){if(N.aim)u.aim+=N.aim;if(N.crit)u.crit=(u.crit||0)+N.crit;
   if(u.jedi){if(N.jdmg)u.dmg=[u.dmg[0]+N.jdmg,u.dmg[1]+N.jdmg]}else{if(N.tarmor){u.armor=(u.armor||0)+N.tarmor;u.armorMax=Math.max(u.armorMax||0,u.armor)}
    if(N.kit){if(u.nades!=null)u.nades+=N.kit;else if(u.kits!=null)u.kits+=N.kit}}}
  log(`Temple support: ${modNext()}.`,'good');C.mods.next={};if(typeof render==='function')render()}}catch(e){console.error(e)}return r};

// ── Undercroft digs + spire builds ──
function bayDig(id){const M=ensureMods(),s=slotById(id),c=UNDER_DIG[id]||0;if(!s||s.tier!=='u'||M.dug[id]||M.digging||C.res.credits<c)return;gain('credits',-c);M.digging=id;C.news.push(`Diggers break into ${s.n}.`);saveGame()}
function bayDone(){const M=ensureMods();if(!M||!M.digging)return;const id=M.digging,s=slotById(id);M.dug[id]=1;M.digging=null;const f=bayFeat(id);
 for(const [r,n] of Object.entries(f.found||{}))gain(r,n);C.news.push(`${s.n} is open. Found: ${f.n}. ${f.tip}`)}
function spireBuild(id){const M=ensureMods(),S0=SPIRES[id];if(!S0||M.spire[id]||M.spireB||!spireOpen()||!modPay(SPIRE_COST))return;for(const [r,n] of Object.entries(SPIRE_COST))gain(r,-n);
 M.spireB={id,left:SPIRE_TIME};C.news.push(`Scaffolds climb the Temple: the ${S0.n} begins to rise.`);saveGame()}
function spireTick(){const M=ensureMods(),B=M&&M.spireB;if(!B)return;if(--B.left>0)return;M.spire[B.id]=1;M.spireB=null;C.news.push(`<span class="up">The ${SPIRES[B.id].n} is complete.</span> ${SPIRES[B.id].tip}`)}

// ── Per mission / month ──
const _taTM=templeAdvance;templeAdvance=function(){_taTM();try{const M=ensureMods();
 for(const t of Object.keys(TIER_OPEN))if(tierOpen(t)&&!M.open[t]){M.open[t]=1;C.news.push(`The Temple grows: the ${TIER_N[t].toLowerCase()} is ready for new wings.`)}
 if(spireOpen()&&!M.open.sp){M.open.sp=1;C.news.push('The Council approves new towers. The four spires can now be raised.')}
 for(const k of Object.keys(M.cd))if(M.cd[k]>0)M.cd[k]--;bayDone();spireTick();
 const got=[],heal=baySum('heal'),st=baySum('stress'),rs=baySum('research');
 if(heal){for(const r of C.roster)if(r.status==='active'&&r.wound>0)r.wound=Math.max(0,r.wound-heal);got.push(`wounds −${heal} days`)}
 if(st){for(const r of C.roster)if(r.status==='active'&&r.stress>0){try{addStress(r,-st)}catch(e){}}got.push(`stress −${st}`)}
 if(rs&&C.research&&C.research.cur&&C.wings.archives){C.research.prog+=rs;got.push(`research +${rs} days`)}
 if(got.length)C.news.push(`Bay features: ${got.join(', ')}.`)}catch(e){console.error(e)}};
const _tmTM=templeMonth;templeMonth=function(){_tmTM();try{const L=[...bayLive().map(x=>x.f),...spireLive().map(k=>({n:SPIRES[k].n,month:SPIRES[k].eff.month}))];for(const f of L)for(const [r,n] of Object.entries(f.month||{}))gain(r,n);
 const t=L.filter(f=>f.month).map(f=>f.n);if(t.length)C.news.push(`Bay features pay out: ${t.join(', ')}.`)}catch(e){console.error(e)}};
const _arTM=applyResults;applyResults=function(win){const dep=new Set(S?S.units.filter(u=>u.side==='p'&&u.rid).map(u=>u.rid):[]),out=_arTM(win);
 try{const c=baySum('winCr');if(win&&c){gain('credits',c,out&&out.res);C.news.push(`Arms cache salvage: +${c} Credits.`)}
  const b=baySum('bench');if(b)for(const r of C.roster)if(r.status==='active'&&!dep.has(r.id)){r.xp+=b;if(typeof promote==='function')promote(r)}
  const x=baySum('xp');if(x)for(const r of C.roster)if(r.status==='active'&&dep.has(r.id))r.xp+=x}catch(e){console.error(e)}return out};

// ── Placement only on open wing bays ──
const _baTM=buildAt;buildAt=function(k,id){const s=slotById(id);if(!s||!s.wing||!slotOpen(id))return;return _baTM(k,id)};

// ── Cutaway decoration (called from temple-build.js) ──
function slotDeco(id){const M=ensureMods();if(!M)return {cls:'',html:''};const s=slotById(id);
 if(s.tier==='u'){if(M.digging===id)return {cls:'dig',html:`<b>Digging…</b><small>${s.sn}</small><span class="drill"></span>`};
  if(!M.dug[id])return {cls:'rock',html:`<b>Vault</b><small>Dig · ${UNDER_DIG[id]} Cr</small>`};const f=bayFeat(id),on=bayLive().some(x=>x.s===s);
  return {cls:'found'+(on?' on':''),html:`${icon(f.ic)}<b>${f.n}</b><small>${on?'Active':'Needs '+f.wings.map(w=>WING_SHORT[w]).join('/')}</small>`}}
 if(!slotOpen(id))return {cls:'locked',html:`<small>${TIER_WHY[s.tier]||'Locked'}</small>`};
 return {cls:'',html:''}}
function roomDeco(k){const M=ensureMods();if(!M)return {cls:'',html:''};const A=C.roster.filter(r=>r.status==='active');
 const n=k==='medical'?A.filter(r=>r.wound>0).length:k==='gardens'?A.filter(r=>r.assign==='calm').length:k==='training'?A.filter(r=>r.assign==='train').length:k==='barracks'?Math.min(4,A.filter(r=>!r.wound&&!r.assign).length):0;
 const st=C.staff&&C.staff[k]?1:0,ppl=Math.min(5,n+st),f=null;
 return {cls:modReady(k)?'ready':'',html:(ppl?`<span class="ppl" aria-hidden="true">${'<i></i>'.repeat(ppl)}</span>`:'')+(f?`<span class="feat on" title="${f.f.n}: ${f.f.tip}">${icon(f.f.ic)}</span>`:'')}}

// ── Room panel: action card on top ──
const _wsTM=wingSideHTML;wingSideHTML=function(k){const A=MOD_ACTS[k],M=ensureMods();let h='';
 if(A&&M){const up=wingUp(k),rd=modReady(k),pay=modPay(A.cost);
  h=`<div class="modact ${rd?'rd':''}">${icon(A.ic)}<div><b>${A.n}</b> <small class="muted">${modCost(A.cost)} · every ${modCd(k)} mission${modCd(k)>1?'s':''}</small><p>${A.desc}</p></div>
  <button type="button" class="primary" data-act="modact:${k}" ${up&&rd&&pay?'':'disabled'}>${!up?'Build first':rd?(pay?'Use now':'Can’t afford'):`Ready in ${M.cd[k]}`}</button></div>`;
  if(M.next&&modNext())h+=`<p class="flag">Next battle: ${modNext()}.</p>`}
 const fs=bayLive().filter(x=>x.f.wings.includes(k));for(const x of fs)h+=`<p class="up">${icon(x.f.ic)} Undercroft find powered by this wing: <b>${x.f.n}</b>. ${x.f.tip}</p>`;
 return h+_wsTM(k)};
const _spTM=slotPanelHTML;slotPanelHTML=function(id){const M=ensureMods(),s=slotById(id);
 if(s.tier==='sp'){const P=SPIRES[id],B=M.spireB;
  if(M.spire[id])return `<p class="up">${icon(P.ic)} <b>${P.n}</b> stands over the Temple. ${P.tip}</p>`;
  if(B&&B.id===id)return `<p>${icon(P.ic)} <b>${P.n}</b>: scaffolds climbing. Done in ${B.left} mission${B.left>1?'s':''}.</p>`;
  return `<p>${icon(P.ic)} <b>${P.n}</b>. ${P.tip}</p><button type="button" class="primary" data-act="spire:${id}" ${!spireOpen()||B||!modPay(SPIRE_COST)?'disabled':''}>Raise the tower · ${modCost(SPIRE_COST)} · ${SPIRE_TIME} missions</button>
   <small class="muted">${!spireOpen()?' The Council allows new towers from month 4.':B?' One tower at a time.':''}</small>`}
 if(s.tier==='u'){if(M.digging===id)return `<p>${s.n}: the diggers are at work. Open after the next mission.</p>`;
  if(!M.dug[id])return `<p>${s.n}: a sealed chamber under the base hall. Dig it out for a rare find: a Kyber cave, a holocron chamber, a Jedi crypt…</p>
   <button type="button" class="primary" data-act="dig:${id}" ${M.digging||C.res.credits<UNDER_DIG[id]?'disabled':''}>Dig · ${UNDER_DIG[id]} Cr · 1 mission</button>${M.digging?' <small class="muted">One dig at a time.</small>':''}`;
  const f=bayFeat(id);return `<p class="flag">${icon(f.ic)} <b>${f.n}</b>: ${f.tip}</p>`}
 if(!slotOpen(id))return `<p class="muted">${s.n}: ${TIER_WHY[s.tier]}. The Temple grows as the Order does.</p>`;
 return _spTM(id)};
const _bcTM=buildClick;buildClick=function(ev){const b=ev.target.closest('[data-act]');if(b&&!b.disabled){const [a,x]=b.dataset.act.split(':');
  if(a==='modact'){modUse(x);return true}if(a==='dig'){bayDig(x);return true}if(a==='spire'){spireBuild(x);return true}}return _bcTM(ev)};

// Sith schemes with custom effects (data in data-modules.js).
const _ohTM=opHits;opHits=function(o){_ohTM(o);try{const D=SITH_OPS[o.k],M=ensureMods();
 if(D.jam){const W=Object.keys(MOD_ACTS).filter(wingUp).sort(()=>Math.random()-.5).slice(0,D.jam);for(const k of W){M.cd[k]=Math.max(M.cd[k]||0,3);wlog(k,'Saboteurs wrecked the controls. Out for 3 missions.','bad')}if(W.length)C.news.push(`Jammed: ${W.map(k=>MOD_ACTS[k].n).join(', ')}.`)}
 if(D.hunt){const r=C.roster.filter(r=>r.status==='active').sort((a,b)=>(b.rank||1)-(a.rank||1)||(b.kills||0)-(a.kills||0))[0];if(r){r.wound=Math.max(r.wound||0,14);try{addStress(r,30)}catch(e){}C.news.push(`The Sith hunter found ${r.n}: 14 days wounded.`)}}}catch(e){console.error(e)}};

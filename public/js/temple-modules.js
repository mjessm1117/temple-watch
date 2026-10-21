/* Temple modules (Coordinator, 2026-10-21): wing actions, excavation + bay features, a living cutaway. Data: data-modules.js.
   State C.mods = {cd:{wing:missions}, next:{aim,jdmg,tarmor,kit,crit}, dug:{slot:1}, digging:slot|null, feat:{slot:key}}.
   Hooks used by temple-build.js: slotDeco(id), roomDeco(k). Wraps: wingSideHTML, slotPanelHTML, buildClick, buildAt, bestSlot,
   templeAdvance, templeMonth, applyResults, startMission. */

function ensureMods(){if(!C)return null;ensureSlots();const M=C.mods=C.mods||{cd:{},next:{},dug:{},digging:null,feat:{}};
 for(const s of SLOTS){if(s.f===1||C.slots[s.id])M.dug[s.id]=1;
  if(!M.feat[s.id]){const P=s.f>3?DEEP_FEAT_POOL:BAY_FEAT_POOL;M.feat[s.id]=s.f===1?'rubble':P[Math.floor(Math.random()*P.length)]}}
 M.open=M.open||{};
 // One of the deep bays always holds a Kyber vein, so the Forge has a real home to fight for.
 if(!SLOTS.some(s=>s.f>1&&M.feat[s.id]==='kyber')){const d=SLOTS.filter(s=>s.f>1&&s.f<4&&!M.dug[s.id]);if(d.length)M.feat[d[Math.floor(Math.random()*d.length)].id]='kyber'}
 return M}
// Floors 4–5 open by month or era. Hidden floors are skipped by the cutaway and by placement.
const floorOpen=f=>{const o=DEEP_OPEN[f];return !o||(C&&(C.month>=o.month||(C.era||1)>=o.era))};
const slotOpen=id=>{const s=slotById(id);return !!s&&floorOpen(s.f)};
const bayDug=id=>{const M=ensureMods();return !!(M&&M.dug[id])};
const bayFeat=id=>{const M=ensureMods();return M&&M.dug[id]?BAY_FEAT[M.feat[id]]:null};
// Features whose wing sits on top and is built.
function bayLive(){const M=ensureMods(),out=[];if(!M)return out;for(const s of SLOTS){const k=C.slots[s.id],f=bayFeat(s.id);if(k&&f&&f.wings.includes(k)&&wingUp(k))out.push({s,k,f})}return out}
const baySum=key=>bayLive().reduce((n,x)=>n+(x.f[key]||0),0);

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
const _smTM=startMission;startMission=function(...a){const r=_smTM.apply(this,a);try{const N=C&&C.mods&&C.mods.next;if(N&&S&&Object.values(N).some(Boolean)){
  for(const u of S.units.filter(u=>u.side==='p'&&u.rid&&!u.vip)){if(N.aim)u.aim+=N.aim;if(N.crit)u.crit=(u.crit||0)+N.crit;
   if(u.jedi){if(N.jdmg)u.dmg=[u.dmg[0]+N.jdmg,u.dmg[1]+N.jdmg]}else{if(N.tarmor){u.armor=(u.armor||0)+N.tarmor;u.armorMax=Math.max(u.armorMax||0,u.armor)}
    if(N.kit){if(u.nades!=null)u.nades+=N.kit;else if(u.kits!=null)u.kits+=N.kit}}}
  log(`Temple support: ${modNext()}.`,'good');C.mods.next={};if(typeof render==='function')render()}}catch(e){console.error(e)}return r};

// ── Excavation ──
function bayDig(id){const M=ensureMods(),s=slotById(id),c=DIG_COST[s.f]||0;if(!s||M.dug[id]||M.digging||C.res.credits<c)return;gain('credits',-c);M.digging=id;C.news.push(`Diggers break into ${s.n}.`);saveGame()}
function bayDone(){const M=ensureMods();if(!M||!M.digging)return;const id=M.digging,s=slotById(id);M.dug[id]=1;M.digging=null;const f=bayFeat(id);
 for(const [r,n] of Object.entries(f.found||{}))gain(r,n);C.news.push(`${s.n} is open. Found: ${f.n}. ${f.tip}`)}

// ── Per mission / month ──
const _taTM=templeAdvance;templeAdvance=function(){_taTM();try{const M=ensureMods();
 for(const f of Object.keys(DEEP_OPEN))if(floorOpen(+f)&&!M.open[f]){M.open[f]=1;C.news.push(`Surveyors break through below the Temple: Sublevel ${f} can be dug. Rare finds wait down there.`)}for(const k of Object.keys(M.cd))if(M.cd[k]>0)M.cd[k]--;bayDone();
 const got=[],heal=baySum('heal'),st=baySum('stress'),rs=baySum('research');
 if(heal){for(const r of C.roster)if(r.status==='active'&&r.wound>0)r.wound=Math.max(0,r.wound-heal);got.push(`wounds −${heal} days`)}
 if(st){for(const r of C.roster)if(r.status==='active'&&r.stress>0){try{addStress(r,-st)}catch(e){}}got.push(`stress −${st}`)}
 if(rs&&C.research&&C.research.cur&&C.wings.archives){C.research.prog+=rs;got.push(`research +${rs} days`)}
 if(got.length)C.news.push(`Bay features: ${got.join(', ')}.`)}catch(e){console.error(e)}};
const _tmTM=templeMonth;templeMonth=function(){_tmTM();try{const L=bayLive();for(const x of L)for(const [r,n] of Object.entries(x.f.month||{}))gain(r,n);
 const t=L.filter(x=>x.f.month).map(x=>x.f.n);if(t.length)C.news.push(`Bay features pay out: ${t.join(', ')}.`)}catch(e){console.error(e)}};
const _arTM=applyResults;applyResults=function(win){const dep=new Set(S?S.units.filter(u=>u.side==='p'&&u.rid).map(u=>u.rid):[]),out=_arTM(win);
 try{const c=baySum('winCr');if(win&&c){gain('credits',c,out&&out.res);C.news.push(`Arms cache salvage: +${c} Credits.`)}
  const b=baySum('bench');if(b)for(const r of C.roster)if(r.status==='active'&&!dep.has(r.id)){r.xp+=b;if(typeof promote==='function')promote(r)}}catch(e){console.error(e)}return out};

// ── Placement only on open bays ──
const _baTM=buildAt;buildAt=function(k,id){if(!bayDug(id))return;return _baTM(k,id)};
const _bsTM=bestSlot;bestSlot=function(k){const f=freeSlots().filter(bayDug);if(!f.length)return _bsTM(k);
 return f.map(id=>({id,sc:linksAt(k,id).length*10+(bayFeat(id)&&bayFeat(id).wings.includes(k)?15:0)+(WING_HOME[k]===id?1:0)})).sort((a,b)=>b.sc-a.sc)[0].id};

// ── Cutaway decoration (called from temple-build.js) ──
function slotDeco(id){const M=ensureMods();if(!M)return {cls:'',html:''};const s=slotById(id);
 if(M.digging===id)return {cls:'dig',html:`<b>Digging…</b><small>${s.sn}</small><span class="drill"></span>`};
 if(!M.dug[id])return {cls:'rock'+(s.f>3?' deep':''),html:`<b>Rock</b><small>Dig · ${DIG_COST[s.f]} Cr</small>`};
 const f=bayFeat(id);return {cls:'',html:f&&M.feat[id]!=='rubble'?`<span class="feat" title="${f.n}: ${f.tip}">${icon(f.ic)}</span>`:''}}
function roomDeco(k){const M=ensureMods();if(!M)return {cls:'',html:''};const A=C.roster.filter(r=>r.status==='active');
 const n=k==='medical'?A.filter(r=>r.wound>0).length:k==='gardens'?A.filter(r=>r.assign==='calm').length:k==='training'?A.filter(r=>r.assign==='train').length:k==='barracks'?Math.min(4,A.filter(r=>!r.wound&&!r.assign).length):0;
 const st=C.staff&&C.staff[k]?1:0,ppl=Math.min(5,n+st),f=bayLive().find(x=>x.k===k);
 return {cls:modReady(k)?'ready':'',html:(ppl?`<span class="ppl" aria-hidden="true">${'<i></i>'.repeat(ppl)}</span>`:'')+(f?`<span class="feat on" title="${f.f.n}: ${f.f.tip}">${icon(f.f.ic)}</span>`:'')}}

// ── Room panel: action card on top ──
const _wsTM=wingSideHTML;wingSideHTML=function(k){const A=MOD_ACTS[k],M=ensureMods();let h='';
 if(A&&M){const up=wingUp(k),rd=modReady(k),pay=modPay(A.cost);
  h=`<div class="modact ${rd?'rd':''}">${icon(A.ic)}<div><b>${A.n}</b> <small class="muted">${modCost(A.cost)} · every ${modCd(k)} mission${modCd(k)>1?'s':''}</small><p>${A.desc}</p></div>
  <button type="button" class="primary" data-act="modact:${k}" ${up&&rd&&pay?'':'disabled'}>${!up?'Build first':rd?(pay?'Use now':'Can’t afford'):`Ready in ${M.cd[k]}`}</button></div>`;
  if(M.next&&modNext())h+=`<p class="flag">Next battle: ${modNext()}.</p>`}
 const s=slotOf(k),f=s&&bayFeat(s);if(f&&M.feat[s]!=='rubble')h+=`<p class="${f.wings.includes(k)?'up':'muted'}">${icon(f.ic)} Bay feature: <b>${f.n}</b>. ${f.wings.includes(k)?f.tip:`Wasted here. ${f.tip}`}</p>`;
 return h+_wsTM(k)};
const _spTM=slotPanelHTML;slotPanelHTML=function(id){const M=ensureMods(),s=slotById(id);
 if(M.digging===id)return `<p>${s.n}: the diggers are at work. Open after the next mission.</p>`;
 if(!M.dug[id]){const c=DIG_COST[s.f];return `<p>${s.n} is solid rock. Dig it out to find what's down there: a Kyber vein, a sealed vault, a hot spring… Each pays off only with the right wing on top.</p>
  <button type="button" class="primary" data-act="dig:${id}" ${M.digging||C.res.credits<c?'disabled':''}>Dig · ${c} Cr · 1 mission</button>${M.digging?` <small class="muted">One dig at a time.</small>`:''}`}
 const f=bayFeat(id);return (f&&M.feat[id]!=='rubble'?`<p class="flag">${icon(f.ic)} <b>${f.n}</b>: ${f.tip}</p>`:'')+_spTM(id)};
const _bcTM=buildClick;buildClick=function(ev){const b=ev.target.closest('[data-act]');if(b&&!b.disabled){const [a,x]=b.dataset.act.split(':');
  if(a==='modact'){modUse(x);return true}if(a==='dig'){bayDig(x);return true}}return _bcTM(ev)};

// Sith schemes with custom effects (data in data-modules.js).
const _ohTM=opHits;opHits=function(o){_ohTM(o);try{const D=SITH_OPS[o.k],M=ensureMods();
 if(D.jam){const W=Object.keys(MOD_ACTS).filter(wingUp).sort(()=>Math.random()-.5).slice(0,D.jam);for(const k of W){M.cd[k]=Math.max(M.cd[k]||0,3);wlog(k,'Saboteurs wrecked the controls. Out for 3 missions.','bad')}if(W.length)C.news.push(`Jammed: ${W.map(k=>MOD_ACTS[k].n).join(', ')}.`)}
 if(D.hunt){const r=C.roster.filter(r=>r.status==='active').sort((a,b)=>(b.rank||1)-(a.rank||1)||(b.kills||0)-(a.kills||0))[0];if(r){r.wound=Math.max(r.wound||0,14);try{addStress(r,30)}catch(e){}C.news.push(`The Sith hunter found ${r.n}: 14 days wounded.`)}}}catch(e){console.error(e)}};

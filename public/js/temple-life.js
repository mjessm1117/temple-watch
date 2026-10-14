/* Temple life (Chat P): Council seats + votes, service records, loadout presets, identity editor, Master–Padawan pairs, Hutt black market.
   Data: data-life.js. Hooks: progMods → lifeMods, templeAfterMission → lifeAfterMission, progMonth → lifeMonth, giveScar → lifeLog. */
Object.assign(UTIL,{stims:{n:'Combat stims',cost:40,market:1,mod:{mob:1,aim:5},desc:'+1 move, +5 aim.'}});
for(const t of [ARMOR,UTIL])for(const [k,v] of Object.entries(t))v.id=k;
const unlockedG=id=>!!(C&&C.unlocked&&C.unlocked.includes(id));
const RC=COUNCIL_RULES,eraN=()=>C.era||1;
function ensureLife(){const L=C.life=C.life||{};for(const k of ['appointed','gone','seen'])L[k]=L[k]||[];L.loy=L.loy||{};
 C.pairs=C.pairs||{};C.presets=C.presets||[];C.unlocked=C.unlocked||[];C.market=C.market||{stock:[],bought:[]};
 if(L.era!==eraN()){if(L.era){L.appointed=[];L.gone=[];L.seen=[];L.vote=null;C.pairs={}}L.era=eraN();restock()}
 for(const r of C.roster){r.log=r.log||[];r.quotes=r.quotes||[];if(r.caps==null)r.caps=0}
 for(const [p,m] of Object.entries(C.pairs)){const P=unit(p),M=unit(m);if(!P||!M||P.status!=='active'||M.status!=='active'||P.title!=='Padawan'){
  if(P&&M&&P.title==='Knight'){bondUp(p,m,'Trials passed');C.news.push(`${P.n} passed the Trials. ${M.n}'s teaching is done.`)}delete C.pairs[p]}}}

// --- Council ---
const loyMap=()=>(C.story&&C.story.loyal)||C.life.loy;
const loyOf=id=>{const m=loyMap();if(m[id]==null)m[id]=RC.start;return m[id]};
const addLoy=(id,n)=>{const m=loyMap();m[id]=Math.max(0,Math.min(100,loyOf(id)+n))};
function members(){const o=[];for(const [id,s] of Object.entries(SEATS))if(s.era===eraN()&&!C.life.gone.includes(id))o.push({id,n:s.n,stance:s.stance,chair:s.chair});
 for(const id of C.life.appointed){const r=unit(id);if(r&&r.status!=='dead')o.push({id,n:r.n,stance:r.cls,unit:1})}return o.slice(0,RC.seats)}
const perkVal=k=>C&&C.life?members().reduce((s,m)=>s+((STANCE_PERK[m.stance]||{})[k]||0)*(loyOf(m.id)>=RC.double?2:1),0):0;
function tally(){const V=VOTES[C.life.vote.k],M=members(),votes={};for(const m of M)votes[m.id]=V.opts.findIndex(o=>o.pleases.includes(m.stance));
 const cnt=V.opts.map((_,i)=>M.filter(m=>votes[m.id]===i).length),max=Math.max(...cnt);let maj=cnt.indexOf(max);const ch=M.find(m=>m.chair);
 if(cnt.filter(c=>c===max).length>1&&ch&&votes[ch.id]>=0&&cnt[votes[ch.id]]===max)maj=votes[ch.id];return {V,M,votes,cnt,maj}}
const affords=fx=>C.res.credits>=-(fx.credits||0)&&C.res.intel>=-(fx.intel||0);
function lifeFx(fx){for(const [k,v] of Object.entries(fx||{})){if(k==='stress')for(const r of C.roster.filter(r=>r.status==='active'))addStress(r,v);else gain(k,v)}}
const fxTxt=fx=>Object.entries(fx||{}).map(([k,v])=>`${v>0?'+':''}${v} ${k==='stress'?'stress (all)':RES_NAMES[k]||k}`).join(', ')||'no cost';
function castVote(i,auto){const v=C.life.vote;if(!v)return;const T=tally(),o=T.V.opts[i];if(!o||(!auto&&!affords(o.fx)))return;
 if(!auto&&i!==T.maj)for(const m of T.M)if(T.votes[m.id]>=0&&T.votes[m.id]!==i)addLoy(m.id,RC.dissent);
 if(!auto)for(const m of T.M)if(T.votes[m.id]===i)addLoy(m.id,RC.agree);
 if(auto&&!affords(o.fx))return(C.life.vote=null);
 lifeFx(o.fx);C.life.last=`${T.V.n}: ${o.t}${auto?' (the Council decided without you)':i!==T.maj?' (you overruled the majority)':''}.`;C.news.push('Council: '+C.life.last);C.life.vote=null;saveGame()}
function appoint(id){const r=unit(id);if(!r||members().length>=RC.seats||C.life.appointed.includes(id)||!seatable(r))return;C.life.appointed.push(id);loyMap()[id]=RC.start;C.news.push(`${r.n} takes a seat on the Council.`);saveGame()}
const seatable=r=>isJedi(r)&&r.status!=='dead'&&(r.title==='Master'||(r.status==='retired'&&r.rank>=RC.appointRank));
function unseat(id){if(C.res.favor<RC.replaceFavor)return;const m=members().find(m=>m.id===id);if(!m)return;gain('favor',-RC.replaceFavor);
 if(m.unit)C.life.appointed=C.life.appointed.filter(x=>x!==id);else C.life.gone.push(id);for(const o of members())addLoy(o.id,RC.replaceOthers);C.news.push(`${m.n} leaves the Council.`);saveGame()}
function lifeMonth(){ensureLife();if(C.life.vote){const T=tally();castVote(T.maj,1)}
 for(const m of members())if(loyOf(m.id)<RC.resign){if(m.unit)C.life.appointed=C.life.appointed.filter(x=>x!==m.id);else C.life.gone.push(m.id);C.news.push(`<span class="bad">${m.n} resigns from the Council</span> (loyalty ${loyOf(m.id)}). A seat is open.`)}
 const d=perkVal('monthDark');if(d)gain('orderDark',d);
 let pool=Object.keys(VOTES).filter(k=>!C.life.seen.includes(k));if(!pool.length){C.life.seen=[];pool=Object.keys(VOTES)}
 const k=pickOne(pool);C.life.seen.push(k);C.life.vote={k};C.news.push(`The Council will vote: ${VOTES[k].n}. See the Council tab.`);restock()}
function councilTab(){ensureLife();const M=members(),L=C.life,v=L.vote,cand=C.roster.filter(r=>seatable(r)&&!L.appointed.includes(r.id));let h='';
 if(v){const T=tally();h+=`<div class="opt"><div class="oh2"><b>Vote · ${T.V.n}</b><span class="tag">Council</span></div><p>${T.V.text}</p><div class="picks">${T.V.opts.map((o,i)=>{const who=T.M.filter(m=>T.votes[m.id]===i).map(m=>m.n).join(', ');
  return `<button type="button" data-ch="${i}" data-act="vote:${i}" ${affords(o.fx)?'':'disabled'}><b>${o.t}${i===T.maj?' · majority':''}</b><small>${fxTxt(o.fx)}${who?` · for: ${who}`:''}</small></button>`}).join('')}</div>
  <small class="muted">Agreeing with a member: their loyalty +${RC.agree}. Overruling the majority: everyone who voted otherwise ${RC.dissent}. Undecided at month end: the majority wins.</small></div>`}
 else h+=`<p class="muted">${L.last?'Last decision: '+L.last+' ':''}Next vote at the start of next month.</p>`;
 h+=`<div class="seats">${M.map(m=>{const l=loyOf(m.id),P=STANCE_PERK[m.stance];return `<div class="seat" data-tip="class:${m.stance}"><b>${m.n}</b><div class="muted">${m.stance}${m.chair?' · Master of the Order':''}</div>
  <div>Perk: ${P?P.desc:'none'}${l>=RC.double?' <b class="up">×2</b>':''}</div><div>Loyalty <b class="${l<RC.resign+10?'bad':l>=RC.double?'up':''}">${l}</b>/100</div>
  <button type="button" data-act="unseat:${m.id}" ${C.res.favor<RC.replaceFavor?'disabled':''}>Remove · ${RC.replaceFavor} Favor</button></div>`}).join('')}
  ${Array.from({length:RC.seats-M.length},()=>`<div class="seat vac">Open seat${cand.length?`<div class="picks">${cand.map(r=>`<button type="button" data-act="appoint:${r.id}">Appoint ${r.n}</button>`).join('')}</div>`:'<div>Name a Jedi Master (rank 5 Knight, Roster) or a retired rank-5 Jedi to fill it.</div>'}</div>`).join('')}</div>
 <p class="muted">Loyalty below ${RC.resign}: the member resigns at month end. ${RC.double}+: perk doubled.</p>`;return h}

// --- service record, quotes ---
const stamp=()=>`${eraN()>1?'E'+eraN()+' ':''}M${C.month}`;
function lifeLog(r,txt){r.log=r.log||[];r.log.unshift(`${stamp()} · ${txt}`);r.log.length=Math.min(r.log.length,12)}
function quote(r,ev){const Q=SAY_LINES[ev];if(!Q)return;r.quotes=r.quotes||[];r.quotes.unshift({t:pickOne(Q[isJedi(r)?'jedi':'troop']),w:stamp()});r.quotes.length=Math.min(r.quotes.length,3)}
function lifeAfterMission(dep,win,o,out){ensureLife();const M=S.M;
 for(const {r,u} of dep){if(u.vip){if(win&&r.status==='active'){lifeLog(r,`Freed at ${M.n}`);quote(r,'freed')}continue}
  const row=out.rows.find(x=>x.n===r.n);r.caps+=u.caps||0;lifeLog(r,`${M.n} (${win?'won':'lost'}): ${u.kills||0} kills · ${row?row.fate:r.status}`);
  if(r.status!=='active')continue;if(out.promo.includes(r.id)){lifeLog(r,`Promoted to rank ${r.rank}`);quote(r,'promo')}else if(u.downed)quote(r,'down');else if((u.kills||0)>=2)quote(r,'kill')}
 if(win){const iv=perkVal('winIntel');if(iv)gain('intel',iv,out.res);if(o.src==='Senate request'){const f=perkVal('senateFavor');if(f)gain('favor',f,out.res)}}
 const ids=new Set(dep.map(d=>d.r.id));out.prog=out.prog||[];
 for(const [p,m] of Object.entries(C.pairs)){const P=unit(p);if(ids.has(p)&&ids.has(m)&&P.status==='active'){P.xp+=PAIR.xp;out.prog.push(`${P.n} learns from ${unit(m).n}: +${PAIR.xp} XP.`);if(promote(P))out.promo.push(P.id)}}}
function recordHTML(r){const b=bondsOf(r).filter(b=>b.lvl),pm=C.pairs[r.id]&&unit(C.pairs[r.id]),pp=Object.keys(C.pairs).find(p=>C.pairs[p]===r.id);
 return `<div><b class="eyebrow">Service record</b><div class="stl">Missions ${r.missions} · Kills ${r.kills} · Captures ${r.caps||0} · Stress ${r.stress||0}${r.scars&&r.scars.length?` · Scars: ${r.scars.map(k=>SCARS[k].n).join(', ')}`:''}${b.length?` · Bonds: ${b.map(x=>x.n+' '+'★'.repeat(x.lvl)).join(', ')}`:''}${pm?` · Master: ${pm.n}`:''}${pp?` · Padawan: ${unit(pp).n}`:''}</div>
 ${r.quotes.length?r.quotes.map(q=>`<p class="flag">“${q.t}” <small class="muted">${q.w}</small></p>`).join(''):''}
 ${r.log.length?`<small class="muted">${r.log.join('<br>')}</small>`:'<small class="muted">No missions yet.</small>'}</div>`}

// --- Master–Padawan pairing ---
const mentors=p=>C.roster.filter(m=>isJedi(m)&&m.status==='active'&&m.id!==p.id&&(m.title==='Knight'||m.title==='Master')&&m.rank>=PAIR.rank&&!Object.entries(C.pairs).some(([a,b])=>b===m.id&&a!==p.id));
function setPair(p,m){const P=unit(p);if(!P||P.title!=='Padawan')return;if(!m){delete C.pairs[p];return saveGame()}
 if(!mentors(P).some(x=>x.id===m))return;C.pairs[p]=m;const k=bkey(p,m),v=C.bonds[k];if(!v||v.lvl<PAIR.bond)C.bonds[k]={lvl:PAIR.bond,n:0};C.news.push(`${unit(m).n} takes ${P.n} as Padawan. Bond level ${PAIR.bond}.`);saveGame()}
function pairHTML(r){if(!isJedi(r)||r.title!=='Padawan'||r.status!=='active')return '';const ms=mentors(r),cur=C.pairs[r.id];
 return `<label class="muted">Master: <select data-pair="${r.id}"><option value="">None</option>${ms.map(m=>`<option value="${m.id}" ${cur===m.id?'selected':''}>${m.n} (${m.title}, R${m.rank})</option>`).join('')}</select></label> <small class="muted">Together on a mission: +${PAIR.xp} XP for the Padawan.</small>`}

// --- loadout presets ---
function savePreset(id,name){const r=unit(id);if(!r)return;const g=r.gear,J=isJedi(r),n=(name||'').replace(/[<>&"]/g,'').trim().slice(0,24)||`${r.cls} loadout`;
 C.presets.unshift({n,kind:J?'jedi':'troop',armor:g.armor,util:g.util,form:J?g.form:null,w:J?null:g.w,mods:J?[]:[...g.mods]});C.presets.length=Math.min(C.presets.length,PRESET_MAX);saveGame()}
function presetCost(r,p){const g=r.gear;let c=0;if(p.kind==='troop')for(let t=g.w+1;t<=p.w;t++)c+=priceOf(WEAPONS[t].cost);
 if(p.armor!==g.armor)c+=priceOf(ARMOR[p.armor].cost);if(p.util!==g.util)c+=priceOf(UTIL[p.util].cost);for(const m of p.mods)if(!g.mods.includes(m))c+=priceOf(MODS[m].cost);return c}
function applyPreset(id,i){const r=unit(id),p=C.presets[i];if(!r||!p||p.kind!==(isJedi(r)?'jedi':'troop'))return;
 if(p.kind==='troop'){while(r.gear.w<p.w&&WEAPONS[r.gear.w+1]&&okGear(WEAPONS[r.gear.w+1])&&C.res.credits>=priceOf(WEAPONS[r.gear.w+1].cost))buyWeapon(id);
  for(const m of [...r.gear.mods])if(!p.mods.includes(m))dropMod(id,m);for(const m of p.mods)buyMod(id,m)}else setForm(id,p.form);
 buyArmor(id,p.armor);if(p.util!==r.gear.util)setUtil(id,p.util);saveGame()}
function presetHTML(r){const K=isJedi(r)?'jedi':'troop',L=C.presets.map((p,i)=>[p,i]).filter(([p])=>p.kind===K);
 return `<div class="grow"><b>Presets</b>${L.map(([p,i])=>`<button type="button" data-act="preset:${r.id}:${i}" title="${[ARMOR[p.armor].n,UTIL[p.util].n,p.form?FORMS[p.form].n:WEAPONS[p.w].n,...p.mods.map(m=>MODS[m].n)].join(', ')}">${p.n} · ${presetCost(r,p)} Cr</button><button type="button" data-act="delpreset:${i}" aria-label="Delete preset">✕</button>`).join('')}
 <input id="pname" type="text" maxlength="24" placeholder="Preset name" aria-label="Preset name" style="max-width:140px"><button type="button" data-act="savepreset:${r.id}">Save current</button></div>`}

// --- identity editor (Armory) + recruit card fields ---
const clean=(s,n)=>(s||'').replace(/[<>&"]/g,'').trim().slice(0,n);
function identHTML(r){const L=LOOKS[isJedi(r)?'jedi':'troop'];
 return `<div class="grow"><b>Identity</b><input id="idn" type="text" maxlength="24" value="${r.n}" aria-label="Name" style="max-width:150px">
 <select id="ids" aria-label="Species">${SPECIES.map(s=>`<option ${r.species===s?'selected':''}>${s}</option>`).join('')}</select>
 <select id="idl" aria-label="Look">${L.map(s=>`<option ${r.look===s?'selected':''}>${s}</option>`).join('')}</select>
 <input id="idb" type="text" maxlength="${BIO_MAX}" value="${r.bio||''}" placeholder="Short bio (${BIO_MAX} max)" aria-label="Bio" style="flex:1;min-width:160px">
 <button type="button" data-act="ident:${r.id}">Save</button></div>`}
function setIdent(id,f){const r=unit(id);if(!r)return;const n=clean(f.n,24);if(n&&!C.roster.some(x=>x!==r&&x.n===n))r.n=n;
 if(SPECIES.includes(f.s))r.species=f.s;if(LOOKS[isJedi(r)?'jedi':'troop'].includes(f.l))r.look=f.l;r.bio=clean(f.b,BIO_MAX);saveGame()}
function candFields(c,i){const L=LOOKS[c.jedi?'jedi':'troop'];
 return `<select id="rs${i}" aria-label="Species">${SPECIES.map(s=>`<option ${c.species===s?'selected':''}>${s}</option>`).join('')}</select>
 <select id="ro${i}" aria-label="Origin">${ORIGINS[c.jedi?'jedi':'troop'].map(s=>`<option ${c.origin===s?'selected':''}>${s}</option>`).join('')}</select>
 <select id="rl${i}" aria-label="Look">${L.map(s=>`<option>${s}</option>`).join('')}</select>
 <input id="rb${i}" type="text" maxlength="${BIO_MAX}" placeholder="Bio (optional)" aria-label="Bio">`}
function candEdit(i){const c=C.cands[i],v=id=>{const e=document.getElementById(id);return e?e.value:''};if(!c)return;
 if(SPECIES.includes(v('rs'+i)))c.species=v('rs'+i);if(ORIGINS[c.jedi?'jedi':'troop'].includes(v('ro'+i)))c.origin=v('ro'+i);
 const l=v('rl'+i);if(LOOKS[c.jedi?'jedi':'troop'].includes(l))c.look=l;c.bio=clean(v('rb'+i),BIO_MAX)}

// --- Hutt black market ---
function restock(){const pool=Object.keys(MARKET_ITEMS).filter(k=>!(MARKET_ITEMS[k].unlock&&unlockedG(MARKET_ITEMS[k].unlock))),o=[];
 while(o.length<MARKET.stock&&pool.length)o.push(pool.splice(Math.floor(Math.random()*pool.length),1)[0]);C.market={stock:o,bought:[]}}
function buyMarket(k){const it=MARKET_ITEMS[k],M=C.market;if(!it||!M.stock.includes(k)||M.bought.includes(k)||C.res.credits<it.cost)return;
 if(it.merc&&rosterCount()>=rosterCap())return;if(it.stopOp&&!C.ops.list.some(o=>o.st==='open'))return;
 C.res.credits-=it.cost;gain('favor',-MARKET.favor);M.bought.push(k);lifeFx(it.fx);if(it.stress)lifeFx({stress:it.stress});
 if(it.heal)for(const r of C.roster)if(r.wound)r.wound=Math.max(0,r.wound-it.heal);
 if(it.unlock)C.unlocked.push(it.unlock);
 if(it.stopOp){const o=C.ops.list.find(o=>o.st==='open');o.st='done'}
 if(it.merc){const c=genCands().find(c=>!c.jedi);c.cls=pickOne(['Soldier','Heavy']);c.origin='Hired';addRecruit(c,'','#d9a05b');const r=C.roster[C.roster.length-1];r.rank=it.merc;r.xp=RANKS[it.merc-1].xp;r.title=RANK_TITLE[it.merc];r.pick=pendingRank(r);lifeLog(r,'Hired off the Hutt market')}
 C.news.push(`Black market: ${it.n}. Senate Favor −${MARKET.favor}.`);saveGame()}
function marketTab(){const M=C.market;return `<p class="muted">A Hutt broker on Nar Shaddaa. New stock every month. Every deal costs ${MARKET.favor} Senate Favor: the Senate frowns on Hutt business.</p>
 <div class="seats">${M.stock.map(k=>{const it=MARKET_ITEMS[k],sold=M.bought.includes(k),no=sold||C.res.credits<it.cost||(it.merc&&rosterCount()>=rosterCap())||(it.stopOp&&!C.ops.list.some(o=>o.st==='open'));
  return `<div class="seat"><b>${it.n}</b><div>${it.desc}</div><button type="button" data-act="mkt:${k}" ${no?'disabled':''}>${sold?'Sold':`Buy · ${it.cost} Cr`}</button></div>`}).join('')}</div>
 ${C.unlocked.length?`<p class="muted">Unlocked contraband: ${C.unlocked.map(id=>(ARMOR[id]||UTIL[id]||{n:id}).n).join(', ')}.</p>`:''}`}

// --- clicks (called from hubClick via progClick) ---
function lifeClick(a,x,y){const m=document.getElementById('modal');
 if(a==='vote')castVote(+x);else if(a==='appoint')appoint(x);else if(a==='unseat')unseat(x);else if(a==='mkt')buyMarket(x);
 else if(a==='preset')applyPreset(x,+y);else if(a==='delpreset'){C.presets.splice(+x,1);saveGame()}else if(a==='savepreset')savePreset(x,(m.querySelector('#pname')||{}).value);
 else if(a==='ident'){const v=id=>(m.querySelector('#'+id)||{}).value;setIdent(x,{n:v('idn'),s:v('ids'),l:v('idl'),b:v('idb')})}else return false;return true}

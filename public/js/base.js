/* Squad select, debrief (with promotion picks), and slice-end screens, drawn in #modal. The Temple hub itself is in temple-ui.js. Wireframes: docs/specs/ui.md §4 */
const resRow=()=>{const r=C.res;return `<div class="resbar"><span title="Credits">Cr <b>${r.credits}</b></span><span title="Intel">In <b>${r.intel}</b></span><span title="Kyber">Ky <b>${r.kyber}</b></span><span title="Senate Favor">SF <b>${r.favor}</b></span><span title="Recruits">Rc <b>${r.recruits}</b></span><span class="dk" title="Order Darkness 0–100">Darkness <b>${odark()}</b></span><span class="cal">Month ${C.month} · Day ${C.day}</span></div>`};
const fmtRes=o=>Object.entries(o||{}).filter(([k])=>k!=='lose').map(([k,v])=>`${v>0?'+':''}${v} ${RES_NAMES[k]||k}`).join(', ');
function optionHTML(o,i){const M=MISSIONS[o.mission],seeRw=C.wings.comms||o.story;
 return `<div class="opt"><div class="oh2"><b>${o.n||M.n}</b><span class="tag ${o.story?'story':''}">${o.story?'Story':o.kind}</span></div>
 <p>${o.text||M.brief}</p>${o.questTxt?`<div class="meta"><span class="up">Reward: ${o.questTxt}</span><span>${unit(o.quest).n} must deploy</span></div>`:''}<div class="meta"><span>${M.where}</span>${o.src?`<span>${o.src}</span>`:''}</div>
 <div class="meta"><span>Reward: ${o.quest?'mission pay ':''}${seeRw?fmtRes(M.reward)+(M.bonus?` · bonus ${fmtRes(M.bonus)} (${M.bonusTxt})`:''):'? (build the Comms Hub to see)'}</span>${o.adv&&C.options.filter(x=>x.adv).length>1?`<span class="bad">If ignored: ${o.ignore&&o.ignore.lose?'they are lost':fmtRes(o.ignore)}</span>`:''}</div>
 <button type="button" class="primary" data-act="squad:${i}">Choose squad</button></div>`}
let pickSquad=[];
function squadScreen(i,keep){SCR=()=>squadScreen(i,1);const o=C.options[i],M=MISSIONS[o.mission],m=$('#modal');if(!keep)pickSquad=defaultSquad(o);
 const can=C.roster.filter(r=>r.status==='active'&&r.id!==o.hostage),sel=pickSquad.map(id=>C.roster.find(r=>r.id===id)),nj=sel.filter(isJedi).length;
 const qr=o.quest&&unit(o.quest),ok=sel.length>=1&&sel.length<=6&&nj<=3&&(nj>=1||!can.some(r=>isJedi(r)&&fit(r)))&&(!qr||pickSquad.includes(qr.id));
 m.innerHTML=`<div class="box sqbox"><div class="eyebrow">${M.where}</div><h2>${o.n||M.n}</h2>${M.quote?`<blockquote class="mq">${M.quote}</blockquote>`:''}<p>${M.brief}</p>
 <p class="muted">Up to 6 units, 1–3 Jedi. Wounded or assigned units can't deploy.${qr?` ${qr.n} must go (personal quest)${fit(qr)?'':': free them up at the Temple first'}.`:''} ${sel.length}/6 picked · ${nj} Jedi.</p>
 <div class="squad">${can.map(r=>`<button type="button" class="sq ${pickSquad.includes(r.id)?'on':''}" data-sq="${r.id}" style="--uc:${r.col||'var(--troop)'}" ${fit(r)?'':'disabled'}><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><span>${r.n}<small>${r.cls}${specOf(r)?' ('+specOf(r).n+')':''} · Rank ${r.rank} · Power ${unitPower(r)}${r.wound?` · wounded ${r.wound}d`:''}${r.assign?' · '+assignName(r):''}${r.fear?' · afraid':''}${r.stress>=STRESS.shaken?` · ${stressLv(r.stress).n.toLowerCase()} (stress ${r.stress})`:''}${r.scars&&r.scars.length?' · scars '+r.scars.length:''}</small></span></button>`).join('')}</div>
 <div class="endrow"><button type="button" id="sqBack">Back</button><button type="button" class="primary" id="deploy" ${ok?'':'disabled'}>Launch mission</button></div></div>`;
 m.onclick=ev=>{const b=ev.target.closest('[data-sq]');if(!b||b.disabled)return;const id=b.dataset.sq;
  pickSquad=pickSquad.includes(id)?pickSquad.filter(x=>x!==id):pickSquad.length<6?[...pickSquad,id]:pickSquad;squadScreen(i,1)};
 $('#sqBack').onclick=ev=>{ev.stopPropagation();baseScreen()};$('#deploy').onclick=ev=>{ev.stopPropagation();launchMission(i,pickSquad)}}
// Called by finish() in turns.js.
function missionOver(win,msg){S.phase='over';const out=C?applyResults(win):null;debrief(win,msg,out)}
let lastDeb=null;
// Promotion picks right in the debrief (spec: every promoted unit, troops too). Shows what the pick changed.
function promoHTML(out){if(!out||!out.promo.length)return '';
 return `<section><h3>Promotions</h3>${out.promo.map(id=>{const r=unit(id),p=pendingRank(r),done=out.picked&&out.picked[id];
  return `<div class="rrow"><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><div class="rmain"><b>${r.n} · Rank ${r.rank}</b>
  ${p?`<div class="picks">Rank ${p}: ${p===3?'choose a specialization (permanent)':'choose one'} ${treeOpts(r,p).map(k=>{const a=pickCard(r,p,k);return `<button type="button" data-act="dpick:${id}:${k}" title="${a.desc.replace(/"/g,'')}">${icon(a.ic||'guard')}${a.name}</button>`}).join('')}</div>
   <small>${treeOpts(r,p).map(k=>{const a=pickCard(r,p,k);return `${a.name}: ${a.desc}`}).join(' · ')}</small>`:''}
  ${done?`<small class="up">${done}</small>`:''}</div></div>`}).join('')}</section>`}
function debriefPick(id,k){const r=unit(id),a=battleUnit({...r,rank:pendingRank(r)-1,picks:r.picks}),out=lastDeb[2];pickAbility(id,k);
 out.picked=out.picked||{};out.picked[id]=`Took ${pickInfo(k).name}. ${statDiff(a,battleUnit(r))}`;debrief(...lastDeb)}
function debrief(win,msg,out){const m=$('#modal');m.hidden=false;SCR=null;lastDeb=[win,msg,out];
 const rows=out?out.rows.map(r=>`<div><span>${r.n}${r.dark!=null?` <small class="dkt">Darkness ${r.dark}</small>`:''}</span><span>${r.xp?`+${r.xp} XP · `:''}${r.rank?`<b class="up">Rank ${r.rank}!</b> · `:''}${r.fate}</span></div>`).join('')
  :S.units.filter(u=>u.side==='p').map(u=>`<div><span>${u.n}</span><span>${u.status}</span></div>`).join('');
 m.innerHTML=`<div class="box"><div class="eyebrow">Debrief · ${S.M.n} · Turn ${S.turn}</div><h2 class="${win?'':'lose'}">${win?'Mission complete':'Mission failed'}</h2><p>${msg}</p>
 ${out&&out.flag?`<p class="flag">${out.flag}</p>`:''}
 <div class="sum">${rows}<div><span>Enemies killed / captured</span><span>${S.kills} / ${S.units.filter(u=>u.side==='e'&&u.status==='captured').length}</span></div>
 ${out?`<div><span>Rewards</span><span>${fmtRes(out.res)||'none'}${out.bonus?` · bonus: ${out.bonus}`:''}</span></div>`:''}</div>
 ${out&&out.quest?`<p class="flag">${out.quest}</p>`:''}${out&&out.bonds&&out.bonds.length?`<div class="news">${out.bonds.map(b=>`<p>${b}</p>`).join('')}</div>`:''}
 ${out&&out.prog&&out.prog.length?`<div class="news">${out.prog.map(b=>`<p>${b}</p>`).join('')}</div>`:''}
 ${promoHTML(out)}
 ${win?'':'<p class="muted">The war goes on. Losses stand, but the Order endures.</p>'}
 <button type="button" class="primary" id="toBase">${C?'Return to the Temple':'Play again'}</button></div>`;
 $('#toBase').onclick=()=>C?baseScreen():briefing();
 m.onclick=ev=>{const b=ev.target.closest('[data-act^="dpick:"]');if(!b)return;const [,id,k]=b.dataset.act.split(':');debriefPick(id,k)}}
function endScreen(){SCR=endScreen;const m=$('#modal'),alive=C.roster.filter(r=>r.status==='active');
 m.innerHTML=`<div class="box"><div class="eyebrow">Act I · end of the v0.2a slice</div><h2>The trail leads to Coruscant</h2>
 <p>${C.flags.e1_strike_known?'Thanks to the envoy, the Council knows the treaty is a feint. The strike is coming, and you will be ready.':'The Council suspects the treaty is a feint, but nobody can prove it.'}</p>
 <div class="sum"><div><span>Squad still standing</span><span>${alive.length}</span></div><div><span>Highest rank</span><span>${Math.max(...alive.map(r=>r.rank),0)}</span></div>
 <div><span>Credits · Intel · Kyber · Favor</span><span>${C.res.credits} · ${C.res.intel} · ${C.res.kyber} · ${C.res.favor}</span></div><div><span>Order Darkness</span><span>${odark()}/100</span></div>
 <div><span>Fallen</span><span>${C.legends.map(l=>l.n).join(', ')||'none'}</span></div></div>
 <p class="muted">Coming in v0.2b: Years pass (aging, Trials, retirement), saber crafting, and the Docking Ring Nine boss against Darth Malgus.</p>
 <button type="button" class="primary" id="restart">New campaign</button></div>`;
 $('#restart').onclick=()=>{C=null;briefing(true)}}

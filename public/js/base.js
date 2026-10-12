/* Temple base, squad select, debrief, and slice-end screens (all drawn in #modal). Wireframes: docs/specs/ui.md §4 */
const resRow=()=>{const r=C.res;return `<div class="resbar"><span title="Credits">Cr <b>${r.credits}</b></span><span title="Intel">In <b>${r.intel}</b></span><span title="Kyber">Ky <b>${r.kyber}</b></span><span title="Senate Favor">SF <b>${r.favor}</b></span><span title="Recruits">Rc <b>${r.recruits}</b></span><span class="dk" title="Order Darkness 0–100">Darkness <b>${odark()}</b></span><span class="cal">Month ${C.month} · Day ${C.day}</span></div>`};
const fmtRes=o=>Object.entries(o||{}).filter(([k])=>k!=='lose').map(([k,v])=>`${v>0?'+':''}${v} ${RES_NAMES[k]||k}`).join(', ');
function rosterRow(r){const lvl=RANKS[r.rank],next=RANKS[r.rank]&&r.rank<3?RANKS[r.rank].xp:null;
 const st=r.status==='captured'?`<span class="bad">Captured</span>`:r.wound?`<span class="warn">Wounded · ${r.wound} days</span>`:'<span class="ready">Ready</span>';
 const pick=r.pick?`<div class="picks">Rank ${r.pick}: choose one ${KITS[r.cls][r.pick].map(k=>`<button type="button" data-act="pick:${r.id}:${k}" title="${AB[k].tip.replace(/"/g,'')}">${icon(AB[k].ic||'guard')}${AB[k].name}</button>`).join('')}</div>`:'';
 return `<div class="rrow"><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><div class="rmain"><b>${r.n}</b><small>${r.title?r.title+' · ':''}${r.cls} · Rank ${r.rank} · ${r.xp}${next?'/'+next:''} XP${isJedi(r)?` · Darkness ${r.dark}`:''}</small>${pick}</div>${st}</div>`}
function optionHTML(o,i){const M=MISSIONS[o.mission],seeRw=C.wings.comms||o.story;
 return `<div class="opt"><div class="oh2"><b>${o.n||M.n}</b><span class="tag ${o.story?'story':''}">${o.story?'Story':o.kind}</span></div>
 <p>${o.text||M.brief}</p><div class="meta"><span>${M.where}</span>${o.src?`<span>${o.src}</span>`:''}</div>
 <div class="meta"><span>Reward: ${seeRw?fmtRes(M.reward)+(M.bonus?` · bonus ${fmtRes(M.bonus)} (${M.bonusTxt})`:''):'? (build the Comms Hub to see)'}</span>${o.adv&&C.options.filter(x=>x.adv).length>1?`<span class="bad">If ignored: ${o.ignore&&o.ignore.lose?'they are lost':fmtRes(o.ignore)}</span>`:''}</div>
 <button type="button" class="primary" data-act="squad:${i}">Choose squad</button></div>`}
function baseScreen(){SCR=baseScreen;S=null;const m=$('#modal');m.hidden=false;
 if(C.step>=PLAN.length&&!C.options.length)return endScreen();
 const wings=Object.entries(WINGS).map(([k,w])=>{const l=C.wings[k],nc=w.cost[l+1],bld=C.build===k;
  return `<div class="wing ${l?'':'off'}"><div><b>${w.n}</b> <small>${l?'Level '+l:'Not built'}</small><p>${bld?'Under construction · ready after the next mission':w.eff[l]}${l&&w.eff[l+1]?` · <span class="muted">Next: ${w.eff[l+1]}</span>`:!l?` · <span class="muted">${w.eff[1]}</span>`:''}</p></div>
  ${nc!=null&&!bld?`<button type="button" data-act="build:${k}" ${C.build||C.res.credits<nc?'disabled':''}>${l?'Upgrade':'Build'} ${nc} Cr</button>`:''}</div>`}).join('');
 const act=C.roster.filter(r=>r.status!=='dead');
 m.innerHTML=`<div class="box wide base">${resRow()}
 <div><div class="eyebrow">Old Republic · ~3,660 BBY · ${DIFF[C.diff].n}</div><h2>Jedi Temple, Coruscant</h2></div>
 ${C.news.length?`<div class="news">${C.news.map(n=>`<p>${n}</p>`).join('')}</div>`:''}
 <section><h3>Galaxy · choose the next mission</h3><div class="opts">${C.options.map(optionHTML).join('')}</div></section>
 <div class="cols"><section><h3>Wings</h3>${wings}<p class="muted">One build at a time. Upkeep is paid monthly.</p></section>
 <section><h3>Roster <small>${act.filter(r=>r.status==='active').length}/${ROSTER_CAP}</small></h3>${act.map(rosterRow).join('')}
 <button type="button" data-act="hire" ${C.res.recruits<1||C.res.credits<HIRE_COST?'disabled':''}>Hire a trooper · ${HIRE_COST} Cr + 1 Recruit</button>
 ${C.legends.length?`<p class="muted">Fallen: ${C.legends.map(l=>l.n).join(', ')}</p>`:''}</section></div></div>`;
 m.onclick=baseClick}
function baseClick(ev){const b=ev.target.closest('[data-act]');if(!b||b.disabled)return;const [a,x,y]=b.dataset.act.split(':');
 if(a==='build')buildWing(x);else if(a==='hire')hireTroop();else if(a==='pick')pickAbility(x,y);else if(a==='squad')return squadScreen(+x);
 baseScreen()}
let pickSquad=[];
function squadScreen(i,keep){SCR=()=>squadScreen(i,1);const o=C.options[i],M=MISSIONS[o.mission],m=$('#modal');if(!keep)pickSquad=defaultSquad(o);
 const can=C.roster.filter(r=>r.status==='active'&&r.id!==o.hostage),sel=pickSquad.map(id=>C.roster.find(r=>r.id===id)),nj=sel.filter(isJedi).length;
 const ok=sel.length>=1&&sel.length<=6&&nj<=3&&(nj>=1||!can.some(r=>isJedi(r)&&fit(r)));
 m.innerHTML=`<div class="box"><div class="eyebrow">${M.where}</div><h2>${o.n||M.n}</h2><p>${M.brief}</p>
 <p class="muted">Up to 6 units, 1–3 Jedi. Wounded units can't deploy. ${sel.length}/6 picked · ${nj} Jedi.</p>
 <div class="squad">${can.map(r=>`<button type="button" class="sq ${pickSquad.includes(r.id)?'on':''}" data-sq="${r.id}" ${fit(r)?'':'disabled'}><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><span>${r.n}<small>${r.cls} · Rank ${r.rank}${r.wound?` · wounded ${r.wound}d`:''}</small></span></button>`).join('')}</div>
 <div class="endrow"><button type="button" id="sqBack">Back</button><button type="button" class="primary" id="deploy" ${ok?'':'disabled'}>Launch mission</button></div></div>`;
 m.onclick=ev=>{const b=ev.target.closest('[data-sq]');if(!b||b.disabled)return;const id=b.dataset.sq;
  pickSquad=pickSquad.includes(id)?pickSquad.filter(x=>x!==id):pickSquad.length<6?[...pickSquad,id]:pickSquad;squadScreen(i,1)};
 $('#sqBack').onclick=ev=>{ev.stopPropagation();baseScreen()};$('#deploy').onclick=ev=>{ev.stopPropagation();launchMission(i,pickSquad)}}
// Called by finish() in turns.js.
function missionOver(win,msg){S.phase='over';const out=C?applyResults(win):null;debrief(win,msg,out)}
function debrief(win,msg,out){const m=$('#modal');m.hidden=false;SCR=null;
 const rows=out?out.rows.map(r=>`<div><span>${r.n}${r.dark!=null?` <small class="dkt">Darkness ${r.dark}</small>`:''}</span><span>${r.xp?`+${r.xp} XP · `:''}${r.rank?`<b class="up">Rank ${r.rank}!</b> · `:''}${r.fate}</span></div>`).join('')
  :S.units.filter(u=>u.side==='p').map(u=>`<div><span>${u.n}</span><span>${u.status}</span></div>`).join('');
 m.innerHTML=`<div class="box"><div class="eyebrow">Debrief · ${S.M.n} · Turn ${S.turn}</div><h2 class="${win?'':'lose'}">${win?'Mission complete':'Mission failed'}</h2><p>${msg}</p>
 ${out&&out.flag?`<p class="flag">${out.flag}</p>`:''}
 <div class="sum">${rows}<div><span>Enemies killed / captured</span><span>${S.kills} / ${S.units.filter(u=>u.side==='e'&&u.status==='captured').length}</span></div>
 ${out?`<div><span>Rewards</span><span>${fmtRes(out.res)||'none'}${out.bonus?` · bonus: ${out.bonus}`:''}</span></div>`:''}</div>
 ${out&&out.promo.length?`<p class="muted">Promoted: ${out.promo.join(', ')}. Jedi pick a new ability at the Temple.</p>`:''}
 ${win?'':'<p class="muted">The war goes on. Losses stand, but the Order endures.</p>'}
 <button type="button" class="primary" id="toBase">${C?'Return to the Temple':'Play again'}</button></div>`;
 $('#toBase').onclick=()=>C?baseScreen():briefing()}
function endScreen(){SCR=endScreen;const m=$('#modal'),alive=C.roster.filter(r=>r.status==='active');
 m.innerHTML=`<div class="box"><div class="eyebrow">Act I · end of the v0.2a slice</div><h2>The trail leads to Coruscant</h2>
 <p>${C.flags.e1_strike_known?'Thanks to the envoy, the Council knows the treaty is a feint. The strike is coming, and you will be ready.':'The Council suspects the treaty is a feint, but nobody can prove it.'}</p>
 <div class="sum"><div><span>Squad still standing</span><span>${alive.length}</span></div><div><span>Highest rank</span><span>${Math.max(...alive.map(r=>r.rank),0)}</span></div>
 <div><span>Credits · Intel · Kyber · Favor</span><span>${C.res.credits} · ${C.res.intel} · ${C.res.kyber} · ${C.res.favor}</span></div><div><span>Order Darkness</span><span>${odark()}/100</span></div>
 <div><span>Fallen</span><span>${C.legends.map(l=>l.n).join(', ')||'none'}</span></div></div>
 <p class="muted">Coming in v0.2b: Years pass (aging, Trials, retirement), saber crafting, and the Docking Ring Nine boss against Darth Malgus.</p>
 <button type="button" class="primary" id="restart">New campaign</button></div>`;
 $('#restart').onclick=()=>{C=null;briefing(true)}}

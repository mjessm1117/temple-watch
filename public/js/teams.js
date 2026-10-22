/* Strike teams (Chat S2, bucket 3). Named teams: a Jedi leader + up to 3 troopers (data-teams.js). On a step with several crises you
   play one yourself; every other crisis you gave a team auto-resolves with that team instead of being ignored (odds, wounds,
   capture, rare death). Fatigue: fighting 2 steps in a row makes a unit Tired (−10 aim). Teams grow bonds when they fight together.
   State: C.teams=[{id,n,lead,mem:[ids]}], C.tAs={step,map:{crisisId:teamId},played:[ids]}, C.tFought=[ids], C.tPend=[txt], C.tLog=[{t,m,win}].
   Hooks (wrappers): ignoreCrisis, launchMission, advance, templeAdvance, battleUnit, debrief. UI: galaxy.js (panel, buttons), base.js (squad). */
const teamCap=()=>Math.min(TEAMS.max,TEAMS.base+TEAMS.barracks.filter(l=>(C.wings.barracks||0)>=l).length);
const isTired=r=>!!r&&(r.fat||0)>=FATIGUE.at;
const teamUnits=t=>[t.lead,...t.mem].map(unit).filter(r=>r&&r.status!=='dead');
const teamOf=id=>(C.teams||[]).find(t=>t.lead===id||t.mem.includes(id));
function ensureTeams(){if(!C)return;C.teams=C.teams||[];
 while(C.teams.length<teamCap()){const i=C.teams.length;C.teams.push({id:'t'+(i+1),n:TEAMS.names[i]+' Team',lead:null,mem:[]})}
 for(const t of C.teams){if(t.lead&&!(unit(t.lead)&&unit(t.lead).status!=='dead'))t.lead=null;t.mem=t.mem.filter(id=>unit(id)&&unit(id).status!=='dead')}
 // Fill empty teams (new game, new team slot) from units not on any team: best Jedi leads, troopers dealt round-robin.
 const empty=C.teams.filter(t=>!t.lead&&!t.mem.length);if(!empty.length)return;
 const free=C.roster.filter(r=>r.status==='active'&&!teamOf(r.id)).sort((a,b)=>b.rank-a.rank),J=free.filter(isJedi),T=free.filter(r=>!isJedi(r));
 for(const t of empty)if(J.length)t.lead=J.shift().id;
 for(let k=0;T.length&&k<(TEAMS.size-1)*empty.length;k++){const t=empty[k%empty.length];if(t.mem.length<TEAMS.size-1)t.mem.push(T.shift().id)}}
// This step's assignments (crisis id → team id) and who already fought it yourself.
function tAs(){if(!C.tAs||C.tAs.step!==C.step)C.tAs={step:C.step,map:{},played:[]};return C.tAs}
const twinUsed=()=>(C.twin&&C.twin.used)||[];
function teamAvail(t){const P=[...((C.tAs&&C.tAs.played)||[]),...twinUsed()];return teamUnits(t).filter(r=>fit(r)&&!P.includes(r.id))}
// Risk level 1–4 for this team on this mission (same bands as the galaxy panel, team Power scaled).
function teamRisk(T,M,id){const p=enemyPower(M,id),sp=T.reduce((s,r)=>s+unitPower(r),0)*TAUTO.scale,x=sp?100*p/sp:p/RISK_W.solo;return RISK.filter(r=>x>=r[0]).pop()[2]}
function teamOdds(t,o){const M=MISSIONS[o.mission],T=teamAvail(t),A=TAUTO;if(!M||T.length<TEAMS.min)return{ch:0,why:[],T,lv:0};
 const rk=T.reduce((s,r)=>s+r.rank,0),why=[['Base',A.base],[`Ranks (${rk})`,A.perRank*rk]],L=unit(t.lead);
 if(L&&T.includes(L))why.push([`Led by ${L.n}`,A.lead]);
 let bp=0;for(let i=0;i<T.length;i++)for(let j=i+1;j<T.length;j++){const v=C.bonds&&C.bonds[bkey(T[i].id,T[j].id)];if(v&&v.lvl)bp+=A.bond}
 if(bp)why.push(['Bonds',Math.min(A.bondMax,bp)]);const tired=T.filter(isTired).length;if(tired)why.push([`Tired ×${tired}`,-A.tired*tired]);
 if(T.length<TEAMS.size)why.push([`Short-handed ${T.length}/${TEAMS.size}`,-A.short*(TEAMS.size-T.length)]);
 const dv=(A.diff||{})[C.diff]||0;if(dv)why.push([DIFF[C.diff].n,dv]);const lv=teamRisk(T,M,o.mission);if(A.risk[lv])why.push([`${RISK[lv-1][1]} risk`,A.risk[lv]]);
 return{ch:Math.max(A.min,Math.min(A.max,why.reduce((s,w)=>s+w[1],0))),why,T,lv}}
const teamFor=o=>{const id=o&&o.crisis&&C.tAs&&C.tAs.step===C.step&&C.tAs.map[o.crisis];return id&&C.teams.find(t=>t.id===id)};
// Auto-resolve one crisis with a team. Called instead of ignoring it.
function autoTeam(x,t){const M=MISSIONS[x.mission],od=teamOdds(t,x),T=od.T,A=TAUTO,win=Math.random()*100<od.ch,nm=x.n||M.n,L=[];
 C.tFought=[...(C.tFought||[]),...T.map(r=>r.id)];
 if(win){const res={};for(const [k,v] of Object.entries(M.reward||{}))res[k]=Math.round(k==='credits'?v*DIFF[C.diff].income*MISSION_CR:v);for(const [k,v] of Object.entries(res))gain(k,v);
  const hurt=[],up=[];for(const r of T){r.xp+=A.xp;r.missions=(r.missions||0)+1;if(Math.random()*100<A.winWound){r.wound=Math.max(r.wound||0,Math.ceil(WOUND.light/healMult()));hurt.push(r.n)}if(promote(r))up.push(`${r.n} reached Rank ${r.rank}`)}
  L.push(`<b class="up">${t.n} won ${nm}</b> (auto, ${od.ch}%). ${fmtRes(res)||'No reward'}; +${A.xp} XP each${hurt.length?`; light wounds: ${hurt.join(', ')}`:''}`,...up);
  if(typeof bondPts==='function')for(let i=0;i<T.length;i++)for(let j=i+1;j<T.length;j++)bondPts(T[i].id,T[j].id,BOND.field||1,'strike team together')}
 else{gain('favor',A.loseFavor);for(const r of T)if(typeof addStress==='function')addStress(r,A.loseStress);
  const d=Math.random()*100,pool=[...T],v=d<A.death+A.capture&&pool.length?pool.splice(Math.floor(Math.random()*pool.length),1)[0]:null,h=pool.length?pickOne(pool):null;let fate='';
  if(v&&d<A.death){v.status='dead';C.legends.push({n:v.n,cls:v.cls,how:'Fell on a strike team mission',where:nm});if(typeof archive==='function')try{archive(v,'Fell on a strike team mission')}catch(e){}fate=`; <b class="bad">${v.n} was killed</b>`}
  else if(v){v.status='captured';v.capT=CAPTIVE;v.assign=null;fate=`; <b class="bad">${v.n} was captured</b> (rescue mission next step)`}
  if(h)h.wound=Math.max(h.wound||0,Math.ceil(WOUND.serious/healMult()));
  L.push(`<span class="bad">${t.n} lost ${nm}</span> (auto, ${od.ch}%). Senate Favor ${A.loseFavor}, stress +${A.loseStress} each${h?`; ${h.n} badly wounded (${h.wound} days)`:''}${fate}`)}
 if(typeof addUnrest==='function')addUnrest(regionOf(M.where),win?UNREST.win:UNREST.lose,`${t.n} ${win?'won':'lost'} ${nm}`);
 const txt=L.join(' · ')+'.';C.tLog=[{t:txt,m:C.month,win:win?1:0},...(C.tLog||[])].slice(0,TEAMS.log);
 if(C.chosen!=null)(C.tPend=C.tPend||[]).push(txt);else C.news.push(txt);   // a mission is launching: advance() wipes news, so hold it
 return win}

const _ignoreTm=ignoreCrisis;ignoreCrisis=function(x){ensureTeams();const t=teamFor(x)||(x&&x.crisis&&C.tAs&&C.tAs.step===C.step-1&&C.teams.find(k=>k.id===C.tAs.map[x.crisis]));
 if(t&&!x.hostages&&teamAvail(t).length>=TEAMS.min){delete C.tAs.map[x.crisis];autoTeam(x,t);return}_ignoreTm(x)};
const _launchTm=launchMission;launchMission=function(i,ids){if(C){const a=tAs();a.played=[...a.played,...ids];C.tFought=[...(C.tFought||[]),...ids];
  const o=C.options[i];if(o&&o.crisis)delete a.map[o.crisis]}return _launchTm(i,ids)};
let TDEB=[];
const _advanceTm=advance;advance=function(o){TDEB=[];const P=(C&&C.tPend)||[],st=C&&C.step;if(C)C.tPend=[];_advanceTm(o);if(C&&C.step!==st)C.tAs=null;if(P.length){C.news.push(...P);TDEB=P}};
const _templeAdvTm=templeAdvance;templeAdvance=function(){_templeAdvTm();const F=new Set(C.tFought||[]);
 for(const r of C.roster)if(r.status==='active')r.fat=F.has(r.id)?(r.fat||0)+1:0;C.tFought=[]};
const _buTm=battleUnit;battleUnit=function(r){const u=_buTm(r);if(isTired(r)){u.aim+=FATIGUE.aim;u.tired=1}return u};
const _debTm=debrief;debrief=function(win,msg,out){_debTm(win,msg,out);if(!TDEB.length)return;const b=document.querySelector('#modal .box .sum');
 if(b&&!document.querySelector('#modal .tdeb'))b.insertAdjacentHTML('afterend',`<div class="news tdeb"><b class="eyebrow">Strike teams</b>${TDEB.map(t=>`<p>${t}</p>`).join('')}</div>`)};

// ── UI ──
const TUI={sel:0};
function teamButtons(i,o){if(!C||!o.adv||!o.crisis||o.hostages||o.story||C.options.filter(y=>y.adv).length<2)return '';ensureTeams();
 const cur=teamFor(o),a=tAs(),busy=id=>Object.entries(a.map).some(([k,v])=>v===id&&k!==o.crisis),od=cur?teamOdds(cur,o):null,A=TAUTO;
 return `<div class="tauto"><div class="eyebrow">Or send a strike team · auto-resolves when you launch another mission</div><div class="picks">
 ${C.teams.map(t=>{const d=teamOdds(t,o),n=d.T.length;return `<button type="button" class="${cur===t?'on':''}" data-act="tas:${o.crisis}:${t.id}" ${n<TEAMS.min?'disabled':''} title="${teamUnits(t).map(r=>r.n).join(', ')}">${t.n} · ${n<TEAMS.min?'not enough free':d.ch+'%'}${busy(t.id)?' (moves here)':''}</button>`}).join('')}</div>
 ${od?`<div class="godds"><b>${od.ch}%</b> win <small class="muted">${od.why.map(([w,v])=>`${w} ${v>0?'+':''}${v}`).join(' · ')}</small></div>
 <p class="muted">Win: mission rewards, +${A.xp} XP each, ${A.winWound}% light wound each. Loss: Favor ${A.loseFavor}, stress +${A.loseStress}, one serious wound, ${A.capture}% one captured, ${A.death}% one killed. Members you also take into your own fight don't go.</p>`:''}</div>`}
function teamsPanel(){ensureTeams();const t=C.teams[TUI.sel]||C.teams[0];TUI.sel=C.teams.indexOf(t);
 const st=r=>r.status!=='active'?r.status:r.wound?`wounded ${r.wound}d`:r.assign?assignName(r):isTired(r)?'tired (−10 aim)':'ready';
 const act=C.roster.filter(r=>r.status==='active'||r.status==='captured');
 const chip=(r,on,a)=>{const o=teamOf(r.id);return `<button type="button" class="${on?'on':''}" data-act="${a}:${r.id}">${r.n} · ${r.cls} R${r.rank}${o&&o!==t?` <small class="muted">(${o.n.split(' ')[0]})</small>`:''}${isTired(r)?' · tired':''}</button>`};
 const U=teamUnits(t),bonds=[];for(let i=0;i<U.length;i++)for(let j=i+1;j<U.length;j++){const v=C.bonds&&C.bonds[bkey(U[i].id,U[j].id)];if(v&&v.lvl)bonds.push(`${U[i].n.split(' ')[0]} & ${U[j].n.split(' ')[0]} ${v.lvl}`)}
 return `<div class="eyebrow">Strike teams · ${C.teams.length}/${TEAMS.max}${C.teams.length<TEAMS.max?` · next at Barracks level ${TEAMS.barracks[C.teams.length-TEAMS.base]}`:''}</div>
 <div class="picks">${C.teams.map((k,i)=>`<button type="button" class="${i===TUI.sel?'on':''}" data-act="tsel:${i}">${k.n}</button>`).join('')}</div>
 <h3 class="gtitle">${t.n} <button type="button" data-act="tren:${t.id}" title="Rename">✎</button></h3>
 <p class="muted">A Jedi leads up to ${TEAMS.size-1} troopers. Teams that fight together bond. Give a team any crisis you don't play yourself.</p>
 <div class="gfacts">${U.map(r=>`<span>${r.id===t.lead?'Leader':'Trooper'}</span><b>${r.n} · ${r.cls} R${r.rank} <small class="${st(r)==='ready'?'muted':'bad'}">${st(r)}</small></b>`).join('')||'<span>Empty</span><b>Pick a leader and troopers below.</b>'}
 ${bonds.length?`<span>Bonds</span><b>${bonds.join(' · ')}</b>`:''}</div>
 <b class="eyebrow">Leader (Jedi)</b><div class="picks">${act.filter(isJedi).map(r=>chip(r,r.id===t.lead,'tlead')).join('')||'<span class="muted">No Jedi.</span>'}</div>
 <b class="eyebrow">Troopers (${t.mem.length}/${TEAMS.size-1})</b><div class="picks">${act.filter(r=>!isJedi(r)).map(r=>chip(r,t.mem.includes(r.id),'tmem')).join('')}</div>
 ${(C.tLog||[]).length?`<div class="glog"><b class="eyebrow">Team reports</b>${C.tLog.map(l=>`<p>Month ${l.m} · ${l.t}</p>`).join('')}</div>`:''}
 <button type="button" data-act="tclose">Back to the briefing</button>`}
function teamMove(id,t,lead){for(const k of C.teams){if(k.lead===id)k.lead=null;k.mem=k.mem.filter(x=>x!==id)}if(lead)t.lead=id;else if(t.mem.length<TEAMS.size-1)t.mem.push(id)}
// Returns true when it handled the click (caller re-renders).
function teamClick(ev){const b=ev.target.closest('[data-act^="tas:"],[data-act^="tsel:"],[data-act^="tlead:"],[data-act^="tmem:"],[data-act^="tren:"],[data-act="tclose"],[data-act="topen"]');if(!b||b.disabled)return false;
 ensureTeams();const [a,x,y]=b.dataset.act.split(':'),t=C.teams[TUI.sel]||C.teams[0];
 if(a==='topen'){GAL.teams=1;GAL.reg=null}else if(a==='tclose')GAL.teams=0;else if(a==='tsel')TUI.sel=+x;
 else if(a==='tas'){const m=tAs().map;if(m[x]===y)delete m[x];else{for(const k of Object.keys(m))if(m[k]===y)delete m[k];m[x]=y}}
 else if(a==='tlead'){if(t.lead===x)t.lead=null;else teamMove(x,t,1)}
 else if(a==='tmem'){if(t.mem.includes(x))t.mem=t.mem.filter(i=>i!==x);else teamMove(x,t,0)}
 else if(a==='tren'){const k=C.teams.find(z=>z.id===x),n=typeof prompt==='function'?prompt('Team name',k.n):null;if(n&&n.trim())k.n=n.replace(/[<>&"]/g,'').trim().slice(0,22)}
 saveGame();return true}
// Squad screen: one-tap "load team" + whether a unit is tired or promised to an auto-resolve.
function teamLoadHTML(){ensureTeams();return `<div class="picks tload"><span class="muted">Load a team:</span>${C.teams.map(t=>`<button type="button" data-tload="${t.id}">${t.n}</button>`).join('')}</div>`}
function teamLoad(id,o){const t=C.teams.find(k=>k.id===id),R=squadRule(),ok=r=>r&&fit(r)&&!R.used.includes(r.id)&&r.id!==(o&&o.hostage);if(!t)return pickSquad;
 const T=teamUnits(t).filter(ok).map(r=>r.id),rest=defaultSquad(o).filter(i=>!T.includes(i)),out=[...T];
 for(const i of rest){if(out.length>=R.max)break;const nj=out.map(unit).filter(isJedi).length;if(isJedi(unit(i))&&nj>=R.jmax)continue;out.push(i)}return out}
function teamTag(r){const a=C.tAs&&C.tAs.step===C.step?C.tAs.map:{},t=teamOf(r.id),job=t&&Object.keys(a).find(k=>a[k]===t.id);
 return `${isTired(r)?' · <b class="bad">tired −10 aim</b>':''}${job?` · ${t.n} auto: ${(CRISES[job]&&CRISES[job].n)||job}`:''}`}

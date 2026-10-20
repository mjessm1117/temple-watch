/* Field ops (Chat I): send 2–3 units on an off-screen job for X days. It resolves on a roll when they return; the result shows in the
   Temple news and the galaxy panel. Nobody dies: a failure costs stress and wounds. Data: data-galaxy.js (FIELD_OPS, FIELD).
   State C.field={list:[{id,k,planet,st,exp,left,team,ch,fresh}],n,log:[],era}. st: open → team → done | failed; open → lapsed.
   Hooks (wrappers): templeMonth (new ops), templeAdvance (time passes), assignOpts/assign (units away can't be reassigned). */
let FTEAM=[];
function ensureField(){if(!C)return;const era=C.era||1;
 if(!C.field||C.field.era!==era){const old=C.field;C.field={list:[],n:old?old.n:0,log:old?old.log:[],era};
  for(const r of C.roster)if(r.assign&&r.assign.startsWith('field:'))r.assign=null;    // a new era brings every team home
  spawnField(1)}}
function spawnField(n,cov){const F=C.field,keys=Object.keys(FIELD_OPS).filter(k=>!FIELD_OPS[k].covert===!cov&&!F.list.some(o=>o.k===k&&(o.st==='open'||o.st==='team'))),pl=FIELD_PLANETS[C.era||1]||FIELD_PLANETS[1];
 for(let i=0;i<n&&keys.length;i++){const k=keys.splice(Math.floor(Math.random()*keys.length),1)[0];
  F.list.push({id:'f'+(++F.n),k,planet:pickOne(pl),st:'open',exp:FIELD.expire,fresh:1})}}
const fieldOp=id=>C&&C.field&&C.field.list.find(o=>o.id===id);
const fieldWant=(r,D)=>D.want.includes(r.cls)||(D.want.includes('jedi')&&isJedi(r));
// Success chance for a team (0–100), with the reasons, so the panel can show the math.
function fieldOdds(k,team,planet){const D=FIELD_OPS[k],T=team.map(unit).filter(Boolean);if(!D||!T.length)return{ch:0,why:[]};
 const rk=T.reduce((s,r)=>s+r.rank,0),fits=Math.min(FIELD.matchMax,T.filter(r=>fieldWant(r,D)).length),why=[[`Base`,FIELD.base],[`Ranks (${rk})`,FIELD.perRank*rk]];
 if(fits)why.push([`Right skills ×${fits}`,FIELD.match*fits]);if(T.length>=3)why.push(['Third member',FIELD.three]);const reg=planet&&PLANETS[planet]&&PLANETS[planet].reg;if(reg&&typeof unrestOf==='function'&&unrestOf(reg)>=UNREST.hostile)why.push([`Unrest in ${REG_N[reg]}`,UNREST.fieldAt3]);if(D.stars>1)why.push([`Difficulty ${'★'.repeat(D.stars)}`,-FIELD.star*(D.stars-1)]);
 const raw=why.reduce((s,w)=>s+w[1],0);return{ch:Math.max(FIELD.min,Math.min(FIELD.max,raw)),why}}
function fieldRes(D){const o={};for(const [k,v] of Object.entries(D.res))o[k]=k==='credits'?Math.round(v*FIELD.cr*DIFF[C.diff].income):v;return o}
function sendField(id){if(typeof twinB==='function'&&twinB())return false;const o=fieldOp(id),T=FTEAM.map(unit).filter(r=>r&&fit(r));if(!o||o.st!=='open'||T.length<FIELD.team[0]||T.length>FIELD.team[1])return false;
 const D=FIELD_OPS[o.k];if(D.fee){if(C.res.credits<D.fee)return false;C.res.credits-=D.fee}o.st='team';o.team=T.map(r=>r.id);o.ch=fieldOdds(o.k,o.team,o.planet).ch;o.left=D.days;o.fresh=1;
 for(const r of T)r.assign='field:'+o.id;FTEAM=[];C.news.push(`${T.map(r=>r.n).join(', ')} left for ${o.planet}: ${D.n} (${o.ch}%). Back in ${D.days} days.`);saveGame();return true}
function resolveField(o){const D=FIELD_OPS[o.k],T=o.team.map(unit).filter(r=>r&&r.status==='active'),roll=Math.random()*100,win=roll<o.ch,lines=[];
 for(const r of T)if(r.assign==='field:'+o.id)r.assign=null;
 if(win){o.st='done';const res=fieldRes(D);for(const [k,v] of Object.entries(res))gain(k,v);
  for(const r of T){r.xp+=FIELD.xp;if(promote(r))lines.push(`${r.n} reached Rank ${r.rank}`)}
  if(typeof addUnrest==='function')addUnrest((PLANETS[o.planet]||{}).reg,UNREST.fieldWin);lines.unshift(`<b class="up">Field op success: ${D.n} on ${o.planet}.</b> ${fmtRes(res)}; +${FIELD.xp} XP each`)}
 else{o.st='failed';const bad=roll>=100-FIELD.badRoll;
  for(const r of T)if(typeof addStress==='function')addStress(r,FIELD.failStress);
  const cap=D.covert&&T.length&&Math.random()*100<FIELD.covert.capture?pickOne(T):null;if(cap){cap.status='captured';cap.capT=CAPTIVE;T.splice(T.indexOf(cap),1)}
  const hurt=T.length?pickOne(T):null;if(hurt){const w=Math.ceil((bad?FIELD.badWound:FIELD.failWound)/healMult());hurt.wound=Math.max(hurt.wound||0,w)}
  lines.unshift(`<span class="bad">Field op failed: ${D.n} on ${o.planet}.</span> Stress +${FIELD.failStress} each${hurt?`; ${hurt.n} ${bad?'badly ':''}wounded (${hurt.wound} days)`:''}${cap?`; <b class="bad">${cap.n} was captured</b>`:''}`)}
 const txt=lines.join(' · ')+'.';C.news.push(txt);C.field.log.unshift({t:txt,m:C.month,win:win?1:0});C.field.log.length=Math.min(C.field.log.length,FIELD.log)}
// Time passes (every mission): open ops count down to lapse, teams count down to return.
function fieldAdvance(){ensureField();const F=C.field;
 for(const o of F.list){if(o.fresh){o.fresh=0;continue}
  if(o.st==='open'&&(o.exp-=DAYS)<=0){o.st='lapsed';C.news.push(`Field op lapsed: ${FIELD_OPS[o.k].n} on ${o.planet}.`);if(typeof addUnrest==='function')addUnrest((PLANETS[o.planet]||{}).reg,UNREST.lapse,'a field op lapsed')}
  else if(o.st==='team'&&(o.left-=DAYS)<=0)resolveField(o)}
 F.list=F.list.filter(o=>o.st==='open'||o.st==='team')}
function fieldMonth(){ensureField();const [a,b]=FIELD.perMonth;spawnField(C.month>=3?b:a);if(C.month>=FIELD.covert.from)spawnField(FIELD.covert.perMonth,1);C.news.push('New field ops are on the galaxy map.')}
const _templeAdvanceF=templeAdvance;templeAdvance=function(){_templeAdvanceF();fieldAdvance()};
const _templeMonthF=templeMonth;templeMonth=function(){_templeMonthF();fieldMonth()};
const _assignOptsF=assignOpts;assignOpts=function(r){if(r.assign&&r.assign.startsWith('field:')){const o=fieldOp(r.assign.slice(6));return[[r.assign,`On a field op${o?`: ${FIELD_OPS[o.k].n}, back in ${o.left} days`:''}`]]}return _assignOptsF(r)};
const _assignF=assign;assign=function(id,v){const r=unit(id);if(r&&r.assign&&r.assign.startsWith('field:'))return;_assignF(id,v)};

// Briefing panel for a field op pin (galaxy.js calls this).
function fieldPanel(o){const D=FIELD_OPS[o.k],P=PLANETS[o.planet]||{},away=o.st==='team';
 const pool=C.roster.filter(fit),sel=FTEAM.filter(id=>pool.some(r=>r.id===id)),od=fieldOdds(o.k,away?o.team:sel,o.planet),n=sel.length,ok=n>=FIELD.team[0]&&n<=FIELD.team[1];
 const res=fmtRes(fieldRes(D)),wants=D.want.map(w=>w==='jedi'?'any Jedi':w).join(', ');
 return `<div class="eyebrow">Field op · ${o.planet}${P.reg?` · ${REG_N[P.reg]}`:''}</div><h3 class="gtitle">${D.n}</h3><p>${D.desc}</p>
 <div class="gfacts"><span>Reward</span><b>${res}, +${FIELD.xp} XP each</b><span>Time away</span><b>${D.days} days (${Math.round(D.days/DAYS)} mission${D.days>DAYS?'s':''})</b>
 <span>Difficulty</span><b>${'★'.repeat(D.stars)}${'☆'.repeat(3-D.stars)}</b><span>Best fit</span><b>${wants}</b>
 <span>${away?'Returns in':'Expires in'}</span><b>${away?o.left:o.exp} days</b>${D.fee?`<span>Fee</span><b>${D.fee} Cr up front${away?' (paid)':''}</b>`:''}<span>If it fails</span><b class="bad">Stress +${FIELD.failStress} each, one wounded${D.covert?`, ${FIELD.covert.capture}% one captured`:''}. Nobody dies.</b></div>
 ${away?`<p class="muted">Team: ${o.team.map(unit).filter(Boolean).map(r=>r.n).join(', ')}. They can't deploy until they return.</p><div class="godds"><b>${o.ch}%</b> success</div>`
 :`<p class="muted">Pick ${FIELD.team[0]}–${FIELD.team[1]} units. They miss the next ${Math.round(D.days/DAYS)} mission${D.days>DAYS?'s':''}.</p>
 <div class="picks">${pool.map(r=>`<button type="button" class="${sel.includes(r.id)?'on':''}" data-act="fop:${r.id}" title="${fieldWant(r,D)?'Right skills for this job':''}">${r.n} · ${r.cls} R${r.rank}${fieldWant(r,D)?' ✓':''}</button>`).join('')||'<span class="muted">Nobody is free.</span>'}</div>
 <div class="godds"><b>${n?od.ch+'%':'—'}</b> success${n?` <small class="muted">${od.why.map(([t,v])=>`${t} ${v>0?'+':''}${v}`).join(' · ')}</small>`:''}</div>
 <button type="button" class="primary" data-act="fsend:${o.id}" ${ok&&C.res.credits>=(D.fee||0)?'':'disabled'}>${D.fee?`Pay ${D.fee} Cr · send`:'Send team'}${n?` (${n})`:''}</button>`}`}
function fieldLogHTML(){const L=(C.field&&C.field.log)||[];return L.length?`<div class="glog"><b class="eyebrow">Field reports</b>${L.map(l=>`<p>Month ${l.m} · ${l.t}</p>`).join('')}</div>`:''}
function fieldClick(a,x){if(a==='fop'){FTEAM=FTEAM.includes(x)?FTEAM.filter(i=>i!==x):[...FTEAM,x].slice(-FIELD.team[1]);return true}
 if(a==='fsend'){sendField(x);return true}return false}

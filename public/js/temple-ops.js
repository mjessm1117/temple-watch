/* Progression logic (wave 3, Chat P): research, Sith ops, stress & scars, campaignMods(), and the Research / Sith Ops tabs.
   Data: temple-prog.js. Hooks: temple.js calls progMods (battleUnit), progAfterMission (applyResults), progAdvance (advance), progMonth (month turn). */
for(const t of Object.values(SABER_TRAITS))t.desc=t.desc||t.tip+'.';
const researched=id=>!id||!!(C&&C.research&&C.research.done.includes(id));
const okGear=it=>it&&hasWing(it.need)&&(researched(it.res)||unlockedG(it.id))&&(!it.market||unlockedG(it.id));
function ensureProg(){C.research=C.research||{done:[],cur:null,prog:0};C.ops=C.ops||{list:[],mods:[],n:0};if((C.ops.era||1)!==(C.era||1)){C.ops={list:[],mods:[],n:C.ops.n,era:C.era||1}}
 for(const r of C.roster){if(r.stress==null)r.stress=0;r.scars=r.scars||[];if(!r.gear.util)r.gear.util='none';if(!r.gear.form)r.gear.form='shiiCho'}}

// Campaign → battle modifiers (contract): Chat X reads this in startMission. Unit-level numbers go through battleUnit instead.
function campaignMods(){const o={enemyAim:0,enemyHp:0,extraEnemies:0,squadAim:0};if(!C||!C.ops)return o;
 for(const m of C.ops.mods)for(const [k,v] of Object.entries(m.mod))o[k]=(o[k]||0)+v;return o}
const xpMult=r=>(C.wings.training>=2?1.2:C.wings.training?1.1:1)*(C.staff.training?1.1:1)*(researched('holocron')?1.1:1)*(r.trait&&TRAITS[r.trait].xp||1);
const stressLv=s=>STRESS_LV.filter(l=>(s||0)>=l.at).pop();
const crystalOf=r=>Object.keys(CRYSTALS).find(k=>CRYSTALS[k]===r.col)||null;

// Unit-level battle mods (called from templeMods): utility item, crystal, form, research perks, stress, scars, will.
function progMods(u,r){const g=r.gear,it=UTIL[g.util];
 if(it&&it.mod){if(it.give){const k=it.give==='grenade'?'nades':'kits';if(u[k]==null)u[k]=0;if(!u.abil.includes(it.give))u.abil.splice(1,0,it.give)}addMod(u,it.mod)}
 if(isJedi(r)){const cr=crystalOf(r);if(cr)addMod(u,CRYSTAL_FX[cr].mod);if(FORMS[g.form])addMod(u,FORMS[g.form].mod)}
 if(r.cls==='Medic'&&researched('fieldMed'))u.kits++;
 if(researched('sithTactics'))u.aim+=5;if(isJedi(r))u.aim+=perkVal('jediAim');if(researched('beastLore'))u.aimVsHorror=(u.aimVsHorror||0)+10;
 addMod(u,stressLv(r.stress).mod);for(const s of r.scars)addMod(u,SCARS[s].mod);
 u.stress=r.stress;u.scars=[...r.scars];u.will=Math.max(5,u.will||50);return u}

// --- stress & scars after a mission ---
function addStress(r,n){if(n>0&&r.scars.includes('nightmares'))n=Math.round(n*SCARS.nightmares.stressX);if(n>0&&r.trait==='steady')n=Math.round(n*.75);
 r.stress=Math.max(0,Math.min(100,(r.stress||0)+n))}
function giveScar(r,kind,out){const have=r.scars;if(have.length>=SCAR.max)return;
 let pool=Object.keys(SCARS).filter(k=>SCARS[k].kind===kind&&!have.includes(k));if(!pool.length)return;const k=pickOne(pool);have.push(k);lifeLog(r,`${kind==='wound'?'Scarred':'Traumatized'}: ${SCARS[k].n}`);quote(r,'scar');
 out.prog.push(`<span class="bad">${r.n}: new ${kind==='wound'?'scar':'trauma'} · ${SCARS[k].n}</span> (${SCARS[k].desc})`)}
function progAfterMission(dep,win,out){out.prog=out.prog||[];ensureProg();
 const deaths=dep.filter(d=>!d.u.vip&&d.r.status==='dead').length,horror=S.units.some(u=>u.side==='e'&&u.horror);
 for(const {r,u} of dep){if(u.vip||r.status!=='active')continue;const before=r.stress;
  let n=STRESS.base+(u.downed?STRESS.grave:u.hp*2<=u.max?STRESS.serious:u.hurt?STRESS.light:0)+deaths*STRESS.allyDied+(horror?STRESS.horror:0)+(win?0:STRESS.lost);
  addStress(r,n);const lv=stressLv(r.stress);if(lv!==stressLv(before)&&lv.at)out.prog.push(`${r.n} is <b class="warn">${lv.n}</b> (stress ${r.stress}). ${lv.desc}`);
  if(u.downed&&rnd(SCAR.grave))giveScar(r,'wound',out);
  const tr=(deaths?SCAR.trauma:0)+(r.stress>=STRESS.breaking?SCAR.breaking:0);
  if(tr&&rnd(tr)){const pool=horror&&rnd(researched('beastLore')?25:50)?'fearsHorrors':null;
   if(pool&&!r.scars.includes(pool)&&r.scars.length<SCAR.max){r.scars.push(pool);out.prog.push(`<span class="bad">${r.n}: new trauma · ${SCARS[pool].n}</span> (${SCARS[pool].desc})`)}else giveScar(r,'trauma',out)}
  if(isJedi(r)){const d=(FORMS[r.gear.form]&&FORMS[r.gear.form].dark||0)+(r.scars.includes('anger')?1:0);if(d){r.dark=Math.min(10,r.dark+d);out.prog.push(`${r.n}: Darkness +${d} (${r.scars.includes('anger')?'anger':'Juyo'}).`)}}}
 for(const m of C.ops.mods)m.left--;C.ops.mods=C.ops.mods.filter(m=>m.left>0)}

// --- time passes between missions: research, rest, ops teams, treatment ---
function progAdvance(){ensureProg();const R=C.research;
 if(R.cur&&C.wings.archives){R.prog+=DAYS*(C.wings.archives>=2?1.5:1)*(C.staff.archives?1.25:1);const P=RESEARCH[R.cur];
  if(R.prog>=P.days){R.done.push(R.cur);C.news.push(`Research complete: ${P.n}. ${P.desc}`);if(R.cur==='kyberLore')C.res.kyber++;if(P.dark)gain('orderDark',P.dark);R.cur=null;R.prog=0}}
 const deployed=new Set((S&&S.units||[]).filter(u=>u.side==='p'&&u.rid).map(u=>u.rid));
 for(const r of C.roster.filter(r=>r.status==='active')){
  if(!deployed.has(r.id)){let d=STRESS.bench+(r.assign==='rest'?STRESS.rest:0)+(r.assign==='calm'?STRESS.calm:0);addStress(r,-d)}
  if(C.staff.gardens)addStress(r,-STRESS.gardensStaff);
  if(r.assign==='calm'&&C.wings.gardens>=2&&r.scars.some(k=>SCARS[k].kind==='trauma')&&rnd(SCAR.treat)){const k=r.scars.find(k=>SCARS[k].kind==='trauma');r.scars=r.scars.filter(x=>x!==k);C.news.push(`${r.n} made peace with it: ${SCARS[k].n} is gone.`)}
  if(r.assign==='rest'&&C.wings.medical>=3&&r.scars.some(k=>SCARS[k].kind==='wound')&&rnd(SCAR.treat)){const k=r.scars.find(k=>SCARS[k].kind==='wound');r.scars=r.scars.filter(x=>x!==k);C.news.push(`Bacta treatment: ${r.n}'s ${SCARS[k].n} is healed.`)}
  if(r.assign==='calm'&&!r.stress&&!(isJedi(r)&&r.dark>0)&&!(C.wings.gardens>=2&&r.scars.some(k=>SCARS[k].kind==='trauma'))){r.assign=null;C.news.push(`${r.n} is at peace and back on call.`)}
  if(r.assign&&r.assign.startsWith('op:'))r.assign=null}
 for(const o of C.ops.list.filter(o=>o.st==='team')){const T=o.team.map(unit).filter(Boolean),ch=Math.min(OPS.max,OPS.teamBase+OPS.perRank*T.reduce((s,r)=>s+r.rank,0));
  if(rnd(ch)){o.st='done';for(const r of T){r.xp+=OPS.xp;if(promote(r))C.news.push(`${r.n} reached Rank ${r.rank}. Choose a new skill in the Roster.`)}C.news.push(`Sith op stopped: ${SITH_OPS[o.k].n}. The team earns +${OPS.xp} XP each.`)}
  else{o.st='open';for(const r of T)addStress(r,OPS.failStress);C.news.push(`The team failed to stop ${SITH_OPS[o.k].n} (stress +${OPS.failStress}). Counter it with Intel or it hits at month end.`)}}}
// Month turns over: ignored ops land, new ops appear.
function progMonth(){ensureProg();for(const o of C.ops.list.filter(o=>o.st==='open'))opHits(o);C.ops.list=C.ops.list.filter(o=>o.st==='team');
 const n=C.month>=3?2:1,keys=Object.keys(SITH_OPS);for(let i=0;i<n;i++){const k=pickOne(keys.filter(k=>!C.ops.list.some(o=>o.k===k)));C.ops.list.push({id:'op'+(++C.ops.n),k,st:'open'})}
 C.news.push(`Imperial Intelligence is moving: ${n} Sith op${n>1?'s':''} this month. See the Sith Ops tab.`);lifeMonth()}
function opHits(o){const D=SITH_OPS[o.k];o.st='hit';C.news.push(`<span class="bad">Ignored Sith op: ${D.n}.</span> ${D.desc.replace('If ignored: ','')}`);
 if(D.mod)C.ops.mods.push({k:o.k,mod:D.mod,left:D.missions});for(const [k,v] of Object.entries(D.res||{}))gain(k,v);if(C.res.kyber<0)C.res.kyber=0;
 if(D.hurt){const r=pickOne(C.roster.filter(able));if(r){r.wound=Math.max(r.wound,10);addStress(r,20)}}}
const opCost=o=>Math.max(1,SITH_OPS[o.k].intel-(researched('codebreak')?1:0));
function counterOp(id){const o=C.ops.list.find(o=>o.id===id);if(!o||o.st!=='open'||C.res.intel<opCost(o))return;C.res.intel-=opCost(o);o.st='done';C.news.push(`Intel spent: ${SITH_OPS[o.k].n} is exposed and stopped.`);saveGame()}
let OPTEAM=[];
function sendTeam(id){const o=C.ops.list.find(o=>o.id===id),T=OPTEAM.map(unit).filter(r=>r&&fit(r));if(!o||o.st!=='open'||T.length!==2)return;
 o.st='team';o.team=T.map(r=>r.id);for(const r of T)r.assign='op:'+o.id;OPTEAM=[];saveGame()}
function startResearch(k){const P=RESEARCH[k],R=C.research;if(!P||!C.wings.archives||R.cur||R.done.includes(k)||!(P.need||[]).every(researched))return;
 const c=P.cost;if(C.res.credits<(c.credits||0)||C.res.intel<(c.intel||0))return;C.res.credits-=c.credits||0;C.res.intel-=c.intel||0;R.cur=k;R.prog=0;saveGame()}
function setUtil(id,k){const r=unit(id),it=UTIL[k];if(!r||!it||r.gear.util===k||!okGear(it))return;if(!pay(priceOf(it.cost)))return;r.gear.util=k;saveGame()}
function setForm(id,k){const r=unit(id),f=FORMS[k];if(r&&f&&isJedi(r)&&researched(f.res)){r.gear.form=k;saveGame()}}
function raiseMaster(id){const r=unit(id);if(r&&isJedi(r)&&r.title==='Knight'&&r.rank>=5){r.title='Master';C.news.push(`The Council names ${r.n} a Jedi Master.`);saveGame()}}

// --- screens ---
const costTxt=c=>[c.credits&&c.credits+' Cr',c.intel&&c.intel+' Intel'].filter(Boolean).join(' + ')||'free';
function researchTab(){const R=C.research;if(!C.wings.archives)return '<p class="muted">Build the Archives (Wings tab) to start research.</p>';
 const sp=(C.wings.archives>=2?1.5:1)*(C.staff.archives?1.25:1),cur=R.cur&&RESEARCH[R.cur];
 return `<p>${cur?`Researching <b>${cur.n}</b>: ${Math.floor(R.prog)}/${cur.days} days (+${Math.round(DAYS*sp)} per mission).`:'<span class="warn">No project running.</span> Pick one below.'} Done: ${R.done.length}/${Object.keys(RESEARCH).length}.</p>
 <div class="seats">${Object.entries(RESEARCH).map(([k,P])=>{const done=R.done.includes(k),need=(P.need||[]).filter(n=>!researched(n)),c=P.cost,no=R.cur||need.length||C.res.credits<(c.credits||0)||C.res.intel<(c.intel||0);
  return `<div class="seat ${done?'':need.length?'vac':''}" data-tip="research:${k}"><b>${P.n}</b><div>${P.desc}</div><small class="muted">${P.days} days · ${costTxt(c)}${need.length?` · needs ${need.map(n=>RESEARCH[n].n).join(', ')}`:''}</small>
  ${done?'<div class="up">Done</div>':R.cur===k?'<div class="warn">In progress</div>':`<button type="button" data-act="res:${k}" ${no?'disabled':''}>Research</button>`}</div>`}).join('')}</div>`}
function opsTab(){const L=C.ops.list,fitU=C.roster.filter(fit),mods=C.ops.mods;
 return `<p class="muted">The Empire runs ops each month. Counter one with Intel now, or send a 2-unit team: they miss the next mission and succeed on a roll (better with rank). Anything still open at month end hits you.</p>
 ${mods.length?`<div class="news">${mods.map(m=>`<p class="bad">Active: ${SITH_OPS[m.k].n} · ${m.left} mission${m.left>1?'s':''} left</p>`).join('')}</div>`:''}
 ${L.length?L.map(o=>{const D=SITH_OPS[o.k],T=(o.team||[]).map(unit).filter(Boolean),ch=Math.min(OPS.max,OPS.teamBase+OPS.perRank*OPTEAM.map(unit).filter(Boolean).reduce((s,r)=>s+r.rank,0));
  return `<div class="wing"><div><b>${D.n}</b> <small>${o.st==='open'?'<span class="warn">Open</span>':o.st==='team'?'Team deployed':o.st==='done'?'<span class="up">Stopped</span>':'<span class="bad">Hit</span>'}</small><p>${D.desc}</p>
  ${o.st==='team'?`<p class="muted">Team: ${T.map(r=>r.n).join(' & ')}. Resolves after the next mission.</p>`:''}
  ${o.st==='open'?`<div class="picks">Team (pick 2): ${fitU.map(r=>`<button type="button" class="${OPTEAM.includes(r.id)?'on':''}" data-act="opt:${r.id}">${r.n} R${r.rank}</button>`).join('')}</div>`:''}</div>
  ${o.st==='open'?`<div style="display:grid;gap:4px"><button type="button" data-act="opi:${o.id}" ${C.res.intel<opCost(o)?'disabled':''}>Spend ${opCost(o)} Intel</button><button type="button" data-act="opteam:${o.id}" ${OPTEAM.length!==2?'disabled':''}>Send team · ${ch}%</button></div>`:''}</div>`}).join('')
 :'<p class="muted">No Sith ops yet. They start next month.</p>'}`}
// Armory rows added for every unit: armor (by who), utility slot; Jedi also get crystal stats and a form.
function armoryProg(r){const g=r.gear,J=isJedi(r);let h='';
 h+=`<div class="grow"><b>Armor</b>${Object.entries(ARMOR).filter(([,a])=>(a.who==='any'||a.who===(J?'jedi':'troop'))&&(!a.market||unlockedG(a.id))).map(([k,a])=>`<button type="button" class="${g.armor===k?'on':''}" data-act="armor:${r.id}:${k}" data-tip="gear:${k}" ${g.armor!==k&&(!okGear(a)||C.res.credits<priceOf(a.cost))?'disabled':''}>${a.n} · ${a.desc}${g.armor===k?'':' · '+priceOf(a.cost)+' Cr'}${lockTxt(a)}</button>`).join('')}</div>`;
 h+=`<div class="grow"><b>Utility</b>${Object.entries(UTIL).filter(([,it])=>!it.market||unlockedG(it.id)).map(([k,it])=>`<button type="button" class="${g.util===k?'on':''}" data-act="util:${r.id}:${k}" data-tip="gear:${k}" ${g.util!==k&&(!okGear(it)||C.res.credits<priceOf(it.cost))?'disabled':''}>${it.n}${k==='none'?'':' · '+it.desc}${g.util===k||!it.cost?'':' · '+priceOf(it.cost)+' Cr'}${lockTxt(it)}</button>`).join('')}</div>`;
 if(J){h+=`<div class="grow"><b>Form</b>${Object.entries(FORMS).map(([k,f])=>`<button type="button" class="${g.form===k?'on':''}" data-act="form:${r.id}:${k}" data-tip="gear:${k}" ${researched(f.res)?'':'disabled'}>${f.n} · ${f.desc}${lockTxt(f)}</button>`).join('')}</div>`;
  const cr=crystalOf(r);if(cr)h+=`<p class="muted">Crystal: <b>${CRYSTAL_FX[cr].n}</b> · ${CRYSTAL_FX[cr].desc} ${Object.values(CRYSTAL_FX).filter(c=>c.n!==CRYSTAL_FX[cr].n).map(c=>`${c.n}: ${c.desc}`).join(' · ')}</p>`}
 return h}
const lockTxt=it=>it.market&&!unlockedG(it.id)?' · black market':!researched(it.res)&&!unlockedG(it.id)?` · research ${RESEARCH[it.res].n}`:needTxt(it.need);
// Roster extras: stress, scars, Master button.
function rosterProg(r){const lv=stressLv(r.stress),sc=r.scars.map(k=>`<span title="${SCARS[k].desc}">${SCARS[k].n}</span>`).join(', ');
 return `<small>Stress ${r.stress}/100 · <span class="${lv.at?'warn':''}" title="${lv.desc}">${lv.n}</span> · Will ${battleUnit(r).will}${sc?` · <span class="bad">Scars: ${sc}</span>`:''}</small>
 ${isJedi(r)&&r.title==='Knight'&&r.rank>=5?`<div class="picks">The Council will hear you. <button type="button" data-act="master:${r.id}">Name ${r.n} a Jedi Master</button></div>`:''}${pairHTML(r)}`}
function progClick(a,x,y){if(lifeClick(a,x,y))return true;if(a==='res')startResearch(x);else if(a==='opi')counterOp(x);else if(a==='opteam')sendTeam(x);
 else if(a==='opt'){OPTEAM=OPTEAM.includes(x)?OPTEAM.filter(i=>i!==x):[...OPTEAM,x].slice(-2)}
 else if(a==='util')setUtil(x,y);else if(a==='form')setForm(x,y);else if(a==='master')raiseMaster(x);else return false;return true}

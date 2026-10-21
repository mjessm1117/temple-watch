/* Saga (story-first layer, Era 1). Data: data-saga.js. Spec: docs/specs/saga.md.
   Load after story.js, battle.js, identity.js, console.js (it wraps their versions) and before screens.js.
   Hooks by wrapping globals: baseScreen, squadScreen, launchMission, startMission, bvFire, bvPick, applyResults, optionsFor, battleUnit.
   State: C.saga = {t:{cast:trust}, id:{cast:rosterId}, seen:[ids], q:[scenes], visit, talked, pm:[personal mission ids], pmDone:[], gone:[], ap}. ~2 KB. */
const sagaOn=()=>typeof C!=='undefined'&&!!C&&(C.era||1)===1;
let SAGA_NEXT=null;const SAGA_FORCE=2;  // at most 2 forced talks per hub visit; the rest wait for the next visit
function sagaInit(){if(!C)return null;const g=C.saga=C.saga||{t:{},id:{},seen:[],q:[],visit:'',talked:'',pm:[],pmDone:[],gone:[],ap:0};
 for(const [k,c] of Object.entries(CAST))if(!g.id[k]){const r=C.roster.find(r=>r.n===c.n);if(r)g.id[k]=r.id}
 for(const k in g.id)if(g.t[k]==null)g.t[k]=0;return g}
const castR=k=>{const id=C.saga.id[k];return id?unit(id):null};
const castOn=k=>{const r=castR(k);return r&&r.status==='active'?r:null};
const castKey=rid=>Object.keys(C.saga.id).find(k=>C.saga.id[k]===rid);
const castName=k=>{const r=castR(k);return r?r.n:CAST[k]?CAST[k].n:k};
const sagaTxt=(s,k,x={})=>String(s||'').replace(/\{(\w+)\}/g,(m,v)=>v==='n'?castName(k):x[v]!=null?x[v]:CAST[v]?castName(v):m);
const sagaDone=()=>(C.story&&C.story.done)||0;
function trustAdd(k,n){const g=C.saga;if(!castR(k))return null;g.t[k]=Math.max(TRUST.min,Math.min(TRUST.max,(g.t[k]||0)+n));return `${castName(k)} ${n>0?'trusts you more':'trusts you less'}`}

// Conditions shared by talks, beats and aftermath choices.
function sagaWhen(w,k){w=w||{};const f=C.flags,t=k?C.saga.t[k]||0:0;
 if(w.done!=null&&sagaDone()<w.done)return false;
 if(w.act!=null&&(typeof actNow==='function'?actNow():1)<w.act)return false;
 if(w.flag&&!f[w.flag])return false;if(w.notFlag&&f[w.notFlag])return false;
 if(w.anyFlag&&!w.anyFlag.some(x=>f[x]))return false;
 if(w.need&&!w.need.every(castOn))return false;
 if(w.minT!=null&&t<w.minT)return false;if(w.maxT!=null&&t>w.maxT)return false;return true}

// Apply a choice's campaign effects. Returns {lines, ok} (ok=false when a chance roll failed).
function sagaFx(f,k){const g=C.saga,out=[],r=k?castR(k):null,pass={};f=f||{};
 if(f.chance!=null&&!rnd(f.chance*100)){const x=sagaFx(f.fail||{},k);return{lines:x.lines,ok:false}}
 for(const [key,v] of Object.entries(f)){
  if(key==='chance'||key==='fail')continue;
  if(key==='t'){const l=r&&trustAdd(k,v);if(l)out.push(l)}
  else if(key==='trust'){for(const [ck,n] of Object.entries(v)){const l=trustAdd(ck,n);if(l)out.push(l)}}
  else if(key==='dark'){if(r&&isJedi(r)){r.dark=Math.max(0,(r.dark||0)+v);out.push(`${r.n}: Darkness ${sgn(v)}`)}}
  else if(key==='stress'){if(r&&typeof addStress==='function'){r.scars=r.scars||[];addStress(r,v);out.push(`${r.n}: stress ${sgn(v)}`)}}
  else if(key==='flag'){for(const x of [].concat(v))C.flags[x]=1}
  else if(key==='retire'){if(r){r.status='retired';r.role=v;if(r.assign&&C.staff)for(const w in C.staff)if(C.staff[w]===r.id)delete C.staff[w];r.assign=null;
   if(r.rank>=2&&typeof archive==='function')archive(r,v+'.');out.push(`${r.n} leaves the squad: ${v.toLowerCase()}`)}}
  else if(key==='teach'){if(r&&C.story){C.story.teach[r.cls]=r.n;out.push(`${r.n} will teach the next ${r.cls} recruit`)}}
  else if(key==='away'){if(r){r.wound=Math.max(r.wound||0,v);out.push(`${r.n} is away ${v} days`)}}
  else if(key==='personal'){if(!g.pm.includes(v)&&!g.pmDone.includes(v)&&CRISES[v]){g.pm.push(v);if(!C.options.some(o=>o.crisis===v))C.options.push({...CRISES[v],crisis:v,adv:0,personal:1});out.push(`New personal mission: ${CRISES[v].n}`)}}
  else pass[key]=v}
 if(Object.keys(pass).length)out.push(...applyFx(pass));
 return{lines:out,ok:true}}
// Plain-words preview of a choice.
function sagaPreview(f,k){if(!f)return 'Nothing changes';const o=[],pass={};
 for(const [key,v] of Object.entries(f)){
  if(key==='t')o.push(`${castName(k)} ${v>0?'trusts you more':'trusts you less'}`);
  else if(key==='trust')for(const [ck,n] of Object.entries(v)){if(castR(ck))o.push(`${castName(ck)} ${n>0?'trusts you more':'trusts you less'}`)}
  else if(key==='dark')o.push(`Their Darkness ${sgn(v)}`);else if(key==='stress')o.push(`Their stress ${sgn(v)}`);
  else if(key==='retire')o.push('They leave the squad');else if(key==='teach')o.push('They teach the next recruit');
  else if(key==='away')o.push(`Away ${v} days`);else if(key==='personal')o.push(`Unlocks a personal mission`);
  else if(key==='chance')o.push(`${Math.round(v*100)}% it goes well`);else if(key!=='flag'&&key!=='fail')pass[key]=v}
 const p=Object.keys(pass).length?choiceText(pass):'';if(p&&p!=='Nothing changes')o.push(p);return o.join(' · ')||'Nothing changes yet'}
const sagaCant=c=>Object.entries(c.fx||{}).some(([k,v])=>RES_NAMES[k]&&k!=='orderDark'&&k!=='favor'&&v<0&&(C.res[k]||0)+v<0)||(c.need||[]).some(k=>!castOn(k));

// ── Scenes: talks, aftermath, grief. One renderer; the reply screen shows the speaker's answer. ──
function sagaScene(sc,fromQ){SCR=()=>sagaScene(sc,fromQ);const m=$('#modal');m.hidden=false;const k=sc.who,r=k&&castR(k);
 const eye=sc.kind==='talk'?`Temple · ${r?r.n:''}${r?' · '+TRUST.word(C.saga.t[k]||0):''}`:sc.kind==='after'?`Aftermath · ${sc.mn||''}`:'Hall of Remembrance';
 m.innerHTML=`<div class="box saga-scene"><div class="eyebrow">${eye}</div>${r?`<div class="saga-who"><span class="mini" data-pt="${r.id}" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><b>${r.n}</b><small>${CAST[k]?CAST[k].arc:''}</small></div>`:''}
 <h2>${sc.t}</h2><p>${sagaTxt(sc.text,k,sc.x)}</p>
 ${sc.ch.map((c,i)=>`<button type="button" class="choice" data-ch="${i}" ${sagaCant(c)?'disabled':''}><b>${c.l}</b><span>${sagaPreview(c.fx,k)}</span></button>`).join('')}</div>`;
 m.onclick=ev=>{const b=ev.target.closest('[data-ch]');if(!b||b.disabled)return;const c=sc.ch[+b.dataset.ch],g=C.saga;
  if(sc.id&&!g.seen.includes(sc.id))g.seen.push(sc.id);if(fromQ)g.q.shift();
  const res=sagaFx(c.fx,k),say=res.ok?c.say:(c.sayFail||c.say);saveGame();sagaReply(sc,c,say,res.lines)}}
function sagaReply(sc,c,say,lines){SCR=()=>baseScreen();const m=$('#modal'),k=sc.who;
 if(lines.length)C.news.push(`${sc.t}: ${lines.join(' · ')}.`);saveGame();
 m.innerHTML=`<div class="box saga-scene"><div class="eyebrow">You chose · ${c.l}</div><h2>${sc.t}</h2>${say?`<p class="saga-say">${sagaTxt(say,k,sc.x)}</p>`:''}
 ${lines.length?`<div class="news">${lines.map(l=>`<p>${l}</p>`).join('')}</div>`:''}<button type="button" class="primary" id="scOk">Continue</button></div>`;
 m.onclick=null;$('#scOk').onclick=()=>baseScreen()}
// Build a scene object from a queue entry or a talk id.
function sagaBuild(e){const g=C.saga;
 if(e.k==='talk'){const T=TALKS.find(x=>x.id===e.id);return T&&{...T,kind:'talk'}}
 if(e.k==='after'){const A=AFTER[e.id];if(!A)return null;const who=A.who&&castR(A.who)&&castR(A.who).status!=='dead'?A.who:null;return{...A,who,id:'after:'+e.id+':'+e.n,kind:'after',mn:e.mn}}
 if(e.k==='grief')return{...GRIEF,who:e.who,kind:'grief',id:'grief:'+e.dead,x:{dead:castName(e.dead)}};return null}
const talkReady=T=>!C.saga.seen.includes(T.id)&&castOn(T.who)&&sagaWhen(T.when,T.who);

// ── Hub: forced scenes first, then the base screen with the "Your people" strip ──
const _sgBase=baseScreen;
baseScreen=function(){if(!sagaOn())return _sgBase();if(typeof storyInit==='function')storyInit();const g=sagaInit();if(!C.story)return _sgBase();
 const key=C.step+'|'+sagaDone();
 if(g.visit!==key){g.visit=key;let n=0;for(const T of TALKS)if(n<SAGA_FORCE&&T.force&&talkReady(T)&&!g.q.some(e=>e.id===T.id)){g.q.push({k:'talk',id:T.id});n++}saveGame()}
 while(g.q.length){const sc=sagaBuild(g.q[0]);if(sc&&(sc.kind!=='talk'||castOn(sc.who)))return sagaScene(sc,1);g.q.shift()}
 _sgBase();sagaStrip()};
function sagaStrip(){const box=document.querySelector('#modal .base .thead');if(!box||document.querySelector('.saga-strip'))return;const g=C.saga,key=C.step+'|'+sagaDone(),busy=g.talked===key;
 const who=Object.keys(g.id).filter(castOn);if(!who.length)return;
 const ready=k=>TALKS.find(T=>T.who===k&&!T.force&&talkReady(T));
 box.insertAdjacentHTML('beforeend',`<div class="saga-strip"><div class="saga-h"><b>Your people</b><span>${busy?'No more time to talk before the next mission.':who.some(ready)?'Time for one conversation before the next mission.':'Nobody needs you right now.'}</span></div>
 <div class="saga-row">${who.map(k=>{const r=castR(k),T=ready(k),t=g.t[k]||0;return `<button type="button" class="saga-chip${T?' talk':''}" ${T&&!busy?`data-talk="${T.id}"`:'disabled'} style="--uc:${r.col||'var(--troop)'}" title="${CAST[k].arc}${T?': '+T.t:''}">
  <b>${r.n}</b><small class="tr${t>=2?' hi':t<=-2?' lo':''}">${TRUST.word(t)}</small>${T?`<em>${busy?'wants a word later':'wants a word'}</em>`:''}</button>`}).join('')}</div></div>`)}
document.addEventListener('click',ev=>{const b=ev.target.closest('[data-talk]');if(!b||b.disabled||!sagaOn())return;ev.stopPropagation();
 const g=C.saga,T=TALKS.find(x=>x.id===b.dataset.talk);if(!T||!talkReady(T))return;g.talked=C.step+'|'+sagaDone();saveGame();sagaScene({...T,kind:'talk'},0)},true);

// ── Personal missions stay on the galaxy list until played ──
const _sgOpts=optionsFor;
optionsFor=function(step){const o=_sgOpts(step);if(!sagaOn()||!C.saga)return o;
 for(const id of C.saga.pm)if(CRISES[id]&&!o.some(x=>x.crisis===id))o.push({...CRISES[id],crisis:id,adv:0,personal:1});return o};

// ── Approach: picked on the squad screen, paid and applied at launch ──
const apList=o=>[AP_BRIEF,...(APPROACH[o.mission]||(o.story?[]:APPROACH._))];
const apCant=a=>Object.entries(a.cost||{}).some(([k,v])=>k!=='orderDark'&&(C.res[k]||0)<v);
const apCost=a=>Object.entries(a.cost||{}).map(([k,v])=>`${v} ${RES_NAMES[k]||k}`).join(', ');
const _sgSquad=squadScreen;
squadScreen=function(i,keep){_sgSquad(i,keep);if(!sagaOn())return;const g=sagaInit(),o=C.options[i];if(!o)return;const L=apList(o),tag=o.mission+'|'+C.step;
 if(g.apFor!==tag){g.apFor=tag;g.ap=0}if(!L[g.ap]||apCant(L[g.ap]))g.ap=0;
 const end=document.querySelector('#modal .sqbox .endrow');if(!end)return;
 const fin=S_finaleRows(o.mission);
 end.insertAdjacentHTML('beforebegin',`${fin.length?`<div class="saga-fin"><h3>Who stands with you</h3>${fin.map(x=>`<p><b>${x.who}</b> ${x.txt}</p>`).join('')}</div>`:''}
 <div class="saga-ap"><h3>Approach</h3><div class="saga-aps">${L.map((a,j)=>`<button type="button" class="choice${j===g.ap?' on':''}" data-ap="${j}" ${apCant(a)?'disabled':''} aria-pressed="${j===g.ap}"><b>${a.l}</b><span>${a.d}${a.cost?` <i>Cost: ${apCost(a)}</i>`:''}</span></button>`).join('')}</div></div>`);
 document.querySelector('#modal .saga-aps').onclick=ev=>{ev.stopPropagation();const b=ev.target.closest('[data-ap]');if(!b||b.disabled)return;g.ap=+b.dataset.ap;squadScreen(i,1)}};
const _sgLaunch=launchMission;
launchMission=function(i,ids){if(sagaOn()){const g=sagaInit(),o=C.options[i],L=o?apList(o):[AP_BRIEF];let a=L[g.apFor===(o&&o.mission+'|'+C.step)?g.ap:0]||AP_BRIEF;if(apCant(a))a=AP_BRIEF;
  for(const [k,v] of Object.entries(a.cost||{}))gain(k,k==='orderDark'?v:-v);SAGA_NEXT=a.fx?a:null;g.ap=0;g.apFor=null}
 return _sgLaunch(i,ids)};

// Battle effects for an approach or a finale row. Squad = real roster units (no VIPs, no guests).
function sagaBattleFx(f){const P=players().filter(u=>!u.vip&&!u.guest),J=P.filter(u=>u.jedi),bv=k=>{if(S.bv)bvDo(k)};
 for(const [k,v] of Object.entries(f||{})){
  if(k==='aim')for(const u of P)u.aim+=v;else if(k==='jediAim')for(const u of J)u.aim+=v;
  else if(k==='clsAim'){for(const u of P)if(v[u.cls])u.aim+=v[u.cls]}
  else if(k==='mob')for(const u of P)u.mob=Math.max(2,u.mob+v);
  else if(k==='hp')for(const u of P){u.max=Math.max(1,u.max+v);u.hp=Math.max(1,Math.min(u.max,u.hp+v))}
  else if(k==='focus')for(const u of J)u.focus=Math.min(u.maxF||u.focus+v,u.focus+v);
  else if(k==='foeHp'){for(const e of enemies())if(!e.boss){e.max=Math.max(1,e.max+v);e.hp=Math.max(1,Math.min(e.max,e.hp+v))}}
  else if(k==='threat')S.threat=Math.max(0,Math.min(5,S.threat+v));
  else if(k==='ally'){if(typeof bvGuest==='function')bvGuest(v,null,f.allyName?{n:f.allyName}:{})}
  else if(k==='unitAim'){for(const [ck,n] of Object.entries(v)){const u=P.find(u=>u.rid===C.saga.id[ck]);if(u)u.aim+=n}}
  else if(k==='cutFoe')bv({remove:v});else if(['foeAim','foeStun','lock','hurtBoss','strafe'].includes(k))bv({[k]:v})}}
// Finale rows that apply to the era boss mission.
function S_finaleRows(id){const M=MISSIONS[id];if(!M||!M.eraBoss||!sagaOn()||!C.saga)return [];const f=C.flags,done={},o=[];
 for(const F of FINALE){if(done[F.k]||!F.if(f))continue;if(F.fx.unitAim&&!Object.keys(F.fx.unitAim).every(castOn))continue;done[F.k]=1;o.push(F)}return o}
const _sgStart=startMission;
startMission=function(id,sq,o){_sgStart(id,sq,o);if(!S)return;S.saga={fx:[],ap:null,beat:0};if(!sagaOn()){SAGA_NEXT=null;return}
 const a=SAGA_NEXT;SAGA_NEXT=null;if(a){S.saga.ap={l:a.l,win:a.win||null};sagaBattleFx(a.fx);log(`Approach: ${a.l}.`,'good')}
 const fin=S_finaleRows(id);if(fin.length){for(const F of fin){sagaBattleFx(F.fx);log(`${F.who}: “${F.txt}”`,'beat')}
  if(S.bv)S.bv.comm={who:'Who stands with you',txt:fin.map(F=>`${F.who}: ${F.txt}`).join(' ')}}
 render()};

// ── Squad beats: a squad member speaks on turn 2 or 3 (comm box decision) ──
const _sgFire=bvFire;
bvFire=function(ev,c={}){_sgFire(ev,c);if(ev==='turn'&&(c.n===2||c.n===3)&&sagaOn()&&S&&S.saga&&!S.saga.beat&&S.bv&&!S.over)sagaBeat()};
function sagaBeat(){const g=C.saga,inSq=k=>S.units.find(u=>u.side==='p'&&!u.guest&&!u.vip&&u.status==='ok'&&u.rid&&u.rid===g.id[k]);
 const L=SQUAD_BEATS.filter(B=>!g.seen.includes('beat:'+B.id)&&inSq(B.who)&&sagaWhen(B.when,B.who)&&(!B.types||B.types.includes(S.type))&&(!B.foe||enemies().some(e=>FOES[B.foe]&&e.n===FOES[B.foe].n)));
 if(!L.length)return;const B=L.find(B=>B.foe)||pickOne(L),u=inSq(B.who);S.saga.beat=1;g.seen.push('beat:'+B.id);
 log(`${u.n}: “${B.txt}”`,'beat');S.bv.q.push({who:u.n,txt:B.txt,a:B.a,b:B.b,c:{unit:u.uid},saga:B.who});render()}
const _sgPick=bvPick;
bvPick=function(i){const q=S&&S.bv&&S.bv.q[0];_sgPick(i);if(q&&q.saga&&S.saga){const o=i?q.b:q.a;S.saga.fx.push({k:q.saga,fx:o.saga||{}})}};

// ── After the mission: beat effects, approach reward, deaths → grief, aftermath scene ──
const _sgApply=applyResults;
applyResults=function(win){const out=_sgApply(win);if(!sagaOn()||!S||!out)return out;const g=sagaInit(),lines=[],id=S.id;
 for(const x of (S.saga&&S.saga.fx)||[])lines.push(...sagaFx(x.fx,x.k).lines);
 if(win&&S.saga&&S.saga.ap&&S.saga.ap.win)lines.push(...applyFx(S.saga.ap.win));
 if(g.pm.includes(id)){g.pm=g.pm.filter(x=>x!==id);g.pmDone.push(id)}
 // A fallen cast member: the living one who trusts you most grieves.
 for(const k of Object.keys(g.id)){const r=castR(k);if(!r||r.status!=='dead'||g.gone.includes(k))continue;g.gone.push(k);
  const by=Object.keys(g.id).filter(x=>x!==k&&castOn(x)).sort((a,b)=>(g.t[b]||0)-(g.t[a]||0))[0];if(by)g.q.push({k:'grief',dead:k,who:by})}
 // Aftermath: story missions always, won crises half the time (each variant once per era).
 const ak=AFTER[id+':'+(win?'win':'lose')]?id+':'+(win?'win':'lose'):win&&!S.M.story&&AFTER[S.type+':a']&&!g.seen.includes('after:'+S.type+':a')&&rnd(50)?S.type+':a':null;
 if(ak){g.q.push({k:'after',id:ak,n:sagaDone(),mn:S.M.n});if(!ak.includes(':win')&&!ak.includes(':lose'))g.seen.push('after:'+ak)}
 if(lines.length)out.prog=(out.prog||[]).concat(lines);
 if(g.q.length)out.prog=(out.prog||[]).concat(['Back at the Temple, a decision is waiting.']);
 saveGame();return out};

// ── Trust in battle: ≥2 → +5 aim, ≤−2 → −5 aim ──
const _sgUnit=battleUnit;
battleUnit=function(r){const u=_sgUnit(r);if(r&&r.id&&sagaOn()&&C.saga){const k=castKey(r.id),t=k?C.saga.t[k]||0:0;if(t>=2){u.aim+=TRUST.aim;u.trust=t}else if(t<=-2){u.aim-=TRUST.aim;u.trust=t}}return u};

// ── Era-end lines for the cast, ahead of story.js EPILOGUE ──
EPILOGUE.unshift([r=>!!(C&&C.saga&&castKey(r.id)&&SAGA_EPI[castKey(r.id)]&&SAGA_EPI[castKey(r.id)].some(([f])=>f(C.flags,C.saga.t[castKey(r.id)]||0))),
 r=>{const k=castKey(r.id);return SAGA_EPI[k].find(([f])=>f(C.flags,C.saga.t[k]||0))[1]}]);

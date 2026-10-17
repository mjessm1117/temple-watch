/* Story layer, Era 1: vision shard, hub events, Vision meter (shadow 0–10), Years pass, Malgus assault, era end, Archive of Legends.
   Data: data-story.js. Load after base.js, before screens.js. It hooks in by wrapping these globals (nothing else needs to call it):
   baseScreen (temple-ui.js), endScreen, applyResults, addRecruit (base.js / campaign.js / temple.js) and startMission, checkEnd, threatStep (turns.js). */
const ARCH_KEY='templewatch-archive';

function storyInit(){if(!C)return;let s=C.story;
 if(!s){s=C.story={shadow:SHADOW.start,seen:[],q:[],visit:'',done:0,bby:ERA1.bby,shard:0,loyal:{},teach:{},yrs:null,eraDone:0};
  for(const k in COUNCIL_SEATS)s.loyal[k]=COUNCIL_SEATS[k].loyalty;
  for(const r of C.roster)if(YEARS.ages[r.n])r.age=YEARS.ages[r.n]}
 for(const r of C.roster)if(r.age==null)r.age=startAge(r)}
function startAge(r){const R=!isJedi(r)?YEARS.range.troop:r.title==='Knight'||r.rank>=3?YEARS.range.Knight:YEARS.range.Padawan;return ri(R[0],R[1])}
const shadowAdd=n=>{const s=C.story;s.shadow=Math.max(0,Math.min(10,s.shadow+n))};
const bbyTxt=n=>`~${n.toLocaleString('en-US')} BBY`;
const sgn=n=>(n>0?'+':'')+n;

// ── Events ──
const actNow=()=>1+PLAN.slice(0,C.step).filter(p=>p.years).length;
function trig(t){const s=C.story;
 if(t.type==='era_start')return true;
 if(t.type==='act')return actNow()>=(t.min||1);
 if(t.type==='all')return t.all.every(trig);
 if(t.type==='notFlag')return !C.flags[t.flag];
 if(t.type==='month')return C.month>=(t.min||1);
 if(t.type==='after_mission')return s.done>=(t.min||1);
 if(t.type==='flag')return !!C.flags[t.flag];
 if(t.type==='stat'){const v=C.res[t.key]||0;return t.op==='>='?v>=t.val:t.op==='<='?v<=t.val:v===t.val}
 return false}
function whoUnit(w){const A=C.roster.filter(r=>r.status==='active'),J=A.filter(isJedi);
 if(w==='jedi_random')return J.length?pickOne(J):null;
 if(w==='jedi_highestDark')return J.sort((a,b)=>b.dark-a.dark)[0]||null;
 return A.sort((a,b)=>b.rank-a.rank)[0]||null}
// Apply an event choice. Returns short result lines for the hub news.
function applyFx(f){const s=C.story,out=[];
 if(f.chance!=null&&!rnd(f.chance*100))return applyFx(f.fail||{});
 for(const [k,v] of Object.entries(f)){
  if(k==='chance'||k==='fail')continue;
  if(RES_NAMES[k]){gain(k,v);out.push(`${sgn(v)} ${RES_NAMES[k]}`)}
  else if(k==='shadow'){shadowAdd(v);out.push(v<0?'The vision dims':'The vision sharpens')}
  else if(k==='flag')C.flags[v]=1;
  else if(k.startsWith('loyalty')){s.loyal[v.seat]=Math.max(0,Math.min(100,(s.loyal[v.seat]??60)+v.n));out.push(`${COUNCIL_SEATS[v.seat].n} ${v.n>0?'approves':'disapproves'}`)}
  else if(k==='unitDark'){const r=whoUnit(v.who);if(r){r.dark=Math.max(0,r.dark+v.n);out.push(`${r.n}: Darkness ${sgn(v.n)}`)}}
  else if(k==='wound'){const r=whoUnit(v.who);if(r){r.wound=Math.max(r.wound,v.turns*DAYS);out.push(`${r.n} is hurt: out ${r.wound} days`)}}
  else if(k==='recruit'){const d=STORY_RECRUITS[v];
   if(d&&!C.roster.some(r=>r.n===d.n)&&rosterCount()<rosterCap()){
    C.roster.push({id:'u'+C.nid++,xp:0,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0,...d,picks:[...(d.picks||[])]});out.push(`${d.n} joins your strike teams`)}
   else out.push('No room in the barracks')}
  else if(k==='mission'){const c=CRISES[v];if(c){C.options.push({...c,crisis:v,adv:0});out.push(`New mission: ${c.n}`)}}}
 return out}

// ── Hub hook: shard scene and at most one event per visit, before the base screen ──
const _baseScreen=baseScreen;
baseScreen=function(){if(!C)return _baseScreen();storyInit();const s=C.story,P=PLAN[C.step];
 if(P&&P.years)return yearsScreen();
 const key=C.step+'|'+s.done;
 if(s.visit!==key){s.visit=key;
  if((s.shard||0)<actNow()){s.shard=actNow();s.q.push('shard')}
  const e=EVENTS.find(e=>!s.seen.includes(e.id)&&!s.q.includes(e.id)&&trig(e.trigger));if(e)s.q.push(e.id);
  if(s.q.length)saveGame()}
 if(s.q.length)return sceneScreen();
 _baseScreen();storyHud()};
function storyHud(){const s=C.story,bar=document.querySelector('#modal .resbar');
 if(bar&&!bar.querySelector('#memBtn')){bar.insertAdjacentHTML('beforeend','<button type="button" class="vis" id="memBtn" title="The names of the fallen and the retired, across every campaign on this device.">Archive of Legends</button>');
  bar.querySelector('#memBtn').onclick=ev=>{ev.stopPropagation();memorialScreen(baseScreen)}}
 if(bar&&!bar.querySelector('.vis:not(#memBtn)'))bar.insertAdjacentHTML('beforeend',`<span class="vis" title="The Vision: how surely the Council's vision of the burning Temple is coming true. Lower is better. ${s.shadow}/10">Vision <b>${SHADOW.word(s.shadow)}</b></span>`);
 const eb=document.querySelector('#modal .base .eyebrow');if(eb)eb.textContent=eb.textContent.replace(/~[\d,]+ BBY/,bbyTxt(s.bby))}
function sceneScreen(){SCR=sceneScreen;const s=C.story,id=s.q[0],m=$('#modal');m.hidden=false;
 const done=lines=>{s.q.shift();if(lines&&lines.length)C.news.push(lines.join(' · ')+'.');saveGame();baseScreen()};
 if(id==='shard'){const a=actNow();m.innerHTML=`<div class="box"><div class="eyebrow">Jedi Council · Act ${a} · ${bbyTxt(s.bby)}</div><h2>${ERA1.shard.t}</h2><p>${a>1&&SHARDS[a]||ERA1.shard.text}</p>
  ${(loreSee(['zym','gnost','darach','coruscant']),'')}<p class="muted">The Vision meter shows how surely it is coming true. It starts <b>${SHADOW.word(s.shadow)}</b>. Win the fights that matter to dim it.</p>
  <button type="button" class="primary" id="scOk">Continue</button></div>`;m.onclick=null;$('#scOk').onclick=()=>done();return}
 const e=EVENTS.find(e=>e.id===id);if(!e){s.q.shift();return baseScreen()}loreSee(EVENT_LORE[e.id]);
 const cant=c=>Object.entries(c.effects).some(([k,v])=>RES_NAMES[k]&&k!=='orderDark'&&k!=='favor'&&v<0&&(C.res[k]||0)+v<0);
 m.innerHTML=`<div class="box"><div class="eyebrow">Council matter · Month ${C.month}</div><h2>A choice</h2><p>${e.text}</p>
  ${e.choices.map((c,i)=>`<button type="button" class="choice" data-ch="${i}" ${cant(c)?'disabled':''}><b>${c.label}</b><span>${choiceText(c.effects)}</span></button>`).join('')}</div>`;
 m.onclick=ev=>{const b=ev.target.closest('[data-ch]');if(!b||b.disabled)return;const c=e.choices[+b.dataset.ch];s.seen.push(e.id);done([c.label,...applyFx(c.effects)])}}
// Preview of a choice's effects, in plain words.
function choiceText(f){const o=[];for(const [k,v] of Object.entries(f)){
 if(RES_NAMES[k])o.push(`${sgn(v)} ${RES_NAMES[k]}`);else if(k==='mission')o.push(`Unlocks a mission: ${CRISES[v].n}`);
 else if(k.startsWith('loyalty'))o.push(`${COUNCIL_SEATS[v.seat].n} ${v.n>0?'approves':'disapproves'}`);
 else if(k==='unitDark')o.push(`A Jedi gains Darkness ${sgn(v.n)}`);else if(k==='recruit')o.push(`${STORY_RECRUITS[v].n} joins`);
 else if(k==='shadow')o.push(v<0?'Dims the vision':'Sharpens the vision');else if(k==='chance')o.push(`${Math.round(v*100)}% it goes well`);
 else if(k==='flag'&&FLAG_LINES[v])o.push('History remembers')}
 return o.join(' · ')||'Nothing changes'}

// ── Years pass (+5 years): aging, Trials, retirement ──
function yearsJump(){const s=C.story,y={rows:[],ret:[]},J5=PLAN[C.step].years>1?PLAN[C.step].years:YEARS.jump;s.bby-=J5;
 for(const r of C.roster){
  if(r.status==='captured'){r.status='dead';C.legends.push({n:r.n,cls:r.cls,how:'Never came back from captivity'});archive(r,'Never came back from captivity');y.rows.push([r.n,'Lost in captivity']);continue}
  if(r.status!=='active')continue;const J=isJedi(r),notes=[];r.age+=J5;r.wound=0;
  if(J&&r.title==='Padawan'&&r.rank>=2){if(r.dark>=YEARS.trialsFail.dark&&rnd(YEARS.trialsFail.chance))notes.push('fails the Trials, stays a Padawan');else{r.title='Knight';notes.push('<b class="up">passes the Trials: Knight</b>')}}
  const p=YEARS.retire(r,J);if(p&&rnd(p)){r.status='retired';y.ret.push({id:r.id,role:null});notes.push(`<b>retires</b> (${p}% at this age)`)}
  y.rows.push([r.n,`Age ${r.age}${notes.length?' · '+notes.join(' · '):''}`])}
 gain('recruits',YEARS.recruits);return y}
function yearsScreen(){SCR=yearsScreen;const s=C.story,m=$('#modal');m.hidden=false;
 if(!s.yrs){s.yrs=yearsJump();saveGame()}const y=s.yrs,built=Object.keys(C.wings).filter(k=>C.wings[k]>0);
 const roleBtns=x=>{const r=C.roster.find(r=>r.id===x.id);return `<div class="rrow"><div class="rmain"><b>${r.n}</b><small>${r.cls} · Rank ${r.rank} · age ${r.age}</small>
  ${x.role?`<p class="ready">${x.role}</p>`:`<div class="picks">${built.map(k=>`<button type="button" data-role="${x.id}:staff:${k}">Staff ${WINGS[k].n}</button>`).join('')}
  <button type="button" data-role="${x.id}:teach">${YEARS.roles.teach}</button><button type="button" data-role="${x.id}:relic">${YEARS.roles.relic}</button></div>`}</div></div>`};
 const P=PLAN[C.step],A=ACTS[P.act]||ACTS[2];
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Act ${P.act||2} · ${bbyTxt(s.bby)}</div><h2>${A.t}</h2>
 <p>${A.text}</p>
 <div class="sum">${y.rows.map(([n,t])=>`<div><span>${n}</span><span>${t}</span></div>`).join('')}<div><span>New recruits</span><span>+${YEARS.recruits}</span></div></div>
 ${y.ret.length?`<h3>Retirees · choose what each one does</h3>${y.ret.map(roleBtns).join('')}`:''}
 <button type="button" class="primary" id="yrOk" ${y.ret.some(x=>!x.role)?'disabled':''}>Back to the Temple</button></div>`;
 m.onclick=ev=>{const b=ev.target.closest('[data-role]');if(!b)return;const [id,role,wing]=b.dataset.role.split(':'),x=y.ret.find(x=>x.id===id),r=C.roster.find(r=>r.id===id);
  if(role==='staff'){const old=C.staff[wing]&&unit(C.staff[wing]);if(old&&old.status==='active')old.assign=null;C.staff[wing]=r.id;r.assign='staff:'+wing;x.role=`Staffs the ${WINGS[wing].n}`}
  else if(role==='teach'){s.teach[r.cls]=r.n;x.role=`Teaches the next ${r.cls} recruit`}
  else{x.role='Leaves a relic to the Archive';r.relic=1}
  r.role=x.role;if(r.rank>=2)archive(r,`Retired at ${r.age}. ${x.role}.`);saveGame();yearsScreen()};
 $('#yrOk').onclick=ev=>{ev.stopPropagation();s.yrs=null;C.step++;C.options=optionsFor(C.step);C.news=[`Years have passed. It is now ${bbyTxt(s.bby)}.`];saveGame();baseScreen()}}

// A retired teacher's next recruit of that class starts at rank 2 (spec B §1.5).
const _addRecruit=addRecruit;
addRecruit=function(c,name,col){_addRecruit(c,name,col);const s=C.story,r=C.roster[C.roster.length-1],t=s&&s.teach[r.cls];
 if(t&&r.rank<2){r.rank=2;r.xp=RANKS[1].xp;r.title=isJedi(r)?r.title:RANK_TITLE[2];delete s.teach[r.cls];C.news.push(`${r.n} was taught by ${t}: starts at Rank 2.`)}};

// ── Malgus assault (mission type 'assault'): win = boss dead; Threat 6 = he reaches the Temple lifts ──
const _startMission=startMission;
startMission=function(id,sq,o){_startMission(id,sq,o);if(!S.M.eraBoss||!C)return;const f=C.flags;
 if(f.e1_ambush_ready){const b=S.units.find(u=>u.boss);if(b){b.hp=Math.max(1,b.hp-3);log(STORY_TEXT.ambush,'good')}}
 if(f.e1_adraas_down){const i=S.units.findIndex(u=>u.side!=='p'&&!u.boss&&/Trooper/.test(u.n));if(i>=0){S.units.splice(i,1);log(STORY_TEXT.adraas,'good')}}
 if(f.e1_docks_guarded){S.noReinf=1;log(STORY_TEXT.guards,'good')}render()};
// Assault win/Threat rules now live in turns.js (Chat X).

// ── Results hook: Archive entries for the fallen, boss outcome ──
const _applyResults=applyResults;
applyResults=function(win){storyInit();const s=C.story,n0=C.legends.length,M=S.M,beatPar=win&&M.boss&&S.turn<=M.par;
 const out=_applyResults(win);s.done++;const id=Object.keys(MISSIONS).find(k=>MISSIONS[k]===M||MISSIONS[k].n===M.n);
 if(win&&M.winFlag)C.flags[M.winFlag]=1;if(!win&&M.loseFlag)C.flags[M.loseFlag]=1;
 if(win&&M.winRecruit){const l=applyFx({recruit:M.winRecruit});if(l.length)C.news.push(l.join(' · ')+'.')}
 for(const L of C.legends.slice(n0)){const r=C.roster.find(r=>r.n===L.n)||L;archive(r,L.how,L.where)}
 if(M.eraBoss){if(win){C.flags.boss_or_won=1;shadowAdd(-1);gain('favor',10,out.res);if(beatPar){for(const [k,v] of Object.entries(M.bonus))gain(k,v,out.res);out.bonus=M.bonusTxt}out.flag=STORY_TEXT.bossWin}
  else{C.flags.temple_scarred=1;shadowAdd(1);gain('favor',-10,out.res);const w=Object.keys(C.wings).filter(k=>C.wings[k]>0).sort((a,b)=>C.wings[b]-C.wings[a])[0];if(w)C.wings[w]--;out.flag=STORY_TEXT.bossLose}}
 const v=(DEBRIEF_IF[id]||[]).find(x=>C.flags[x[0]]&&x[win?1:2]),e=v?v[win?1:2]:EPI[id]&&EPI[id][win?'win':'lose'];if(e)out.flag=(out.flag?out.flag+' ':'')+e;
 saveGame();return out};

// ── Archive of Legends: shared across campaigns on this device, newest first, cap 30 ──
function archiveLoad(){try{return JSON.parse(localStorage.getItem(ARCH_KEY)||'[]')}catch(e){return[]}}
function archive(r,how,where){const a=archiveLoad(),bby=C&&C.story?C.story.bby:ERA1.bby;
 a.unshift({n:r.n,cls:r.cls,rank:r.rank||1,era:ERA1.n,bby,how,where:where||'',kills:r.kills||0,
  ep:`${r.n}, ${r.cls}${r.rank>1?', rank '+r.rank:''}. ${how}${where?' at '+where:''}, ${bbyTxt(bby)}.`});
 try{localStorage.setItem(ARCH_KEY,JSON.stringify(a.slice(0,30)))}catch(e){}}

// ── Era end (replaces the slice-end screen once the plan is done) ──
const _endScreen=endScreen;
endScreen=function(){if(!C||!C.story)return _endScreen();SCR=endScreen;const s=C.story,m=$('#modal'),od=odark();
 if(!s.eraDone){s.eraDone=1;if(od>=60)shadowAdd(1);saveGame()}
 const won=!!C.flags.boss_or_won,ret=C.roster.filter(r=>r.status==='retired'),hist=Object.keys(FLAG_LINES).filter(k=>C.flags[k]).map(k=>`<p>${FLAG_LINES[k]}</p>`).join('');
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Era 1 ends · ${ERA1.n} · ${bbyTxt(s.bby)}</div><h2>The Cold Treaty</h2>
 <p>${won?STORY_TEXT.eraWin:STORY_TEXT.eraLose}</p>${od>=60?`<p class="dkt">${STORY_TEXT.darkWarn}</p>`:''}
 <div class="sum"><div><span>The Vision</span><span>${SHADOW.word(s.shadow)} · ${s.shadow}/10</span></div><div><span>Order Darkness</span><span>${od}/100</span></div>
 <div><span>Senate Favor</span><span>${C.res.favor}</span></div><div><span>Still serving</span><span>${C.roster.filter(r=>r.status==='active').map(r=>r.n).join(', ')||'none'}</span></div>
 <div><span>Retired</span><span>${ret.map(r=>`${r.n} (${(r.role||'').toLowerCase()})`).join(', ')||'none'}</span></div>
 <div><span>Fallen</span><span>${C.legends.map(l=>l.n).join(', ')||'none'}</span></div><div><span>Archive of Legends</span><span>${archiveLoad().length} names</span></div></div>
 <h3>Where they went</h3><div class="news">${C.roster.filter(r=>r.status==='active'||r.status==='retired').map(epiCard).join('')||'<p>No one is left to remember it.</p>'}</div>
 ${hist?`<h3>What history changed</h3><div class="news">${hist}</div>`:''}
 <p class="muted">Centuries pass. Your heroes become Legends. To be continued: ${ERA1.next}.</p>
 ${typeof startEra==='function'?'<button type="button" class="primary" id="nextEra">Continue to the next era</button>':''}
 <button type="button" id="memorial">Archive of Legends</button>
 <button type="button" class="${typeof startEra==='function'?'':'primary'}" id="restart">New campaign</button></div>`;
 m.onclick=null;$('#restart').onclick=()=>{C=null;briefing(true)};$('#memorial').onclick=()=>memorialScreen(endScreen);const nx=$('#nextEra');if(nx)nx.onclick=()=>startEra(2)};

// ── Wave 3 follow-up: Codex reveals, barks, epilogue cards, memorial ──
// Codex: planets and characters count as met when a mission or event shows them.
function loreSee(ids){if(!ids||typeof codexSee!=='function'||typeof CODEX==='undefined')return;
 for(const x of ids.flat())codexSee(CODEX.planet&&CODEX.planet[x]?'planet':'character',x)}
const _startMissionL=startMission;
startMission=function(id,sq,o){_startMissionL(id,sq,o);const L=MISSION_LORE[id];if(L)loreSee([L[0],...(L[1]||[])]);
 if(S)for(const u of S.units)if(u.side==='p'&&CODEX.character)for(const [k,v] of Object.entries({kira:'Kira Venn',tor:'Tor Saalen',dax:'Sgt. Rhal Dax',ilsa:'Ilsa Myr',bren:'Doc Bren',grak:'Grak Ordo',satele:'Satele Shan',jace:'Jace Malcom'}))if(u.n===v)loreSee([k])};
// Flag-aware briefs: the mission brief grows one line from the first matching flag (BRIEF_IF).
for(const [id,list] of Object.entries(BRIEF_IF)){const M=MISSIONS[id];if(!M)continue;const base=M.brief;
 Object.defineProperty(M,'brief',{configurable:true,enumerable:true,get(){const f=typeof C!=='undefined'&&C?C.flags:{},x=list.find(([k])=>f[k]);return x?base+' '+x[1]:base}})}

// Barks: one line in the log on kill, down, crit and panic. At most one per unit per turn (down and panic always speak).
let barkT={};
function bark(u,ev){if(!u||u.side!=='p'||u.vip||!S||S.over)return;const k=u.rid+'|'+S.turn;
 if(ev!=='down'&&ev!=='panic'&&(barkT[k]||!rnd(60)))return;
 const r=C&&C.roster.find(r=>r.id===u.rid),dflt=u.jedi?BARKS.jedi:BARKS.troop,set=HERO_BARKS[u.n]||(r&&r.trait&&BARKS[r.trait])||dflt,L=set[ev]||dflt[ev];
 if(!L)return;barkT[k]=1;const txt=pickOne(L);log(`${u.n}: “${txt}”`,'bark');fx('bark',{u,txt,ev})}
const _logL=log;log=function(t,c){if(S&&typeof t==='string'&&/critical hit/i.test(t))S._crit=1;return _logL(t,c)};
onFx((type,d)=>{if(!S)return;if(type==='hit'){if(S._crit){S._crit=0;bark(d.src,'crit')}}else if(type==='kill')bark(d.src,'kill');else if(type==='down')bark(d.t,'down')});
const _panicL=panicCheck;panicCheck=function(u,...a){const was=u&&u.panic,r=_panicL(u,...a);if(u&&!was&&u.panic)bark(u,'panic');return r};

// Era-end card per surviving or retired unit.
function epiCard(r){const rule=EPILOGUE.find(([t])=>t(r));
 return `<p><b>${r.n}</b> · ${r.cls}${isJedi(r)&&r.title?' '+r.title:''} · Rank ${r.rank||1}${r.age?' · age '+r.age:''} · ${r.missions||0} missions, ${r.kills||0} foes<br>${rule[1](r)}</p>`}

// Archive of Legends memorial: every name on this device, newest first. `back` = screen to return to.
function memorialScreen(back){SCR=()=>memorialScreen(back);const m=$('#modal'),a=archiveLoad();m.hidden=false;
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Jedi Temple · Hall of Remembrance</div><h2>Archive of Legends</h2>
 <p class="muted">A candle for every name. The Archive keeps them across campaigns, so the next Order remembers what this one paid.</p>
 ${a.length?`<div class="news">${a.map(e=>`<p><b>${e.n}</b> · ${e.cls}${e.rank>1?' · rank '+e.rank:''} · ${e.era||ERA1.n}, ${bbyTxt(e.bby)}<br>${e.how}${e.where?' at '+e.where:''}${e.kills?` · ${e.kills} foes`:''}</p>`).join('')}</div>`
  :'<p>No names yet. May it stay that way.</p>'}
 <button type="button" class="primary" id="memBack">Back</button></div>`;
 m.onclick=null;$('#memBack').onclick=()=>back()}

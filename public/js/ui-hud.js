/* Battle HUD extras + Temple calendar (Chat U): objectives, contacts (enemy pods), log filter, area odds,
   first-mission tips, Temple calendar strip, era label. render() calls hudRender(). */
// --- Era label: reads C.era (Era 2 = Ruusan). Story chats can add ERA3… later; label follows. ---
function eraLabel(){const e=typeof C!=='undefined'&&C&&C.era||1,E=uiGv('ERA'+e)||uiGv('ERA1')||{n:'Old Republic',bby:3660};
 const by=typeof C!=='undefined'&&C&&C.story&&C.story.bby||E.bby;return `${E.n} · ~${Number(by).toLocaleString('en-US')} BBY`}
// --- Area abilities: who the 3×3 hits, their %, damage, kill. ab.areaChance(u,t) can override the default (areas auto-hit). ---
const hurtsAllies=ab=>ab.friendly!=null?!!ab.friendly:/allies too|everyone|friend/i.test((ab.desc||'')+' '+(ab.tip||''));
function areaHits(u,k,g){const ab=AB[k];if(!ab||!u||!g)return [];if(ab.ally&&!ab.dm)return [];const ff=hurtsAllies(ab),dm=ab.dm?ab.dm(u):null;
 return S.units.filter(t=>alive(t)&&!t.hid&&t.status!=='captured'&&cheb(t,g)<=1&&(t.side==='e'||ff)).map(t=>{
  const ally=t.side==='p',ch=ab.areaChance?ab.areaChance(u,t):100,d=dm&&[Math.max(1,dm[0]-(t.armor?1:0)),Math.max(1,dm[1]-(t.armor?1:0))];
  return {t,ally,chance:Math.round(ch),dm:d,kill:d&&t.status==='ok'?(d[0]>=t.hp?'kills':d[1]>=t.hp?'may kill':''):''}}).sort((a,b)=>a.ally-b.ally)}
// --- Objectives panel ---
const OBJ_TXT={defend:M=>`Hold the ${M.objName||'objective'} until the end of turn ${M.turns}.`,rescue:()=>'Free the prisoner and get them to an evac zone.',
 escort:()=>'Get the VIP to an evac zone alive.',sabotage:M=>`Arm ${M.need} charges, then get everyone to evac.`,
 investigate:()=>'Copy data from the terminals (computer screens): 2 clues to win, 3 for the bonus. Then get everyone to the evac circles.',assault:()=>'Take down the target.'};
// "Do this next" line: the one concrete step and the button to press, from live mission state.
function objNext(){const M=S.M,h=typeof hostage==='function'?hostage():null,P=players().filter(alive);
 if(S.type==='investigate'){if(S.clues<2){const q=tilesWhere(c=>c==='q').length;return q?`Walk any unit onto a tile touching a data terminal (diagonals count). A <b>Scan clue</b> button appears: press it, then click the terminal. ${2-S.clues} more to go.`:'No terminals left.'}
  return `Data secured${S.clues<3?' (one more terminal = bonus)':''}. Move everyone onto the evac circles.`}
 if(S.type==='rescue'&&h){if(h.bound)return 'Open the cell: stand next to a console and press <b>Use console</b>, or use <b>Hack</b> within 4 tiles.';return `Walk ${h.n} to an evac circle. Keep them out of enemy fire.`}
 if(S.type==='escort'&&h)return `Walk ${h.n} to an evac circle. Your squad clears the way.`;
 if(S.type==='sabotage'){const a=armed();return a<M.need?`Stand next to a charge site and press <b>Plant charge</b>. ${M.need-a} more to arm.`:'Charges armed. Move everyone onto the evac circles.'}
 if(S.type==='defend')return `Keep enemies off the ${M.objName||'objective'}. Survive to the end of turn ${M.turns}.`;
 if(S.type==='assault')return 'Focus fire on the target. Everyone else is a distraction.';
 return ''}
function objHTML(){const M=S.M,o=objStat(),rows=[];
 rows.push(`<p class="obj1">${(OBJ_TXT[S.type]||(()=>M.brief||''))(M)}</p>`);
 rows.push(`<div class="orow"><span>${o.label}</span><b>${o.val}</b></div>`);
 {const n=objNext();if(n)rows.push(`<p class="onext"><b>Next:</b> ${n}</p>`)}
 if(S.type==='defend')rows.push(`<div class="orow"><span>Turn</span><b>${S.turn} / ${M.turns}</b></div>`);
 const nw=M.waves&&Object.keys(M.waves).map(Number).find(t=>t>S.turn);if(M.waves)rows.push(`<div class="orow"><span>Next wave</span><b>${nw?'turn '+nw:'none left'}</b></div>`);
 if(M.par)rows.push(`<div class="orow${S.threat>=4?' hot':''}"><span data-tip="stat:threat">Threat</span><b>${S.threat?`${S.threat} / 6 · fails at 6`:`rises after turn ${M.par}`}</b></div>`);
 if(M.bonusTxt){const ok=missionBonus();rows.push(`<div class="orow ${ok?'ok':''}"><span>Bonus</span><b>${ok?'✓ ':'○ '}${M.bonusTxt}</b></div>`)}
 if(S.conc)rows.push(`<p class="ocall" data-tip="status:concealed">Concealed: stay out of red tiles. Your first attack is an ambush (+20 aim).</p>`);
 for(const u of players().filter(u=>u.status==='down'&&!u.stable))rows.push(`<p class="ocall bad">${u.n} bleeds out in ${u.bleed} turn${u.bleed>1?'s':''}.</p>`);
 return rows.join('')}
// --- Contacts: every visible enemy, grouped by pod on stealth missions; click to inspect ---
function podState(e){if(e.status!=='ok')return({stunned:'stunned',surrender:'surrendered',down:'down'})[e.status]||e.status;
 if(typeof asleep==='function'&&asleep(e))return S.M.patrol&&S.M.patrol[e.pod]?'patrolling':'on guard';
 return e.panic?'panicked':e.disarmed?'disarmed':e.ow?'overwatch':'alert'}
function podsHTML(){const E=enemies().filter(e=>!e.hid);$('#podN').textContent=E.length?`(${E.length})`:'';if(!E.length)return '<p class="muted small">No contacts in sight.</p>';
 const G={};for(const e of E){const k=S.M.stealth&&e.pod!=null?e.pod:'all';(G[k]=G[k]||[]).push(e)}
 return Object.entries(G).map(([k,L],i)=>`${Object.keys(G).length>1?`<div class="podh">Pod ${i+1}${typeof asleep==='function'&&asleep(L[0])?' · unaware':''}</div>`:''}${L.map(e=>
  `<button type="button" class="podr ${e===S.peek?'on':''}" data-peek="${e.uid}" data-tip="enemy:${e.type}">${icon(unitIcon(e))}<span>${e.n}</span>${pips(e.max,e.hp)}<small>${podState(e)}</small></button>`).join('')}`).join('')}
// --- Log filter ---
let LOGF='all';const LOGF_OPTS=[['all','All'],['good','Good'],['bad','Threats'],['dark','Dark side']];
function logHTML(){const L=LOGF==='all'?S.log.slice(0,14):S.log.filter(l=>l.cls===LOGF);return L.map(l=>`<p class="${l.cls}">${l.t}</p>`).join('')||'<p class="muted">Nothing yet.</p>'}
function hudRender(){$('#objs').innerHTML=objHTML();$('#pods').innerHTML=podsHTML();
 $('#logF').innerHTML=LOGF_OPTS.map(([k,n])=>`<button type="button" data-lf="${k}" class="${LOGF===k?'on':''}">${n}</button>`).join('');$('#log').innerHTML=logHTML();
 tipCheck()}
$('#pods').addEventListener('click',ev=>{const b=ev.target.closest('[data-peek]');if(!b||!S)return;const e=byId(+b.dataset.peek);if(!e)return;S.peek=S.peek===e?null:e;S.mode='move';S.tg=[];S.pick=null;render()});
$('#logF').addEventListener('click',ev=>{const b=ev.target.closest('[data-lf]');if(b&&S){LOGF=b.dataset.lf;hudRender()}});
// Remember which side panels are folded.
for(const id of ['objP','podP']){const d=$('#'+id);try{const v=localStorage.getItem('tw.fold.'+id);if(v!=null)d.open=v==='1'}catch{}
 d.addEventListener('toggle',()=>{try{localStorage.setItem('tw.fold.'+id,d.open?'1':'0')}catch{}})}
// --- First-mission tips: one at a time, each shown once; "Skip tips" turns them all off (Settings turns them back on) ---
const TIP_KEY='tw.tips';let TIPS_ST=(()=>{try{return JSON.parse(localStorage.getItem(TIP_KEY))||{seen:{}}}catch{return {seen:{}}}})(),tipNow=null;
const TIPS=[
 ['move',()=>S.mode==='move'&&canAct(S.sel)&&!S.peek,'Move: click a lit tile. Blue costs 1 action; gold is a dash and uses both. Each unit gets 2 actions a turn.'],
 ['conc',()=>S.conc,'You start concealed. Red tiles are what the enemy can see: step in and the squad is revealed. Your first attack is an ambush (+20 aim).'],
 ['cover',()=>players().some(u=>u.ap===1),'Cover matters. Shields mark it: solid = full cover (−40 to hit you), outline = half (−20). Finish moves next to cover.'],
 ['aim',()=>S.mode!=='move'&&S.tg.length,'Pick a red-outlined target to see every modifier on the shot, then Confirm. Keyboard: Space aims at the best target, Space again fires.'],
 ['enemy',()=>enemies().some(e=>!e.hid),'Click an enemy (or its row under Contacts) to see its stats and what it plans to do next. Hover anything for details.'],
 ['down',()=>players().some(u=>u.status==='down'),'A downed unit bleeds out. An adjacent ally can Stabilize; a medkit revives.'],
 ['end',()=>S.phase==='player'&&!players().some(canAct),'Everyone has acted. End the turn (End key) and watch the enemy move.']];
function tipsSave(){try{localStorage.setItem(TIP_KEY,JSON.stringify(TIPS_ST))}catch{}}
function tipCheck(){const box=$('#tips');if(TIPS_ST.off||!S||S.over||S.phase!=='player'){box.hidden=true;return}
 if(tipNow&&!TIPS_ST.seen[tipNow])return;tipNow=null;
 const t=TIPS.find(([id,when])=>!TIPS_ST.seen[id]&&(()=>{try{return when()}catch{return false}})());if(!t){box.hidden=true;return}
 tipNow=t[0];box.innerHTML=`<b>Tip</b><p>${t[2]}</p><div class="endrow"><button type="button" data-tipk="skip">Skip tips</button><button type="button" class="primary" data-tipk="ok">Got it</button></div>`;box.hidden=false}
$('#tips').addEventListener('click',ev=>{const b=ev.target.closest('[data-tipk]');if(!b)return;if(b.dataset.tipk==='skip'){TIPS_ST.off=true;SETTINGS.tips=false;saveSettings()}else if(tipNow)TIPS_ST.seen[tipNow]=1;tipNow=null;tipsSave();tipCheck()});
function tipsReset(on){TIPS_ST={seen:on?{}:TIPS_ST.seen,off:!on};tipsSave();if(typeof S!=='undefined'&&S)tipCheck()}
// --- Temple calendar strip: what lands after each of the next 4 missions (15 days each) ---
function calHTML(){const st=DAYS,slots=[[],[],[],[]],put=(n,txt,cls='')=>{if(n>=1&&n<=4)slots[n-1].push(`<span class="${cls}">${txt}</span>`)};
 const mEnd=Math.ceil((31-C.day)/st);put(mEnd,`Month ${C.month+1}: stipend, pay, new Sith ops`,'mo');
 if(C.build&&WINGS[C.build])put(1,`${WINGS[C.build].n} upgrade ready`,'up');
 const R=C.research,RS=uiGv('RESEARCH');if(R&&R.cur&&RS&&RS[R.cur]&&C.wings.archives){const rate=st*(C.wings.archives>=2?1.5:1)*(C.staff&&C.staff.archives?1.25:1);put(Math.max(1,Math.ceil((RS[R.cur].days-R.prog)/rate)),`Research: ${RS[R.cur].n}`,'up')}
 for(const r of C.roster)if(r.status==='active'&&r.wound>0)put(Math.ceil(r.wound/st),`${shortName(r)} fit again`,'ok');
 const OPS=uiGv('SITH_OPS');if(C.ops&&OPS){for(const m of C.ops.mods||[])if(OPS[m.k])put(m.left,`${OPS[m.k].n} wears off`,'ok');
  for(const o of C.ops.list||[])if(o.st==='open'&&OPS[o.k])put(mEnd,`${OPS[o.k].n} hits unless countered`,'bad')}
 return `<div class="calstrip" aria-label="Calendar"><div class="calnow"><b>Coming up</b><small>${eraLabel()}</small></div>${slots.map((L,i)=>
  `<div class="calslot"><small>After mission ${i===0?'(next)':i+1} · +${st*(i+1)} days</small>${L.join('')||'<span class="muted">—</span>'}</div>`).join('')}</div>`}
new MutationObserver(()=>{try{const b=document.querySelector('#modal .base');if(!b||b.querySelector('.calstrip')||typeof C==='undefined'||!C)return;
 const rb=b.querySelector('.resbar');(rb||b.firstElementChild).insertAdjacentHTML(rb?'afterend':'beforebegin',calHTML());$('#where').textContent='Jedi Temple · '+eraLabel()}catch(e){}})
 .observe(document.getElementById('modal'),{childList:true,subtree:true});

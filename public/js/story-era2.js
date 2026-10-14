/* Era 2: Ruusan. Era jump (spec B §1.4), time-skip scene, Era 2 plan, Ruusan foe mechanics, Kaan/Bane outcomes, era-end stub.
   Data: data-era2.js. Load after story.js, before screens.js. Like story.js, it hooks in by wrapping globals:
   trig, archive, baseScreen, endScreen, applyResults (story layer); newCampaign, continueGame (campaign/save); startMission, threatStep (turns.js);
   odds, damage, resolve (rules.js); eAct, intentOf (ai.js). Entry point: startEra(2), called by the Era 1 ending. */
const era=()=>C&&C.era||1;

// ── Plan swap: PLAN holds the current era's steps. Era 1's steps are kept in PLAN.era1 so a new campaign can restore them. ──
function usePlan(n){if(n===2&&!PLAN.era1){PLAN.era1=PLAN.slice();PLAN.length=0;PLAN.push(...PLAN2)}
 else if(n!==2&&PLAN.era1){const p=PLAN.era1;PLAN.length=0;PLAN.push(...p);delete PLAN.era1}}
const _newCampaign=newCampaign;newCampaign=function(d){usePlan(1);return _newCampaign(d)};
const _continueGame=continueGame;continueGame=function(d){usePlan(d&&d.C&&d.C.era||1);return _continueGame(d)};

// ── Era jump (spec B §1.4) ──
function startEra(n){if(n!==2||!C||era()===2)return;storyInit();usePlan(2);const s=C.story,K=ERA2.carry,J={legends:[],wings:[],res:[]};
 // Rank 3+ heroes become Legends of the Archive; the rest are forgotten.
 for(const r of C.roster)if((r.status==='active'||r.status==='retired')&&(r.rank||1)>=3){J.legends.push(r.n);archive(r,`Became a Legend of the ${ERA1.n}`)}
 C.eras=[...(C.eras||[]),{era:1,shadow:s.shadow,legends:J.legends,fallen:C.legends.map(l=>l.n),won:!!C.flags.boss_or_won}];
 // Wings drop one level unless staffed (min 1). Staff leave with their era.
 for(const k of Object.keys(C.wings)){const l=C.wings[k];if(l>=2&&!(C.staff&&C.staff[k])){C.wings[k]=l-1;J.wings.push(`${WINGS[k].n} ${l}→${l-1}`)}}
 const R=C.res,c0=R.credits,f0=R.favor,i0=R.intel,o0=C.orderDark;
 R.credits=Math.round(c0*K.credits)+K.warChest;R.intel=0;R.favor=Math.round((f0+K.favorTo)/2);C.orderDark=Math.round(o0*K.orderDark);
 J.res=[['Credits',`${c0} → ${R.credits} (30% kept + ${K.warChest} war chest)`],['Intel',`${i0} → 0`],['Kyber',`${R.kyber} kept`],['Senate Favor',`${f0} → ${R.favor}`],['Order Darkness',`${o0} → ${C.orderDark}`]];
 C.eraMod=C.flags.boss_or_won?0:ERA2.eraMod;
 C.roster=ERA2_ROSTER.map(r=>({id:'u'+C.nid++,rank:1,xp:0,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0,...r,picks:[...(r.picks||[])]}));
 C.legends=[];C.staff={};C.bonds={};C.quests={};C.cands=null;C.build=null;C.era=2;C.month=1;C.day=1;C.step=0;
 Object.assign(s,{bby:ERA2.bby,done:0,eraDone:0,visit:'',q:[],yrs:null,shard:1,jump:J});
 for(const k of ['hoth','farfalla'])if(s.loyal[k]==null)s.loyal[k]=COUNCIL_SEATS[k].loyalty;
 ensureTemple();C.options=optionsFor(0);C.news=[`It is now ${bbyTxt(ERA2.bby)}. The Army of Light needs the Temple.`];saveGame();jumpScreen()}
function jumpScreen(){SCR=jumpScreen;const s=C.story,J=s.jump,m=$('#modal');m.hidden=false;
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Era 2 · ${ERA2.n} · ${bbyTxt(ERA2.bby)}</div><h2>Centuries pass</h2><p>${ERA2.jump}</p>
 <div class="sum"><div><span>Legends of the Archive</span><span>${J.legends.join(', ')||'none reached rank 3'}</span></div>
 <div><span>Temple wings</span><span>${J.wings.join(' · ')||'every wing held its level'}</span></div>
 ${J.res.map(([a,b])=>`<div><span>${a}</span><span>${b}</span></div>`).join('')}
 <div><span>Research</span><span>The Archives keep everything</span></div>
 ${C.eraMod?`<div><span>Malgus was not stopped</span><span>Ruusan foes are tougher (+${C.eraMod} HP)</span></div>`:''}
 <div><span>The Vision</span><span>${SHADOW.word(s.shadow)} · ${s.shadow}/10</span></div></div>
 <h3>${ERA2.shard.t}</h3><p>${ERA2.shard.text}</p>
 <p class="muted">New squad: ${C.roster.map(r=>r.n).join(', ')}. New Council voices: Lord Hoth, Lord Farfalla.</p>
 <button type="button" class="primary" id="jumpOk">To Ruusan</button></div>`;
 m.onclick=null;$('#jumpOk').onclick=()=>{s.jump=null;saveGame();baseScreen()}}

// ── Story-layer hooks ──
// Events carry their era in trigger.era (default 1).
const _trig=trig;trig=function(t){return(t.era||1)===era()&&_trig(t)};
const _archive=archive;archive=function(r,how,where){_archive(r,how,where);if(era()!==2)return;
 try{const a=archiveLoad();if(a[0]&&a[0].n===r.n){a[0].era=ERA2.n;a[0].ep=a[0].ep.replace(/~[\d,]+ BBY/,bbyTxt(C.story.bby));localStorage.setItem(ARCH_KEY,JSON.stringify(a))}}catch(e){}};
const _baseScreen2=baseScreen;
baseScreen=function(){if(!C||era()!==2)return _baseScreen2();usePlan(2);if(C.story&&C.story.jump)return jumpScreen();_baseScreen2();
 const eb=document.querySelector('#modal .base .eyebrow');if(eb)eb.textContent=eb.textContent.replace(ERA1.n,ERA2.n)};
const _endScreen2=endScreen;
endScreen=function(){if(!C||!C.story)return _endScreen2();if(era()!==2){_endScreen2();
  // Era 1 end → offer Ruusan, unless the Era 1 ending already shows its own button (id nextEra).
  const r=document.getElementById('restart');if(r&&!document.getElementById('nextEra')){r.insertAdjacentHTML('beforebegin','<button type="button" class="primary" id="nextEra">Continue to Ruusan</button>');r.classList.remove('primary')}
  const b=document.getElementById('nextEra');if(b&&!b.onclick)b.onclick=()=>startEra(2);return}
 era2End()};
function era2End(){SCR=endScreen;const s=C.story,m=$('#modal'),od=odark();m.hidden=false;
 if(!s.eraDone){s.eraDone=1;if(od>=60)shadowAdd(1);saveGame()}
 const won=!!C.flags.boss_ru_won,b=['dead','captured','escaped'].find(k=>C.flags[BANE[k].flag])||'escaped',hist=Object.keys(FLAG_LINES).filter(k=>k.startsWith('e2_')&&C.flags[k]).map(k=>`<p>${FLAG_LINES[k]}</p>`).join('');
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Era 2 ends · ${ERA2.n} · ${bbyTxt(s.bby)}</div><h2>The Army of Light</h2>
 <p>${won?STORY_TEXT2.eraWin:STORY_TEXT2.eraLose}</p><p>${BANE[b].line}</p>${od>=60?`<p class="dkt">${STORY_TEXT2.darkWarn}</p>`:''}
 <div class="sum"><div><span>The Vision</span><span>${SHADOW.word(s.shadow)} · ${s.shadow}/10</span></div><div><span>Order Darkness</span><span>${od}/100</span></div>
 <div><span>Senate Favor</span><span>${C.res.favor}</span></div><div><span>Still serving</span><span>${C.roster.filter(r=>r.status==='active').map(r=>r.n).join(', ')||'none'}</span></div>
 <div><span>Fallen</span><span>${C.legends.map(l=>l.n).join(', ')||'none'}</span></div><div><span>Archive of Legends</span><span>${archiveLoad().length} names</span></div></div>
 ${hist?`<h3>What history changed</h3><div class="news">${hist}</div>`:''}
 <p class="muted">Centuries pass again. To be continued: ${ERA2.next}.</p>
 <button type="button" class="primary" id="restart">New campaign</button></div>`;
 m.onclick=null;$('#restart').onclick=()=>{C=null;usePlan(1);briefing(true)}}

// ── Missions: era difficulty mod, assault Threat for Era 2, Bane leaving, Kaan/Bane/caves results ──
const _startMission2=startMission;
startMission=function(id,sq,o){_startMission2(id,sq,o);if(!S.M.era||!C||!C.eraMod)return;
 for(const e of enemies())if(!e.horror&&!e.nexus){e.hp+=C.eraMod;e.max+=C.eraMod}render()};
const _threatStep2=threatStep;
threatStep=function(){if(!S.M.era||S.type!=='assault')return _threatStep2();log(`Threat rises to ${S.threat}.`,'bad');
 const bomb=S.id==='r_bomb';
 if(S.threat>=6)return finish(false,`${bomb?'The thought bomb fires.':'The nexus erupts.'} ${S.M.lose}`);
 log(S.threat>=5?(bomb?'The ritual is almost complete. Next turn it fires.':'The nexus is about to erupt.'):(bomb?'Kaan\'s Lords chant louder.':'The nexus pulses.'),'bad');
 if(S.threat%2===0&&S.M.reinforce)spawn(S.M.reinforce)};
const _applyResults2=applyResults;
applyResults=function(win){const M=S.M,id=S.id,clues=S.clues,bane=S.units.find(u=>u.bane);const out=_applyResults2(win);if(!M.era)return out;
 const s=C.story;
 if(id==='r_ravine'&&win){const f=applyFx({recruit:'johun'});ensureTemple();out.flag=f.join('. ')+'.'}
 if(id==='r_caves'){C.flags.e2_caves_done=1;if(win){C.flags.e2_bomb_known=1;out.flag='The tablets describe a thought bomb. You will have more time to stop it.';
  if(clues>=3){C.flags.e2_bane_seen=1;out.flag+=' A scout saw one Sith walk away from the caves, alone.'}}}
 if(id==='r_bomb'){let k='escaped';if(bane&&bane.status==='dead')k='dead';else if(bane&&bane.status==='captured')k='captured';
  C.flags[BANE[k].flag]=1;shadowAdd(BANE[k].shadow);
  if(win){C.flags.boss_ru_won=1;C.flags.e2_hoth_lives=1;gain('favor',10,out.res);out.flag=STORY_TEXT2.bossWin+' '+BANE[k].line}
  else{C.flags.e2_bomb_fired=1;gain('favor',-10,out.res);out.flag=STORY_TEXT2.bossLose+' '+BANE[k].line}}
 saveGame();return out};

// ── Ruusan foe mechanics (Requests to X: fold into rules.js/ai.js whenever you like) ──
// Brotherhood troopers: +lordAura aim within 4 tiles of a living Sith Lord.
const _odds=odds;odds=function(a,t,o){const r=_odds(a,t,o);
 if(a.lordAura&&a.side==='e'&&enemies().some(e=>e!==a&&e.sithLord&&e.status==='ok'&&dist(e,a)<=4)){r.lines.push(['Sith Lord nearby',a.lordAura]);r.total=Math.max(5,Math.min(95,r.total+a.lordAura))}return r};
// Marauders grow angrier when hit (max +3). Fanatics never surrender.
const _damage=damage;damage=function(t,d,src){const st=t.status;_damage(t,d,src);
 if(t.fanatic&&t.status==='surrender'&&st!=='surrender'){t.status='ok';log(`${t.n} refuses to surrender.`,'bad')}
 if(t.rage&&t.status==='ok'&&(t.rageN||0)<3){t.rageN=(t.rageN||0)+1;t.dmg=[t.dmg[0]+1,t.dmg[1]+1];log(`${t.n}'s rage grows (+${t.rageN} damage).`,'bad')}};
const _resolve=resolve;resolve=function(a,...r){a.fired=1;return _resolve(a,...r)};
// Snipers overwatch when they don't fire. A nexus never acts; every N turns it spawns a Sith Spawn beside it.
const _eAct=eAct;
eAct=async function(e){
 // Bane watches from the ridge: he fights only what reaches him, and walks away on turn BANE.leaves.
 if(e.bane){if(e.status==='ok'&&S.turn>=BANE.leaves){S.units=S.units.filter(u=>u!==e);log('Darth Bane turns his back on the ritual and walks away over the ridge.','dark');return}
  if(e.status==='ok'&&!players().some(p=>p.status==='ok'&&cheb(p,e)<=1))return}
 if(e.nexus){if(e.status==='ok'&&S.turn%e.nexus===0&&S.lastSpawn!==S.turn){
  const p=N4.map(([dx,dy])=>({x:e.x+dx,y:e.y+dy})).find(p=>inb(p.x,p.y)&&PASS(tile(p.x,p.y))&&!unitAt(p.x,p.y));
  if(p){S.lastSpawn=S.turn;S.units.push(mkFoe('sith_spawn',p.x,p.y));fx(p,'SPAWN','dmg');log(`${e.n} pulses. A Sith Spawn crawls out.`,'dark')}}return}
 e.fired=0;if(e.autoOW)e.ow=false;await _eAct(e);
 if(e.autoOW&&e.status==='ok'&&!e.fired&&!S.over){e.ow=true;log(`${e.n} settles in on overwatch.`)}};
const _intentOf=intentOf;intentOf=function(e){if(e.bane&&!players().some(p=>p.status==='ok'&&cheb(p,e)<=1))return{txt:`Watching from the ridge. Leaves on turn ${BANE.leaves}`};return e.nexus?{txt:`Spawns a Sith Spawn every ${e.nexus} turns`}:_intentOf(e)};

// Codex lore for Era 2 ids, once L's CODEX exists.
addEventListener('load',()=>{if(typeof CODEX==='undefined')return;for(const [k,v] of Object.entries(ERA2_LORE)){CODEX[k]=CODEX[k]||{};for(const [id,o] of Object.entries(v))if(!CODEX[k][id])CODEX[k][id]=o}});

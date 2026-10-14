/* Era 2: Ruusan. Era jump (spec B §1.4), time-skip scene, Era 2 plan, Ruusan foe mechanics, Kaan/Bane outcomes, era-end stub.
   Data: data-era2.js. Load after story.js, before screens.js. Like story.js, it hooks in by wrapping globals:
   trig, archive, baseScreen, endScreen, applyResults (story layer); newCampaign, continueGame, optionsFor (campaign/save); startMission (turns.js).
   Entry point: startEra(2), called by the Era 1 ending. */
const era=()=>C&&C.era||1;

// ── Era swap: PLAN, the Years-pass text (ACTS) and Act shards (SHARDS) hold the current era's data. (Council seats by era: SEATS, data-life.js.)
// Era 1's copies are kept in ERA_SAVED so a new campaign can restore them. ──
let ERA_SAVED=null;
function usePlan(n){const T=[[PLAN,PLAN2],[ACTS,ACTS2],[SHARDS,SHARDS2]];
 const put=(t,v)=>{if(Array.isArray(t)){t.length=0;t.push(...v)}else{for(const k of Object.keys(t))delete t[k];Object.assign(t,v)}};
 if(n===2&&!ERA_SAVED){ERA_SAVED=T.map(([t])=>Array.isArray(t)?t.slice():{...t});T.forEach(([t,v])=>put(t,v))}
 else if(n!==2&&ERA_SAVED){T.forEach(([t],i)=>put(t,ERA_SAVED[i]));ERA_SAVED=null}}
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
// Events carry their era in trigger.era (default 1). New trigger: loyal{seat,min} = a Council seat's loyalty is at least min.
const _trig=trig;trig=function(t){if((t.era||1)!==era())return false;if(t.type==='loyal')return((C.story.loyal||{})[t.seat]??60)>=t.min;return _trig(t)};
// Era 2: a captured unit's rescue runs on a Ruusan map instead of Ord Mantell.
const _optionsFor=optionsFor;optionsFor=function(step){const o=_optionsFor(step);if(era()===2)for(const x of o)if(x.crisis==='rescue')x.mission='r_prisoners';return o};
const _archive=archive;archive=function(r,how,where){_archive(r,how,where);if(era()!==2)return;
 try{const a=archiveLoad();if(a[0]&&a[0].n===r.n){a[0].era=ERA2.n;a[0].ep=a[0].ep.replace(/~[\d,]+ BBY/,bbyTxt(C.story.bby));localStorage.setItem(ARCH_KEY,JSON.stringify(a))}}catch(e){}};
const _baseScreen2=baseScreen;
baseScreen=function(){if(!C||era()!==2)return _baseScreen2();usePlan(2);if(C.story&&C.story.jump)return jumpScreen();_baseScreen2()};   // the Temple eyebrow reads C.era itself (eraLabel, ui-hud.js)
const _endScreen2=endScreen;
endScreen=function(){if(!C||!C.story)return _endScreen2();if(era()!==2){_endScreen2();
  // Era 1 end → offer Ruusan, unless the Era 1 ending already shows its own button (id nextEra).
  const r=document.getElementById('restart');if(r&&!document.getElementById('nextEra')){r.insertAdjacentHTML('beforebegin','<button type="button" class="primary" id="nextEra">Continue to Ruusan</button>');r.classList.remove('primary')}
  const b=document.getElementById('nextEra');if(b&&!b.onclick)b.onclick=()=>startEra(2);return}
 era2End()};
// What Era 3 reads: C.eras[1] = {era:2, shadow, bane:'dead'|'captured'|'escaped', hoth:'lives'|'died', johun, won, loyal}; flags e2_* and rule_of_two.
function era2Record(){const s=C.story,F=C.flags,b=['dead','captured','escaped'].find(k=>F[BANE[k].flag])||'escaped';
 return{era:2,shadow:s.shadow,bane:b,hoth:F.e2_hoth_lives?'lives':'died',johun:F.johun_joined?'joined':F.e2_johun_saved?'saved':'lost',won:!!F.boss_ru_won,
  loyal:{hoth:s.loyal.hoth,farfalla:s.loyal.farfalla},fallen:C.legends.map(l=>l.n)}}
function era2End(){SCR=endScreen;const s=C.story,m=$('#modal'),od=odark();m.hidden=false;
 if(!s.eraDone){s.eraDone=1;if(od>=60)shadowAdd(1);C.eras=[...(C.eras||[]).filter(e=>e.era!==2),era2Record()];saveGame()}
 const won=!!C.flags.boss_ru_won,b=era2Record().bane,hist=Object.keys(FLAG_LINES).filter(k=>k.startsWith('e2_')&&C.flags[k]).map(k=>`<p>${FLAG_LINES[k]}</p>`).join('');
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Era 2 ends · ${ERA2.n} · ${bbyTxt(s.bby)}</div><h2>The Army of Light</h2>
 <p>${won?STORY_TEXT2.eraWin:STORY_TEXT2.eraLose}</p><p>${BANE[b].line}</p>${od>=60?`<p class="dkt">${STORY_TEXT2.darkWarn}</p>`:''}
 <div class="sum"><div><span>The Vision</span><span>${SHADOW.word(s.shadow)} · ${s.shadow}/10</span></div><div><span>Order Darkness</span><span>${od}/100</span></div>
 <div><span>Senate Favor</span><span>${C.res.favor}</span></div><div><span>Still serving</span><span>${C.roster.filter(r=>r.status==='active').map(r=>r.n).join(', ')||'none'}</span></div>
 <div><span>Fallen</span><span>${C.legends.map(l=>l.n).join(', ')||'none'}</span></div><div><span>Archive of Legends</span><span>${archiveLoad().length} names</span></div>
 <div><span>Lord Hoth</span><span>${C.flags.e2_hoth_lives?'lives':'died in the thought bomb'} · trust ${s.loyal.hoth}</span></div><div><span>Lord Farfalla</span><span>leads the Order · trust ${s.loyal.farfalla}</span></div></div>
 ${hist?`<h3>What history changed</h3><div class="news">${hist}</div>`:''}
 <p class="muted">Centuries pass again. To be continued: ${ERA2.next}.</p>
 <button type="button" class="primary" id="restart">New campaign</button></div>`;
 m.onclick=null;$('#restart').onclick=()=>{C=null;usePlan(1);briefing(true)}}

// ── Missions: era difficulty mod, prisoner names, story results (Johun, Vell, Vorr, caves, Kaan/Bane) ──
const _startMission2=startMission;
startMission=function(id,sq,o){_startMission2(id,sq,o);if(!S.M.era)return;
 const h=S.M.hostN&&hostage();if(h&&!h.rid)h.n=S.M.hostN;   // Era 2 prisoner name (a captured squad member keeps theirs)
 if(C&&C.eraMod)for(const e of enemies())if(!e.horror&&!e.nexus){e.hp+=C.eraMod;e.max+=C.eraMod}render()};
const _applyResults2=applyResults;
applyResults=function(win){const M=S.M,id=S.id,clues=S.clues,bane=S.units.find(u=>u.bane);const out=_applyResults2(win);if(!M.era)return out;
 const F=C.flags;
 if(id==='r_ravine'&&win){F.e2_johun_saved=1;out.flag='Johun Othone lives. He goes back to Hoth\'s side, for now.'}
 if(id==='r_sixth'&&win)F.e2_vell_saved=1;
 if(id==='r_seventh'){F.e2_seventh_done=1;if(win)F.e2_vorr_down=1}
 if(id==='r_caves'){C.flags.e2_caves_done=1;if(win){C.flags.e2_bomb_known=1;out.flag='The tablets describe a thought bomb. You will have more time to stop it.';
  if(clues>=3){C.flags.e2_bane_seen=1;out.flag+=' A scout saw one Sith walk away from the caves, alone.'}}}
 if(id==='r_bomb'){let k='escaped';if(bane&&bane.status==='dead')k='dead';else if(bane&&bane.status==='captured')k='captured';
  F[BANE[k].flag]=1;if(k==='escaped')F.rule_of_two=1;shadowAdd(BANE[k].shadow);
  if(win){F.boss_ru_won=1;F.e2_hoth_lives=1;gain('favor',10,out.res);out.flag=STORY_TEXT2.bossWin+' '+BANE[k].line}
  else{F.e2_bomb_fired=1;gain('favor',-10,out.res);if(F.e2_hoth_waits)F.e2_hoth_lives=1;out.flag=(F.e2_hoth_waits?STORY_TEXT2.bossLoseHothOut:STORY_TEXT2.bossLose)+' '+BANE[k].line}}
 saveGame();return out};


// Ruusan foe flags (lordAura, fanatic, rage, autoOW, nexus, bane) and Era 2 assault Threat text now live in rules.js / ai.js / turns.js (Chat X).


/* Era 3: the High Republic. Era jump from Ruusan, time-skip scene, Era 3 plan, Nihil/Drengir/Nameless foe behaviors, Act boss results, era-end screen.
   Data: data-era3.js. Load after story-era2.js (wraps its usePlan/startEra/endScreen), before battle.js. Hooks in by wrapping globals, like story-era2.js:
   usePlan, yearsJump, startEra, baseScreen, endScreen, optionsFor, archive, startMission, applyResults (story layer); eAct, eDo, intentOf (ai.js); odds (rules.js).
   Entry point: startEra(3), from the Era 2 end screen. */
const isE3=()=>typeof S!=='undefined'&&S&&S.M&&S.M.era===3;

// ── Rows for tables that load after data-era3.js ──
Object.assign(SEATS,{veter:{n:'Grand Master Pra-Tre Veter',era:3,stance:'Consular',chair:1},gios:{n:'Master Stellan Gios',era:3,stance:'Guardian'}});
Object.assign(PLANETS,{   // frontier placements: Hetzal, Starlight, Valo = Outer Rim frontier (C, Med); Wild Space beyond the rim (C, Med)
 'Hetzal':{x:545,y:175,reg:'outer'},'Starlight Beacon':{x:560,y:225,reg:'outer'},'Valo':{x:470,y:325,reg:'outer'},'Wild Space':{x:585,y:120,reg:'outer'},'Outer Rim':{x:520,y:290,reg:'outer'}});
FIELD_PLANETS[3]=['Hetzal','Valo','Starlight Beacon','Wild Space','Ord Mantell','Dantooine','Nar Shaddaa'];
REDEEM_TXT[3]={n:'The way back',text:'{n} has seen the husks the Nameless leave behind, and the fear has turned to hate. Settlers are trapped by a Nihil Cloud. Bring them out alive, with {n} leading.'};
if(typeof GUESTS!=='undefined')Object.assign(GUESTS,{   // [N]
 venz:{era:3,n:'Lt. Arra Venz',cls:'Soldier',rank:2,col:'#e0bd78',line:'Republic Defense Coalition. Starlight sent me. Point me at the Nihil.'},
 tal:{era:3,n:'Knight Ember Tal',cls:'Guardian',rank:2,col:'#62b3ff',line:'I heard the fight from the next valley. For light and life.'}});

// ── Era swap: PLAN, ACTS, SHARDS hold the current era's data. Era 2's usePlan handles 1↔2; this adds 3. ──
let ERA3_SAVED=null;
const e3T=()=>[[PLAN,PLAN3],[ACTS,ACTS3],[SHARDS,SHARDS3]],
 e3Put=(t,v)=>{if(Array.isArray(t)){t.length=0;t.push(...v)}else{for(const k of Object.keys(t))delete t[k];Object.assign(t,v)}};
const _usePlan3=usePlan;
usePlan=function(n){if(ERA3_SAVED){e3T().forEach(([t],i)=>e3Put(t,ERA3_SAVED[i]));ERA3_SAVED=null}
 if(n!==3)return _usePlan3(n);
 _usePlan3(1);ERA3_SAVED=e3T().map(([t])=>Array.isArray(t)?t.slice():{...t});e3T().forEach(([t,v])=>e3Put(t,v))};
// Years pass: story.js treats {years:1} as the default 5-year jump; in Era 3 a step marked years:1 really is one year (232 → 231 → 230 BBY).
const _yearsJump3=yearsJump;
yearsJump=function(){const P=PLAN[C.step];if(era()!==3||!P||P.years!==1)return _yearsJump3();const j=YEARS.jump;YEARS.jump=1;try{return _yearsJump3()}finally{YEARS.jump=j}};

// ── Era jump (spec B §1.4), Ruusan → High Republic ──
const _startEra3=startEra;
startEra=function(n){if(n!==3)return _startEra3(n);if(!C||era()===3)return;storyInit();const from=era();
 if(from===2&&!(C.eras||[]).some(e=>e.era===2))C.eras=[...(C.eras||[]),era2Record()];
 const s=C.story,K=ERA3.carry,J={legends:[],wings:[],res:[],echo:[]},F=C.flags,from2=(C.eras||[]).find(e=>e.era===2);
 for(const r of C.roster)if((r.status==='active'||r.status==='retired')&&(r.rank||1)>=3){J.legends.push(r.n);archive(r,`Became a Legend of ${from===2?ERA2.n:ERA1.n}`)}
 usePlan(3);
 for(const k of Object.keys(C.wings)){const l=C.wings[k];if(l>=2&&!(C.staff&&C.staff[k])){C.wings[k]=l-1;J.wings.push(`${WINGS[k].n} ${l}→${l-1}`)}}
 const R=C.res,c0=R.credits,f0=R.favor,i0=R.intel,o0=C.orderDark;
 R.credits=Math.round(c0*K.credits)+K.warChest;R.intel=0;R.favor=Math.round((f0+K.favorTo)/2);C.orderDark=Math.round(o0*K.orderDark);
 J.res=[['Credits',`${c0} → ${R.credits} (30% kept + ${K.warChest} from the Republic)`],['Intel',`${i0} → 0`],['Kyber',`${R.kyber} kept`],['Senate Favor',`${f0} → ${R.favor}`],['Order Darkness',`${o0} → ${C.orderDark}`]];
 // +1 foe HP per lost era boss so far (Malgus, Kaan), cap +2.
 C.eraMod=Math.min(ERA3.eraModMax,(F.boss_or_won?0:1)+(from===2&&!F.boss_ru_won?1:0));
 // Ruusan echoes (Era 2 record).
 if(from2){J.echo.push(BANE[from2.bane]?{dead:'No Sith walked away from Ruusan. The Archives call the Sith extinct, and for once they may be right.',
  captured:'Darth Bane died in a Jedi cell. His holocron is still in the Temple vault.',escaped:'One Sith walked away from Ruusan. Nobody has seen his line since. Nobody has looked.'}[from2.bane]:'');
  if(from2.hoth==='lives')J.echo.push('Lord Hoth lived. His rule that no Jedi takes a war title still stands in the Temple.')}
 C.roster=ERA3_ROSTER.map(r=>({id:'u'+C.nid++,rank:1,xp:0,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0,...r,picks:[...(r.picks||[])]}));
 C.legends=[];C.staff={};C.bonds={};C.quests={};C.cands=null;C.build=null;C.era=3;C.month=1;C.day=1;C.step=0;
 Object.assign(s,{bby:ERA3.bby,done:0,eraDone:0,visit:'',q:[],yrs:null,shard:1,jump:J});
 s.loyal=s.loyal||{};for(const k of ['veter','gios'])if(s.loyal[k]==null)s.loyal[k]=COUNCIL_SEATS[k].loyalty;
 ensureTemple();C.options=optionsFor(0);C.news=[`It is now ${bbyTxt(ERA3.bby)}. Starlight Beacon is lit. The Republic reaches for the frontier.`];saveGame();jumpScreen3()};
function jumpScreen3(){SCR=jumpScreen3;const s=C.story,J=s.jump,m=$('#modal');m.hidden=false;
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Era 3 · ${ERA3.n} · ${bbyTxt(ERA3.bby)}</div><h2>Centuries pass</h2><p>${ERA3.jump}</p>
 <div class="sum"><div><span>Legends of the Archive</span><span>${J.legends.join(', ')||'none reached rank 3'}</span></div>
 <div><span>Temple wings</span><span>${J.wings.join(' · ')||'every wing held its level'}</span></div>
 ${J.res.map(([a,b])=>`<div><span>${a}</span><span>${b}</span></div>`).join('')}
 <div><span>Research</span><span>The Archives keep everything</span></div>
 ${C.eraMod?`<div><span>Old defeats</span><span>Foes this era are tougher (+${C.eraMod} HP)</span></div>`:''}
 <div><span>The Vision</span><span>${SHADOW.word(s.shadow)} · ${s.shadow}/10</span></div></div>
 ${(J.echo||[]).filter(Boolean).map(t=>`<p class="muted">${t}</p>`).join('')}
 <h3>${ERA3.shard.t}</h3><p>${ERA3.shard.text}</p>
 <p class="muted">New squad: ${C.roster.map(r=>r.n).join(', ')}. ${C.roster[1].n} walks the Wayseeker path: Jedi who answer to the Force, not the Council. New Council voices: Grand Master Veter, Master Gios.</p>
 <button type="button" class="primary" id="jumpOk">To the frontier</button></div>`;
 m.onclick=null;$('#jumpOk').onclick=()=>{s.jump=null;saveGame();baseScreen()}}

// ── Story-layer hooks (event era filter + loyal trigger already come from story-era2.js's trig wrapper) ──
const _optionsFor3=optionsFor;optionsFor=function(step){const o=_optionsFor3(step);if(era()===3)for(const x of o)if(x.crisis==='rescue'||x.mission==='r_prisoners')x.mission='h_prisoners';return o};
const _archive3=archive;archive=function(r,how,where){_archive3(r,how,where);if(era()!==3)return;
 try{const a=archiveLoad();if(a[0]&&a[0].n===r.n){a[0].era=ERA3.n;a[0].ep=a[0].ep.replace(/~[\d,]+ BBY/,bbyTxt(C.story.bby));localStorage.setItem(ARCH_KEY,JSON.stringify(a))}}catch(e){}};
const _baseScreen3=baseScreen;
baseScreen=function(){if(!C||era()!==3)return _baseScreen3();usePlan(3);if(C.story&&C.story.jump)return jumpScreen3();_baseScreen3()};
const _endScreen3=endScreen;
endScreen=function(){if(C&&C.story&&era()===3)return era3End();_endScreen3();if(!C||!C.story||era()!==2)return;
 // Era 2 end → offer the High Republic.
 const r=document.getElementById('restart');if(!r||document.getElementById('nextEra3'))return;
 r.insertAdjacentHTML('beforebegin','<button type="button" class="primary" id="nextEra3">Continue to the High Republic</button>');r.classList.remove('primary');
 for(const p of document.querySelectorAll('#modal p.muted'))if(/To be continued/.test(p.textContent))p.textContent=`Centuries pass again. Next: ${ERA2.next}.`;
 document.getElementById('nextEra3').onclick=()=>startEra(3)};
// What Era 4 reads: C.eras.find(e=>e.era===3).
function era3Record(){const s=C.story,F=C.flags;
 return{era:3,shadow:s.shadow,beacon:F.e3_beacon_saved?'saved':'fell',ro:F.e3_ro_down?'down':'fled',lourna:F.e3_lourna_dead?'dead':F.e3_lourna_escaped?'escaped':'unmet',
  progenitor:F.e3_progenitor_down?'dead':'lives',orla:F.orla_joined?'joined':'walked',won:!!F.boss_hr_won,loyal:{veter:s.loyal.veter,gios:s.loyal.gios},fallen:C.legends.map(l=>l.n)}}
function era3End(){SCR=endScreen;const s=C.story,m=$('#modal'),od=odark(),F=C.flags;m.hidden=false;
 if(!s.eraDone){s.eraDone=1;if(od>=60)shadowAdd(1);C.eras=[...(C.eras||[]).filter(e=>e.era!==3),era3Record()];saveGame()}
 const won=!!F.boss_hr_won,rec=era3Record(),hist=Object.keys(FLAG_LINES).filter(k=>(k.startsWith('e3_')||k==='orla_joined')&&F[k]).map(k=>`<p>${FLAG_LINES[k]}</p>`).join('');
 m.innerHTML=`<div class="box wide"><div class="eyebrow">Era 3 ends · ${ERA3.n} · ${bbyTxt(s.bby)}</div><h2>Light and Life</h2>
 <p>${won?STORY_TEXT3.eraWin:STORY_TEXT3.eraLose}</p>${od>=60?`<p class="dkt">${STORY_TEXT3.darkWarn}</p>`:''}
 <div class="sum"><div><span>Starlight Beacon</span><span>${rec.beacon==='saved'?'still shines':'fell into the sea of Eiram'}</span></div>
 <div><span>Marchion Ro</span><span>${rec.ro==='down'?'fell on Starlight':'escaped into the dark'}</span></div>
 <div><span>Lourna Dee</span><span>${{dead:'fell at her hideout',escaped:'got away',unmet:'never cornered'}[rec.lourna]}</span></div>
 <div><span>The Great Progenitor</span><span>${rec.progenitor==='dead'?'withered':'still growing somewhere'}</span></div>
 <div><span>The Vision</span><span>${SHADOW.word(s.shadow)} · ${s.shadow}/10</span></div><div><span>Order Darkness</span><span>${od}/100</span></div>
 <div><span>Senate Favor</span><span>${C.res.favor}</span></div><div><span>Still serving</span><span>${C.roster.filter(r=>r.status==='active').map(r=>r.n).join(', ')||'none'}</span></div>
 <div><span>Fallen</span><span>${C.legends.map(l=>l.n).join(', ')||'none'}</span></div><div><span>Archive of Legends</span><span>${archiveLoad().length} names</span></div>
 <div><span>Grand Master Veter</span><span>trust ${s.loyal.veter}</span></div><div><span>Master Gios</span><span>trust ${s.loyal.gios}</span></div></div>
 ${hist?`<h3>What history changed</h3><div class="news">${hist}</div>`:''}
 <p class="muted">Two centuries pass. To be continued: ${ERA3.next}.</p>
 <button type="button" class="primary" id="restart">New campaign</button></div>`;
 m.onclick=null;$('#restart').onclick=()=>{C=null;usePlan(1);briefing(true)}}

// ── Missions: Path-Runners start out of sight; story results ──
const _startMission3=startMission;
// Comm beats say {cmd}; battle.js maps any era ≥2 to "Army of Light". Era 3 answers to Starlight. (Wrapped lazily: battle.js loads after this file. E: fold into bvSub.)
let e3CmdW=0;function e3Cmd(){if(e3CmdW||typeof bvSub!=='function')return;e3CmdW=1;const f=bvSub;bvSub=function(s,c){const r=f(s,c);return isE3()?r.replace(/Army of Light/g,'Starlight Command'):r}}
startMission=function(id,sq,o){e3Cmd();_startMission3(id,sq,o);if(!isE3())return;for(const e of enemies())if(e.pathJump){e.hid=1;e.jumpT=e.pathJump}render()};
// Path-Runners that arrive with a wave drop in behind the squad at once.
const _mkFoe3=mkFoe;
mkFoe=function(t,x,y){const u=_mkFoe3(t,x,y);if(!isE3()||!u.pathJump||S.turn<2||!players().length)return u;
 const T=freeTiles().filter(p=>!(p.x===x&&p.y===y)).map(p=>({...p,d:nearP(p)})).filter(p=>p.d>=3&&p.d<=7).sort((a,b)=>b.y-a.y+Math.random()-.5);
 if(T[0]){u.x=T[0].x;u.y=T[0].y;u.jumped=1;log(`${u.n} drops out of hyperspace behind your line!`,'bad')}return u};
const _applyResults3=applyResults;
applyResults=function(win){const M=S.M,id=S.id,clues=S.clues,boss=S.units.find(u=>u.boss);const out=_applyResults3(win);if(M.era!==3)return out;const F=C.flags;
 if(id==='h_hetzal'&&win){F.e3_hetzal_saved=1;out.flag='Marshal Avar Kriss noted your squad\'s name.'}
 if(id==='h_grove'){F.e3_grove_done=1;if(win){F.e3_progenitor_down=1;out.flag=STORY_TEXT3.groveWin}else out.flag=STORY_TEXT3.groveLose}
 if(id==='h_valo'&&win){F.e3_valo_held=1;F.e3_ro_named=1;out.flag='A captured Nihil talks. The Eye has a name.'}
 if(id==='h_tempest'){const k=win&&boss&&boss.status==='dead'?'dead':'escaped';F['e3_lourna_'+k]=1;out.flag=STORY_TEXT3.tempest[k]}
 if(id==='h_husks'&&win){F.e3_nameless_known=1;if(clues>=3){F.e3_leveler_found=1;out.flag='The logs show how the Leveler hunts. You will have more time on Starlight.'}}
 if(id==='h_beacon'){if(win){F.boss_hr_won=1;F.e3_beacon_saved=1;F.e3_ro_down=1;shadowAdd(-1);gain('favor',10,out.res);out.flag=STORY_TEXT3.bossWin}
  else{F.e3_beacon_fell=1;shadowAdd(1);gain('favor',-10,out.res);out.flag=STORY_TEXT3.bossLose}}
 saveGame();return out};

// ── Foe behaviors (Era 3 only). hitRun · gas · pathJump · root · seed · dread · pathEscape · eyeMark ──
const freeTiles=()=>{const o=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(PASS(tile(x,y))&&!unitAt(x,y))o.push({x,y});return o};
const nearP=p=>{const P=players().filter(u=>u.status!=='dead');return P.length?Math.min(...P.map(u=>dist(u,p))):99};
function e3Jump(e,pick,txt){const T=freeTiles();if(!T.length)return;const t=T.sort((a,b)=>pick(b)-pick(a))[0];e.x=t.x;e.y=t.y;e.hid=0;fx(e,'PATH JUMP','dmg');log(txt,'bad');render()}
function e3Spawn(e,type){const p=N4.map(([dx,dy])=>({x:e.x+dx,y:e.y+dy})).find(p=>inb(p.x,p.y)&&PASS(tile(p.x,p.y))&&!unitAt(p.x,p.y));
 if(p){S.units.push(mkFoe(type,p.x,p.y));fx(p,'SPROUT','dmg');log(`A ${FOES[type].n} tears out of the soil beside ${e.n}.`,'bad')}}
const dreadNear=u=>u.jedi&&u.side==='p'&&enemies().some(e=>e.dread&&e.status==='ok'&&dist(e,u)<=3);
const _eAct3=eAct;
eAct=async function(e){if(!isE3())return _eAct3(e);
 if(S.e3t!==S.turn){S.e3t=S.turn;for(const p of players())if(p.rooted&&p.rootT<S.turn){p.rooted=0}}   // roots hold through one player turn
 if(e.status!=='ok')return _eAct3(e);
 if(e.pathJump&&!e.jumped){if(S.turn<(e.jumpT||0))return;e.jumped=1;
  e3Jump(e,t=>{const d=nearP(t);return d<3||d>7?-99:t.y*2+Math.random()},`${e.n} drops out of hyperspace behind your line!`)}
 if(e.pathEscape&&!e.escaped&&e.hp*2<=e.max){e.escaped=1;e.hp=Math.min(e.max,e.hp+e.pathEscape);e3Jump(e,t=>nearP(t)+Math.random(),`${e.n} hits a Path beacon and jumps across the field, patching her wounds.`)}
 if(e.seed&&S.turn%e.seed===0&&e.seedT!==S.turn){e.seedT=S.turn;e3Spawn(e,'drengir')}
 if(e.eyeMark)S.roMark=null;
 if(e.seed&&!e.mob)return;   // the Root-Mother only grows
 e.shot=0;await _eAct3(e);if(S.over||e.status!=='ok')return;
 if(e.dread)for(const u of players())if(u.jedi&&u.status==='ok'&&dist(u,e)<=3&&u.focus>0){u.focus--;fx(u,'DREAD','dark')}
 // Hit and run: after a shot, dash up to 3 tiles back toward cover.
 if(e.hitRun&&e.shot&&!e.rooted){const m0=e.mob;e.mob=3;const R=reach(e);e.mob=m0;const P=players().filter(p=>p.status==='ok');let best=null,bs=-1e9;
  for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),pos={x,y};let s=Math.random();for(const p of P)if(dist(p,pos)<=10&&los(p,pos))s-=(40-coverVal(pos,p))/2;if(s>bs){bs=s;best=pos}}
  if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));log(`${e.n} fires and dashes back into cover.`);render()}}};
const _eDo3=eDo;
eDo=async function(e,a){if(!isE3())return _eDo3(e,a);const t=a.t,hp0=t?t.hp:0;await _eDo3(e,a);
 if(a.kind==='shot'){e.shot=1;if(e.eyeMark&&t&&t.status==='ok'){S.roMark=t.uid;fx(t,'MARKED','dmg');log(`${e.n} marks ${t.n}. Every Nihil gun turns that way.`,'bad')}}
 if(e.root&&a.kind==='melee'&&t&&t.hp<hp0&&t.status==='ok'){t.rooted=1;t.rootT=S.turn;fx(t,'ROOTED','dmg');log(`Vines lock ${t.n} in place.`,'bad')}
 if(e.gas&&a.kind==='nade')for(const u of players())if(u.status==='ok'&&cheb(u,a)<=1){u.choke=S.turn+1;fx(u,'CHOKING','dmg')}};
const _odds3=odds;
odds=function(a,t,o){const r=_odds3(a,t,o);if(!isE3())return r;const L=r.lines;
 if(a.choke>=S.turn)L.push(['Choking gas',-15]);
 if(dreadNear(a))L.push(['Dread',-15]);
 if(a.side==='e'&&S.roMark&&t.uid===S.roMark&&enemies().some(e=>e.eyeMark&&e.status==='ok'))L.push(['Marked by the Eye',15]);
 const raw=L.reduce((s,l)=>s+l[1],0);r.total=Math.max(5,Math.min(95,Math.round(raw)));return r};
const _intentOf3=intentOf;
intentOf=function(e){if(isE3()){if(e.pathJump&&!e.jumped)return{txt:`On a hyperspace Path. Drops in behind you on turn ${Math.max(S.turn,e.jumpT||0)}`};
 if(e.seed&&!e.mob)return{txt:`Grows a Drengir every ${e.seed} turns`}}return _intentOf3(e)};

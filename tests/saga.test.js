// Saga layer (saga.js): talks, forced arc scenes, approach, squad beats, aftermath, grief, finale allies. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s),q=s=>d.querySelector(s);
const clear=(g=0)=>{for(let k=0;k<16;k++){const ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);
 if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[g%ch.length].click();else if(q('[data-role]'))q('[data-role]').click();else if(q('#yrOk')&&!q('#yrOk').disabled)q('#yrOk').click();else return}};
(async()=>{
q('[data-d="normal"]').click();clear();
check(E("Object.keys(C.saga.id).length")>=6,'the 6 starting units are mapped to cast arcs');
// Content sanity: every talk has a known speaker, ≤280-char text, 2–3 choices with ≤32-char labels and a free option.
check(E("TALKS.every(T=>CAST[T.who]&&T.text.length<=280&&T.ch.length>=2&&T.ch.length<=3&&T.ch.every(c=>c.l.length<=32)&&T.ch.some(c=>!Object.entries(c.fx).some(([k,v])=>RES_NAMES[k]&&v<0&&k!=='orderDark'&&k!=='favor')&&!c.need))"),'talks: valid speakers, text caps, a free choice each');
check(E("Object.values(AFTER).every(A=>A.text.length<=280&&A.ch.every(c=>c.l.length<=32))"),'aftermath text caps');
check(E("SQUAD_BEATS.every(B=>CAST[B.who]&&B.a.label.length<=32&&B.b.label.length<=32)"),'squad beats: valid speakers and labels');
check(E("Object.keys(APPROACH).every(k=>k==='_'||MISSIONS[k])&&['ilsaDrop','brenClinic','grakClan'].every(k=>MISSIONS[k]&&CRISES[k])"),'approach keys and personal missions exist');
check(E("new Set(TALKS.map(t=>t.id)).size===TALKS.length"),'talk ids unique');
// Optional talk from the strip: none at 0 missions done, one after a mission.
E("C.story.done=1;baseScreen()");clear();
check(!!q('.saga-strip'),'Temple screen shows the Your people strip');
const t1=q('[data-talk]');check(!!t1,'someone wants a word after the first mission');
t1.click();check(!!q('.saga-scene [data-ch]'),'clicking a chip opens the talk');
q('.saga-scene [data-ch]').click();check(!!q('#scOk')&&!!q('.saga-say'),'a reply screen shows the answer');q('#scOk').click();clear();
check(E("C.saga.seen.length")===1,'talk marked seen');
check(!!q('.saga-strip')&&!q('[data-talk]'),'only one talk per hub visit');
// Kira's arc: k1 told → trust up, flag set.
E("C.saga.seen=C.saga.seen.filter(x=>x!=='k1');C.saga.talked=''");E("baseScreen()");clear();
E("sagaScene({...TALKS.find(t=>t.id==='k1'),kind:'talk'},0)");q('[data-ch="0"]').click();q('#scOk').click();clear();
check(E("C.flags.kira_told===1&&C.saga.t.kira>=1"),'Kira k1 "Tell me everything" sets kira_told and trust');
// Forced talk: Ilsa's burst at 2 missions done queues itself.
E("C.story.done=2;C.saga.visit='';baseScreen()");check(E("C.saga.q.some(e=>e.id==='i1')")||E("C.saga.seen.includes('i1')"),'forced talk i1 queues at 2 missions');
check(!!q('.saga-scene'),'forced talk shows before the Temple');clear();
check(E("C.saga.seen.includes('i1')&&(C.flags.ilsa_caught||C.flags.ilsa_watched||C.flags.ilsa_free)"),'forced talk resolved with a flag');
// Personal mission: unlocked by a talk, persists on the galaxy list, not advancing the plan.
E("sagaFx({personal:'grakClan'},'grak')");check(E("C.options.some(o=>o.crisis==='grakClan'&&o.adv===0)"),'personal mission added to options');
check(E("optionsFor(C.step).some(o=>o.crisis==='grakClan')"),'personal mission persists across option rebuilds');
// Approach: squad screen shows it; a costed approach is paid at launch and applied in battle.
const oi=E("C.options.findIndex(o=>o.story)");E(`squadScreen(${oi})`);check(!!q('.saga-ap [data-ap]'),'squad screen shows approach options');
check(q('.saga-ap [data-ap="0"]').classList.contains('on'),'As briefed is the default');
E("C.res.favor=50");q('.saga-ap [data-ap="2"]').click();check(q('.saga-ap [data-ap="2"]').classList.contains('on'),'picking an approach highlights it');
const fav=E("C.res.favor"),ids=E("JSON.stringify(defaultSquad(C.options["+oi+"]))");E(`launchMission(${oi},${ids})`);
check(E("C.res.favor")===fav-3,'Call the Navy costs 3 Favor at launch');
check(E("S.units.some(u=>u.guest)"),'Call the Navy adds a guest trooper');
// Squad beat on turn 2: Kira speaks if she is in the squad.
E("C.saga.seen=C.saga.seen.filter(x=>!x.startsWith('beat:'));C.story.done=3;S.turn=2;bvFire('turn',{n:2})");
check(E("S.saga.beat===1&&S.bv.q.some(x=>x.saga)"),'a squad beat fires on turn 2 with a decision');
const bk=E("S.bv.q.find(x=>x.saga).saga");E("while(S.bv.q.length)bvPick(0)");check(E("S.saga.fx.length")===1,'beat choice is recorded for after the mission');
const tr0=E(`C.saga.t['${bk}']`);
// Finish the mission: beat effects land, story aftermath queues.
E("finish(true,'test win')");check(E(`C.saga.t['${bk}']`)!==tr0||E("Object.keys(S.saga.fx[0].fx).length===0||!('t' in S.saga.fx[0].fx)"),'beat effect applied after the mission');
check(E("C.saga.q.some(e=>e.k==='after')"),'story mission queues an aftermath scene');
q('#toBase')&&q('#toBase').click();check(!!q('.saga-scene')&&/Aftermath/.test(q('.saga-scene .eyebrow').textContent),'aftermath scene shows at the Temple');clear(1);
// Grief: a dead cast member queues a scene from the most trusted survivor.
E("const r=castR('rhal');r.status='dead';C.saga.gone=[];startMission('shrine',C.roster.filter(r=>r.status==='active').slice(0,4).map(battleUnit),{diff:'normal',map:0});S.saga={fx:[],ap:null,beat:1};applyResults(true)");
check(E("C.saga.q.some(e=>e.k==='grief'&&e.dead==='rhal')"),'a fallen cast member queues a grief scene');
E("baseScreen()");clear();
// Trust in battle.
E("C.saga.t.kira=2");check(E("battleUnit(castR('kira')).trust")===2&&E("battleUnit(castR('kira')).aim-(C.saga.t.kira=0,battleUnit(castR('kira')).aim)")===5,'trust 2 gives +5 aim');
// Finale: flags become allies at Docking Ring Nine.
E("Object.assign(C.flags,{kira_foresight:1,ilsa_sis:1,grak_envoy:1})");check(E("S_finaleRows('dock').length")===3,'three arc results stand with you at the dock');
E("startMission('dock',C.roster.filter(r=>r.status==='active').slice(0,6).map(battleUnit),{diff:'normal',map:0})");
check(E("S.bv&&S.bv.locks>=1")&&E("S.log.some(l=>/Kira Venn/.test(l.t||l))"),'finale allies apply at the dock (lift lock + log)');
// Era 2: the layer stays out of the way.
E("C.era=2");check(E("sagaOn()")===false,'saga is off in Era 2');E("C.era=1");
// Epilogue line for a cast member.
E("C.flags.bren_clinic=1");check(/wounded is wounded/.test(E("epiCard(castR('bren'))")),'cast epilogue line at era end');
check(!errs.length,'no page errors'+(errs.length?': '+errs.slice(0,3).join(' | '):''));
console.log(JSON.stringify({err:errs.length,fail}));process.exit(fail||errs.length?1:0)})();

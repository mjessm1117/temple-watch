// Bucket 3 strike teams: team slots, odds, auto-resolve instead of ignore, fatigue, covert actions. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
const story=()=>{for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else if(q('[data-role]'))q('[data-role]').click();else return}};
d.querySelector('[data-d="normal"]').click();story();E('ensureTemple();ensureTeams()');
// Slots and auto-fill
check(E('C.teams.length')===2,'2 teams at the start');
check(E('C.teams.every(t=>t.lead&&isJedi(unit(t.lead))&&t.mem.length>=1)'),'each team has a Jedi leader and troopers');
check(E('new Set(C.teams.flatMap(t=>[t.lead,...t.mem])).size===C.teams.flatMap(t=>[t.lead,...t.mem]).length'),'nobody is on two teams');
E('C.wings.barracks=3;ensureTeams()');check(E('C.teams.length')===4,'Barracks 3 → 4 teams');E('C.wings.barracks=2');
// A step with 2+ crises
const step=E('PLAN.findIndex(p=>p.crises&&p.crises.length>=2)');check(step>=0,'plan has a step with 2+ crises');
E(`C.step=${step};C.options=optionsFor(C.step);var cr=C.options.filter(o=>o.crisis&&o.adv&&!o.hostages)`);
check(E('cr.length')>=2,'step offers 2+ crises');
const od=E('teamOdds(C.teams[0],cr[1])');check(od.ch>=TA('min')&&od.ch<=TA('max')&&od.why.length>=2,`odds in range with reasons (${od.ch}%)`);
function TA(k){return E('TAUTO.'+k)}
// Assign team 0 to crisis 1; play crisis 0 with team 1 only → crisis 1 auto-resolves instead of being ignored
E("tAs().map[cr[1].crisis]=C.teams[0].id;var played=teamUnits(C.teams[1]).filter(fit).map(r=>r.id);var t0=teamUnits(C.teams[0]).map(r=>r.id);var log0=(C.tLog||[]).length");
E("var i0=C.options.indexOf(cr[0]);var _sm=startMission;startMission=function(){};launchMission(i0,played);startMission=_sm");
check(E('C.tLog.length')===E('log0')+1,'assigned crisis auto-resolved (team report logged)');
check(!E("C.news.some(n=>n.includes('Ignored: '+cr[1].n))"),'assigned crisis was not ignored');
check(E('C.tPend.length')===1,'report held until time passes');
E('advance({adv:1})');check(E('C.news.some(n=>/Team (won|lost)/.test(n))'),'report shows in the Temple news after time passes');
check(E('t0.filter(id=>unit(id).status==="active").every(id=>unit(id).fat===1)')&&E('played.every(id=>unit(id).fat===1)'),'both teams get 1 fatigue');
// Fatigue
E('var r=C.roster.find(x=>x.status==="active");r.fat=2;var a=battleUnit(r).aim;r.fat=0;var b=battleUnit(r).aim');
check(E('a')===E('b')-10,'tired = −10 aim in battle');
E('C.tFought=[];templeAdvance()');check(E('C.roster.filter(x=>x.status==="active").every(x=>!x.fat)'),'a step off clears fatigue');
// Forced loss: one serious wound for sure; capture/death never both
E('var _r=Math.random;Math.random=()=>0.995');
E(`C.step=${step};C.options=optionsFor(C.step);C.roster.forEach(r=>{if(r.status==='active'){r.wound=0;r.assign=null}});var c2=C.options.find(o=>o.crisis&&o.adv&&!o.hostages);var tl=C.teams.find(t=>teamAvail(t).length>=2)`);
if(E('!!(c2&&tl)')){E('var f0=C.res.favor;C.chosen=null;var won=autoTeam(c2,tl)');check(!E('won')&&E('C.res.favor')<E('f0'),'forced roll loses and costs Favor');
 check(E('teamUnits(tl).filter(r=>r.status!=="active").length')<=1,'at most one member lost (killed or captured)');
 check(E('teamUnits(tl).some(r=>r.wound>0)'),'a loss wounds a member')}
E('Math.random=_r');
// Covert action: fee paid up front
E("ensureField();C.field.list.push({id:'fx1',k:'vault',planet:'Taris',st:'open',exp:30,fresh:0});C.res.credits=500;FTEAM=C.roster.filter(fit).slice(0,2).map(r=>r.id)");
const sent=E("sendField('fx1')");check(sent&&E('C.res.credits')===440,'covert action charges its fee');
E("C.res.credits=10;C.field.list.push({id:'fx2',k:'mole',planet:'Taris',st:'open',exp:30,fresh:0});FTEAM=C.roster.filter(fit).slice(0,2).map(r=>r.id)");
check(!E("sendField('fx2')"),'covert action blocked without the fee');
// UI renders
check(E("teamsPanel()").includes('Strike teams'),'teams panel renders');check(E("teamLoadHTML()").includes('data-tload'),'squad screen load-team row renders');
E('saveGame()');check(JSON.stringify(E('C')).length<500000,'save stays small');
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({teams:'done',fail,err:errs.length}));process.exit(fail?1:0);

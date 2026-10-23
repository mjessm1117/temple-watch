// Focus session 2026-10-21: Temple modules (actions, digs, bay features, battle buffs) + graze. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
(async()=>{
d.querySelector('[data-d="normal"]').click();for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else break}
E('ensureMods();baseScreen()');
check(d.querySelectorAll('.spr').length===4&&d.querySelectorAll('.slot.vault').length===3,'ziggurat: 4 spires and 3 undercroft vaults');
check(E("Object.values(C.mods.feat).includes('kyber2')"),'a Great Kyber cave is hidden in the undercroft');
check(!E("slotOpen('t0')")&&E("slotOpen('b0')"),'upper terrace locked at the start, base hall open');
E("C.res.credits=999;C.res.kyber=9");check(!E("buildAt('forge','u0'),slotOf('forge')"),'no wings in the undercroft');
E("bayDig('u0')");check(E('C.mods.digging')==='u0','dig starts');E('templeAdvance()');check(E('!!C.mods.dug.u0&&!C.mods.digging'),'dig finishes after a mission');
E("C.mods.feat.u0='kyber2';C.wings.forge=1;var k0=C.res.kyber;templeMonth()");check(E('C.res.kyber')>=E('k0')+2,'Great Kyber cave pays while the Forge stands');
E("C.month=4;spireBuild('sp3');templeAdvance();templeAdvance()");check(E("!!C.mods.spire.sp3"),'a spire rises in 2 missions');
// actions
E("C.roster[0].wound=9;C.roster[0].status='active';modUse('medical')");check(E('C.roster[0].wound')===0&&E('C.mods.cd.medical')===3,'Bacta Rush heals and goes on cooldown');
check(!E("modReady('medical')"),'not ready until missions pass');E('templeAdvance();templeAdvance();templeAdvance()');check(E("modReady('medical')"),'ready again after 3 missions');
E("C.wings.training=1;C.wings.armory=1;C.mods.cd={};modUse('training');modUse('armory')");
E("startMission('relay',C.roster.slice(0,4).map(battleUnit),{diff:'normal',map:0})");
const tr=E("S.units.find(u=>u.side==='p'&&u.rid&&!u.jedi)");check(E("S.log.some(l=>/Temple support/.test(l.t))"),'buffs announced at deploy');
check(E("(()=>{const u=S.units.find(u=>u.side==='p'&&u.rid&&!u.jedi),b=battleUnit(C.roster.find(r=>r.id===u.rid));return u.aim===b.aim+5&&u.armor===(b.armor||0)+1})()"),'trooper got +5 aim and +1 armor pip');
check(E("modNext()")==='','buffs clear after one battle');
// graze: a shot that misses by < GRAZE still does half damage
E("var A=S.units.find(u=>u.side==='p'&&!u.jedi),T={n:'Dummy',side:'e',x:0,y:0,hp:20,max:20,status:'ok'};S.units.push(T);var _r=Math.random;Math.random=()=>0.55");
E("resolve(A,T,50,[6,6],{})");check(E('T.hp')===17,'graze: roll 55 vs 50% does half of 6');
E("Math.random=()=>0.9;T.hp=20;resolve(A,T,50,[6,6],{});Math.random=_r");check(E('T.hp')===20,'clean miss outside the band');
// Wave 7 (E2): Kyber Forge has a real effect (gates saber tiers that add damage); roster cards show team + Tired.
E("var J=C.roster.find(r=>isJedi(r)&&r.status==='active');J.gear.saber=0;C.wings.forge=0;C.res.credits=999;C.res.kyber=9");
var dm0=E('battleUnit(J).dmg[1]');E('craftSaber(J.id)');check(E('J.gear.saber')===0,'no Forge: saber craft blocked');
E('C.wings.forge=1;craftSaber(J.id)');check(E('J.gear.saber')===1&&E('battleUnit(J).dmg[1]')===dm0+1,'Forge L1: Attuned saber crafts and adds +1 damage');
E("ensureTeams();C.teams[0].lead=J.id;J.fat=FATIGUE.at");var rt=E('rosterTab()');
check(rt.includes(E('C.teams[0].n'))&&rt.includes('>Tired<'),'roster card shows team name and Tired badge');
E('J.fat=0;C.teams[0].lead=null');
E("var _S=S;S=null;var A2=C.roster.filter(r=>r.status==='active')[0],B2=C.roster.filter(r=>r.status==='active')[1];A2.stress=B2.stress=50;A2.assign=B2.assign=null;C.staff.gardens=null;A2.fought=C.tick||0;progAdvance();S=_S");
check(E('A2.stress')===50&&E('B2.stress')===50-E('STRESS.bench'),'two fronts: front A squad gets no bench relief at the shared step');
E("var QR=C.roster.find(r=>r.status==='active');QR.rank=2;C.quests[QR.id]={q:Object.keys(QUESTS)[0],st:'offer'}");
check(E('questOptions().some(o=>o.quest===QR.id)'),'personal quest offered');E('C.quests[QR.id].tried=C.step');
check(!E('questOptions().some(o=>o.quest===QR.id)'),'a failed quest is not re-offered on the same step (no endless loop)');
// Clear objectives (E2, 2026-10-23): a "Next:" step in the panel; objective buttons stay visible with how-to.
E("startMission('envoy',C.roster.filter(fit).slice(0,4).map(battleUnit))");
check(E('objHTML()').includes('Next:')&&E('objHTML()').includes('Scan clue'),'investigate: panel says what to do next');
E("S.phase='player';S.sel=players().find(u=>!adjTiles(u,'q').length&&u.abil.includes('scan'))||players()[0];if(!S.sel.abil.includes('scan'))S.sel.abil.push('scan');S.sel.ap=2");
check(E('actsHTML()').includes('Stand next to a data terminal'),'Scan clue button shows greyed with a hint when not next to a terminal');
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0)})();

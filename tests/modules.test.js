// Focus session 2026-10-21: Temple modules (actions, digs, bay features, battle buffs) + graze. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
(async()=>{
d.querySelector('[data-d="normal"]').click();for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else break}
E('ensureMods();baseScreen()');
check(d.querySelectorAll('.slot.rock').length>=4,'deep bays start as rock');
check(E("SLOTS.some(s=>s.f>1&&C.mods.feat[s.id]==='kyber')"),'a Kyber vein is hidden somewhere deep');
E("C.res.credits=999;var bay=SLOTS.find(s=>s.f===2&&!C.mods.dug[s.id]).id");
check(!E("buildAt('forge',bay),slotOf('forge')"),'cannot build on rock');
E("bayDig(bay)");check(E('C.mods.digging')===E('bay'),'dig starts');E('templeAdvance()');check(E('!!C.mods.dug[bay]&&!C.mods.digging'),'dig finishes after a mission');
E("C.mods.feat[bay]='kyber';C.slots[bay]='forge';C.wings.forge=1;var k0=C.res.kyber;templeMonth()");check(E('C.res.kyber')>E('k0'),'Forge on a Kyber vein pays Kyber monthly');
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
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0)})();

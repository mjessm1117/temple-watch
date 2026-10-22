// Arsenal 2026-10-22: module slots by tier, Mk upgrades, research tree + era gates, unit evolution. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
(async()=>{
d.querySelector('[data-d="normal"]').click();for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else break}
E("ensureTemple();C.res.credits=5000;C.res.intel=50;C.res.kyber=20;C.wings.armory=2;C.wings.forge=2;C.wings.archives=1;var T=C.roster.find(r=>!isJedi(r)),J=C.roster.find(r=>isJedi(r))");
check(E("Object.keys(RESEARCH).length")>=35&&E("RES_TREE.length")===5,'research tree: 35+ projects in 5 branches');
check(E("RES_TREE.flatMap(b=>b.ids).every(k=>RESEARCH[k])&&Object.keys(RESEARCH).every(k=>RES_TREE.some(b=>b.ids.includes(k)))"),'every project sits in exactly one branch');
check(E("Object.values(RESEARCH).every(P=>(P.need||[]).every(n=>RESEARCH[n]))"),'all prerequisites exist');
check(E("[0,1,2].map(i=>WEAPONS[i].slots).join()")==='3,4,5'&&E("[0,1,2].map(i=>SABERS[i].slots).join()")==='3,4,5','slots grow 3→5 by tier');
check(E("Object.values(MODPOOL).every(P=>Object.keys(P).length>=8)"),'8 modules per gear line');
E("var a0=battleUnit(T).aim;fitMod(T.id,'w','scope')");check(E("battleUnit(T).aim")===E("a0")+8,'Scope Mk I: +8 aim');
E("mkUp(T.id,'w','scope')");check(E("mkOf(T,'w','scope')")===1,'Mk II locked until researched');
E("C.research.done.push('eliteMods','gunMk2');mkUp(T.id,'w','scope')");check(E("battleUnit(T).aim")===E("a0")+10,'Scope Mk II after research: +10 aim');
E("for(const m of ['barrel','cell','gyro','stock'])fitMod(T.id,'w',m)");check(E("T.gear.mods.length===slotsOf(T,'w')"),'weapon holds only as many modules as its slots');
E("buyWeapon(T.id);buyWeapon(T.id);fitMod(T.id,'w','gyro');fitMod(T.id,'w','stock')");check(E("T.gear.mods.length")===5,'elite blaster holds 5');
E("buyArmor(T.id,'heavy');for(const m of ['padding','servos','damper','bandolier','medpouch'])fitMod(T.id,'a','m')".replace("'m'","m"));check(E("T.gear.amods.length")===5,'heavy armor holds 5 modules');
E("buyArmor(T.id,'light')");check(E("T.gear.amods.length")===3,'smaller armor trims extra modules');
E("fitMod(J.id,'s','matrix');fitMod(J.id,'s','dcell')");check(E("J.gear.smods.join()")==='matrix','saber module fits; Diatium cell needs research');
check(E("C.era=1;startResearch('gunMk3'),C.research.cur")!=='gunMk3','era 2 project locked in era 1');
E("C.era=2;C.research.cur=null;startResearch('gunMk3')");check(E("C.research.cur")==='gunMk3','era 2 project opens in era 2');
E("T.rank=4;var h0=battleUnit(T).hp;evolve(T.id)");check(!E("T.evo"),'evolution needs research');
E("C.research.done.push('eliteProgram');evolve(T.id)");check(E("T.evo")===1&&E("battleUnit(T).hp")===E("h0")+1,'trooper evolves: +1 HP');
E("TAB='armory';ARM=T.id;baseScreen()");check(/Weapon modules 5\/5/.test(d.body.textContent)&&/Armor modules/.test(d.body.textContent),'armory shows module rows');
E("TAB='research';baseScreen()");check(d.querySelectorAll('.rtree .rbr').length===5,'research tab shows 5 branches');
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0)})();

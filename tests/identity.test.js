// Bucket 1 squad identity: armor pips, voices, nicknames, Padawan pairing. Fast jsdom checks.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
const story=()=>{for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else if(q('[data-role]'))q('[data-role]').click();else return}};
(async()=>{
d.querySelector('[data-d="normal"]').click();story();E('ensureTemple()');
// Voices
check(E("C.roster.every(r=>VOICES[r.voice]&&VOICES[r.voice].who===(isJedi(r)?'jedi':'troop'))"),'every unit has a voice that fits Jedi/trooper');
check(E("new Set(C.roster.filter(r=>!isJedi(r)).map(r=>r.voice)).size")>=Math.min(4,E("C.roster.filter(r=>!isJedi(r)).length")),'troopers get different voices');
E("startMission('relay',C.roster.slice(0,4).map(battleUnit),{diff:'normal',map:0})");
// Armor pips: 1 pip per attack, hazards ignore armor
E("var T={n:'T',side:'p',x:0,y:0,hp:10,max:10,armor:2,status:'ok'},X={n:'X',side:'e',x:1,y:0,hp:5,max:5,status:'ok'};S.units.push(T,X)");
E("damage(T,4,X)");check(E('T.hp')===7&&E('T.armor')===1&&E('T.armorMax')===2,'armor: hit cut by 1 and strips a pip (10→7, 2→1 pips)');
E("damage(T,4,X)");E("damage(T,4,X)");check(E('T.hp')===0&&E('T.armor')===0,'armor breaks after 2 hits, then raw damage');
E("var tzHz={n:'HZ',side:'p',x:2,y:2,hp:6,max:6,armor:1,status:'ok'};S.units.push(tzHz);damage(tzHz,2)");check(E('tzHz.armor')===1&&E('tzHz.hp')===4,'hazard damage ignores armor');
check(E("armorPips({armor:1,armorMax:3})").split('class="on"').length-1===1,'pips show 1 lit of 3');
// Nicknames
E("var A=C.roster.find(r=>!isJedi(r));A.deeds={crit:3,clutch:1};A.nick=null");
check(E("nickOpts(A).map(o=>o.n).join()").startsWith('Deadeye,Lucky'),'deeds suggest Deadeye then Lucky');
E("setNick(A.id,'Deadeye')");check(E("battleUnit(A).nick")==='“Deadeye”'&&E("fullName(A)").includes('Deadeye'),'nickname reaches the battle card');
E("var J=C.roster.find(r=>isJedi(r));J.deeds={cap:3};J.nick=null");check(E("nickOpts(J)[0].n")==='the Merciful','Jedi earn epithets');
// Promotion offers a name in the debrief
E("lastDeb=[true,'test',{res:{},rows:[],promo:[A.id],said:[{rid:A.id,txt:'Clean.',rank:3}]}];A.status='active';debrief(...lastDeb)");
check(!!d.querySelector(`[data-nick="${E('A.id')}"]`),'promotion shows nickname choices');
check(d.querySelector('#modal').textContent.includes('Clean.'),'debrief quotes a line from the mission');
d.querySelector(`[data-nick="${E('A.id')}"][data-v]`).click();check(!!E('A.nick'),'clicking a suggestion sets the nickname');
// Padawan pairing + battle bonus
E("var M=C.roster.find(r=>isJedi(r));M.title='Knight';M.rank=4;M.status='active';var P={...M,id:'u999',n:'Pad Test',title:'Padawan',rank:1};C.roster.push(P);C.pairs={};C.pairNo={};for(const r of C.roster)if(r!==P&&r.title==='Padawan')C.pairNo[r.id]=1;ensureTemple()");
check(E("C.pairs[P.id]")===E('M.id'),'new Padawan is paired with a free Knight');
E("var pu=battleUnit(P),mu=battleUnit(M);pu.side=mu.side='p';pu.status=mu.status='ok';pu.x=3;pu.y=3;mu.x=4;mu.y=3;pu.uid=901;mu.uid=902;S.units.push(pu,mu)");
check(E("masterNear(pu)")===10&&E('pu.masterN')===E('M.n'),'Padawan near Master: +10 aim');
E("mu.x=12;mu.y=12");check(E("masterNear(pu)")===0,'no bonus when the Master is far');
E("setPair(P.id,'');ensureTemple()");check(!E("C.pairs[P.id]"),'choosing None is respected');
check(!errs.length,'no page errors'+(errs.length?': '+errs.join(' | '):''));
console.log(JSON.stringify({fail,err:errs.length}));process.exit(fail||errs.length?1:0)})();

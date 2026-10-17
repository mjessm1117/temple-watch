// Chat I systems: Darkness reduction (Gardens, mentors, mercy, redemption), field ops, galaxy map. Fast unit-style checks in jsdom.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}else console.log('ok   '+msg)};
const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
const E=s=>w.eval(s);
const story=()=>{for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[0].click();else if(q('[data-role]'))q('[data-role]').click();else return}};
d.querySelector('[data-d="normal"]').click();story();
// Galaxy map
check(d.querySelectorAll('g[data-pin]').length>=2,'galaxy map shows mission + field op pins');
check(!!d.querySelector('[data-act="squad:0"]'),'briefing panel has Choose squad');
d.querySelector('.greg[data-reg="core"]').dispatchEvent(new w.MouseEvent('click',{bubbles:true}));check(E('GAL.reg')==='core'&&/Core Worlds/.test(d.querySelector('.gpanel').textContent),'region click shows region card');
check(E("['Low','Moderate','High','Severe'].includes(riskOf(MISSIONS.relay,'relay').n)"),'risk rating computes');
// Gardens: a meditating Jedi sheds Darkness by Gardens level each month
E("C.wings.gardens=2;var K=C.roster.find(r=>r.n==='Kira Venn');K.dark=5;K.stress=0;assign(K.id,'calm');templeMonth()");
check(E('K.dark')===3,'Gardens L2: −2 Darkness a month');
E("templeAdvance()");check(E("K.assign")==='calm','meditating Jedi with Darkness stays in the Gardens');
// Mentor: low-Darkness counsel pulls down, a dark one pulls up
E("var T=C.roster.find(r=>r.n==='Tor Saalen');T.dark=4;K.dark=0;K.rank=4;K.assign=null;C.pairs={};C.pairs[T.id]=K.id;templeMonth()");check(E('T.dark')===3,'Master at Darkness 0 pulls the Padawan down 1');
E("K.dark=8;T.dark=2;templeMonth()");check(E('T.dark')===3,'Master at Darkness 8 pulls the Padawan up 1');
// Redemption option at Darkness 6+
E("K.dark=7;K.status='active';C.redeem={};var st=PLAN.findIndex(p=>p.crises);var opts=optionsFor(st);var ro=opts.find(o=>o.redeem)");
check(E('!!ro&&ro.redeem===K.id'),'redemption mission offered at Darkness 7');
E("var out={res:{},rows:[],promo:[],prog:[],bonds:[]};redeemResult(ro,true,out)");check(E('K.dark')===3,'redemption win: Darkness −4');
check(E('optionsFor(st).every(o=>!o.redeem)'),'one redemption per Jedi per era');
// Mercy: subdue a surrendered foe in battle
E("C.options=optionsFor(C.step);launchMission(0,defaultSquad(C.options[0]))");
E("var J=S.units.find(u=>u.jedi&&u.side==='p');J.dark=4;var F=S.units.find(u=>u.side==='e');F.status='surrender';F.x=J.x+1;F.y=J.y;AB.subdue.run(J,{t:F,chance:100})");
check(E('J.dark')===3,'sparing a surrendered foe: mercy −1 Darkness');
E("var A=S.units.find(u=>u.side==='p'&&u!==J);A.hp=1;J.mercy=0;J.mercyOff=0;J.focus=4;AB.forceHeal&&J.abil.includes('forceHeal')");
// Field ops: send, time passes, resolves with a report, units come home
E("S=null;ensureField();C.field.list=[{id:'fz',k:'convoy',planet:'Taris',st:'open',exp:30}];FTEAM=C.roster.filter(fit).slice(0,2).map(r=>r.id);var sent=sendField('fz')");
check(E('sent&&C.field.list[0].st==="team"'),'field op team sent');check(E("C.roster.filter(r=>r.assign==='field:fz').length")===2,'team marked away');
check(E("!fit(C.roster.find(r=>r.assign==='field:fz'))"),'team away cannot deploy');
E("C.field.list[0].fresh=0;var n0=C.field.log.length;fieldAdvance()");check(E("C.field.log.length")===E('n0')+1&&E("C.roster.filter(r=>r.assign==='field:fz').length")===0,'field op resolves, report logged, team home');
check(E("fieldOdds('pirates',[]).ch")===0&&E("fieldOdds('convoy',C.roster.slice(0,3).map(r=>r.id)).ch")>40,'field odds');
// Region Unrest + Sith op pins
E("C.unrest=null;ignoreCrisis({n:'X',mission:'rescue'})");check(E("unrestOf('mid')")===1,'ignored crisis raises Unrest in its region');
E("C.unrest.r.mid=4;C.news=[];templeMonth()");check(E("C.news.some(n=>/Unrest in/.test(n))"),'Unrest 4+ costs Senate Favor at month end');
E("C.unrest.r.mid=3;C.options=optionsFor(C.step);var rix=C.options.findIndex(o=>regionOf(MISSIONS[o.mission].where)==='mid');if(rix>=0)launchMission(rix,defaultSquad(C.options[rix]))");
check(E("rix<0||S.unrestAim===5"),'hostile region: enemies +5 aim');
E("S=null;C.ops.list.push({id:'opz',k:'snipers',st:'open'});baseScreen()");check(!!d.querySelector('g[data-pin="sopz"]'),'Sith op shows as a pin');
// Two fronts: front A plays without time passing, front B gets 4 slots and excludes A's squad, then time passes once.
E("S=null;C.twin=null;C.wings.barracks=2;var ts=twinSteps();C.step=ts[0];C.options=optionsFor(C.step).filter(o=>o.adv);for(let i=0;i<6;i++)addTroop();for(const r of C.roster){r.wound=0;r.assign=null;r.status='active'}");
check(E('twinOpen()'),'twin step opens with Barracks 2 and 8+ fit units');
E("var d0=C.month*30+C.day,s0=C.step,ida=defaultSquad(C.options[0]);launchMission(0,ida);missionOver(true,'test')");
check(E("twinB()&&C.step===s0&&C.month*30+C.day===d0"),'after front A: front B open, no time passed');
check(E("squadRule().max")===4&&E("defaultSquad(C.options[0]).every(id=>!ida.includes(id))"),'front B: 4 slots, front A squad excluded');
d.querySelector('#toBase').click();story();check(!!d.querySelector('.twin.b')&&!!d.querySelector('[data-act="standdown"]'),'galaxy shows the front B banner');
E("launchMission(0,defaultSquad(C.options[0]));missionOver(false,'test')");
check(E("!C.twin&&C.step===s0+1&&C.month*30+C.day===d0+DAYS"),'after front B: one step, time passed once');
d.querySelector('#toBase').click();
E("C.step=ts[1];C.options=optionsFor(C.step).filter(o=>o.adv&&!o.hostages);for(const r of C.roster){r.wound=0;r.assign=null}launchMission(0,defaultSquad(C.options[0]));missionOver(true,'t')");
check(E("twinB()"),'second twin step opens');E("var s1=C.step;autoFront(0)");check(E("!C.twin&&C.step===s1+1"),'auto-resolve front B finishes the step');
// Risk is rated against the squad you'd send
E("var rk0=riskOf(MISSIONS.relay,'relay').T;for(const r of C.roster)r.rank=Math.min(7,r.rank+3);var rk1=riskOf(MISSIONS.relay,'relay').T");
check(E('rk1<rk0'),'stronger squad lowers mission risk');check(E("riskOf(MISSIONS.dock,'dock').T>riskOf(MISSIONS.relay,'relay').T"),'era boss rates riskier than the opening relay');
check(errs.length===0,'no page errors '+(errs[0]||''));
console.log(JSON.stringify({err:errs.length}));process.exit(fail?1:0);

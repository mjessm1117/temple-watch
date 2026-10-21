// Era 3 (High Republic): plays Era 3 through the real screens with the test bot. Run 0 plays Era 2 first (via startEra(2)) and takes the
// "Continue to the High Republic" button; the rest jump straight in with startEra(3). Checks the era jump, the 3-Act plan (232 → 230 BBY), one-year
// Years pass, Wayseeker unlock, save/reload, the Era 4 hand-off record, codex lore, Ruusan echo events, foe behaviors, and that a new campaign gets Era 1 back.
// RUNS (default 3) and FULL=0 (skip the Era 2 play-through) for quick runs.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace(/const sleep=ms=>[^\n]*?;\n/,'const sleep=()=>Promise.resolve();\n');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');
const story=(d,g)=>{for(let k=0;k<16;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);
 if(q('#scOk'))q('#scOk').click();else if(q('#jumpOk'))q('#jumpOk').click();else if(ch.length)ch[g%ch.length].click();else if(q('[data-role]'))q('[data-role]').click();else if(q('#yrOk')&&!q('#yrOk').disabled)q('#yrOk').click();else return}};
let fail=0;const check=(ok,m)=>{if(!ok){console.log('FAIL '+m);fail++}};
async function playEra(w,d,g){const ms=[];for(let m=0;m<60&&(story(d,g),w.eval('C.options.length'));m++){
  for(const p of d.querySelectorAll('[data-act^="pick:"]'))if(p.isConnected)p.click();
  const oi=g%2&&w.eval('C.options.length')>1?1:0;d.querySelector(`button[data-pin="o${oi}"]`).click();d.querySelector(`[data-act="squad:${oi}"]`).click();d.querySelector('#deploy').click();
  if(!w.eval('S&&!S.over')){check(false,'mission did not start');break}const id=w.eval('S.id');
  for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
  check(w.eval('S.over'),'mission ended');ms.push(id+(w.eval('S.win')?'+':'-'));d.querySelector('#toBase').click()}return ms}
const win=()=>new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window;
(async()=>{
 // Static checks: lore for every Era 3 mission and foe, plan shape, Wayseeker lock, events gated by era and Ruusan outcome.
 {const w=win();
  const miss=w.eval(`[...PLAN3.filter(p=>p.story).map(p=>p.story),...PLAN3.flatMap(p=>p.crises||[]).map(c=>CRISES[c].mission)].filter(id=>!(CODEX.mission[id]&&CODEX.mission[id].lore))`);
  check(!miss.length,'codex lore for missions: '+miss.join());
  const foes=w.eval(`Object.keys(ERA3_LORE.enemy).filter(id=>!FOES[id]||!CODEX.enemy[id].lore||!FOES[id].desc)`);check(!foes.length,'foe desc/lore: '+foes.join());
  check(w.eval('PLAN3.filter(p=>p.story||p.crises).length')===12&&w.eval('PLAN3.filter(p=>p.years).length')===2,'12 missions, 2 Years pass');
  check(w.eval("CLASS.Wayseeker.lockEra")===3,'Wayseeker locked to Era 3');
  check(w.eval("PLAN3.filter(p=>p.story).every(p=>MISSIONS[p.story].era===3)&&MISSION_LORE.h_beacon[0]==='starlight'"),'story missions tagged era 3');
  w.document.querySelector('[data-d="normal"]').click();
  check(!w.eval("xtrainClasses({cls:'Guardian',jedi:1,title:'Knight'}).includes('Wayseeker')"),'no Wayseeker in Era 1');
  w.eval("C.flags.rule_of_two=1");w.eval('startEra(3)');w.document.querySelector('#jumpOk').click();
  check(w.eval("C.era")===3&&w.eval("C.story.bby")===232,'Era 3 starts at 232 BBY');
  check(w.eval("C.roster.some(r=>r.cls==='Wayseeker')"),'Era 3 squad has a Wayseeker');
  check(w.eval("Object.keys(CLASS).filter(k=>CLASS[k].jedi&&(CLASS[k].lockEra||0)<=C.era).includes('Wayseeker')"),'Wayseeker unlocked in Era 3');
  check(w.eval("trig(EVENTS.find(e=>e.id==='e3_bane_line').trigger)")&&!w.eval("trig(EVENTS.find(e=>e.id==='e3_bane_vault').trigger)"),'Ruusan echo events follow Bane flags');
  check(!w.eval("EVENTS.filter(e=>(e.trigger.era||1)!==3).some(e=>e.trigger.type==='era_start'&&trig(e.trigger))"),'other eras\' events stay out of Era 3');
  check(w.eval("ensureLife(),members().map(m=>m.id).join()")==='veter,gios','Era 3 Council seats');
  check(w.eval("eraLabel()").includes('High Republic'),'era label');
  // Foe behaviors on a live map: Path-Runners start hidden, Dread and Choke show in the odds.
  w.eval(`startMission('h_valo',C.roster.slice(0,6).map(battleUnit),{diff:C.diff})`);
  w.eval(`S.units.push(mkFoe('path_runner',0,0));S.units.push(mkFoe('nameless',5,5))`);const j=w.eval("players().find(p=>p.jedi)");
  w.eval(`{const j=players().find(p=>p.jedi),n=enemies().find(e=>e.type==='nameless');j.x=5;j.y=7;j.choke=S.turn}`);
  const L=w.eval(`odds(players().find(p=>p.jedi),enemies().find(e=>e.type==='nameless')).lines.map(l=>l[0]).join()`);
  check(/Dread/.test(L)&&/Choking gas/.test(L),'Dread and Choking gas in the odds: '+L);
  w.close()}
 for(let g=0;g<(+process.env.RUNS||3);g++){const w=win(),d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
  try{w.eval(bot);d.querySelector('[data-d="normal"]').click();story(d,g);
   if(g===0&&process.env.FULL!=='0'){w.eval('startEra(2)');await playEra(w,d,g);check(!!d.querySelector('#nextEra3'),'Era 2 end offers the High Republic');d.querySelector('#nextEra3').click();
    check(!!w.eval("C.eras.find(e=>e.era===2)"),'Era 2 record kept')}
   else w.eval('startEra(3)');
   check(w.eval('C.era')===3&&w.eval('PLAN.length')===w.eval('PLAN3.length'),'Era 3 plan in place');check(!!d.querySelector('#jumpOk'),'era jump screen');
   const ms=await playEra(w,d,g);
   check(w.eval('C.step')===w.eval('PLAN.length'),'Era 3 finished');check(/Era 3 ends/.test(d.body.innerHTML),'Era 3 end screen');
   check(w.eval('C.story.bby')===230,'Era 3 ends at 230 BBY (one-year jumps)');
   const rec=w.eval('JSON.stringify(C.eras.find(e=>e.era===3)||null)');check(rec&&/"beacon":"(saved|fell)"/.test(rec),'Era 4 record');
   check(w.eval("['e3_beacon_saved','e3_beacon_fell'].filter(k=>C.flags[k]).length")===1,'one Starlight outcome flag');
   w.eval('usePlan(1);continueGame(loadSave())');check(w.eval('PLAN.length')===w.eval('PLAN3.length')&&w.eval("PLAN[PLAN.length-1].story")==='h_beacon','reload keeps the Era 3 plan');
   console.log(JSON.stringify({ms,shadow:w.eval('C.story.shadow'),rec:JSON.parse(rec),save:w.eval('JSON.stringify(saveData()).length')}));
   d.querySelector('#restart').click();d.querySelector('[data-d="normal"]').click();check(w.eval('(C.era||1)===1&&PLAN[PLAN.length-1].story')==='dock','new campaign restores Era 1')}
  catch(e){errs.push(e.stack)}if(errs.length){fail++;console.log('FAIL',errs[0])}w.close()}
 process.exit(fail?1:0)})();

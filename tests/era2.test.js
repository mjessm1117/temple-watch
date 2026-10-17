// Era 2 (Ruusan): plays Era 2 through the real screens with the test bot. Run 0 plays Era 1 first and takes the "next era" button;
// the rest jump straight in with startEra(2). Checks the era jump, the 3-Act plan, Years pass, save/reload, Era 3 hand-off record, codex lore,
// the Hoth/Johun event chain, and that a new campaign gets Era 1 back. RUNS (default 3) and FULL=0 (skip the Era 1 play-through) for quick runs.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace(/const sleep=ms=>[^\n]*?;\n/,'const sleep=()=>Promise.resolve();\n');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');
// Clears story screens (shards, events, Years pass, era jump) with varied choices.
const story=(d,g)=>{for(let k=0;k<16;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);
 if(q('#scOk'))q('#scOk').click();else if(q('#jumpOk'))q('#jumpOk').click();else if(ch.length)ch[g%ch.length].click();else if(q('[data-role]'))q('[data-role]').click();else if(q('#yrOk')&&!q('#yrOk').disabled)q('#yrOk').click();else return}};
let fail=0;const check=(ok,m)=>{if(!ok){console.log('FAIL '+m);fail++}};
async function playEra(w,d,g){const ms=[];for(let m=0;m<60&&(story(d,g),w.eval('C.options.length'));m++){
  for(const p of d.querySelectorAll('[data-act^="pick:"]'))if(p.isConnected)p.click();
  const oi=g%2&&w.eval('C.options.length')>1?1:0;d.querySelector(`button[data-pin="o${oi}"]`).click();d.querySelector(`[data-act="squad:${oi}"]`).click();d.querySelector('#deploy').click();
  if(!w.eval('S&&!S.over')){check(false,'mission did not start');break}const id=w.eval('S.id');
  for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
  check(w.eval('S.over'),'mission ended');ms.push(id+(w.eval('S.win')?'+':'-'));d.querySelector('#toBase').click()}return ms}
(async()=>{
 // Static checks: every Era 2 mission and foe has codex lore; the plan has 12 mission steps in 3 Acts.
 {const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window;
  const miss=w.eval(`[...PLAN2.filter(p=>p.story).map(p=>p.story),...PLAN2.flatMap(p=>p.crises||[]).map(c=>CRISES[c].mission)].filter(id=>!(CODEX.mission[id]&&CODEX.mission[id].lore))`);
  check(!miss.length,'codex lore for missions: '+miss.join());
  const foes=w.eval(`Object.keys(ERA2_LORE.enemy).filter(id=>!FOES[id]||!CODEX.enemy[id].lore||!FOES[id].desc)`);check(!foes.length,'foe desc/lore: '+foes.join());
  check(w.eval('PLAN2.filter(p=>p.story||p.crises).length')===12&&w.eval('PLAN2.filter(p=>p.years).length')===2,'12 missions, 2 Years pass');
  // Johun is rare: saved in the ravine AND Hoth trusts you (≥70).
  w.document.querySelector('[data-d="normal"]').click();w.eval('startEra(2)');w.document.querySelector('#jumpOk').click();
  check(!w.eval("EVENTS.filter(e=>e.id==='e2_hoth_student').some(e=>trig(e.trigger))"),'Johun event locked at start');
  w.eval("C.flags.e2_johun_saved=1;C.story.loyal.hoth=70");check(w.eval("trig(EVENTS.find(e=>e.id==='e2_hoth_student').trigger)"),'Johun event unlocks');
  check(!w.eval("EVENTS.filter(e=>e.trigger.era!==2).some(e=>e.trigger.type==='era_start'&&trig(e.trigger))"),'Era 1 events stay out of Era 2');
  check(w.eval("ensureLife(),members().map(m=>m.id).join()")==='hoth,farfalla','Era 2 Council seats');w.close()}
 for(let g=0;g<(+process.env.RUNS||3);g++){const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document,errs=[];w.addEventListener('error',e=>errs.push(e.message));
  try{w.eval(bot);d.querySelector('[data-d="normal"]').click();story(d,g);
   if(g===0&&process.env.FULL!=='0'){await playEra(w,d,g);check(!!d.querySelector('#nextEra'),'Era 1 end offers the next era');d.querySelector('#nextEra').click()}
   else w.eval('startEra(2)');
   check(w.eval('C.era')===2&&w.eval('PLAN.length')===PLAN2Len(w),'Era 2 plan in place');check(!!d.querySelector('#jumpOk'),'era jump screen');
   const ms=await playEra(w,d,g);
   check(w.eval('C.step')===w.eval('PLAN.length'),'Era 2 finished');check(/Era 2 ends/.test(d.body.innerHTML),'Era 2 end screen');
   check(w.eval('C.story.bby')===1000,'Era 2 ends at 1,000 BBY');
   const rec=w.eval('JSON.stringify(C.eras.find(e=>e.era===2)||null)');check(rec&&/"bane":"(dead|captured|escaped)"/.test(rec),'Era 3 record');
   check(w.eval("['e2_bane_dead','e2_bane_captured','e2_bane_escaped'].filter(k=>C.flags[k]).length")===1,'one Bane outcome flag');
   // Reload: a fresh page gets Era 2 back from the save.
   w.eval('usePlan(1);continueGame(loadSave())');check(w.eval('PLAN.length')===PLAN2Len(w),'reload keeps the Era 2 plan');
   console.log(JSON.stringify({ms,shadow:w.eval('C.story.shadow'),rec:JSON.parse(rec),save:w.eval('JSON.stringify(saveData()).length')}));
   d.querySelector('#restart').click();d.querySelector('[data-d="normal"]').click();check(w.eval('(C.era||1)===1&&PLAN[PLAN.length-1].story')==='dock','new campaign restores Era 1')}
  catch(e){errs.push(e.stack)}if(errs.length){fail++;console.log('FAIL',errs[0])}w.close()}
 process.exit(fail?1:0)})();
function PLAN2Len(w){return w.eval('PLAN2.length')}

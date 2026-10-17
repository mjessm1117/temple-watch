// Plays the whole v0.2a campaign slice through the real screens with the test bot. Checks the loop, economy and save size.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');
// Story screens (vision shard, Council events, Years pass) sit between hub visits; the bot clears them with varied choices.
const story=(d,g)=>{for(let k=0;k<12;k++){const q=s=>d.querySelector(s),ch=[...d.querySelectorAll('[data-ch]')].filter(b=>!b.disabled);
 if(q('#scOk'))q('#scOk').click();else if(ch.length)ch[g%ch.length].click();else if(q('[data-role]'))q('[data-role]').click();else if(q('#yrOk')&&!q('#yrOk').disabled)q('#yrOk').click();else return}};
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}};const sum={runs:0,err:0,finished:0,credits:0,rank3:0,maxSave:0,missions:0,field:0,fieldDone:0};
(async()=>{for(let g=0;g<(+process.env.CAMPAIGNS||4);g++){const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
 try{w.eval(bot);d.querySelector('[data-d="normal"]').click();if(g===0)check(w.eval('C.res.credits')===300,'start credits 300');story(d,g);const cr0=w.eval('C.res.credits');
  if(g===0){check(!!d.querySelector('[data-act="squad:0"]'),'base screen shows a mission');
   d.querySelector('[data-act="build:training"]').click();check(w.eval('C.build')==='training','build queued');check(w.eval('C.res.credits')===cr0-150,'build paid')}
  for(let m=0;m<60&&(story(d,g),w.eval('C.options.length'));m++){
   const b=d.querySelector('[data-act="hire"]');if(g%2&&b&&!b.disabled)b.click();
   for(const p of d.querySelectorAll('[data-act^="pick:"]'))if(p.isConnected)p.click();
   // Galaxy map: odd runs send a field op team when one is open, then every run picks a pin and opens its squad screen.
   const fp=d.querySelector('g[data-pin^="ff"]');if(g%2&&fp&&w.eval("C.field.list.some(o=>o.st==='open')")&&w.eval('C.roster.filter(fit).length')>=6){fp.dispatchEvent(new w.MouseEvent('click',{bubbles:true}));
    for(let k=0;k<2;k++){const L=[...d.querySelectorAll('[data-act^="fop:"]:not(.on)')];if(L.length)L[L.length-1].click()}const s2=d.querySelector('[data-act^="fsend:"]');if(s2&&!s2.disabled){s2.click();sum.field++}}
   const oi=g%2&&w.eval('C.options.length')>1?1:0;const pb=d.querySelector(`button[data-pin="o${oi}"]`);if(!pb)console.log("NOPIN",oi,w.eval("JSON.stringify(C.options.map(o=>o.mission))"),d.querySelector("#modal").innerHTML.slice(0,400));pb.click();
   d.querySelector(`[data-act="squad:${oi}"]`).click();d.querySelector('#deploy').click();
   if(!w.eval("S&&!S.over")){console.log("not started", w.eval("JSON.stringify({step:C.step,fit:C.roster.filter(fit).length,pick:pickSquad})"));fail++;break}sum.maxSave=Math.max(sum.maxSave,w.eval('JSON.stringify(saveData()).length'));
   for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
   check(w.eval('S.over'),'mission ended');sum.missions++;d.querySelector('#toBase').click()}
  const end=w.eval('PLAN.length');check(w.eval('C.step')===end,'reached the end of the era');sum.finished+=w.eval('C.step')===end?1:0;
  check(!!d.querySelector('#restart'),'end screen shows');sum.credits+=w.eval('C.res.credits');sum.fieldDone+=w.eval('C.field.log.length');sum.rank3+=w.eval("C.roster.filter(r=>r.rank>=3).length");
  if(g===0){check(w.eval('loadSave().C.step')===w.eval('PLAN.length'),'campaign saved locally');check(w.eval('C.month')>=2,'calendar advanced')}}
 catch(e){errs.push(e.stack)}
 sum.runs++;if(errs.length){sum.err++;fail++;console.log(errs[0])}w.close()}
 sum.credits=Math.round(sum.credits/sum.runs);sum.rank3=+(sum.rank3/sum.runs).toFixed(1);console.log(JSON.stringify(sum));
 check(sum.maxSave<100000,'save stays under 100 KB');process.exit(fail?1:0)})();

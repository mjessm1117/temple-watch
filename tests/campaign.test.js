// Plays the whole v0.2a campaign slice through the real screens with the test bot. Checks the loop, economy and save size.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');
let fail=0;const check=(ok,msg)=>{if(!ok){console.log('FAIL '+msg);fail++}};const sum={runs:0,err:0,finished:0,credits:0,rank3:0,maxSave:0,missions:0};
(async()=>{for(let g=0;g<8;g++){const w=new JSDOM(html,{runScripts:'dangerously',url:'https://tw.test/'}).window,d=w.document;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
 try{w.eval(bot);d.querySelector('[data-d="normal"]').click();
  if(g===0){check(!!d.querySelector('[data-act="squad:0"]'),'base screen shows a mission');check(w.eval('C.res.credits')===300,'start credits 300');
   d.querySelector('[data-act="build:training"]').click();check(w.eval('C.build')==='training','build queued');check(w.eval('C.res.credits')===150,'build paid')}
  for(let m=0;m<10&&w.eval('C.options.length');m++){
   const b=d.querySelector('[data-act="hire"]');if(g%2&&b&&!b.disabled)b.click();
   for(const p of d.querySelectorAll('[data-act^="pick:"]'))if(p.isConnected)p.click();
   d.querySelector(`[data-act="squad:${g%2&&w.eval('C.options.length')>1?1:0}"]`).click();d.querySelector('#deploy').click();
   if(!w.eval("S&&!S.over")){console.log("not started", w.eval("JSON.stringify({step:C.step,fit:C.roster.filter(fit).length,pick:pickSquad})"));fail++;break}sum.maxSave=Math.max(sum.maxSave,w.eval('JSON.stringify(saveData()).length'));
   for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
   check(w.eval('S.over'),'mission ended');sum.missions++;d.querySelector('#toBase').click()}
  check(w.eval('C.step')===3,'reached the end of the slice');sum.finished+=w.eval('C.step')===3?1:0;
  check(!!d.querySelector('#restart'),'end screen shows');sum.credits+=w.eval('C.res.credits');sum.rank3+=w.eval("C.roster.filter(r=>r.rank>=3).length");
  if(g===0){check(w.eval('loadSave().C.step')===3,'campaign saved locally');check(w.eval('C.month')>=2,'calendar advanced')}}
 catch(e){errs.push(e.stack)}
 sum.runs++;if(errs.length){sum.err++;fail++;console.log(errs[0])}w.close()}
 sum.credits=Math.round(sum.credits/sum.runs);sum.rank3=+(sum.rank3/sum.runs).toFixed(1);console.log(JSON.stringify(sum));
 check(sum.maxSave<100000,'save stays under 100 KB');process.exit(fail?1:0)})();

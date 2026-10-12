// Plays bot games on every v0.2a mission (Normal). Prints win rate per mission; any "err" > 0 is a bug.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');
const N=+process.env.GAMES||10,diff=process.env.DIFF||'normal';let fail=0;
(async()=>{for(const id of ['relay','shrine','rescue','envoy']){const res={mission:id,win:0,lose:0,err:0,dead:0,turns:0};
 for(let g=0;g<N;g++){const w=new JSDOM(html,{runScripts:'dangerously'}).window;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
  try{w.eval(bot);w.eval(`startMission('${id}',START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r})),{diff:'${diff}'})`);
   for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
   if(!w.eval('S.over'))errs.push('mission never ended');}catch(e){errs.push(e.stack)}
  if(errs.length){res.err++;console.log(id,errs[0])}
  res[w.eval('S.win')?'win':'lose']++;res.turns+=w.eval('S.turn');res.dead+=w.eval("S.units.filter(u=>u.side==='p'&&u.status==='dead').length");w.close()}
 res.turns=+(res.turns/N).toFixed(1);if(res.err)fail++;console.log(JSON.stringify(res))}
 process.exit(fail?1:0)})();

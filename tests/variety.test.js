// Battle variety (battle.js): every twist and every story signature plays bot games with 0 errors; signature tiles get placed;
// decisions resolve; twists respect themes. RUNS games per case (default 2).
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');const N=+process.env.RUNS||2;let fail=0;const check=(ok,m)=>{if(!ok){console.log('FAIL '+m);fail++}};
const w0=new JSDOM(html,{runScripts:'dangerously'}).window;
const st=w0.eval(`({sig:Object.keys(SIG).filter(k=>!MISSIONS[k]),tw:Object.keys(TWISTS),
 badTheme:Object.keys(MISSIONS).filter(id=>{const th=MISSIONS[id].theme||THEME_OF[id]||'plains';for(let i=0;i<30;i++){const t=TWISTS[rollTwist(id)];if(t.themes&&!t.themes.includes(th))return true}return false}),
 story:Object.keys(SIG)})`);w0.close();
check(!st.sig.length,'SIG for unknown missions: '+st.sig);
// Biome hazards: every map variant places its theme's hazards (20 tries each), never cuts the squad off from evac, never on a start tile.
{const w1=new JSDOM(html,{runScripts:'dangerously'}).window;if(w1.eval("typeof HAZARDS")!=='undefined'){
 const hz=w1.eval(`(()=>{const bad=[],sq=()=>START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r}));let n=0;
  for(const [id,B] of Object.entries(MISSIONS))for(let mi=0;mi<=(B.alts||[]).length;mi++)for(let k=0;k<20;k++){startMission(id,sq(),{map:mi,twist:'none'});
   if(!S.bv.hz)continue;n++;const Z=HAZARDS[S.bv.hz];if(!S.grid.flat().some(c=>Z.tiles.includes(c)))bad.push(id+'#'+mi+' none placed');if(!hzReach())bad.push(id+'#'+mi+' evac cut');
   if(players().some(u=>TILES[tile(u.x,u.y)].hurt))bad.push(id+'#'+mi+' unit on hazard')}
  // Mechanics on a clean floor: ice slides up to 3 tiles, lava hurts 3, mud can't be crossed, conduits pulse.
  startMission('relay',sq(),{twist:'none',hazards:false});S.bv.hz='snow';const u=players()[0];S.units=S.units.filter(o=>o===u);for(let x=0;x<10;x++)S.grid[3][x]=x>=3&&x<=6?'i':'.';
  u.x=1;u.y=3;moveAlong(u,[{x:2,y:3},{x:3,y:3}]);if(u.x!==6)bad.push('ice slide ended at '+u.x);
  const hp=u.hp;S.grid[3][8]='l';moveAlong(u,[{x:8,y:3}]);if(u.hp!==hp-3)bad.push('lava hp '+hp+'→'+u.hp);
  S.grid[5][1]='m';S.grid[4][1]='.';S.grid[6][1]='.';u.x=1;u.y=6;u.mob=5;const R=reach(u);if(R.d['1,4']!=null&&R.prev['1,4']==='1,5')bad.push('walked through mud');
  S.turn=1;if(hzLive('n'))bad.push('conduit live on odd turn');S.turn=2;if(!hzLive('n'))bad.push('conduit dead on even turn');
  return{bad,n}})()`);w1.close();check(!hz.bad.length,'hazards: '+hz.bad.slice(0,5).join(', '));console.log(JSON.stringify({hazardMaps:hz.n}))}else w1.close()}
check(!st.badTheme.length,'twist rolled off-theme: '+st.badTheme);
const cases=[...st.tw.map(t=>[{sandstorm:'relay',blizzard:'ilum',blackout:'envoy',ionstorm:'rescue',collapse:'archive',ally:'escort'}[t]||'relay',t]),...st.story.map(id=>[id,'none'])];
(async()=>{for(const [id,tw] of cases){const r={id,tw,win:0,err:0,beats:0,picks:0};
 for(let g=0;g<N;g++){const w=new JSDOM(html,{runScripts:'dangerously'}).window;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
  try{w.eval(bot);w.eval(`startMission('${id}',START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r})),{diff:'normal',twist:'${tw}'})`);
   if(g===0){const ok=w.eval(`(()=>{const G=SIG[S.id];if(!G)return true;const b=S.bv;return !!((!G.pads||b.pad.at.length===G.pads.at.length)&&(!G.relic||b.relic)&&(!G.pylons||Object.keys(b.pyl).length===G.pylons.at.length)&&(!G.switches||b.sw.need===G.switches.at.length)&&(!G.wounded||b.wd.length===G.wounded.at.length)&&(!G.runner||b.run)&&(!G.keyholder||b.key)&&(!G.barrage||b.bar.uid!=null))})()`);check(ok,`${id}: signature setup incomplete`);
    check(w.eval(`S.bv.tw===${tw==='none'?'null':`'${tw}'`}`),`${id}: twist ${tw} not applied`)}
   for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}if(!w.eval('S.over'))errs.push('mission never ended');
   check(!w.eval('S.bv.q.length')||w.eval('S.over'),`${id}: decision left open`);r.beats+=w.eval('(S.bv.hist||[]).length');r.picks+=w.eval("(S.bv.hist||[]).filter(t=>t[0]==='→').length")}catch(e){errs.push(e.stack)}
  if(errs.length){r.err++;console.log(id,tw,errs[0])}if(w.eval('S.win'))r.win++;w.close()}
 if(r.err)fail++;console.log(JSON.stringify(r))}
 process.exit(fail?1:0)})();

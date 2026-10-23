// Plays bot games on every mission map variant (Normal). Prints win rate per map; any "err" > 0 is a bug. Also checks every map is legal.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');
const N=+process.env.GAMES||6,diff=process.env.DIFF||'normal';let fail=0;
const w0=new JSDOM(html,{runScripts:'dangerously'}).window,maps=w0.eval(`(()=>{const out=[],bad=[];
 for(const [id,B] of Object.entries(MISSIONS))[B,...(B.alts||[])].forEach((v,i)=>{const M={...B,...v},g=M.map,at=(x,y)=>g[y]&&g[y][x],ok=p=>!!p&&PASS(at(p[0],p[1]));
  out.push([id,i]);const tag=id+'#'+i,need=['rescue','investigate','sabotage','escort'].includes(M.type);
  if(g.length<8||g.some(r=>r.length!==g[0].length))bad.push(tag+' size');for(const r of g)for(const c of r)if(!TILES[c])bad.push(tag+' tile '+c);
  if(M.start.length<6||!M.start.every(ok))bad.push(tag+' start');if(!(M.foes||[]).every(f=>ok([f[1],f[2]])))bad.push(tag+' foe');
  if(M.hostage&&!ok(M.hostage))bad.push(tag+' hostage');if(need&&!g.join('').includes('E'))bad.push(tag+' no evac');
  if(M.type==='sabotage'&&(g.join('').match(/C/g)||[]).length<M.need)bad.push(tag+' charges');
  if(M.type==='investigate'&&(g.join('').match(/q/g)||[]).length<3)bad.push(tag+' clues');
  // Every start tile must reach an evac zone with no units in the way (locked doors count as open).
  if(need){const seen=new Set([M.start[0]+'']),q=[M.start[0]];let hit=0;while(q.length){const [x,y]=q.shift();if(at(x,y)==='E'){hit=1;break}
   for(const [dx,dy] of N4){const nx=x+dx,ny=y+dy,c=at(nx,ny);if(c&&(PASS(c)||'dD'.includes(c))&&!seen.has(nx+','+ny)){seen.add(nx+','+ny);q.push([nx,ny])}}}if(!hit)bad.push(tag+' evac unreachable')}});
 return{out,bad}})()`);w0.close();
// Memory: jsdom games leak, so the parent runs each mission in its own child process (ONLY=<id>). FIRST=1 plays only map 0 of each mission (test:quick).
const ONLY=process.env.ONLY,FIRST=process.env.FIRST==='1';
if(!ONLY){if(maps.bad.length){console.log('FAIL maps:',maps.bad.join(', '));process.exit(1)}
 console.log(`maps ok: ${maps.out.length}`);const {spawnSync}=require('child_process');
 // SHARD=i/n plays every n-th mission (run shards in parallel to fit under time caps); unset = all.
 const [si,sn]=(process.env.SHARD||'0/1').split('/').map(Number);
 for(const id of [...new Set(maps.out.map(m=>m[0]))].filter((_,i)=>i%sn===si)){const r=spawnSync(process.execPath,[__filename],{stdio:'inherit',env:{...process.env,ONLY:id}});if(r.status!==0){fail++;console.log(`FAIL balance child ${id} exit ${r.status}${r.signal?' '+r.signal:''}`)}}
 process.exit(fail?1:0)}
(async()=>{for(const [id,mi] of maps.out.filter(m=>m[0]===ONLY&&(!FIRST||m[1]===0))){const res={mission:id,map:mi,win:0,lose:0,err:0,dead:0,turns:0};
 for(let g=0;g<N;g++){const w=new JSDOM(html,{runScripts:'dangerously'}).window;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
  try{w.eval(bot);w.eval(`startMission('${id}',START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r})),{diff:'${diff}',map:${mi}})`);
   for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
   if(!w.eval('S.over'))errs.push('mission never ended');}catch(e){errs.push(e.stack)}
  if(errs.length){res.err++;console.log(id,errs[0])}
  res[w.eval('S.win')?'win':'lose']++;res.turns+=w.eval('S.turn');res.dead+=w.eval("S.units.filter(u=>u.side==='p'&&u.status==='dead').length");w.close()}
 res.turns=+(res.turns/N).toFixed(1);if(res.err)fail++;console.log(JSON.stringify(res))}
 process.exit(fail?1:0)})();

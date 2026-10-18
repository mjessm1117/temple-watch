// Maps & Tactics (Chat M, wave 5): new map legality, board size, sight angles, overwatch call-outs, entries, operation steps.
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
let fail=0;const ok=(c,m)=>{console.log((c?'ok   ':'FAIL ')+m);if(!c)fail++};
const page=()=>new JSDOM(html,{runScripts:'dangerously'}).window;
const go=(w,id,mi,o='')=>w.eval(`startMission('${id}',START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r})),{diff:'normal',map:${mi},hazards:false${o}})`);
(async()=>{
 // 1. Every new map: rectangular, known tiles, starts/foes/entries on walkable tiles, zones/exits/evac reachable from the start.
 let w=page();const bad=w.eval(`(()=>{const out=[];let n=0;for(const [id,L] of Object.entries(NEW_MAPS))for(const m0 of L){n++;const M={...MISSIONS[id],...m0},g=M.map,t=m0.n,at=(x,y)=>g[y]&&g[y][x],walk=p=>!!p&&PASS(at(p[0],p[1]));
  if(g.some(r=>r.length!==g[0].length))out.push(t+' ragged');for(const r of g)for(const c of r)if(!TILES[c])out.push(t+' tile '+c);
  M.start.forEach(p=>{if(!walk(p))out.push(t+' start '+p)});(M.foes||[]).forEach(f=>{if(!walk([f[1],f[2]]))out.push(t+' foe '+f)});(M.entries||[]).forEach(e=>{if(!walk(e))out.push(t+' entry '+e)});
  const seen=new Set([M.start[0]+'']),q=[M.start[0]];while(q.length){const [x,y]=q.shift();for(const [dx,dy] of N4){const nx=x+dx,ny=y+dy,c=at(nx,ny);if(c&&(PASS(c)||'dD'.includes(c))&&!seen.has(nx+','+ny)){seen.add(nx+','+ny);q.push([nx,ny])}}}
  const R=p=>seen.has(p[0]+','+p[1]);(M.entries||[]).forEach(e=>{if(!R(e))out.push(t+' entry unreachable')});(M.phases||[]).forEach(p=>{if(p.at&&!R(p.at))out.push(t+' zone unreachable');if(p.exit&&!R(p.exit))out.push(t+' exit unreachable')});
  if((M.phases||[]).some(p=>p.k==='extract')||['rescue','investigate','sabotage','escort'].includes(M.type))if(!g.some((r,y)=>[...r].some((c,x)=>c==='E'&&R([x,y]))))out.push(t+' no reachable evac')}
  return {n,out}})()`);ok(!bad.out.length,`${bad.n} new maps legal ${bad.out.join(', ')}`);
 // 2. Board size follows the mission grid.
 const big=w.eval(`(()=>{for(const [id,B] of Object.entries(MISSIONS))for(let i=0;i<(B.alts||[]).length;i++)if(B.alts[i].big)return [id,i+1];})()`);
 go(w,big[0],big[1]);ok(w.eval('W===S.grid[0].length&&H===S.grid.length&&W*H>120'),`board size follows the grid (${w.eval('W')}×${w.eval('H')})`);
 // 3. Angles: a wall right in front blocks the shot; leaning out from a wall end sees past it.
 w.eval(`S.grid=Array.from({length:12},()=>Array(10).fill('.'));for(let x=2;x<=6;x++)S.grid[5][x]='#'`);
 ok(!w.eval('los({x:4,y:6},{x:4,y:1})'),'wall in front blocks sight');
 ok(w.eval('los({x:6,y:6},{x:8,y:1})'),'peek from the wall end sees around it');
 ok(w.eval('los({x:7,y:9},{x:7,y:1})'),'open ground sees');
 // 4. Overwatch fires on a mover and pops an OVERWATCH call-out.
 w=page();go(w,'relay',0);const ow=w.eval(`(()=>{const T=[];onFx((t,d)=>{if(t==='text')T.push(d.txt)});S.grid=Array.from({length:12},()=>Array(10).fill('.'));
  S.units=S.units.filter(u=>u.side==='p').slice(0,1);const p=S.units[0];p.x=5;p.y=10;p.ow=true;p.range=8;const e=mkFoe('trooper',5,2);S.units.push(e);
  moveAlong(e,[{x:5,y:3},{x:5,y:4}]);return {txt:T,ow:p.ow}})()`);
 ok(ow.txt.includes('OVERWATCH')&&ow.ow===false,'overwatch fires on a mover with an OVERWATCH call-out');
 // 5. Entries: waves come from the map's entry points, several sides across a mission.
 w=page();const sh=w.eval(`(()=>{for(let i=0;i<MISSIONS.shrine.alts.length;i++)if(MISSIONS.shrine.alts[i].entries&&MISSIONS.shrine.alts[i].waves)return i+1})()`);go(w,'shrine',sh);
 const used=new Set();for(let i=0;i<6;i++){const e=w.eval('JSON.stringify(pickEntry())');used.add(e)}ok(used.size>=2,`entries rotate (${used.size} used)`);
 // 6. Operation: reach → hold → extract, and a runner that escapes fails the mission.
 w=page();const op=w.eval(`(()=>{for(const [id,B] of Object.entries(MISSIONS))for(let i=0;i<(B.alts||[]).length;i++){const a=B.alts[i];if(a.type==='op'&&a.phases[0].k==='reach'&&a.phases[1].k==='hold')return [id,i+1]}})()`);go(w,op[0],op[1]);
 const r=w.eval(`(()=>{const p=S.M.phases[0],u=players()[0];for(const e of enemies())e.status='dead';u.x=p.at[0];u.y=p.at[1];checkEnd();const a=S.ph.i;
  const h=S.M.phases[1];for(let t=0;t<h.turns;t++){startPlayerTurn()}return [a,S.ph.i,S.over]})()`);
 ok(r[0]===1&&r[1]===2&&!r[2],`reach then hold advance the operation (${r})`);
 w=page();const ch=w.eval(`(()=>{for(const [id,B] of Object.entries(MISSIONS))for(let i=0;i<(B.alts||[]).length;i++){const a=B.alts[i];if(a.type==='op'&&a.phases[0].k==='chase')return [id,i+1]}})()`);go(w,ch[0],ch[1]);
 await w.eval(`(async()=>{const f=byId(S.runner);for(const e of enemies())if(e!==f)e.status='dead';f.x=f.runner.x+1;f.y=f.runner.y;if(!PASS(tile(f.x,f.y))){f.x=f.runner.x;f.y=f.runner.y+1}await eAct(f)})()`);
 ok(w.eval('S.over&&!S.win'),'a runner that reaches the exit fails the operation');
 process.exit(fail?1:0)})();

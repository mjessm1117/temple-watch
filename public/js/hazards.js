/* Biome hazards (Chat H, wave 4 round 2). Data: HAZARDS + hazard tiles in data-battle.js. Loads after battle.js.
   Placement: patches of 2–3 tiles on open floor, away from starts, objectives, evac and units; block tiles never cut the squad off
   from evac. Effects: hurt (enter + round start; pulse = even turns only), slide (keep going, max 3), stop (move ends), block (walk 0).
   Wraps: startMission, moveAlong, reach, push, startPlayerTurn, tileScore (AI avoids hurt tiles). */
const HZ=c=>TILES[c]||{};
const hzLive=c=>{const t=HZ(c);return !!t.hurt&&(!t.pulse||S.turn%2===0)};
const hzSet=()=>S&&S.bv&&HAZARDS[S.bv.hz];

const _hzStart=startMission;
startMission=function(id,sq,o={}){_hzStart(id,sq,o);if(!S.bv)return;const th=S.theme||'plains';
 S.bv.hz=o.hazards===false||(MISSIONS[id]||{}).noHaz?null:HAZARDS[th]?th:null;if(S.bv.hz)hzPlace(HAZARDS[th]);render();saveGame()};
function hzPlace(Z){const keep=[...S.units.filter(u=>alive(u)),...tilesWhere(c=>'OEkqCDbHTPLUG'.includes(c))];
 const free=(x,y)=>S.grid[y][x]==='.'&&!keep.some(k=>cheb(k,{x,y})<=1);let put=0;
 for(let p=0,tries=0;p<Z.patches&&tries<40;tries++){const C=tilesWhere((c,x,y)=>free(x,y)&&y>=2);if(!C.length)break;
  const s=pickOne(C),ch=pickOne(Z.tiles),n=ri(2,3),cells=[s];
  for(let i=1;i<n;i++){const b=pickOne(cells),[dx,dy]=pickOne(N4),q={x:b.x+dx,y:b.y+dy};if(inb(q.x,q.y)&&free(q.x,q.y)&&!cells.some(c=>c.x===q.x&&c.y===q.y))cells.push(q)}
  const old=cells.map(c=>S.grid[c.y][c.x]);for(const c of cells)S.grid[c.y][c.x]=ch;
  if(!HZ(ch).walk&&!hzReach()){cells.forEach((c,i)=>S.grid[c.y][c.x]=old[i]);continue}p++;put+=cells.length}
 if(put)log(`Terrain: ${Z.n}. Hover a tile to see what it does.`,'bad')}
// Every standing squad member can still walk to an evac zone (doors count as open). Maps without evac pass.
function hzReach(){const E=tilesWhere(c=>c==='E');if(!E.length)return true;
 for(const u of players().filter(u=>u.status==='ok')){const seen=new Set([u.x+','+u.y]),q=[[u.x,u.y]];let hit=0;
  while(q.length){const [x,y]=q.shift();if(S.grid[y][x]==='E'){hit=1;break}for(const [dx,dy] of N4){const nx=x+dx,ny=y+dy,c=inb(nx,ny)&&S.grid[ny][nx];
   if(c&&(PASS(c)||'dD'.includes(c))&&!seen.has(nx+','+ny)){seen.add(nx+','+ny);q.push([nx,ny])}}}if(!hit)return false}return true}

// One tile entered (walked, slid or pushed): hurt, then report whether movement should stop.
function hzEnter(u){const c=tile(u.x,u.y),t=HZ(c);if(!alive(u)||u.status==='down')return true;
 if(t.hurt&&hzLive(c)){fx(u,t.n.toUpperCase(),'dmg');log(`${u.n} ${c==='l'?'is burned by':c==='n'?'is shocked by':'is hurt by'} the ${t.n.toLowerCase()}.`,u.side==='p'?'bad':'good');damage(u,t.hurt,null)}
 return !!t.stop||u.status!=='ok'}
// Slide while on slick tiles, the way the unit was moving. Returns true if it moved.
function hzSlide(u,dx,dy){let moved=false;for(let i=0;i<3&&HZ(tile(u.x,u.y)).slide&&u.status==='ok';i++){const nx=u.x+dx,ny=u.y+dy;
  if(!inb(nx,ny)||!PASS(tile(nx,ny))||unitAt(nx,ny)||Math.abs(elevAt(nx,ny)-elevAt(u.x,u.y))>1)break;
  if(!moved){fx(u,'SLIDE','miss');log(`${u.n} slides on the ${HZ(tile(u.x,u.y)).n.toLowerCase()}.`)}moved=true;
  _hzMove(u,[{x:nx,y:ny}]);if(hzEnter(u))break}return moved}
const _hzMove=moveAlong;
moveAlong=function(u,path){if(!hzSet())return _hzMove(u,path);
 for(const s of path){const dx=Math.sign(s.x-u.x),dy=Math.sign(s.y-u.y),c0=S.conc;_hzMove(u,[s]);if(u.x!==s.x||u.y!==s.y||u.status!=='ok'||(c0&&!S.conc))break;
  if(hzEnter(u))break;if(HZ(tile(u.x,u.y)).slide){hzSlide(u,dx,dy);break}}};
// Mud and thorns: a move may end on them but never pass through.
const _hzReach=reach;
reach=function(u){const R=_hzReach(u);if(!hzSet())return R;const s=u.x+','+u.y;
 for(const k of Object.keys(R.d)){let p=R.prev[k];while(p&&p!==s){const [x,y]=p.split(',').map(Number);if(HZ(tile(x,y)).stop){delete R.d[k];break}p=R.prev[p]}}return R};
// Force pushes: landing on a hazard counts as entering it (lava hurts, ice keeps sliding).
const _hzPush=push;
push=function(u,t){const x0=t.x,y0=t.y;_hzPush(u,t);if(!hzSet()||!alive(t)||t.status!=='ok'||(t.x===x0&&t.y===y0))return;
 if(!hzEnter(t)&&HZ(tile(t.x,t.y)).slide)hzSlide(t,Math.sign(t.x-x0),Math.sign(t.y-y0))};
// Round start: everyone standing in a live hurting tile takes it again.
const _hzSPT=startPlayerTurn;
startPlayerTurn=function(){if(hzSet()&&!S.over)for(const u of S.units.filter(u=>alive(u)&&u.status==='ok'&&hzLive(tile(u.x,u.y)))){
  fx(u,HZ(tile(u.x,u.y)).n.toUpperCase(),'dmg');log(`${u.n} is still in the ${HZ(tile(u.x,u.y)).n.toLowerCase()}.`,u.side==='p'?'bad':'good');damage(u,HZ(tile(u.x,u.y)).hurt,null);if(S.over)return}
 _hzSPT()};
// AI: stay out of hurting tiles and off slick ones.
const _hzScore=tileScore;
tileScore=function(e,pos){let s=_hzScore(e,pos);if(hzSet()){const t=HZ(tile(pos.x,pos.y));if(t.hurt)s-=12*t.hurt;if(t.slide)s-=6}return s};

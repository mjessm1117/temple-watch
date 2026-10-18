/* Open maps (Jess, wave 5): no dead ends, fewer choke points, no walled-off pockets.
   Runs on a mission's maps (all its alt layouts) the first time that mission starts. Greedy: try turning one solid wall ('#' or 'B') into a broken wall 'h'
   (half cover you can vault, see VAULT in rules.js) and keep the breach that helps most; up to OPEN.max breaches per map.
   Rooms you can only enter through a door ('d'/'D', e.g. prison cells) are left alone: not scored, never breached.
   Doors, objectives, consoles and every other tile are never touched.
   OPEN.off = true (or MISSIONS[id].closed = 1) turns it off. Loads after maps.js. */
const OPEN={max:4,walls:new Set(['#','B']),off:false};
function openGrid(G){const H=G.length,W=G[0].length,T=t=>TILES[t]||{},V=typeof VAULT!=='undefined'?VAULT:new Set();
 const P=(x,y)=>x>=0&&y>=0&&x<W&&y<H&&!!T(G[y][x]).walk,E=(x,y)=>T(G[y][x]).elev||0,K=(x,y)=>x+','+y;
 const nb=(x,y)=>{const r=[];for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++){if(!dx&&!dy)continue;const nx=x+dx,ny=y+dy;if(nx<0||ny<0||nx>=W||ny>=H)continue;
  if(V.has(G[ny][nx])&&!(dx&&dy)){if(P(nx+dx,ny+dy)&&Math.abs(E(nx+dx,ny+dy)-E(x,y))<=1)r.push([nx+dx,ny+dy]);continue}
  if(!P(nx,ny)||(dx&&dy&&(!P(x+dx,y)||!P(x,y+dy))))continue;const de=Math.abs(E(nx,ny)-E(x,y));if(de>2||(de===2&&dx&&dy))continue;r.push([nx,ny])}return r};
 const comps=()=>{const cells=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(P(x,y))cells.push([x,y]);const comp={},sz=[];
  for(const [x,y] of cells){if(comp[K(x,y)]!=null)continue;const id=sz.length,q=[[x,y]];comp[K(x,y)]=id;let s=0;
   while(q.length){const [a,b]=q.pop();s++;for(const [c,d] of nb(a,b))if(comp[K(c,d)]==null){comp[K(c,d)]=id;q.push([c,d])}}sz.push(s)}return {cells,comp,sz}};
 // Door rooms: pockets off the main area that touch a door. Left exactly as designed.
 const room=new Set();{const {cells,comp,sz}=comps(),main=sz.indexOf(Math.max(...sz)),byC={};
  for(const [x,y] of cells)if(comp[K(x,y)]!==main)(byC[comp[K(x,y)]]=byC[comp[K(x,y)]]||[]).push([x,y]);
  for(const L of Object.values(byC))if(L.some(([x,y])=>[[1,0],[-1,0],[0,1],[0,-1]].some(([a,b])=>'dD'.includes((G[y+b]||[])[x+a]||'.'))))for(const [x,y] of L)room.add(K(x,y))}
 const nearRoom=(x,y)=>[[1,0],[-1,0],[0,1],[0,-1]].some(([a,b])=>room.has(K(x+a,y+b)));
 // Score: walled-off tiles ×3 + dead ends ×2 + choke points. Lower is better.
 const score=()=>{const cells=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(P(x,y)&&!room.has(K(x,y)))cells.push([x,y]);if(!cells.length)return 0;
  const comp={},sz=[];for(const [x,y] of cells){if(comp[K(x,y)]!=null)continue;const id=sz.length,q=[[x,y]];comp[K(x,y)]=id;let s=0;
   while(q.length){const [a,b]=q.pop();s++;for(const [c,d] of nb(a,b))if(comp[K(c,d)]==null){comp[K(c,d)]=id;q.push([c,d])}}sz.push(s)}
  const cut=cells.length-Math.max(...sz),dead=cells.filter(([x,y])=>nb(x,y).filter(([a,b])=>!room.has(K(a,b))).length===1).length;
  const disc={},low={},art=new Set();let t=0;
  const dfs=(u,p)=>{disc[u]=low[u]=t++;let ch=0;const [x,y]=u.split(',').map(Number);
   for(const [a,b] of nb(x,y)){const v=K(a,b);if(room.has(v))continue;if(disc[v]==null){ch++;dfs(v,u);low[u]=Math.min(low[u],low[v]);if(p!=null&&low[v]>=disc[u])art.add(u)}else if(v!==p)low[u]=Math.min(low[u],disc[v])}
   if(p==null&&ch>1)art.add(u)};
  for(const [x,y] of cells)if(disc[K(x,y)]==null)dfs(K(x,y),null);
  return cut*3+dead*2+art.size};
 let cur=score(),n=0;
 while(n<OPEN.max&&cur>0){let best=null,bs=cur;
  for(let y=0;y<H;y++)for(let x=0;x<W;x++){if(!OPEN.walls.has(G[y][x])||nearRoom(x,y))continue;
   // only walls with walkable ground on two opposite sides (a breach you can vault through)
   if(!((P(x-1,y)&&P(x+1,y))||(P(x,y-1)&&P(x,y+1))))continue;
   const was=G[y][x];G[y][x]='h';const s=score();G[y][x]=was;if(s<bs){bs=s;best=[x,y]}}
  if(!best)break;G[best[1]][best[0]]='h';cur=bs;n++}
 return n}
function openMission(B){let total=0;if(OPEN.off||!B||B.closed)return 0;
 for(const M of [B,...(B.alts||[])]){if(!M.map||M.closed||M._open)continue;const G=M.map.map(r=>r.split(''));const n=openGrid(G);if(n)M.map=G.map(r=>r.join(''));M._open=1;total+=n}
 return total}
const openMaps=()=>Object.values(MISSIONS).reduce((s,B)=>s+openMission(B),0);
const _oStart=startMission;startMission=function(id){try{openMission(MISSIONS[id])}catch(e){}return _oStart.apply(this,arguments)};

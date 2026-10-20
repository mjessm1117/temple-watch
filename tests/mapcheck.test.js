// Map validator (Chat M2, wave 6). Every layout of every mission, as designed (before map-open.js breaches or hazards):
//  1. reach  — every walkable tile can be reached from the squad start (doors count as open).
//  2. routes — every objective and every enemy entry has 2+ separate routes: no single 2×2 patch of ground (a choke) cuts it off.
//  3. cover  — every walkable tile has a cover spot (a tile next to cover or higher ground) within 3 tiles.
// Prints one line per layout. MAPCHECK=warn prints the report but never fails (for exploring).
const {JSDOM}=require('jsdom');const fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8');
const w=new JSDOM(html,{runScripts:'dangerously'}).window;
const D=JSON.parse(w.eval(`JSON.stringify({T:TILES,V:[...VAULT],L:Object.entries(MISSIONS).flatMap(([id,B])=>[B,...(B.alts||[])].map((v,i)=>({id,i,M:{...B,...v,alts:0}})))})`));w.close();
const T=D.T,V=new Set(D.V),DOOR=new Set(['d','D','_']);
const PLUG=+process.env.PLUG||2;

function check({id,i,M}){const g=M.map,H=g.length,W=g[0].length,at=(x,y)=>x>=0&&y>=0&&x<W&&y<H?g[y][x]:null,K=(x,y)=>x+','+y;
 const walk=(x,y,doors=1)=>{const c=at(x,y);return !!c&&(!!(T[c]||{}).walk||doors&&DOOR.has(c))},el=(x,y)=>(T[at(x,y)]||{}).elev||0;
 // Neighbours by the real movement rule (rules.js reach): 8 ways, no corner cutting, vault low cover straight, max 2-level step (straight only).
 const nb=(x,y,doors=1)=>{const r=[];for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++){if(!dx&&!dy)continue;const nx=x+dx,ny=y+dy,c=at(nx,ny);if(c==null)continue;
  if(V.has(c)&&!(dx&&dy)){if(walk(nx+dx,ny+dy,doors)&&Math.abs(el(nx+dx,ny+dy)-el(x,y))<=1)r.push([nx+dx,ny+dy]);continue}
  if(!walk(nx,ny,doors))continue;if(dx&&dy&&(!walk(x+dx,y,doors)||!walk(x,y+dy,doors)))continue;
  const de=Math.abs(el(nx,ny)-el(x,y));if(de>2||(de===2&&dx&&dy))continue;r.push([nx,ny])}return r};
 const cells=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(walk(x,y))cells.push([x,y]);
 const bfs=(src,block,doors=1)=>{const seen=new Set(),q=[];for(const [x,y] of src){const k=K(x,y);if(!block||!block.has(k)){seen.add(k);q.push([x,y])}}
  while(q.length){const [x,y]=q.pop();for(const [a,b] of nb(x,y,doors)){const k=K(a,b);if(!seen.has(k)&&!(block&&block.has(k))){seen.add(k);q.push([a,b])}}}return seen};
 const start=M.start||[],all=bfs(start);
 // 1. reach
 const lost=cells.filter(([x,y])=>!all.has(K(x,y)));
 // Objectives → the tiles you stand on to use them.
 const ring=(x,y,r=1)=>{const o=[];for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++)if(walk(x+dx,y+dy))o.push([x+dx,y+dy]);return o};
 // A room only reachable through a door (prison cell): its goal is the ground outside its door(s).
 const outsideDoor=(x,y)=>{const room=bfs([[x,y]],null,0);const o=[];for(const k of room){const [a,b]=k.split(',').map(Number);
  for(const [p,q] of [[1,0],[-1,0],[0,1],[0,-1]])if('dD'.includes(at(a+p,b+q)||''))for(const [s,t] of ring(a+p,b+q))if(!room.has(K(s,t)))o.push([s,t])}return o.length&&room.size<cells.length/3?o:null};
 const goals=[];const add=(n,tiles)=>{tiles=tiles.filter(([x,y])=>walk(x,y));if(tiles.length)goals.push({n,tiles})};
 const tilesOf=c=>{const o=[];g.forEach((r,y)=>[...r].forEach((t,x)=>{if(t===c)o.push([x,y])}));return o};
 if(g.join('').includes('O'))add('objective',tilesOf('O').flatMap(([x,y])=>ring(x,y)));
 tilesOf('q').forEach(([x,y])=>add('terminal '+x+','+y,ring(x,y)));tilesOf('C').forEach(([x,y])=>add('charge '+x+','+y,ring(x,y)));
 if(g.join('').includes('E'))add('evac',tilesOf('E'));
 if(M.hostage){const [x,y]=M.hostage;add('hostage',outsideDoor(x,y)||ring(x,y))}
 (M.phases||[]).forEach((p,j)=>{if(p.at)add(p.k+' '+(j+1),ring(p.at[0],p.at[1],p.r??1));if(p.exit)add('exit '+(j+1),ring(p.exit[0],p.exit[1]))});
 (M.entries||[]).forEach(e=>add('entry '+(e[2]||e[0]+','+e[1]),ring(e[0],e[1])));
 if(M.type==='assault'&&M.foes&&M.foes[0])add('target',ring(M.foes[0][1],M.foes[0][2]));
 // 2. routes: try every 2×2 plug of ground (not the start, not the goal); any plug that cuts the goal off is a choke.
 const srcK=new Set(start.map(p=>K(p[0],p[1])));const chokes=[];
 for(const G of goals){const gK=new Set(G.tiles.map(([x,y])=>K(x,y)));if(!G.tiles.some(([x,y])=>all.has(K(x,y)))){chokes.push(G.n+' unreachable');continue}
  let cut=null;for(let y=0;y<=H-PLUG&&!cut;y++)for(let x=0;x<=W-PLUG&&!cut;x++){const blk=new Set();
   for(let b=y;b<y+PLUG;b++)for(let a=x;a<x+PLUG;a++){const k=K(a,b);if(walk(a,b)&&!srcK.has(k)&&!gK.has(k))blk.add(k)}
   if(!blk.size)continue;const s=bfs(start,blk);if(!G.tiles.some(([a,b])=>s.has(K(a,b))))cut=[x,y]}
  if(cut)chokes.push(`${G.n}@${cut}`)}
 // 3. cover within 3
 const cov=(x,y)=>[[1,0],[-1,0],[0,1],[0,-1]].some(([a,b])=>{const c=at(x+a,y+b);return c&&((T[c]||{}).cover>0||el(x+a,y+b)>el(x,y))});
 const spots=cells.filter(([x,y])=>!DOOR.has(at(x,y))&&cov(x,y));
 const bare=cells.filter(([x,y])=>!spots.some(([a,b])=>Math.max(Math.abs(a-x),Math.abs(b-y))<=3));
 const dead=cells.filter(([x,y])=>nb(x,y).length===1).length;
 return {tag:`${id}#${i}`,n:M.n,size:W+'x'+H,lost,chokes,bare,dead,goals:goals.length}}

let fail=0;const rows=D.L.map(check);
for(const r of rows){const ok=!r.lost.length&&!r.chokes.length&&!r.bare.length;if(!ok)fail++;
 console.log(`${ok?'ok  ':'FAIL'} ${r.tag.padEnd(14)} ${r.size.padEnd(6)} goals ${r.goals} · unreachable ${r.lost.length}${r.lost.length?" ["+r.lost.slice(0,6).map(p=>p.join(",")).join(" ")+"]":""} · chokes ${r.chokes.length}${r.chokes.length?' ['+r.chokes.join('; ')+']':''} · bare ${r.bare.length}${r.bare.length?' ['+r.bare.slice(0,6).map(p=>p.join(',')).join(' ')+(r.bare.length>6?' …':'')+']':''} · dead ends ${r.dead}`)}
console.log(`mapcheck: ${rows.length-fail}/${rows.length} layouts pass`);
process.exit(fail&&process.env.MAPCHECK!=='warn'?1:0);

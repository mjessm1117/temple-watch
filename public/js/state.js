/* Mission state S, lookups, log. Campaign state C lives in campaign.js. */
let S,fid=0;
// W/H follow the live mission's grid (maps can be any size); defined here so the getter sees S.
Object.defineProperty(window,'W',{get:()=>S&&S.grid?S.grid[0].length:10,configurable:true});Object.defineProperty(window,'H',{get:()=>S&&S.grid?S.grid.length:12,configurable:true});

const tile=(x,y)=>inb(x,y)?S.grid[y][x]:'#';
const alive=u=>u.status!=='dead'&&u.status!=='captured';
const unitAt=(x,y)=>S.units.find(u=>alive(u)&&u.x===x&&u.y===y);
const players=()=>S.units.filter(u=>u.side==='p'&&alive(u));
const enemies=()=>S.units.filter(u=>u.side==='e'&&alive(u));
const foesIn=(u,f)=>enemies().filter(e=>!e.hid&&f(e));
const byId=id=>S.units.find(u=>u.uid===id);
function tilesWhere(f){const o=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(f(S.grid[y][x],x,y))o.push({x,y});return o}
const consoles=()=>tilesWhere(c=>c==='O');
const nearestConsole=p=>consoles().reduce((b,c)=>dist(p,c)<dist(p,b)?c:b);
const hostage=()=>S.units.find(u=>u.vip);

function log(t,cls=''){S.log.unshift({t,cls});S.log.length=Math.min(S.log.length,30)}
function fx(p,txt,cls=''){const id=++fid;S.fx.push({x:p.x,y:p.y,txt,cls,id});setTimeout(()=>{if(!S)return;S.fx=S.fx.filter(f=>f.id!==id);render()},1150)}

/* Game state and lookups. */
let S,fid=0;

const tile=(x,y)=>inb(x,y)?S.grid[y][x]:'#';
const alive=u=>u.status!=='dead'&&u.status!=='captured';
const unitAt=(x,y)=>S.units.find(u=>alive(u)&&u.x===x&&u.y===y);
const players=()=>S.units.filter(u=>u.side==='p'&&alive(u));
const enemies=()=>S.units.filter(u=>u.side==='e'&&alive(u));
const foesIn=(u,f)=>enemies().filter(f);
const consoles=()=>{const o=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(S.grid[y][x]==='O')o.push({x,y});return o};
const nearestConsole=p=>consoles().reduce((b,c)=>dist(p,c)<dist(p,b)?c:b);

function log(t,cls=''){S.log.unshift({t,cls});S.log.length=Math.min(S.log.length,30)}
function fx(p,txt){const id=++fid;S.fx.push({x:p.x,y:p.y,txt,id});setTimeout(()=>{S.fx=S.fx.filter(f=>f.id!==id);render()},1150)}

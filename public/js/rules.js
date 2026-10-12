/* Combat rules: sight, cover, hit chance, movement, damage. */
function line(x0,y0,x1,y1){const pts=[],n=Math.max(Math.abs(x1-x0),Math.abs(y1-y0))*2||1;
 for(let i=0;i<=n;i++){const t=i/n,p={x:Math.round(x0+(x1-x0)*t),y:Math.round(y0+(y1-y0)*t)},l=pts[pts.length-1];if(!l||l.x!==p.x||l.y!==p.y)pts.push(p)}return pts}
// Full cover blocks sight unless it sits right beside shooter (step-out) or target (it's their cover instead).
function los(a,b){for(const p of line(a.x,a.y,b.x,b.y).slice(1,-1)){if(FULL(tile(p.x,p.y))&&cheb(p,a)>1&&cheb(p,b)>1)return false}return true}
function coverVal(t,from){let b=0;const dx=Math.sign(from.x-t.x),dy=Math.sign(from.y-t.y);
 const chk=(x,y)=>{const c=tile(x,y);if(FULL(c))b=Math.max(b,40);else if(HALF(c))b=Math.max(b,20)};
 if(dx)chk(t.x+dx,t.y);if(dy)chk(t.x,t.y+dy);return b}
const inCover=t=>N4.some(([dx,dy])=>inb(t.x+dx,t.y+dy)&&(FULL(tile(t.x+dx,t.y+dy))||HALF(tile(t.x+dx,t.y+dy))));
const flanked=(t,a)=>inCover(t)&&coverVal(t,a)===0;
function hitChance(a,t,{melee=false,mod=0}={}){
 if(melee)return Math.min(95,a.aim+10);
 let c=a.aim-coverVal(t,a)+mod;const d=dist(a,t);if(d>a.range*.6)c-=Math.round((d-a.range*.6)*3);
 if(t.status==='stunned'||t.status==='surrender')c+=30;
 return Math.max(5,Math.min(95,Math.round(c)))}

function reach(u){const d={},prev={},q=[[u.x,u.y]];d[u.x+','+u.y]=0;
 while(q.length){const [x,y]=q.shift(),cd=d[x+','+y];if(cd>=u.mob)continue;
  for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++){if(!dx&&!dy)continue;const nx=x+dx,ny=y+dy,k=nx+','+ny;
   if(!inb(nx,ny)||!PASS(tile(nx,ny))||unitAt(nx,ny)||d[k]!=null)continue;
   if(dx&&dy&&(!PASS(tile(x+dx,y))||!PASS(tile(x,y+dy))))continue;
   d[k]=cd+1;prev[k]=x+','+y;q.push([nx,ny])}}
 return{d,prev}}
function pathTo(u,x,y,prev){const p=[];let k=x+','+y;const s=u.x+','+u.y;while(k&&k!==s){const [a,b]=k.split(',').map(Number);p.unshift({x:a,y:b});k=prev[k]}return p}
function moveAlong(u,path){for(const s of path){u.x=s.x;u.y=s.y;reactions(u);if(u.status!=='ok')break}}
function reactions(u){
 for(const o of S.units.filter(o=>alive(o)&&o.side!==u.side&&o.status==='ok'&&(o.ow||o.guard))){
  if(u.status!=='ok')break;
  if(o.guard&&o.jedi&&!o.guardStruck&&cheb(o,u)===1){o.guardStruck=true;log(`${o.n} strikes from Guard!`);resolve(o,u,hitChance(o,u,{melee:true}),o.dmg,{melee:true,label:'saber'});continue}
  if(o.ow&&dist(o,u)<=o.range&&los(o,u)){o.ow=false;log(`${o.n} fires on overwatch.`);resolve(o,u,hitChance(o,u,{mod:-15}),o.dmg,{label:'overwatch shot'})}}}

function addDark(u,n){const b=u.dark;u.dark=Math.min(10,u.dark+n);
 if(b<5&&u.dark>=5)log(`${u.n} feels the dark side's strength: +1 damage, and a narrower path.`,'dark');
 if(u.dark>=10)log(`${u.n} stands at the edge of falling.`,'dark')}
function damage(t,d,src){const wasSurr=t.status==='surrender';t.hp-=d;fx(t,'-'+d);
 if(t.hp<=0){t.hp=0;
  if(t.side==='p'){t.status='down';t.bleed=3;t.guard=t.ow=false;log(`${t.n} is down. Bleeding out in 3 turns.`,'bad')}
  else{t.status='dead';log(`${t.n} is killed.`);S.kills++;
   if(wasSurr&&src){if(src.jedi){addDark(src,2);log(`${src.n} struck down a foe who had surrendered.`,'dark')}else{S.orderDark++;log('Killing a prisoner stains the Order.','dark')}}}}
 else if(t.side==='e'&&t.type!=='acolyte'&&t.status==='ok'&&t.hp<=2&&rnd(40)){t.status='surrender';t.ow=false;log(`${t.n} drops his blaster and surrenders.`,'good')}}
function resolve(a,t,chance,dr,{melee=false,ignoreDeflect=false,label='shot'}={}){
 if(!rnd(chance)){log(`${a.n}'s ${label} misses ${t.n}.`);fx(t,'MISS');return false}
 if(!melee&&!ignoreDeflect&&t.deflect&&t.status==='ok'){const def=t.guard?t.guardDef:t.deflect;
  if(rnd(def)){log(`${t.n} deflects the bolt!`,t.side==='p'?'good':'');fx(t,'DEFLECT');
   if(t.guard&&rnd(40)&&alive(a)&&a.status==='ok'){log(`…and sends it back into ${a.n}.`,'good');damage(a,ri(a.dmg[0],a.dmg[1]),t)}return false}}
 let d=ri(dr[0],dr[1]);if(a.jedi&&a.dark>=5)d++;
 if(!melee&&!ignoreDeflect&&flanked(t,a)&&rnd(50)){d+=2;log('Flanked: critical hit!')}
 log(`${a.n}'s ${label} hits ${t.n} for ${d}.`,t.side==='p'?'bad':'');damage(t,d,a);return true}
function blast(x,y,d,src){for(const u of S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1))damage(u,d,src);
 for(let yy=y-1;yy<=y+1;yy++)for(let xx=x-1;xx<=x+1;xx++)if(inb(xx,yy)&&HALF(S.grid[yy][xx]))S.grid[yy][xx]='.';fx({x,y},'BOOM')}
function nearCrate(u){let b=null;for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(S.grid[y][x]==='c'&&dist(u,{x,y})<=4&&(!b||dist(u,{x,y})<dist(u,b)))b={x,y};return b}
function push(u,t){const dx=Math.sign(t.x-u.x),dy=Math.sign(t.y-u.y);
 for(let i=0;i<2;i++){const nx=t.x+dx,ny=t.y+dy,c=tile(nx,ny),o=inb(nx,ny)&&unitAt(nx,ny);
  if(!inb(nx,ny)||!PASS(c)||o){log(`${t.n} slams into ${o?o.n:c==='c'?'a crate':'a wall'}.`);if(c==='c')S.grid[ny][nx]='.';damage(t,2,u);if(o&&o.side==='e'&&alive(o))damage(o,1,u);return}
  t.x=nx;t.y=ny}log(`${u.n} hurls ${t.n} back.`)}

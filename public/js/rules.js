/* Combat rules: sight, cover, hit chance (with an itemized breakdown), movement, damage. */
function line(x0,y0,x1,y1){const pts=[],n=Math.max(Math.abs(x1-x0),Math.abs(y1-y0))*2||1;
 for(let i=0;i<=n;i++){const t=i/n,p={x:Math.round(x0+(x1-x0)*t),y:Math.round(y0+(y1-y0)*t)},l=pts[pts.length-1];if(!l||l.x!==p.x||l.y!==p.y)pts.push(p)}return pts}
// Full cover blocks sight unless it sits right beside shooter (step-out) or target (it's their cover instead).
function los(a,b){for(const p of line(a.x,a.y,b.x,b.y).slice(1,-1)){if(FULL(tile(p.x,p.y))&&cheb(p,a)>1&&cheb(p,b)>1)return false}return true}
function coverVal(t,from){if(t.barrier)return 40;let b=0;const dx=Math.sign(from.x-t.x),dy=Math.sign(from.y-t.y);
 const chk=(x,y)=>{const c=tile(x,y);if(FULL(c))b=Math.max(b,40);else if(HALF(c))b=Math.max(b,20)};
 if(dx)chk(t.x+dx,t.y);if(dy)chk(t.x,t.y+dy);return b}
const inCover=t=>t.barrier||N4.some(([dx,dy])=>inb(t.x+dx,t.y+dy)&&(FULL(tile(t.x+dx,t.y+dy))||HALF(tile(t.x+dx,t.y+dy))));
const flanked=(t,a)=>!t.hunker&&inCover(t)&&coverVal(t,a)===0;
const onSmoke=t=>S.smoke.some(s=>cheb(s,t)<=1);
const bmedNear=u=>{const c=S.bmed!=null&&byId(S.bmed);return !!c&&alive(c)&&c.status==='ok'&&dist(c,u)<=6};
const defLineNear=t=>t.side==='p'&&S.units.some(g=>g!==t&&g.defLine&&g.side==='p'&&g.status==='ok'&&cheb(g,t)===1);
// Every modifier as its own line, so the odds panel can show the math.
function odds(a,t,{melee=false,mod=0,noCover=false}={}){const L=[['Aim',a.aim]];
 if(melee)L.push(['Close quarters',10]);
 else{const cv=noCover?0:coverVal(t,a);if(cv)L.push([cv>=40?'Full cover':'Half cover',-cv]);
  const d=dist(a,t);if(d>a.range*.6)L.push(['Range',-Math.round((d-a.range*.6)*3)]);
  if(onSmoke(t))L.push(['Smoke',-20]);
  if(a.snipe&&!noCover&&coverVal(t,a)===0)L.push(['Exposed target',a.snipe])}
 if(t.hunker)L.push(['Hunkered down',-30]);
 if(defLineNear(t))L.push(['Defensive Line',-15]);
 if(t.status==='stunned'||t.status==='surrender')L.push(['Helpless',30]);
 if(a.supp)L.push(['Suppressed',-30]);
 if(bmedNear(a))L.push(['Battle Meditation',a.side==='p'?10:-10]);
 if(a.side==='p'&&t.marked)L.push(['Marked',15]);
 if(mod)L.push([mod>0?'Ability bonus':'Ability penalty',mod]);
 const raw=L.reduce((s,l)=>s+l[1],0);return{lines:L,total:Math.max(5,Math.min(95,Math.round(raw)))}}
const hitChance=(a,t,o)=>odds(a,t,o).total;

function reach(u){const d={},prev={},q=[[u.x,u.y]];d[u.x+','+u.y]=0;
 while(q.length){const [x,y]=q.shift(),cd=d[x+','+y];if(cd>=u.mob)continue;
  for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++){if(!dx&&!dy)continue;const nx=x+dx,ny=y+dy,k=nx+','+ny;
   if(!inb(nx,ny)||!PASS(tile(nx,ny))||unitAt(nx,ny)||d[k]!=null)continue;
   if(dx&&dy&&(!PASS(tile(x+dx,y))||!PASS(tile(x,y+dy))))continue;
   d[k]=cd+1;prev[k]=x+','+y;q.push([nx,ny])}}
 return{d,prev}}
function pathTo(u,x,y,prev){const p=[];let k=x+','+y;const s=u.x+','+u.y;while(k&&k!==s){const [a,b]=k.split(',').map(Number);p.unshift({x:a,y:b});k=prev[k]}return p}
function moveAlong(u,path){for(const s of path){u.x=s.x;u.y=s.y;if(u.side==='p')reveal();reactions(u);if(u.status!=='ok')break}}
// Concealed enemies show up when a squad member gets within 4 with line of sight.
function reveal(){for(const e of enemies().filter(e=>e.hid))if(players().some(p=>p.status==='ok'&&dist(p,e)<=4&&los(p,e))){e.hid=0;fx(e,'SPOTTED');log(`${e.n} spotted!`,'bad')}}
function reactions(u){if(u.hid)return;
 for(const o of S.units.filter(o=>alive(o)&&o.side!==u.side&&o.status==='ok')){
  if(u.status!=='ok')break;
  if(o.supT===u.uid&&dist(o,u)<=o.range&&los(o,u)){o.supT=null;log(`${o.n} fires on ${u.n} as it breaks cover.`);resolve(o,u,hitChance(o,u),o.dmg,{label:'suppressing shot'});continue}
  if(o.guard&&o.jedi&&!o.guardStruck&&cheb(o,u)===1){o.guardStruck=true;log(`${o.n} strikes from Guard!`);resolve(o,u,hitChance(o,u,{melee:true}),o.dmg,{melee:true,label:'saber'});continue}
  if(o.ow&&dist(o,u)<=o.range&&los(o,u)){o.ow=false;log(`${o.n} fires on overwatch.`);resolve(o,u,hitChance(o,u,{mod:-15}),o.dmg,{label:'overwatch shot'})}}}

function addDark(u,n){const b=u.dark;u.dark=Math.max(0,Math.min(10,u.dark+n));
 if(b<5&&u.dark>=5)log(`${u.n} feels the dark side's strength: +1 damage, and a narrower path.`,'dark');
 if(u.dark>=10)log(`${u.n} stands at the edge of falling.`,'dark')}
function damage(t,d,src){
 if(src&&src.horror&&!t.jedi){fx(t,'IMMUNE');log(`${src.n} ignores ${t.n}. It hunts only the Force.`);return}
 if(t.armor)d=Math.max(1,d-t.armor);
 const wasSurr=t.status==='surrender';t.hp-=d;fx(t,'-'+d,'dmg');if(t.side==='p')t.hurt=1;
 if(S.bmed===t.uid){S.bmed=null;log(`${t.n}'s Battle Meditation breaks.`)}
 if(t.hp<=0){t.hp=0;
  if(t.side==='p'){t.status='down';t.bleed=S.d.bleed;t.stable=0;t.downed=1;t.downT=S.turn;t.guard=t.ow=t.hunker=false;t.supT=null;log(`${t.n} is down. Bleeding out in ${t.bleed} turns.`,'bad')}
  else{t.status='dead';log(`${t.n} is killed.`);S.kills++;if(src&&src.side==='p')src.kills=(src.kills||0)+1;
   if(t.envoy&&src&&src.jedi){addDark(src,1);log('The envoy is dead. The Council wanted him alive.','dark')}
   if(wasSurr&&src&&src.side==='p'){if(src.jedi){addDark(src,2);log(`${src.n} struck down a foe who had surrendered.`,'dark')}else{S.orderDark++;log('Killing a prisoner stains the Order.','dark')}}}}
 else if(t.side==='e'&&!t.noCap&&t.status==='ok'&&t.hp<=2&&rnd(t.envoy?80:40)){t.status='surrender';t.ow=false;t.supT=null;log(`${t.n} drops his blaster and surrenders.`,'good')}}
// Roll an attack. Aim assist (Story/Normal): each miss in a row adds hidden aim to that unit's next roll.
function resolve(a,t,chance,dr,{melee=false,ignoreDeflect=false,label='shot'}={}){
 let ch=chance;if(a.side==='p'&&a.miss&&S.d.assist)ch=Math.min(95,ch+a.miss*S.d.assist);
 if(a.hid){a.hid=0;log(`${a.n} was hiding in plain sight!`,'bad')}
 if(!rnd(ch)){if(a.side==='p')a.miss=(a.miss||0)+1;log(`${a.n}'s ${label} misses ${t.n}.`);fx(t,'MISS','miss');return false}
 if(a.side==='p')a.miss=0;
 if(!melee&&!ignoreDeflect&&t.deflect&&t.status==='ok'){const def=t.guard?t.guardDef:t.deflect;
  if(rnd(def)){log(`${t.n} deflects the bolt!`,t.side==='p'?'good':'');fx(t,'DEFLECT','defl');
   if(t.guard&&rnd(t.reflectM?65:40)){const tgt=t.reflectM?(enemies().filter(e=>e.status==='ok'&&!e.hid&&dist(t,e)<=6).sort((x,y)=>x.hp-y.hp)[0]||a):a;
    if(alive(tgt)&&tgt.status==='ok'){log(`…and sends it into ${tgt.n}.`,'good');damage(tgt,ri(a.dmg[0],a.dmg[1]),t)}}return false}}
 let d=ri(dr[0],dr[1]);if(a.jedi&&a.dark>=5)d++;
 if(!melee&&!ignoreDeflect&&flanked(t,a)&&rnd(50)){d+=2;log('Flanked: critical hit!')}else if(a.crit&&rnd(a.crit)){d+=2;log('Critical hit!')}
 log(`${a.n}'s ${label} hits ${t.n} for ${d}.`,t.side==='p'?'bad':'');damage(t,d,a);
 if(a.shredder&&alive(t))shred(a,t);return true}
function shred(a,t){if(t.armor){t.armor--;log(`${t.n}'s armor is shredded.`)}
 const dx=Math.sign(a.x-t.x),dy=Math.sign(a.y-t.y);for(const [x,y] of [[t.x+dx,t.y],[t.x,t.y+dy]])if((dx||dy)&&inb(x,y)&&S.grid[y][x]==='c'){S.grid[y][x]='.';log('The crate it hid behind is torn apart.');break}}
// Explosion: 3×3. Crates and rubble are cleared; barrels chain.
function blast(x,y,d,src,seen=new Set()){seen.add(x+','+y);fx({x,y},'BOOM','boom');
 for(const u of S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1))damage(u,d,src);
 for(let yy=y-1;yy<=y+1;yy++)for(let xx=x-1;xx<=x+1;xx++){if(!inb(xx,yy))continue;const c=S.grid[yy][xx];
  if(c==='c'||c==='r')S.grid[yy][xx]='.';else if(c==='x'&&!seen.has(xx+','+yy)){S.grid[yy][xx]='.';log('A barrel goes up!','bad');blast(xx,yy,3,src,seen)}}}
function explodeBarrel(x,y,src){S.grid[y][x]='.';log('The barrel explodes!','bad');blast(x,y,3,src)}
function nearCrate(u){let b=null;for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(S.grid[y][x]==='c'&&dist(u,{x,y})<=4&&(!b||dist(u,{x,y})<dist(u,b)))b={x,y};return b}
function push(u,t){const dx=Math.sign(t.x-u.x),dy=Math.sign(t.y-u.y);
 for(let i=0;i<2;i++){const nx=t.x+dx,ny=t.y+dy,c=tile(nx,ny),o=inb(nx,ny)&&unitAt(nx,ny);
  if(!inb(nx,ny)||!PASS(c)||o){log(`${t.n} slams into ${o?o.n:c==='c'?'a crate':c==='x'?'a barrel':'a wall'}.`);if(c==='c')S.grid[ny][nx]='.';damage(t,2,u);if(o&&o.side==='e'&&alive(o))damage(o,1,u);if(c==='x')explodeBarrel(nx,ny,u);return}
  t.x=nx;t.y=ny}log(`${u.n} hurls ${t.n} back.`)}
// Locked doors open everywhere at once (one security system per map). Frees a bound hostage.
function unlock(u){for(const p of tilesWhere(c=>c==='D'))S.grid[p.y][p.x]='_';const h=hostage();
 if(h&&h.bound){h.bound=0;log(`The cell opens. ${h.n} is free. Get them to an evac zone.`,'good')}else log('The locks disengage.','good')}

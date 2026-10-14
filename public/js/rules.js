/* Combat rules: sight, cover, hit chance (with an itemized breakdown), movement, damage. */
function line(x0,y0,x1,y1){const pts=[],n=Math.max(Math.abs(x1-x0),Math.abs(y1-y0))*2||1;
 for(let i=0;i<=n;i++){const t=i/n,p={x:Math.round(x0+(x1-x0)*t),y:Math.round(y0+(y1-y0)*t)},l=pts[pts.length-1];if(!l||l.x!==p.x||l.y!==p.y)pts.push(p)}return pts}
// Full cover blocks sight unless it sits right beside shooter (step-out) or target (it's their cover instead).
// Heights (wave 3): eyes sit 1.2 above the tile's elev. Walls (h 2) and raised ground (elev) block a line that passes below their top.
// Ground to ground behaves as before; a shooter on a high ledge sees over walls at mid range.
const elevAt=(x,y)=>(TILES[tile(x,y)]||{}).elev||0,uEl=u=>elevAt(u.x,u.y);
function los(a,b){const P=line(a.x,a.y,b.x,b.y),n=P.length-1,ea=elevAt(a.x,a.y)+1.2,eb=elevAt(b.x,b.y)+1.2;
 for(let i=1;i<n;i++){const p=P[i];if(cheb(p,a)<=1||cheb(p,b)<=1)continue;const c=tile(p.x,p.y),top=FULL(c)?(TILES[c].h||2)+elevAt(p.x,p.y):elevAt(p.x,p.y);
  if(top&&top>=ea+(eb-ea)*i/n)return false}return true}
function coverVal(t,from){if(t.barrier)return 40;let b=0;const dx=Math.sign(from.x-t.x),dy=Math.sign(from.y-t.y);
 const te=uEl(t),fe=elevAt(from.x,from.y);
 // A ledge one step up is half cover, two steps up full cover, unless the shooter stands at least that high.
 const chk=(x,y)=>{const c=tile(x,y);if(FULL(c))b=Math.max(b,40);else if(HALF(c))b=Math.max(b,20);else if(inb(x,y)){const r=elevAt(x,y)-te;if(r>0&&fe<te+r)b=Math.max(b,r>=2?40:20)}};
 if(dx)chk(t.x+dx,t.y);if(dy)chk(t.x,t.y+dy);return b}
const inCover=t=>t.barrier||N4.some(([dx,dy])=>{const x=t.x+dx,y=t.y+dy;return inb(x,y)&&(FULL(tile(x,y))||HALF(tile(x,y))||elevAt(x,y)>uEl(t))});
const flanked=(t,a)=>!t.hunker&&inCover(t)&&coverVal(t,a)===0;
const onSmoke=t=>S.smoke.some(s=>cheb(s,t)<=1);
const bmedNear=u=>{const c=S.bmed!=null&&byId(S.bmed);return !!c&&alive(c)&&c.status==='ok'&&dist(c,u)<=6};
// Bonds (spec C §7, numbers from the Temple: u.bonds=[{rid,lvl}], u.bondAim, u.bondReact).
const bondMates=a=>(a.bonds||[]).filter(b=>b.lvl>=1).map(b=>b.rid);
const bondNear=a=>a.side==='p'&&a.bondAim&&players().some(p=>p!==a&&p.status==='ok'&&bondMates(a).includes(p.rid)&&dist(a,p)<=3)?a.bondAim:0;
// Bond level 2: once per mission, a partner who sees an ally get hit answers with a free shot or strike.
function bondAnswer(t,src){if(!src||src.side!=='e'||!alive(src)||src.status!=='ok')return;
 for(const p of players().filter(p=>p!==t&&p.status==='ok'&&p.bondReact&&!p.bondUsed&&(p.bonds||[]).some(b=>b.lvl>=2&&b.rid===t.rid))){
  const melee=p.range<2;if(melee?cheb(p,src)!==1:dist(p,src)>p.range||!los(p,src))continue;
  p.bondUsed=1;log(`${p.n} answers for ${t.n}!`,'good');resolve(p,src,hitChance(p,src,{melee}),p.dmg,{melee,label:melee?'strike':'shot'});return}}
const defLineNear=t=>t.side==='p'&&S.units.some(g=>g!==t&&g.defLine&&g.side==='p'&&g.status==='ok'&&cheb(g,t)===1);
// Every modifier as its own line, so the odds panel can show the math.
function odds(a,t,{melee=false,mod=0,noCover=false}={}){const L=[['Aim',a.aim]];
 if(melee)L.push(['Close quarters',10]);
 else{const cv=noCover?0:coverVal(t,a);if(cv)L.push([cv>=40?'Full cover':'Half cover',-cv]);
  const d=dist(a,t);if(d>a.range*.6)L.push(['Range',-Math.round((d-a.range*.6)*3)]);
  if(onSmoke(t))L.push(['Smoke',-20]);
  if(a.snipe&&!noCover&&coverVal(t,a)===0)L.push(['Exposed target',a.snipe]);
  if(cv&&uEl(a)>uEl(t))L.push(['Cover seen from above',Math.min(10,cv)])}
 if(uEl(a)>uEl(t))L.push(['High ground',15]);
 if(a.side==='p'&&t.side==='e'&&(S.conc||a.conc))L.push(['Ambush',20]);
 if(a.executioner&&t.hp*2<=t.max)L.push(['Executioner',25]);
 if(a.aimVs)for(const g of tagsOf(t))if(a.aimVs[g])L.push([`Vs ${g}`,a.aimVs[g]]);
 if(a.aimVsHorror&&t.horror)L.push([a.aimVsHorror>0?'Beast lore':'Fear of horrors',a.aimVsHorror]);
 if(a.lead){const P=byId(a.lead);if(P&&alive(P)&&P.status==='ok'&&dist(P,a)<=5)L.push(['Pod leader',5])}
 if(a.lordAura&&a.side==='e'&&enemies().some(e=>e!==a&&e.sithLord&&e.status==='ok'&&dist(e,a)<=4))L.push(['Sith Lord nearby',a.lordAura]);
 if(a.buffAim)L.push(['Boosted',a.buffAim]);if(t.buffDef)L.push(['Target shielded',-t.buffDef]);
 if(t.hunker)L.push(['Hunkered down',-30]);
 if(defLineNear(t))L.push(['Defensive Line',-15]);
 if(t.status==='stunned'||t.status==='surrender')L.push(['Helpless',30]);
 if(a.supp)L.push(['Suppressed',-30]);
 if(bmedNear(a))L.push(['Battle Meditation',a.side==='p'?10:-10]);
 if(a.side==='p'&&t.marked)L.push(['Marked',15]);
 const bd=bondNear(a);if(bd)L.push(['Bond',bd]);
 if(mod)L.push([mod>0?'Ability bonus':'Ability penalty',mod]);
 const raw=L.reduce((s,l)=>s+l[1],0);return{lines:L,total:Math.max(5,Math.min(95,Math.round(raw)))}}
const hitChance=(a,t,o)=>odds(a,t,o).total;

// Moves: 8 directions; a step may climb or drop one level of elev, never two (use the ramps).
function reach(u){const d={},prev={},q=[[u.x,u.y]],mob=u.rooted?0:u.mob;d[u.x+','+u.y]=0;
 while(q.length){const [x,y]=q.shift(),cd=d[x+','+y];if(cd>=mob)continue;
  for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++){if(!dx&&!dy)continue;const nx=x+dx,ny=y+dy,k=nx+','+ny;
   if(!inb(nx,ny)||!PASS(tile(nx,ny))||unitAt(nx,ny)||d[k]!=null)continue;
   if(dx&&dy&&(!PASS(tile(x+dx,y))||!PASS(tile(x,y+dy))))continue;if(Math.abs(elevAt(nx,ny)-elevAt(x,y))>1)continue;
   d[k]=cd+1;prev[k]=x+','+y;q.push([nx,ny])}}
 return{d,prev}}
function pathTo(u,x,y,prev){const p=[];let k=x+','+y;const s=u.x+','+u.y;while(k&&k!==s){const [a,b]=k.split(',').map(Number);p.unshift({x:a,y:b});k=prev[k]}return p}
function moveAlong(u,path){for(const s of path){u.x=s.x;u.y=s.y;if(u.side==='p'){reveal();lootAt(u);if(watchCheck(u))break}reactions(u);if(u.status!=='ok')break}}
// Concealed enemies show up when a squad member gets within 4 with line of sight.
// Sentinels with Sense find them at 8.
function reveal(){for(const e of enemies().filter(e=>e.hid))if(players().some(p=>p.status==='ok'&&dist(p,e)<=(p.sense?8:4)&&los(p,e))){e.hid=0;fx(e,'SPOTTED');log(`${e.n} spotted!`,'bad');horrorSeen(e)}}
function reactions(u){if(u.hid)return;
 for(const o of S.units.filter(o=>alive(o)&&o.side!==u.side&&o.status==='ok')){
  if(u.status!=='ok')break;
  if(reactOne(o,u)&&o.side==='p'&&S.conc)breakConceal(`${o.n}'s reaction fire springs the ambush!`,u,true)}}
// One unit's reaction to a mover. True if it fired. A concealed squad firing on a patrol springs the ambush (above).
function reactOne(o,u){
  if(o.supT===u.uid&&dist(o,u)<=o.range&&los(o,u)){o.supT=null;log(`${o.n} fires on ${u.n} as it breaks cover.`);resolve(o,u,hitChance(o,u),o.dmg,{label:'suppressing shot'});return true}
  if(o.guard&&o.jedi&&!o.guardStruck&&cheb(o,u)===1){o.guardStruck=true;log(`${o.n} strikes from Guard!`);resolve(o,u,hitChance(o,u,{melee:true}),o.dmg,{melee:true,label:'saber'});return true}
  // Hold the Line keeps overwatch up and fires once at every enemy that moves. Ambush overwatch (squad just revealed) has no −15.
  if(o.ow&&dist(o,u)<=o.range&&los(o,u)&&!(o.owHit||[]).includes(u.uid)){if(o.ow==='all')(o.owHit=o.owHit||[]).push(u.uid);else o.ow=false;
   log(S.ambush?`${o.n} springs the ambush!`:`${o.n} fires on overwatch.`,S.ambush?'good':'');resolve(o,u,hitChance(o,u,{mod:S.ambush?0:-15}),o.dmg,{label:S.ambush?'ambush shot':'overwatch shot'});return true}
  return false}

function addDark(u,n){const b=u.dark;u.dark=Math.max(0,Math.min(10,u.dark+n));
 if(b<5&&u.dark>=5)log(`${u.n} feels the dark side's strength: +1 damage, and a narrower path.`,'dark');
 if(u.dark>=10)log(`${u.n} stands at the edge of falling.`,'dark')}
function damage(t,d,src){
 if(src&&src.horror&&!t.jedi){fx(t,'IMMUNE');log(`${src.n} ignores ${t.n}. It hunts only the Force.`);return}
 if(t.armor)d=Math.max(1,d-t.armor);
 // Thought Shield (Sith Lords): Force powers do half damage.
 if(S.forceAct&&t.sithLord&&src&&src.side==='p'){d=Math.ceil(d/2);fx(t,'SHIELDED','defl');log(`${t.n}'s Thought Shield blunts the Force.`)}
 if(t.shield>0){const a=Math.min(t.shield,d);t.shield-=a;d-=a;fx(t,'SHIELD','defl');log(`${t.n}'s shield soaks ${a}.`);if(!d)return}
 const wasSurr=t.status==='surrender';t.hp-=d;fx(t,'-'+d,'dmg');if(t.side==='p')t.hurt=1;
 if(S.bmed===t.uid){S.bmed=null;log(`${t.n}'s Battle Meditation breaks.`)}
 if(t.hp<=0){t.hp=0;
  if(t.side==='p'){t.status='down';t.bleed=S.d.bleed;t.stable=0;t.downed=1;t.downT=S.turn;t.guard=t.ow=t.hunker=false;t.supT=null;t.panic=null;log(`${t.n} is down. Bleeding out in ${t.bleed} turns.`,'bad');if(!t.vip)allyFell(t,15,`${t.n} going down`)}
  else{t.status='dead';log(`${t.n} is killed.`);S.kills++;if(src&&src.side==='p'){src.kills=(src.kills||0)+1;if(src.ghost&&!src.ghostUsed&&!S.conc){src.ghostUsed=1;src.conc=1;fx(src,'GHOST');log(`${src.n} melts back into the shadows.`,'good')}}
   leaderDown(t);dropLoot(t);
   if(t.envoy&&src&&src.jedi){addDark(src,1);log('The envoy is dead. The Council wanted him alive.','dark')}
   if(wasSurr&&src&&src.side==='p'){if(src.jedi){addDark(src,2);log(`${src.n} struck down a foe who had surrendered.`,'dark')}else{S.orderDark++;log('Killing a prisoner stains the Order.','dark')}}}}
 else if(t.side==='e'&&!t.noCap&&!t.fanatic&&t.status==='ok'&&t.hp<=2&&rnd(t.envoy?80:40)){t.status='surrender';t.ow=false;t.supT=null;log(`${t.n} drops his blaster and surrenders.`,'good')}
 if(t.side==='e'&&alive(t)&&asleep(t)&&!S.amb)alertPod(t.pod);
 // Marauder rage: +1 damage per hit taken (max +3).
 if(t.rage&&t.status==='ok'&&(t.rageN||0)<3){t.rageN=(t.rageN||0)+1;t.dmg=[t.dmg[0]+1,t.dmg[1]+1];log(`${t.n}'s rage grows (+${t.rageN} damage).`,'bad')}
 if(t.side==='p'&&t.status==='ok'&&!t.vip&&d>=Math.max(3,t.max/2))panicCheck(t,20,'a brutal hit');
 if(t.side==='p'&&t.rid)bondAnswer(t,src)}
// Roll an attack. Aim assist (Story/Normal): each miss in a row adds hidden aim to that unit's next roll.
function resolve(a,t,chance,dr,{melee=false,ignoreDeflect=false,label='shot'}={}){a.fired=1;
 let ch=chance;if(a.side==='p'&&a.miss&&S.d.assist)ch=Math.min(95,ch+a.miss*S.d.assist);
 if(a.hid){a.hid=0;log(`${a.n} was hiding in plain sight!`,'bad')}if(a.side==='p'&&a.conc&&!S.conc){a.conc=0;log(`${a.n} strikes from the shadows.`)}
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
 const dx=Math.sign(a.x-t.x),dy=Math.sign(a.y-t.y);for(const [x,y] of [[t.x+dx,t.y],[t.x,t.y+dy]])if((dx||dy)&&inb(x,y)&&TILES[S.grid[y][x]].breaks){degrade(x,y);break}}
// Destructible cover: blast wall → broken wall → rubble; crates → rubble. Plain walls only fall to Collapse.
const tileH=(x,y)=>(TILES[tile(x,y)]||{}).h||0;
function degrade(x,y){const c=S.grid[y][x],t=TILES[c];if(!t||!t.breaks)return false;S.grid[y][x]=t.breaks;fx('coverBreak',{x,y,from:c,to:t.breaks});
 fx({x,y},t.breaks==='r'?'CRUMBLE':'CRACK','boom');log(t.breaks==='r'?`The ${t.n.toLowerCase()} crumbles to rubble.`:`The ${t.n.toLowerCase()} cracks. Only half cover now.`);return true}
// Alarm beacons: shoot or blast them (4 HP). Destroyed → rubble, and any call for help is cancelled.
function hitBeacon(x,y,d){const k=x+','+y;S.bhp=S.bhp||{};S.bhp[k]=(S.bhp[k]??BEACON_HP)-d;fx({x,y},'-'+d,'dmg');
 if(S.bhp[k]>0)return log(`The beacon sparks (${S.bhp[k]} left).`);S.grid[y][x]='r';log('The alarm beacon is wrecked.','good');
 if(S.beacon&&S.beacon.x===x&&S.beacon.y===y){S.beacon=null;log('Their call for help dies with it.','good')}}
// Explosion: 3×3. Breakable cover drops one step (full → half → rubble); beacons take the damage; barrels chain.
function blast(x,y,d,src,seen=new Set()){seen.add(x+','+y);fx({x,y},'BOOM','boom');
 for(const u of S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1))damage(u,d,src);
 for(let yy=y-1;yy<=y+1;yy++)for(let xx=x-1;xx<=x+1;xx++){if(!inb(xx,yy))continue;const c=S.grid[yy][xx];
  if(TILES[c].breaks)degrade(xx,yy);else if(c==='b')hitBeacon(xx,yy,d);else if(c==='x'&&!seen.has(xx+','+yy)){S.grid[yy][xx]='.';log('A barrel goes up!','bad');blast(xx,yy,3,src,seen)}}}
function explodeBarrel(x,y,src){S.grid[y][x]='.';log('The barrel explodes!','bad');blast(x,y,3,src)}
function nearCrate(u){let b=null;for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(S.grid[y][x]==='c'&&dist(u,{x,y})<=4&&(!b||dist(u,{x,y})<dist(u,b)))b={x,y};return b}
// Push: a cliff two levels up stops them like a wall; shoving someone off a ledge deals 1 per level dropped.
function push(u,t){const dx=Math.sign(t.x-u.x),dy=Math.sign(t.y-u.y),e0=uEl(t);pushN(u,t,dx,dy,2);
 const drop=e0-uEl(t);if(drop>0&&alive(t)&&t.hp>0){log(`${t.n} falls ${drop} level${drop>1?'s':''}.`);damage(t,drop,u)}}
function pushN(u,t,dx,dy,n){
 for(let i=0;i<n;i++){const nx=t.x+dx,ny=t.y+dy,c=tile(nx,ny),o=inb(nx,ny)&&unitAt(nx,ny);
  if(!inb(nx,ny)||!PASS(c)||o||elevAt(nx,ny)-uEl(t)>1){log(`${t.n} slams into ${o?o.n:TILES[c]&&inb(nx,ny)?'a '+TILES[c].n.toLowerCase():'a wall'}.`);if(inb(nx,ny)&&TILES[c].breaks)degrade(nx,ny);damage(t,2,u);if(o&&o.side==='e'&&alive(o))damage(o,1,u);if(c==='x')explodeBarrel(nx,ny,u);return}
  t.x=nx;t.y=ny}log(`${u.n} hurls ${t.n} back.`)}
// Locked doors open everywhere at once (one security system per map). Frees a bound hostage.
function unlock(u){for(const p of tilesWhere(c=>c==='D'))S.grid[p.y][p.x]='_';const h=hostage();
 if(h&&h.bound){h.bound=0;log(`The cell opens. ${h.n} is free. Get them to an evac zone.`,'good')}else log('The locks disengage.','good')}

// ---- Will & panic (wave 3). u.will comes from battleUnit() (Chat P: ~50 + perks, already lowered by stress); default Jedi 60, troops 45, +5/rank.
// Chance = trigger − will/3 (Battle Meditation nearby −15), capped 0–60. Triggers: ally down 15, ally dead 30 (+20 bonded), horror sighted 25 (troops 10), brutal hit 20.
const tagsOf=t=>[...(t.tags||[]),...['horror','force','droid','creature','boss','elite'].filter(k=>t[k]&&!(t.tags||[]).includes(k))];
const willOf=u=>u.will??((u.jedi?60:45)+5*((u.rank||1)-1));
function panicCheck(u,sev,why){if(u.side!=='p'||u.vip||u.status!=='ok'||u.panic||S.over)return;
 let ch=sev-willOf(u)/3;if(bmedNear(u))ch-=15;ch=Math.max(0,Math.min(60,Math.round(ch)));if(!rnd(ch))return;
 u.panics=(u.panics||0)+1;
 // Jedi may turn fear into anger instead: no lost turn, but the dark side gets a foothold.
 if(u.jedi&&rnd(50)){addDark(u,1);fx(u,'ANGER','dark');log(`${u.n} meets ${why} with anger, not fear. Darkness +1.`,'dark');return}
 u.panic=u.range<2?pickOne(['freeze','flee']):pickOne(['freeze','flee','wild']);fx(u,'PANIC','dmg');log(`${u.n} panics at ${why}! They will ${PANIC_TXT[u.panic]} next turn.`,'bad')}
const PANIC_TXT={freeze:'freeze in place',flee:'run for cover',wild:'fire wildly'};
// Ally down 15, ally dead 30 (+20 for a bonded partner); everyone standing within 8 who can see it rolls.
function allyFell(t,sev,why){for(const p of players().filter(p=>p!==t&&p.status==='ok'&&!p.vip&&dist(p,t)<=8&&los(p,t)))
 panicCheck(p,sev+((p.bonds||[]).some(b=>b.lvl>=1&&b.rid===t.rid)?20:0),why)}
// The first sight of a Force horror: Jedi feel it (25), troops less (10).
function horrorSeen(e){if(!e.horror||e.hid||e.seenH)return;e.seenH=1;for(const p of players().filter(p=>p.status==='ok'&&!p.vip&&los(p,e)))panicCheck(p,p.jedi?25:10,`the sight of the ${FOES[e.type]?FOES[e.type].n:e.n}`)}
// Runs at the start of the panicked unit's turn. It loses that turn either way.
function doPanic(u){const k=u.panic;u.panic=null;u.ap=0;
 if(k==='freeze'){u.hunker=1;fx(u,'FROZEN');log(`${u.n} is frozen with fear and ducks down.`,'bad');return}
 if(k==='flee'){const R=reach(u),F=enemies().filter(e=>!e.hid);let best=null,bs=-1e9;
  for(const key of Object.keys(R.d)){const [x,y]=key.split(',').map(Number),p={x,y},s=(F.length?Math.min(...F.map(e=>dist(e,p))):0)+(inCover(p)?3:0);if(s>bs){bs=s;best=p}}
  log(`${u.n} breaks and runs for cover.`,'bad');if(best)moveAlong(u,pathTo(u,best.x,best.y,R.prev));return}
 const T=S.units.filter(o=>o!==u&&alive(o)&&o.status!=='down'&&!o.hid&&dist(u,o)<=u.range&&los(u,o));
 if(!T.length){log(`${u.n} fires wildly at nothing.`,'bad');return}const t=pickOne(T);
 log(`${u.n} fires wildly${t.side==='p'?` and the shot goes toward ${t.n}`:''}!`,'bad');resolve(u,t,Math.max(5,hitChance(u,t)-20),u.dmg,{label:'wild shot'})}

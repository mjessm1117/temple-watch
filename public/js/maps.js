/* Maps & Tactics (Chat M, wave 5). Data: data-maps.js. Loads after hazards.js, before screens.js.
   1. Any board size: W/H follow S.grid (data.js); the 2D board and its overlay resize here.
   2. Entry points (M.entries [[x,y,'name'],…]): waves and reinforcements come from several map edges, announced a turn ahead.
   3. Operations (type 'op', M.phases): reach → hold → chase → extract, one step at a time. Threat past par works as usual.
   4. Overwatch you can see: amber zones for every unit on overwatch, an OVERWATCH call-out when it fires, a log line when it held.
   5. Bigger maps: enemies with nothing in range advance on the squad (or the zone being held) instead of idling.
   Wraps: render, spawn, dropship, startMission, startPlayerTurn, checkEnd, evacCheck, objStat, eAct, tileScore, reactOne. */

const MAPKIND={reach:'Reach',hold:'Hold',chase:'Chase',extract:'Extract'};
const phNow=()=>S&&S.type==='op'&&S.ph&&S.M.phases?S.M.phases[S.ph.i]:null;
const inZone=(u,p)=>!!p&&!!p.at&&cheb(u,{x:p.at[0],y:p.at[1]})<=(p.r??1);
const squadUp=()=>players().filter(u=>!u.vip&&u.status==='ok');

// ---- 1. Board size (2D) ----
const _mRender=render;
render=function(){_mRender();if(!S)return;const b=$('#board');if(!b)return;const k=W+'x'+H;
 if(b.dataset.wh!==k){b.dataset.wh=k;b.style.gridTemplateColumns=`repeat(${W},1fr)`;const o=$('#over');if(o)o.setAttribute('viewBox',`0 0 ${W} ${H}`);
  b.parentElement&&b.parentElement.style.setProperty('--board-ar',(W/H).toFixed(3))}
 for(const m of mapMarks()){const c=b.querySelector(`[data-x="${m.x}"][data-y="${m.y}"]`);if(c)c.classList.add('mk-'+m.k)}};

// ---- 2. Entry points ----
// Pick where the next group comes in: an entry 4+ tiles from the squad, not the one used last time if there is a choice.
function pickEntry(){const E=(S.M.entries||[]).map(([x,y,n])=>({x,y,n:n||'map edge'})),P=squadUp();if(!E.length)return null;
 let C=E.filter(e=>P.every(p=>dist(p,e)>=4));if(!C.length)C=E;const last=S.lastEntry;if(C.length>1)C=C.filter(e=>!(last&&e.x===last.x&&e.y===last.y));
 const e=pickOne(C);S.lastEntry={x:e.x,y:e.y};return e}
function placeAt(e,list){const spots=tilesWhere((c,x,y)=>PASS(c)&&c!=='E'&&!unitAt(x,y)&&cheb(e,{x,y})<=2).sort((a,b)=>dist(a,e)-dist(b,e)),got=[];
 list.forEach((t,i)=>{const p=spots[i];if(p){const f=mkFoe(t,p.x,p.y);S.units.push(f);got.push(f);horrorSeen(f)}});formPods(got);return got}
const _mSpawn=spawn;
spawn=function(list){if(!S.M.entries)return _mSpawn(list);list=[...list];for(let i=0;i<S.d.extra;i++)list.push('trooper');
 const e=S.inbound&&S.inbound.turn===S.turn?S.inbound:pickEntry();S.inbound=null;const got=placeAt(e,list);
 fx(e,'CONTACT','dmg');log(`Contact: ${got.length} hostiles from the ${e.n}.`,'bad')};
// Reinforcements (Threat, beacons, phase waves) land at an entry instead of a random flare.
const _mDrop=dropship;
dropship=function(list,delay=1){if(!S.M.entries)return _mDrop(list,delay);list=[...list];for(let i=0;i<S.d.extra;i++)list.push('trooper');
 const e=pickEntry(),d={x:e.x,y:e.y,list,turn:S.turn+delay,n:e.n};fx(e,'INBOUND','dmg');
 log(`${list.length} hostiles inbound from the ${e.n}${delay?' next turn':''}.`,'bad');S.drops.push(d);if(!delay)landDrops()};

// ---- 3. Operations ----
const _mStart=startMission;
startMission=function(id,squad,o={}){_mStart(id,squad,o);if(!S||S.over)return;S.ow0=[];
 if(S.type==='op'){S.ph={i:0,held:0};phBegin()}announceNext();render()};
// Announce next turn's wave and where it enters.
function announceNext(){const M=S.M;if(S.over||!M.entries||!M.waves||!M.waves[S.turn+1])return;const e=pickEntry();S.inbound={...e,turn:S.turn+1};
 fx(e,'INBOUND','dmg');log(`Next turn: ${M.waves[S.turn+1].length} hostiles from the ${e.n}.`,'bad')}
function phBegin(){const p=phNow();if(!p)return;log(`Objective ${S.ph.i+1}/${S.M.phases.length}: ${p.n}`,'good');if(p.at)fx({x:p.at[0],y:p.at[1]},MAPKIND[p.k].toUpperCase(),'heal');
 if(p.wave)dropship(p.wave,p.now?0:1);
 if(p.k==='chase'){const [t,x,y]=p.foe,q=unitAt(x,y)?floorNear({x,y},2)[0]:{x,y};const f=mkFoe(t,q.x,q.y);f.runner={x:p.exit[0],y:p.exit[1]};f.noCap=0;S.units.push(f);S.runner=f.uid;
  fx(f,'RUNNER','dmg');log(`${f.n} breaks for the ${p.exitN||'exit'}! Drop him before he gets there.`,'bad')}}
function phNext(){S.ph.i++;S.ph.held=0;if(S.ph.i>=S.M.phases.length)return finish(true,S.M.win);fx(squadUp()[0]||{x:0,y:0},'OBJECTIVE','heal');phBegin()}
// Instant steps (reach, chase, extract) are checked after every action; hold ticks once per turn.
function phCheck(){if(!S||S.over||S.type!=='op')return;const p=phNow();if(!p)return;const sq=squadUp();
 if(p.k==='reach'&&sq.some(u=>inZone(u,p))){log(`${p.n}: done.`,'good');return phNext()}
 if(p.k==='chase'){const r=byId(S.runner);if(!r||r.status!=='ok'){log(r?`${r.n} is stopped.`:'The runner is down.','good');return phNext()}}
 if(p.k==='extract'&&sq.length&&sq.every(u=>tile(u.x,u.y)==='E'))return finish(true,S.M.win)}
function phHold(){const p=phNow();if(!p||p.k!=='hold')return;const z=enemies().filter(e=>e.status==='ok'&&!e.hid&&inZone(e,p)),in_=squadUp().filter(u=>inZone(u,p));
 if(!in_.length){log(`Nobody holds the ${p.zn||'zone'}. Get back in.`,'bad');return}
 if(z.length){fx({x:p.at[0],y:p.at[1]},'CONTESTED','dmg');log(`The ${p.zn||'zone'} is contested. Clear it to keep the count.`,'bad');return}
 S.ph.held++;fx({x:p.at[0],y:p.at[1]},`HELD ${S.ph.held}/${p.turns}`,'heal');if(S.ph.held>=p.turns){log(`${p.n}: done.`,'good');phNext()}}
// A runner flees to its exit each enemy turn. If it gets there, the operation fails.
const _mEAct=eAct;
eAct=async function(e){if(!e.runner||e.status!=='ok'||S.over)return _mEAct(e);
 const R=reach(e);let best=null,bd=1e9;for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),d=dist({x,y},e.runner)-(inCover({x,y})?.3:0);if(d<bd){bd=d;best={x,y}}}
 if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(380)}
 if(e.status==='ok'&&cheb(e,e.runner)<=0){S.units=S.units.filter(u=>u!==e);finish(false,`${e.n} gets away. ${S.M.lose}`)}};
const _mCheckEnd=checkEnd;checkEnd=function(){_mCheckEnd();phCheck()};
const _mEvac=evacCheck;evacCheck=function(){_mEvac();phCheck()};
const _mObj=objStat;
objStat=function(){const p=phNow();if(!p)return _mObj();const r=p.k==='chase'&&byId(S.runner);
 return{label:`${S.ph.i+1}/${S.M.phases.length} ${MAPKIND[p.k]}`,val:p.k==='hold'?`${S.ph.held}/${p.turns} turns`:r?`${r.n} ${r.hp}/${r.max}`:p.k==='extract'?'all on evac':p.n}};
THREAT_LOSE.op='The window closes and the squad has to pull out.';

// ---- 4. Overwatch you can see ----
const _mReact=reactOne;
reactOne=function(o,u){const ow=o.ow,owHit=o.owHit&&o.owHit.length,fired=_mReact(o,u);
 if(fired&&ow&&(!o.ow||o.ow==='all'&&o.owHit&&o.owHit.length>owHit)){fx(o,'OVERWATCH','dmg');(S.owFired=S.owFired||[]).push(o.uid)}return fired};
const _mPTurn=startPlayerTurn;
startPlayerTurn=function(){if(S&&S.turn>1){const held=players().filter(u=>u.ow&&u.status==='ok'&&!(S.owFired||[]).includes(u.uid));
  if(held.length)log(`Overwatch held: nothing moved through ${held.map(u=>u.n).join(', ')}'s sight.`)}
 S.owFired=[];_mPTurn();if(!S.over&&S.type==='op')phHold();announceNext();render()};
// Tiles a unit on overwatch covers: in range, in sight, walkable.
let owKey='',owT=[];
function owTiles(){const W0=S.units.filter(u=>alive(u)&&u.status==='ok'&&u.ow&&!u.hid&&u.range>=2),k=S.turn+'|'+W0.map(u=>u.uid+':'+u.x+','+u.y).join(';')+'|'+S.grid.map(r=>r.join('')).join('');
 if(k===owKey)return owT;owKey=k;const m=new Map();
 for(const u of W0)for(let y=Math.max(0,u.y-u.range|0);y<=Math.min(H-1,u.y+u.range);y++)for(let x=Math.max(0,u.x-u.range|0);x<=Math.min(W-1,u.x+u.range);x++){
  const t={x,y};if((x!==u.x||y!==u.y)&&dist(u,t)<=u.range&&PASS(tile(x,y))&&los(u,t))m.set(x+','+y,{x,y,k:u.side==='p'?'ow':'owe'})}
 return owT=[...m.values()]}

// ---- Marks for both views: objective zone, incoming groups, overwatch zones ----
function mapMarks(){if(!S||S.over)return[];const out=[],p=phNow();
 if(p&&p.at&&p.k!=='chase'){const r=p.r??1;for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){const x=p.at[0]+dx,y=p.at[1]+dy;if(inb(x,y)&&PASS(tile(x,y)))out.push({x,y,k:'zone'})}}
 if(p&&p.k==='chase'){const r=byId(S.runner);if(r&&r.runner)out.push({x:r.runner.x,y:r.runner.y,k:'exit'})}
 for(const d of [...(S.drops||[]),...(S.inbound?[S.inbound]:[])])for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const x=d.x+dx,y=d.y+dy;if(inb(x,y)&&PASS(tile(x,y)))out.push({x,y,k:'in'})}
 if(S.phase!=='over')out.push(...owTiles());return out}
window.mapMarks=mapMarks;

// ---- 5. Bigger maps: nothing in range → close in (or crowd the zone being held) ----
const _mScore=tileScore;
tileScore=function(e,pos){let s=_mScore(e,pos);if(!S.M.big&&S.type!=='op')return s;const P=squadUp();if(!P.length)return s;
 const near=P.some(p=>dist(p,e)<=e.range+1);if(!near&&!e.horror&&e.range>=2)s-=Math.min(...P.map(p=>dist(p,pos)))*2;
 const p=phNow();if(p&&p.k==='hold'&&p.at)s-=dist(pos,{x:p.at[0],y:p.at[1]})*.8;return s};

// Bot hook (tests/bot.js): where a squad member should head on an operation. Undefined = no opinion.
function mapGoal(u){const p=phNow();if(!p||u.vip)return undefined;const here={x:u.x,y:u.y};
 if(p.k==='reach'||p.k==='hold'){if(inZone(u,p))return here;const z={x:p.at[0],y:p.at[1]};return z}
 if(p.k==='chase'){const r=byId(S.runner);return r&&r.status==='ok'&&dist(u,r)>u.range*.7?{x:r.x,y:r.y}:undefined}
 if(p.k==='extract'){if(tile(u.x,u.y)==='E')return here;return tilesWhere((c,x,y)=>c==='E'&&!unitAt(x,y)).sort((a,b)=>dist(u,a)-dist(u,b))[0]}}
window.mapGoal=mapGoal;

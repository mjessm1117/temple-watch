// Test bot, injected into the game page. One-ply greedy: objective first, then rescue allies, then the best attack, else advance or hold.
window.AI=function(){while(S.bv&&S.bv.q&&S.bv.q.length&&!S.over)bvPick(Math.random()<.5?0:1);if(S.conc&&stealthTurn())return;for(let n=0;n<24;n++){const u=players().find(canAct);if(!u||S.over)break;S.sel=u;act(u)}};
function pick(u,k){if(!u.abil.includes(k))return null;const ab=AB[k];if(ab.passive||(ab.f&&u.focus<ab.f)||(ab.avail&&ab.avail(u)))return null;
 if(ab.instant)return[k,null];const t=targetsFor(u,k).sort((a,b)=>(b.chance||0)-(a.chance||0))[0];return t?[k,t]:null}
function goalFor(u){u.stay=0;if(window.mapGoal){const g=mapGoal(u);if(g!==undefined){if(g&&g.x===u.x&&g.y===u.y){u.stay=1;return null}if(g)return g}}if(window.sigGoal){const g=sigGoal(u);if(g!==undefined){if(g&&g.x===u.x&&g.y===u.y){u.stay=1;return null}if(g)return g}}
 if(u.vip)return S.grid.flatMap((r,y)=>r.map((c,x)=>c==='E'?{x,y}:null)).filter(Boolean).sort((a,b)=>dist(u,a)-dist(u,b))[0];
 if(S.type==='investigate'){if(S.clues>=2)return goalFor({...u,vip:1});const q=tilesWhere(c=>c==='q').sort((a,b)=>dist(u,a)-dist(u,b))[0];
  if(q&&u.abil.includes('scan')&&!players().some(p=>p!==u&&p.abil.includes('scan')&&dist(p,q)<dist(u,q)))return cheb(u,q)>1?q:null}
 if(S.type==='sabotage'){if(tilesWhere(c=>c==='X').length>=S.M.need){if(tile(u.x,u.y)==='E')return null;return tilesWhere((c,x,y)=>c==='E'&&!unitAt(x,y)).sort((a,b)=>dist(u,a)-dist(u,b))[0]}
  const cs=tilesWhere(c=>c==='C').sort((a,b)=>dist(u,a)-dist(u,b))[0];if(cs&&!players().some(p=>p!==u&&!p.vip&&p.status==='ok'&&dist(p,cs)<dist(u,cs)))return cheb(u,cs)>1?cs:null}
 if(S.type==='rescue'&&tilesWhere(c=>c==='D').length){if(u.abil.includes('hack')){const d=tilesWhere(c=>c==='D')[0];return dist(u,d)>4?d:null}
  if(u.abil.includes('console')&&!players().some(p=>p.abil.includes('hack')&&p.status==='ok')){const k=tilesWhere(c=>c==='k')[0];return cheb(u,k)>1?k:null}}
 return null}
function moveToward(u,g,near=0){const R=reach(u);let best=null,bd=dist(u,g)-.5;
 for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),t=TILES[tile(x,y)]||{},d=dist({x,y},g)-(inCover({x,y})?.4:0)+(t.hurt?2:0)+(t.slide?.6:0);if(R.d[k]>0&&d<bd){bd=d;best={x,y}}}
 if(!best)return false;moveAlong(u,pathTo(u,best.x,best.y,R.prev));u.ap--;after();return true}
function act(u){const go=c=>{exec(u,c[0],c[1]);return true};
 for(const k of ['hack','console','scan','plant','door','defuse','light','rouse','wreck'])if(pick(u,k))return go(pick(u,k));
 let c=pick(u,'forceRevive')||pick(u,'stabilize');if(!c&&u.abil.includes('heal')){const d=pick(u,'heal');if(d&&d[1].t.status==='down')c=d}if(c)return go(c);
 const dn=players().find(p=>p.status==='down'&&!p.stable&&!p.vip&&dist(u,p)<=u.mob+1);if(dn&&!u.vip&&u.ap===2&&cheb(u,dn)>1&&moveToward(u,dn))return true;
 const g=goalFor(u);if(g&&moveToward(u,g))return true;
 if(S.type==='sabotage'&&!u.vip&&tile(u.x,u.y)==='E'&&tilesWhere(c=>c==='X').length>=S.M.need){const s=pick(u,'shoot');return go(s&&s[1].t&&s[1].chance>=45?s:[u.jedi?'guard':'overwatch',null])}
 if(u.vip){u.ap=0;return after()}
 if(u.jedi){c=pick(u,'subdue')||pick(u,'saberThrow')||pick(u,'strike');if(c&&c[0]==='strike'&&c[1].spot.path.length>3)c=pick(u,'push')||c}
 if(!c&&S.beacon){const b=targetsFor(u,'shoot').find(g=>g.beacon);if(b)c=['shoot',b]}
 if(!c){const s=pick(u,'shoot');if(s&&s[1].beacon)s[1]=targetsFor(u,'shoot').filter(g=>g.t).sort((a,b)=>b.chance-a.chance)[0];if(s&&s[1]&&(s[1].pylon?1:s[1].barrel?enemies().some(e=>cheb(e,s[1])<=1)&&!players().some(p=>cheb(p,s[1])<=1):s[1].t.status==='ok'&&s[1].chance>=45))c=s}
 if(!c&&u.nades){const gs=targetsFor(u,'grenade').map(g=>({g,n:enemies().filter(e=>e.status==='ok'&&!e.hid&&cheb(e,g)<=1).length,m:players().filter(p=>cheb(p,g)<=1).length})).filter(o=>o.n>=2&&!o.m);if(gs.length)c=['grenade',gs[0].g]}
 if(c)return go(c);
 if(S.type!=='defend'&&u.ap===2&&!u.stay){const e=enemies().filter(e=>!e.hid&&e.status==='ok').sort((a,b)=>dist(u,a)-dist(u,b))[0];if(e&&dist(u,e)>(u.range<2?1.5:u.range*.6)&&moveToward(u,e))return true}
 return go([u.jedi?'guard':u.abil.includes('hunker')&&u.hp*2<=u.max?'hunker':'overwatch',null])}

// Concealed (stealth missions): creep only through tiles outside enemy sight (red tiles), toward the objective or an ambush spot.
// Once someone has a 55%+ shot (or from turn 3), everyone else sets overwatch/guard and the best shot springs the ambush.
function safePath(u,R,k,red){let c=k;while(c&&c!==u.x+','+u.y){if(red.has(c))return false;c=R.prev[c]}return true}
function bestShot(u,pos){const a={...u,...pos};let b=0;if(u.range<2||!u.abil.includes('shoot'))return 0;
 for(const e of enemies())if(!e.hid&&e.status==='ok'&&dist(a,e)<=u.range&&los(a,e))b=Math.max(b,hitChance(a,e));return b}
function stealthTurn(){const red=new Set(visionTiles().map(p=>p.x+','+p.y)),sq=players().filter(u=>canAct(u)&&!u.vip);
 for(const u of [...sq,...sq.filter(u=>goalFor(u))]){if(!S.conc)return false;
  for(const k of ['hack','console','scan','plant','door','defuse','light','rouse','wreck']){const c=pick(u,k);if(c){exec(u,c[0],c[1]);break}}if(!S.conc)return false;if(!canAct(u))continue;
  const g=goalFor(u),foe=enemies().filter(e=>!e.hid&&e.status==='ok').sort((a,b)=>dist(u,a)-dist(u,b))[0],tgt=g||foe;if(!tgt)continue;
  const R=reach(u);let best=null,bs=-1e9;
  for(const k of Object.keys(R.d)){if(!R.d[k]||!safePath(u,R,k,red))continue;const [x,y]=k.split(',').map(Number),p={x,y};
   const s=g?-dist(p,g):bestShot(u,p)+(inCover(p)?8:0)-dist(p,tgt)*.5;if(s>bs){bs=s;best=p}}
  if(best){moveAlong(u,pathTo(u,best.x,best.y,R.prev));u.ap--;after()}}
 if(!S.conc)return false;
 const sh=players().filter(u=>canAct(u)&&!u.vip).map(u=>({u,c:pick(u,'shoot')})).filter(o=>o.c&&o.c[1].t).sort((a,b)=>b.c[1].chance-a.c[1].chance)[0];
 if(sh&&(sh.c[1].chance>=55||S.turn>=3)){for(const u of players().filter(u=>canAct(u)&&!u.vip&&u!==sh.u))exec(u,u.jedi?'guard':'overwatch',null);exec(sh.u,'shoot',sh.c[1]);return true}
 if(S.turn>=4)return false;
 for(const u of players().filter(u=>canAct(u)&&!u.vip))exec(u,u.jedi?'guard':'overwatch',null);return true}
// Signature objectives (battle.js): the nearest able unit takes each job. Returns a tile to go to, the unit's own tile to hold it, or undefined.
function sigGoal(u){const b=S.bv;if(!b||u.vip)return undefined;const sq=players().filter(q=>!q.vip&&q.status==='ok'&&!(b.relic&&b.relic.by===q.uid)),here={x:u.x,y:u.y};
 const first=t=>sq.slice().sort((a,c)=>dist(a,t)-dist(c,t))[0]===u,near=(L)=>L.sort((a,c)=>dist(u,a)-dist(u,c))[0];
 if(b.relic){if(b.relic.by===u.uid)return tile(u.x,u.y)==='E'?here:near(tilesWhere(c=>c==='E'));if(b.relic.by==null&&first(b.relic))return{x:b.relic.x,y:b.relic.y}}
 for(const m of (b.bombs||[]).slice().sort((a,c)=>a.t-c.t))if(first(m))return cheb(u,m)>1?m:undefined;
 for(const t of tilesWhere(c=>c==='L'))if(first(t))return cheb(u,t)>1?t:undefined;
 for(const id of b.wd||[]){const w=byId(id);if(w&&w.status==='down'&&w.wounded&&first(w))return cheb(u,w)>1?{x:w.x,y:w.y}:undefined}
 if(b.pad&&(SIG[S.id].pads.need||S.turn>=(S.M.par||0)-1)){if(tile(u.x,u.y)==='U')return here;const P=tilesWhere(c=>c==='U');for(const p of P)if(!unitAt(p.x,p.y)&&first(p)&&!sq.some(q=>q!==u&&tile(q.x,q.y)==='U'))return p}
 if(b.pyl&&u.jedi&&(SIG[S.id].pylons.shieldBoss||b.sp)){const P=Object.keys(b.pyl).map(k=>{const [x,y]=k.split(',').map(Number);return{x,y}});const p=near(P);
  if(p&&sq.filter(q=>q.jedi).sort((a,c)=>dist(a,p)-dist(c,p))[0]===u)return cheb(u,p)>1?p:undefined}
 return undefined}

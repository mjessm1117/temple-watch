// Test bot, injected into the game page. One-ply greedy: objective first, then rescue allies, then the best attack, else advance or hold.
window.AI=function(){for(let n=0;n<24;n++){const u=players().find(canAct);if(!u||S.over)break;S.sel=u;act(u)}};
function pick(u,k){if(!u.abil.includes(k))return null;const ab=AB[k];if(ab.passive||(ab.f&&u.focus<ab.f)||(ab.avail&&ab.avail(u)))return null;
 if(ab.instant)return[k,null];const t=targetsFor(u,k).sort((a,b)=>(b.chance||0)-(a.chance||0))[0];return t?[k,t]:null}
function goalFor(u){
 if(u.vip)return S.grid.flatMap((r,y)=>r.map((c,x)=>c==='E'?{x,y}:null)).filter(Boolean).sort((a,b)=>dist(u,a)-dist(u,b))[0];
 if(S.type==='investigate'){if(S.clues>=2)return goalFor({...u,vip:1});const q=tilesWhere(c=>c==='q').sort((a,b)=>dist(u,a)-dist(u,b))[0];
  if(q&&u.abil.includes('scan')&&!players().some(p=>p!==u&&p.abil.includes('scan')&&dist(p,q)<dist(u,q)))return cheb(u,q)>1?q:null}
 if(S.type==='rescue'&&tilesWhere(c=>c==='D').length){if(u.abil.includes('hack')){const d=tilesWhere(c=>c==='D')[0];return dist(u,d)>4?d:null}
  if(u.abil.includes('console')&&!players().some(p=>p.abil.includes('hack')&&p.status==='ok')){const k=tilesWhere(c=>c==='k')[0];return cheb(u,k)>1?k:null}}
 return null}
function moveToward(u,g,near=0){const R=reach(u);let best=null,bd=dist(u,g)-.5;
 for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),d=dist({x,y},g)-(inCover({x,y})?.4:0);if(R.d[k]>0&&d<bd){bd=d;best={x,y}}}
 if(!best)return false;moveAlong(u,pathTo(u,best.x,best.y,R.prev));u.ap--;after();return true}
function act(u){const go=c=>{exec(u,c[0],c[1]);return true};
 for(const k of ['hack','console','scan'])if(pick(u,k))return go(pick(u,k));
 let c=pick(u,'forceRevive')||pick(u,'stabilize');if(!c&&u.abil.includes('heal')){const d=pick(u,'heal');if(d&&d[1].t.status==='down')c=d}if(c)return go(c);
 const dn=players().find(p=>p.status==='down'&&!p.stable&&!p.vip&&dist(u,p)<=u.mob+1);if(dn&&!u.vip&&u.ap===2&&cheb(u,dn)>1&&moveToward(u,dn))return true;
 const g=goalFor(u);if(g&&moveToward(u,g))return true;
 if(u.vip){u.ap=0;return after()}
 if(u.jedi){c=pick(u,'subdue')||pick(u,'saberThrow')||pick(u,'strike');if(c&&c[0]==='strike'&&c[1].spot.path.length>3)c=pick(u,'push')||c}
 if(!c){const s=pick(u,'shoot');if(s&&(s[1].barrel?enemies().some(e=>cheb(e,s[1])<=1)&&!players().some(p=>cheb(p,s[1])<=1):s[1].t.status==='ok'&&s[1].chance>=45))c=s}
 if(!c&&u.nades){const gs=targetsFor(u,'grenade').map(g=>({g,n:enemies().filter(e=>e.status==='ok'&&!e.hid&&cheb(e,g)<=1).length,m:players().filter(p=>cheb(p,g)<=1).length})).filter(o=>o.n>=2&&!o.m);if(gs.length)c=['grenade',gs[0].g]}
 if(c)return go(c);
 if(S.type!=='defend'&&u.ap===2){const e=enemies().filter(e=>!e.hid&&e.status==='ok').sort((a,b)=>dist(u,a)-dist(u,b))[0];if(e&&dist(u,e)>(u.range<2?1.5:u.range*.6)&&moveToward(u,e))return true}
 return go([u.jedi?'guard':u.abil.includes('hunker')&&u.hp*2<=u.max?'hunker':'overwatch',null])}

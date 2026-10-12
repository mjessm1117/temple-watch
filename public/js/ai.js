/* Enemy AI: seeks cover, flanks, focuses weak targets. */
/* ---------- Enemy AI: cover-seeking, flanking, focuses weak or exposed targets ---------- */
function bestBlast(e,pos){let best=null;
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){if(dist(pos,{x,y})>6||FULL(tile(x,y)))continue;
  const hit=S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1),n=hit.filter(u=>u.side==='p').length,m=hit.filter(u=>u.side==='e').length;
  if(!n)continue;let s=40+n*22-m*45;if(hit.some(u=>u.side==='p'&&inCover(u)))s+=10;if(n>=2&&(!best||s>best.score))best={kind:'nade',x,y,score:s}}
 return best}
function eAttacks(e,pos){const a={...e,x:pos.x,y:pos.y},out=[];
 for(const p of players().filter(p=>p.status==='ok')){
  if(e.type==='acolyte'){if(cheb(pos,p)===1)out.push({kind:'melee',t:p,chance:hitChance(a,p,{melee:true}),dmg:e.dmg});else if(dist(pos,p)<=5&&los(pos,p))out.push({kind:'lightning',t:p,chance:80,dmg:[3,4]})}
  else if(dist(pos,p)<=e.range&&los(pos,p))out.push({kind:'shot',t:p,chance:hitChance(a,p),dmg:e.dmg})}
 for(const o of out){let s=o.chance;if((o.dmg[0]+o.dmg[1])/2>=o.t.hp)s+=25;if(o.kind==='shot'&&flanked(o.t,pos))s+=10;
  if(o.t.jedi){if(e.type==='acolyte')s+=20;else if(o.kind==='shot')s-=(o.t.guard?o.t.guardDef:o.t.deflect)*.6}o.score=s}
 if(e.type!=='acolyte'){const c=nearestConsole(pos);if(dist(pos,c)<=e.range&&los(pos,c))out.push({kind:'console',c,chance:e.aim-15,dmg:e.dmg,score:34})}
 if(e.nades>0){const g=bestBlast(e,pos);if(g&&g.score>=70)out.push(g)}
 out.sort((x,y)=>y.score-x.score);return out[0]||null}
function tileScore(e,pos){let s=Math.random()*3;const P=players().filter(p=>p.status==='ok');
 for(const p of P)if(dist(p,pos)<=10&&los(p,pos))s-=(40-coverVal(pos,p))/2;
 const a=eAttacks(e,pos);if(a)s+=a.score*.6;
 if(e.type==='acolyte'){const j=P.filter(p=>p.jedi),T=j.length?j:P;if(T.length)s-=Math.min(...T.map(p=>dist(p,pos)))*4}
 else s-=dist(pos,nearestConsole(pos))*2.5;
 return s}
async function eDo(e,a){
 if(a.kind==='console'){if(!rnd(a.chance)){fx(a.c,'MISS');log(`${e.n} fires at the relay and misses.`)}else{const d=ri(a.dmg[0],a.dmg[1]);S.cons=Math.max(0,S.cons-d);fx(a.c,'-'+d);log(`${e.n} blasts the relay for ${d}.`,'bad')}}
 else if(a.kind==='nade'){e.nades--;log(`${e.n} throws a grenade!`,'bad');blast(a.x,a.y,3,e)}
 else if(a.kind==='lightning'){log(`${e.n} unleashes Force lightning.`,'dark');resolve(e,a.t,a.chance,a.dmg,{ignoreDeflect:1,label:'lightning'})}
 else resolve(e,a.t,a.chance,a.dmg,{melee:a.kind==='melee',label:a.kind==='melee'?'saber':'shot'});
 render();await sleep(500)}
async function eAct(e){
 if(e.status==='stunned'){e.status='ok';log(`${e.n} shakes off the stun.`);return}
 if(e.status!=='ok')return;
 S.peek=e;let a=eAttacks(e,e);
 if(a&&a.score>=65){await eDo(e,a);return}
 const R=reach(e);let best=null,bs=-1e9;
 for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),s=tileScore(e,{x,y});if(s>bs){bs=s;best={x,y}}}
 if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(380)}
 if(e.status!=='ok'||S.over)return;
 a=eAttacks(e,e);if(a&&a.score>=15)await eDo(e,a)}

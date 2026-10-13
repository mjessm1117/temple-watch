/* Enemy AI: cover-seeking, flanking, focuses weak or exposed targets. Horrors hunt Jedi only; agents wait in hiding. */
function bestBlast(e,pos){let best=null;
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){if(dist(pos,{x,y})>6||FULL(tile(x,y)))continue;
  const hit=S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1),n=hit.filter(u=>u.side==='p').length,m=hit.filter(u=>u.side==='e').length;
  if(!n)continue;let s=40+n*22-m*45;if(hit.some(u=>u.side==='p'&&inCover(u)))s+=10;if(n>=2&&(!best||s>best.score))best={kind:'nade',x,y,score:s}}
 return best}
// Who this enemy is willing to attack. The prisoner: once freed, or in the cell after Threat rises; one shot per enemy turn.
function eTargets(e){let P=players().filter(p=>p.status==='ok'&&(!p.vip||((!p.bound||S.threat>=1)&&!S.hostShot)));if(e.horror)P=P.filter(p=>p.jedi);return P}
function eAttacks(e,pos){const a={...e,x:pos.x,y:pos.y},out=[];
 for(const p of eTargets(e)){
  if(e.range<2){if(cheb(pos,p)===1)out.push({kind:'melee',t:p,chance:hitChance(a,p,{melee:true}),dmg:e.dmg});else if(e.lightning&&dist(pos,p)<=5&&los(pos,p))out.push({kind:'lightning',t:p,chance:80,dmg:e.lightning})}
  else if(dist(pos,p)<=e.range&&los(pos,p))out.push({kind:'shot',t:p,chance:p.vip?50:hitChance(a,p),dmg:e.dmg})}
 for(const o of out){let s=o.chance;if((o.dmg[0]+o.dmg[1])/2>=o.t.hp)s+=25;if(o.kind==='shot'&&flanked(o.t,pos))s+=10;if(o.t.vip)s+=20;
  if(o.t.jedi){if(e.force||e.horror)s+=20;else if(o.kind==='shot')s-=(o.t.guard?o.t.guardDef:o.t.deflect)*.6}o.score=s}
 if(S.type==='defend'&&e.range>=2){const c=nearestConsole(pos);if(dist(pos,c)<=e.range&&los(pos,c))out.push({kind:'console',c,chance:e.aim-15,dmg:e.dmg,score:34})}
 if(e.nades>0){const g=bestBlast(e,pos);if(g&&g.score>=70)out.push(g)}
 out.sort((x,y)=>y.score-x.score);return out[0]||null}
function tileScore(e,pos){let s=Math.random()*3;const P=players().filter(p=>p.status==='ok'&&!p.vip);
 if(!e.horror)for(const p of P)if(dist(p,pos)<=10&&los(p,pos))s-=(40-coverVal(pos,p))/2;
 const a=eAttacks(e,pos);if(a)s+=a.score*.6;
 if(e.range<2){const j=P.filter(p=>p.jedi),T=(e.force||e.horror)&&j.length?j:P;if(T.length)s-=Math.min(...T.map(p=>dist(p,pos)))*4}
 else if(S.type==='defend')s-=dist(pos,nearestConsole(pos))*2.5;
 else if(P.length)s-=Math.max(0,Math.min(...P.map(p=>dist(p,pos)))-e.range*.7)*2;
 return s}
async function eDo(e,a){e.hid=0;if(a.t&&a.t.vip)S.hostShot=1;
 if(a.kind==='console'){if(!rnd(a.chance)){fx(a.c,'MISS','miss');log(`${e.n} fires at the ${S.M.objName.toLowerCase()} and misses.`)}else{const d=ri(a.dmg[0],a.dmg[1]);S.obj=Math.max(0,S.obj-d);fx(a.c,'-'+d,'dmg');log(`${e.n} blasts the ${S.M.objName.toLowerCase()} for ${d}.`,'bad')}}
 else if(a.kind==='nade'){e.nades--;log(`${e.n} throws a grenade!`,'bad');blast(a.x,a.y,3,e)}
 else if(a.kind==='lightning'){log(`${e.n} unleashes Force lightning.`,'dark');resolve(e,a.t,a.chance,a.dmg,{ignoreDeflect:1,label:'lightning'})}
 else resolve(e,a.t,a.chance,a.dmg,{melee:a.kind==='melee',label:a.kind==='melee'?(e.horror?'claws':'saber'):'shot'});
 render();await sleep(500)}
async function eAct(e){
 if(e.status==='stunned'){e.status='ok';log(`${e.n} shakes off the stun.`);return}
 if(e.status!=='ok')return;
 if(e.tricked){e.tricked=0;S.peek=e;const melee=e.range<2,o=enemies().filter(o=>o!==e&&o.status==='ok'&&!o.hid&&(melee?cheb(e,o)===1:dist(e,o)<=e.range&&los(e,o)));
  if(o.length){const t=o.sort((x,y)=>x.hp-y.hp)[0];log(`${e.n}, mind clouded, turns on ${t.n}.`,'good');resolve(e,t,hitChance(e,t,{melee}),e.dmg,{melee,label:'confused attack'});render();await sleep(500)}
  else log(`${e.n} stands confused.`);return}
 // Hidden agents wait until someone comes within 6 or they get a 70%+ shot.
 if(e.hid&&!players().some(p=>p.status==='ok'&&!p.vip&&dist(p,e)<=6)){const a=eAttacks(e,e);if(!a||a.kind!=='shot'||a.chance<70)return}
 // An enemy beside an idle alarm beacon trips it once the squad is in sight: reinforcements in 2 turns unless it is wrecked.
 if(!S.beacon&&!S.beaconUsed&&!e.hid){const b=tilesWhere((c,x,y)=>c==='b'&&cheb(e,{x,y})===1)[0];
  if(b&&players().some(p=>p.status==='ok'&&dist(p,e)<=9&&los(p,e))){S.beacon={x:b.x,y:b.y,turn:S.turn+2};S.beaconUsed=1;S.peek=e;fx(b,'ALARM','dmg');log(`${e.n} trips an alarm beacon! Help arrives in 2 turns unless you wreck it.`,'bad');render();await sleep(500);return}}
 S.peek=e.hid?null:e;let a=eAttacks(e,e);
 if(a&&a.score>=65)await eDo(e,a);
 else{const R=reach(e);let best=null,bs=-1e9;
  for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),s=tileScore(e,{x,y});if(s>bs){bs=s;best={x,y}}}
  if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(380)}
  if(e.status==='ok'&&!S.over){a=eAttacks(e,e);if(a&&a.score>=15)await eDo(e,a)}}
 if(e.horror&&e.status==='ok'){const j=S.units.find(u=>u.side==='p'&&u.jedi&&u.status==='down'&&!u.stable&&S.turn>u.downT&&cheb(u,e)===1);
  if(j){j.status='dead';j.consumed=1;fx(j,'TAKEN','dmg');log(`${e.n} drags ${j.n} into the dark. ${j.n} is gone.`,'bad')}}}
// What this enemy would do right now, for the intent preview (spec D §5). Can change once you move.
function intentOf(e){if(!S.beacon&&!S.beaconUsed&&tilesWhere((c,x,y)=>c==='b'&&cheb(e,{x,y})===1).length)return{txt:'Trip the alarm beacon'};const a=eAttacks(e,e);if(!a)return{txt:e.horror?'Hunting the nearest Jedi':S.type==='defend'&&e.range>=2?`Advancing on the ${S.M.objName.toLowerCase()}`:'Moving to a better position'};
 if(a.kind==='console')return{txt:`Shoot the ${S.M.objName.toLowerCase()} · ${a.chance}%`,to:a.c};
 if(a.kind==='nade')return{txt:'Throw a grenade',area:a};
 return{txt:`${a.kind==='melee'?'Attack':a.kind==='lightning'?'Lightning':'Shoot'} ${a.t.n} · ${a.chance}%`,to:a.t}}

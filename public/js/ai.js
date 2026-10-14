/* Enemy AI: cover-seeking, flanking, focuses weak or exposed targets. Horrors hunt Jedi only; agents wait in hiding. */
function bestBlast(e,pos){let best=null;
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){if(dist(pos,{x,y})>6||FULL(tile(x,y)))continue;
  const hit=S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1),n=hit.filter(u=>u.side==='p').length,m=hit.filter(u=>u.side==='e').length;
  if(!n)continue;let s=40+n*22-m*45;if(hit.some(u=>u.side==='p'&&inCover(u)))s+=10;if(n>=2&&(!best||s>best.score))best={kind:'nade',x,y,score:s}}
 return best}
// Who this enemy is willing to attack. The prisoner: once freed, or in the cell after Threat rises; one shot per enemy turn.
function eTargets(e){let P=players().filter(p=>p.status==='ok'&&(!p.conc||cheb(p,e)<=2)&&(!p.vip||((!p.bound||S.threat>=1)&&!S.hostShot)));if(e.horror)P=P.filter(p=>p.jedi);return P}
function eAttacks(e,pos){const a={...e,x:pos.x,y:pos.y},out=[];
 for(const p of eTargets(e)){
  if(e.range<2){if(cheb(pos,p)===1)out.push({kind:'melee',t:p,chance:hitChance(a,p,{melee:true}),dmg:e.dmg});else if(e.lightning&&!e.disarmed&&dist(pos,p)<=5&&los(pos,p))out.push({kind:'lightning',t:p,chance:80,dmg:e.lightning})}
  else if(!e.disarmed&&dist(pos,p)<=e.range&&los(pos,p))out.push({kind:'shot',t:p,chance:p.vip?50:hitChance(a,p),dmg:e.dmg})}
 for(const o of out){let s=o.chance;if((o.dmg[0]+o.dmg[1])/2>=o.t.hp)s+=25;if(o.kind==='shot'&&flanked(o.t,pos))s+=10;if(o.t.vip)s+=20;
  if(o.t.jedi){if(e.force||e.horror)s+=20;else if(o.kind==='shot')s-=(o.t.guard?o.t.guardDef:o.t.deflect)*.6}o.score=s}
 if(S.type==='defend'&&e.range>=2&&!e.disarmed){const c=nearestConsole(pos);if(dist(pos,c)<=e.range&&los(pos,c))out.push({kind:'console',c,chance:e.aim-15,dmg:e.dmg,score:34})}
 if(e.nades>0&&!e.disarmed){const g=bestBlast(e,pos);if(g&&g.score>=70)out.push(g)}
 out.sort((x,y)=>y.score-x.score);return out[0]||null}
function tileScore(e,pos){let s=Math.random()*3+elevAt(pos.x,pos.y)*3;const P=players().filter(p=>p.status==='ok'&&!p.vip);
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
async function eAct(e){await eAct0(e);e.disarmed=0;e.rooted=0}
async function eAct0(e){
 if(e.status==='stunned'){e.status='ok';log(`${e.n} shakes off the stun.`);return}
 if(e.status!=='ok')return;
 if(e.skip)return;
 if(S.conc||asleep(e))return idleAct(e);
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
  if(j){j.status='dead';j.consumed=1;fx(j,'TAKEN','dmg');log(`${e.n} drags ${j.n} into the dark. ${j.n} is gone.`,'bad');allyFell(j,30,`${j.n} taken by the beast`)}}}
// What this enemy would do right now, for the intent preview (spec D §5). Can change once you move.
function intentOf(e){if(S.conc||asleep(e))return{txt:e.hid?'Lying in wait':S.M.patrol&&S.M.patrol[e.pod]?'Patrolling, unaware of you':'On guard, unaware of you'};if(!S.beacon&&!S.beaconUsed&&tilesWhere((c,x,y)=>c==='b'&&cheb(e,{x,y})===1).length)return{txt:'Trip the alarm beacon'};const a=eAttacks(e,e);if(!a)return{txt:e.horror?'Hunting the nearest Jedi':S.type==='defend'&&e.range>=2?`Advancing on the ${S.M.objName.toLowerCase()}`:'Moving to a better position'};
 if(a.kind==='console')return{txt:`Shoot the ${S.M.objName.toLowerCase()} · ${a.chance}%`,to:a.c};
 if(a.kind==='nade')return{txt:'Throw a grenade',area:a};
 return{txt:`${a.kind==='melee'?'Attack':a.kind==='lightning'?'Lightning':'Shoot'} ${a.t.n} · ${a.chance}%`,to:a.t}}

// ---- Stealth & ambush (wave 3, spec A §1). Missions with stealth:true start with the squad concealed (S.conc).
// Foes there belong to pods (4th entry in M.foes; unnamed = a pod of one). A sleeping pod patrols M.patrol[pod] or stands guard.
// Concealed: any enemy within DETECT tiles with line of sight spots the squad (those are the red tiles, visionTiles()).
// Revealed: a sleeping pod wakes when it sees anyone within SIGHT. Waking = scamper: every member dashes to cover, no attack.
// Attacking from concealment gets +20 aim (Ambush), and squad overwatch fires at the scampering pod with no −15 penalty.
const DETECT=4,SIGHT=8;
const asleep=e=>e.pod!=null&&!S.alert[e.pod];
function visionTiles(){if(!S||!S.conc)return[];const W8=enemies().filter(e=>e.status==='ok'&&!e.hid);
 return tilesWhere((c,x,y)=>PASS(c)&&W8.some(e=>dist(e,{x,y})<=DETECT&&los(e,{x,y})))}
const spotterOf=p=>enemies().find(e=>e.status==='ok'&&dist(e,p)<=DETECT&&los(e,p));
// A player step: returns true if contact stops the move.
function watchCheck(u){if(S.amb||S.over)return false;
 if(S.conc){const e=spotterOf(u);if(e){breakConceal(`${e.hid?'Someone':e.n} spots ${u.n}! The squad is revealed.`,e);return true}return false}
 if(u.conc){const e=enemies().find(e=>e.status==='ok'&&!asleep(e)&&cheb(e,u)<=2&&los(e,u));if(e){u.conc=0;fx(u,'SPOTTED','dmg');log(`${e.n} spots ${u.n} in the shadows.`,'bad');return true}}
 const e=enemies().find(e=>asleep(e)&&e.status==='ok'&&dist(e,u)<=SIGHT&&los(e,u));if(e){alertPod(e.pod);return true}return false}
function breakConceal(msg,spotter,ambush){if(!S.conc)return;S.conc=false;log(msg,ambush?'good':'bad');fx(spotter||players()[0]||{x:0,y:0},ambush?'AMBUSH':'REVEALED','dmg');
 S.ambush=ambush?1:0;if(spotter&&spotter.pod!=null)alertPod(spotter.pod);
 for(const e of enemies())if(asleep(e)&&e.status==='ok'&&players().some(p=>p.status==='ok'&&!p.conc&&dist(e,p)<=SIGHT&&los(e,p)))alertPod(e.pod);
 S.ambush=0}
const scamperScore=(e,pos)=>{let s=Math.random()*2-dist(e,pos)*.5;for(const p of players())if(p.status==='ok'&&los(p,pos))s+=coverVal(pos,p)-40;return s};
function alertPod(pod){if(S.alert[pod])return;S.alert[pod]=1;const M=enemies().filter(e=>e.pod===pod);
 if(M.some(e=>!e.hid))log(M.length>1?`${M.length} hostiles scramble for cover!`:`${M[0].n} scrambles for cover!`,'bad');
 // Woken on the enemy's own turn: the scramble is their whole action (XCOM pod activation).
 for(const e of M){if(S.phase==='enemy')e.skip=1;if(e.hid||e.status!=='ok'||S.over)continue;fx(e,'!','dmg');horrorSeen(e);
  // The scramble is short and defensive: the nearest solid cover from everyone who can see the spot, not a flanking run.
  const R=reach({...e,mob:Math.ceil(e.mob/2)+1});let best=null,bs=-1e9;for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),sc=scamperScore(e,{x,y});if(sc>bs){bs=sc;best={x,y}}}
  if(best&&(best.x!==e.x||best.y!==e.y))moveAlong(e,pathTo(e,best.x,best.y,R.prev))}}
// A sleeping or concealed-phase enemy: walk the patrol (leader to the next waypoint, the rest follow), then look around.
async function idleAct(e){const P=S.M.patrol&&S.M.patrol[e.pod];
 if(P&&!e.hid){const lead=enemies().find(o=>o.pod===e.pod&&o.status==='ok'),R=reach({...e,mob:Math.ceil(e.mob/2)+1});S.pat[e.pod]=S.pat[e.pod]||0;
  let goal;if(lead===e){goal={x:P[S.pat[e.pod]][0],y:P[S.pat[e.pod]][1]};if(dist(e,goal)<=1.5){S.pat[e.pod]=(S.pat[e.pod]+1)%P.length;goal={x:P[S.pat[e.pod]][0],y:P[S.pat[e.pod]][1]}}}else goal=lead;
  let best=null,bd=1e9;for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),d=Math.abs(dist({x,y},goal)-(lead===e?0:1.5));if(d<bd){bd=d;best={x,y}}}
  if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(300)}}
 if(S.over||e.status!=='ok')return;
 if(S.conc){const p=players().find(p=>p.status==='ok'&&dist(e,p)<=DETECT&&los(e,p));if(p){breakConceal(`${e.n} spots ${p.n}! The squad is revealed.`,e);render();await sleep(400)}}
 else if(asleep(e)&&players().some(p=>p.status==='ok'&&!p.conc&&dist(e,p)<=SIGHT&&los(e,p))){alertPod(e.pod);render();await sleep(400)}}

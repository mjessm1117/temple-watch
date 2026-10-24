/* Enemy AI: cover-seeking, flanking, focus fire on the wounded, grenades on clusters, elites fall back when hurt, pods follow a leader.
   Horrors hunt Jedi only; agents wait in hiding. Ruusan flags: autoOW, nexus, bane (and lordAura/fanatic/rage in rules.js). */
function bestBlast(e,pos){let best=null;
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){if(dist(pos,{x,y})>6||FULL(tile(x,y)))continue;
  const hit=S.units.filter(u=>alive(u)&&u.status!=='down'&&cheb(u,{x,y})<=1),n=hit.filter(u=>u.side==='p').length,m=hit.filter(u=>u.side==='e').length;
  if(!n)continue;let s=40+n*22+(n>2?15:0)-m*45;if(hit.some(u=>u.side==='p'&&inCover(u)))s+=10;if(hit.some(u=>u.side==='p'&&u.hp<=3))s+=10;if(n>=2&&(!best||s>best.score))best={kind:'nade',x,y,score:s}}
 return best}
// Who this enemy is willing to attack. The prisoner: once freed, or in the cell after Threat rises; one shot per enemy turn.
function eTargets(e){let P=players().filter(p=>p.status==='ok'&&(!p.conc||cheb(p,e)<=2)&&(!p.vip||((!p.bound||S.threat>=1)&&!S.hostShot)));if(e.horror)P=P.filter(p=>p.jedi);return P}
function eAttacks(e,pos){const a={...e,x:pos.x,y:pos.y},out=[];
 for(const p of eTargets(e)){
  if(e.range<2){if(cheb(pos,p)===1)out.push({kind:'melee',t:p,chance:hitChance(a,p,{melee:true}),dmg:e.dmg});else if(e.lightning&&!e.disarmed&&dist(pos,p)<=5&&los(pos,p))out.push({kind:'lightning',t:p,chance:80,dmg:e.lightning})}
  else if(!e.disarmed&&dist(pos,p)<=e.range&&los(pos,p))out.push({kind:'shot',t:p,chance:p.vip?50:hitChance(a,p),dmg:e.dmg})}
 // Sith Lords Force-push a target out of hard cover (every other turn).
 if(e.sithLord&&!e.disarmed&&!(e.pushT>=S.turn-1))for(const p of eTargets(e))if(cheb(pos,p)>1&&dist(pos,p)<=4&&los(pos,p)&&inCover(p))out.push({kind:'fpush',t:p,chance:90,dmg:[2,2],score:55+(p.hunker||p.guard||p.ow?20:0)+(N4.some(([dx,dy])=>FULL(tile(p.x+dx,p.y+dy)))?30:0)});
 // Focus fire: wounded targets and ones a squadmate already shot this turn score higher.
 for(const o of out){if(o.kind==='fpush')continue;let s=o.chance;if((o.dmg[0]+o.dmg[1])/2>=o.t.hp)s+=25;s+=Math.round((1-o.t.hp/o.t.max)*20);if((S.focusT||[]).includes(o.t.uid))s+=10;
  if(o.kind==='shot'&&flanked(o.t,pos))s+=10;if(o.t.vip)s+=20;if(o.t.taunt===S.turn)s+=40;
  if(o.t.jedi){if(e.force||e.horror)s+=20;else if(o.kind==='shot')s-=(o.t.guard?o.t.guardDef:o.t.deflect)*.6}o.score=s}
 if(S.type==='defend'&&e.range>=2&&!e.disarmed){const c=nearestConsole(pos);if(dist(pos,c)<=e.range&&los(pos,c))out.push({kind:'console',c,chance:e.aim-15,dmg:e.dmg,score:34})}
 if(e.nades>0&&!e.disarmed){const g=bestBlast(e,pos);if(g&&g.score>=70)out.push(g)}
 out.sort((x,y)=>y.score-x.score);return out[0]||null}
function tileScore(e,pos){let s=Math.random()*3+elevAt(pos.x,pos.y)*3;const P=players().filter(p=>p.status==='ok'&&!p.vip);
 const melee=e.range<2,fear=melee?.2:.5; // melee enemies charge (Jess 10-17): they barely care about cover
 if(!e.horror)for(const p of P)if(dist(p,pos)<=10&&los(p,pos))s-=(40-coverVal(pos,p))*fear;
 const a=eAttacks(e,pos);if(a)s+=a.score*.6;
 // Flanking: a spot that sees a squad member with no cover toward it.
 if(e.range>=2)for(const p of P)if(inCover(p)&&dist(pos,p)<=e.range&&los(pos,p)&&coverVal(p,pos)===0)s+=12;
 // Pods stay within 3 of a living leader.
 const L=e.lead&&byId(e.lead);if(L&&alive(L)&&L.status==='ok')s-=Math.max(0,dist(pos,L)-3)*3;
 if(melee){const j=P.filter(p=>p.jedi),T=(e.force||e.horror)&&j.length?j:P;if(T.length){const m=Math.min(...T.map(p=>dist(p,pos)));s-=m*7;if(T.some(p=>cheb(p,pos)===1))s+=30}}
 else if(S.type==='defend')s-=dist(pos,nearestConsole(pos))*2.5;
 else if(P.length)s-=Math.max(0,Math.min(...P.map(p=>dist(p,pos)))-e.range*.7)*2;
 return s}
async function eDo(e,a){e.hid=0;if(a.t&&a.t.vip)S.hostShot=1;if(a.t)(S.focusT=S.focusT||[]).push(a.t.uid);
 if(a.kind==='fpush'){e.pushT=S.turn;fx(a.t,'PUSH');log(`${e.n} rips ${a.t.n} out of cover with the Force!`,'dark');push(e,a.t);render();await sleep(500);return}
 if(a.kind==='console'){if(!rnd(a.chance)){fx(a.c,'MISS','miss');log(`${e.n} fires at the ${S.M.objName.toLowerCase()} and misses.`)}else{const d=ri(a.dmg[0],a.dmg[1]);S.obj=Math.max(0,S.obj-d);fx(a.c,'-'+d,'dmg');log(`${e.n} blasts the ${S.M.objName.toLowerCase()} for ${d}.`,'bad')}}
 else if(a.kind==='nade'){e.nades--;log(`${e.n} throws a grenade!`,'bad');blast(a.x,a.y,3,e)}
 else if(a.kind==='lightning'){log(`${e.n} unleashes Force lightning.`,'dark');resolve(e,a.t,a.chance,a.dmg,{ignoreDeflect:1,label:'lightning'})}
 else resolve(e,a.t,a.chance,a.dmg,{melee:a.kind==='melee',label:a.kind==='melee'?(e.horror?'claws':'saber'):'shot'});
 render();await sleep(500)}
async function eAct(e){e.fired=0;if(e.autoOW)e.ow=false;await eAct0(e);e.disarmed=0;e.rooted=0;
 // Snipers (autoOW) settle into overwatch when they didn't fire.
 if(e.autoOW&&e.status==='ok'&&!e.fired&&!S.over&&!asleep(e)&&!S.conc){e.ow=true;log(`${e.n} settles in on overwatch.`)}}
async function eAct0(e){
 if(e.status==='stunned'){e.status='ok';log(`${e.n} shakes off the stun.`);return}
 if(e.status!=='ok')return;
 if(e.skip)return;
 // Bane watches from the ridge: he fights only what reaches him, and walks away on turn BANE.leaves.
 if(e.bane){if(S.turn>=BANE.leaves){S.units=S.units.filter(u=>u!==e);log('Darth Bane turns his back on the ritual and walks away over the ridge.','dark');return}
  if(!players().some(p=>p.status==='ok'&&cheb(p,e)<=1))return}
 // A nexus never acts; every N turns it spawns a Sith Spawn beside it.
 if(e.nexus){if(S.turn%e.nexus===0&&S.lastSpawn!==S.turn){
  const p=N4.map(([dx,dy])=>({x:e.x+dx,y:e.y+dy})).find(p=>inb(p.x,p.y)&&PASS(tile(p.x,p.y))&&!unitAt(p.x,p.y));
  if(p){S.lastSpawn=S.turn;S.units.push(mkFoe('sith_spawn',p.x,p.y));fx(p,'SPAWN','dmg');log(`${e.n} pulses. A Sith Spawn crawls out.`,'dark')}}return}
 // A pod whose leader just fell may falter (30%) and lose the turn.
 if(e.lead&&e.leadLost){e.leadLost=0;if(rnd(30)){fx(e,'FALTERS');log(`${e.n} falters without a leader.`,'good');return}}
 if(isElite(e)&&e.hp*3<=e.max&&!e.fellBack&&!S.conc&&!asleep(e))return fallBack(e);
 if(S.conc||asleep(e))return idleAct(e);
 if(e.tricked){e.tricked=0;S.peek=e;const melee=e.range<2,o=enemies().filter(o=>o!==e&&o.status==='ok'&&!o.hid&&(melee?cheb(e,o)===1:dist(e,o)<=e.range&&los(e,o)));
  let tg=o;if(!tg.length){ // close in on the nearest former ally first, then strike (Jess 10-17)
   const foes=enemies().filter(x=>x!==e&&x.status==='ok'&&!x.hid);if(foes.length){const R=reach(e);let best=null,bs=-1e9;
    for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),p={x,y},n=foes.map(f=>dist(p,f)).sort((a,b)=>a-b)[0],can=foes.some(f=>melee?cheb(p,f)===1:dist(p,f)<=e.range&&los(p,f));
     const sc=(can?100:0)-n;if(sc>bs){bs=sc;best=p}}
    if(best&&(best.x!==e.x||best.y!==e.y)){log(`${e.n}, mind clouded, rounds on its own side.`,'good');moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(380)}
    if(e.status==='ok')tg=foes.filter(f=>melee?cheb(e,f)===1:dist(e,f)<=e.range&&los(e,f))}}
  if(tg.length&&e.status==='ok'){const t=tg.sort((x,y)=>x.hp-y.hp)[0];log(`${e.n}, mind clouded, turns on ${t.n}.`,'good');resolve(e,t,hitChance(e,t,{melee}),e.dmg,{melee,label:'confused attack'});render();await sleep(500)}
  else log(`${e.n} stands confused.`);return}
 // Hidden agents wait until someone comes within 6 or they get a 70%+ shot.
 if(e.hid&&!players().some(p=>p.status==='ok'&&!p.vip&&dist(p,e)<=6)){const a=eAttacks(e,e);if(!a||a.kind!=='shot'||a.chance<70)return}
 // An enemy beside an idle alarm beacon trips it once the squad is in sight: reinforcements in 2 turns unless it is wrecked.
 if(!S.beacon&&!S.beaconUsed&&!e.hid){const b=tilesWhere((c,x,y)=>c==='b'&&cheb(e,{x,y})===1)[0];
  if(b&&players().some(p=>p.status==='ok'&&dist(p,e)<=9&&los(p,e))){S.beacon={x:b.x,y:b.y,turn:S.turn+2};S.beaconUsed=1;S.peek=e;fx(b,'ALARM','dmg');log(`${e.n} trips an alarm beacon! Help arrives in 2 turns unless you wreck it.`,'bad');render();await sleep(500);return}}
 S.peek=e.hid?null:e;await eTurn(e);
 if(e.horror&&e.status==='ok'){const j=S.units.find(u=>u.side==='p'&&u.jedi&&u.status==='down'&&!u.stable&&S.turn>u.downT&&cheb(u,e)===1);
  if(j){j.status='dead';j.consumed=1;fx(j,'TAKEN','dmg');log(`${e.n} drags ${j.n} into the dark. ${j.n} is gone.`,'bad');allyFell(j,30,`${j.n} taken by the beast`)}}}
// ---- 3 AP (Chat R, wave 9): every enemy spends AP.max. A move is 1 AP (one full move); attacks cost by weapon
// (melee, lightning, Force push 1; guns and grenades 2). A strong shot (65+) is taken from where it stands; otherwise it moves
// (up to 2 moves) and attacks. 1-AP fighters may attack twice (AP.eAttacks). A gunner with AP left over after firing, standing
// in the open, slips back into cover.
const eCost=(e,a)=>a.kind==='melee'||a.kind==='lightning'||a.kind==='fpush'?1:a.kind==='nade'?2:e.range<2?1:AP.gunDef;
async function eMove(e){const R=reach(e);let best=null,bs=-1e9;
 for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),s=tileScore(e,{x,y});if(s>bs){bs=s;best={x,y}}}
 if(!best||best.x===e.x&&best.y===e.y)return false;moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(380);return true}
const eOpen=e=>players().some(p=>p.status==='ok'&&!p.vip&&p.range>=2&&dist(p,e)<=p.range&&los(p,e)&&coverVal(e,p)<20);
async function eTurn(e){let ap=AP.max,n=0,mv=0,a=eAttacks(e,e);const go=async a=>{await eDo(e,a);ap-=eCost(e,a);n++};
 if(a&&a.score>=65)await go(a);
 while(ap>0&&e.status==='ok'&&!S.over){
  if(!n){if(mv>=2||!await eMove(e))break;mv++;ap--;if(e.status!=='ok'||S.over)break;a=eAttacks(e,e);if(a&&a.score>=15&&eCost(e,a)<=ap)await go(a);continue}
  if(n>=AP.eAttacks)break;a=eAttacks(e,e);if(a&&a.score>=40&&eCost(e,a)<=ap){await go(a);continue}break}
 if(ap>0&&n&&e.range>=2&&e.status==='ok'&&!S.over&&!e.horror&&eOpen(e)){const R=reach(e);let best=null,bs=-1e9;
  for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),sc=scamperScore(e,{x,y});if(sc>bs){bs=sc;best={x,y}}}
  if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));log(`${e.n} ducks back into cover.`);render();await sleep(380)}}}
// What this enemy would do right now, for the intent preview (spec D §5). Can change once you move.
function intentOf(e){if(e.bane&&!players().some(p=>p.status==='ok'&&cheb(p,e)<=1))return{txt:`Watching from the ridge. Leaves on turn ${BANE.leaves}`};
 if(e.nexus)return{txt:`Spawns a Sith Spawn every ${e.nexus} turns`};
 if(isElite(e)&&e.hp*3<=e.max&&!e.fellBack&&!S.conc&&!asleep(e))return{txt:'Badly hurt: falling back to cover'};
 if(S.conc||asleep(e))return{txt:e.hid?'Lying in wait':S.M.patrol&&S.M.patrol[e.pod]?'Patrolling, unaware of you':'On guard, unaware of you'};if(!S.beacon&&!S.beaconUsed&&tilesWhere((c,x,y)=>c==='b'&&cheb(e,{x,y})===1).length)return{txt:'Trip the alarm beacon'};const a=eAttacks(e,e);if(!a)return{txt:e.horror?'Hunting the nearest Jedi':S.type==='defend'&&e.range>=2?`Advancing on the ${S.M.objName.toLowerCase()}`:'Moving to a better position'};
 if(a.kind==='console')return{txt:`Shoot the ${S.M.objName.toLowerCase()} · ${a.chance}%`,to:a.c};
 if(a.kind==='nade')return{txt:'Throw a grenade',area:a};
 if(a.kind==='fpush')return{txt:`Force-push ${a.t.n} out of cover`,to:a.t};
 return{txt:`${a.kind==='melee'?'Attack':a.kind==='lightning'?'Lightning':'Shoot'} ${a.t.n} · ${a.chance}%`,to:a.t}}

// ---- Stealth & ambush (wave 3, spec A §1). Missions with stealth:true start with the squad concealed (S.conc).
// Foes there belong to pods (4th entry in M.foes; unnamed = a pod of one). A sleeping pod patrols M.patrol[pod] or stands guard.
// Concealed: any enemy within DETECT (3) tiles with line of sight spots the squad (those are the red tiles, visionTiles()).
// Revealed: a sleeping pod wakes when it sees anyone within SIGHT. Waking = scamper: every member dashes to cover, no attack.
// Attacking from concealment gets +20 aim (Ambush), and squad overwatch fires at the scampering pod with no −15 penalty.
const DETECT=3,SIGHT=8;
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

// ---- Elites fall back (wave 3): a wounded elite (6+ max HP, not a boss/horror) breaks off once, to the safest cover it can reach, and shoots if it still can.
const isElite=e=>!!(e.elite||(e.max>=6&&!e.horror&&!e.boss&&!e.nexus&&!e.bane&&!e.vip));
async function fallBack(e){e.fellBack=1;const R=reach(e),P=players().filter(p=>p.status==='ok');let best=null,bs=-1e9;
 for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number),p={x,y};let s=(P.length?Math.min(...P.map(q=>dist(q,p))):0)*2;for(const q of P)if(los(q,p))s-=(40-coverVal(p,q))/4;if(s>bs){bs=s;best=p}}
 S.peek=e;fx(e,'FALLS BACK');log(`${e.n} is badly hurt and falls back.`,'good');
 if(best&&(best.x!==e.x||best.y!==e.y)){moveAlong(e,pathTo(e,best.x,best.y,R.prev));render();await sleep(380)}
 if(e.status==='ok'&&!S.over){const a=eAttacks(e,e);if(a&&a.kind!=='fpush'&&a.score>=40)await eDo(e,a)}}
// ---- Pods with leaders: each group (stealth pod, spawn wave, or foes starting within 3 of each other) gets its strongest member as leader.
// Followers get +5 aim near a living leader (odds line "Pod leader") and stay close; when the leader dies, each may falter for a turn.
function formPods(list){const g=list.filter(e=>!e.horror&&!e.nexus&&!e.bane&&!e.boss);if(g.length<2)return;
 const L=g.reduce((b,e)=>(e.max*10+e.aim)>(b.max*10+b.aim)?e:b);L.leader=1;for(const e of g)if(e!==L)e.lead=L.uid}
function groupFoes(list){const out=[],seen=new Set();
 for(const e of list){if(seen.has(e))continue;const grp=[e];seen.add(e);
  for(let i=0;i<grp.length;i++)for(const o of list)if(!seen.has(o)&&(e.pod!=null?o.pod===e.pod:o.pod==null&&cheb(o,grp[i])<=3)){seen.add(o);grp.push(o)}out.push(grp)}
 return out}
function leaderDown(t){if(!t.leader)return;for(const e of enemies())if(e.lead===t.uid&&e.status==='ok'){e.leadLost=1;e.lead=0}log(`${t.n} led that squad. The rest waver.`,'good')}

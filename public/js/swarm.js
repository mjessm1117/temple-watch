/* Horror swarms (K2, wave 7; Jess 2026-10-22: "chain swarm", countered by both troops and Jedi by role).
   Brood: a big Force horror on the field calls Dark Husks around itself every few enemy turns.
   Chain: when your squad kills a horror, the nearest Husk close by lunges at once (free move + attack), XCOM "Lost" style.
   Counters: Husks, like every horror, can't hurt troops, so troops hold the line; a landed Beast Calm stops chains for the rest of your turn.
   Dark Husk is invented for the game [N]. Tune here. */
const SWARM={on:1,every:2,n:2,cap:6,ring:3,chainR:5,chainMax:2};
FOES.husk={n:'Dark Husk',ic:'e_horror',hp:3,aim:70,mob:6,dmg:[2,3],range:1.5,horror:1,swarm:1,noCap:1,init:9,tags:['creature'],
 desc:'Swarm horror, 3 HP. Only hurts Jedi. Comes in packs around a big horror; killing a horror makes the nearest Husk lunge.'};
let chainP=null;
const bigHorror=e=>e.horror&&!e.swarm&&e.status==='ok'&&!e.hid;
// Brood: before a big horror acts on a brood turn, Husks crawl out of the ground around it (cap SWARM.cap alive).
function brood(e){if(!SWARM.on||!bigHorror(e)||S.turn%SWARM.every||S.broodT===S.turn)return;S.broodT=S.turn;
 const live=enemies().filter(h=>h.swarm&&alive(h)).length,n=Math.min(SWARM.n,SWARM.cap-live);if(n<=0)return;
 const spots=tilesWhere((c,x,y)=>PASS(c)&&!unitAt(x,y)&&cheb(e,{x,y})<=SWARM.ring&&cheb(e,{x,y})>0).sort((a,b)=>dist(a,e)-dist(b,e)).slice(0,n);
 for(const p of spots){const h=mkFoe('husk',p.x,p.y);h.seenH=1;S.units.push(h);fx(h,'BROOD','dmg')}
 if(spots.length)log(`${e.n} calls its brood: ${spots.length} Dark Husk${spots.length>1?'s':''} crawl out of the dark.`,'bad')}
// Chain: queued from damage(), played right after the action that caused it, one Husk at a time.
function chainFrom(t,src){if(!SWARM.on||!t.horror||t.side!=='e'||!src||src.side!=='p'||S.phase!=='player')return;
 if(S.calmT===S.turn){log('The swarm stays calm. No one answers the kill.','good');return}
 if(S.chainT!==S.turn){S.chainT=S.turn;S.chainN=0}if(S.chainN>=SWARM.chainMax)return;
 const h=enemies().filter(h=>h.swarm&&h.status==='ok'&&!h.hid&&h.chained!==S.turn&&dist(h,t)<=SWARM.chainR).sort((a,b)=>dist(a,t)-dist(b,t))[0];if(!h)return;
 S.chainN++;h.chained=S.turn;log(`The swarm surges! ${h.n} lunges.`,'bad');fx(h,'SURGE','dmg');
 chainP=(chainP||Promise.resolve()).then(async()=>{if(S.over||h.status!=='ok')return;await eAct(h);if(window.View3D)await View3D.idle();checkEnd();render()})}
const _swDamage=damage;damage=function(t,d,src){const was=t.status;const r=_swDamage.apply(this,arguments);if(was!=='dead'&&t.status==='dead')chainFrom(t,src);return r};
const _swEAct=eAct;eAct=async function(e){brood(e);return _swEAct.apply(this,arguments)};
const _swEnd=endTurn;endTurn=async function(){if(chainP){const p=chainP;await p;if(chainP===p)chainP=null}if(S&&S.over)return;return _swEnd.apply(this,arguments)};
// Beast Calm that lands also quiets the swarm for the rest of this turn.
{const ab=AB.beastCalm,run=ab.run;ab.run=function(u,g){run.apply(this,arguments);if(g&&g.t&&g.t.status==='stunned'){S.calmT=S.turn;log('The swarm settles. Kills this turn won’t set it off.','good')}};
 ab.desc=ab.tip=ab.desc+' A landed Calm also stops the horror swarm from surging for the rest of your turn.'}

/* Hack rewards (Coordinator, 2026-10-21, XCOM 2 style). Hack a console or an enemy droid within 4: pick SAFE (likely, small) or RISKY (big, can backfire).
   Locked doors still open the old way. Each console can be hacked once. State: S.hacked = ['x,y', …]. Numbers in HACK. [Default] */
const HACK={range:4,
 console:{safe:{p:85,n:'Scan the network',d:'Reveal every hidden enemy · +1 Intel'},risky:{p:45,n:'Seize the grid',d:'Stun up to 2 enemies in sight of you',fail:'Alarm: reinforcements in 2 turns'}},
 droid:{safe:{p:80,n:'Shut it down',d:'Stun the droid for a turn'},risky:{p:40,n:'Take control',d:'The droid fights for you next turn',fail:'It locks on: +20 aim for 2 turns'}}};
const hackBonus=u=>(u.cls==='Medic'?10:0)+(u.spec==='tech'||u.tech?10:0);
const _hackTg=AB.hack.tg;
AB.hack.tg=u=>{const L=_hackTg(u).filter(p=>tile(p.x,p.y)==='D'),H=S.hacked||[];
 for(const p of tilesWhere((c,x,y)=>c==='k'&&dist(u,{x,y})<=HACK.range&&!H.includes(x+','+y)))L.push({...p,hack:'console',chance:HACK.console.safe.p});
 for(const e of enemies())if(e.droid&&e.status==='ok'&&!e.hid&&dist(u,e)<=HACK.range&&los(u,e))L.push({x:e.x,y:e.y,t:e,hack:'droid',chance:HACK.droid.safe.p});
 return L};
const _hackRun=AB.hack.run;
AB.hack.run=(u,g)=>{if(!g||!g.hack)return _hackRun(u,g);const H=HACK[g.hack],risky=g.mode==='risky',o=H[risky?'risky':'safe'],ok=rnd(Math.min(95,o.p+hackBonus(u)));
 if(g.hack==='console')(S.hacked=S.hacked||[]).push(g.x+','+g.y);fx(g,ok?'HACKED':'FAILED',ok?'heal':'dmg');
 if(!ok){log(`${u.n}'s hack fails.${risky?' '+o.fail+'.':''}`,'bad');
  if(risky&&g.hack==='console'&&!S.beacon){S.beacon={x:g.x,y:g.y,turn:S.turn+2};S.beaconUsed=1}
  if(risky&&g.hack==='droid'&&g.t){g.t.aim+=20;g.t.lockT=S.turn+2}return}
 log(`${u.n}: ${o.n}.`,'good');
 if(g.hack==='console'&&!risky){for(const e of enemies())if(e.hid){e.hid=0;fx(e,'REVEALED')}S.intel=(S.intel||0)+1}
 else if(g.hack==='console'){const T=enemies().filter(e=>e.status==='ok'&&!e.hid&&los(u,e)).sort((a,b)=>b.hp-a.hp).slice(0,2);for(const e of T){e.status='stunned';fx(e,'STUNNED')}if(!T.length)log('Nothing in sight to shut down.')}
 else if(!risky){g.t.status='stunned';fx(g.t,'STUNNED')}
 else{g.t.tricked=1;fx(g.t,'CONTROLLED','heal');log(`${g.t.n} turns its guns on the Sith.`,'good')}};
AB.hack.tip='Slice a console or enemy droid within 4: choose a safe or a risky reward. Also opens locked doors. Ends turn.';
// Aim bar: two confirm buttons (safe / risky) instead of one.
const _oddsH=oddsHTML;oddsHTML=function(){const g=S.pick,u=S.sel;if(!g||!g.hack||S.mode!=='hack'||!canAct(u))return _oddsH();const H=HACK[g.hack],b=hackBonus(u);
 const btn=(k,o)=>`<button type="button" class="${k==='safe'?'primary':''}" data-hack="${k}" title="${o.d}">${k==='safe'?'Safe':'Risky'}: ${o.n} · ${Math.min(95,o.p+b)}%<small>${o.d}${o.fail?` · fail: ${o.fail}`:''}</small></button>`;
 return `<div class="odds hackp"><div class="oh"><b>Hack ${g.hack==='droid'?g.t.n:'console'}</b></div>${btn('safe',H.safe)}${btn('risky',H.risky)}</div>`};
document.getElementById('odds').addEventListener('click',ev=>{const b=ev.target.closest('[data-hack]');if(!b||!S||!S.pick||!canAct(S.sel))return;ev.stopPropagation();exec(S.sel,'hack',{...S.pick,mode:b.dataset.hack})},true);
// Droid overclock wears off.
onFx((type)=>{if(type!=='turn'||!S)return;for(const e of enemies())if(e.lockT&&S.turn>=e.lockT){e.aim-=20;e.lockT=0}});

/* Campaign state C: calendar, resources, wings, roster, XP/ranks, wounds, crises. Spec: docs/specs/campaign.md */
let C=null;
const isJedi=r=>!!CLASS[r.cls].jedi;
const troopClasses=()=>Object.keys(CLASS).filter(k=>!CLASS[k].jedi&&(CLASS[k].lockEra||0)<=((C&&C.era)||1));
function newCampaign(diff){
 C={v:2,treeV:1,diff,month:1,day:1,step:0,res:{...START_RES},orderDark:0,wings:{medical:1,training:0,forge:0,armory:0,comms:0,archives:0,gardens:0,barracks:1},build:null,
  roster:START_ROSTER.map((r,i)=>({id:'u'+(i+1),rank:START_RANK,xp:RANKS[START_RANK-1].xp,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0,gear:startGear(r.cls),...r})),nid:START_ROSTER.length+1,
  options:[],news:[],flags:{},legends:[]};
 ensureTemple();C.options=optionsFor(0);S=null;saveGame();baseScreen()}
// The first squad arrives trained (rank 2) and kitted: Jedi with an attuned saber and battle robes, troops with military blasters and light armor.
const START_RANK=2,startGear=cls=>CLASS[cls]&&CLASS[cls].jedi?{w:0,armor:'robes',mods:[],saber:1,trait:null}:{w:1,armor:'light',mods:[],saber:0,trait:null};
function abilFor(r){const P=picksOf(r).filter(k=>AB[k]),B=BASE_KIT[r.cls]||[];
 if(isJedi(r))return['strike',...B,...P,...(r.rank>=2?['choke']:[]),'push','guard','meditate','subdue','stabilize','liftUp','door','console','scan'];
 return['shoot',...B,...P,'overwatch','subdue','stabilize','liftUp','door',...(B.includes('scan')?[]:['scan'])]}   // anyone can copy a terminal (was Jedi + Medic only)
// Roster entry → battle stats: class base + RANK_GAIN for every rank reached (data-campaign.js), then gear/perks/stress (templeMods).
function battleUnit(r){const b=CLASS[r.cls],u={...b,n:r.n,cls:r.cls,col:r.col,rid:r.id,rank:r.rank,title:r.title,dark:r.dark||0,dmg:[...b.dmg]};delete u.desc;
 for(let k=2;k<=r.rank;k++){const G=RANK_GAIN[k]||{};u.hp+=G.hp||0;u.aim+=G.aim||0;u.will+=G.will||0;
  for(const [s,v] of Object.entries((b.jedi?G.jedi:G.troop)||{}))if(u[s]!=null)u[s]+=v}
 u.abil=abilFor(r);return templeMods(u,r)}
const able=r=>r.status==='active'&&!r.wound,fit=r=>able(r)&&!r.assign;
const healMult=()=>(C.wings.medical>=3?2.5:C.wings.medical>=2?2:C.wings.medical?1.5:1)*(C.staff&&C.staff.medical?1.25:1);
const odark=()=>Math.min(100,C.orderDark+4*C.roster.filter(r=>isJedi(r)&&r.status==='active').reduce((s,r)=>s+r.dark,0));

// Mission options for a plan step. All captives share ONE rescue crisis (the step's own, or an extra one that doesn't use up the step,
// offered at most once per step). Ignored captives come home on their own after CAPTIVE missions (wounded, stressed).
function optionsFor(step){const P=PLAN[step],o=[];if(!P)return o;
 if(P.story)o.push({mission:P.story,story:1,adv:1});
 for(const id of P.crises||[])o.push({...CRISES[id],crisis:id,adv:1});
 if(P.crises)o.push(...questOptions());
 const cap=C.roster.filter(r=>r.status==='captured');if(!cap.length)return o;
 const names=cap.map(r=>r.n).join(' and '),hs={n:`Rescue ${names}`,hostage:cap[0].id,hostages:cap.map(r=>r.id)};
 const res=o.find(x=>x.crisis==='rescue');
 if(res)Object.assign(res,hs,{text:`${names} ${cap.length>1?'were':'was'} taken after the last fight. Get them back.`});
 else if(C.rescueStep!==step)o.push({...CRISES.rescue,crisis:'rescue',...hs,text:`${names} ${cap.length>1?'are':'is'} held at a Sith depot. Ignore it and they limp home in ${Math.max(...cap.map(r=>r.capT||1))} mission(s), hurt and shaken.`,ignore:{},adv:0});
 return o}
function gain(k,n,out){if(!n)return;if(k==='orderDark')C.orderDark=Math.max(0,Math.min(100,C.orderDark+n));else{C.res[k]=(C.res[k]||0)+n;if(k==='favor')C.res.favor=Math.max(0,Math.min(100,C.res.favor))}
 if(out)out[k]=(out[k]||0)+n}
function chooseOption(i){const o=C.options[i];C.chosen=i;
 if(o.adv)for(const x of C.options)if(x!==o&&x.adv)ignoreCrisis(x)}
function ignoreCrisis(x){C.news.push(`Ignored: ${x.n}.`);for(const [k,v] of Object.entries(x.ignore||{})){
 gain(k,v)}}
function hostageFor(o){const r=o.hostage&&C.roster.find(r=>r.id===o.hostage);if(!r)return null;
 const u=battleUnit(r);return{...u,hp:Math.ceil(u.hp/2),dmg:[2,3],range:6,abil:['shoot','stabilize','door'],rid:r.id}}

// Mission over → apply results right away (so a reload never repeats a mission), then show the debrief.
function applyResults(win){const M=S.M,o=C.options[C.chosen]||{},out={res:{},rows:[],promo:[]},dep=[];
 if(win){for(const [k,v] of Object.entries(M.reward||{}))gain(k,Math.round(k==='credits'?v*DIFF[C.diff].income*MISSION_CR:v),out.res);
  const bonus=missionBonus();
  if(bonus){for(const [k,v] of Object.entries(M.bonus||{}))gain(k,v,out.res);out.bonus=M.bonusTxt}
  if(S.envoyTaken){C.flags.e1_strike_known=1;out.flag='The envoy talks: the peace talks are a feint. The Empire plans a strike on Coruscant.'}}
 else gain('favor',-3,out.res);
 gain('intel',S.intel,out.res);gain('credits',S.lootCred||0,out.res);gain('orderDark',4*S.orderDark,out.res);
 for(const u of S.units.filter(u=>u.side==='p'&&u.rid)){const r=C.roster.find(r=>r.id===u.rid);if(!r)continue;let xp=0,fate;
  if(u.vip){if(win&&u.status!=='dead'){r.status='active';r.capT=0;r.wound=Math.ceil(WOUND.serious/healMult());fate='Rescued · recovering'}
   else if(u.status==='dead'){r.status='dead';fate='Died in the rescue'}else fate='Still captive'}
  else if(u.status==='dead'){r.status='dead';C.legends.push({n:r.n,cls:r.cls,how:u.consumed?'Taken by a Terentatek':'Fell in battle',where:M.n});fate='One with the Force'}
  else if(u.status==='down'&&!win){r.status='captured';r.capT=CAPTIVE;fate='Captured by the Sith'}
  else{xp=XP.survive+(u.kills||0)*XP.kill+(u.caps||0)*XP.capture+(M.story&&win?XP.story:0);xp=Math.round(xp*xpMult(r));if(win&&r.trait&&TRAITS[r.trait].intel)gain('intel',TRAITS[r.trait].intel,out.res);
   const w=u.downed?(C.wings.medical>=2?WOUND.graveL2:WOUND.grave):u.hp*2<=u.max?WOUND.serious:u.hurt?WOUND.light:0;
   r.wound=Math.ceil(w/healMult());fate=w===0?'Unhurt':`${u.downed?'Grave':u.hp*2<=u.max?'Serious':'Light'} wound · ${r.wound} days`}
  r.dark=u.dark;if(!u.vip){r.missions++;r.kills+=u.kills||0;r.xp+=xp}
  const before=r.rank;if(r.status==='active'&&promote(r))out.promo.push(r.id);dep.push({r,u});
  out.rows.push({n:r.n,xp,fate,rank:r.rank>before?r.rank:0,dark:isJedi(r)?r.dark:null})}
 if(o.hostages){C.rescueStep=C.step;if(win)for(const id of o.hostages){const r=C.roster.find(r=>r.id===id);if(r&&r.status==='captured'){r.status='active';r.capT=0;r.wound=Math.ceil(WOUND.serious/healMult());out.rows.push({n:r.n,xp:0,fate:'Freed from the cells · recovering',rank:0,dark:null})}}}
 C.tick=C.tick||0;for(const {r} of dep)r.fought=C.tick;   // who fought since the last time step (both fronts count)
 templeAfterMission(dep,win,o,out);advance(o);return out}
// Time passes: builds finish, wounds heal, the month turns over (stipend, upkeep, pay, recruits).
function advance(o){C.news=[];C.day+=DAYS;while(C.day>30){C.day-=30;C.month++;monthTick()}
 if(C.build){C.wings[C.build]++;C.news.push(`${WINGS[C.build].n} level ${C.wings[C.build]} is ready.`);C.build=null}
 for(const r of C.roster){if(r.wound)r.wound=Math.max(0,r.wound-DAYS);
  if(r.status==='captured'&&!(o.hostages||[]).includes(r.id)&&--r.capT<=0){r.status='active';r.capT=0;r.wound=Math.ceil(WOUND.serious/healMult());r.stress=Math.min(100,(r.stress||0)+25);C.news.push(`${r.n} escaped the Sith and limped home: ${r.wound} days wounded, stress +25.`)}}
 // Never lose (spec B §7): with fewer than 4 fit units, the Council grants an emergency levy.
 templeAdvance();
 if(C.roster.filter(able).length<4&&C.step<PLAN.length){for(let i=0;i<3;i++)addTroop();gain('favor',-10);C.news.push('Emergency levy: the Senate sends 3 green troopers. Senate Favor −10.')}
 ensureTemple();if(o.adv)C.step++;C.chosen=null;C.options=optionsFor(C.step);saveGame()}
function monthTick(){const f=C.res.favor,st=Math.round((STIPEND[0]+STIPEND[1]*f)*DIFF[C.diff].income),
 up=Object.entries(C.wings).reduce((s,[k,l])=>s+(WINGS[k].up[l]||0),0),pay=TROOP_PAY*C.roster.filter(r=>r.status==='active'&&!isJedi(r)).length,rec=1+Math.floor(f/40);
 C.res.credits+=st-up-pay;if(C.res.credits<0){C.res.credits=0;gain('favor',-5);C.news.push('The Temple ran out of credits. The Senate covered the debt: Senate Favor −5.')}C.res.recruits+=rec;C.news.push(`Month ${C.month}: Senate stipend +${st}, upkeep −${up}, troop pay −${pay}, recruits +${rec}. New recruit candidates are in.`);templeMonth()}
function buildWing(k){const l=C.wings[k],cost=WINGS[k].cost[l+1];if(C.build||cost==null||C.res.credits<cost||!researched(WINGS[k].req&&WINGS[k].req[l+1]))return;C.res.credits-=cost;C.build=k;saveGame()}
function addTroop(){const used=new Set(C.roster.map(r=>r.n)),n=RECRUIT_NAMES.find(x=>!used.has(x))||'Recruit '+C.nid;
 C.roster.push({id:'u'+C.nid++,n,cls:pickOne(troopClasses()),rank:1,xp:0,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0})}
function pickAbility(id,k){const r=C.roster.find(r=>r.id===id),p=r&&pendingRank(r);if(!p||!treeOpts(r,p).includes(k))return;r.picks.push(k);if(p===3)r.spec=Object.keys(TREES[r.cls].specs).find(n=>TREES[r.cls].specs[n].sig===k);r.pick=pendingRank(r);saveGame()}
// Free respec any time (Jess 2026-10-23): clear picks, spec and borrowed skills; ranks re-prompt one by one.
function respec(id){const r=C.roster.find(r=>r.id===id);if(!r)return;r.picks=[];r.spec=null;r.borrow=[];r.alt=null;if(typeof fixExtra==='function')fixExtra(r);r.pick=pendingRank(r);saveGame()}
function launchMission(i,ids){ensureTemple();const o=C.options[i],sq=ids.map(id=>battleUnit(C.roster.find(r=>r.id===id)));chooseOption(i);
 startMission(o.mission,sq,{diff:C.diff,hostage:hostageFor(o),crisis:o.crisis||null,fewer:o.fewer||0})}
// Squad size rules. twin.js overrides this for the second front (4 units, 0–2 Jedi, squad A's units excluded).
function squadRule(){return{max:6,jmin:1,jmax:3,used:[]}}
function defaultSquad(o){const R=squadRule(),q=o&&o.quest,ok=C.roster.filter(r=>fit(r)&&!R.used.includes(r.id)&&r.id!==(o&&o.hostage)).sort((a,b)=>(b.id===q)-(a.id===q)),J=ok.filter(isJedi).slice(0,R.jmax),T=ok.filter(r=>!isJedi(r));return[...J,...T].slice(0,R.max).map(r=>r.id)}
// Saves made mid-mission before every unit could scan: add Scan clue on resume (2026-10-23).
if(typeof continueGame==='function'){const _cgScan=continueGame;continueGame=function(d){const r=_cgScan.apply(this,arguments);if(S&&S.units)for(const u of S.units)if(u.side==='p'&&u.rid&&!u.vip&&u.abil&&!u.abil.includes('scan'))u.abil.push('scan');return r}}

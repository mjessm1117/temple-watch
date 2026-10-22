/* Arsenal (Coordinator, 2026-10-22): module slots on weapon / armor / saber, Mk I–III upgrades, unit evolution, the research tree screen.
   Data: data-arsenal.js. State per unit: r.gear.mods (weapon), .amods (armor), .smods (saber), .mk {'w.scope':2}; r.evo = 1 once evolved.
   Hooks: templeMods → arsenalMods; researchTab → arsenalResearch. Wraps: ensureProg, progClick, armoryProg, rosterProg, buyArmor, progAfterMission. */
const MODK={w:'mods',a:'amods',s:'smods'},MOD_LAB={w:'Weapon modules',a:'Armor modules',s:'Saber modules'};
const _epA=ensureProg;ensureProg=function(){_epA();for(const r of C.roster)gearArr(r)};
function gearArr(r){const g=r.gear;if(!g)return null;for(const k of Object.values(MODK))g[k]=g[k]||[];g.mk=g.mk||{};return g}
function slotsOf(r,k){const g=r.gear,J=isJedi(r);return k==='w'?(J?0:WEAPONS[g.w].slots):k==='s'?(J?SABERS[g.saber].slots:0):((ARMOR[g.armor]||{}).slots||0)}
const mkOf=(r,k,m)=>(r.gear.mk||{})[k+'.'+m]||1;
const mkMax=k=>researched(MK_RES[k][1])?3:researched(MK_RES[k][0])?2:1;
const modWho=(r,M)=>!M.who||M.who===(isJedi(r)?'jedi':'troop');
const modOk=(r,k,m)=>{const M=MODPOOL[k][m];return !!M&&modWho(r,M)&&researched(M.res)&&hasWing(M.need)};

// Battle stats: installed modules at their Mk, evolution, branch perks.
function arsenalMods(u,r){const g=r.gear;
 for(const k of Object.keys(MODK))for(const m of g[MODK[k]]||[])if(MODPOOL[k][m])addMod(u,MODPOOL[k][m].mk[mkOf(r,k,m)-1]);
 if(r.evo&&EVO[r.cls])addMod(u,EVO[r.cls].mod);
 if(r.cls==='Heavy'&&researched('ordnance'))addMod(u,{nades:1});
 if(isJedi(r)&&researched('livingForce'))addMod(u,{will:10,deflect:5});
 if(!isJedi(r)&&researched('repeaters'))addMod(u,{dmg:1});
 if(researched('namelessLore'))u.aimVsHorror=(u.aimVsHorror||0)+10;return u}

// --- buying ---
function fitMod(id,k,m){const r=unit(id),g=r&&gearArr(r);if(!g||!MODK[k])return;const L=g[MODK[k]];
 if(L.includes(m)||L.length>=slotsOf(r,k)||!modOk(r,k,m)||!pay(priceOf(MODPOOL[k][m].cost)))return;L.push(m);g.mk[k+'.'+m]=1;saveGame()}
function pullMod(id,k,m){const r=unit(id),g=r&&gearArr(r);if(!g||!MODK[k])return;g[MODK[k]]=g[MODK[k]].filter(x=>x!==m);delete g.mk[k+'.'+m];saveGame()}
function mkUp(id,k,m){const r=unit(id),g=r&&gearArr(r);if(!g||!MODK[k]||!g[MODK[k]].includes(m))return;const lv=mkOf(r,k,m);
 if(lv>=mkMax(k)||!pay(priceOf(MK_COST[lv])))return;g.mk[k+'.'+m]=lv+1;saveGame()}
// Smaller armor = fewer slots: extra modules come off (no refund).
const _baA=buyArmor;buyArmor=function(id,k){_baA(id,k);const r=unit(id),g=r&&gearArr(r);if(g&&g.amods.length>slotsOf(r,'a')){g.amods.length=slotsOf(r,'a');saveGame()}};
const evoRes=r=>isJedi(r)?'mastery':'eliteProgram';
function evolve(id){const r=unit(id),E=r&&EVO[r.cls];if(!E||r.evo||r.rank<EVO_RANK||!researched(evoRes(r))||C.res.intel<EVO_COST.intel||!pay(EVO_COST.credits))return;
 C.res.intel-=EVO_COST.intel;r.evo=1;C.news.push(`${r.n} evolves: ${E.n}. ${E.desc}`);if(typeof lifeLog==='function')lifeLog(r,`Evolved into ${E.n}`);saveGame()}

// --- Armory rows ---
function modRows(r,k){const s=slotsOf(r,k),g=gearArr(r),L=g[MODK[k]],mx=mkMax(k);
 if(!s)return `<div class="grow"><b>${MOD_LAB[k]}</b><span class="muted">No slots on this ${k==='a'?'armor':'item'}.</span></div>`;
 const have=L.map(m=>{const M=MODPOOL[k][m],lv=mkOf(r,k,m),up=lv<3?priceOf(MK_COST[lv]):0;
  return `<button type="button" class="on" data-act="pmod:${r.id}:${k}.${m}" data-tip="gear:${m}" title="Remove (no refund)">${M.n} ${MK_N[lv]} · ${gfxTxt(M.mk[lv-1])} ✕</button>`
  +(lv<3?`<button type="button" data-act="mkup:${r.id}:${k}.${m}" ${lv>=mx||C.res.credits<up?'disabled':''} title="${gfxTxt(M.mk[lv])}">▲ ${MK_N[lv+1]} · ${up} Cr${lv>=mx?` · research ${RESEARCH[MK_RES[k][lv-1]].n}`:''}</button>`:'')}).join('');
 const shop=Object.entries(MODPOOL[k]).filter(([m,M])=>!L.includes(m)&&modWho(r,M)).map(([m,M])=>{const ok=modOk(r,k,m),c=priceOf(M.cost);
  return `<button type="button" data-act="fmod:${r.id}:${k}.${m}" data-tip="gear:${m}" ${!ok||L.length>=s||C.res.credits<c?'disabled':''}>${M.n} · ${M.tip} · ${c} Cr${ok?'':!researched(M.res)?` · research ${RESEARCH[M.res].n}`:needTxt(M.need)}</button>`}).join('');
 return `<div class="grow"><b>${MOD_LAB[k]} ${L.length}/${s}</b>${have}${L.length<s?shop:''}</div>`}
function evoHTML(r){const E=EVO[r.cls];if(!E)return '';if(r.evo)return `<p class="up">Evolved: <b>${E.n}</b> · ${E.desc}</p>`;
 const res=researched(evoRes(r)),ok=res&&r.rank>=EVO_RANK&&C.res.credits>=EVO_COST.credits&&C.res.intel>=EVO_COST.intel;
 return `<div class="grow"><b>Evolve</b><button type="button" data-act="evo:${r.id}" ${ok?'':'disabled'}>Become ${E.n} · ${E.desc} · ${EVO_COST.credits} Cr + ${EVO_COST.intel} Intel${res?'':` · research ${RESEARCH[evoRes(r)].n}`}${r.rank<EVO_RANK?` · rank ${EVO_RANK}`:''}</button></div>`}
const _apA=armoryProg;armoryProg=function(r){return (isJedi(r)?modRows(r,'s'):'')+_apA(r)+modRows(r,'a')+evoHTML(r)};
const _rpA=rosterProg;rosterProg=function(r){return (r.evo&&EVO[r.cls]?`<small class="up">Evolved: ${EVO[r.cls].n}</small> `:'')+_rpA(r)};
const _pcA=progClick;progClick=function(a,x,y){const f={fmod:fitMod,pmod:pullMod,mkup:mkUp}[a];if(f){const [k,m]=(y||'').split('.');f(x,k,m);return true}
 if(a==='evo'){evolve(x);return true}return _pcA(a,x,y)};
// Holonet relays: +1 Intel per won mission.
const _pamA=progAfterMission;progAfterMission=function(dep,win,out){_pamA(dep,win,out);if(win&&researched('holonet')){C.res.intel++;out.prog.push('Holonet relays: +1 Intel.')}};

// --- Research tree: 5 branches side by side ---
function arsenalResearch(){const R=C.research;if(!C.wings.archives)return '<p class="muted">Build the Archives (Wings tab) to start research.</p>';
 const sp=(C.wings.archives>=2?1.5:1)*(C.staff.archives?1.25:1),cur=R.cur&&RESEARCH[R.cur],era=C.era||1;
 const node=k=>{const P=RESEARCH[k],done=R.done.includes(k),need=(P.need||[]).filter(n=>!researched(n)),lockE=(P.era||1)>era,c=P.cost,
  no=R.cur||need.length||lockE||C.res.credits<(c.credits||0)||C.res.intel<(c.intel||0);
  return `<div class="rnode ${done?'done':R.cur===k?'cur':need.length||lockE?'lock':''}" data-tip="research:${k}"><b>${P.n}</b><small>${P.desc}</small>
  <small class="muted">${P.days} days · ${costTxt(c)}${lockE?` · <span class="warn">Era ${P.era}</span>`:''}${need.length?` · needs ${need.map(n=>RESEARCH[n].n).join(', ')}`:''}</small>
  ${done?'<span class="up">Done</span>':R.cur===k?`<span class="warn">${Math.floor(R.prog)}/${P.days} days</span>`:`<button type="button" data-act="res:${k}" ${no?'disabled':''}>Research</button>`}</div>`};
 return `<p>${cur?`Researching <b>${cur.n}</b>: ${Math.floor(R.prog)}/${cur.days} days (+${Math.round(DAYS*sp)} per mission).`:'<span class="warn">No project running.</span> Pick one below.'} Done: ${R.done.length}/${Object.keys(RESEARCH).length}. Later eras open new projects.</p>
 <div class="rtree">${RES_TREE.map(b=>`<div class="rbr"><b class="eyebrow">${icon(b.ic)} ${b.n} · ${b.ids.filter(k=>R.done.includes(k)).length}/${b.ids.length}</b>${b.ids.map(node).join('')}</div>`).join('')}</div>`}

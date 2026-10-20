/* Temple hub: Operations (missions) on top, then tabs Roster · Armory · Wings · Recruit · Council. All tabs render; inactive ones are hidden. */
let TAB='roster',ARM=null;

const cost=(cr,ky)=>`${cr} Cr${ky?` + ${ky} Ky`:''}`;
const needTxt=n=>n&&!hasWing(n)?` · needs ${WINGS[n[0]].n} ${n[1]}`:'';
function statLine(r){const u=battleUnit(r);return `HP ${u.hp} · Aim ${u.aim} · Dmg ${u.dmg.join('–')} · Range ${u.range<2?'melee':u.range} · Move ${u.mob}${u.armor?` · Armor ${u.armor}`:''}${u.crit?` · Crit ${u.crit}%`:''}${u.maxF?` · Focus ${u.maxF} · Deflect ${u.deflect}`:''}${u.kits!=null?` · Medkits ${u.kits}`:''}${u.nades!=null?` · Grenades ${u.nades}`:''}${u.bondAim?` · Bond +${u.bondAim} aim`:''}`}
function stateTag(r){return r.status==='retired'?'<span class="dim">Retired</span>':r.status==='captured'?'<span class="bad">Captured</span>':r.assign?`<span class="warn">${assignName(r)}${r.wound?` · ${r.wound}d`:''}</span>`:r.wound?`<span class="warn">Wounded · ${r.wound} days</span>`:'<span class="ready">Ready</span>'}

function rosterTab(){const act=C.roster.filter(r=>r.status!=='dead');
 return act.map(r=>{const next=r.rank<RANKS.length?RANKS[r.rank].xp:null,p=pendingRank(r),bs=bondsOf(r).filter(b=>b.lvl);
  return `<div class="rrow"><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><div class="rmain"><b data-tip="class:${r.cls}">${r.n}</b>
  <small><span class="pwr">${icon('st_power')}${unitPower(r)}</span> · ${r.title?r.title+' · ':''}${r.cls}${specOf(r)?' ('+specOf(r).n+')':''} · Rank ${r.rank} · ${r.xp}${next?'/'+next:''} XP${isJedi(r)?` · Darkness ${r.dark}`:''}${r.trait?` · ${TRAITS[r.trait].n}`:''} · age ${r.age}${r.fear?` · <span class="bad">afraid (${r.fear})</span>`:''}</small>
  ${bs.length?`<small class="bd">Bonds: ${bs.map(b=>`${b.n} ♦${b.lvl}`).join(', ')}</small>`:''}
  ${p?`<div class="picks">Rank ${p}: ${p===3?'choose a specialization (permanent)':'choose one'} ${treeOpts(r,p).map(k=>{const a=pickCard(r,p,k);return `<button type="button" data-act="pick:${r.id}:${k}" data-tip="${AB[k]?'ability':'gear'}:${k}">${icon(a.ic||'guard')}${a.name}</button>`}).join('')}<small>${treeOpts(r,p).map(k=>{const a=pickCard(r,p,k);return `${a.name}: ${a.desc}`}).join(' · ')}</small></div>`:''}
  ${TREES[r.cls]?`<button type="button" class="tbtn" data-act="tree:${r.id}">${icon('st_power')} Skill tree${p?' · pick waiting':''}</button>`:''}
  ${rosterProg(r)}
  ${r.grief?`<div class="picks">${r.n} lost ${r.grief}. <button type="button" data-act="grief:${r.id}:0">Grieve (keep fear)</button><button type="button" data-act="grief:${r.id}:1">Use the anger (Darkness +2, no fear)</button></div>`:''}
  ${r.status==='active'?`<select data-assign="${r.id}" aria-label="Assignment for ${r.n}">${assignOpts(r).map(([v,t])=>`<option value="${v}" ${(r.assign||'')===v?'selected':''}>${t}</option>`).join('')}</select>`:''}</div>
  <div style="display:grid;gap:4px;justify-items:end">${stateTag(r)}<button type="button" data-act="arm:${r.id}">Gear</button></div></div>`}).join('')
 +`<p class="muted">Assigned units train, recover or staff a wing between missions, but can't deploy.${C.legends.length?` Fallen: ${C.legends.map(l=>l.n).join(', ')}.`:''}</p>`}

function armoryTab(){const L=C.roster.filter(r=>r.status==='active');if(!L.some(r=>r.id===ARM))ARM=L[0]&&L[0].id;const r=unit(ARM);
 const list=L.map(x=>`<button type="button" class="${x.id===ARM?'on':''}" data-act="arm:${x.id}"><span class="mini" style="--uc:${x.col||'var(--troop)'}">${icon(x.cls.toLowerCase())}</span><span>${x.n}<small>${x.cls} · R${x.rank} · P${unitPower(x)}</small></span></button>`).join('');
 if(!r)return '<p class="muted">No one at the Temple.</p>';const g=r.gear;let h='';
 if(isJedi(r)){const nx=SABERS[g.saber+1];
  h+=`<div class="grow"><b>Saber</b><span>${SABERS[g.saber].n} (T${g.saber+1})</span>${nx?`<button type="button" data-act="saber:${r.id}" ${!hasWing(nx.need)||C.res.credits<nx.cost||C.res.kyber<kyberOf(nx.kyber)?'disabled':''}>Craft ${nx.n} · ${cost(nx.cost,kyberOf(nx.kyber))}${needTxt(nx.need)}</button>`:''}</div>`;
  if(SABERS[g.saber].trait)h+=`<div class="grow"><b>Trait</b>${Object.entries(SABER_TRAITS).map(([k,t])=>`<button type="button" class="${g.trait===k?'on':''}" data-act="trait:${r.id}:${k}" title="${t.tip}">${t.n} · ${t.tip}</button>`).join('')}</div>`;
  h+=`<div class="grow"><b>Crystal</b>${Object.entries(CRYSTALS).map(([k,c])=>`<button type="button" class="sw ${r.col===c?'on':''}" style="--c:${c}" data-act="col:${r.id}:${c}" title="${k}" aria-label="${k} crystal"></button>`).join('')}</div>`}
 else{const nx=WEAPONS[g.w+1],slots=WEAPONS[g.w].slots;
  h+=`<div class="grow"><b>Weapon</b><span>${WEAPONS[g.w].n} (T${g.w+1})</span>${nx?`<button type="button" data-act="wpn:${r.id}" ${!hasWing(nx.need)||C.res.credits<priceOf(nx.cost)?'disabled':''}>Upgrade to ${nx.n} · ${cost(priceOf(nx.cost))}${needTxt(nx.need)}</button>`:''}</div>`;
  h+=`<div class="grow"><b>Mods ${g.mods.length}/${slots}</b>${slots?Object.entries(MODS).filter(([,m])=>researched(m.res)).map(([k,m])=>g.mods.includes(k)?`<button type="button" class="on" data-act="dropmod:${r.id}:${k}" title="Remove (no refund)">${m.n} · ${m.tip} ✕</button>`
   :`<button type="button" data-act="mod:${r.id}:${k}" ${g.mods.length>=slots||C.res.credits<priceOf(m.cost)?'disabled':''}>${m.n} · ${m.tip} · ${cost(priceOf(m.cost))}</button>`).join(''):'<span class="muted">Upgrade the weapon to fit mods.</span>'}</div>`;
  h+=`<div class="grow"><b>Color</b>${TROOP_COLS.map(c=>`<button type="button" class="sw ${(r.col||TROOP_COLS[0])===c?'on':''}" style="--c:${c}" data-act="col:${r.id}:${c}" aria-label="Token color ${c}"></button>`).join('')}</div>`}
 h+=armoryProg(r)+presetHTML(r)+identHTML(r)+treeHTML(r)+recordHTML(r);const picks=r.picks.map(k=>pickInfo(k).name).join(', ');
 return `<div class="tw"><div class="ulist">${list}</div><div class="gear"><div><b>${r.n}</b> <small class="muted">${r.cls} · Rank ${r.rank}${picks?' · '+picks:''}</small></div><div class="stl">${statLine(r)}</div>${h}
 <p class="muted">${isJedi(r)?'Sabers need the Kyber Forge and Kyber crystals.':'Military gear and heavy armor need the Armory.'} Stats shown are what this unit takes into battle.</p></div></div>`}

function wingRow(k){const w=WINGS[k];{const l=C.wings[k],nc=w.cost[l+1],bld=C.build===k,s=C.staff[k]&&unit(C.staff[k]);
 return `<div class="wing ${l?'':'off'}" data-tip="wing:${k}"><div><b>${w.n}</b> <small>${l?'Level '+l:'Not built'}${typeof slotOf==='function'&&slotOf(k)?' · '+slotById(slotOf(k)).n:''}</small><p>${bld?'Under construction · ready after the next mission':w.eff[l]}${l&&w.eff[l+1]?` · <span class="muted">Next: ${w.eff[l+1]}</span>`:!l?` · <span class="muted">${w.eff[1]}</span>`:''}</p>
 ${l?`<p class="muted">Staff: ${s?`<b>${s.n}</b> · ${w.staff}`:`open slot (${w.staff}). Assign someone in the Roster.`}</p>`:''}</div>
 ${nc!=null&&!bld?`<button type="button" data-act="build:${k}" ${C.build||C.res.credits<nc||!researched(w.req&&w.req[l+1])?'disabled':''}>${l?'Upgrade':'Build'} ${nc} Cr${!l&&typeof bestSlot==='function'&&!slotOf(k)&&bestSlot(k)?` · ${slotById(bestSlot(k)).sn}`:''}${w.req&&!researched(w.req[l+1])?` · research ${RESEARCH[w.req[l+1]].n}`:''}</button>`:''}</div>`}}
function wingsTab(){return Object.keys(WINGS).map(wingRow).join('')+'<p class="muted">One build at a time. Upkeep is paid monthly.</p>'}

function recruitTab(){const full=rosterCount()>=rosterCap();
 return `<p class="muted">Roster ${rosterCount()}/${rosterCap()} (Barracks). New candidates every month. Troopers cost ${HIRE_COST} Cr + 1 Recruit; Padawans come from the Temple, free.${full?' <span class="bad">Roster full: upgrade the Barracks.</span>':''}</p>
 <div class="cands">${C.cands.map((c,i)=>{const k=candCost(c),no=full||C.res.credits<k.credits||C.res.recruits<k.recruits,cols=c.jedi?Object.values(CRYSTALS):TROOP_COLS;
  return `<div class="cand"><div><span class="mini" style="--uc:${cols[0]}">${icon(c.cls.toLowerCase())}</span> <b data-tip="class:${c.cls}">${c.jedi?'Padawan':'Trooper'} · ${c.cls}</b></div>
  <small>Age ${c.age}</small><small>Trait: <b>${TRAITS[c.trait].n}</b> (${TRAITS[c.trait].tip})</small>
  <input id="rn${i}" type="text" maxlength="24" placeholder="${freeName(c.jedi)}" aria-label="Name">
  ${candFields(c,i)}
  <div>${cols.map((col,j)=>`<label><input type="radio" name="rc${i}" value="${col}" ${j?'':'checked'}><span class="sw" style="--c:${col};display:inline-block"></span></label>`).join(' ')}</div>
  <button type="button" class="primary" data-act="hire:${i}" ${no?'disabled':''}>Recruit · ${k.credits?`${k.credits} Cr + 1 Recruit`:'free'}</button></div>`}).join('')||'<p class="muted">No candidates left this month.</p>'}</div>`}


const TABS=[['roster','Roster',rosterTab],['armory','Armory',armoryTab],['wings','Wings',wingsTab],['research','Research',researchTab],['ops','Sith Ops',opsTab],['council','Council',councilTab],['market','Black Market',marketTab],['recruit','Recruit',recruitTab]];
function baseScreen(){SCR=baseScreen;S=null;ensureTemple();const m=$('#modal');m.hidden=false;
 if(C.step>=PLAN.length&&!C.options.length)return endScreen();
 const pend=C.roster.filter(r=>r.status==='active'&&pendingRank(r)).length;
 const R=curRoom(),war=R.id==='war';
 m.innerHTML=`<div class="box wide base">${resRow()}
 <aside class="tmap" aria-label="Temple rooms">${templeMapHTML(pend)}</aside>
 <div class="troom"><div class="thead"><div class="eyebrow">Jedi Temple · ${eraLabel()} · ${DIFF[C.diff].n}</div><h2>${R.n}</h2><p class="muted">${R.d}</p></div>
 ${C.news.length?`<div class="news">${C.news.map(n=>`<p>${n}</p>`).join('')}</div>`:''}
 <section class="rwar" ${war?'':'hidden'}>${typeof galaxyHTML==='function'?galaxyHTML():`<section><h3>Galaxy · choose the next mission</h3><div class="opts">${C.options.map(optionHTML).join('')}</div></section>`}</section>
 ${R.wing?`<div class="rwing">${wingRow(R.wing)}${typeof wingSideHTML==='function'?wingSideHTML(R.wing):''}</div>`:''}
 ${R.slot?`<div class="rwing rslot">${slotPanelHTML(R.slot)}</div>`:''}
 ${TABS.map(([k,,f])=>`<section class="tpanel" ${TAB===k&&!war&&!R.slot?'':'hidden'}>${f()}</section>`).join('')}</div></div>`;
 m.onclick=hubClick;m.onchange=ev=>{const s=ev.target.closest('[data-assign]');if(s){assign(s.dataset.assign,s.value);baseScreen()}const p=ev.target.closest('[data-pair]');if(p){setPair(p.dataset.pair,p.value);baseScreen()}}}
function hubClick(ev){if(typeof galaxyClick==='function'&&galaxyClick(ev))return;if(typeof buildClick==='function'&&buildClick(ev))return baseScreen();if(ev.target.closest('#hubCx'))return codexOpen();if(ev.target.closest('#hubSet'))return settingsOpen();const rm=ev.target.closest('[data-room]');if(rm){setRoom(rm.dataset.room);return baseScreen()}const t=ev.target.closest('[data-tab]');if(t){TAB=t.dataset.tab;return baseScreen()}
 const b=ev.target.closest('[data-act]');if(!b||b.disabled)return;const [a,x,y]=b.dataset.act.split(':');
 if(a==='squad')return squadScreen(+x);if(a==='tree')return treeScreen(x);
 if(progClick(a,x,y));else if(a==='build')buildWing(x);else if(a==='pick')pickAbility(x,y);else if(a==='alt')setAlt(x,y);else if(a==='borrow')borrowSkill(x,y);else if(a==='grief')griefChoice(x,y==='1');
 else if(a==='arm'){ARM=x;TAB='armory';ROOM='armory'}else if(a==='wpn')buyWeapon(x);else if(a==='armor')buyArmor(x,y);else if(a==='mod')buyMod(x,y);else if(a==='dropmod')dropMod(x,y);
 else if(a==='saber')craftSaber(x);else if(a==='trait')setTrait(x,y);else if(a==='col')setColor(x,y);
 else if(a==='hire'){candEdit(+x);const i=+x,c=$('#modal').querySelector(`input[name="rc${i}"]:checked`);hireCand(i,$('#rn'+i).value,c&&c.value)}
 baseScreen()}

// Full skill tree for one unit (Armory): trunk ranks 1–2, then both specializations side by side, then cross-training.
const optHTML=(k,on,r)=>{const a=pickInfo(k);return `<span class="topt ${on?'on':''}" data-tip="${AB[k]?'ability':'gear'}:${k}">${icon(a.ic||'guard')}<b>${a.name}${on&&r&&AB[k]?pwTag(skillPower(r,k)):''}</b><small>${a.desc||a.tip||''}</small></span>`};
const rowHTML=(r,rk,opts,P)=>`<div class="trow ${rk>r.rank?'lock':''}"><span>R${rk}${RANKS[rk-1]?` <small>${RANKS[rk-1].xp} XP</small>`:''}</span>${opts.map(k=>optHTML(k,P[rk-1]===k,r)).join('')}</div>`;
function treeHTML(r){const T=TREES[r.cls];if(!T)return '';const P=r.picks.length?r.picks:picksOf(r);
 return `<div><b class="eyebrow">Skill tree · ${r.cls}${specOf(r)?' · '+specOf(r).n:''}</b> <button type="button" class="tbtn" data-act="tree:${r.id}">Open full tree</button> <span class="pwr">${icon('st_power')} Power ${unitPower(r)}</span> <small class="muted">Skill power: I at learning, +1 every 2 ranks (max III), signature +1. Each level: +1 damage/heal, +5% hit.</small><br>${CLASS[r.cls].desc?` <small class="muted">${CLASS[r.cls].desc}</small>`:''}<div class="tree">${[1,2].map(rk=>rowHTML(r,rk,T.trunk[rk],P)).join('')}</div>
 <div class="specs">${Object.entries(T.specs).map(([id,s])=>`<div class="spec ${r.spec===id?'on':r.spec?'off':''}"><b>${icon(s.ic||'guard')} ${s.n}</b><small class="muted">${s.desc} Rank 3, permanent.</small>${SPEC_TRAITS[id]?`<small class="strait"><b>${SPEC_TRAITS[id].n}:</b> ${SPEC_TRAITS[id].desc}</small>`:''}
  <div class="tree">${rowHTML(r,3,[s.sig],r.spec===id?P:[])}${[4,5,6,7].map(rk=>rowHTML(r,rk,s[rk],r.spec===id?P:[])).join('')}</div></div>`).join('')}</div>${xtrainHTML(r)}</div>`}
function xtrainHTML(r){const lv=C.wings.training||0,n=xtrainSlots(r),B=r.borrow||[];let h;
 if(!lv)h='<small class="muted">Build the Training Salle to cross-train: borrow skills from a second class.</small>';
 else if(r.rank<XTRAIN.minRank[0])h=`<small class="muted">Cross-training opens at rank ${XTRAIN.minRank[0]}.</small>`;
 else{h=`<small class="muted">Borrowed ${B.length}/${n}${lv<2?' · Training Salle L2 adds a 2nd at rank 6':r.rank<XTRAIN.minRank[1]?' · 2nd slot at rank 6':''}. ${isJedi(r)?'Jedi can learn any class.':'Troops can learn other troop classes, never the Force.'}</small>`;
  if(B.length)h+=`<div class="tree"><div class="trow"><span>${r.alt}</span>${B.map(k=>optHTML(k,1,r)).join('')}</div></div>`;
  if(!B.length)h+=`<div class="picks">Second class: ${xtrainClasses(r).map(c=>`<button type="button" class="${r.alt===c?'on':''}" data-act="alt:${r.id}:${c}" data-tip="class:${c}">${icon(c.toLowerCase())}${c}</button>`).join('')}</div>`;
  if(r.alt&&B.length<n)h+=`<div class="picks">Borrow from ${r.alt}: ${xtrainPool(r).map(k=>{const a=pickInfo(k);return `<button type="button" data-act="borrow:${r.id}:${k}" data-tip="${AB[k]?'ability':'gear'}:${k}">${icon(a.ic||'guard')}${a.name}</button>`}).join('')}</div>`}
 return `<div class="xtrain"><b class="eyebrow">Cross-training</b> ${h}</div>`}

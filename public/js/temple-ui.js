/* Temple hub: Operations (missions) on top, then tabs Roster · Armory · Wings · Recruit · Council. All tabs render; inactive ones are hidden. */
let TAB='roster',ARM=null;
(function(){const st=document.createElement('style');st.textContent=`
.tabs{display:flex;gap:4px;border-bottom:1px solid var(--line);flex-wrap:wrap}.tabs button{border-radius:6px 6px 0 0;border-bottom:none}
.tabs button.on{color:var(--holo);border-color:var(--holo)}.tpanel{display:grid;gap:8px}
.tw{display:grid;gap:14px}@media(min-width:880px){.tw{grid-template-columns:240px 1fr}}
.ulist{display:grid;gap:4px;align-content:start}.ulist button{display:flex;gap:8px;align-items:center;text-align:left}.ulist small,.rmain small{display:block;color:var(--dim)}
.gear{display:grid;gap:10px}.gear .grow{display:flex;flex-wrap:wrap;gap:6px;align-items:center}.gear .grow>b{min-width:90px;font:600 12px var(--disp);letter-spacing:.08em;color:var(--dim);text-transform:uppercase}
.stl{font:500 12px var(--mono);color:var(--fg);background:var(--raise);border:1px solid var(--line);border-radius:6px;padding:8px}
.sw{width:26px;height:26px;min-height:0;padding:0;border-radius:50%;background:var(--c);border:2px solid var(--line)}.sw.on{border-color:var(--fg);box-shadow:0 0 0 2px var(--holo)}
.cands{display:grid;gap:10px}@media(min-width:880px){.cands{grid-template-columns:repeat(3,1fr)}}
.cand{border:1px solid var(--line);border-radius:8px;padding:10px;display:grid;gap:6px;background:var(--raise)}.cand input{font-size:14px;padding:6px}
.cand label{display:inline-block}.cand input[type=radio]{position:absolute;opacity:0}.cand input[type=radio]:checked+.sw{border-color:var(--fg);box-shadow:0 0 0 2px var(--holo)}
.seats{display:grid;gap:8px;grid-template-columns:repeat(auto-fill,minmax(180px,1fr))}.seat{border:1px solid var(--line);border-radius:8px;padding:8px;font-size:12px}.seat.vac{color:var(--dim);border-style:dashed}
.rrow select{max-width:220px;font-size:12px;background:var(--raise);color:var(--fg);border:1px solid var(--line);border-radius:6px;padding:4px}
.bd{color:var(--good);font-size:12px}.up{color:var(--good)}`;document.head.appendChild(st)})();

const cost=(cr,ky)=>`${cr} Cr${ky?` + ${ky} Ky`:''}`;
const needTxt=n=>n&&!hasWing(n)?` · needs ${WINGS[n[0]].n} ${n[1]}`:'';
function statLine(r){const u=battleUnit(r);return `HP ${u.hp} · Aim ${u.aim} · Dmg ${u.dmg.join('–')} · Range ${u.range<2?'melee':u.range} · Move ${u.mob}${u.armor?` · Armor ${u.armor}`:''}${u.crit?` · Crit ${u.crit}%`:''}${u.maxF?` · Focus ${u.maxF} · Deflect ${u.deflect}`:''}${u.kits!=null?` · Medkits ${u.kits}`:''}${u.nades!=null?` · Grenades ${u.nades}`:''}${u.bondAim?` · Bond +${u.bondAim} aim`:''}`}
function stateTag(r){return r.status==='retired'?'<span class="dim">Retired</span>':r.status==='captured'?'<span class="bad">Captured</span>':r.assign?`<span class="warn">${assignName(r)}${r.wound?` · ${r.wound}d`:''}</span>`:r.wound?`<span class="warn">Wounded · ${r.wound} days</span>`:'<span class="ready">Ready</span>'}

function rosterTab(){const act=C.roster.filter(r=>r.status!=='dead');
 return act.map(r=>{const next=r.rank<RANKS.length?RANKS[r.rank].xp:null,p=pendingRank(r),bs=bondsOf(r).filter(b=>b.lvl);
  return `<div class="rrow"><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><div class="rmain"><b>${r.n}</b>
  <small>${r.title?r.title+' · ':''}${r.cls} · Rank ${r.rank} · ${r.xp}${next?'/'+next:''} XP${isJedi(r)?` · Darkness ${r.dark}`:''}${r.trait?` · ${TRAITS[r.trait].n}`:''} · age ${r.age}${r.fear?` · <span class="bad">afraid (${r.fear})</span>`:''}</small>
  ${bs.length?`<small class="bd">Bonds: ${bs.map(b=>`${b.n} ${'★'.repeat(b.lvl)}`).join(', ')}</small>`:''}
  ${p?`<div class="picks">Rank ${p}: choose one ${KITS[r.cls][p].map(k=>{const a=pickInfo(k);return `<button type="button" data-act="pick:${r.id}:${k}" title="${(a.tip||'').replace(/"/g,'')}">${icon(a.ic||'guard')}${a.name}</button>`}).join('')}</div>`:''}
  ${r.grief?`<div class="picks">${r.n} lost ${r.grief}. <button type="button" data-act="grief:${r.id}:0">Grieve (keep fear)</button><button type="button" data-act="grief:${r.id}:1">Use the anger (Darkness +2, no fear)</button></div>`:''}
  ${r.status==='active'?`<select data-assign="${r.id}" aria-label="Assignment for ${r.n}">${assignOpts(r).map(([v,t])=>`<option value="${v}" ${(r.assign||'')===v?'selected':''}>${t}</option>`).join('')}</select>`:''}</div>
  <div style="display:grid;gap:4px;justify-items:end">${stateTag(r)}<button type="button" data-act="arm:${r.id}">Gear</button></div></div>`}).join('')
 +`<p class="muted">Assigned units train, recover or staff a wing between missions, but can't deploy.${C.legends.length?` Fallen: ${C.legends.map(l=>l.n).join(', ')}.`:''}</p>`}

function armoryTab(){const L=C.roster.filter(r=>r.status==='active');if(!L.some(r=>r.id===ARM))ARM=L[0]&&L[0].id;const r=unit(ARM);
 const list=L.map(x=>`<button type="button" class="${x.id===ARM?'on':''}" data-act="arm:${x.id}"><span class="mini" style="--uc:${x.col||'var(--troop)'}">${icon(x.cls.toLowerCase())}</span><span>${x.n}<small>${x.cls} · R${x.rank}</small></span></button>`).join('');
 if(!r)return '<p class="muted">No one at the Temple.</p>';const g=r.gear;let h='';
 if(isJedi(r)){const nx=SABERS[g.saber+1];
  h+=`<div class="grow"><b>Saber</b><span>${SABERS[g.saber].n} (T${g.saber+1})</span>${nx?`<button type="button" data-act="saber:${r.id}" ${!hasWing(nx.need)||C.res.credits<nx.cost||C.res.kyber<kyberOf(nx.kyber)?'disabled':''}>Craft ${nx.n} · ${cost(nx.cost,kyberOf(nx.kyber))}${needTxt(nx.need)}</button>`:''}</div>`;
  if(SABERS[g.saber].trait)h+=`<div class="grow"><b>Trait</b>${Object.entries(SABER_TRAITS).map(([k,t])=>`<button type="button" class="${g.trait===k?'on':''}" data-act="trait:${r.id}:${k}" title="${t.tip}">${t.n} · ${t.tip}</button>`).join('')}</div>`;
  h+=`<div class="grow"><b>Crystal</b>${Object.entries(CRYSTALS).map(([k,c])=>`<button type="button" class="sw ${r.col===c?'on':''}" style="--c:${c}" data-act="col:${r.id}:${c}" title="${k}" aria-label="${k} crystal"></button>`).join('')}</div>`}
 else{const nx=WEAPONS[g.w+1],slots=WEAPONS[g.w].slots;
  h+=`<div class="grow"><b>Weapon</b><span>${WEAPONS[g.w].n} (T${g.w+1})</span>${nx?`<button type="button" data-act="wpn:${r.id}" ${!hasWing(nx.need)||C.res.credits<priceOf(nx.cost)?'disabled':''}>Upgrade to ${nx.n} · ${cost(priceOf(nx.cost))}${needTxt(nx.need)}</button>`:''}</div>`;
  h+=`<div class="grow"><b>Armor</b>${Object.entries(ARMOR).map(([k,a])=>`<button type="button" class="${g.armor===k?'on':''}" data-act="armor:${r.id}:${k}" ${g.armor!==k&&(!hasWing(a.need)||C.res.credits<priceOf(a.cost))?'disabled':''}>${a.n}${a.mod?` (${a.mod.hp?'+'+a.mod.hp+' HP':''}${a.mod.mob?', '+a.mod.mob+' move':''})`:''}${g.armor===k?'':' · '+cost(priceOf(a.cost))}${needTxt(a.need)}</button>`).join('')}</div>`;
  h+=`<div class="grow"><b>Mods ${g.mods.length}/${slots}</b>${slots?Object.entries(MODS).map(([k,m])=>g.mods.includes(k)?`<button type="button" class="on" data-act="dropmod:${r.id}:${k}" title="Remove (no refund)">${m.n} · ${m.tip} ✕</button>`
   :`<button type="button" data-act="mod:${r.id}:${k}" ${g.mods.length>=slots||C.res.credits<priceOf(m.cost)?'disabled':''}>${m.n} · ${m.tip} · ${cost(priceOf(m.cost))}</button>`).join(''):'<span class="muted">Upgrade the weapon to fit mods.</span>'}</div>`;
  h+=`<div class="grow"><b>Color</b>${TROOP_COLS.map(c=>`<button type="button" class="sw ${(r.col||TROOP_COLS[0])===c?'on':''}" style="--c:${c}" data-act="col:${r.id}:${c}" aria-label="Token color ${c}"></button>`).join('')}</div>`}
 const picks=r.picks.map(k=>pickInfo(k).name).join(', ');
 return `<div class="tw"><div class="ulist">${list}</div><div class="gear"><div><b>${r.n}</b> <small class="muted">${r.cls} · Rank ${r.rank}${picks?' · '+picks:''}</small></div><div class="stl">${statLine(r)}</div>${h}
 <p class="muted">${isJedi(r)?'Sabers need the Kyber Forge and Kyber crystals.':'Military gear and heavy armor need the Armory.'} Stats shown are what this unit takes into battle.</p></div></div>`}

function wingsTab(){return Object.entries(WINGS).map(([k,w])=>{const l=C.wings[k],nc=w.cost[l+1],bld=C.build===k,s=C.staff[k]&&unit(C.staff[k]);
 return `<div class="wing ${l?'':'off'}"><div><b>${w.n}</b> <small>${l?'Level '+l:'Not built'}</small><p>${bld?'Under construction · ready after the next mission':w.eff[l]}${l&&w.eff[l+1]?` · <span class="muted">Next: ${w.eff[l+1]}</span>`:!l?` · <span class="muted">${w.eff[1]}</span>`:''}</p>
 ${l?`<p class="muted">Staff: ${s?`<b>${s.n}</b> · ${w.staff}`:`open slot (${w.staff}). Assign someone in the Roster.`}</p>`:''}</div>
 ${nc!=null&&!bld?`<button type="button" data-act="build:${k}" ${C.build||C.res.credits<nc?'disabled':''}>${l?'Upgrade':'Build'} ${nc} Cr</button>`:''}</div>`}).join('')+'<p class="muted">One build at a time. Upkeep is paid monthly.</p>'}

function recruitTab(){const full=rosterCount()>=rosterCap();
 return `<p class="muted">Roster ${rosterCount()}/${rosterCap()} (Barracks). New candidates every month. Troopers cost ${HIRE_COST} Cr + 1 Recruit; Padawans come from the Temple, free.${full?' <span class="bad">Roster full: upgrade the Barracks.</span>':''}</p>
 <div class="cands">${C.cands.map((c,i)=>{const k=candCost(c),no=full||C.res.credits<k.credits||C.res.recruits<k.recruits,cols=c.jedi?Object.values(CRYSTALS):TROOP_COLS;
  return `<div class="cand"><div><span class="mini" style="--uc:${cols[0]}">${icon(c.cls.toLowerCase())}</span> <b>${c.jedi?'Padawan':'Trooper'} · ${c.cls}</b></div>
  <small>${c.species}, age ${c.age} · ${c.origin}</small><small>Trait: <b>${TRAITS[c.trait].n}</b> (${TRAITS[c.trait].tip})</small>
  <input id="rn${i}" type="text" maxlength="24" placeholder="${freeName(c.jedi)}" aria-label="Name">
  <div>${cols.map((col,j)=>`<label><input type="radio" name="rc${i}" value="${col}" ${j?'':'checked'}><span class="sw" style="--c:${col};display:inline-block"></span></label>`).join(' ')}</div>
  <button type="button" class="primary" data-act="hire:${i}" ${no?'disabled':''}>Recruit · ${k.credits?`${k.credits} Cr + 1 Recruit`:'free'}</button></div>`}).join('')||'<p class="muted">No candidates left this month.</p>'}</div>`}

function councilTab(){return `<div class="seats">${COUNCIL.map(c=>c.seat?`<div class="seat"><b>${c.n}</b><div class="muted">${c.seat} · ${c.stance}</div><div>Perk: ${c.perk}</div><small class="muted">${c.lore}</small></div>`:'<div class="seat vac">Vacant seat</div>').join('')}</div>
 <p class="muted">Display only for now: seat perks and Council votes switch on in a later update.</p>`}

const TABS=[['roster','Roster',rosterTab],['armory','Armory',armoryTab],['wings','Wings',wingsTab],['recruit','Recruit',recruitTab],['council','Council',councilTab]];
function baseScreen(){SCR=baseScreen;S=null;ensureTemple();const m=$('#modal');m.hidden=false;
 if(C.step>=PLAN.length&&!C.options.length)return endScreen();
 const pend=C.roster.filter(r=>r.status==='active'&&pendingRank(r)).length;
 m.innerHTML=`<div class="box wide base">${resRow()}
 <div><div class="eyebrow">Old Republic · ~3,660 BBY · ${DIFF[C.diff].n}</div><h2>Jedi Temple, Coruscant</h2></div>
 ${C.news.length?`<div class="news">${C.news.map(n=>`<p>${n}</p>`).join('')}</div>`:''}
 <section><h3>Galaxy · choose the next mission</h3><div class="opts">${C.options.map(optionHTML).join('')}</div></section>
 <nav class="tabs" role="tablist">${TABS.map(([k,n])=>`<button type="button" role="tab" class="${TAB===k?'on':''}" aria-selected="${TAB===k}" data-tab="${k}">${n}${k==='roster'&&pend?` (${pend})`:''}</button>`).join('')}</nav>
 ${TABS.map(([k,,f])=>`<section class="tpanel" ${TAB===k?'':'hidden'}>${f()}</section>`).join('')}</div>`;
 m.onclick=hubClick;m.onchange=ev=>{const s=ev.target.closest('[data-assign]');if(s){assign(s.dataset.assign,s.value);baseScreen()}}}
function hubClick(ev){const t=ev.target.closest('[data-tab]');if(t){TAB=t.dataset.tab;return baseScreen()}
 const b=ev.target.closest('[data-act]');if(!b||b.disabled)return;const [a,x,y]=b.dataset.act.split(':');
 if(a==='squad')return squadScreen(+x);
 if(a==='build')buildWing(x);else if(a==='pick')pickAbility(x,y);else if(a==='grief')griefChoice(x,y==='1');
 else if(a==='arm'){ARM=x;TAB='armory'}else if(a==='wpn')buyWeapon(x);else if(a==='armor')buyArmor(x,y);else if(a==='mod')buyMod(x,y);else if(a==='dropmod')dropMod(x,y);
 else if(a==='saber')craftSaber(x);else if(a==='trait')setTrait(x,y);else if(a==='col')setColor(x,y);
 else if(a==='hire'){const i=+x,c=$('#modal').querySelector(`input[name="rc${i}"]:checked`);hireCand(i,$('#rn'+i).value,c&&c.value)}
 baseScreen()}

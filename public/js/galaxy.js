/* Galaxy map (Chat I): replaces the hub's mission list. Clickable regions, one pin per mission option and field op,
   and a briefing panel (reward, deadline, risk, expected enemies, squad rules). Data: data-galaxy.js. Field ops: fieldops.js.
   Hooks: temple-ui.js calls galaxyHTML() for the Galaxy section and galaxyClick(ev) first in hubClick. UI-only state in GAL (not saved). */
const GAL={sel:null,reg:null};
const planetOf=where=>{const p=String(where||'').split('·').pop().trim();return PLANETS[p]?p:null};
// Enemy-power estimate for a mission: every starting foe and every wave, weighted by HP, armor and aim; horrors count extra.
function foeList(M){const L=[...(M.foes||[]).map(f=>f[0]),...Object.values(M.waves||{}).flat(),...[M.boss,M.bossKey].filter(k=>k&&!(M.foes||[]).some(f=>f[0]===k))];return L.filter(k=>FOES[k])}
function riskOf(M,id){const d=DIFF[(C&&C.diff)||'normal'],t=(typeof TUNE!=='undefined'&&(TUNE[id+':0']||TUNE[id]))||{},L=foeList(M);
 let p=0;for(const k of L){const F=FOES[k];p+=(F.hp+(t.hp||0)+d.enemyHp+2*(F.armor||0))*((F.aim+(t.aim||0)+d.enemyAim)/65)*(F.horror?1.4:1)*(k===M.boss||k===M.bossKey?1.5:1)}
 p+=((t.extra||0)+d.extra*Object.keys(M.waves||{}).length)*4;
 const cm=typeof campaignMods==='function'?campaignMods():{};p*=1+((cm.enemyAim||0)+(cm.enemyHp||0)*8)/100;
 const b=RISK.filter(r=>p>=r[0]).pop();return{p:Math.round(p),n:b[1],lv:b[2]}}
function foeCounts(M){const c={};for(const k of foeList(M)){const n=FOES[k].n;c[n]=(c[n]||0)+1}return Object.entries(c).map(([n,k])=>`${k>1?k+'× ':''}${n}`).join(', ')}
// Everything the map shows: mission options (index i) and field ops.
function galaxyItems(){ensureField();const it=[];
 C.options.forEach((o,i)=>{const M=MISSIONS[o.mission];if(!M)return;const cat=o.redeem?'redeem':o.quest?'quest':o.crisis==='rescue'&&o.hostages?'rescue':o.story?'story':'crisis';
  it.push({key:'o'+i,i,o,M,cat,planet:planetOf(M.where)||'Mid Rim',n:o.n||M.n,ic:o.redeem?'darkness':TYPE_IC[M.type]||'strike'})});
 for(const f of C.field.list)it.push({key:'f'+f.id,f,cat:'field',planet:PLANETS[f.planet]?f.planet:'Mid Rim',n:FIELD_OPS[f.k].n,ic:f.st==='team'?'dash':'scan'});
 const at={};for(const x of it){const P=PLANETS[x.planet],k=at[x.planet]=(at[x.planet]||0)+1;   // spread pins that share a planet
  const a=(k-1)*2.1,r=k>1?16+(k>6?10:0):0;x.x=Math.round(P.x+r*Math.cos(a));x.y=Math.round(P.y+r*Math.sin(a))}
 return it}
// How long an option stays open, in plain words.
function expiryTxt(x){const o=x.o;if(x.f)return x.f.st==='team'?`Team away · back in ${x.f.left} days`:`Expires in ${x.f.exp} days`;
 if(o.story)return'No deadline · but the war moves while you wait';
 if(!o.adv)return o.quest||o.redeem?'Stays open while the unit is free':'Stays open this step';
 return C.options.filter(y=>y.adv).length>1?'Expires when you launch another mission':'Last chance';}
function galaxyHTML(){const it=galaxyItems();if(!it.some(x=>x.key===GAL.sel))GAL.sel=(it.find(x=>x.o&&x.o.story)||it[0]||{}).key||null;
 const cx=GAL_C.x,cy=GAL_C.y,rings=REGIONS.filter(r=>r[2]).reverse();
 const svg=`<svg class="gmap" viewBox="0 0 600 380" role="img" aria-label="Galaxy map">
 <defs><radialGradient id="gcore"><stop offset="0" stop-color="#e8f6ff" stop-opacity=".55"/><stop offset="1" stop-color="#79d3e2" stop-opacity="0"/></radialGradient></defs>
 <path class="greg unk ${GAL.reg==='unknown'?'on':''}" data-reg="unknown" d="M0 0H70Q30 190 70 380H0Z"><title>${REG_N.unknown}</title></path>
 ${rings.map(([id,n,rx])=>`<ellipse class="greg ${GAL.reg===id?'on':''}" data-reg="${id}" cx="${cx}" cy="${cy}" rx="${rx}" ry="${Math.round(rx*GAL_C.ry)}"><title>${n}</title></ellipse>`).join('')}
 <ellipse cx="${cx}" cy="${cy}" rx="46" ry="28" fill="url(#gcore)" pointer-events="none"/>
 ${rings.map(([id,n,rx])=>`<text class="glab" x="${cx}" y="${cy-Math.round(rx*GAL_C.ry)+11}">${n}</text>`).join('')}<text class="glab" x="36" y="370">Unknown</text>
 ${Object.entries(PLANETS).filter(([n])=>!/Rim|Way/.test(n)).map(([n,p])=>`<circle class="gpl" cx="${p.x}" cy="${p.y}" r="2.2"/><text class="gpn" x="${p.x+5}" y="${p.y-4}">${n}</text>`).join('')}
 ${it.map(x=>{const P=PIN[x.cat],on=x.key===GAL.sel;return `<g class="gpin ${on?'on':''} ${x.f&&x.f.st==='team'?'away':''}" data-pin="${x.key}" tabindex="0" role="button" aria-label="${x.n}" style="--pc:${P.c}">
  <line x1="${x.x}" y1="${x.y}" x2="${x.x}" y2="${x.y-14}"/><circle cx="${x.x}" cy="${x.y-22}" r="${on?11:9}"/><use href="#i-${x.ic}" x="${x.x-6}" y="${x.y-28}" width="12" height="12"/><title>${x.n} · ${x.planet}</title></g>`}).join('')}
 </svg>`;
 const chips=it.map(x=>`<button type="button" class="gchip ${x.key===GAL.sel?'on':''}" data-pin="${x.key}" style="--pc:${PIN[x.cat].c}"><i></i>${x.n}<small>${x.planet}</small></button>`).join('');
 const legend=[['story','Story'],['crisis','Crisis'],['rescue','Rescue'],['quest','Personal'],['redeem','Redemption'],['field','Field op']].filter(([k])=>it.some(x=>x.cat===k))
  .map(([k,n])=>`<span style="--pc:${PIN[k].c}"><i></i>${n}</span>`).join('');
 return `<section class="galaxy"><h3>Galaxy · choose the next mission <small>${it.filter(x=>x.o).length} missions · ${it.filter(x=>x.f&&x.f.st==='open').length} field ops</small></h3>
 <div class="gwrap"><div class="gleft">${svg}<div class="glegend">${legend}<span class="muted">Click a pin or a region.</span></div><div class="gchips">${chips}</div></div>
 <aside class="gpanel">${GAL.reg?regionPanel(GAL.reg,it):panelFor(it.find(x=>x.key===GAL.sel))}${fieldLogHTML()}</aside></div></section>`}
function regionPanel(id,it){const R=REGIONS.find(r=>r[0]===id),here=it.filter(x=>(PLANETS[x.planet]||{}).reg===id);
 return `<div class="eyebrow">Region</div><h3 class="gtitle">${R[1]}</h3><p>${R[3]}</p>
 ${here.length?`<div class="gchips col">${here.map(x=>`<button type="button" class="gchip" data-pin="${x.key}" style="--pc:${PIN[x.cat].c}"><i></i>${x.n}<small>${x.planet}</small></button>`).join('')}</div>`:'<p class="muted">Nothing needs the Order here right now.</p>'}
 <button type="button" data-reg="none">Back to the briefing</button>`}
function panelFor(x){if(!x)return '<p class="muted">The galaxy is quiet.</p>';if(x.f)return fieldPanel(x.f);
 const {o,M,i}=x,P=PLANETS[x.planet]||{},seeRw=C.wings.comms||o.story,rk=riskOf(M,o.mission),sib=C.options.filter(y=>y.adv).length>1;
 const reward=seeRw?(fmtRes(M.reward)||'none')+(M.bonus?` · bonus ${fmtRes(M.bonus)} (${M.bonusTxt})`:''):'Unknown · build the Comms Hub to see';
 const goal=M.type==='defend'?`Hold for ${M.turns} turns`:M.type==='rescue'?'Free the prisoner and reach evac':M.type==='investigate'?'Scan the terminals and extract':M.type==='sabotage'?'Plant the charges and extract':M.type==='escort'?'Get the VIP to evac':'Take down the target';
 return `<div class="eyebrow">${o.story?'Story mission':o.kind||'Mission'} · ${M.where}${P.reg?` · ${REG_N[P.reg]}`:''}</div><h3 class="gtitle">${x.n}</h3>
 ${M.quote&&o.story?`<blockquote class="mq">${M.quote}</blockquote>`:''}<p>${o.text||M.brief}</p>${o.text&&M.brief&&o.text!==M.brief?`<p class="muted">${M.brief}</p>`:''}
 <div class="gfacts"><span>Goal</span><b>${goal}${M.par?` · par ${M.par} turns`:''}</b>
 <span>Risk</span><b class="risk r${rk.lv}" title="Enemy strength estimate ${rk.p}">${'▮'.repeat(rk.lv)}${'▯'.repeat(4-rk.lv)} ${rk.n}</b>
 <span>Expected</span><b>${foeCounts(M)||'Unknown'}${M.stealth?' · you start hidden':''}</b>
 <span>Reward</span><b>${o.quest?'mission pay · ':''}${reward}</b>${o.questTxt?`<span>${o.redeem?'Redemption':'Quest'}</span><b class="up">${o.questTxt}</b>`:''}
 <span>Deadline</span><b>${expiryTxt(x)}</b>${o.adv&&sib?`<span>If ignored</span><b class="bad">${o.ignore&&o.ignore.lose?'they are lost':fmtRes(o.ignore)||'nothing'}</b>`:''}
 ${o.src?`<span>Asked by</span><b>${o.src}</b>`:''}${o.quest?`<span>Must deploy</span><b>${unit(o.quest).n}</b>`:''}</div>
 <button type="button" class="primary" data-act="squad:${i}">Choose squad</button>`}
// Returns true when it handled the click (then the hub re-renders).
function galaxyClick(ev){const p=ev.target.closest('[data-pin]'),r=ev.target.closest('[data-reg]'),b=ev.target.closest('[data-act^="fop:"],[data-act^="fsend:"]');
 if(b&&!b.disabled){const [a,x]=b.dataset.act.split(':');fieldClick(a,x);baseScreen();return true}
 if(p){GAL.sel=p.dataset.pin;GAL.reg=null;FTEAM=[];baseScreen();return true}
 if(r){GAL.reg=r.dataset.reg==='none'||GAL.reg===r.dataset.reg?null:r.dataset.reg;baseScreen();return true}return false}
document.addEventListener('keydown',ev=>{if((ev.key==='Enter'||ev.key===' ')&&ev.target.closest&&ev.target.closest('g[data-pin]')){ev.preventDefault();ev.target.dispatchEvent(new MouseEvent('click',{bubbles:true}))}});

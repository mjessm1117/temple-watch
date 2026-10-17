/* Galaxy map (Chat I): replaces the hub's mission list. Clickable regions, one pin per mission option and field op,
   and a briefing panel (reward, deadline, risk, expected enemies, squad rules). Data: data-galaxy.js. Field ops: fieldops.js.
   Hooks: temple-ui.js calls galaxyHTML() for the Galaxy section and galaxyClick(ev) first in hubClick. UI-only state in GAL (not saved). */
const GAL={sel:null,reg:null};
const planetOf=where=>{const p=String(where||'').split('·').pop().trim();return PLANETS[p]?p:null};
// Enemy-power estimate for a mission: every starting foe and every wave, weighted by HP, armor and aim; horrors count extra.
function foeList(M){const L=[...(M.foes||[]).map(f=>f[0]),...Object.values(M.waves||{}).flat(),...[M.boss,M.bossKey].filter(k=>k&&!(M.foes||[]).some(f=>f[0]===k))];return L.filter(k=>FOES[k])}
function enemyPower(M,id){const d=DIFF[(C&&C.diff)||'normal'],t=(typeof TUNE!=='undefined'&&(TUNE[id+':0']||TUNE[id]))||{},L=foeList(M);
 let p=0;for(const k of L){const F=FOES[k];p+=(F.hp+(t.hp||0)+d.enemyHp+2*(F.armor||0))*((F.aim+(t.aim||0)+d.enemyAim)/65)*(F.horror?1.4:1)*(k===M.boss||k===M.bossKey||F.boss?RISK_W.boss:1)}
 p+=((t.extra||0)+d.extra*Object.keys(M.waves||{}).length)*4;if(RISK_W.clock.includes(M.type))p+=RISK_W.threat;   // Threat-clock missions call reinforcements
 const cm=typeof campaignMods==='function'?campaignMods():{};return p*(1+((cm.enemyAim||0)+(cm.enemyHp||0)*8)/100)}
// Risk = enemy strength vs the squad you'd send (defaultSquad: best fit units, front-B rules included). No fit units → enemy strength alone.
function riskOf(M,id,o){const p=enemyPower(M,id),sq=C&&typeof unitPower==='function'?defaultSquad(o||{}).map(unit).filter(Boolean):[],sp=sq.reduce((s,r)=>s+unitPower(r),0);
 const T=sp?100*p/sp:p/RISK_W.solo,b=RISK.filter(r=>T>=r[0]).pop()
 return{p:Math.round(p),sp,T:+T.toFixed(1),n:b[1],lv:b[2],vs:sq.length}}
function foeCounts(M){const c={};for(const k of foeList(M)){const n=FOES[k].n;c[n]=(c[n]||0)+1}return Object.entries(c).map(([n,k])=>`${k>1?k+'× ':''}${n}`).join(', ')}
// Everything the map shows: mission options (index i) and field ops.
function galaxyItems(){ensureField();const it=[];
 C.options.forEach((o,i)=>{const M=MISSIONS[o.mission];if(!M)return;const cat=o.redeem?'redeem':o.quest?'quest':o.crisis==='rescue'&&o.hostages?'rescue':o.story?'story':'crisis';
  it.push({key:'o'+i,i,o,M,cat,planet:planetOf(M.where)||'Mid Rim',n:o.n||M.n,ic:o.redeem?'darkness':TYPE_IC[M.type]||'strike'})});
 for(const o of (C.ops&&C.ops.list)||[])if(o.st==='open'||o.st==='team')it.push({key:'s'+o.id,s:o,cat:'sith',planet:opPlanet(o),n:SITH_OPS[o.k].n,ic:o.st==='team'?'dash':'e_trooper'});
 for(const f of C.field.list)it.push({key:'f'+f.id,f,cat:'field',planet:PLANETS[f.planet]?f.planet:'Mid Rim',n:FIELD_OPS[f.k].n,ic:f.st==='team'?'dash':'scan'});
 const at={},seen={};for(const x of it)at[x.planet]=(at[x.planet]||0)+1;   // pins sharing a planet fan out in an arc above it
 for(const x of it){const P=PLANETS[x.planet],n=at[x.planet],k=seen[x.planet]=(seen[x.planet]||0)+1;
  const a=n>1?Math.PI*(1.15+.7*(k-1)/(n-1)):0,r=n>1?(n>4?30:22):0;x.x=Math.round(P.x+r*Math.cos(a));x.y=Math.round(P.y+r*Math.sin(a)+(n>1?8:0))}
 return it}
// How long an option stays open, in plain words.
function expiryTxt(x){const o=x.o;if(x.s)return x.s.st==='team'?'Team away · resolves after the next mission':'Hits at month end';if(x.f)return x.f.st==='team'?`Team away · back in ${x.f.left} days`:`Expires in ${x.f.exp} days`;
 if(o.story)return'No deadline · but the war moves while you wait';
 if(!o.adv)return o.quest||o.redeem?'Stays open while the unit is free':'Stays open this step';
 return C.options.filter(y=>y.adv).length>1?'Expires when you launch another mission':'Last chance';}
function galaxyHTML(){const it=galaxyItems();if(!it.some(x=>x.key===GAL.sel))GAL.sel=(it.find(x=>x.o&&x.o.story)||it[0]||{}).key||null;
 const at={};for(const x of it)at[x.planet]=1;const cx=GAL_C.x,cy=GAL_C.y,rings=REGIONS.filter(r=>r[2]).reverse();
 const svg=`<svg class="gmap" viewBox="0 0 600 380" role="img" aria-label="Galaxy map">
 <defs><radialGradient id="gcore"><stop offset="0" stop-color="#e8f6ff" stop-opacity=".55"/><stop offset="1" stop-color="#79d3e2" stop-opacity="0"/></radialGradient></defs>
 <path class="greg unk ${GAL.reg==='unknown'?'on':''}" data-reg="unknown" d="M0 0H70Q30 190 70 380H0Z"><title>${REG_N.unknown}</title></path>
 ${rings.map(([id,n,rx])=>`<ellipse class="greg u${unrestOf(id)} ${GAL.reg===id?'on':''}" data-reg="${id}" cx="${cx}" cy="${cy}" rx="${rx}" ry="${Math.round(rx*GAL_C.ry)}"><title>${n} · Unrest ${unrestOf(id)} (${UNREST_WORD[unrestOf(id)]})</title></ellipse>`).join('')}
 <ellipse cx="${cx}" cy="${cy}" rx="46" ry="28" fill="url(#gcore)" pointer-events="none"/>
 ${rings.map(([id,n,rx])=>`<text class="glab" x="${cx}" y="${cy-Math.round(rx*GAL_C.ry)+11}">${n}</text>`).join('')}<text class="glab" x="36" y="370">Unknown</text>
 ${Object.entries(PLANETS).filter(([n])=>!/Rim|Way/.test(n)).map(([n,p])=>`<circle class="gpl" cx="${p.x}" cy="${p.y}" r="2.2"/>${at[n]?'':`<text class="gpn" x="${p.x+5}" y="${p.y-4}">${n}</text>`}`).join('')}
 ${it.filter(x=>!x.o).map(pinSVG).join('')}${it.filter(x=>x.o).map(pinSVG).join('')}
 </svg>`;
 const chips=it.map(x=>`<button type="button" class="gchip ${x.key===GAL.sel?'on':''} ${x.o?'':'op'}" data-pin="${x.key}" style="--pc:${PIN[x.cat].c}"><i></i><span>${x.n}<small>${chipMeta(x)}</small></span></button>`).join('');
 const legend=[['story','Story'],['crisis','Crisis'],['rescue','Rescue'],['quest','Personal'],['redeem','Redemption'],['field','Field op'],['sith','Sith op']].filter(([k])=>it.some(x=>x.cat===k))
  .map(([k,n])=>`<span style="--pc:${PIN[k].c}"><i></i>${n}</span>`).join('');
 return `<section class="galaxy"><h3>Galaxy · choose the next mission <small>${it.filter(x=>x.o).length} missions · ${it.filter(x=>x.f&&x.f.st==='open').length} field ops</small></h3>
 ${typeof twinBanner==='function'?twinBanner():''}<div class="gwrap"><div class="gleft">${svg}<div class="glegend">${legend}${C.options.filter(y=>y.adv).length>1||C.ops.list.some(o=>o.st==='open')?`<span><i style="background:var(--sith);width:6px;height:6px"></i>expires if you pick another</span>`:''}<span class="muted">Click a pin or a region.</span></div><div class="gchips">${chips}</div></div>
 <aside class="gpanel">${GAL.reg?regionPanel(GAL.reg,it):panelFor(it.find(x=>x.key===GAL.sel))}${fieldLogHTML()}</aside></div></section>`}
function regionPanel(id,it){const R=REGIONS.find(r=>r[0]===id),here=it.filter(x=>(PLANETS[x.planet]||{}).reg===id);
 const u=unrestOf(id);return `<div class="eyebrow">Region</div><h3 class="gtitle">${R[1]}</h3><p>${R[3]}</p><div class="gfacts"><span>Unrest</span><b class="${u>=UNREST.hostile?'bad':''}">${'▮'.repeat(u)}${'▯'.repeat(UNREST.max-u)} ${u} · ${UNREST_WORD[u]}</b><span>Effects</span><b>${u>=UNREST.favorAt?`Senate Favor ${UNREST.favor}/month · `:''}${u>=UNREST.hostile?`enemies +${UNREST.aimAt3} aim, field ops ${UNREST.fieldAt3}% here`:'none yet'}</b><span>Raised by</span><b>ignored crises, lost missions, Sith op hits, lapsed field ops</b><span>Lowered by</span><b>winning missions and field ops here</b></div>
 ${here.length?`<div class="gchips col">${here.map(x=>`<button type="button" class="gchip" data-pin="${x.key}" style="--pc:${PIN[x.cat].c}"><i></i>${x.n}<small>${x.planet}</small></button>`).join('')}</div>`:'<p class="muted">Nothing needs the Order here right now.</p>'}
 <button type="button" data-reg="none">Back to the briefing</button>`}
function panelFor(x){if(!x)return '<p class="muted">The galaxy is quiet.</p>';if(x.f)return fieldPanel(x.f);if(x.s)return sithPanel(x.s,x.planet);
 const {o,M,i}=x,P=PLANETS[x.planet]||{},seeRw=C.wings.comms||o.story,rk=riskOf(M,o.mission,o),sib=C.options.filter(y=>y.adv).length>1;
 const reward=seeRw?(fmtRes(M.reward)||'none')+(M.bonus?` · bonus ${fmtRes(M.bonus)} (${M.bonusTxt})`:''):'Unknown · build the Comms Hub to see';
 const goal=M.type==='defend'?`Hold for ${M.turns} turns`:M.type==='rescue'?'Free the prisoner and reach evac':M.type==='investigate'?'Scan the terminals and extract':M.type==='sabotage'?'Plant the charges and extract':M.type==='escort'?'Get the VIP to evac':'Take down the target';
 return `<div class="eyebrow">${o.story?'Story mission':o.kind||'Mission'} · ${M.where}${P.reg?` · ${REG_N[P.reg]}`:''}</div><h3 class="gtitle">${x.n}</h3>
 ${M.quote&&o.story?`<blockquote class="mq">${M.quote}</blockquote>`:''}<p>${o.text||M.brief}</p>${o.text&&M.brief&&o.text!==M.brief?`<p class="muted">${M.brief}</p>`:''}
 <div class="gfacts"><span>Goal</span><b>${goal}${M.par?` · par ${M.par} turns`:''}</b>
 <span>Risk</span><b class="risk r${rk.lv}" title="Enemy strength ${rk.p} vs squad Power ${rk.sp}">${'▮'.repeat(rk.lv)}${'▯'.repeat(4-rk.lv)} ${rk.n}${rk.vs?` <small class="muted">vs your best ${rk.vs} (Power ${rk.sp})</small>`:' <small class="muted">enemy strength</small>'}</b>
 <span>Expected</span><b>${foeCounts(M)||'Unknown'}${M.stealth?' · you start hidden':''}${o.fewer?` · front B: ${o.fewer} fewer rank-and-file`:''}</b>
 <span>Reward</span><b>${o.quest?'mission pay · ':''}${reward}</b>${o.questTxt?`<span>${o.redeem?'Redemption':'Quest'}</span><b class="up">${o.questTxt}</b>`:''}
 <span>Deadline</span><b>${expiryTxt(x)}</b>${P.reg?`<span>Region</span><b class="${unrestOf(P.reg)>=UNREST.hostile?'bad':''}">Unrest ${unrestOf(P.reg)} · ${UNREST_WORD[unrestOf(P.reg)]}${unrestOf(P.reg)>=UNREST.hostile?` · enemies +${UNREST.aimAt3} aim`:''}${o.adv&&sib?' · ignoring adds +1':''}</b>`:''}${o.adv&&sib?`<span>If ignored</span><b class="bad">${o.ignore&&o.ignore.lose?'they are lost':fmtRes(o.ignore)||'nothing'}</b>`:''}
 ${o.src?`<span>Asked by</span><b>${o.src}</b>`:''}${o.quest?`<span>Must deploy</span><b>${unit(o.quest).n}</b>`:''}</div>
 <button type="button" class="primary" data-act="squad:${i}">Choose squad${typeof twinB==='function'&&twinB()?` · front B (${TWIN.bMax})`:''}</button>${typeof twinButtons==='function'?twinButtons(i,o):''}`}
// Returns true when it handled the click (then the hub re-renders).
function galaxyClick(ev){if(typeof twinClick==='function'&&twinClick(ev))return true;const p=ev.target.closest('[data-pin]'),r=ev.target.closest('[data-reg]'),b=ev.target.closest('[data-act^="fop:"],[data-act^="fsend:"]');
 if(b&&!b.disabled){const [a,x]=b.dataset.act.split(':');fieldClick(a,x);baseScreen();return true}
 if(p){GAL.sel=p.dataset.pin;GAL.reg=null;FTEAM=[];baseScreen();return true}
 if(r){GAL.reg=r.dataset.reg==='none'||GAL.reg===r.dataset.reg?null:r.dataset.reg;baseScreen();return true}return false}
document.addEventListener('keydown',ev=>{if((ev.key==='Enter'||ev.key===' ')&&ev.target.closest&&ev.target.closest('g[data-pin]')){ev.preventDefault();ev.target.dispatchEvent(new MouseEvent('click',{bubbles:true}))}});

// ── Region Unrest (state C.unrest={era,r:{region:n}}). Hooks wrap ignoreCrisis, templeAfterMission, opHits, templeMonth, startMission. ──
const regionOf=where=>{const p=planetOf(where);return p?PLANETS[p].reg:null};
function unrestOf(reg){if(!C)return 0;if(!C.unrest||C.unrest.era!==(C.era||1))C.unrest={era:C.era||1,r:{}};return C.unrest.r[reg]||0}
function addUnrest(reg,n,why){if(!reg||!n||!C)return;const b=unrestOf(reg),a=Math.max(0,Math.min(UNREST.max,b+n));C.unrest.r[reg]=a;
 if(a!==b&&why)C.news.push(`${REG_N[reg]} ${a>b?'grows':'grows calmer'}: Unrest ${a} (${UNREST_WORD[a]}) · ${why}.`)}
const _ignoreCrisisG=ignoreCrisis;ignoreCrisis=function(x){_ignoreCrisisG(x);const M=MISSIONS[x.mission];if(M)addUnrest(regionOf(M.where),UNREST.ignore,`ignored ${x.n||M.n}`)};
const _templeAfterG=templeAfterMission;templeAfterMission=function(dep,win,o,out){_templeAfterG(dep,win,o,out);const M=S&&S.M;if(M)addUnrest(regionOf(M.where),win?UNREST.win:UNREST.lose,win?`won ${M.n}`:`lost ${M.n}`)};
// Sith ops land in a region: a stable spot per op id.
const opPlanet=o=>{const L=FIELD_PLANETS[C.era||1]||FIELD_PLANETS[1];let h=0;for(const ch of o.id)h=h*31+ch.charCodeAt(0)|0;return L[Math.abs(h)%L.length]};
const _opHitsG=opHits;opHits=function(o){_opHitsG(o);addUnrest(PLANETS[opPlanet(o)].reg,UNREST.opHit,`Sith op ${SITH_OPS[o.k].n}`)};
const _templeMonthG=templeMonth;templeMonth=function(){_templeMonthG();unrestOf('core');
 const hot=Object.entries(C.unrest.r).filter(([,n])=>n>=UNREST.favorAt);if(hot.length){gain('favor',UNREST.favor*hot.length);C.news.push(`<span class="bad">Unrest in ${hot.map(([k])=>REG_N[k]).join(', ')}: the Senate blames the Order.</span> Senate Favor ${UNREST.favor*hot.length}.`)}};
const _startMissionG=startMission;startMission=function(id,sq,o){_startMissionG(id,sq,o);if(!C||!S)return;const reg=regionOf(S.M.where);
 if(unrestOf(reg)>=UNREST.hostile){for(const u of S.units)if(u.side==='e')u.aim+=UNREST.aimAt3;S.unrestAim=UNREST.aimAt3;log(`${REG_N[reg]} is ${UNREST_WORD[unrestOf(reg)].toLowerCase()}: the locals help the enemy (+${UNREST.aimAt3} enemy aim).`,'dark')}};
function sithPanel(o,planet){const D=SITH_OPS[o.k],P=PLANETS[planet]||{},T=(o.team||[]).map(unit).filter(Boolean),fitU=C.roster.filter(fit),sel=OPTEAM.map(unit).filter(Boolean),
 ch=Math.min(OPS.max,OPS.teamBase+OPS.perRank*sel.reduce((s,r)=>s+r.rank,0));
 return `<div class="eyebrow">Sith op · ${planet}${P.reg?` · ${REG_N[P.reg]}`:''}</div><h3 class="gtitle">${D.n}</h3><p>${D.desc}</p>
 <div class="gfacts"><span>Deadline</span><b>Hits at month end${P.reg?` · Unrest +${UNREST.opHit} in ${REG_N[P.reg]}`:''}</b><span>Counter</span><b>${opCost(o)} Intel now, or a 2-unit team (resolves after the next mission)</b></div>
 ${o.st==='team'?`<p class="muted">Team: ${T.map(r=>r.n).join(' & ')}.</p>`:`<div class="picks">${fitU.map(r=>`<button type="button" class="${OPTEAM.includes(r.id)?'on':''}" data-act="opt:${r.id}">${r.n} R${r.rank}</button>`).join('')}</div>
 <div style="display:flex;gap:6px;flex-wrap:wrap"><button type="button" data-act="opi:${o.id}" ${C.res.intel<opCost(o)?'disabled':''}>Spend ${opCost(o)} Intel</button><button type="button" class="primary" data-act="opteam:${o.id}" ${OPTEAM.length!==2?'disabled':''}>Send team · ${ch}%</button></div>`}`}

// One pin: a stalk, a head sized by importance (story > crisis > ops), the type icon, an urgency dot, and a haloed label.
function pinSVG(x){const P=PIN[x.cat],on=x.key===GAL.sel,big=x.o&&x.o.story,op=!x.o,r=(big?12:op?7.5:10)+(on?2:0),hy=x.y-(op?16:22),
 urgent=(x.o&&x.o.adv&&C.options.filter(y=>y.adv).length>1)||(x.s&&x.s.st==='open'),lab=pinLabel(x.n),left=x.x>470,lx=left?x.x-r-4:x.x+r+4;
 return `<g class="gpin ${on?'on':''} ${op?'op':''} ${big?'big':''} ${x.f&&x.f.st==='team'||x.s&&x.s.st==='team'?'away':''}" data-pin="${x.key}" tabindex="0" role="button" aria-label="${x.n}, ${x.planet}" style="--pc:${P.c}">
 <line x1="${x.x}" y1="${x.y}" x2="${x.x}" y2="${hy+r}"/><circle class="gpd" cx="${x.x}" cy="${x.y}" r="1.8"/>${big?`<circle class="ring" cx="${x.x}" cy="${hy}" r="${r+3.5}"/>`:''}
 ${x.s?`<rect class="head" x="${x.x-r*.8}" y="${hy-r*.8}" width="${r*1.6}" height="${r*1.6}" transform="rotate(45 ${x.x} ${hy})"/>`:`<circle class="head" cx="${x.x}" cy="${hy}" r="${r}"/>`}<use href="#i-${x.ic}" x="${x.x-r*.62}" y="${hy-r*.62}" width="${r*1.24}" height="${r*1.24}"/>
 ${urgent?`<circle class="urg" cx="${x.x+r*.75}" cy="${hy-r*.75}" r="3"><title>Expires if you pick another</title></circle>`:''}
 ${!op||on?`<text class="gpl2" x="${lx}" y="${hy+3.5}" text-anchor="${left?'end':'start'}">${lab}</text>`:''}<title>${x.n} · ${x.planet}</title></g>`}
const pinLabel=n=>{n=String(n).replace(/ · .*/,'');return n.length>20?n.slice(0,19)+'…':n};
function chipMeta(x){if(x.o){const rk=riskOf(x.M,x.o.mission,x.o);return `${x.planet} · ${x.o.story?'Story':x.o.kind||'Mission'} · ${rk.n} risk`}
 if(x.f)return `${x.planet} · Field op · ${x.f.st==='team'?`team back in ${x.f.left}d`:`${FIELD_OPS[x.f.k].days}d away`}`;
 return `${x.planet} · Sith op · ${x.s.st==='team'?'team out':'hits at month end'}`}

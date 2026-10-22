/* Descriptions, tooltips and the Codex (Chat U).
   describe(kind,id) → {name,desc,lore,ic}. desc = owner's one-line `desc` field (fallbacks below); lore = CODEX[kind][id].lore (Chat L).
   Any element with data-tip="kind:id" gets a hover tooltip (long-press on touch). codexSee(kind,id) unlocks a Codex entry. */
const KINDS=[['ability','Abilities'],['enemy','Enemies'],['class','Classes'],['status','Status'],['tile','Terrain'],['gear','Gear'],['wing','Temple'],['research','Research'],['mission','Missions'],['planet','Planets'],['character','Characters']];
// Global lookup that also sees `const` tables from other scripts (they aren't on window).
const uiGv=n=>{try{return Function(`return typeof ${n}!=='undefined'?${n}:null`)()}catch{return null}};
// Fallback text for things no data table describes yet. Owners' `desc` fields win.
const STATUS_INFO={down:['Down','Out of the fight and bleeding out. An adjacent ally can Stabilize; a medkit revives.'],stunned:['Stunned','Loses its next turn.'],
 surrender:['Surrendered','Gave up. Subdue it to take a prisoner.'],captured:['Captured','Bound and out of the fight.'],guard:['Guard','Deflects more bolts and strikes enemies who come close, until its next turn.'],
 overwatch:['Overwatch','Fires at the first enemy that moves in range.'],hunker:['Hunkered down','+30 defense and immune to flanking crits until its next turn.'],
 barrier:['Force Barrier','Counts as full cover from every side until the caster\'s next turn.'],suppress:['Suppressed','−30 aim; moving gives the suppressor a free shot.'],
 mark:['Marked','Allies get +15 aim against it.'],scan:['Carrying data','Get this unit to an evac zone to extract the data.'],disarmed:['Disarmed','Can\'t shoot next turn; can still move and melee.'],
 concealed:['Concealed','Unseen by the enemy until it attacks or is spotted.'],graze:['Graze','A shot that just misses still clips the target for half damage. The band is 10% above the hit chance.'],tired:['Tired','Fought the last two missions back to back: −10 aim. Sit out one mission to recover.'],panic:['Panicked','Lost its nerve: may freeze, flee or fire wildly.'],darkness:['Darkness','Dark-side pull. High Darkness adds damage and risks a fall.']};
const STAT_INFO={aim:['Aim','Base chance to hit before cover, range and other modifiers.'],move:['Move','Tiles per move action. Two moves (a dash) cover double.'],
 damage:['Damage','Damage range on a hit. Armor removes some; minimum 1.'],range:['Range','Max shooting distance. Hit chance drops past 60% of it.'],
 deflect:['Deflect','Chance a Jedi blocks a blaster bolt.'],crit:['Crit','Chance a hit deals +2 damage. Flanking adds more.'],padawan:['Padawan','Within 3 tiles of their Master: +10 aim. A Padawan kill gives the Master +1 Focus.'],armor:['Armor','Each pip cuts one hit by 1, then breaks. Shredder strips an extra pip. Restored after every mission.'],medkits:['Medkits','Heals or revives an adjacent ally.'],
 grenades:['Grenades','3×3 blast; breaks half cover.'],hp:['HP','Health. At 0 a unit goes down and starts to bleed out.'],actions:['Actions','Two per turn. Moves cost 1; most attacks end the turn.'],
 focus:['Focus','Fuel for Force powers. Meditate to regain it.'],will:['Will','Resistance to panic from deaths, horrors and heavy damage.'],stress:['Stress','Builds over missions; high stress lowers will.'],threat:['Threat','Rises each turn past par. At 6 the mission fails.']};
const MOD_INFO={'Aim':'The shooter\'s base aim.','Half cover':'Target behind half cover: −20.','Full cover':'Target behind full cover: −40.','Range':'Past 60% of weapon range, aim drops 3 per tile.',
 'Close quarters':'Melee bonus.','Smoke':'Target in smoke.','Exposed target':'Snipers punish targets with no cover.','Hunkered down':'Target is hunkered.','Defensive Line':'A Guardian beside the target shields it.',
 'Helpless':'Stunned or surrendered target.','Suppressed':'The shooter is pinned by suppressing fire.','Battle Meditation':'A Consular\'s meditation steadies allies and shakes foes.',
 'Marked':'A Scout marked this target.','Bond':'Fighting near a bonded partner.','Ability bonus':'Bonus from the ability used.','Ability penalty':'Penalty from the ability used.',
 'Height':'Shooting down from higher ground.','High ground':'+15 when shooting down at a lower target.','Cover seen from above':'Shooting down past cover: it protects less (up to +10).',
 'Executioner':'+25 against targets at half HP or less.','Boosted':'An ally\'s buff raises this unit\'s aim.','Target shielded':'A buff on the target makes it harder to hit.',
 'Sith Lord nearby':'A Sith Lord within 4 tiles drives nearby Sith to shoot straighter.','Vs':'Trained against this kind of foe.','Beast lore':'Knows how beasts fight.','Fear of horrors':'A scar: this unit fears horrors.','Flank':'Target has no cover against this angle.','Ambush':'First shot from concealment.','Will':'Shaken nerves.'};
function loreOf(kind,id){const C=uiGv('CODEX');return C&&C[kind]&&C[kind][id]&&C[kind][id].lore||''}
function gearItem(id){for(const n of ['GEAR','ARMOR','MODS','AMODS','SMODS','UTIL','UTILITY','STANCES','FORMS','CRYSTAL_FX','SABER_TRAITS','TRAITS','PERKS','SCARS']){const t=uiGv(n);if(t&&!Array.isArray(t)&&t[id]&&typeof t[id]==='object')return t[id]}
 for(const n of ['WEAPONS','SABERS']){const t=uiGv(n);if(Array.isArray(t)){const i=t.find((w,ix)=>w.id===id||String(ix)===String(id)||w.n===id);if(i)return i}}return null}
function foeAuto(f){return [`HP ${f.hp} · Aim ${f.aim} · Move ${f.mob} · Damage ${f.dmg[0]}–${f.dmg[1]} · Range ${f.range<2?'melee':f.range}`,f.armor?`Armor ${f.armor}.`:'',f.horror||f.forceOnly?'Hurts only Force users; troops are immune.':'',f.hid?'Starts hidden.':''].filter(Boolean).join(' ')}
function describe(kind,id){let name=id,desc='',ic=null,t;
 if(kind==='ability'&&(t=uiGv('AB'))&&t[id]){name=t[id].name;desc=t[id].desc||t[id].tip||'';ic=t[id].ic}
 else if(kind==='enemy'&&(t=uiGv('FOES'))&&t[id]){name=t[id].n.replace(/ \d+$/,'');desc=t[id].desc||foeAuto(t[id]);ic=t[id].ic}
 else if(kind==='tile'&&(t=uiGv('TILES'))&&t[id]){const c=t[id];name=c.n;desc=c.desc||[c.cover===2?'Full cover.':c.cover?'Half cover.':'',c.walk?'':'Blocks movement.',c.elev?`Raised ${c.elev}: +aim from above.`:'',c.breaks?'Explosions break it down.':''].filter(Boolean).join(' ')||'Open ground.'}
 else if(kind==='class'&&(t=uiGv('CLASS'))&&t[id]){name=id;desc=t[id].desc||`${t[id].jedi?'Jedi':'Trooper'} · HP ${t[id].hp} · Aim ${t[id].aim} · Move ${t[id].mob}`;ic=id.toLowerCase()}
 else if(kind==='wing'&&(t=uiGv('WINGS'))&&t[id]){name=t[id].n;desc=t[id].desc||(t[id].eff&&t[id].eff[1])||''}
 else if(kind==='research'&&(t=uiGv('RESEARCH'))&&t[id]){name=t[id].n||t[id].name||id;desc=t[id].desc||''}
 else if(kind==='mission'&&(t=uiGv('MISSIONS'))&&t[id]){name=t[id].n;desc=t[id].desc||t[id].where||''}
 else if(kind==='gear'&&(t=gearItem(id))){name=t.n||t.name||id;desc=t.desc||t.tip||''}
 else if(kind==='status'){t=uiGv('STATUS');const s=t&&t[id];name=s&&s.n||(STATUS_INFO[id]||[id])[0];desc=s&&s.desc||(STATUS_INFO[id]||[])[1]||'';ic=id}
 else if(kind==='stat'){[name,desc]=STAT_INFO[id]||[id,'']}
 else if(kind==='mod'){name=id;desc=MOD_INFO[id]||MOD_INFO[id.replace(/ .*/,'')]||''}
 const C=uiGv('CODEX'),cx=C&&C[kind]&&C[kind][id];if(cx&&cx.n)name=cx.n;if(cx&&!desc&&cx.desc)desc=cx.desc;
 return {name,desc,lore:loreOf(kind,id),ic}}
// --- What the player has met (per browser) ---
const CX_KEY='tw.codex';let CX_SEEN=(()=>{try{return JSON.parse(localStorage.getItem(CX_KEY))||{}}catch{return {}}})(),cxDirty=0;
function codexSee(kind,id){if(id==null||kind==='stat'||kind==='mod')return;const k=CX_SEEN[kind]||(CX_SEEN[kind]={});if(k[id])return;k[id]=Date.now();
 if(!cxDirty){cxDirty=1;setTimeout(()=>{cxDirty=0;try{localStorage.setItem(CX_KEY,JSON.stringify(CX_SEEN))}catch{}},400)}}
// Called from render(): everything on the board counts as met.
function codexScan(){if(!S)return;codexSee('mission',S.id);
 for(const row of S.grid)for(const c of row)if(c!=='.')codexSee('tile',c);
 for(const u of S.units){if(u.hid)continue;if(u.side==='e')codexSee('enemy',u.type);else{if(u.cls&&!u.vip)codexSee('class',u.cls);for(const k of u.abil||[])codexSee('ability',k)}
  const b=badge(u);if(b)codexSee('status',b);if(u.status==='down')codexSee('status','down')}}
function codexIds(kind){const src={ability:'AB',enemy:'FOES',class:'CLASS',tile:'TILES',wing:'WINGS',research:'RESEARCH',mission:'MISSIONS'}[kind];
 let ids=src&&uiGv(src)?Object.keys(uiGv(src)):[];
 if(kind==='status')ids=Object.keys({...STATUS_INFO,...(uiGv('STATUS')||{})});
 if(kind==='gear')for(const n of ['GEAR','ARMOR','MODS','AMODS','SMODS','UTIL','UTILITY','STANCES','FORMS']){const t=uiGv(n);if(t&&!Array.isArray(t))ids.push(...Object.keys(t).filter(k=>k!=='none'))}
 if(kind==='tile')ids=ids.filter(c=>c!=='.');
 const C=uiGv('CODEX');if(C&&C[kind])for(const k of Object.keys(C[kind]))if(!ids.includes(k))ids.push(k);
 return [...new Set(ids)]}
let CX_TAB='ability';
function codexOpen(tab){if(tab)CX_TAB=tab;
 // Squad and Temple count as met even before a mission.
 const Cg=uiGv('C');if(Cg){for(const r of Cg.roster||[])if(r.cls)codexSee('class',r.cls);const wl=Cg.wings||{};for(const k in wl)if((wl[k]&&wl[k].lvl!=null?wl[k].lvl:wl[k])>0)codexSee('wing',k)}
 const o=uiLayer('codex'),ids=codexIds(CX_TAB),seen=CX_SEEN[CX_TAB]||{},met=ids.filter(i=>seen[i]);
 o.innerHTML=`<div class="ui-card wide" role="dialog" aria-label="Codex"><div class="ui-head"><h2>Codex</h2><span class="muted small">${Object.values(CX_SEEN).reduce((s,k)=>s+Object.keys(k).length,0)} entries found</span><button type="button" data-ui="close" aria-label="Close">✕</button></div>
 <div class="cxtabs" role="tablist">${KINDS.map(([k,n])=>{const a=codexIds(k),m=a.filter(i=>(CX_SEEN[k]||{})[i]).length;return a.length?`<button type="button" role="tab" data-cx="${k}" class="${k===CX_TAB?'on':''}">${n} <small>${m}/${a.length}</small></button>`:''}).join('')}</div>
 <div class="cxlist">${met.length?met.map(i=>{const d=describe(CX_TAB,i);return `<article class="cxe">${d.ic&&ICONS[d.ic]?icon(d.ic):''}<div><b>${d.name}</b>${d.desc?`<p>${d.desc}</p>`:''}${d.lore?`<p class="lore">${d.lore}</p>`:''}</div></article>`}).join(''):'<p class="muted">Nothing here yet. Entries appear as you meet them.</p>'}
 ${ids.length>met.length?`<p class="muted small">${ids.length-met.length} still unknown.</p>`:''}</div></div>`;
 o.querySelector('.cxtabs').addEventListener('click',ev=>{const b=ev.target.closest('[data-cx]');if(b){ev.stopPropagation();codexOpen(b.dataset.cx)}})}
// --- Tooltips: hover (mouse) or long-press (touch) on any [data-tip="kind:id"] ---
const UI_TIP=(()=>{const d=document.createElement('div');d.id='tip';d.className='tip';d.hidden=true;d.setAttribute('role','tooltip');document.body.appendChild(d);return d})();
let tipT=0,tipEl=null,tipTouch=0;
function tipShow(el,x,y){const [kind,...r]=el.dataset.tip.split(':'),id=r.join(':'),d=describe(kind,id);if(!d.desc&&!d.lore)return;codexSee(kind,id);
 UI_TIP.innerHTML=`<b>${d.name}</b>${d.desc?`<span>${d.desc}</span>`:''}${d.lore?`<i>${d.lore}</i>`:''}`;UI_TIP.hidden=false;
 const w=UI_TIP.offsetWidth,h=UI_TIP.offsetHeight,vw=innerWidth,vh=innerHeight;let L=x+14,T=y+16;if(L+w>vw-8)L=Math.max(8,x-w-14);if(T+h>vh-8)T=Math.max(8,y-h-12);UI_TIP.style.left=L+'px';UI_TIP.style.top=T+'px'}
function tipHide(){clearTimeout(tipT);tipEl=null;UI_TIP.hidden=true}
document.addEventListener('mouseover',ev=>{if(tipTouch)return;const el=ev.target.closest&&ev.target.closest('[data-tip]');if(el===tipEl)return;tipHide();if(!el)return;tipEl=el;
 const delay=el.closest('#board')?700:350,{clientX:x,clientY:y}=ev;tipT=setTimeout(()=>tipShow(el,x,y),delay)});
document.addEventListener('mousemove',ev=>{if(!UI_TIP.hidden&&tipEl){UI_TIP.style.left=Math.min(ev.clientX+14,innerWidth-UI_TIP.offsetWidth-8)+'px';UI_TIP.style.top=Math.min(ev.clientY+16,innerHeight-UI_TIP.offsetHeight-8)+'px'}},{passive:true});
document.addEventListener('pointerdown',ev=>{if(ev.pointerType!=='touch'){tipHide();return}tipTouch=1;tipHide();const el=ev.target.closest('[data-tip]');if(!el)return;
 tipT=setTimeout(()=>{tipShow(el,ev.clientX,ev.clientY);el.dataset.tipped='1'},450)});
document.addEventListener('pointerup',ev=>{if(ev.pointerType==='touch')clearTimeout(tipT)});
// A long-press that opened a tooltip shouldn't also click the button.
document.addEventListener('click',ev=>{const el=ev.target.closest&&ev.target.closest('[data-tipped]');if(el){delete el.dataset.tipped;ev.stopPropagation();ev.preventDefault();setTimeout(tipHide,1800)}},true);
addEventListener('scroll',tipHide,{passive:true});
// Base/Temple screens: anything they mark with data-tip also counts as met once shown.
new MutationObserver(()=>{try{for(const el of document.querySelectorAll('#modal [data-tip]')){const [k,...r]=el.dataset.tip.split(':');codexSee(k,r.join(":"))}}catch{}}).observe(document.getElementById('modal'),{childList:true,subtree:true});

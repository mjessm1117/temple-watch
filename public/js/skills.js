/* Skills overhaul (Chat Q, wave 5): skill points, buying extra skills, bonds panel + bond techniques in the skill tree.
   Data: data-skills.js (SKILL, BOND_TECH, third options). Effects in battle: power.js. Loads after legacy.js.
   State: r.sp (unspent), r.spXp (XP points already paid), r.spVet (veteran ranks already paid), r.extra (bought skill ids); C.bonds[k].tech.
   Wraps: promote, ensureLegacy, nodeState, nodeHTML, unlockChips, treeScreen, treeClick, recordHTML, startMission. */

// Rank a tree node sits at for this unit (trunk 1–2, own spec 3–7), or 0.
function nodeRank(r,k){const T=TREES[r.cls];if(!T)return 0;for(const n of [1,2])if(T.trunk[n].includes(k))return n;
 const s=specOf(r);if(s){if(s.sig===k)return 3;for(const n of [4,5,6,7])if((s[n]||[]).includes(k))return n}return 0}
// Buyable: an option at a rank whose pick you've already made, not owned yet.
function canBuy(r,k){const n=nodeRank(r,k);return !!n&&n!==3&&n<=r.picks.length&&!r.picks.includes(k)&&!(r.extra||[]).includes(k)&&(r.sp||0)>0}
function fixExtra(r){r.extra=(r.extra||[]).filter((k,i,a)=>a.indexOf(k)===i&&nodeRank(r,k)&&nodeRank(r,k)<=r.picks.length&&!r.picks.includes(k))}
// Pay out skill points owed: start bonus, one per SKILL.xpPer XP, one per veteran rank (8+).
function spSync(r){if(!r||!TREES[r.cls])return 0;let g=0;
 if(r.sp==null){r.sp=SKILL.start;r.spXp=0;r.spVet=0;g+=SKILL.start}
 const x=Math.floor((r.xp||0)/SKILL.xpPer);if(x>(r.spXp||0)){g+=x-(r.spXp||0);r.sp+=x-(r.spXp||0);r.spXp=x}
 const v=Math.max(0,r.rank-7);if(v>(r.spVet||0)){g+=(v-(r.spVet||0))*SKILL.vet;r.sp+=(v-(r.spVet||0))*SKILL.vet;r.spVet=v}return g}
function buySkill(id,k){const r=unit(id);if(!r||!canBuy(r,k))return;r.sp--;r.extra=[...(r.extra||[]),k];
 if(typeof lifeLog==='function')lifeLog(r,`Learned ${pickInfo(k).name} (skill point)`);saveGame()}
const _promoteS=promote;
promote=function(r){const up=_promoteS(r);const g=spSync(r);if(g&&C&&C.news&&r.sp)C.news.push(`${r.n}: +${g} skill point${g>1?'s':''} (${r.sp} to spend in the Skill tree).`);return up};
const _ensureLegS=ensureLegacy;
ensureLegacy=function(){_ensureLegS();if(C)for(const r of C.roster)spSync(r)};

// --- skill tree screen ---
const _nodeStateS=nodeState;
nodeState=function(r,rk,k,sid){if((r.extra||[]).includes(k))return 'taken';const s=_nodeStateS(r,rk,k,sid);return (s==='skip'||s==='lock')&&canBuy(r,k)?'buy':s};
const _nodeHTMLS=nodeHTML;
nodeHTML=function(r,rk,k,sid){const h=_nodeHTMLS(r,rk,k,sid);return nodeState(r,rk,k,sid)==='buy'?h.replace('aria-disabled="true"',`data-act="tbuy:${r.id}:${k}" title="Spend 1 skill point"`):h};
const _chipsS=unlockChips;
unlockChips=function(k){const P=PERKS[k];let h=_chipsS(k);if(!P)return h;
 for(const [f,v] of Object.entries(P.fx||{}))h+=`<i class="chip fx${/chain/i.test(f)?' chain':''}">${FX_N[f]||f}${v===1&&/lastStand|chain/i.test(f)?'':' '+(['dodge','ward'].includes(f)?'−':'+')+v}</i>`;
 for(const [g,v] of Object.entries(P.aimVs||{}))h+=`<i class="chip fx">+${v} aim vs ${g}</i>`;return h};
function treeBondsHTML(r){const L=Object.entries(C.bonds||{}).filter(([k])=>k.split('|').includes(r.id)).map(([k,v])=>({k,v,p:unit(k.split('|').find(x=>x!==r.id))}))
 .filter(x=>x.p&&x.p.status!=='dead').sort((a,b)=>b.v.lvl-a.v.lvl||b.v.n-a.v.n);
 return `<section class="tt-bonds"><h4>Bonds</h4><p class="muted">Fight beside someone to raise a bond. Every level: pick a drill you <b>both</b> keep. Bond ${SKILL.bond.join(' and ')}: +1 skill point each. Bond ${BOND_TECH_AT}: pick a pair technique (works when you deploy together). Bond ${BOND.max}: ${BOND_MAX_PERK.n}.</p>
 ${L.length?L.map(({k,v,p})=>{const nd=bondNeed(v.lvl),pct=v.lvl>=BOND.max?100:Math.round(100*(v.n||0)/nd),T=v.tech&&BOND_TECH[v.tech];
  return `<div class="bondrow"><div><b>${p.n}</b> · ${p.cls} · Bond <b>${v.lvl}</b>/${BOND.max} <small class="muted">${v.lvl>=BOND.max?BOND_MAX_PERK.desc:`${v.n||0}/${nd} to next`}</small><div class="bbar"><i style="width:${pct}%"></i></div>
  ${(v.dr||[]).length?`<small>Drills: ${v.dr.map(d=>`<b>${DRILLS[d].n}</b> (${DRILLS[d].desc})`).join(' · ')}</small>`:''}${T?`<br><small>Technique: <b>${T.n}</b> · ${T.desc}</small>`:''}</div>
  ${v.offer?`<div class="picks"><small>Pick a drill:</small> ${v.offer.map(d=>`<button type="button" data-act="drill:${k}:${d}">${DRILLS[d].n} · ${DRILLS[d].desc}</button>`).join('')}</div>`:''}
  ${v.lvl>=BOND_TECH_AT&&!v.tech?`<div class="picks"><small>Pick a technique (permanent):</small> ${Object.entries(BOND_TECH).map(([t,x])=>`<button type="button" data-act="btech:${k}:${t}">${x.n} · ${x.desc}</button>`).join('')}</div>`:''}</div>`}).join('')
 :'<p class="muted">No bonds yet. Deploy with the same people to build them.</p>'}</section>`}
const _treeScreenS=treeScreen;
treeScreen=function(id){_treeScreenS(id);const r=unit(id),box=document.querySelector('#modal .ttree');if(!r||!box)return;spSync(r);
 const hint=box.querySelector('.tt-hint');if(hint)hint.insertAdjacentHTML('afterend',`<p class="tt-sp"><b>${r.sp||0}</b> skill point${r.sp===1?'':'s'} · ${(r.sp||0)?'click a <span class="tk buy"></span> purple skill to learn it as well.':`next at ${(Math.floor((r.xp||0)/SKILL.xpPer)+1)*SKILL.xpPer} XP.`} <small class="muted">Earn: 1 per ${SKILL.xpPer} XP · ranks 8–10 · bond ${SKILL.bond.join('/')}. Buy any option at a rank you've picked.</small></p>`);
 box.insertAdjacentHTML('beforeend',treeBondsHTML(r))};
const _treeClickS=treeClick;
treeClick=function(ev){const b=ev.target.closest('[data-act]');if(b&&!b.disabled){const [a,x,y]=b.dataset.act.split(':');
 if(a==='tbuy'){buySkill(x,y);return treeScreen(x)}
 if(a==='drill'){pickDrill(x,y);return treeScreen(TREE_ID)}
 if(a==='btech'){const v=C.bonds[x];if(v&&v.lvl>=BOND_TECH_AT&&!v.tech&&BOND_TECH[y]){v.tech=y;saveGame()}return treeScreen(TREE_ID)}}
 return _treeClickS(ev)};
const _recordS=recordHTML;
recordHTML=function(r){spSync(r);return (r.sp?`<p class="tt-sp"><b>${r.sp}</b> skill point${r.sp>1?'s':''} to spend · open the Skill tree.</p>`:'')+_recordS(r)};
const _lifeClickS=lifeClick;
lifeClick=function(a,x,y){if(a==='btech'){const v=C.bonds[x];if(v&&v.lvl>=BOND_TECH_AT&&!v.tech&&BOND_TECH[y]){v.tech=y;saveGame()}return true}return _lifeClickS(a,x,y)};

// Bond techniques reach battle: partners deployed together get u.pairs=[{uid,t}] (power.js reads them).
const _startS=startMission;
startMission=function(id,sq,o){_startS(id,sq,o);if(!S||!C)return;const P=S.units.filter(u=>u.side==='p'&&u.rid);
 for(const u of P){u.pairs=[];for(const p of P){if(p===u)continue;const v=C.bonds[bkey(u.rid,p.rid)];if(v&&v.tech)u.pairs.push({uid:p.uid,t:v.tech})}}};

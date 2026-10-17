/* Skill tree screen (Chat F · Skill Trees). One unit's whole tree at a glance: trunk R1–2, fork into two specs (R3 sig → R7),
   cross-training below. Each node shows its icon, what it unlocks as chips (+2 HP, New ability · 2 Focus), and its state:
   taken (lit) · open (pick now) · locked (rank not reached) · skipped / closed (other branch). Open from Roster or Armory. */
const MOD_N={hp:'HP',aim:'Aim',dmg:'Damage',dmgHi:'Max dmg',armor:'Armor',crit:'Crit %',mob:'Move',maxF:'Focus',will:'Will',range:'Range',kits:'Medkit',nades:'Grenade',deflect:'Deflect',guardDef:'Guard'};
let TREE_CONF=null,TREE_ID=null;  // spec sig awaiting confirmation (rank 3 is permanent)
function unlockChips(k){const p=PERKS[k],a=AB[k];
 if(p&&p.mod)return Object.entries(p.mod).map(([s,v])=>`<i class="chip">${v>0?'+':''}${v} ${MOD_N[s]||s}</i>`).join('');
 if(a)return `<i class="chip new">${a.passive?'Passive':'New ability'}${a.f?` · ${a.f} Focus`:''}</i>`;return ''}
function nodeState(r,rk,k,sid){const P=r.picks;
 if(P[rk-1]===k)return 'taken';if(rk<=P.length)return 'skip';if(sid&&r.spec&&r.spec!==sid)return 'closed';
 return pendingRank(r)===rk&&treeOpts(r,rk).includes(k)?'open':'lock'}
function nodeHTML(r,rk,k,sid){const st=nodeState(r,rk,k,sid),a=pickInfo(k);
 return `<button type="button" class="tn ${st}${TREE_CONF===k?' conf':''}" ${st==='open'?`data-act="tpick:${r.id}:${k}"`:'aria-disabled="true"'} data-tip="${AB[k]?'ability':'gear'}:${k}">
 ${icon(a.ic||'guard')}<b>${a.name}${st==='taken'&&AB[k]?pwTag(skillPower(r,k)):''}</b><span class="chips">${unlockChips(k)}</span><small>${a.desc||a.tip||''}</small></button>`}
const rankCell=(r,rk,off)=>`<span class="tr ${rk>r.rank||off?'lock':''}">R${rk}<small>${off?'closed':rk>r.rank?RANKS[rk-1].xp+' XP':r.picks[rk-1]?'done':'pick'}</small></span>`;
function treeScreen(id){const r=unit(id);if(!r||!TREES[r.cls])return;TREE_ID=id;SCR=()=>treeScreen(id);const T=TREES[r.cls],m=$('#modal'),p=pendingRank(r),next=r.rank<RANKS.length?RANKS[r.rank].xp:null;
 m.hidden=false;const sigSpec=TREE_CONF&&Object.values(T.specs).find(s=>s.sig===TREE_CONF);
 m.innerHTML=`<div class="box wide ttree">
 <header class="tt-head"><span class="mini" style="--uc:${r.col||'var(--troop)'}">${icon(r.cls.toLowerCase())}</span><div><h2>${r.n}</h2>
  <small>${r.title?r.title+' · ':''}${r.cls}${specOf(r)?' · '+specOf(r).n:''} · Rank ${r.rank} · ${r.xp}${next?'/'+next:''} XP</small></div>
  <span class="pwr big">${icon('st_power')} ${unitPower(r)}</span><button type="button" data-act="tclose">Back to Temple</button></header>
 <p class="tt-hint">${p?`<b>Rank ${p} pick waiting:</b> click a glowing skill.`:'No pick waiting. Earn XP to unlock the next rank.'}
  <span class="tt-key"><i class="tk taken"></i>taken <i class="tk open"></i>pick now <i class="tk lock"></i>locked <i class="tk skip"></i>not taken</span></p>
 ${sigSpec?`<div class="tt-conf">Become a <b>${sigSpec.n}</b>? This is permanent: the other branch closes. <button type="button" class="primary" data-act="tconf:${r.id}">Confirm ${sigSpec.n}</button> <button type="button" data-act="tcancel">Cancel</button></div>`:''}
 <div class="tt-trunk"><h4>Core · ${r.cls}</h4>${[1,2].map(rk=>`<div class="tt-row">${rankCell(r,rk)}${T.trunk[rk].map(k=>nodeHTML(r,rk,k)).join('')}</div>`).join('')}</div>
 <div class="tt-fork">${Object.entries(T.specs).map(([id,s])=>`<section class="tt-spec ${r.spec===id?'on':r.spec?'off':''}">
  <h4>${icon(s.ic)} ${s.n}</h4><small>${s.desc}</small><p class="strait"><b>${SPEC_TRAITS[id].n}:</b> ${SPEC_TRAITS[id].desc}</p>
  ${[3,4,5,6,7].map(rk=>`<div class="tt-row">${rankCell(r,rk,r.spec&&r.spec!==id)}${(rk===3?[s.sig]:s[rk]).map(k=>nodeHTML(r,rk,k,id)).join('')}</div>`).join('')}</section>`).join('')}</div>
 ${xtrainHTML(r)}</div>`;
 m.onclick=treeClick}
function treeClick(ev){const b=ev.target.closest('[data-act]');if(!b||b.disabled||b.getAttribute('aria-disabled'))return;const [a,x,y]=b.dataset.act.split(':');
 if(a==='tclose'){TREE_CONF=null;return baseScreen()}
 if(a==='tcancel')TREE_CONF=null;
 else if(a==='tpick'){const r=unit(x);if(pendingRank(r)===3){TREE_CONF=y}else pickAbility(x,y)}
 else if(a==='tconf'){pickAbility(x,TREE_CONF);TREE_CONF=null}
 else if(a==='alt')setAlt(x,y);else if(a==='borrow')borrowSkill(x,y);
 treeScreen(TREE_ID)}

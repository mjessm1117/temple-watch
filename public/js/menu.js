/* Menu button (header, or M): rewind to the start of one of the last 3 turns, restart the mission, retreat,
   3 manual save slots, settings. Checkpoints wrap startMission/startPlayerTurn, so load this after every other wrapper. */
const CKKEY='templewatch-ck',SLOTKEY=n=>'templewatch-slot-'+n,CK_TURNS=3;
let CK=(()=>{try{return JSON.parse(localStorage.getItem(CKKEY)||'null')}catch(e){return null}})();
const ckSave=()=>{try{localStorage.setItem(CKKEY,JSON.stringify(CK))}catch(e){}};
const snap=()=>JSON.stringify(saveData());
// Mission start: a fresh nonce ties checkpoints to this run of the mission.
const _mnStart=startMission;
startMission=function(...a){const r=_mnStart.apply(this,a);if(S&&!S.over){S.nonce=Date.now();CK={nonce:S.nonce,start:snap(),turns:[]};ckSave()}return r};
const _mnSPT=startPlayerTurn;
startPlayerTurn=function(...a){const r=_mnSPT.apply(this,a);
 if(S&&!S.over&&S.phase==='player'&&CK&&CK.nonce===S.nonce){CK.turns=CK.turns.filter(c=>c.t<S.turn);CK.turns.push({t:S.turn,txt:snap()});CK.turns=CK.turns.slice(-CK_TURNS);ckSave()}
 return r};
const inBattle=()=>!!(S&&!S.over);
const ckOk=()=>inBattle()&&CK&&CK.nonce===S.nonce;
function restore(txt,msg){const d=JSON.parse(txt);$('#modal').hidden=true;continueGame(d);saveGame();if(msg)log(msg)}
const slotRead=n=>{try{return JSON.parse(localStorage.getItem(SLOTKEY(n))||'null')}catch(e){return null}};
const slotLabel=()=>inBattle()?`${S.M.n||S.id} · turn ${S.turn}`:'Temple';
const when=t=>new Date(t).toLocaleString([],{month:'short',day:'numeric',hour:'numeric',minute:'2-digit'});

function menuOpen(view){const m=$('#modal');m.hidden=false;const B=inBattle(),pl=B&&S.phase==='player';let h='';
 if(view==='confirm-retreat')h=`<h2 class="lose">Retreat?</h2><p>The squad pulls out. The mission counts as lost (normal penalties), but nobody is captured: downed troops are carried out wounded.</p>
  <div class="endrow"><button type="button" data-m="main">Cancel</button><button type="button" class="primary" data-m="retreat">Retreat</button></div>`;
 else if(view&&view.startsWith('confirm-load-'))h=`<h2>Load slot ${view.slice(-1)}?</h2><p>Anything since your last save is lost.</p>
  <div class="endrow"><button type="button" data-m="main">Cancel</button><button type="button" class="primary" data-m="load-${view.slice(-1)}">Load</button></div>`;
 else{const ck=ckOk()?CK.turns.filter(c=>c.t<=S.turn):[];
  h=`<div class="eyebrow">Menu</div><h2>${B?(S.M.n||'Mission')+' · Turn '+S.turn:'Temple Watch'}</h2>
  ${B?`<section class="mnu"><h3>Battle</h3>
   <div class="mrow">${ck.length?ck.map(c=>`<button type="button" data-m="rw-${c.t}" ${pl?'':'disabled'}>Back to start of turn ${c.t}</button>`).join(''):'<span class="muted">No turn checkpoints yet.</span>'}</div>
   <div class="mrow"><button type="button" data-m="restart" ${ckOk()&&pl?'':'disabled'}>Restart mission</button><button type="button" class="warn" data-m="ask-retreat" ${pl?'':'disabled'}>Retreat</button></div>
   ${pl?'':'<p class="muted">Wait for the enemy turn to finish.</p>'}</section>`:''}
  <section class="mnu"><h3>Save slots</h3>${[1,2,3].map(n=>{const s=slotRead(n);return`<div class="slot"><span><b>Slot ${n}</b> ${s?`${s.label} <span class="muted">· ${when(s.at)}</span>`:'<span class="muted">empty</span>'}</span>
   <button type="button" data-m="save-${n}" ${B&&!pl?'disabled':''}>Save</button><button type="button" data-m="ask-load-${n}" ${s?'':'disabled'}>Load</button></div>`}).join('')}</section>
  <div class="endrow"><button type="button" data-m="settings">Settings</button><button type="button" class="primary" data-m="close">Resume</button></div>`}
 m.innerHTML=`<div class="box menu">${h}</div>`;
 m.onclick=ev=>{const b=ev.target.closest('[data-m]');if(!b||b.disabled)return;const a=b.dataset.m;
  if(a==='close'){m.hidden=true;m.onclick=null}
  else if(a==='main')menuOpen();
  else if(a==='settings'){m.hidden=true;m.onclick=null;$('#setBtn').click()}
  else if(a.startsWith('rw-')){const c=CK.turns.find(c=>c.t===+a.slice(3));if(c){CK.turns=CK.turns.filter(x=>x.t<=c.t);ckSave();m.onclick=null;restore(c.txt,`Rewound to the start of turn ${c.t}.`)}}
  else if(a==='restart'){CK.turns=[];ckSave();m.onclick=null;restore(CK.start,'Mission restarted.')}
  else if(a==='ask-retreat')menuOpen('confirm-retreat');
  else if(a==='retreat'){m.hidden=true;m.onclick=null;retreat()}
  else if(a.startsWith('save-')){try{localStorage.setItem(SLOTKEY(a.slice(5)),JSON.stringify({at:Date.now(),label:slotLabel(),data:saveData()}))}catch(e){}menuOpen()}
  else if(a.startsWith('ask-load-'))menuOpen('confirm-load-'+a.slice(-1));
  else if(a.startsWith('load-')){const s=slotRead(a.slice(5));if(s){m.onclick=null;restore(JSON.stringify(s.data),`Loaded slot ${a.slice(5)}.`)}}}}
// Retreat: mission lost, squad safe. Downed units are carried out at 1 HP (wounded, not captured).
function retreat(){if(!inBattle()||S.phase!=='player')return;for(const u of players())if(u.status==='down'){u.status='ok';u.hp=1;u.bleed=0}
 S.retreated=1;finish(false,'The squad pulls back to the transport. The objective is lost, but everyone comes home.')}

(()=>{const row=document.querySelector('header .endrow');if(row&&!$('#menuBtn')){const b=document.createElement('button');b.type='button';b.id='menuBtn';b.title='Menu (M)';b.textContent='Menu';row.prepend(b);b.onclick=()=>menuOpen()}})();
document.addEventListener('keydown',ev=>{if(ev.ctrlKey||ev.metaKey||ev.altKey||/INPUT|TEXTAREA|SELECT/.test(ev.target.tagName))return;
 if(ev.key==='m'||ev.key==='M'){ev.preventDefault();const m=$('#modal');if(!m.hidden&&m.querySelector('.menu')){m.hidden=true;m.onclick=null}else if(m.hidden)menuOpen()}});

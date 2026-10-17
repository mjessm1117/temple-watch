/* Battle variety UI (Chat H, wave 4): twist + signature on the briefing, HUD rows, top-strip chip, comm box with decisions,
   board marks (shell zones, charge timers). Loads after battle.js. */
(function(){const st=document.getElementById('sConc');if(st&&!document.getElementById('sTwist'))st.insertAdjacentHTML('afterend','<span id="sTwist" class="twchip" hidden></span>');
 const bn=document.getElementById('banner');if(bn&&!document.getElementById('bvComm'))bn.insertAdjacentHTML('afterend','<div id="bvComm" class="bvcomm" aria-live="polite" hidden></div>')})();
function twCard(T,G,D){return `${D?`<div class="twcard side"><b>${icon('scan')} Side objective: ${D.n}</b><span>${D.desc} Reward on a win: ${fmtRes(D.res)}.</span></div>`:''}${T?`<div class="twcard"><b>${icon(T.ic)} Battle twist: ${T.n}</b><span>${T.desc}</span></div>`:''}${G?`<div class="twcard sig"><b>${icon('mark')} Signature objective: ${G.n}</b><span>${G.desc}</span></div>`:''}`}
// Briefing: the rolled twist (kept on the crisis option) and the story mission's signature objective.
const _bvSquad=squadScreen;squadScreen=function(i,keep){_bvSquad(i,keep);try{const o=C.options[i],M=MISSIONS[o.mission],box=document.querySelector('#modal .box');if(!box||box.querySelector('.twcard'))return;
 const p=[...box.querySelectorAll(':scope > p')].find(p=>!p.classList.contains('muted'))||box.querySelector('h2');p.insertAdjacentHTML('afterend',twCard(TWISTS[twistFor(o)],SIG[o.mission],SIDES[sideFor(o)]))}catch(e){}};
function bvHud(){const b=S.bv,T=TWISTS[b.tw],sg=sigStat(),rows=[];
 if(T)rows.push(`<div class="orow tw" title="${T.desc}"><span>${icon(T.ic)} ${T.n}</span><b>${T.hud}</b></div>`);
 if(sg)rows.push(`<div class="orow sig" title="${sg.desc}"><span>${icon('mark')} ${sg.n}</span><b>${sg.v}</b></div><p class="ocall">${sg.desc}</p>`);
 const sd=sideStat();if(sd)rows.push(`<div class="orow side${sd.v.includes('✗')?' hot':''}" title="${sd.desc}"><span>${icon('scan')} ${sd.n}</span><b>${sd.v}</b></div>`);
 if(b.locks&&!sg)rows.push(`<div class="orow"><span>Locks</span><b>${b.locks}</b></div>`);
 return rows.join('')}
function bvComm(){const el=document.getElementById('bvComm');if(!el)return;const b=S.bv,q=b&&b.q[0],c=b&&b.comm;
 if(!b||S.over||(!q&&(!c||c.turn<S.turn-0)))return el.hidden=true;
 el.hidden=false;el.classList.toggle('ask',!!q);
 el.innerHTML=q?`<div class="cm"><b>${q.who}</b><p>“${q.txt}”</p></div><div class="ch"><button type="button" class="primary" data-bvp="0">${q.a.label}</button><button type="button" class="primary" data-bvp="1">${q.b.label}</button></div><small>Decide to continue. ${q.a.label}: ${bvSub(q.a.txt,q.c)} · ${q.b.label}: ${bvSub(q.b.txt,q.c)}</small>`
  :`<div class="cm"><b>${c.who}</b><p>${c.who==='You chose'?c.txt:`“${c.txt}”`}</p></div><button type="button" class="x" data-bvx aria-label="Dismiss">×</button>`}
document.addEventListener('click',ev=>{const p=ev.target.closest('[data-bvp]');if(p){bvPick(+p.dataset.bvp);return}
 if(ev.target.closest('[data-bvx]')&&S&&S.bv){S.bv.comm=null;bvComm()}});
const _bvHud=hudRender;hudRender=function(){_bvHud();if(!S||!S.bv)return;const o=document.getElementById('objs');if(o)o.insertAdjacentHTML('afterbegin',bvHud());
 const ch=document.getElementById('sTwist'),T=TWISTS[S.bv.tw];if(ch){ch.hidden=!T;if(T){ch.innerHTML=`${icon(T.ic)} ${T.n}`;ch.title=T.desc}}
 if(S.bv.q.length){const e=document.getElementById('endBtn');if(e)e.disabled=true}
 const cell=(x,y)=>document.querySelector(`#board .cell[data-x="${x}"][data-y="${y}"]`);
 for(const z of (S.bv.bar&&S.bv.bar.zones)||[])for(let y=z.y-1;y<=z.y+1;y++)for(let x=z.x-1;x<=z.x+1;x++){const c=inb(x,y)&&cell(x,y);if(c)c.classList.add('warn')}
 for(const m of S.bv.bombs||[]){const c=cell(m.x,m.y);if(c)c.insertAdjacentHTML('beforeend',`<span class="btimer">${m.t}</span>`)}
 for(const [k,hp] of Object.entries(S.bv.pyl||{})){const [x,y]=k.split(',');const c=cell(x,y);if(c)c.insertAdjacentHTML('beforeend',`<span class="btimer hp">${hp}</span>`)}
 bvComm()};
// Temple mission cards: show the rolled twist and side objective, so they weigh into which crisis you pick.
const _bvOpt=optionHTML;optionHTML=function(o,i){const h=_bvOpt(o,i);try{const T=TWISTS[twistFor(o)],D=SIDES[sideFor(o)],G=SIG[o.mission];
 const tags=`<div class="meta twmeta">${T?`<span class="twchip" title="${T.desc}">${icon(T.ic)} ${T.n}</span>`:''}${G?`<span class="twchip sig" title="${G.desc}">${icon('mark')} ${G.n}</span>`:''}${D?`<span class="twchip side" title="${D.desc}">${icon('scan')} ${D.n}: ${fmtRes(D.res)}</span>`:''}</div>`;
 return h.replace(/<button type="button" class="primary" data-act="squad:/,tags+'<button type="button" class="primary" data-act="squad:')}catch(e){return h}};
// Debrief: the fight's story beats and choices, the signature result and side objective, and what they paid.
const _bvDeb=debrief;debrief=function(win,msg,out){_bvDeb(win,msg,out);try{const b=S&&S.bv;if(!b)return;const btn=document.getElementById('toBase');if(!btn)return;
 const T=TWISTS[b.tw],sg=sigStat(),sd=sideStat(),H=(b.hist||[]).slice(-8);
 btn.insertAdjacentHTML('beforebegin',`<div class="bvrecap"><b>Battle report</b>${T?`<p>${icon(T.ic)} Twist: ${T.n}</p>`:''}${sg?`<p>${icon('mark')} ${sg.n}: ${sg.v}</p>`:''}${sd?`<p>${icon('scan')} ${sd.n}: ${win&&sideOk()?'done ✓':'missed'}</p>`:''}
  ${out&&out.bvRes?`<p class="up">Extra rewards: ${fmtRes(out.bvRes)}</p>`:''}${H.length?`<details><summary>Comms log (${H.length})</summary>${H.map(t=>`<p class="muted">${t}</p>`).join('')}</details>`:''}</div>`)}catch(e){}};
// Galaxy map briefing panel (galaxy.js, replaced the mission cards): same chips above "Choose squad".
if(typeof panelFor==='function'){const _bvPanel=panelFor;panelFor=function(x){const h=_bvPanel(x);try{if(!x||!x.o)return h;const o=x.o,T=TWISTS[twistFor(o)],D=SIDES[sideFor(o)],G=SIG[o.mission];
 const tags=`<div class="meta twmeta">${T?`<span class="twchip" title="${T.desc}">${icon(T.ic)} ${T.n}</span>`:''}${G?`<span class="twchip sig" title="${G.desc}">${icon('mark')} ${G.n}</span>`:''}${D?`<span class="twchip side" title="${D.desc}">${icon('scan')} ${D.n}: ${fmtRes(D.res)}</span>`:''}</div>`;
 return h.replace(/<button type="button" class="primary" data-act="squad:/,tags+'<button type="button" class="primary" data-act="squad:')}catch(e){return h}}}

/* Briefing and debrief screens. Boot runs last. */
/* ---------- Briefing & debrief ---------- */
function briefing(noPull){const m=$('#modal');m.hidden=false;
 if(!noPull&&syncCode())pullRemote().then(ch=>{if(ch&&!m.hidden&&m.querySelector('[data-c]'))briefing(true)});
 m.innerHTML=`<div class="box"><div class="eyebrow">Jedi Council · Coruscant</div><h2>A vision of fire</h2>
 <p>In meditation, the Council saw the Temple burning, millennia from now. Nobody knows when. Everyone agrees it can be changed.</p>
 <p>Today the danger is closer. Imperial Sith troopers are closing on Outpost Aurek-7, a hyperspace relay on the frontier. Hold it for 8 turns until the fleet arrives. Three waves are expected.</p>
 ${loadSave()?`<button class="choice" type="button" id="cont" style="border-color:var(--holo)"><b>Continue mission</b><span>Resume your saved game at turn ${loadSave().turn}.</span></button>`:''}
 <p class="eyebrow">${loadSave()?'Or start over. How do you prepare?':'How do you prepare?'}</p>
 <button class="choice" type="button" data-c="fort"><b>Fortify the line</b><span>Three extra crates of cover around the relay.</span></button>
 <button class="choice" type="button" data-c="supply"><b>Extra supplies</b><span>Doc Bren gets a third medkit. Grak gets a third grenade.</span></button>
 <button class="choice" type="button" data-c="calm"><b>Meditate before battle</b><span>Both Jedi start at full Focus.</span></button></div>`;
 m.querySelectorAll('[data-c]').forEach(b=>b.onclick=()=>newGame(b.dataset.c));
 const c=m.querySelector('#cont');if(c)c.onclick=()=>continueGame(loadSave())}
function finish(win,msg){S.over=true;S.phase='over';saveGame();render();
 const rows=S.units.filter(u=>u.side==='p').map(u=>{const fate=u.status==='dead'?'One with the Force':u.status==='down'?(win?'Wounded, evacuated':'Captured by the Sith'):`Returned · ${u.hp}/${u.max} HP`;
  return `<div><span>${u.n}${u.jedi?` <small style="color:var(--dark)">Darkness ${u.dark}</small>`:''}</span><span>${fate}</span></div>`}).join('');
 const odark=S.units.filter(u=>u.jedi).reduce((s,u)=>s+u.dark,0)+S.orderDark;
 const m=$('#modal');m.hidden=false;
 m.innerHTML=`<div class="box"><div class="eyebrow">Debrief · Turn ${S.turn}</div><h2 class="${win?'':'lose'}">${win?'Relay held':'Mission failed'}</h2><p>${msg}</p>
 <div class="sum">${rows}<div><span>Relay integrity</span><span>${S.cons}/${CONS}</span></div><div><span>Enemies killed</span><span>${S.kills}</span></div><div><span>Prisoners taken (intel)</span><span>${S.intel}</span></div><div><span>Order Darkness</span><span>${odark}</span></div></div>
 <p class="muted">${odark>=5?'The Council notes how the battle was won. Some of the Masters are uneasy.':S.intel?'Prisoners mean intel. The Archives will want to talk to them.':'Clean work. The Council approves.'}</p>
 <button type="button" class="primary" id="again">Play again</button></div>`;
 $('#again').onclick=briefing}

newGame('none');briefing();

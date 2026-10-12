/* Drawing the board and side panels. */
/* ---------- Rendering ---------- */
function coverMark(x,y){let b=0;for(const [dx,dy] of N4){const c=tile(x+dx,y+dy);if(!inb(x+dx,y+dy))continue;if(FULL(c))b=2;else if(HALF(c))b=Math.max(b,1)}return b?`<i class="cv${b===2?' f':''}"></i>`:''}
function token(u){const ini=u.side==='e'?u.sym:u.n.replace(/^(Sgt\.|Doc) /,'').split(' ').map(w=>w[0]).join('').slice(0,2);
 const c=['tok',u.side==='e'?'en':'',u===S.sel?'sel':'',u.status,u.guard?'guard':'',u.ow?'ow':'',u.side==='p'&&u.status==='ok'&&!u.ap&&S.phase==='player'?'spent':''].join(' ');
 return `<div class="${c}" style="${u.col?'--uc:'+u.col:''}">${ini}<i class="hp"><b style="width:${u.hp/u.max*100}%"></b></i>${S.info?`<em>${u.hp}</em>`:''}</div>`}
const pips=(n,on,cls='')=>`<span class="pips ${cls}">${Array.from({length:n},(_,i)=>`<i class="${i<on?'on':''}"></i>`).join('')}</span>`;
function cardHTML(){const u=S.peek||S.sel;
 if(!u)return `<p class="muted">${S.phase==='enemy'?'Enemy turn…':'Select a unit.'}</p>`;
 const st={down:`Down · ${u.bleed} turn${u.bleed>1?'s':''} to bleed out`,stunned:'Stunned',surrender:'Surrendered'}[u.status];
 let h=`<div><div class="uname" style="${u.col?'color:'+u.col:''}">${u.n}</div><div class="usub">${u.side==='e'?'Hostile':(u.rank?u.rank+' · ':'')+u.cls}${st?' · '+st:''}${u.guard?' · Guard':''}${u.ow?' · Overwatch':''}</div></div>`;
 h+=`<div class="row" style="--uc:${u.side==='e'?'var(--sith)':u.col||'var(--troop)'}"><span>HP</span>${pips(u.max,u.hp)}</div>`;
 if(u.side==='p')h+=`<div class="row" style="--uc:var(--fg)"><span>Actions</span>${pips(2,u.ap)}</div>`;
 if(u.jedi)h+=`<div class="row"><span>Focus</span>${pips(u.maxF,u.focus,'f')}</div><div class="row"><span>Darkness</span><span class="bar"><b style="width:${u.dark*10}%"></b></span><span>${u.dark}/10</span></div>`;
 if(S.info||u.side==='e')h+=`<div class="grid2"><span>Aim <b>${u.aim}</b></span><span>Move <b>${u.mob}</b></span><span>Damage <b>${u.dmg[0]}–${u.dmg[1]}</b></span><span>Range <b>${u.range<2?'melee':u.range}</b></span><span>Initiative <b>${u.init}</b></span>${u.deflect?`<span>Deflect <b>${u.deflect}%</b></span>`:''}${u.kits!=null?`<span>Medkits <b>${u.kits}</b></span>`:''}${u.nades!=null?`<span>Grenades <b>${u.nades}</b></span>`:''}</div>`;
 return h}
function actsHTML(){const u=S.sel;if(!canAct(u)||S.peek)return '';
 return u.abil.map(k=>{const ab=AB[k];let why=null;
  if(ab.f&&u.focus<ab.f)why=`Needs ${ab.f} Focus`;else if(ab.avail)why=ab.avail(u);
  if(!why&&!ab.instant&&!targetsFor(u,k).length)why='No targets';
  const cost=[ab.f?ab.f+' Focus':'',ab.ap===1?'1 action':ab.instant||ab.tg?'ends turn':''].filter(Boolean).join(' · ');
  return `<button type="button" data-a="${k}" class="${S.mode===k?'on':''}" ${why?'disabled title="'+why+'"':''}>${ab.name}<small>${why||cost}</small></button>`}).join('')}
function hintText(){if(S.over)return '';if(S.phase==='enemy')return 'The Sith are moving…';const u=S.sel;
 if(S.peek)return 'Enemy details. Tap one of your units to give orders.';
 if(!u)return players().some(canAct)?'Select a unit.':'All units have acted. End the turn.';
 if(u.status==='down')return `${u.n} is down. A medic beside them can revive them.`;
 if(!canAct(u))return players().some(canAct)?'This unit has acted. Pick another.':'All units have acted. End the turn.';
 if(S.mode==='move')return 'Tap a lit tile to move (1 action). Squares mark cover: hollow = half, solid = full.';
 return AB[S.mode].tip+' Tap a highlighted target, or tap the ability again to cancel.'}
function render(){
 $('#sTurn').textContent=`${S.turn}/${TURNS}`;$('#sCons').textContent=`${S.cons}/${CONS}`;
 const nw=Object.keys(WAVES).map(Number).find(t=>t>S.turn);$('#sWave').textContent=nw?'T'+nw:'none';
 $('#sIntel').textContent=S.intel;$('#sDark').textContent=players().reduce((s,u)=>s+u.dark,0)+S.units.filter(u=>u.jedi&&!alive(u)).reduce((s,u)=>s+u.dark,0)+S.orderDark;
 $('#infoBtn').textContent='Info: '+(S.info?'on':'off');$('#infoBtn').classList.toggle('on',S.info);
 const R=S.mode==='move'&&canAct(S.sel)&&!S.peek?reach(S.sel).d:{};
 const shoot=S.info&&canAct(S.sel)&&S.mode==='move'&&S.sel.abil.includes('shoot')?targetsFor(S.sel,'shoot'):[];
 let h='';
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){const c=S.grid[y][x],k=x+','+y,g=S.tg.find(t=>t.x===x&&t.y===y),u=unitAt(x,y);
  const cls={'#':'w',c:'c',r:'r',O:'o'}[c]||'';
  h+=`<div class="cell ${cls}${R[k]>0?' reach':''}${g?(g.area?' aim':' tgt')+(g.ally?' ally':''):''}" data-x="${x}" data-y="${y}">`;
  if(R[k]>0)h+=coverMark(x,y);
  if(u)h+=token(u);
  const sp=g&&!g.area&&g.chance!=null?g.chance:(shoot.find(t=>t.x===x&&t.y===y)||{}).chance;
  if(sp!=null)h+=`<span class="pct">${sp}%</span>`;
  for(const f of S.fx)if(f.x===x&&f.y===y)h+=`<span class="fx">${f.txt}</span>`;
  h+='</div>'}
 $('#board').innerHTML=h;
 $('#roster').innerHTML=S.units.filter(u=>u.side==='p').map((u,i)=>`<button type="button" data-u="${i}" class="${u===S.sel&&!S.peek?'on':''} ${!canAct(u)?'done':''}" style="${u.col?'--uc:'+u.col:''}">${u.n.replace(/^(Sgt\.|Doc) /,'').split(' ')[0]}${u.status==='down'?' ✚':u.status==='dead'?' †':''}</button>`).join('');
 $('#card').innerHTML=cardHTML();$('#acts').innerHTML=actsHTML();$('#hint').textContent=hintText();
 $('#endBtn').disabled=S.phase!=='player'||S.over;
 $('#log').innerHTML=S.log.slice(0,12).map(l=>`<p class="${l.cls}">${l.t}</p>`).join('')}

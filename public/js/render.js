/* Drawing the board, overlay lines, side panels, odds panel. Look: docs/specs/ui.md */
const TILE_CLS={'#':'w',c:'c',r:'r',O:'o',x:'x',d:'d',D:'dl',_:'do',k:'k',q:'q',Q:'qd',E:'e'};
const TILE_IC={x:'barrel',d:'door',D:'door',k:'hack',q:'scan',Q:'scan',E:'evac',O:'relay'};
function coverMark(x,y){let b=0;for(const [dx,dy] of N4){const c=tile(x+dx,y+dy);if(!inb(x+dx,y+dy))continue;if(FULL(c))b=2;else if(HALF(c))b=Math.max(b,1)}return b?`<i class="cv${b===2?' f':''}"></i>`:''}
const unitIcon=u=>u.ic||u.cls.toLowerCase();
const shortName=u=>u.n.replace(/^(Sgt\.|Doc|Aide) /,'').split(' ')[0];
function badge(u){return u.status==='down'?'down':u.status==='stunned'?'stunned':u.status==='surrender'?'surrender':u.bound?'captured':u.tricked?'stunned':
 u.guard?'guard':u.ow?'overwatch':u.hunker?'hunker':u.barrier?'barrier':u.supp?'suppress':u.marked?'mark':u.data?'scan':null}
function token(u){if(u.hid)return '';
 const c=['tok',u.side==='e'?'en':'',u===S.sel&&!S.peek?'sel':'',u===S.peek?'peek':'',u.status,u.guard?'guard':'',u.side==='p'&&u.status==='ok'&&!u.bound&&!u.ap&&S.phase==='player'?'spent':''].join(' ');
 const b=badge(u),col=u.side==='e'?'var(--sith)':u.vip?'var(--good)':u.col||'var(--troop)';
 const hp=`<i class="hp">${Array.from({length:u.max},(_,i)=>`<b class="${i<u.hp?'on':''}"></b>`).join('')}</i>`;
 return `<div class="${c}" style="--uc:${col}">${icon(unitIcon(u))}${hp}${b?`<span class="bdg">${icon(b)}${u.status==='down'&&!u.stable?`<small>${u.bleed}</small>`:''}</span>`:''}${S.info?`<em>${u.hp}</em>`:''}</div>`}
const pips=(n,on,cls='')=>`<span class="pips ${cls}">${Array.from({length:n},(_,i)=>`<i class="${i<on?'on':''}"></i>`).join('')}</span>`;
function cardHTML(){const u=S.peek||S.sel;
 if(!u)return `<p class="muted">${S.phase==='enemy'?'Enemy turn…':'Select a unit.'}</p>`;
 const st={down:u.stable?'Down · stabilized':`Down · ${u.bleed} turn${u.bleed>1?'s':''} to bleed out`,stunned:'Stunned',surrender:'Surrendered'}[u.status];
 const tags=[st,u.bound?'Locked in the cell':'',u.guard?'Guard':'',u.ow?'Overwatch':'',u.hunker?'Hunkered':'',u.barrier?'Barrier':'',u.data?'Carrying data':'',u.armor?`Armor ${u.armor}`:'',u.horror?'Hurts only Jedi':''].filter(Boolean);
 const sub=u.side==='e'?'Hostile':u.vip?'Prisoner':`${u.title||'Rank '+(u.rank||1)} · ${u.cls}`;
 let h=`<div class="who"><span class="mini" style="--uc:${u.side==='e'?'var(--sith)':u.col||'var(--troop)'}">${icon(unitIcon(u))}</span><div><div class="uname" style="${u.col?'color:'+u.col:''}">${u.n}</div><div class="usub">${sub}${tags.length?' · '+tags.join(' · '):''}</div></div></div>`;
 h+=`<div class="row" style="--uc:${u.side==='e'?'var(--sith)':u.col||'var(--troop)'}"><span>HP</span>${pips(u.max,u.hp)}${S.info?`<b class="num">${u.hp}/${u.max}</b>`:''}</div>`;
 if(u.side==='p'&&!u.vip)h+=`<div class="row" style="--uc:var(--fg)"><span>Actions</span>${pips(2,u.ap)}</div>`;
 if(u.jedi)h+=`<div class="row"><span>Focus</span>${pips(u.maxF,u.focus,'f')}</div><div class="row"><span>Darkness</span><span class="bar"><b style="width:${u.dark*10}%"></b></span><span>${u.dark}/10</span></div>`;
 if(u.side==='e'){const it=intentOf(u);h+=`<div class="intent">${icon('overwatch')}<span><b>Plan:</b> ${it.txt}<small>Best guess. It can change if you move first.</small></span></div>`}
 if(S.info||u.side==='e')h+=`<div class="grid2"><span>Aim <b>${u.aim}</b></span><span>Move <b>${u.mob}</b></span><span>Damage <b>${u.dmg[0]}–${u.dmg[1]}</b></span><span>Range <b>${u.range<2?'melee':u.range}</b></span>${u.deflect?`<span>Deflect <b>${u.deflect}%</b></span>`:''}${u.crit?`<span>Crit <b>${u.crit}%</b></span>`:''}${u.kits!=null?`<span>Medkits <b>${u.kits}</b></span>`:''}${u.nades!=null?`<span>Grenades <b>${u.nades}</b></span>`:''}</div>`;
 return h}
function actsHTML(){const u=S.sel;if(!canAct(u)||S.peek)return '';
 return u.abil.map(k=>{const ab=AB[k];if(!ab||ab.passive)return '';let why=null;
  if(ab.f&&u.focus<ab.f)why=`Needs ${ab.f} Focus`;else if(ab.avail)why=ab.avail(u);
  if(!why&&!ab.instant&&!targetsFor(u,k).length){if(ab.ctx)return '';why='No targets'}
  const cost=[ab.f?ab.f+' Focus':'',ab.ap===1?'1 action':'ends turn'].filter(Boolean).join(' · ');
  return `<button type="button" data-a="${k}" class="act ${S.mode===k?'on':''}" ${why?'disabled':''} title="${ab.tip.replace(/"/g,'')}">${icon(ab.ic)}<span>${ab.name}<small>${why||cost}</small></span></button>`}).join('')}
// Names what the target hides behind, for the odds panel ("Half cover · crate").
const COVER_N={'#':'wall',O:'objective',d:'door',D:'locked door',c:'crate',r:'rubble',x:'barrel',k:'console',q:'terminal',Q:'terminal'};
function coverName(t,a){if(t.barrier)return 'Force Barrier';let best=null,bv=0;const dx=Math.sign(a.x-t.x),dy=Math.sign(a.y-t.y);
 for(const [x,y] of [dx?[t.x+dx,t.y]:null,dy?[t.x,t.y+dy]:null].filter(Boolean)){const c=tile(x,y),v=FULL(c)?2:HALF(c)?1:0;if(v>bv){bv=v;best=c}}
 return COVER_N[best]||'cover'}
// Odds panel: every modifier on its own line, then Confirm (two-step aiming, spec D §5).
function oddsHTML(){const u=S.sel,g=S.pick;if(!g||!canAct(u))return '';const ab=AB[S.mode];let head,lines=[],total=g.chance;
 if(g.t&&g.t.side==='e'&&(S.mode==='shoot'||ab.melee)){const o=odds(u,g.t,ab.melee?{melee:true,mod:S.mode==='sweep'?-10:u.leapAim||0}:{});lines=o.lines;total=o.total}
 if(g.barrel)head='Barrel · 3×3 blast, 3 damage';else if(g.area)head=ab.name+' · 3×3 area';else if(g.spot)head='Leap here';else if(g.t)head=g.t.n;else head=ab.name;
 const dm=ab.dm&&g.t&&g.t.side==='e'?ab.dm(u):null,kill=dm&&Math.max(1,dm[1]+(u.jedi&&u.dark>=5?1:0)-(g.t.armor||0))>=g.t.hp;
 return `<div class="odds"><div class="oh"><b>${head}</b>${total!=null?`<span class="tot">${total}%</span>`:''}</div>
 ${lines.map(([k,v])=>`<div class="ol"><span>${/cover$/.test(k)&&g.t?k+' · '+coverName(g.t,u):k}</span><span>${k==='Aim'?v:(v>0?'+':'')+v}</span></div>`).join('')}
 ${dm?`<div class="ol dm"><span>Damage</span><span>${dm[0]}–${dm[1]}${kill?' · kills on hit':''}</span></div>`:''}
 <button type="button" id="confirm" class="primary">Confirm ${ab.name}</button></div>`}
function hintText(){if(S.over)return '';if(S.phase==='enemy')return 'The enemy is moving…';const u=S.sel;
 if(S.peek)return 'Enemy details and its likely plan. Tap one of your units to give orders.';
 if(!u)return players().some(canAct)?'Select a unit.':'All units have acted. End the turn.';
 if(u.status==='down')return `${u.n} is down. An adjacent ally can Stabilize; a medkit revives.`;
 if(!canAct(u))return players().some(canAct)?'This unit has acted. Pick another.':'All units have acted. End the turn.';
 if(S.pick)return 'Check the odds, then Confirm. Tap another target to switch.';
 if(S.mode==='move')return window.View3D&&View3D.on?'Click a lit tile to move (1 action). Shields mark cover: outline = half, solid = full.':'Tap a lit tile to move (1 action). Squares mark cover: hollow = half, solid = full.';
 return AB[S.mode].tip+' Tap a highlighted target, or tap the ability again to cancel.'}
function statsRender(){const M=S.M,set=(id,v)=>{$(id).textContent=v},show=(id,on)=>{$(id).hidden=!on};
 $('#where').textContent=`${M.n} · ${M.where}`;
 set('#sTurn',S.type==='defend'?`${S.turn}/${M.turns}`:S.turn);
 {const o=objStat();set('#sObjL',o.label);set('#sObj',o.val)}
 const nw=M.waves&&Object.keys(M.waves).map(Number).find(t=>t>S.turn);show('#sWaveW',!!M.waves);if(M.waves)set('#sWave',nw?'T'+nw:'none');
 show('#sThrW',!!M.par);if(M.par)$('#sThr').innerHTML=S.threat?`${pips(Math.max(4,S.threat),S.threat,'t')}`:`rises after T${M.par}`;
 set('#sIntel',S.intel);
 set('#sDark',S.units.filter(u=>u.jedi).reduce((s,u)=>s+u.dark,0)+S.orderDark)}
let lastPhase='';
function bannerRender(){const b=$('#banner'),ph=S.over?'over':S.phase;if(ph===lastPhase)return;lastPhase=ph;
 b.className='banner '+(ph==='enemy'?'foe':ph==='over'?'done':'');b.textContent=ph==='enemy'?`Enemy phase · turn ${S.turn}`:ph==='over'?'Mission over':`Player phase · turn ${S.turn}`;
 void b.offsetWidth;b.classList.add('sweep')}
// SVG overlay: hover move path (solid holo), chosen shot (animated dashed holo), enemy intent (dashed red).
function drawOver(){const o=$('#over');if(!o)return;const c=p=>`${p.x+.5},${p.y+.5}`;let h='';
 if(S.hpath&&S.hpath.length&&S.sel)h+=`<polyline class="mv" points="${[S.sel,...S.hpath].map(c).join(' ')}"/><circle class="mvd" cx="${S.hpath.at(-1).x+.5}" cy="${S.hpath.at(-1).y+.5}" r=".12"/>`;
 if(S.pick&&S.sel&&!S.pick.area&&!S.pick.spot)h+=`<line class="shot" x1="${S.sel.x+.5}" y1="${S.sel.y+.5}" x2="${S.pick.x+.5}" y2="${S.pick.y+.5}"/>`;
 if(S.pick&&S.pick.area)h+=`<rect class="area" x="${S.pick.x-1}" y="${S.pick.y-1}" width="3" height="3"/>`;
 if(S.peek&&S.peek.side==='e'&&S.phase==='player'){const it=intentOf(S.peek);
  if(it.to)h+=`<line class="int" x1="${S.peek.x+.5}" y1="${S.peek.y+.5}" x2="${it.to.x+.5}" y2="${it.to.y+.5}"/>`;
  if(it.area)h+=`<line class="int" x1="${S.peek.x+.5}" y1="${S.peek.y+.5}" x2="${it.area.x+.5}" y2="${it.area.y+.5}"/><rect class="iarea" x="${it.area.x-1}" y="${it.area.y-1}" width="3" height="3"/>`}
 for(const s of S.smoke)h+=`<rect class="smk" x="${s.x-1}" y="${s.y-1}" width="3" height="3"/>`;
 o.innerHTML=h}
function render(){if(!S)return;
 statsRender();bannerRender();
 $('#infoBtn').textContent='Info: '+(S.info?'on':'off');$('#infoBtn').classList.toggle('on',S.info);
 const R=S.mode==='move'&&canAct(S.sel)&&!S.peek?reach(S.sel).d:{};
 const shoot=S.info&&canAct(S.sel)&&S.mode==='move'&&S.sel.abil.includes('shoot')?targetsFor(S.sel,'shoot').filter(g=>g.t):[];
 const best=Math.max(-1,...S.tg.filter(g=>g.t&&g.t.side==='e'&&g.chance!=null).map(g=>g.chance));
 let h='';
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){const c=S.grid[y][x],k=x+','+y,g=S.tg.find(t=>t.x===x&&t.y===y),u=unitAt(x,y),pk=S.pick&&S.pick.x===x&&S.pick.y===y;
  h+=`<div class="cell ${TILE_CLS[c]||(TILES[c]&&TILES[c].as)||''}${R[k]>0?' reach':''}${g?(g.area?' aim':g.spot?' spot':' tgt')+(g.ally?' ally':''):''}${pk?' picked':''}" data-x="${x}" data-y="${y}">`;
  if(TILE_IC[c])h+=icon(TILE_IC[c],'ti');
  if(R[k]>0)h+=coverMark(x,y);
  if(u)h+=token(u);
  const sp=g&&!g.area&&!g.spot&&g.chance!=null?g:shoot.find(t=>t.x===x&&t.y===y);
  if(sp&&(!sp.t||!sp.t.hid))h+=`<span class="pct${sp.ally?' al':sp.chance===best&&sp.t&&sp.t.side==='e'?' best':''}">${sp.chance}%</span>`;
  for(const f of S.fx)if(f.x===x&&f.y===y)h+=`<span class="fx ${f.cls}">${f.txt}</span>`;
  h+='</div>'}
 $('#board').innerHTML=h;drawOver();
 $('#roster').innerHTML=S.units.filter(u=>u.side==='p').map((u,i)=>`<button type="button" data-u="${i}" class="${u===S.sel&&!S.peek?'on':''} ${!canAct(u)?'done':''}" style="--uc:${u.vip?'var(--good)':u.col||'var(--troop)'}">${icon(unitIcon(u))}${shortName(u)}${u.status==='down'?' ✚':u.status==='dead'?' †':''}</button>`).join('');
 $('#card').innerHTML=cardHTML();$('#acts').innerHTML=actsHTML();$('#odds').innerHTML=oddsHTML();$('#hint').textContent=hintText();
 $('#endBtn').disabled=S.phase!=='player'||S.over;
 $('#log').innerHTML=S.log.slice(0,12).map(l=>`<p class="${l.cls}">${l.t}</p>`).join('');
 if(window.View3D)View3D.sync()}

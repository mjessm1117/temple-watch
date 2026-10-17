/* Drawing the board, overlay lines, side panels, odds panel. Look: docs/specs/ui.md */
const TILE_CLS={'#':'w',c:'c',r:'r',O:'o',x:'x',d:'d',D:'dl',_:'do',k:'k',q:'q',Q:'qd',E:'e'};
const TILE_IC={x:'barrel',d:'door',D:'door',k:'hack',q:'scan',Q:'scan',E:'evac',O:'relay'};
function coverMark(x,y){let b=0;for(const [dx,dy] of N4){const c=tile(x+dx,y+dy);if(!inb(x+dx,y+dy))continue;if(FULL(c))b=2;else if(HALF(c))b=Math.max(b,1)}return b?`<i class="cv${b===2?' f':''}"></i>`:''}
const unitIcon=u=>u.ic||u.cls.toLowerCase();
const shortName=u=>u.n.replace(/^(Sgt\.|Doc|Aide) /,'').split(' ')[0];
// Status ids match STATUS (data.js) so tooltips/codex resolve; BADGE_IC maps them to icons.
function badge(u){return u.status==='down'?'down':u.status==='stunned'?'stunned':u.status==='surrender'?'surrender':u.bound?'captured':u.tricked?'stunned':
 u.panic?'panic':u.disarmed?'disarmed':u.rooted?'rooted':u.guard?'guard':u.ow?'overwatch':u.hunker?'hunker':u.barrier?'barrier':u.supp?'suppressed':u.marked?'marked':u.conc?'concealed':u.shield?'shield':u.data?'scan':null}
const BADGE_IC={suppressed:'suppress',marked:'mark',disarmed:'disarm',concealed:'conceal',rooted:'disarm',shield:'barrier'};
const badgeIc=b=>{const k=BADGE_IC[b]||b;return ICONS[k]?k:'mark'};
function token(u){if(u.hid)return '';
 const c=['tok',u.side==='e'?'en':'',u===S.sel&&!S.peek?'sel':'',u===S.peek?'peek':'',u.status,u.guard?'guard':'',u.side==='p'&&u.status==='ok'&&!u.bound&&!u.ap&&S.phase==='player'?'spent':''].join(' ');
 const b=badge(u),col=u.side==='e'?'var(--sith)':u.vip?'var(--good)':u.col||'var(--troop)';
 const hp=`<i class="hp">${Array.from({length:u.max},(_,i)=>`<b class="${i<u.hp?'on':''}"></b>`).join('')}</i>`;
 const tp=u.side==='e'&&u.type?` data-tip="enemy:${u.type}"`:'';
 return `<div class="${c}" style="--uc:${col}"${tp}>${icon(unitIcon(u))}${hp}${b?`<span class="bdg" data-tip="status:${b}">${icon(badgeIc(b))}${u.status==='down'&&!u.stable?`<small>${u.bleed}</small>`:''}</span>`:''}${S.info?`<em>${u.hp}</em>`:''}</div>`}
const pips=(n,on,cls='')=>`<span class="pips ${cls}">${Array.from({length:n},(_,i)=>`<i class="${i<on?'on':''}"></i>`).join('')}</span>`;
function cardHTML(){const u=S.peek||S.sel;
 if(!u)return `<p class="muted">${S.phase==='enemy'?'Enemy turn…':'Select a unit.'}</p>`;
 const st={down:u.stable?'Down · stabilized':`Down · ${u.bleed} turn${u.bleed>1?'s':''} to bleed out`,stunned:'Stunned',surrender:'Surrendered'}[u.status];
 const T=(t,k)=>t?(k?`<span data-tip="${k}">${t}</span>`:t):'',tags=[T(st,'status:'+u.status),T(u.bound?'Locked in the cell':''),T(u.guard?'Guard':'','status:guard'),T(u.ow?'Overwatch':'','status:overwatch'),T(u.hunker?'Hunkered':'','status:hunker'),T(u.barrier?'Barrier':'','status:barrier'),T(u.data?'Carrying data':'','status:scan'),T(u.panic?'Panicked':'','status:panic'),T(u.disarmed?'Disarmed':'','status:disarmed'),T(u.conc?'Concealed':'','status:concealed'),T(u.armor?`Armor ${u.armor}`:'','stat:damage'),T(u.horror?'Hurts only Jedi':'',u.type?'enemy:'+u.type:'')].filter(Boolean);
 const sub=u.side==='e'?'Hostile':u.vip?'Prisoner':`${u.title||'Rank '+(u.rank||1)} · ${u.cls}`;
 let h=`<div class="who"><span class="mini" style="--uc:${u.side==='e'?'var(--sith)':u.col||'var(--troop)'}">${icon(unitIcon(u))}</span><div><div class="uname" style="${u.col?'color:'+u.col:''}">${u.n}</div><div class="usub">${sub}${tags.length?' · '+tags.join(' · '):''}</div></div></div>`;
 h+=`<div class="row" style="--uc:${u.side==='e'?'var(--sith)':u.col||'var(--troop)'}"><span data-tip="stat:hp">HP</span>${pips(u.max,u.hp)}${S.info?`<b class="num">${u.hp}/${u.max}</b>`:''}</div>`;
 if(u.side==='p'&&!u.vip)h+=`<div class="row apr" style="--uc:var(--fg)"><span data-tip="stat:actions">Actions</span><span class="pips">${[0,1].map(i=>`<i class="${i<u.ap?'on':''}${i===u.ap-1?' s1':''}${i===u.ap-2?' s2':''}"></i>`).join('')}</span></div>`;
 if(u.jedi)h+=`<div class="row fr"><span data-tip="stat:focus">Focus</span><span class="pips f">${Array.from({length:u.maxF},(_,i)=>`<i class="${i<u.focus?'on':''}" data-k="${u.focus-i}"></i>`).join('')}</span></div><div class="row"><span data-tip="status:darkness">Darkness</span><span class="bar"><b style="width:${u.dark*10}%"></b></span><span>${u.dark}/10</span></div>`;
 if(u.side==='e'){const it=intentOf(u);h+=`<div class="intent">${icon('overwatch')}<span><b>Plan:</b> ${it.txt}<small>Best guess. It can change if you move first.</small></span></div>`}
 if(S.info||u.side==='e')h+=`<div class="grid2"><span data-tip="stat:aim">Aim <b>${u.aim}</b></span><span data-tip="stat:move">Move <b>${u.mob}</b></span><span data-tip="stat:damage">Damage <b>${u.dmg[0]}–${u.dmg[1]}</b></span><span data-tip="stat:range">Range <b>${u.range<2?'melee':u.range}</b></span>${u.deflect?`<span data-tip="stat:deflect">Deflect <b>${u.deflect}%</b></span>`:''}${u.crit?`<span data-tip="stat:crit">Crit <b>${u.crit}%</b></span>`:''}${u.kits!=null?`<span data-tip="stat:medkits">Medkits <b>${u.kits}</b></span>`:''}${u.nades!=null?`<span data-tip="stat:grenades">Grenades <b>${u.nades}</b></span>`:''}${u.will!=null?`<span data-tip="stat:will">Will <b>${u.will}</b></span>`:''}${u.stress?`<span data-tip="stat:stress">Stress <b>${u.stress}</b></span>`:''}</div>`;
 if(u.side==='e'&&u.type&&FOES[u.type]&&FOES[u.type].desc)h+=`<p class="udesc">${FOES[u.type].desc}</p>`;
 return h}
function actsHTML(){const u=S.sel;if(!canAct(u)||S.peek)return '';
 let n=0;return u.abil.map(k=>{const ab=AB[k];if(!ab||ab.passive)return '';let why=null;
  if(ab.f&&u.focus<ab.f)why=`Needs ${ab.f} Focus`;else if(ab.avail)why=ab.avail(u);
  if(!why&&!ab.instant&&!targetsFor(u,k).length){if(ab.ctx)return '';why='No targets'}
  const cost=[ab.f?ab.f+' Focus':'',ab.ap===1?'1 action':'ends turn'].filter(Boolean).join(' · ');
  n++;return `<button type="button" data-a="${k}" data-tip="ability:${k}" data-cost="${ab.instant&&!ab.ap?'0':ab.ap===1?'1':'end'}" data-f="${ab.f||0}" class="act ${S.mode===k?'on':''}" ${why?'disabled':''}>${n<10?`<kbd>${n}</kbd>`:''}${icon(ab.ic)}<span>${ab.name}${window.pwTag&&u.pw?pwTag(u.pw[k]||0):''}<small>${why||cost}</small></span></button>`}).join('')}
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
 const AH=g.area?areaHits(u,S.mode,g):[];
 return `<div class="odds"><div class="oh"><b>${head}</b>${total!=null?`<span class="tot">${total}%</span>`:''}</div>
 ${lines.map(([k,v])=>`<div class="ol" data-tip="mod:${k}"><span>${/cover$/.test(k)&&g.t?k+' · '+coverName(g.t,u):k}</span><span>${k==='Aim'?v:(v>0?'+':'')+v}</span></div>`).join('')}
 ${g.area?(AH.length?AH.map(h=>`<div class="ol${h.ally?' warn':''}"><span>${h.t.n}${h.ally?' · ally!':''}</span><span>${h.chance}%${h.dm?` · ${h.dm[0]===h.dm[1]?h.dm[0]:h.dm[0]+'–'+h.dm[1]} dmg`:''}${h.kill?' · '+h.kill:''}</span></div>`).join(''):'<div class="ol"><span class="muted">No one in the blast.</span></div>'):''}
 ${dm?`<div class="ol dm"><span>Damage</span><span>${dm[0]}–${dm[1]}${kill?' · kills on hit':''}</span></div>`:''}
 <button type="button" id="confirm" class="primary">Confirm ${ab.name}</button></div>`}
function hintText(){if(S.over)return '';if(S.phase==='enemy')return 'The enemy is moving…';const u=S.sel;
 if(S.peek)return 'Enemy details and its likely plan. Tap one of your units to give orders.';
 if(!u)return players().some(canAct)?'Select a unit.':'All units have acted. End the turn.';
 if(u.status==='down')return `${u.n} is down. An adjacent ally can Stabilize; a medkit revives.`;
 if(!canAct(u))return players().some(canAct)?'This unit has acted. Pick another.':'All units have acted. End the turn.';
 if(S.pick)return 'Check the odds, then Confirm. Tap another target to switch.';
 if(S.mode==='move'&&S.hcost)return S.hcost===2?'Dash here: uses both actions. Click to move.':'Move here: 1 action. Click to move.';
 if(S.mode==='move'&&canUndo()&&S.undo.uid===u.uid)return 'Moved. Press U (or Undo) to take it back while nothing was revealed.';
 if(S.mode==='move')return window.View3D&&View3D.on?'Click a lit tile: blue = 1 action, gold = dash (both actions). Shields mark cover: outline = half, solid = full.':'Tap a lit tile: blue = 1 action, gold = dash (both actions). Squares mark cover: hollow = half, solid = full.';
 return AB[S.mode].tip+' Tap a highlighted target, or tap the ability again to cancel.'}
function statsRender(){const M=S.M,set=(id,v)=>{$(id).textContent=v},show=(id,on)=>{$(id).hidden=!on};
 $('#where').textContent=`${M.n} · ${M.where}`;
 set('#sTurn',S.type==='defend'?`${S.turn}/${M.turns}`:S.turn);
 {const o=objStat();set('#sObjL',o.label);set('#sObj',o.val)}
 const nw=M.waves&&Object.keys(M.waves).map(Number).find(t=>t>S.turn);show('#sWaveW',!!M.waves);if(M.waves)set('#sWave',nw?'T'+nw:'none');
 show('#sThrW',!!M.par);if(M.par)$('#sThr').innerHTML=S.threat?`${pips(Math.max(4,S.threat),S.threat,'t')}`:`rises after T${M.par}`;
 set('#sIntel',S.intel);show('#sConc',!!S.conc);
 set('#sDark',S.units.filter(u=>u.jedi).reduce((s,u)=>s+u.dark,0)+S.orderDark)}
let lastPhase='';
function bannerRender(){const b=$('#banner'),ph=S.over?'over':S.phase;if(ph===lastPhase)return;lastPhase=ph;
 b.className='banner '+(ph==='enemy'?'foe':ph==='over'?'done':'');b.textContent=ph==='enemy'?`Enemy phase · turn ${S.turn}`:ph==='over'?'Mission over':`Player phase · turn ${S.turn}`;
 void b.offsetWidth;b.classList.add('sweep')}
// SVG overlay: hover move path (solid holo), chosen shot (animated dashed holo), enemy intent (dashed red).
function drawOver(){const o=$('#over');if(!o)return;const c=p=>`${p.x+.5},${p.y+.5}`;let h='';
 if(S.hpath&&S.hpath.length&&S.sel){const e=S.hpath.at(-1),d=S.hcost===2;h+=`<polyline class="mv${d?' dash':''}" points="${[S.sel,...S.hpath].map(c).join(' ')}"/><circle class="mvd" cx="${S.hpath.at(-1).x+.5}" cy="${S.hpath.at(-1).y+.5}" r=".12"/><g class="mvc${d?' dash':''}"><rect x="${e.x+.12}" y="${e.y+(e.y<1?1.02:-.32)}" width=".76" height=".34" rx=".08"/><text x="${e.x+.5}" y="${e.y+(e.y<1?1.27:-.07)}">${d?'DASH':'1 ACT'}</text></g>`}
 if(S.pick&&S.sel&&!S.pick.area&&!S.pick.spot)h+=`<line class="shot" x1="${S.sel.x+.5}" y1="${S.sel.y+.5}" x2="${S.pick.x+.5}" y2="${S.pick.y+.5}"/>`;
 {const A=S.pick&&S.pick.area?S.pick:S.mode!=='move'&&HOV&&S.sel&&S.tg.find(g=>g.area&&g.x===HOV.x&&g.y===HOV.y);
  if(A){h+=`<rect class="area${A===S.pick?'':' hov'}" x="${A.x-1}" y="${A.y-1}" width="3" height="3"/>`;
   if(!A.ally)for(const t of areaHits(S.sel,S.mode,A))h+=`<g class="ach${t.ally?' al':t.kill?' kl':''}"><rect x="${t.t.x+.04}" y="${t.t.y+.04}" width=".62" height=".28" rx=".05"/><text x="${t.t.x+.35}" y="${t.t.y+.25}">${t.ally?'ALLY':t.chance+'%'}</text></g>`}}
 if(S.peek&&S.peek.side==='e'&&S.phase==='player'){const it=intentOf(S.peek);
  if(it.to)h+=`<line class="int" x1="${S.peek.x+.5}" y1="${S.peek.y+.5}" x2="${it.to.x+.5}" y2="${it.to.y+.5}"/>`;
  if(it.area)h+=`<line class="int" x1="${S.peek.x+.5}" y1="${S.peek.y+.5}" x2="${it.area.x+.5}" y2="${it.area.y+.5}"/><rect class="iarea" x="${it.area.x-1}" y="${it.area.y-1}" width="3" height="3"/>`}
 for(const s of S.smoke)h+=`<rect class="smk" x="${s.x-1}" y="${s.y-1}" width="3" height="3"/>`;
 o.innerHTML=h}
// Tiles next to the move zone that a 2-level height jump blocks (rules.js reach() refuses them).
function cliffs(Z){const out=new Set();if(!Z||!Object.keys(Z.d).length)return out;
 for(const k in Z.d){const [x,y]=k.split(',').map(Number),e=elevAt(x,y);
  for(let dx=-1;dx<=1;dx++)for(let dy=-1;dy<=1;dy++){const nx=x+dx,ny=y+dy,nk=nx+','+ny;if((!dx&&!dy)||!inb(nx,ny)||Z.d[nk]!=null||!PASS(tile(nx,ny))||unitAt(nx,ny))continue;
   if(Math.abs(elevAt(nx,ny)-e)>1)out.add(nk)}}return out}
function render(){if(!S)return;
 statsRender();bannerRender();
 $('#infoBtn').textContent='Info: '+(S.info?'on':'off');$('#infoBtn').classList.toggle('on',S.info);
 if(!S._ui){S._ui=1;S.info=!!SETTINGS.numbers}codexScan();
 const Z=S.mode==='move'&&canAct(S.sel)&&!S.peek?moveZones(S.sel):{d:{},mob:0},R=Z.d;
 const shoot=S.info&&canAct(S.sel)&&S.mode==='move'&&S.sel.abil.includes('shoot')?targetsFor(S.sel,'shoot').filter(g=>g.t):[];
 const VIS=S.conc?new Set(visionTiles().map(p=>p.x+','+p.y)):null,CL=cliffs(Z);
 const best=Math.max(-1,...S.tg.filter(g=>g.t&&g.t.side==='e'&&g.chance!=null).map(g=>g.chance));
 let h='';
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){const c=S.grid[y][x],k=x+','+y,g=S.tg.find(t=>t.x===x&&t.y===y),u=unitAt(x,y),pk=S.pick&&S.pick.x===x&&S.pick.y===y;
  h+=`<div class="cell ${TILE_CLS[c]||(TILES[c]&&TILES[c].as)||''}${R[k]>0?(R[k]>Z.mob?' dash':' reach'):''}${g?(g.area?' aim':g.spot?' spot':' tgt')+(g.ally?' ally':''):''}${pk?' picked':''}${VIS&&VIS.has(k)?' vis':''}${CL.has(k)?' cliff':''}${elevAt(x,y)?' el'+elevAt(x,y):''}" data-x="${x}" data-y="${y}">`;
  if(TILE_IC[c])h+=icon(TILE_IC[c],'ti');
  if(elevAt(x,y))h+=`<i class="elv" data-tip="status:highground">▲${elevAt(x,y)}</i>`;
  if(R[k]>0)h+=coverMark(x,y);
  if(u)h+=token(u);
  const sp=g&&!g.area&&!g.spot&&g.chance!=null?g:shoot.find(t=>t.x===x&&t.y===y);
  if(sp&&(!sp.t||!sp.t.hid))h+=`<span class="pct${sp.ally?' al':sp.chance===best&&sp.t&&sp.t.side==='e'?' best':''}">${sp.chance}%</span>`;
  for(const f of S.fx)if(f.x===x&&f.y===y)h+=`<span class="fx ${f.cls}">${f.txt}</span>`;
  h+='</div>'}
 $('#board').innerHTML=h;drawOver();
 $('#roster').innerHTML=S.units.filter(u=>u.side==='p').map((u,i)=>`<button type="button" data-u="${i}" class="${u===S.sel&&!S.peek?'on':''} ${!canAct(u)?'done':''}" style="--uc:${u.vip?'var(--good)':u.col||'var(--troop)'}">${icon(unitIcon(u))}${shortName(u)}${u.status==='down'?' ✚':u.status==='dead'?' †':''}</button>`).join('');
 $('#card').innerHTML=cardHTML();$('#acts').innerHTML=actsHTML();$('#odds').innerHTML=oddsHTML();$('#hint').textContent=hintText();
 $('#endBtn').disabled=S.phase!=='player'||S.over;$('#undoBtn').hidden=!canUndo();
 hudRender();
 if(window.View3D)View3D.sync()}

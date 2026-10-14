/* Taps, clicks, hover paths, hotkeys, undo. Aiming is two steps: pick a target, then Confirm. */
// Move zones (XCOM blue/yellow): d ≤ mob costs 1 action; mob < d ≤ 2×mob is a dash for both actions.
// Reuses reach() so any movement rule in rules.js applies to both zones.
function moveZones(u){if(!canAct(u))return {d:{},prev:{},mob:0};const m=u.mob;if(u.ap<2)return {...reach(u),mob:m};
 let R;try{u.mob=m*2;R=reach(u)}finally{u.mob=m}return {...R,mob:m}}
const moveCost=(Z,k)=>Z.d[k]>0?(Z.d[k]>Z.mob?2:1):0;
// Undo the last move while it revealed nothing and triggered nothing (no log lines, no reactions).
function tryMove(u,x,y){const Z=moveZones(u),k=x+','+y,cost=moveCost(Z,k);if(!cost)return false;
 const before={uid:u.uid,x:u.x,y:u.y,ap:u.ap,turn:S.turn,hidN:enemies().filter(e=>e.hid).length,top:S.log[0]};
 S.hpath=null;S.hcost=0;moveAlong(u,pathTo(u,x,y,Z.prev));u.ap=Math.max(0,u.ap-cost);
 S.undo=u.status==='ok'&&S.log[0]===before.top&&enemies().filter(e=>e.hid).length===before.hidN?{...before,ax:u.x,ay:u.y,aap:u.ap,atop:S.log[0]}:null;
 after();return true}
function canUndo(){const d=S&&S.undo;if(!d||S.phase!=='player'||S.over||S.turn!==d.turn||S.log[0]!==d.atop)return false;
 const u=byId(d.uid);return !!u&&u.status==='ok'&&u.x===d.ax&&u.y===d.ay&&u.ap===d.aap&&!unitAt(d.x,d.y)}
function undoMove(){if(!canUndo())return;const d=S.undo,u=byId(d.uid);u.x=d.x;u.y=d.y;u.ap=d.ap;S.undo=null;S.sel=u;S.peek=null;S.mode='move';S.tg=[];S.pick=null;S.hpath=null;render()}
// boardClick/boardHover are shared by the 2D grid and the 3D view (view3d raycasts to a tile, then calls these).
function boardClick(x,y){if(!S||S.phase!=='player'||S.over)return;
 const g=S.tg.find(t=>t.x===x&&t.y===y);
 if(g&&S.mode!=='move'&&canAct(S.sel)){if(S.pick&&S.pick.x===x&&S.pick.y===y)return exec(S.sel,S.mode,S.pick);S.pick=g;return render()}
 const u=unitAt(x,y);
 if(u&&u.side==='p'&&!u.hid)return select(u);
 if(u&&u.side==='e'&&!u.hid){S.peek=S.peek===u?null:u;S.mode='move';S.tg=[];S.pick=null;return render()}
 if(S.peek){S.peek=null;return render()}
 if(S.mode==='move'&&canAct(S.sel))tryMove(S.sel,x,y)}
$('#board').addEventListener('click',ev=>{const c=ev.target.closest('.cell');if(c)boardClick(+c.dataset.x,+c.dataset.y)});
let hoverK='',HOV=null;
function boardHover(x,y){if(!S)return;const k=x+','+y;if(k===hoverK)return;hoverK=k;
 S.hpath=null;S.hcost=0;HOV=x<0?null:{x,y};if(x>=0&&S.mode==='move'&&canAct(S.sel)&&!S.peek&&S.phase==='player'){const Z=moveZones(S.sel);if(Z.d[k]>0){S.hpath=pathTo(S.sel,x,y,Z.prev);S.hcost=moveCost(Z,k)}}
 document.body.dataset.mv=S.hcost||'';drawOver();$('#hint').textContent=hintText();if(window.View3D)View3D.hover()}
$('#board').addEventListener('mousemove',ev=>{const c=ev.target.closest('.cell');if(c)boardHover(+c.dataset.x,+c.dataset.y)});
$('#board').addEventListener('mouseleave',()=>boardHover(-1,-1));
function chooseAbility(k){const u=S.sel;if(!canAct(u)||!AB[k])return;
 if(AB[k].instant)return exec(u,k,null);
 S.pick=null;S.hpath=null;if(S.mode===k){S.mode='move';S.tg=[]}else{S.mode=k;S.tg=targetsFor(u,k)}render()}
$('#acts').addEventListener('click',ev=>{const b=ev.target.closest('button[data-a]');if(!b||b.disabled)return;chooseAbility(b.dataset.a)});
$('#odds').addEventListener('click',ev=>{if(ev.target.closest('#confirm')&&S.pick&&canAct(S.sel))exec(S.sel,S.mode,S.pick)});
$('#roster').addEventListener('click',ev=>{const b=ev.target.closest('button[data-u]');if(b)select(S.units.filter(u=>u.side==='p')[+b.dataset.u])});
$('#endBtn').addEventListener('click',()=>{const e=$('#endBtn');if(players().some(canAct)&&e.dataset.confirm!=='1'){e.dataset.confirm='1';e.textContent='Units can still act. End turn?';setTimeout(()=>{e.dataset.confirm='';e.textContent='End turn'},2500);return}
 e.dataset.confirm='';e.textContent='End turn';S.undo=null;endTurn()});
$('#undoBtn').addEventListener('click',undoMove);
// Hotkeys: 1–9 abilities · Tab/Shift+Tab next unit · Space/Enter aim then confirm · ←/→ cycle targets · Esc cancel · U undo · End end turn · C codex · I info · ? keys
function cycleUnit(dir){const P=players().filter(canAct);if(!P.length)return;const i=P.indexOf(S.sel);select(P[(i+dir+P.length)%P.length])}
function cycleTarget(dir){const T=S.tg.filter(g=>!g.area||g.t);if(!T.length)return;const i=S.pick?T.findIndex(g=>g.x===S.pick.x&&g.y===S.pick.y):-1;S.pick=T[(i+dir+T.length)%T.length];render()}
function bestTarget(){const T=S.tg.filter(g=>g.t&&g.chance!=null&&g.t.side==='e');return T.sort((a,b)=>b.chance-a.chance)[0]||S.tg[0]}
document.addEventListener('keydown',ev=>{if(ev.ctrlKey&&ev.key!=='z'||ev.metaKey||ev.altKey)return;if(/INPUT|TEXTAREA|SELECT/.test(ev.target.tagName))return;const k=ev.key;
 if(uiOpen()){if(k==='Escape'||(k==='c'||k==='C')&&$('#ui-codex')&&!$('#ui-codex').hidden||k==='?'&&$('#ui-keys')&&!$('#ui-keys').hidden){uiClose();ev.preventDefault()}return}
 if(k==='c'||k==='C'){codexOpen();return ev.preventDefault()}
 if(k==='?'){keysOpen();return ev.preventDefault()}
 if(!S||$('#modal').hidden===false||S.phase!=='player'||S.over)return;
 const busy=()=>ev.preventDefault();
 if(k==='Escape'){S.mode='move';S.tg=[];S.pick=null;S.peek=null;render();return}
 if(k==='Tab'){busy();return cycleUnit(ev.shiftKey?-1:1)}
 if(/^[1-9]$/.test(k)){const b=[...$('#acts').querySelectorAll('button[data-a]')][+k-1];if(b&&!b.disabled){busy();chooseAbility(b.dataset.a)}return}
 if(k===' '||k==='Enter'){busy();if(S.pick&&canAct(S.sel))return exec(S.sel,S.mode,S.pick);if(S.mode!=='move'&&S.tg.length){S.pick=bestTarget();render()}return}
 if(k==='ArrowRight'||k==='ArrowLeft'){if(S.mode!=='move'){busy();cycleTarget(k==='ArrowRight'?1:-1)}return}
 if(k==='u'||k==='U'||ev.ctrlKey&&k==='z'){busy();return undoMove()}
 if(k==='End'||k==='E'&&ev.shiftKey){busy();return $('#endBtn').click()}
 if(k==='i'||k==='I'){S.info=!S.info;render()}});
const KEYS=[['1–9','Pick ability'],['Tab','Next unit (Shift+Tab: back)'],['Space / Enter','Aim at best target, then confirm'],['← →','Switch target'],['Esc','Cancel'],['U','Undo last move'],['End or Shift+E','End turn'],['C','Codex'],['I','Info on/off'],['?','This list']];
function keysOpen(){const o=uiLayer('keys');o.innerHTML=`<div class="ui-card" role="dialog" aria-label="Keys"><div class="ui-head"><h2>Keys</h2><button type="button" data-ui="close" aria-label="Close">✕</button></div>
 <dl class="keys">${KEYS.map(([k,d])=>`<dt><kbd>${k}</kbd></dt><dd>${d}</dd>`).join('')}</dl><p class="muted small">Hover anything for details. On a phone, press and hold.</p></div>`}
$('#infoBtn').addEventListener('click',()=>{if(S){S.info=!S.info;render()}});
$('#syncBtn').addEventListener('click',syncDialog);
$('#codexBtn').addEventListener('click',()=>codexOpen());
$('#setBtn').addEventListener('click',settingsOpen);
$('#keysBtn').addEventListener('click',keysOpen);
$('#sheetBtn').addEventListener('click',()=>document.body.classList.toggle('sheet-min'));
if(syncCode())setSync('on');

/* Taps, clicks, hover paths. Aiming is two steps: pick a target, then Confirm. */
$('#board').addEventListener('click',ev=>{const c=ev.target.closest('.cell');if(!S||!c||S.phase!=='player'||S.over)return;
 const x=+c.dataset.x,y=+c.dataset.y,g=S.tg.find(t=>t.x===x&&t.y===y);
 if(g&&S.mode!=='move'&&canAct(S.sel)){if(S.pick&&S.pick.x===x&&S.pick.y===y)return exec(S.sel,S.mode,S.pick);S.pick=g;return render()}
 const u=unitAt(x,y);
 if(u&&u.side==='p'&&!u.hid)return select(u);
 if(u&&u.side==='e'&&!u.hid){S.peek=S.peek===u?null:u;S.mode='move';S.tg=[];S.pick=null;return render()}
 if(S.peek){S.peek=null;return render()}
 if(S.mode==='move'&&canAct(S.sel)){const R=reach(S.sel),k=x+','+y;if(R.d[k]>0){S.hpath=null;moveAlong(S.sel,pathTo(S.sel,x,y,R.prev));S.sel.ap--;after()}}});
let hoverK='';
$('#board').addEventListener('mousemove',ev=>{const c=ev.target.closest('.cell');if(!S||!c)return;const k=c.dataset.x+','+c.dataset.y;if(k===hoverK)return;hoverK=k;
 S.hpath=null;if(S.mode==='move'&&canAct(S.sel)&&!S.peek&&S.phase==='player'){const R=reach(S.sel);if(R.d[k]>0)S.hpath=pathTo(S.sel,+c.dataset.x,+c.dataset.y,R.prev)}drawOver()});
$('#board').addEventListener('mouseleave',()=>{hoverK='';if(S){S.hpath=null;drawOver()}});
$('#acts').addEventListener('click',ev=>{const b=ev.target.closest('button[data-a]');if(!b||b.disabled)return;const k=b.dataset.a,u=S.sel;
 if(AB[k].instant)return exec(u,k,null);
 S.pick=null;S.hpath=null;if(S.mode===k){S.mode='move';S.tg=[]}else{S.mode=k;S.tg=targetsFor(u,k)}render()});
$('#odds').addEventListener('click',ev=>{if(ev.target.closest('#confirm')&&S.pick&&canAct(S.sel))exec(S.sel,S.mode,S.pick)});
$('#roster').addEventListener('click',ev=>{const b=ev.target.closest('button[data-u]');if(b)select(S.units.filter(u=>u.side==='p')[+b.dataset.u])});
$('#endBtn').addEventListener('click',()=>{const e=$('#endBtn');if(players().some(canAct)&&e.dataset.confirm!=='1'){e.dataset.confirm='1';e.textContent='Units can still act. End turn?';setTimeout(()=>{e.dataset.confirm='';e.textContent='End turn'},2500);return}
 e.dataset.confirm='';e.textContent='End turn';endTurn()});
document.addEventListener('keydown',ev=>{if(!S||$('#modal').hidden===false)return;
 if(ev.key==='Escape'){S.mode='move';S.tg=[];S.pick=null;S.peek=null;render()}
 if(ev.key==='Enter'&&S.pick&&canAct(S.sel))exec(S.sel,S.mode,S.pick)});
$('#infoBtn').addEventListener('click',()=>{if(S){S.info=!S.info;render()}});
$('#syncBtn').addEventListener('click',syncDialog);
if(syncCode())setSync('on');

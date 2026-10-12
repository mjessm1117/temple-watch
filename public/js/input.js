/* Taps and clicks. */
/* ---------- Input ---------- */
$('#board').addEventListener('click',ev=>{const c=ev.target.closest('.cell');if(!c||S.phase!=='player'||S.over)return;
 const x=+c.dataset.x,y=+c.dataset.y,g=S.tg.find(t=>t.x===x&&t.y===y);
 if(g&&S.mode!=='move'&&canAct(S.sel))return exec(S.sel,S.mode,g);
 const u=unitAt(x,y);
 if(u&&u.side==='p')return select(u);
 if(u&&u.side==='e'){S.peek=S.peek===u?null:u;S.mode='move';S.tg=[];return render()}
 if(S.peek){S.peek=null;return render()}
 if(S.mode==='move'&&canAct(S.sel)){const R=reach(S.sel),k=x+','+y;if(R.d[k]>0){moveAlong(S.sel,pathTo(S.sel,x,y,R.prev));S.sel.ap--;after()}}});
$('#acts').addEventListener('click',ev=>{const b=ev.target.closest('button[data-a]');if(!b||b.disabled)return;const k=b.dataset.a,u=S.sel;
 if(AB[k].instant)return exec(u,k,null);
 if(S.mode===k){S.mode='move';S.tg=[]}else{S.mode=k;S.tg=targetsFor(u,k)}render()});
$('#roster').addEventListener('click',ev=>{const b=ev.target.closest('button[data-u]');if(b)select(S.units.filter(u=>u.side==='p')[+b.dataset.u])});
$('#endBtn').addEventListener('click',()=>{if(players().some(canAct)&&$('#endBtn').dataset.confirm!=='1'){$('#endBtn').dataset.confirm='1';$('#endBtn').textContent='Units can still act — end turn?';setTimeout(()=>{$('#endBtn').dataset.confirm='';$('#endBtn').textContent='End turn'},2500);return}
 $('#endBtn').dataset.confirm='';$('#endBtn').textContent='End turn';endTurn()});
$('#infoBtn').addEventListener('click',()=>{S.info=!S.info;render()});
$('#syncBtn').addEventListener('click',syncDialog);
if(syncCode())setSync('on');

/* XCOM HUD helpers (Coordinator, 2026-10-21): body.inbattle while a fight is on screen; portrait-phone "turn your phone" card. Styles: css/xcom.css. */
(function(){const b=document.body,m=document.getElementById('modal');
 b.insertAdjacentHTML('beforeend','<div id="rotHint" role="note"><div><b>Turn your phone sideways</b><br>Battles are built for landscape, like XCOM.</div><div class="endrow"><button type="button" id="rotOk">Play portrait</button></div></div>');
 try{if(localStorage.getItem('tw.rotok'))b.classList.add('rotok')}catch(e){}
 document.getElementById('rotOk').onclick=()=>{b.classList.add('rotok');try{localStorage.setItem('tw.rotok','1')}catch(e){}};
 const tick=()=>b.classList.toggle('inbattle',typeof S!=='undefined'&&!!S&&!S.over&&m.hidden);
 new MutationObserver(tick).observe(m,{attributes:true,attributeFilter:['hidden']});
 const _r=render;render=function(){const r=_r.apply(this,arguments);tick();return r}})();

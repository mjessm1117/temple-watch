/* Visual event bus (wave-2 contract). Logic calls fx(type,data); the view (2D or 3D) listens with onFx(fn).
   Types: move, shot, hit, miss, kill, down, ability, explode, coverBreak, turn, text.
   Old calls fx(p,txt,cls) (floating text, state.js) still work and are also sent on as fx('text',{x,y,txt,cls}).
   Loaded after ai.js so it can wrap the logic functions below and emit events without touching their files.
   If a logic file starts calling fx('shot'|'move'|… ) itself, delete the matching wrapper here to avoid doubles. */
const fxText=fx,FXL=[];
const onFx=f=>FXL.push(f);
fx=function(a,b,c){
 if(typeof a==='string'){for(const f of FXL)try{f(a,b||{})}catch(e){console.error(e)}return}
 fxText(a,b,c);if(FXL.length)fx('text',{x:a.x,y:a.y,txt:b,cls:c||''})};
(function(){const wrap=(name,pre,post)=>{const f=window[name];if(typeof f!=='function')return;
  window[name]=function(...a){const s=pre?pre(...a):null,r=f.apply(this,a);if(post)post(s,r,...a);return r}};
 // Path is shared by reference: if overwatch stops the walk early, the event's path is cut to where the unit ended.
 wrap('moveAlong',(u,path)=>{const d={u,from:{x:u.x,y:u.y},path:path.map(p=>({x:p.x,y:p.y}))};fx('move',d);return d},
  (d,r,u)=>{const i=d.path.findIndex(p=>p.x===u.x&&p.y===u.y);if(i>=0)d.path.length=i+1});
 wrap('resolve',(a,t,ch,dr,o={})=>{const d={a,t,from:{x:a.x,y:a.y},melee:!!o.melee,label:o.label||'shot'};fx('shot',d);return d},
  (d,r)=>{d.hit=r;if(!r)fx('miss',{a:d.a,t:d.t})});
 wrap('damage',t=>({hp:t.hp,st:t.status}),(s,r,t,d,src)=>{if(t.hp<s.hp)fx('hit',{t,src,hp:t.hp,d:s.hp-t.hp});
  if(t.status!==s.st&&(t.status==='dead'||t.status==='down'))fx(t.status==='dead'?'kill':'down',{t,src})});
 wrap('blast',(x,y,d,src)=>{fx('explode',{x,y,src})});
 wrap('exec',(u,k,g)=>{fx('ability',{u,k,g:g&&{x:g.x,y:g.y,t:g.t,area:g.area},from:{x:u.x,y:u.y}})});
})();

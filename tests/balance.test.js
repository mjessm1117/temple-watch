// Plays 40 games with a simple bot. Prints wins/losses; any "err" > 0 is a bug.
const {JSDOM}=require('jsdom');const fs=require('fs');
const html=fs.readFileSync(require('path').join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms));','const sleep=()=>Promise.resolve();');
let res={win:0,lose:0,err:0,end:[],dead:0};
(async()=>{for(let g=0;g<40;g++){
 const w=new JSDOM(html,{runScripts:'dangerously'}).window;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
 w.document.querySelector('[data-c="fort"]').click();
 w.eval(`window.AI=function(){for(const u of players().filter(canAct)){S.sel=u;
  const pick=k=>{if(!u.abil.includes(k))return null;const ab=AB[k];if(ab.f&&u.focus<ab.f)return null;if(ab.avail&&ab.avail(u))return null;const t=targetsFor(u,k).sort((a,b)=>b.chance-a.chance)[0];return t?[k,t]:null};
  let c=null;
  if(u.cls==='Medic'){const d=pick('heal');if(d&&d[1].t.status==='down')c=d}
  if(!c&&u.jedi){c=pick('subdue')||pick('strike');if(c&&c[0]==='strike'&&c[1].spot.path.length>3)c=pick('push')||c}
  if(!c){const s=pick('shoot');if(s&&s[1].chance>=45)c=s}
  if(!c&&u.cls==='Heavy'){const gs=targetsFor(u,'grenade').map(g=>({g,n:enemies().filter(e=>e.status==='ok'&&cheb(e,g)<=1).length,m:players().filter(p=>cheb(p,g)<=1).length})).filter(o=>o.n>=2&&!o.m);if(gs.length&&u.nades)c=['grenade',gs[0].g]}
  if(c){exec(u,c[0],c[1]);continue}
  exec(u,u.jedi?'guard':'overwatch',null)}}`);
 for(let i=0;i<30&&!w.eval('S.over');i++){try{w.eval('AI()');await w.eval('endTurn()')}catch(e){errs.push(e.stack);break}}
 if(errs.length){res.err++;console.log(errs[0])}
 const win=/held/.test(w.document.querySelector('#modal h2').textContent);res[win?'win':'lose']++;
 res.end.push(w.eval('S.turn+":"+S.cons'));res.dead+=w.eval("S.units.filter(u=>u.side==='p'&&u.status==='dead').length");w.close()}
 console.log(JSON.stringify(res))})();

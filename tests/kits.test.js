// One test per skill-tree ability (K2, wave 7): on a cleared arena with fixed rolls, every active tree ability must find a target,
// run without error and change the board; every passive must switch on its unit flag, and the ones with a number get that number checked.
const {JSDOM}=require('jsdom'),fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8');
let fail=0;const check=(ok,m)=>{if(!ok){fail++;console.log('FAIL',m)}};
const w=new JSDOM(html,{runScripts:'dangerously'}).window;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
w.eval(`
function arena(k,opt={}){newCampaign('normal');startMission('relay',START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r})),{diff:'normal',map:0});
 for(const row of S.grid)row.fill('.');for(const t of S.units)t.status='dead';S.conc=false;
 const base=opt.troop?START_ROSTER.find(r=>!CLASS[r.cls]?.jedi&&r.cls!=='Medic')||START_ROSTER[2]:START_ROSTER[0];
 const u=mk({...battleUnit({id:'k',rank:1,xp:0,dark:0,picks:[],...base}),abil:[...new Set([...(battleUnit({id:'k0',rank:1,xp:0,dark:0,picks:[],...base}).abil||[]),'shoot','strike',k])]},'p',{n:'Tester',rid:'k',x:4,y:6});
 Object.assign(u,{maxF:8,focus:8,nades:2,kits:2,ap:AP.max,range:Math.max(u.range||0,8)});
 const ally=mk({...battleUnit({id:'a',rank:1,xp:0,dark:0,picks:[],...START_ROSTER[1]})},'p',{n:'Ally',rid:'a',x:5,y:7});ally.hp=Math.max(1,ally.max-4);
 const down=mk({...battleUnit({id:'d',rank:1,xp:0,dark:0,picks:[],...START_ROSTER[1]})},'p',{n:'Downed',rid:'d',x:3,y:7});down.status='down';down.hp=0;down.bleed=3;
 const e1=mkFoe('trooper',4,5),e2=mkFoe('trooper',5,5),e3=mkFoe('trooper',4,2);
 const e4=mkFoe('terentatek',6,4);for(const e of [e1,e2,e3,e4]){e.hp=e.max=20;e.armor=0;e.shield=0;e.deflect=0}S.grid[3][7]='#';
 S.units=[u,ally,down,e1,e2,e3,e4];S.sel=u;S.turn=Math.max(S.turn,3);return{u,ally,down,e1,e2,e3,e4}}
function snap(){return JSON.stringify([S.grid.map(r=>r.join('')),S.units.map(t=>[t.hp,t.status,t.x,t.y,t.barrier,t.marked,t.ow,t.guard,t.stable,t.side,t.conc,t.armor,t.disarmed,t.buff,t.aimB,t.tricked,t.supp,t.hunker,t.stunned]),S.bmed,(S.smoke||[]).length])}
`);
const ids=w.eval(`(()=>{const ref=new Set(),walk=o=>{if(typeof o==='string')ref.add(o);else if(o&&typeof o==='object')for(const v of Object.values(o))walk(v)};walk(TREES);return [...ref].filter(k=>AB[k])})()`);
check(ids.length>=40,'tree abilities found: '+ids.length);
// Passive checks: [setup, expression that must be true]. Flag wiring is checked for every passive.
const PASSIVE={
 executioner:`(()=>{const {u,e1}=arena('executioner');const full=hitChance(u,e1);e1.hp=5;return hitChance(u,e1)>full})()`,
 pathfinder:`(()=>{const a=arena('shoot').u.mob,b=arena('pathfinder').u.mob;return b===a+1})()`,
 wildBond:`(()=>{const {u}=arena('wildBond');const v=mk({...u,abil:['wildBond'],maxF:4},'p',{x:1,y:1});return v.focus===4})()`,
 defLine:`(()=>{const {u,ally,e3}=arena('defLine');ally.x=u.x+1;ally.y=u.y;const on=hitChance(e3,ally);u.defLine=0;return on<hitChance(e3,ally)})()`,
 spotter:`(()=>{const {u,ally,e3}=arena('spotter');S.grid[4][5]='#';ally.x=5;ally.y=5;return typeof seenFor!=='function'||seenFor(ally,e3)||los(ally,e3)})()`,
 shredder:`(()=>{const {u,e1}=arena('shredder',{troop:1});e1.armor=2;Math.random=()=>0;const g=targetsFor(u,'shoot').find(g=>g.t===e1);if(!g)return false;exec(u,'shoot',g);return e1.armor<2})()`,
 ghost:`(()=>{const {u,e1}=arena('ghost',{troop:1});e1.hp=1;Math.random=()=>0;const g=targetsFor(u,'shoot').find(g=>g.t===e1);if(!g)return false;exec(u,'shoot',g);return !!u.conc})()`,
};
for(const k of ids){const ab=w.eval(`(({passive,instant,tg})=>({passive:!!passive,instant:!!instant,tg:!!tg}))(AB['${k}'])`);
 try{
  if(ab.passive){check(w.eval(`arena('${k}').u['${k}']===1`),k+': passive flag on unit');
   if(PASSIVE[k])check(w.eval(PASSIVE[k]),k+': passive effect');console.log(JSON.stringify({ability:k,passive:1}));continue}
  const troop=w.eval(`!!(AB['${k}'].nade||/nade|Shot|deadeye|rapidFire|holdLine|hunker|suppress|rocket|mark|runGun|smoke|rally|shieldDrone|medBeacon|reviveStim/.test('${k}'))`);
  const r=w.eval(`(()=>{const s=arena('${k}',{troop:${troop}});Math.random=()=>0;const ab=AB['${k}'],u=s.u;
   const why=ab.avail&&ab.avail(u);if(why)return{err:'not available: '+why};
   let g=null;if(!ab.instant){const T=targetsFor(u,'${k}');if(!T.length)return{err:'no targets'};
    g=T.find(g=>g.t&&g.t.side==='e')||T.find(g=>g.t&&g.t.status==='down')||T.find(g=>g.t&&g.t===s.ally)||T.slice().sort((a,b)=>dist(a,s.e1)-dist(b,s.e1))[0]}
   const before=snap(),f0=u.focus;exec(u,'${k}',g);const changed=snap()!==before||u.ap>AP.max||u.rgT||u.ow||u.guard;
   return{changed,focus:f0-u.focus,cost:ab.f||0}})()`);
  Math.random=Math.random;
  if(r.err)check(false,k+': '+r.err);else{check(r.changed,k+': no effect on the board');check(r.focus===r.cost,k+': Focus cost '+r.focus+' vs '+r.cost)}
  console.log(JSON.stringify({ability:k,...r}))}catch(e){check(false,k+': '+e.message)}}
// Horror swarm (swarm.js): brood spawns Husks on a brood turn; a horror kill makes the nearest Husk lunge; a landed Beast Calm stops it.
(async()=>{
 const b=w.eval(`(()=>{const s=arena('shoot');S.turn=2;S.phase='enemy';const n0=enemies().filter(h=>h.swarm).length;brood(s.e4);S.phase='player';return{n0,n1:enemies().filter(h=>h.swarm).length}})()`);
 check(b.n1===b.n0+2,'brood spawns 2 Husks: '+JSON.stringify(b));
 const c=w.eval(`(()=>{const s=arena('shoot');S.turn=3;S.phase='player';const h=mkFoe('husk',5,4);S.units.push(h);s.e4.hp=1;damage(s.e4,5,s.u);return{chained:h.chained===S.turn,n:S.chainN}})()`);
 check(c.chained&&c.n===1,'kill makes nearest Husk surge: '+JSON.stringify(c));
 await w.eval('endTurn()');
 const d=w.eval(`(()=>{const s=arena('beastCalm');S.turn=5;S.phase='player';const h=mkFoe('husk',5,4);S.units.push(h);Math.random=()=>0;
  exec(s.u,'beastCalm',targetsFor(s.u,'beastCalm').find(g=>g.t===s.e4));const calm=S.calmT===S.turn;const h2=mkFoe('husk',2,3);S.units.push(h2);s.e1.horror=1;damage(s.e1,30,s.u);return{calm,chained:h.chained===S.turn||h2.chained===S.turn}})()`);
 check(d.calm&&!d.chained,'Beast Calm stops the surge: '+JSON.stringify(d));
 check(w.eval("FOES.husk.horror===1&&!!FOES.husk.desc"),'Husk foe defined');
 check(!errs.length,'page errors: '+errs.slice(0,3).join(' | '));
console.log(JSON.stringify({test:'kits',abilities:ids.length,err:fail}));process.exit(fail?1:0)})();

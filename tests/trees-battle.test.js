// Rank-7 squads covering all 16 specs play bot games: no errors, power levels and spec traits active.
const {JSDOM}=require('jsdom'),fs=require('fs'),path=require('path');
const html=fs.readFileSync(path.join(__dirname,'..','dist','temple-watch.html'),'utf8').replace('const sleep=ms=>new Promise(r=>setTimeout(r,ms/((window.SETTINGS&&SETTINGS.speed)||1)));','const sleep=()=>Promise.resolve();');
const bot=fs.readFileSync(path.join(__dirname,'bot.js'),'utf8');let fail=0;const check=(ok,m)=>{if(!ok){fail++;console.log('FAIL',m)}};
const SQUADS=[['Guardian','protector','Consular','sage','Sentinel','watchman','Soldier','sergeant','Scout','sniper','Medic','surgeon'],
 ['Guardian','weaponMaster','Consular','shadow','Sentinel','bladeDancer','Soldier','vanguard','Scout','infiltrator','Heavy','demolitionist'],
 ['Wayseeker','beastwarden','Wayseeker','earthshaper','Medic','tech','Heavy','bulwark','Soldier','sergeant','Scout','sniper']];
(async()=>{const seen={};
 for(const [si,sq] of SQUADS.entries())for(const [mission] of [['relay'],['shrine'],['dock']]){
  const w=new JSDOM(html,{runScripts:'dangerously'}).window;const errs=[];w.addEventListener('error',e=>errs.push(e.message));
  try{w.eval(bot);const info=w.eval(`(()=>{newCampaign('normal');C.era=3;C.wings.training=2;ensureTemple();const sq=${JSON.stringify(sq)},L=[];
    for(let i=0;i<sq.length;i+=2){const r={id:'t'+i,n:sq[i+1],cls:sq[i],rank:7,xp:800,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0,col:'#62b3ff'};
     C.roster.push(r);ensureTemple();let p;while((p=pendingRank(r))){const o=treeOpts(r,p),sig=TREES[r.cls].specs[sq[i+1]].sig;pickAbility(r.id,p===3?sig:o[(i+p)%2])}
     const alt=xtrainClasses(r)[0];setAlt(r.id,alt);for(const k of xtrainPool(r))borrowSkill(r.id,k);L.push(battleUnit(r))}
    startMission('${mission}',L,{diff:'normal',map:0});return L.map(u=>({s:u.specT,pw:Math.max(...Object.values(u.pw)),abil:u.abil.length}))})()`);
   for(const u of info){seen[u.s]=1;check(u.pw===4,'signature at Power IV: '+JSON.stringify(u))}
   for(let i=0;i<40&&!w.eval('S.over');i++){w.eval('AI()');await w.eval('endTurn()')}
   if(!w.eval('S.over'))errs.push('mission never ended')}catch(e){errs.push(e.stack)}
  if(errs.length){fail++;console.log('FAIL',mission,si,errs[0])}
  console.log(JSON.stringify({squad:si,mission,win:w.eval('S.win')?1:0,turns:w.eval('S.turn')}));w.close()}
 check(Object.keys(seen).length===16,'all 16 specs fielded: '+Object.keys(seen).join());
 // Direct hook checks.
 const w=new JSDOM(html,{runScripts:'dangerously'}).window;w.eval(bot);
 const r=w.eval(`(()=>{newCampaign('normal');startMission('relay',START_ROSTER.map((r,i)=>battleUnit({id:'u'+i,rank:1,xp:0,dark:0,picks:[],...r})),{diff:'normal',map:0});
  const P=S.units.filter(u=>u.side==='p'),E=S.units.filter(u=>u.side==='e');const a=P[0],b=P[1],e=E[0];
  a.specT='weaponMaster';e.hp=20;e.max=20;e.armor=0;e.shield=0;const h0=e.hp;damage(e,3,a);const plain=h0-e.hp;
  e.hp=1;damage(e,3,a);const mom=a.mom||0;
  b.specT='protector';b.status='ok';a.x=b.x+1;a.y=b.y;const E2=E[1];a.hp=10;a.max=10;a.armor=0;damage(a,3,E2);const wall=10-a.hp;
  return{plain,mom,wall}})()`);
 check(r.plain===3&&r.mom===1,'Momentum after a kill: '+JSON.stringify(r));check(r.wall===2,'Shield Wall soaks 1: '+JSON.stringify(r));
 console.log(JSON.stringify({test:'trees-battle',err:fail}));process.exit(fail?1:0)})();

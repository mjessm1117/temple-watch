// Skill trees: every id exists with a desc, specs well-formed, picks/specs/cross-training work, old saves respec cleanly.
const {JSDOM}=require('jsdom'),fs=require('fs');
const html=fs.readFileSync(__dirname+'/../dist/temple-watch.html','utf8');
const dom=new JSDOM(html,{runScripts:'dangerously',pretendToBeVisual:true,url:'http://localhost/'});const w=dom.window;
let fail=0;const check=(ok,m)=>{if(!ok){fail++;console.log('FAIL',m)}};
setTimeout(()=>{try{
 const bad=w.eval(`(()=>{const o=[];for(const [c,T] of Object.entries(TREES)){if(!CLASS[c])o.push('class '+c);const all=[];
  for(const k of [1,2]){if(T.trunk[k].length!==3)o.push(c+' trunk '+k);all.push(...T.trunk[k])}
  const S=Object.values(T.specs);if(S.length!==2)o.push(c+' spec count');if(S[0].sig===S[1].sig)o.push(c+' same sig');
  for(const s of S){if(!s.n||!s.desc)o.push(c+' spec text');const ids=[s.sig];for(const k of [4,5,6,7]){if(!s[k]||s[k].length!==3||new Set(s[k]).size!==3)o.push(c+' '+s.n+' r'+k);ids.push(...s[k])}
   for(const k of ids)if(all.includes(k)||ids.indexOf(k)!==ids.lastIndexOf(k))o.push(c+' '+s.n+' dup '+k)}
  for(const s of S)for(const k of [s.sig,...[4,5,6,7].flatMap(r=>s[r]),...all]){const a=PERKS[k]||AB[k];if(!a)o.push('missing '+k);else if(!(a.desc||a.tip))o.push('no desc '+k)}}
  return o})()`);
 check(!bad.length,'tree data: '+bad.join(', '));
 // Play it: fresh campaign, rank a Guardian to 7, pick through, cross-train.
 const r=w.eval(`(()=>{newCampaign&&newCampaign('normal');ensureTemple();const r=C.roster.find(r=>r.cls==='Guardian');r.xp=800;promote(r);
  const log=[];let p;while((p=pendingRank(r))){const o=treeOpts(r,p);pickAbility(r.id,o[p===3?1:0]);log.push(p+':'+r.picks[p-1])}
  C.wings.training=2;setAlt(r.id,'Soldier');const pool=xtrainPool(r);borrowSkill(r.id,pool[0]);borrowSkill(r.id,pool[1]);borrowSkill(r.id,pool[2]);
  const u=battleUnit(r);return{spec:r.spec,picks:r.picks,borrow:r.borrow,pool,abil:u.abil,n:r.picks.length}})()`);
 check(r.n===7&&r.spec==='weaponMaster','pick through to rank 7: '+JSON.stringify(r));
 check(r.borrow.length===2&&!r.pool.includes('suppress'),'Jedi borrows 2, no blaster skills: '+JSON.stringify(r.pool));
 check(r.abil.includes('sweep')&&r.abil.includes('hunker'),'battle unit has sig + borrowed ability');
 const t=w.eval(`(()=>{const r=C.roster.find(r=>!isJedi(r));r.xp=200;promote(r);return xtrainClasses(r).some(c=>CLASS[c].jedi)})()`);
 check(!t,'troops cannot cross-train into Jedi');
 // Old save: rank-5 Guardian with the old flat picks → keeps trunk, respecs from rank 3.
 const o=w.eval(`(()=>{const r={...C.roster[0],id:'old1',cls:'Guardian',rank:5,xp:300,picks:['defLine','reflectM','collapse','gIron','gBulwark'],spec:undefined};C.roster.push(r);C.treeV=1;ensureTemple();return{picks:r.picks,spec:r.spec,pend:pendingRank(r)}})()`);
 check(o.picks.join()==='defLine,reflectM'&&o.pend===3,'old save respec: '+JSON.stringify(o));
 const j=w.eval(`(()=>{const r={...C.roster[0],id:'old2',cls:'Guardian',rank:3,picks:['defLine','reflectM','sweep']};C.roster.push(r);ensureTemple();return r.spec})()`);
 check(j==='weaponMaster','preset Johun keeps Weapon Master');
 // Tree screen: open, pick R1 by clicking, rank 3 needs a confirm, other branch closes.
 const ts=w.eval(`(()=>{newCampaign('normal');ensureTemple();const r=C.roster.find(r=>r.cls==='Consular');r.picks=[];r.spec=null;r.xp=170;promote(r);treeScreen(r.id);
  const m=document.querySelector('#modal'),click=s=>m.querySelector(s).click(),out={};
  out.open=m.querySelectorAll('.tn.open').length;click('.tn.open');out.r1=r.picks.length;click('.tn.open');click('.tn.open');out.r2=r.picks.length;
  click('.tn.open');out.wait=r.picks.length;out.conf=!!m.querySelector('[data-act^="tconf"]');click('[data-act^="tconf"]');out.spec=r.spec;
  out.closed=m.querySelectorAll('.tt-spec.off').length;out.chips=m.querySelectorAll('.chip').length;out.taken=m.querySelectorAll('.tn.taken').length;
  click('[data-act="tclose"]');return out})()`);
 check(ts.open===3&&ts.r1===1&&ts.r2===2&&ts.wait===2&&ts.conf&&ts.spec&&ts.closed===1&&ts.taken===3&&ts.chips>10,'tree screen flow: '+JSON.stringify(ts));
 // Balance band: every rank-7 build's Power within ±8% of the median.
 const band=w.eval(`(()=>{C.era=3;const v=[];for(const [cls,T] of Object.entries(TREES))for(const [sid,s] of Object.entries(T.specs))for(const o of [0,1]){
  const r={id:'bb'+cls+sid+o,n:'x',cls,rank:7,xp:800,dark:0,picks:[],pick:0,wound:0,status:'active',kills:0,missions:0};C.roster.push(r);ensureTemple();
  let p;while((p=pendingRank(r)))pickAbility(r.id,p===3?s.sig:treeOpts(r,p)[o]);v.push(unitPower(r))}
  v.sort((a,b)=>a-b);return{min:v[0],max:v[v.length-1],med:v[v.length>>1]}})()`);
 check(band.min>=band.med*.92&&band.max<=band.med*1.08,'R7 Power band: '+JSON.stringify(band));console.log('R7 power',JSON.stringify(band));
 const h=w.eval(`(()=>{ARM=C.roster[0].id;return armoryTab()})()`);
 check(h.includes('class="specs"')&&h.includes('Cross-training'),'Armory shows specs + cross-training');
}catch(e){fail++;console.log('FAIL',e.message)}
 console.log(JSON.stringify({test:'trees',err:fail}));process.exit(fail?1:0)},500);

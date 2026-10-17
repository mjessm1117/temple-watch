// Skill trees: every id exists with a desc, specs well-formed, picks/specs/cross-training work, old saves respec cleanly.
const {JSDOM}=require('jsdom'),fs=require('fs');
const html=fs.readFileSync(__dirname+'/../dist/temple-watch.html','utf8');
const dom=new JSDOM(html,{runScripts:'dangerously',pretendToBeVisual:true,url:'http://localhost/'});const w=dom.window;
let fail=0;const check=(ok,m)=>{if(!ok){fail++;console.log('FAIL',m)}};
setTimeout(()=>{try{
 const bad=w.eval(`(()=>{const o=[];for(const [c,T] of Object.entries(TREES)){if(!CLASS[c])o.push('class '+c);const all=[];
  for(const k of [1,2]){if(T.trunk[k].length!==2)o.push(c+' trunk '+k);all.push(...T.trunk[k])}
  const S=Object.values(T.specs);if(S.length!==2)o.push(c+' spec count');if(S[0].sig===S[1].sig)o.push(c+' same sig');
  for(const s of S){if(!s.n||!s.desc)o.push(c+' spec text');const ids=[s.sig];for(const k of [4,5,6,7]){if(!s[k]||s[k].length!==2||s[k][0]===s[k][1])o.push(c+' '+s.n+' r'+k);ids.push(...s[k])}
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
 const h=w.eval(`(()=>{ARM=C.roster[0].id;return armoryTab()})()`);
 check(h.includes('class="specs"')&&h.includes('Cross-training'),'Armory shows specs + cross-training');
}catch(e){fail++;console.log('FAIL',e.message)}
 console.log(JSON.stringify({test:'trees',err:fail}));process.exit(fail?1:0)},500);

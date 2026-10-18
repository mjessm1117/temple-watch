/* Power levels + spec traits (Chat F · Skill Trees). Spec: docs/specs/trees.md §Power.
   Skill power (I–IV): every tree skill starts at I and gains a level every 2 ranks after you learn it (max III); your spec's
   signature skill gets +1 (max IV). Each level above I: +1 damage, +1 healing, +5% hit chance (ability targets).
   Unit Power: one number summing a unit's battle strength, shown at the Temple and in squad select.
   Spec traits (SPEC_TRAITS, data-trees.js) are applied here by wrapping odds/damage/exec/startPlayerTurn. Loads after fx.js. */
const ROMAN=['','I','II','III','IV'];
// Tree skills a roster unit knows, with the rank each was learned at.
function learnedAt(r){const o={};(r.picks||[]).forEach((k,i)=>{o[k]=i+1});(r.borrow||[]).forEach((k,i)=>{o[k]=XTRAIN.minRank[i]||4});
 (r.extra||[]).forEach(k=>{o[k]=typeof nodeRank==='function'?nodeRank(r,k)||1:1});return o}
function skillPower(r,k){const L=learnedAt(r)[k];if(!L)return 0;const s=specOf(r);
 return Math.min(3,1+Math.floor(Math.max(0,r.rank-L)/2))+(s&&s.sig===k?1:0)}
// Called from templeMods (battleUnit): power map + spec trait.
function treeMods(u,r){u.pw={};for(const k of Object.keys(learnedAt(r)))u.pw[k]=skillPower(r,k);u.specT=r.spec||null;
 const T=r.spec&&SPEC_TRAITS[r.spec];if(T&&T.mod)addMod(u,T.mod);
 // Skill effects (data-skills.js): sum every learned perk's fx; aimVs merges into the engine's per-tag aim table.
 u.fx={};for(const [f,v] of Object.entries((T&&T.fx)||{}))u.fx[f]=(u.fx[f]||0)+v;
 for(const k of Object.keys(learnedAt(r))){const P=PERKS[k];if(!P)continue;for(const [f,v] of Object.entries(P.fx||{}))u.fx[f]=(u.fx[f]||0)+v;
  if(P.aimVs){u.aimVs={...(u.aimVs||{})};for(const [g,v] of Object.entries(P.aimVs))u.aimVs[g]=(u.aimVs[g]||0)+v}}return u}
// Weights (POWER_W, data-trees.js): range, medkits and grenades count, so troops aren't undersold next to Jedi Focus/deflect.
function unitPower(r){const u=battleUnit(r),W=POWER_W,d=(u.dmg[0]+u.dmg[1])/2,pw=Object.values(u.pw||{}).reduce((s,v)=>s+v,0);
 return Math.round(u.hp*W.hp+(u.aim-50)*W.aim+d*W.dmg+(u.armor||0)*W.armor+(u.crit||0)*W.crit+(u.maxF||0)*W.focus+(u.mob||0)*W.mob+(u.deflect||0)*W.deflect
  +Math.min(u.range||0,W.rangeCap)*W.range+(u.kits||0)*W.kit+(u.nades||0)*W.nade+pw*W.skill+Object.keys(u.pw||{}).filter(k=>AB[k]&&!AB[k].passive).length*W.active+(r.spec?W.spec:0)
  +((u.dodge||0)+((u.fx&&u.fx.dodge)||0))*W.dodge+Object.keys(u.fx||{}).filter(k=>k!=='dodge').length*W.fx)}
const pwTag=n=>n>1?` <b class="pw" title="Power ${ROMAN[n]}">${ROMAN[n]}</b>`:'';

// --- engine hooks -------------------------------------------------------------------------------
const SPT=(u,id)=>u&&u.side==='p'&&u.specT===id;
const nearSpec=(t,id,r)=>S.units.some(p=>p!==t&&SPT(p,id)&&p.status==='ok'&&cheb(p,t)<=r);
// Ability targets: +5% per power level above I (enemy targets with a real roll only).
const _targetsFor=targetsFor;
targetsFor=function(u,k){S.inTg=1;let L;try{L=_targetsFor(u,k)}finally{S.inTg=0}const p=(u.pw&&u.pw[k]||1)-1;
 if(p>0)for(const g of L)if(g.t&&g.t.side==='e'&&g.chance>0&&g.chance<100)g.chance=Math.min(95,g.chance+5*p);return L};
// Odds panel lines: spec trait aim bonuses, and the power line while aiming an ability (tg already adds it to the roll).
const _odds=odds;
odds=function(a,t,o){const r=_odds(a,t,o);if(!a||a.side!=='p'||!t||t.side!=='e')return r;const L=r.lines,add=(n,v)=>v&&L.push([n,v]);
 const tg=tagsOf(t),d=dist(a,t);
 if(SPT(a,'watchman')&&(tg.includes('elite')||tg.includes('boss')))add('Watchman: big game',10);
 if(SPT(a,'beastwarden')&&(tg.includes('creature')||tg.includes('horror')))add('Beast lore',15);
 if(SPT(a,'vanguard')&&d<=4)add('Close assault',15);
 if(SPT(a,'sniper')&&d>=7)add('Patience',10);
 if(SPT(a,'infiltrator')&&!a.opened)add('Opening strike',20);
 if(nearSpec(a,'sergeant',3)||SPT(a,'sergeant'))add('Sergeant',5);
 const k=!S.inTg&&S.mode,p=k&&a.pw?(a.pw[k]||1)-1:0;if(p>0)add('Power '+ROMAN[p+1],5*p);
 return{lines:L,total:Math.max(5,Math.min(95,Math.round(L.reduce((s,l)=>s+l[1],0))))}};
// Enemies shooting at units next to a Bulwark: −10.
const _odds2=odds;
odds=function(a,t,o){const r=_odds2(a,t,o);if(a&&a.side==='e'&&t&&t.side==='p'&&nearSpec(t,'bulwark',1)){r.lines.push(['Covered by Bulwark',-10]);r.total=Math.max(5,r.total-10)}return r};
// Damage: power bonus, trait bonuses, Shield Wall, kill triggers.
const _damage=damage;
damage=function(t,d,src,...x){
 if(src&&src.side==='p'&&t.side==='e'&&d>0){d+=S.pw||0;const tg=tagsOf(t),dd=dist(src,t);
  if(SPT(src,'weaponMaster'))d+=src.mom||0;
  if(SPT(src,'shadow')&&S.forceAct)d+=t.status==='stunned'?2:1;
  if(SPT(src,'earthshaper')&&S.forceAct)d+=t.armor||0;
  if(SPT(src,'beastwarden')&&(tg.includes('creature')||tg.includes('horror')))d+=2;
  if(SPT(src,'vanguard')&&dd<=4)d+=1;
  if(SPT(src,'sniper')&&dd>=7)d+=1;
  if(SPT(src,'infiltrator')&&!src.opened){d+=2;src.opened=1;fx(src,'OPENER')}
  if(SPT(src,'demolitionist')&&['grenade','rocket','ionNade'].includes(S.curK))d+=1}
 if(t.side==='p'&&d>1&&src&&src.side==='e'&&nearSpec(t,'protector',1)){d--;fx(t,'SHIELD WALL','defl')}
 const was=alive(t)&&t.status!=='dead';_damage(t,d,src,...x);
 if(was&&t.status==='dead'&&src&&src.side==='p'){
  if(SPT(src,'weaponMaster')&&(src.mom||0)<3){src.mom=(src.mom||0)+1;fx(src,'MOMENTUM')}
  if(SPT(src,'watchman')&&src.maxF){src.focus=Math.min(src.maxF,(src.focus||0)+1);fx(src,'+1 FOCUS')}
  if(SPT(src,'bladeDancer')&&(src.flow||0)<2){src.flow=(src.flow||0)+1;src.mob++;fx(src,'FLOW')}}};
// Abilities: set the power bonus during the ability; extra healing from power, Sage and Field Surgeon.
const _exec=exec;
exec=function(u,k,g,...x){const pw=u&&u.side==='p'&&u.pw?(u.pw[k]||1)-1:0;
 const before=new Map(S.units.filter(p=>p.side==='p').map(p=>[p,p.status==='ok'?p.hp:null]));
 S.pw=pw;S.curK=k;let r;try{r=_exec(u,k,g,...x)}finally{S.pw=0;S.curK=null}
 const extra=pw+(SPT(u,'sage')?1:0)+(SPT(u,'surgeon')?2:0)+fxv(u,'healPlus');let healed=0;
 if(extra)for(const [p,h] of before)if(h!=null&&p.status==='ok'&&p.hp>h&&p.hp<p.max){const n=Math.min(extra,p.max-p.hp);p.hp+=n;fx(p,'+'+n,'heal');healed=1}
 if(healed&&SPT(u,'sage')&&u.maxF)u.focus=Math.min(u.maxF,u.focus+1);
 return r};
// Combat Tech: start of each player turn, patch 1 HP on self and adjacent allies.
const _spt=startPlayerTurn;
startPlayerTurn=function(...x){if(S&&S.units)for(const u of S.units)if(SPT(u,'tech')&&u.status==='ok')for(const p of S.units)
 if(p.side==='p'&&p.status==='ok'&&cheb(u,p)<=1&&p.hp<p.max){p.hp++;fx(p,'+1','heal')}
 return _spt(...x)};

// --- skill effects (u.fx) + bond techniques (u.pairs) · Chat Q ------------------------------------
// Numbers come from PERKS[k].fx (data-skills.js). Kills can refund actions ("chain"): that is how a top Guardian rampages and a sniper streaks.
const fxv=(u,k)=>(u&&u.fx&&u.fx[k])||0;
const pairsT=(u,t)=>(u&&u.pairs||[]).filter(p=>p.t===t).map(p=>S.units.find(x=>x.uid===p.uid)).filter(p=>p&&p.status==='ok');
const exposed=(t,a)=>{try{return coverVal(t,a)===0}catch(e){return false}};
const eliteT=t=>{const g=tagsOf(t);return g.includes('elite')||g.includes('boss')||!!t.boss};
odds=(o=>function(a,t,op){const r=o(a,t,op);if(!a||!t)return r;const L=r.lines,add=(n,v)=>{if(v)L.push([n,v])};
 if(a.side==='p'&&t.side==='e'){const d=dist(a,t);
  if(!a.fxOpened)add('Opening',fxv(a,'openAim'));if(a.hp*2<=a.max)add('Hurt and angry',fxv(a,'lowAim'));
  if(d<=4)add('Close range',fxv(a,'closeAim'));if(d>=7)add('Long range',fxv(a,'farAim'));if(exposed(t,a))add('No cover',fxv(a,'expAim'));
  if(eliteT(t))add('Big target',fxv(a,'eliteAim'));if(fxv(a,'adjAim')&&S.units.some(p=>p!==a&&p.side==='p'&&p.status==='ok'&&cheb(p,a)<=1))add('Pack',fxv(a,'adjAim'));
  const au=S.units.filter(p=>p.side==='p'&&p.status==='ok'&&fxv(p,'auraAim')&&cheb(p,a)<=3).reduce((m,p)=>Math.max(m,fxv(p,'auraAim')),0);add('Inspired',au);
  if(pairsT(a,'crossfire').some(p=>cheb(p,t)<=4))add('Crossfire',15)}
 if(a.side==='e'&&t.side==='p'){add('Dodge',-(fxv(t,'dodge')+(t.dodge||0)));
  add('Sheltered',-S.units.filter(p=>p!==t&&p.side==='p'&&p.status==='ok'&&fxv(p,'shelter')&&cheb(p,t)<=1).reduce((m,p)=>Math.max(m,fxv(p,'shelter')),0));if(pairsT(t,'backToBack').some(p=>cheb(p,t)<=1))add('Back to back',-15)}
 return{lines:L,total:Math.max(5,Math.min(95,Math.round(L.reduce((s,l)=>s+l[1],0))))}})(odds);
damage=(o=>function(t,d,src,...x){
 if(src&&src.side==='p'&&t.side==='e'&&d>0){const dd=dist(src,t);
  if(!src.fxOpened){d+=fxv(src,'openDmg');src.fxOpened=1}if(src.hp*2<=src.max)d+=fxv(src,'lowDmg');
  if(dd<=4)d+=fxv(src,'closeDmg');if(dd>=7)d+=fxv(src,'farDmg');if(exposed(t,src))d+=fxv(src,'expDmg');if(eliteT(t))d+=fxv(src,'eliteDmg');
  d+=src.fxMom||0;if(['grenade','rocket','ionNade'].includes(S.curK))d+=fxv(src,'nadeDmg')}
 if(t.side==='p'&&src&&src.side==='e'&&d>1){const w=Math.min(2,S.units.filter(p=>p!==t&&p.side==='p'&&p.status==='ok'&&fxv(p,'ward')&&cheb(p,t)<=1).length);if(w){d=Math.max(1,d-w);fx(t,'WARD','defl')}}
 // Last stand: own skill, or a Guardian Angel partner within 4.
 if(t.side==='p'&&t.status==='ok'&&d>0){const eff=t.armor?Math.max(1,d-t.armor):d;
  if(eff>=t.hp&&t.hp>1){const ls=fxv(t,'lastStand')&&!t.lsUsed,ga=!ls&&!t.gaUsed&&pairsT(t,'angel').some(p=>cheb(p,t)<=4);
   if(ls||ga){if(ls)t.lsUsed=1;else t.gaUsed=1;d=t.hp-1+(t.armor||0);fx(t,ls?'LAST STAND':'GUARDIAN ANGEL','defl');log(`${t.n} refuses to fall.`,'good')}}}
 const was=alive(t)&&t.status!=='dead'&&t.status!=='down';o(t,d,src,...x);
 // Riposte: a melee hit on someone with Counter costs the attacker.
 if(t.side==='p'&&src&&src.side==='e'&&alive(src)&&src.status!=='dead'&&cheb(src,t)<=1&&fxv(t,'riposte')&&t.status==='ok'){fx(t,'COUNTER');o(src,fxv(t,'riposte'),t)}
 if(was&&src&&src.side==='p'&&t.side==='e'&&(t.status==='dead'||t.status==='down'||!alive(t)))fxKill(src,t)
 // Melee answer (MELEE, data-skills.js): both sides. A Force user hit in melee by a Force user always strikes back (blade lock);
 // other melee fighters strike back MELEE.counter% of the time. Never during Force powers, never chains (S.inCtr).
 if(!S.inCtr&&!S.forceAct&&src&&src.side!==t.side&&src.range<2&&t.range<2&&cheb(src,t)<=1&&t.status==='ok'&&alive(t)&&alive(src)&&src.status!=='dead'){
  const force=u=>u.side==='p'?!!u.jedi:tagsOf(u).includes('force'),lock=force(src)&&force(t);
  if(rnd(lock?MELEE.lock:MELEE.counter)){S.inCtr=1;try{fx(t,lock?'BLADE LOCK':'COUNTER','defl');log(`${t.n} ${lock?'locks blades with':'strikes back at'} ${src.n}.`);o(src,Math.max(1,t.dmg[0]),t)}finally{S.inCtr=0}}}})(damage);
function fxKill(u,t){const melee=cheb(u,t)<=1,far=dist(u,t)>=SKILL.chainR;
 if(fxv(u,'killFocus')&&u.maxF)u.focus=Math.min(u.maxF,(u.focus||0)+fxv(u,'killFocus'));
 if(fxv(u,'killHeal')&&u.hp<u.max){const n=Math.min(fxv(u,'killHeal'),u.max-u.hp);u.hp+=n;fx(u,'+'+n,'heal')}
 if(fxv(u,'killMove')&&(u.fxMove||0)<2){u.fxMove=(u.fxMove||0)+1;u.mob++}
 if(fxv(u,'killDmg')&&(u.fxMom||0)<3)u.fxMom=(u.fxMom||0)+1;
 // Chains: refunded after the action resolves (exec wrapper below), so the turn really extends.
 const n=fxv(u,'chain')+(melee?fxv(u,'chainMelee'):0)+(far?fxv(u,'chainFar'):0)+(u.rhythm?1:0);if(n>0&&(u.chainUsed||0)<n)S.chainUnit=u;
 for(const p of S.units)if(p!==u&&p.side==='p'&&p.status==='ok'&&(p.pairs||[]).some(q=>q.t==='rhythm'&&q.uid===u.uid)){
  if(p.hp<p.max){p.hp++;fx(p,'+1','heal')}if(p.maxF)p.focus=Math.min(p.maxF,(p.focus||0)+1);p.rhythm=1}}
exec=(o=>function(u,k,g,...x){S.chainUnit=null;const r=o(u,k,g,...x);const c=S.chainUnit;S.chainUnit=null;
 if(c&&c===u&&u.status==='ok'&&!S.over&&S.phase==='player'){u.chainUsed=(u.chainUsed||0)+1;if(u.rhythm)u.rhythm=0;u.ap=Math.min(2,u.ap+1);
  fx(u,u.chainUsed>1?`CHAIN ×${u.chainUsed}`:'CHAIN!','heal');log(`${u.n} keeps going: +1 action.`,'good');S.sel=u;render()}return r})(exec);
startPlayerTurn=(o=>function(...x){if(S&&S.units)for(const u of S.units)if(u.side==='p'){u.chainUsed=0;u.rhythm=0;
 if(u.status==='ok'&&fxv(u,'regen')&&u.hp<u.max){const n=Math.min(fxv(u,'regen'),u.max-u.hp);u.hp+=n;fx(u,'+'+n,'heal')}}return o(...x)})(startPlayerTurn);
startMission=(o=>function(id,sq,op){o(id,sq,op);if(S&&S.units)for(const u of S.units)if(u.side==='p'&&fxv(u,'focusStart')&&u.maxF)u.focus=Math.min(u.maxF,(u.focus||0)+fxv(u,'focusStart'))})(startMission);

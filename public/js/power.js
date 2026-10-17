/* Power levels + spec traits (Chat F · Skill Trees). Spec: docs/specs/trees.md §Power.
   Skill power (I–IV): every tree skill starts at I and gains a level every 2 ranks after you learn it (max III); your spec's
   signature skill gets +1 (max IV). Each level above I: +1 damage, +1 healing, +5% hit chance (ability targets).
   Unit Power: one number summing a unit's battle strength, shown at the Temple and in squad select.
   Spec traits (SPEC_TRAITS, data-trees.js) are applied here by wrapping odds/damage/exec/startPlayerTurn. Loads after fx.js. */
const ROMAN=['','I','II','III','IV'];
// Tree skills a roster unit knows, with the rank each was learned at.
function learnedAt(r){const o={};(r.picks||[]).forEach((k,i)=>{o[k]=i+1});(r.borrow||[]).forEach((k,i)=>{o[k]=XTRAIN.minRank[i]||4});return o}
function skillPower(r,k){const L=learnedAt(r)[k];if(!L)return 0;const s=specOf(r);
 return Math.min(3,1+Math.floor(Math.max(0,r.rank-L)/2))+(s&&s.sig===k?1:0)}
// Called from templeMods (battleUnit): power map + spec trait.
function treeMods(u,r){u.pw={};for(const k of Object.keys(learnedAt(r)))u.pw[k]=skillPower(r,k);u.specT=r.spec||null;
 const T=r.spec&&SPEC_TRAITS[r.spec];if(T&&T.mod)addMod(u,T.mod);return u}
function unitPower(r){const u=battleUnit(r),d=(u.dmg[0]+u.dmg[1])/2,pw=Object.values(u.pw||{}).reduce((s,v)=>s+v,0);
 return Math.round(u.hp*2+(u.aim-50)/2+d*3+(u.armor||0)*5+(u.crit||0)/5+(u.maxF||0)*2+(u.mob||0)+(u.deflect||0)/5+pw*2+(r.spec?4:0))}
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
 const extra=pw+(SPT(u,'sage')?1:0)+(SPT(u,'surgeon')?2:0);let healed=0;
 if(extra)for(const [p,h] of before)if(h!=null&&p.status==='ok'&&p.hp>h&&p.hp<p.max){const n=Math.min(extra,p.max-p.hp);p.hp+=n;fx(p,'+'+n,'heal');healed=1}
 if(healed&&SPT(u,'sage')&&u.maxF)u.focus=Math.min(u.maxF,u.focus+1);
 return r};
// Combat Tech: start of each player turn, patch 1 HP on self and adjacent allies.
const _spt=startPlayerTurn;
startPlayerTurn=function(...x){if(S&&S.units)for(const u of S.units)if(SPT(u,'tech')&&u.status==='ok')for(const p of S.units)
 if(p.side==='p'&&p.status==='ok'&&cheb(u,p)<=1&&p.hp<p.max){p.hp++;fx(p,'+1','heal')}
 return _spt(...x)};

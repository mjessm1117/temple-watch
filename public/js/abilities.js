/* Every ability (AB table). Fields: name, ic (icon), f (Focus), ap:1 (costs 1 action; otherwise ends turn), instant (no target),
   passive (never a button), ctx (button only shows when there's a target), tg(u) → targets, run(u,g), avail(u) → reason it's blocked,
   dm(u) → damage range for the odds panel, melee (odds use melee math). Spec: docs/specs/combat.md §2 */
const adjTiles=(u,chars)=>tilesWhere((c,x,y)=>chars.includes(c)&&cheb(u,{x,y})===1);
const allyT=(u,f)=>S.units.filter(p=>p.side==='p'&&alive(p)&&f(p)).map(t=>({t,chance:100,ally:1}));
const enemyT=(u,r,ch,extra=()=>true)=>foesIn(u,t=>dist(u,t)<=r&&los(u,t)&&extra(t)).map(t=>({t,chance:typeof ch==='function'?ch(t):ch}));
function pierceTarget(u,t){const dx=t.x-u.x,dy=t.y-u.y;
 for(const p of line(t.x,t.y,t.x+dx*3,t.y+dy*3).slice(1)){if(dist(u,p)>5||FULL(tile(p.x,p.y)))break;const o=unitAt(p.x,p.y);if(o&&o.side==='e'&&!o.hid)return o}return null}
const AB={
 shoot:{name:'Shoot',ic:'shoot',tip:'Fire your weapon. Ends turn. Barrels and alarm beacons in sight can be shot (always hits).',dm:u=>u.dmg,
  tg:u=>[...foesIn(u,t=>dist(u,t)<=u.range&&seenFor(u,t)).map(t=>({t,chance:hitChance(u,t)})),...tilesWhere((c,x,y)=>(c==='x'||c==='b')&&dist(u,{x,y})<=u.range&&los(u,{x,y})).map(p=>({...p,[tile(p.x,p.y)==='x'?'barrel':'beacon']:1,chance:100}))],
  run:(u,g)=>g.barrel?(log(`${u.n} shoots the barrel.`),explodeBarrel(g.x,g.y,u)):g.beacon?(log(`${u.n} shoots the alarm beacon.`),hitBeacon(g.x,g.y,ri(u.dmg[0],u.dmg[1]))):resolve(u,g.t,g.chance,u.dmg)},
 strike:{name:'Strike',ic:'strike',melee:1,tip:'Dash in and cut. Ignores cover. Ends turn.',dm:u=>u.dmg,tg:u=>{const R=reach(u);return foesIn(u,()=>true).map(t=>{let spot=null;
   if(cheb(u,t)===1)spot={path:[]};else{let best=99;for(const [k,dd] of Object.entries(R.d)){const [x,y]=k.split(',').map(Number);if(dd>0&&dd<best&&cheb({x,y},t)===1){best=dd;spot={x,y}}}if(spot)spot.path=pathTo(u,spot.x,spot.y,R.prev)}
   return spot?{t,chance:hitChance(u,t,{melee:true,mod:u.leapAim||0}),spot}:null}).filter(Boolean)},
  run:(u,g)=>{moveAlong(u,g.spot.path);if(u.status==='ok'&&alive(g.t)&&cheb(u,g.t)===1)resolve(u,g.t,g.chance,u.dmg,{melee:true,label:'strike'});u.leapAim=0}},
 guard:{name:'Guard',ic:'guard',tip:'Deflect more bolts and cut enemies who come close, until your next turn.',instant:1,run:u=>{u.guard=true;u.guardStruck=false;log(`${u.n} takes a Guard stance.`)}},
 overwatch:{name:'Overwatch',ic:'overwatch',tip:'Shoot the first enemy that moves in sight (−15 aim).',instant:1,run:u=>{u.ow=true;log(`${u.n} is on overwatch.`)}},
 push:{name:'Push',ic:'push',f:2,tip:'Shove an enemy 2 tiles, out of cover. Slamming into things deals 2.',tg:u=>enemyT(u,4,90),run:(u,g)=>{if(!rnd(90)){log(`${u.n}'s Push slips.`);return}push(u,g.t)}},
 collapse:{name:'Collapse',loud:1,ic:'collapse',f:3,tip:'Bring down a wall. Enemies beside it take 4. It becomes rubble.',tg:u=>tilesWhere((c,x,y)=>'#Bh'.includes(c)&&dist(u,{x,y})<=5&&los(u,{x,y})),
  run:(u,g)=>{S.grid[g.y][g.x]='r';fx(g,'CRASH','boom');log(`${u.n} tears the wall down.`);for(const e of enemies().filter(e=>cheb(e,g)<=1))damage(e,4,u)}},
 choke:{name:'Choke',ic:'choke',f:2,dm:()=>[4,5],tip:'4–5 damage, ignores cover. Darkness +2.',tg:u=>enemyT(u,5,85),run:(u,g)=>{addDark(u,2);resolve(u,g.t,85,[4,5],{ignoreDeflect:1,label:'Force choke'})}},
 stun:{name:'Stun',ic:'stunned',f:2,tip:'Cloud an enemy’s mind. They lose their next turn and are easier to capture.',tg:u=>enemyT(u,5,75,t=>t.status==='ok'),run:(u,g)=>{if(rnd(75)){g.t.status='stunned';g.t.ow=false;fx(g.t,'STUN');log(`${g.t.n} is stunned.`,'good')}else log(`${g.t.n} resists the stun.`)}},
 subdue:{name:'Subdue',ic:'captured',tip:'Capture an adjacent enemy who is stunned, surrendered, or at half health. Gives intel.',tg:u=>foesIn(u,t=>cheb(u,t)===1&&!t.noCap&&(t.status!=='ok'||t.hp*2<=t.max)).map(t=>({t,chance:t.status==='ok'?60:85})),
  run:(u,g)=>{if(rnd(g.chance)){g.t.status='captured';S.intel++;u.caps=(u.caps||0)+1;if(g.t.envoy){S.envoyTaken=1;S.intel++;log(`${u.n} takes the envoy alive. +2 intel.`,'good')}else log(`${u.n} captures ${g.t.n}. +1 intel.`,'good')}else{log(`${g.t.n} breaks free.`);if(g.t.status==='surrender')g.t.status='ok'}}},
 meditate:{name:'Meditate',ic:'meditate',tip:'+2 Focus. Ends turn.',instant:1,avail:u=>u.focus>=u.maxF?'Focus full':null,run:u=>{u.focus=Math.min(u.maxF,u.focus+(u.wildBond?3:2));log(`${u.n} meditates.`)}},
 heal:{name:'Medkit',ic:'medic',ap:1,tip:'Heal 4, or revive a downed ally at 2 HP. Adjacent only. Costs 1 action.',avail:u=>u.kits>0?null:'No medkits',
  tg:u=>allyT(u,p=>cheb(u,p)<=1&&!p.bound&&(p.status==='down'||p.hp<p.max)),
  run:(u,g)=>{u.kits--;const t=g.t;if(t.status==='down'){t.status='ok';t.hp=2;t.bleed=0;t.stable=0;t.ap=0;t.savedBy=u.rid;log(`${u.n} gets ${t.n} back on their feet.`,'good')}else{t.hp=Math.min(t.max,t.hp+4);log(`${u.n} patches up ${t.n}.`,'good')}fx(t,'+','heal')}},
 grenade:{name:'Grenade',ic:'grenade',dm:()=>[3,3],tip:'3 damage to everyone in a 3×3 area, allies too. Destroys crates, sets off barrels.',avail:u=>u.nades>0?null:'Out of grenades',
  tg:u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=6&&!FULL(c)).map(p=>({...p,area:1})),run:(u,g)=>{u.nades--;log(`${u.n} throws a grenade.`);blast(g.x,g.y,3,u)}},
 // --- shared field actions ---
 stabilize:{name:'Stabilize',ic:'stabilize',ap:1,ctx:1,tip:'Stop a downed ally’s bleeding. They stay down but can’t bleed out. Adjacent, 1 action.',
  tg:u=>allyT(u,p=>p.status==='down'&&!p.stable&&cheb(u,p)===1),run:(u,g)=>{g.t.stable=1;g.t.savedBy=u.rid;fx(g.t,'STABLE','heal');log(`${u.n} stabilizes ${g.t.n}.`,'good')}},
 door:{name:'Open door',ic:'door',ap:1,ctx:1,tip:'Open an adjacent door. 1 action.',tg:u=>adjTiles(u,'d'),run:(u,g)=>{S.grid[g.y][g.x]='_';log(`${u.n} opens the door.`)}},
 console:{name:'Use console',ic:'hack',ap:1,ctx:1,tip:'Try to unlock the doors from an adjacent console. 50% for a Jedi. 1 action.',tg:u=>tilesWhere(c=>c==='D').length?adjTiles(u,'k').map(p=>({...p,chance:50})):[],
  run:u=>{if(rnd(50))unlock(u);else log(`${u.n} can't crack the console.`)}},
 scan:{name:'Scan clue',ic:'scan',ap:1,ctx:1,tip:'Copy an adjacent data terminal. This unit now carries the data. 1 action.',tg:u=>adjTiles(u,'q'),
  run:(u,g)=>{S.grid[g.y][g.x]='Q';u.data=1;S.clues++;fx(g,'DATA','heal');log(`${u.n} copies the terminal (${S.clues}/3).`,'good')}},
 plant:{name:'Plant charge',ic:'charge',ap:1,ctx:1,tip:'Arm an adjacent charge site. Enemy techs may defuse it once Threat rises. 1 action.',tg:u=>adjTiles(u,'C'),
  run:(u,g)=>{S.grid[g.y][g.x]='X';fx(g,'ARMED','heal');log(`${u.n} arms a charge (${tilesWhere(c=>c==='X').length}/${S.M.need}).`,'good')}},
 // --- Guardian ---
 saberThrow:{name:'Saber Throw',ic:'throw',f:2,dm:()=>[3,4],tip:'3–4 damage, ignores cover. Can also hit a second enemy behind the first.',tg:u=>enemyT(u,5,85),
  run:(u,g)=>{const t2=pierceTarget(u,g.t);resolve(u,g.t,85,[3,4],{ignoreDeflect:1,label:'thrown saber'});if(t2&&alive(t2)){log('The blade keeps going…');resolve(u,t2,85,[3,4],{ignoreDeflect:1,label:'thrown saber'})}}},
 defLine:{name:'Defensive Line',passive:1,tip:'Adjacent allies get +15 defense.'},
 leap:{name:'Force Leap',ic:'leap',f:1,ap:1,tip:'Jump up to 6 tiles, over cover and units. Your next Strike this turn gets +15 aim.',
  tg:u=>tilesWhere((c,x,y)=>PASS(c)&&!unitAt(x,y)&&dist(u,{x,y})<=6&&cheb(u,{x,y})>1).map(p=>({...p,spot:1})),
  run:(u,g)=>{u.x=g.x;u.y=g.y;u.leapAim=15;log(`${u.n} leaps.`);reveal();reactions(u)}},
 reflectM:{name:'Reflect Mastery',passive:1,tip:'Guard reflects 65% of deflected bolts, at the weakest enemy in 6.'},
 sweep:{name:'Saber Sweep',ic:'sweep',f:2,melee:1,dm:u=>u.dmg,tip:'Strike every adjacent enemy at −10 aim.',tg:u=>foesIn(u,t=>cheb(u,t)===1).map(t=>({t,chance:hitChance(u,t,{melee:true,mod:-10})})),
  run:u=>{for(const e of foesIn(u,t=>cheb(u,t)===1))resolve(u,e,hitChance(u,e,{melee:true,mod:-10}),u.dmg,{melee:true,label:'sweep'})}},
 // --- Consular ---
 forceHeal:{name:'Force Heal',ic:'medic',f:2,ap:1,tip:'Heal 3 within 3 tiles, or stabilize a downed ally. 1 action.',tg:u=>allyT(u,p=>dist(u,p)<=3&&!p.bound&&(p.status==='down'?!p.stable:p.hp<p.max)),
  run:(u,g)=>{const t=g.t;if(t.status==='down'){t.stable=1;t.savedBy=u.rid;log(`${u.n} holds ${t.n} in the Force. Stabilized.`,'good')}else{t.hp=Math.min(t.max,t.hp+3);log(`${u.n} heals ${t.n}.`,'good')}fx(t,'+','heal')}},
 barrier:{name:'Force Barrier',ic:'barrier',f:2,ap:1,tip:'An ally within 4 counts as in full cover from every side until your next turn.',tg:u=>allyT(u,p=>p.status==='ok'&&dist(u,p)<=4&&!p.barrier),
  run:(u,g)=>{g.t.barrier=1;fx(g.t,'BARRIER','heal');log(`${u.n} wraps ${g.t.n} in a barrier.`,'good')}},
 battleMed:{name:'Battle Meditation',ic:'meditate',f:3,instant:1,tip:'Allies within 6 get +10 aim, enemies within 6 get −10, until your next turn. Breaks if you are hit.',
  run:u=>{S.bmed=u.uid;log(`${u.n} sinks into Battle Meditation.`,'good')}},
 mindTrick:{name:'Mind Trick',ic:'stunned',f:3,tip:'70%: a non-Force enemy within 5 attacks its own side on its next turn.',tg:u=>enemyT(u,5,70,t=>t.status==='ok'&&!t.force&&!t.horror),
  run:(u,g)=>{if(rnd(70)){g.t.tricked=1;fx(g.t,'TRICKED');log(`${g.t.n}'s eyes go blank.`,'good')}else log(`${g.t.n} shrugs off the trick.`)}},
 forceRevive:{name:'Force Revive',ic:'stabilize',f:4,tip:'Revive an adjacent downed ally at 4 HP. Once per mission.',avail:u=>u.revived?'Used this mission':null,
  tg:u=>allyT(u,p=>p.status==='down'&&cheb(u,p)===1),run:(u,g)=>{const t=g.t;u.revived=1;t.savedBy=u.rid;t.status='ok';t.hp=Math.min(t.max,4);t.bleed=0;t.stable=0;t.ap=0;fx(t,'+4','heal');log(`${u.n} pours life into ${t.n}.`,'good')}},
 // --- troops ---
 suppress:{name:'Suppress',ic:'suppress',tip:'Pin an enemy: −30 aim until your next turn. If it moves, you get a free shot.',tg:u=>enemyT(u,u.range,100),
  run:(u,g)=>{g.t.supp=1;u.supT=g.t.uid;fx(g.t,'PINNED');log(`${u.n} pins down ${g.t.n}.`)}},
 hunker:{name:'Hunker Down',ic:'hunker',instant:1,tip:'+30 defense and no flank crits until your next turn.',run:u=>{u.hunker=1;log(`${u.n} hunkers down.`)}},
 mark:{name:'Mark',ic:'mark',ap:1,tip:'Paint a target: everyone gets +15 aim against it until your next turn. 1 action.',tg:u=>enemyT(u,11,100,t=>!t.marked),
  run:(u,g)=>{g.t.marked=1;fx(g.t,'MARKED');log(`${u.n} marks ${g.t.n}.`)}},
 smoke:{name:'Smoke',ic:'smoke',ap:1,tip:'3×3 smoke within 6: allies inside get +20 defense for 2 turns. Once per mission.',avail:u=>u.smoked?'Used this mission':null,
  tg:u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=6&&!FULL(c)).map(p=>({...p,area:1,ally:1})),run:(u,g)=>{u.smoked=1;S.smoke.push({x:g.x,y:g.y,t:2});log(`${u.n} pops smoke.`)}},
 hack:{name:'Hack',ic:'hack',ctx:1,tip:'Slice a console or locked door within 4. Opens every locked door. Ends turn.',tg:u=>tilesWhere(c=>c==='D').length?tilesWhere((c,x,y)=>(c==='k'||c==='D')&&dist(u,{x,y})<=4).map(p=>({...p,chance:100})):[],
  run:u=>unlock(u)},
 shredder:{name:'Shredder',passive:1,tip:'Hits strip 1 armor and tear apart the crate the target hides behind.'}};
// Spotter (Scout): allies may shoot an enemy they can't see if a Spotter within 11 can.
const seenFor=(u,t)=>los(u,t)||players().some(p=>p!==u&&p.spotter&&p.status==='ok'&&dist(p,t)<=11&&los(p,t));

/* ---- Ability engine (wave 3). Chat P can define tree abilities as data: defineAbility(id, def). An existing id is kept unless def.replace.
 def: name, ic, desc (one mechanical sentence), f (Focus), ap (1 = one action, 0 = free, unset = ends turn),
  once (1/mission) · cooldown (turns) · uses ('kits'|'nades'|any counter on the unit; spends 1) · loud (breaks concealment)
  kind: 'attack' (default) · 'ally' · 'self' · 'passive'
  attack: range (default weapon), melee, noLos, area (3×3, auto-hits), tags ([...] targets must have one), dmg ([lo,hi] | 'weapon'), dmgMod,
          aimMod, chance (fixed %), ignoreCover, ignoreDeflect, shots (n), noDmg (effect only, rolls chance)
  effects (on hit, or on the ally/self target): status ('stunned'|'disarmed'|'rooted'|'marked'|'supp') + statusChance,
          heal, stabilize, revive (HP), buff {aim, def, shield, ap, …} (aim/def last until your next turn), focus (+Focus), dark (Darkness to user)
  passive: mod {stat:n} added to the unit at mission start (aim, hp, mob, crit, armor, deflect, will…); the unit also gets u[id]=1. */
function defineAbility(id,d){if(AB[id]&&!d.replace)return AB[id];
 const a={name:d.name||id,ic:d.ic||'strike',desc:d.desc,tip:d.desc,f:d.f,ap:d.ap,loud:d.loud,melee:d.melee};
 const mark=u=>{if(d.once)(u.used=u.used||{})[id]=1;if(d.cooldown)(u.cd=u.cd||{})[id]=S.turn+d.cooldown;if(d.uses)u[d.uses]--};
 a.avail=u=>d.once&&(u.used||{})[id]?'Used this mission':d.cooldown&&(u.cd||{})[id]>=S.turn?'Cooling down':d.uses&&!(u[d.uses]>0)?'None left':null;
 if(d.kind==='passive'||d.passive){a.passive=1;a.mod=d.mod;delete a.avail}
 else if(d.kind==='self'){a.instant=1;a.run=u=>{mark(u);applyEff(u,u,d)}}
 else if(d.kind==='ally'){a.tg=u=>allyT(u,p=>!p.bound&&(d.self||p!==u)&&dist(u,p)<=(d.range||1.5)&&(d.revive||d.stabilize?p.status==='down'&&(d.revive||!p.stable):p.status==='ok'));
  a.run=(u,g)=>{mark(u);applyEff(u,g.t,d)}}
 else{const rng=u=>d.range||u.range,dm=u=>Array.isArray(d.dmg)?d.dmg:[u.dmg[0]+(d.dmgMod||0),u.dmg[1]+(d.dmgMod||0)];a.dm=dm;
  const ch=(u,t)=>d.chance??Math.max(5,hitChance(u,t,{melee:d.melee,mod:d.aimMod||0,noCover:d.ignoreCover}));
  const ok=t=>!d.tags||d.tags.some(g=>tagsOf(t).includes(g));
  if(d.area){a.loud=1;a.tg=u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=rng(u)&&!FULL(c)&&(d.noLos||los(u,{x,y}))).map(p=>({...p,area:1}));
   a.run=(u,g)=>{mark(u);fx(g,'BOOM','boom');for(const t of enemies().filter(t=>cheb(t,g)<=1&&!t.hid&&ok(t)))hitWith(u,t,d,dm(u),100)}}
  else{a.tg=u=>foesIn(u,t=>ok(t)&&(d.melee?cheb(u,t)===1:dist(u,t)<=rng(u)&&(d.noLos||los(u,t)))).map(t=>({t,chance:ch(u,t)}));
   a.run=(u,g)=>{mark(u);for(let i=0;i<(d.shots||1);i++)if(alive(g.t))hitWith(u,g.t,d,dm(u),g.chance)}}}
 return AB[id]=a}
function hitWith(u,t,d,dmg,chance){const label=(d.name||'attack').toLowerCase();
 if(d.noDmg){if(rnd(chance))applyEff(u,t,d);else{log(`${t.n} resists ${u.n}'s ${label}.`);fx(t,'MISS','miss')}return}
 if(resolve(u,t,chance,dmg,{melee:d.melee,ignoreDeflect:d.ignoreDeflect||d.area,label})&&alive(t))applyEff(u,t,d)}
function applyEff(u,t,d){
 if(d.status&&t.status==='ok'&&(!d.statusChance||rnd(d.statusChance))){if(d.status==='stunned'){t.status='stunned';t.ow=false}else t[d.status]=1;
  const n=(STATUS[d.status]||{}).n||d.status;fx(t,n.toUpperCase());log(`${t.n}: ${n}.`,t.side==='e'?'good':'bad')}
 if(d.heal&&t.status==='ok'){t.hp=Math.min(t.max,t.hp+d.heal);fx(t,'+'+d.heal,'heal');log(`${u.n} heals ${t.n}.`,'good')}
 if(d.stabilize&&t.status==='down'&&!t.stable){t.stable=1;t.savedBy=u.rid;fx(t,'STABLE','heal');log(`${u.n} stabilizes ${t.n}.`,'good')}
 if(d.revive&&t.status==='down'){t.status='ok';t.hp=Math.min(t.max,d.revive);t.bleed=0;t.stable=0;t.ap=0;t.savedBy=u.rid;fx(t,'+'+d.revive,'heal');log(`${u.n} revives ${t.n}.`,'good')}
 for(const [k,n] of Object.entries(d.buff||{})){const f=k==='aim'?'buffAim':k==='def'?'buffDef':k;t[f]=(t[f]||0)+n}
 if(d.buff)fx(t,'BOOST','heal');
 if(d.focus&&t.maxF)t.focus=Math.min(t.maxF,t.focus+d.focus);
 if(d.dark)addDark(u,d.dark)}

// ---- Spec A §2 kits not built in wave 2: Sentinel, Wayseeker, and the remaining troop abilities.
Object.assign(AB,{
 sense:{name:'Sense',passive:1,desc:'Finds hidden enemies within 8 tiles instead of 4.'},
 executioner:{name:'Executioner',passive:1,desc:'+25 aim against enemies at half health or less.'},
 shadowStep:{name:'Shadow Step',ic:'conceal',f:1,ap:1,desc:'Blink to a free tile within 5 (no reaction fire); your next Strike this turn gets +20 aim, and you stay concealed until you attack or an enemy comes within 2. 1 action.',
  tg:u=>tilesWhere((c,x,y)=>PASS(c)&&!unitAt(x,y)&&dist(u,{x,y})<=5&&cheb(u,{x,y})>1).map(p=>({...p,spot:1})),
  run:(u,g)=>{u.x=g.x;u.y=g.y;reveal();const e=enemies().find(e=>e.status==='ok'&&cheb(e,u)<=2&&los(e,u));
   u.leapAim=20;if(e&&!S.conc)log(`${u.n} steps out of the shadows right in front of ${e.n}.`,'bad');else{u.conc=1;fx(u,'HIDDEN');log(`${u.n} vanishes into the shadows.`,'good')}}},
 pathfinder:{name:'Pathfinder',passive:1,desc:'+1 movement.'},
 wildBond:{name:'Wild Bond',passive:1,desc:'Starts every mission at full Focus; Meditate restores 3.'},
 beastCalm:{name:'Beast Calm',ic:'calm',f:2,desc:'Soothe a creature or horror within 5: it loses its next turn (75%, horrors 50%).',
  tg:u=>enemyT(u,5,t=>t.horror?50:75,t=>t.status==='ok'&&(t.horror||tagsOf(t).includes('creature'))),
  run:(u,g)=>{if(rnd(g.chance)){g.t.status='stunned';fx(g.t,'CALMED');log(`${g.t.n} goes still under ${u.n}'s hand.`,'good')}else log(`${g.t.n} shakes off the calm.`)}},
 pull:{name:'Force Pull',ic:'pull',f:1,ap:1,desc:'Yank an enemy within 6 up to 3 tiles toward you, out of cover. Slamming into things deals 2. 1 action.',tg:u=>enemyT(u,6,90,t=>cheb(u,t)>1),
  run:(u,g)=>{if(!rnd(90))return log(`${u.n}'s Pull slips.`);const t=g.t,e0=uEl(t);pushN(u,t,Math.sign(u.x-t.x),Math.sign(u.y-t.y),Math.min(3,cheb(u,t)-1));
   const drop=e0-uEl(t);if(drop>0&&alive(t))damage(t,drop,u);log(`${u.n} pulls ${t.n} in.`)}},
 runGun:{name:'Run & Gun',ic:'dash',ap:0,desc:'Free: gain an extra action this turn (dash, then still shoot). Once every 2 turns.',
  avail:u=>u.rgT&&S.turn<=u.rgT+1?'Cooling down':null,instant:1,run:u=>{u.rgT=S.turn;u.ap++;log(`${u.n} sprints.`)}},
 spotter:{name:'Spotter',passive:1,desc:'Allies may shoot enemies within their range that this unit sees (within 11), even without their own line of sight.'},
 ghost:{name:'Ghost',passive:1,desc:'Once per mission, after a kill this unit slips back into concealment.'},
 ionNade:{name:'Ion Grenade',ic:'ion',loud:1,dm:()=>[1,4],desc:'Uses a grenade. 3×3 within 6: droids take 4 and are stunned, everyone else takes 1. Spares cover.',avail:u=>u.nades>0?null:'Out of grenades',
  tg:u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=6&&!FULL(c)).map(p=>({...p,area:1})),
  run:(u,g)=>{u.nades--;fx(g,'ION','boom');log(`${u.n} throws an ion grenade.`);for(const t of S.units.filter(t=>alive(t)&&t.status!=='down'&&cheb(t,g)<=1)){const dr=tagsOf(t).includes('droid');damage(t,dr?4:1,u);if(dr&&alive(t)&&t.status==='ok'){t.status='stunned';fx(t,'STUN')}}}},
 holdLine:{name:'Hold the Line',ic:'overwatch',instant:1,desc:'Overwatch that fires at every enemy that moves in range (−15 each) until your next turn.',run:u=>{u.ow='all';u.owHit=[];log(`${u.n} holds the line.`)}}});
defineAbility('disarm',{name:'Disarm',ic:'disarm',f:2,range:5,chance:80,noDmg:1,status:'disarmed',desc:'80%: an enemy within 5 can’t shoot, throw or use lightning on its next turn (it can still move and strike).'});
defineAbility('protocol',{name:'Combat Protocol',ic:'hack',range:8,noLos:1,dmg:[3,3],chance:100,ignoreDeflect:1,tags:['droid'],desc:'3 damage to a droid within 8, no line of sight needed. Never misses.'});
// Tree abilities designed by Chat P (were PROG_AB in temple-prog.js). Ids kept.
Object.assign(AB,{
 flurry:{name:'Flurry',ic:'flurry',f:1,melee:1,dm:u=>u.dmg,desc:'Two strikes on one adjacent enemy, each at −10 aim. Ends turn.',
  tg:u=>foesIn(u,t=>cheb(u,t)===1).map(t=>({t,chance:hitChance(u,t,{melee:true,mod:-10})})),
  run:(u,g)=>{for(let i=0;i<2&&alive(g.t)&&g.t.status==='ok';i++)resolve(u,g.t,hitChance(u,g.t,{melee:true,mod:-10}),u.dmg,{melee:true,label:'flurry'})}},
 mightyBlow:{name:'Mighty Blow',ic:'strike',f:2,melee:1,dm:u=>[u.dmg[0]+2,u.dmg[1]+2],desc:'A heavy strike on an adjacent enemy: +2 damage. Ends turn.',
  tg:u=>foesIn(u,t=>cheb(u,t)===1).map(t=>({t,chance:hitChance(u,t,{melee:true})})),run:(u,g)=>resolve(u,g.t,g.chance,[u.dmg[0]+2,u.dmg[1]+2],{melee:true,label:'mighty blow'})},
 precisionStrike:{name:'Precision Strike',ic:'strike',f:2,melee:1,dm:u=>[u.dmg[0]+1,u.dmg[1]+1],desc:'Strike an adjacent enemy at +20 aim and +1 damage. Ends turn.',
  tg:u=>foesIn(u,t=>cheb(u,t)===1).map(t=>({t,chance:hitChance(u,t,{melee:true,mod:20})})),run:(u,g)=>resolve(u,g.t,g.chance,[u.dmg[0]+1,u.dmg[1]+1],{melee:true,label:'precision strike'})},
 massHeal:{name:'Mass Heal',ic:'medic',f:3,ap:1,instant:1,desc:'Heal 2 on every ally within 4, and stabilize downed allies there. 1 action.',
  run:u=>{log(`${u.n} pours the Force into the squad.`,'good');healArea(u,4)}},
 forceWave:{name:'Force Wave',ic:'push',f:3,instant:1,loud:1,desc:'Every visible enemy within 2 takes 2 damage (ignores cover) and may be stunned (40%). Ends turn.',
  run:u=>{log(`${u.n} releases a wave of Force.`);for(const e of foesIn(u,t=>dist(u,t)<=2.9)){damage(e,2,u);if(alive(e)&&e.status==='ok'&&rnd(40)){e.status='stunned';e.ow=false;fx(e,'STUN')}}}},
 stasisField:{name:'Stasis Field',ic:'stunned',f:4,instant:1,loud:1,desc:'60% chance to stun each visible enemy within 3. Ends turn.',
  run:u=>{log(`${u.n} freezes the air itself.`,'good');for(const e of foesIn(u,t=>dist(u,t)<=3.2&&t.status==='ok'))if(rnd(60)){e.status='stunned';e.ow=false;fx(e,'STUN')}}},
 tremor:{name:'Tremor',ic:'tremor',f:3,loud:1,dm:()=>[2,2],desc:'Shake a 3×3 area within 5: cover there drops a step (crates to rubble), enemies take 2 and lose overwatch. Ends turn.',
  tg:u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=5&&los(u,{x,y})&&!FULL(c)).map(p=>({...p,area:1})),
  run:(u,g)=>{fx(g,'QUAKE','boom');log(`${u.n} makes the ground heave.`);for(let y=g.y-1;y<=g.y+1;y++)for(let x=g.x-1;x<=g.x+1;x++){if(!inb(x,y))continue;
   if(TILES[S.grid[y][x]].breaks)degrade(x,y);const e=unitAt(x,y);if(e&&e.side==='e'&&!e.hid&&alive(e)){e.ow=false;damage(e,2,u)}}}},
 chainShot:{name:'Chain Shot',ic:'shoot',dm:u=>u.dmg,desc:'Shoot at −10 aim; on a hit, shoot the same target again at −10. Ends turn.',
  tg:u=>enemyT(u,u.range,t=>Math.max(5,hitChance(u,t)-10)),
  run:(u,g)=>{const h=g.t.hp;resolve(u,g.t,g.chance,u.dmg,{label:'first shot'});if(alive(g.t)&&g.t.status==='ok'&&g.t.hp<h)resolve(u,g.t,Math.max(5,hitChance(u,g.t)-10),u.dmg,{label:'follow-up shot'})}},
 shieldDrone:{name:'Shield Drone',ic:'drone',ap:1,desc:'Send a drone to an ally within 4: they count as in full cover from every side until your next turn. Once per mission. 1 action.',
  avail:u=>u.droneUsed?'Used this mission':null,tg:u=>allyT(u,p=>p.status==='ok'&&dist(u,p)<=4&&!p.barrier),
  run:(u,g)=>{u.droneUsed=1;g.t.barrier=1;fx(g.t,'SHIELD','heal');log(`${u.n}'s drone shields ${g.t.n}.`,'good')}},
 medBeacon:{name:'Med Beacon',ic:'medic',ap:1,instant:1,desc:'Heal 2 on every ally within 3 and stabilize downed allies there. Once per mission. 1 action.',
  avail:u=>u.beaconUsed?'Used this mission':null,run:u=>{u.beaconUsed=1;log(`${u.n} drops a med beacon.`,'good');healArea(u,3)}}});
function healArea(u,r){for(const p of S.units.filter(p=>p.side==='p'&&alive(p)&&dist(u,p)<=r)){
 if(p.status==='down'){if(!p.stable){p.stable=1;p.savedBy=u.rid;fx(p,'STABLE','heal')}}else if(p.hp<p.max){p.hp=Math.min(p.max,p.hp+2);fx(p,'+2','heal')}}}
// Mechanical one-liners for the codex/tooltips (U's describe()). Older abilities used `tip`.
for(const a of Object.values(AB)){a.desc=a.desc||a.tip;a.tip=a.tip||a.desc}

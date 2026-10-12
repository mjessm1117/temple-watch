/* Every ability (AB table). Fields: name, ic (icon), f (Focus), ap:1 (costs 1 action; otherwise ends turn), instant (no target),
   passive (never a button), ctx (button only shows when there's a target), tg(u) → targets, run(u,g), avail(u) → reason it's blocked,
   dm(u) → damage range for the odds panel, melee (odds use melee math). Spec: docs/specs/combat.md §2 */
const adjTiles=(u,chars)=>tilesWhere((c,x,y)=>chars.includes(c)&&cheb(u,{x,y})===1);
const allyT=(u,f)=>S.units.filter(p=>p.side==='p'&&alive(p)&&f(p)).map(t=>({t,chance:100,ally:1}));
const enemyT=(u,r,ch,extra=()=>true)=>foesIn(u,t=>dist(u,t)<=r&&los(u,t)&&extra(t)).map(t=>({t,chance:typeof ch==='function'?ch(t):ch}));
function pierceTarget(u,t){const dx=t.x-u.x,dy=t.y-u.y;
 for(const p of line(t.x,t.y,t.x+dx*3,t.y+dy*3).slice(1)){if(dist(u,p)>5||FULL(tile(p.x,p.y)))break;const o=unitAt(p.x,p.y);if(o&&o.side==='e'&&!o.hid)return o}return null}
const AB={
 shoot:{name:'Shoot',ic:'shoot',tip:'Fire your weapon. Ends turn. Barrels in sight can be shot (always hits).',dm:u=>u.dmg,
  tg:u=>[...enemyT(u,u.range,t=>hitChance(u,t)),...tilesWhere((c,x,y)=>c==='x'&&dist(u,{x,y})<=u.range&&los(u,{x,y})).map(p=>({...p,barrel:1,chance:100}))],
  run:(u,g)=>g.barrel?(log(`${u.n} shoots the barrel.`),explodeBarrel(g.x,g.y,u)):resolve(u,g.t,g.chance,u.dmg)},
 strike:{name:'Strike',ic:'strike',melee:1,tip:'Dash in and cut. Ignores cover. Ends turn.',dm:u=>u.dmg,tg:u=>{const R=reach(u);return foesIn(u,()=>true).map(t=>{let spot=null;
   if(cheb(u,t)===1)spot={path:[]};else{let best=99;for(const [k,dd] of Object.entries(R.d)){const [x,y]=k.split(',').map(Number);if(dd>0&&dd<best&&cheb({x,y},t)===1){best=dd;spot={x,y}}}if(spot)spot.path=pathTo(u,spot.x,spot.y,R.prev)}
   return spot?{t,chance:hitChance(u,t,{melee:true,mod:u.leapAim||0}),spot}:null}).filter(Boolean)},
  run:(u,g)=>{moveAlong(u,g.spot.path);if(u.status==='ok'&&alive(g.t))resolve(u,g.t,g.chance,u.dmg,{melee:true,label:'strike'});u.leapAim=0}},
 guard:{name:'Guard',ic:'guard',tip:'Deflect more bolts and cut enemies who come close, until your next turn.',instant:1,run:u=>{u.guard=true;u.guardStruck=false;log(`${u.n} takes a Guard stance.`)}},
 overwatch:{name:'Overwatch',ic:'overwatch',tip:'Shoot the first enemy that moves in sight (−15 aim).',instant:1,run:u=>{u.ow=true;log(`${u.n} is on overwatch.`)}},
 push:{name:'Push',ic:'push',f:2,tip:'Shove an enemy 2 tiles, out of cover. Slamming into things deals 2.',tg:u=>enemyT(u,4,90),run:(u,g)=>{if(!rnd(90)){log(`${u.n}'s Push slips.`);return}push(u,g.t)}},
 collapse:{name:'Collapse',ic:'collapse',f:3,tip:'Bring down a wall. Enemies beside it take 4. It becomes rubble.',tg:u=>tilesWhere((c,x,y)=>c==='#'&&dist(u,{x,y})<=5&&los(u,{x,y})),
  run:(u,g)=>{S.grid[g.y][g.x]='r';fx(g,'CRASH','boom');log(`${u.n} tears the wall down.`);for(const e of enemies().filter(e=>cheb(e,g)<=1))damage(e,4,u)}},
 choke:{name:'Choke',ic:'choke',f:2,dm:()=>[4,5],tip:'4–5 damage, ignores cover. Darkness +2.',tg:u=>enemyT(u,5,85),run:(u,g)=>{addDark(u,2);resolve(u,g.t,85,[4,5],{ignoreDeflect:1,label:'Force choke'})}},
 stun:{name:'Stun',ic:'stunned',f:2,tip:'Cloud an enemy’s mind. They lose their next turn and are easier to capture.',tg:u=>enemyT(u,5,75,t=>t.status==='ok'),run:(u,g)=>{if(rnd(75)){g.t.status='stunned';g.t.ow=false;fx(g.t,'STUN');log(`${g.t.n} is stunned.`,'good')}else log(`${g.t.n} resists the stun.`)}},
 subdue:{name:'Subdue',ic:'captured',tip:'Capture an adjacent enemy who is stunned, surrendered, or at half health. Gives intel.',tg:u=>foesIn(u,t=>cheb(u,t)===1&&!t.noCap&&(t.status!=='ok'||t.hp*2<=t.max)).map(t=>({t,chance:t.status==='ok'?60:85})),
  run:(u,g)=>{if(rnd(g.chance)){g.t.status='captured';S.intel++;u.caps=(u.caps||0)+1;if(g.t.envoy){S.envoyTaken=1;S.intel++;log(`${u.n} takes the envoy alive. +2 intel.`,'good')}else log(`${u.n} captures ${g.t.n}. +1 intel.`,'good')}else{log(`${g.t.n} breaks free.`);if(g.t.status==='surrender')g.t.status='ok'}}},
 meditate:{name:'Meditate',ic:'meditate',tip:'+2 Focus. Ends turn.',instant:1,avail:u=>u.focus>=u.maxF?'Focus full':null,run:u=>{u.focus=Math.min(u.maxF,u.focus+2);log(`${u.n} meditates.`)}},
 heal:{name:'Medkit',ic:'medic',ap:1,tip:'Heal 4, or revive a downed ally at 2 HP. Adjacent only. Costs 1 action.',avail:u=>u.kits>0?null:'No medkits',
  tg:u=>allyT(u,p=>cheb(u,p)<=1&&!p.bound&&(p.status==='down'||p.hp<p.max)),
  run:(u,g)=>{u.kits--;const t=g.t;if(t.status==='down'){t.status='ok';t.hp=2;t.bleed=0;t.stable=0;t.ap=0;log(`${u.n} gets ${t.n} back on their feet.`,'good')}else{t.hp=Math.min(t.max,t.hp+4);log(`${u.n} patches up ${t.n}.`,'good')}fx(t,'+','heal')}},
 grenade:{name:'Grenade',ic:'grenade',dm:()=>[3,3],tip:'3 damage to everyone in a 3×3 area, allies too. Destroys crates, sets off barrels.',avail:u=>u.nades>0?null:'Out of grenades',
  tg:u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=6&&!FULL(c)).map(p=>({...p,area:1})),run:(u,g)=>{u.nades--;log(`${u.n} throws a grenade.`);blast(g.x,g.y,3,u)}},
 // --- shared field actions ---
 stabilize:{name:'Stabilize',ic:'stabilize',ap:1,ctx:1,tip:'Stop a downed ally’s bleeding. They stay down but can’t bleed out. Adjacent, 1 action.',
  tg:u=>allyT(u,p=>p.status==='down'&&!p.stable&&cheb(u,p)===1),run:(u,g)=>{g.t.stable=1;fx(g.t,'STABLE','heal');log(`${u.n} stabilizes ${g.t.n}.`,'good')}},
 door:{name:'Open door',ic:'door',ap:1,ctx:1,tip:'Open an adjacent door. 1 action.',tg:u=>adjTiles(u,'d'),run:(u,g)=>{S.grid[g.y][g.x]='_';log(`${u.n} opens the door.`)}},
 console:{name:'Use console',ic:'hack',ap:1,ctx:1,tip:'Try to unlock the doors from an adjacent console. 50% for a Jedi. 1 action.',tg:u=>tilesWhere(c=>c==='D').length?adjTiles(u,'k').map(p=>({...p,chance:50})):[],
  run:u=>{if(rnd(50))unlock(u);else log(`${u.n} can't crack the console.`)}},
 scan:{name:'Scan clue',ic:'scan',ap:1,ctx:1,tip:'Copy an adjacent data terminal. This unit now carries the data. 1 action.',tg:u=>adjTiles(u,'q'),
  run:(u,g)=>{S.grid[g.y][g.x]='Q';u.data=1;S.clues++;fx(g,'DATA','heal');log(`${u.n} copies the terminal (${S.clues}/3).`,'good')}},
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
  run:(u,g)=>{const t=g.t;if(t.status==='down'){t.stable=1;log(`${u.n} holds ${t.n} in the Force. Stabilized.`,'good')}else{t.hp=Math.min(t.max,t.hp+3);log(`${u.n} heals ${t.n}.`,'good')}fx(t,'+','heal')}},
 barrier:{name:'Force Barrier',ic:'barrier',f:2,ap:1,tip:'An ally within 4 counts as in full cover from every side until your next turn.',tg:u=>allyT(u,p=>p.status==='ok'&&dist(u,p)<=4&&!p.barrier),
  run:(u,g)=>{g.t.barrier=1;fx(g.t,'BARRIER','heal');log(`${u.n} wraps ${g.t.n} in a barrier.`,'good')}},
 battleMed:{name:'Battle Meditation',ic:'meditate',f:3,instant:1,tip:'Allies within 6 get +10 aim, enemies within 6 get −10, until your next turn. Breaks if you are hit.',
  run:u=>{S.bmed=u.uid;log(`${u.n} sinks into Battle Meditation.`,'good')}},
 mindTrick:{name:'Mind Trick',ic:'stunned',f:3,tip:'70%: a non-Force enemy within 5 attacks its own side on its next turn.',tg:u=>enemyT(u,5,70,t=>t.status==='ok'&&!t.force&&!t.horror),
  run:(u,g)=>{if(rnd(70)){g.t.tricked=1;fx(g.t,'TRICKED');log(`${g.t.n}'s eyes go blank.`,'good')}else log(`${g.t.n} shrugs off the trick.`)}},
 forceRevive:{name:'Force Revive',ic:'stabilize',f:4,tip:'Revive an adjacent downed ally at 4 HP. Once per mission.',avail:u=>u.revived?'Used this mission':null,
  tg:u=>allyT(u,p=>p.status==='down'&&cheb(u,p)===1),run:(u,g)=>{const t=g.t;u.revived=1;t.status='ok';t.hp=Math.min(t.max,4);t.bleed=0;t.stable=0;t.ap=0;fx(t,'+4','heal');log(`${u.n} pours life into ${t.n}.`,'good')}},
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

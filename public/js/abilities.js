/* Every ability a unit can use. Add new ones here. */
const AB={
 shoot:{name:'Shoot',tip:'Fire your weapon. Ends turn.',tg:u=>foesIn(u,t=>dist(u,t)<=u.range&&los(u,t)).map(t=>({t,chance:hitChance(u,t)})),run:(u,g)=>resolve(u,g.t,g.chance,u.dmg)},
 strike:{name:'Strike',tip:'Dash in and cut. Ignores cover. Ends turn.',tg:u=>{const R=reach(u);return foesIn(u,()=>true).map(t=>{let spot=null;
   if(cheb(u,t)===1)spot={path:[]};else{let best=99;for(const [k,dd] of Object.entries(R.d)){const [x,y]=k.split(',').map(Number);if(dd>0&&dd<best&&cheb({x,y},t)===1){best=dd;spot={x,y}}}if(spot)spot.path=pathTo(u,spot.x,spot.y,R.prev)}
   return spot?{t,chance:hitChance(u,t,{melee:true}),spot}:null}).filter(Boolean)},
  run:(u,g)=>{moveAlong(u,g.spot.path);if(u.status==='ok'&&alive(g.t))resolve(u,g.t,g.chance,u.dmg,{melee:true,label:'strike'})}},
 guard:{name:'Guard',tip:'Deflect more bolts and cut enemies who come close, until your next turn.',instant:1,run:u=>{u.guard=true;u.guardStruck=false;log(`${u.n} takes a Guard stance.`)}},
 overwatch:{name:'Overwatch',tip:'Shoot the first enemy that moves in sight (−15 aim).',instant:1,run:u=>{u.ow=true;log(`${u.n} is on overwatch.`)}},
 push:{name:'Push',f:2,tip:'Shove an enemy 2 tiles, out of cover. Slamming into things deals 2.',tg:u=>foesIn(u,t=>dist(u,t)<=4&&los(u,t)).map(t=>({t,chance:90})),run:(u,g)=>{if(!rnd(90)){log(`${u.n}'s Push slips.`);return}push(u,g.t)}},
 throw:{name:'Throw',f:2,tip:'Rip the nearest crate (within 4) loose and hurl it. 3–4 damage.',avail:u=>nearCrate(u)?null:'No crate in reach',tg:u=>foesIn(u,t=>dist(u,t)<=6&&los(u,t)).map(t=>({t,chance:85})),run:(u,g)=>{const c=nearCrate(u);S.grid[c.y][c.x]='.';resolve(u,g.t,85,[3,4],{ignoreDeflect:1,label:'thrown crate'})}},
 collapse:{name:'Collapse',f:3,tip:'Bring down a wall. Enemies beside it take 3. It becomes rubble.',tg:u=>{const o=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(S.grid[y][x]==='#'&&dist(u,{x,y})<=5&&los(u,{x,y}))o.push({x,y});return o},
  run:(u,g)=>{S.grid[g.y][g.x]='r';fx(g,'CRASH');log(`${u.n} tears the wall down.`);for(const e of enemies().filter(e=>cheb(e,g)<=1))damage(e,3,u)}},
 choke:{name:'Choke',f:2,tip:'4–5 damage, ignores cover. Darkness +2.',tg:u=>foesIn(u,t=>dist(u,t)<=5&&los(u,t)).map(t=>({t,chance:85})),run:(u,g)=>{addDark(u,2);resolve(u,g.t,85,[4,5],{ignoreDeflect:1,label:'Force choke'})}},
 stun:{name:'Stun',f:2,tip:'Cloud an enemy’s mind. They lose their next turn and are easier to capture.',tg:u=>foesIn(u,t=>dist(u,t)<=5&&los(u,t)&&t.status==='ok').map(t=>({t,chance:75})),run:(u,g)=>{if(rnd(75)){g.t.status='stunned';g.t.ow=false;fx(g.t,'STUN');log(`${g.t.n} is stunned.`,'good')}else log(`${g.t.n} resists the stun.`)}},
 subdue:{name:'Subdue',tip:'Capture an adjacent enemy who is stunned, surrendered, or at half health. Gives intel.',tg:u=>foesIn(u,t=>cheb(u,t)===1&&t.type!=='acolyte'&&(t.status!=='ok'||t.hp*2<=t.max)).map(t=>({t,chance:t.status==='ok'?60:85})),
  run:(u,g)=>{if(rnd(g.chance)){g.t.status='captured';S.intel++;log(`${u.n} captures ${g.t.n}. +1 intel.`,'good')}else{log(`${g.t.n} breaks free.`);if(g.t.status==='surrender')g.t.status='ok'}}},
 meditate:{name:'Meditate',tip:'+2 Focus. Ends turn.',instant:1,avail:u=>u.focus>=u.maxF?'Focus full':null,run:u=>{u.focus=Math.min(u.maxF,u.focus+2);log(`${u.n} meditates.`)}},
 heal:{name:'Medkit',ap:1,tip:'Heal 4, or revive a downed ally at 2 HP. Adjacent only. Costs 1 action.',avail:u=>u.kits>0?null:'No medkits',
  tg:u=>players().filter(p=>cheb(u,p)<=1&&(p.status==='down'||p.hp<p.max)).map(t=>({t,chance:100,ally:1})),
  run:(u,g)=>{u.kits--;const t=g.t;if(t.status==='down'){t.status='ok';t.hp=2;t.bleed=0;t.ap=0;log(`${u.n} gets ${t.n} back on their feet.`,'good')}else{t.hp=Math.min(t.max,t.hp+4);log(`${u.n} patches up ${t.n}.`,'good')}fx(t,'+')}},
 grenade:{name:'Grenade',tip:'3 damage to everyone in a 3×3 area, allies too. Destroys crates.',avail:u=>u.nades>0?null:'Out of grenades',
  tg:u=>{const o=[];for(let y=0;y<H;y++)for(let x=0;x<W;x++)if(dist(u,{x,y})<=6&&!FULL(tile(x,y)))o.push({x,y,area:1});return o},run:(u,g)=>{u.nades--;log(`${u.n} throws a grenade.`);blast(g.x,g.y,3,u)}}};

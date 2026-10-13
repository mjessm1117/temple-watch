/* Troop rank-2/3 abilities from spec A §2.3 that the troop promotion picks need. Added only if abilities.js doesn't define them,
   so Chat H's versions win when they land. Stat-only picks live in PERKS (temple-data.js) and are applied in battleUnit(). */
const TROOP_AB={
 rapidFire:{name:'Rapid Fire',ic:'shoot',tip:'Two shots at −15 aim each. Ends turn. Needs a turn to cool down.',dm:u=>u.dmg,
  avail:u=>u.rfT&&S.turn<=u.rfT+1?'Cooling down':null,tg:u=>enemyT(u,u.range,t=>Math.max(5,hitChance(u,t)-15)),
  run:(u,g)=>{u.rfT=S.turn;resolve(u,g.t,g.chance,u.dmg,{label:'first shot'});if(alive(g.t)&&g.t.status==='ok')resolve(u,g.t,g.chance,u.dmg,{label:'second shot'})}},
 deadeye:{name:'Deadeye',ic:'mark',tip:'A careful shot: +3 damage, −20 aim. Ends turn.',dm:u=>[u.dmg[0]+3,u.dmg[1]+3],
  tg:u=>enemyT(u,u.range,t=>Math.max(5,hitChance(u,t)-20)),run:(u,g)=>resolve(u,g.t,g.chance,[u.dmg[0]+3,u.dmg[1]+3],{label:'deadeye shot'})},
 rally:{name:'Rally',ic:'guard',ap:1,instant:1,tip:'Allies within 4 shake off stuns, and downed allies in range stop bleeding. 1 action, once per mission.',
  avail:u=>u.rallied?'Used this mission':null,
  run:u=>{u.rallied=1;log(`${u.n} rallies the squad!`,'good');
   for(const p of S.units.filter(p=>p.side==='p'&&p!==u&&alive(p)&&dist(u,p)<=4)){if(p.status==='stunned'){p.status='ok';fx(p,'RALLY','heal')}
    if(p.status==='down'&&!p.stable){p.stable=1;p.savedBy=u.rid;fx(p,'STABLE','heal');log(`${p.n} is stabilized.`,'good')}}}},
 reviveStim:{name:'Revive Stim',ic:'stabilize',ap:1,ctx:1,tip:'Revive a downed ally up to 2 tiles away at 2 HP. Uses a medkit. 1 action.',
  avail:u=>u.kits>0?null:'No medkits',tg:u=>allyT(u,p=>p.status==='down'&&dist(u,p)<=2.9),
  run:(u,g)=>{u.kits--;const t=g.t;t.status='ok';t.hp=Math.min(t.max,2);t.bleed=0;t.stable=0;t.ap=0;t.savedBy=u.rid;fx(t,'+2','heal');log(`${u.n} jabs a stim into ${t.n}. Back up!`,'good')}},
 rocket:{name:'Rocket',ic:'grenade',dm:()=>[4,4],tip:'4 damage in a 3×3 area, allies too. Turns walls and pillars there to rubble. Once per mission. Ends turn.',
  avail:u=>u.rocketUsed?'Used this mission':null,tg:u=>tilesWhere((c,x,y)=>dist(u,{x,y})<=9&&los(u,{x,y})).map(p=>({...p,area:1})),
  run:(u,g)=>{u.rocketUsed=1;log(`${u.n} fires a rocket!`,'bad');blast(g.x,g.y,4,u);
   for(let y=g.y-1;y<=g.y+1;y++)for(let x=g.x-1;x<=g.x+1;x++)if(inb(x,y)&&FULL(S.grid[y][x])&&!'OdD'.includes(S.grid[y][x])){S.grid[y][x]='r';fx({x,y},'CRASH','boom')}}}};
for(const [k,v] of Object.entries(TROOP_AB))if(!AB[k])AB[k]=v;

/* Battle variety engine (Chat H, wave 4). Data: data-battle.js. Loads after story-era2.js, before screens.js.
   1) Twists: one per mission (rolled on the briefing, kept on the crisis option). 2) Beats: comm lines on triggers, some with a
   2-choice decision (S.bv.q; the fight waits for an answer). 3) Signature objectives on story missions (SIG primitives below).
   State: S.bv = {tw, sig, fired, gen, q, comm, res, flags, …} (saved with S). Wraps: startMission, startPlayerTurn, endTurn,
   checkEnd, threatStep, damage, blast, los, mkFoe, eAct, lootAt, hudRender, squadScreen, launchMission, applyResults. */
Object.assign(TILES,BV_TILES);FOES.wardroid=WAR_DROID;
Object.assign(TILE_IC,{z:'tremor',U:'mark',G:'dash',H:'kyber',T:'charge',P:'barrier',L:'beacon',J:'beacon',Y:'darkness'});
const bvOn=()=>typeof S!=='undefined'&&S&&S.bv&&!S.over;
const sqd=()=>players().filter(u=>!u.vip&&u.status==='ok');
const sqdReal=()=>players().filter(u=>!u.vip&&!u.guest);
const bossU=()=>S.units.find(u=>u.boss&&alive(u));
const floorNear=(p,r=3,ok=c=>c==='.')=>tilesWhere((c,x,y)=>ok(c)&&!unitAt(x,y)).filter(t=>cheb(t,{x:p[0]??p.x,y:p[1]??p.y})<=r)
 .sort((a,b)=>dist(a,{x:p[0]??p.x,y:p[1]??p.y})-dist(b,{x:p[0]??p.x,y:p[1]??p.y}));
// Put a signature tile at its spot, or the nearest free floor if the spot is taken.
function bvPlace(ch,at){const [x,y]=at;let p=tile(x,y)==='.'&&!unitAt(x,y)?{x,y}:floorNear(at,4)[0];if(!p)return null;S.grid[p.y][p.x]=ch;return p}

// ---- Twist roll: weighted, filtered by mission theme. Kept on the crisis option so the briefing and the fight agree.
function rollTwist(id){const B=MISSIONS[id],th=(B&&B.theme)||THEME_OF[id]||'plains',L=Object.entries(TWISTS).filter(([k,t])=>!t.themes||t.themes.includes(th));
 const tot=L.reduce((s,[,t])=>s+t.w,0);let r=Math.random()*tot;for(const [k,t] of L)if((r-=t.w)<0)return k;return 'ally'}
function twistFor(o){if(!o)return null;if(!o.twist||!TWISTS[o.twist])o.twist=rollTwist(o.mission);return o.twist}
function rollSide(id){const B=MISSIONS[id];if(!B||B.story)return null;const L=Object.keys(SIDES).filter(k=>!SIDES[k].types||SIDES[k].types.includes(B.type));return pickOne(L)}
function sideFor(o){if(!o||o.story)return null;if(o.side===undefined||(o.side&&!SIDES[o.side]))o.side=rollSide(o.mission);return o.side}
let BV_NEXT=null,BV_SIDE;

// ---- Mission setup
const _bvStart=startMission;
startMission=function(id,sq,o={}){const tw=o.twist||BV_NEXT||rollTwist(id),sd=o.side!==undefined?o.side:BV_SIDE!==undefined?BV_SIDE:rollSide(id);BV_NEXT=null;BV_SIDE=undefined;_bvStart(id,sq,o);S.M={...S.M};
 S.bv={tw:TWISTS[tw]?tw:null,sig:SIG[id]?id:null,fired:{},gen:0,q:[],comm:null,res:{},flags:[],locks:0,foeAim:0,side:SIDES[sd]?sd:null,sideFail:0};bvSetup();
 bvFire('twist');bvFire('turn',{n:1});render();saveGame()};
function bvSetup(){const T=TWISTS[S.bv.tw]||{},G=SIG[S.bv.sig]||{},b=S.bv;
 if(T.range)for(const u of S.units)bvRange(u);
 if(T.droids){const spots=tilesWhere((c,x,y)=>c==='.'&&y<=3&&!unitAt(x,y)).sort(()=>Math.random()-.5);
  for(let i=0;i<T.droids&&spots[i];i++){const e=mkFoe('wardroid',spots[i].x,spots[i].y);if(S.M.stealth)e.pod='ion';S.units.push(e)}}
 if(T.guest){const L=Object.entries(GUESTS).filter(([k,g])=>g.line&&g.era===(S.M.era||1)),g=pickOne(L);if(g){const u=bvGuest(g[0]);if(u)b.guest=u.uid}}
 if(G.pads){b.pad={n:0,done:0,at:G.pads.at.map(a=>bvPlace('U',a)).filter(Boolean)}}
 if(G.runner){const e=enemies().find(e=>e.type===G.runner.type);const p=bvPlace('G',G.runner.to);if(e&&p)b.run={uid:e.uid,to:p,mob:G.runner.mob,on:0}}
 if(G.relic){const p=bvPlace('H',G.relic.at);if(p)b.relic={x:p.x,y:p.y,by:null}}
 if(G.bombs)b.bombs=[];
 if(G.pylons){b.pyl={};for(const a of G.pylons.at){const p=bvPlace('P',a);if(p)b.pyl[p.x+','+p.y]=PYLON_HP}}
 if(G.switches){b.sw={n:0,need:0};for(const a of G.switches.at)if(bvPlace('L',a))b.sw.need++}
 if(G.wounded){b.wd=[];const L=Object.entries(GUESTS).filter(([k,g])=>g.era===2&&CLASS[g.cls]&&CLASS[g.cls].jedi);
  for(const a of G.wounded.at){const p=tile(a[0],a[1])==='.'&&!unitAt(a[0],a[1])?{x:a[0],y:a[1]}:floorNear(a,3)[0];if(!p)continue;
   const u=bvGuest(L.length?pickOne(L)[0]:'wynn',p,{n:pickOne(['Knight Ilen Varo','Padawan Sesh Ruul','Knight Dora Kett','Padawan Tam Orrin'])});
   if(u){u.status='down';u.hp=0;u.stable=1;u.wounded=1;u.ap=0;b.wd.push(u.uid)}}}
 if(G.spread)b.sp={on:1};
 if(G.keyholder){const K=G.keyholder,e=enemies().filter(e=>e.type===K.type).sort((a,c)=>dist(a,{x:K.near[0],y:K.near[1]})-dist(c,{x:K.near[0],y:K.near[1]}))[0]||enemies().find(e=>!e.boss);
  if(e){e.key=1;e.n=K.name;e.noCap=0;b.key={uid:e.uid,done:0}}}
 if(G.barrage){const e=enemies().find(e=>e.type===G.barrage.spotter)||enemies().find(e=>!e.boss&&e.range>=8);if(e){e.spotter=1;e.n='Spotter '+e.n.replace(/ \d+$/,'')}b.bar={uid:e?e.uid:null,zones:[]}}
 const F=['defuse','light','rouse','wreck'].filter(k=>(k==='defuse'&&G.bombs)||(k==='light'&&G.switches)||(k==='rouse'&&G.wounded)||(k==='wreck'&&G.pylons));
 for(const u of players())for(const k of F)if(!u.vip&&!u.abil.includes(k))u.abil.push(k)}
function bvRange(u){const T=TWISTS[S.bv&&S.bv.tw];if(T&&T.range&&u.range>=2&&!u.rng0){u.rng0=u.range;u.range=Math.max(3,u.range+T.range)}}
// A guest fighter: a roster-less unit (no rid), so XP, wounds and death never touch the campaign.
function bvGuest(k,at,extra={}){const g=GUESTS[k];if(!g||!CLASS[g.cls])return null;const base=battleUnit({n:g.n,cls:g.cls,rank:g.rank||1,xp:0,dark:0,picks:[],col:g.col});
 delete base.rid;const p=at||floorNear(S.M.start[0],4,c=>PASS(c)&&c!=='E')[0];if(!p)return null;
 const u=mk({...base,...extra},'p',{x:p.x,y:p.y,guest:1});bvRange(u);for(const k2 of ['defuse','light','rouse','wreck'])if(players()[0]&&players()[0].abil.includes(k2)&&!u.abil.includes(k2))u.abil.push(k2);
 S.units.push(u);fx(u,'ALLY','heal');log(`${u.n} joins the fight.`,'good');return u}
const _bvMkFoe=mkFoe;mkFoe=function(t,x,y){const e=_bvMkFoe(t,x,y);if(S.bv){bvRange(e);e.aim+=S.bv.foeAim||0}return e};

// ---- Sight (blackout): nothing is seen or shot past the twist's vision. Sense users see 3 further.
const _bvLos=los;los=function(a,b){if(S&&S.bv&&S.bv.tw){const v=(TWISTS[S.bv.tw]||{}).vision;if(v&&dist(a,b)>v+(a.sense||b.sense?3:0))return false}return _bvLos(a,b)};

// ---- Turn flow
const _bvSPT=startPlayerTurn;
startPlayerTurn=function(){if(S.bv&&S.bv.mobB){for(const u of players())if(u.mobB){u.mob-=u.mobB;u.mobB=0}S.bv.mobB=0}
 _bvSPT();if(!bvOn()||S.phase!=='player')return;const b=S.bv,T=TWISTS[b.tw]||{},G=SIG[b.sig]||{};
 if(T.ionStun){for(const u of S.units.filter(u=>alive(u)&&!u.vip))u.shield=0;
  for(const e of S.units.filter(u=>alive(u)&&u.status==='ok'&&tagsOf(u).includes('droid')))if(rnd(T.ionStun)){e.status='stunned';fx(e,'ION','defl');log(`${e.n} shorts out in the ion storm.`,e.side==='e'?'good':'bad')}}
 if(T.cracks)bvCrack(T.cracks);
 if(b.pad)bvPadTick(G.pads);
 if(b.bombs)bvBombs(G.bombs);
 if(b.sp)bvSpread(G.spread);
 if(b.bar)bvBarrage(G.barrage);
 if(S.over)return;
 bvFire('turn',{n:S.turn});bvFire('threat',{n:S.threat});checkEnd();render()};
const _bvEnd=endTurn;endTurn=async function(){if(S&&S.bv&&S.bv.q.length&&!S.over){render();return}return _bvEnd()};
// Threat rises can be cancelled by banked locks (dock: lift controls).
const _bvThr=threatStep;threatStep=function(){if(S.bv&&S.bv.locks>0&&S.threat>0){S.bv.locks--;S.threat--;fx(players()[0]||{x:5,y:5},'LOCKED','heal');log('The lifts stay locked: Threat does not rise this turn.','good');return}return _bvThr()};
const _bvCheck=checkEnd;
checkEnd=function(){if(!S||S.over)return _bvCheck();if(S.bv){bvWatch();if(S.over)return}
 // Guests can't carry a mission alone: once every real squad member is down, it's lost.
 if(S.bv&&players().some(u=>u.guest)&&!sqdReal().some(u=>u.status==='ok'))return finish(false,'The squad is overwhelmed.');return _bvCheck()};
// Watches state changes between actions: keyholder, runner, spotter, objective at half.
function bvWatch(){const b=S.bv;
 if(b.key&&!b.key.done){const e=byId(b.key.uid);if(!e||!alive(e)){b.key.done=1;unlock(null);S.threat=Math.max(0,S.threat-1);fx(e||{x:5,y:3},'KEY','heal');log('The jailer\'s key opens the cell. Threat −1.','good');bvFire('keyTaken')}}
 if(b.bar&&b.bar.uid!=null){const e=byId(b.bar.uid);if(!e||!alive(e)||e.status!=='ok'&&e.status!=='stunned'){b.bar.uid=null;b.bar.zones=[];log('The spotter is down. The guns go blind.','good');bvFire('spotterDown')}}
 if(b.run&&b.run.on!==2){const e=byId(b.run.uid);if(e&&alive(e)&&e.status==='ok'&&!b.run.on&&(S.turn>=SIG[b.sig].runner.start||sqd().some(p=>dist(p,e)<=4&&los(p,e)))){b.run.on=1;e.ow=false;bvFire('runner')}}
 if(S.type==='defend'&&S.obj*2<=S.M.obj)bvFire('objHalf')}

// ---- Beats
function bvSub(s,c={}){const u=c.unit!=null&&byId(c.unit),h=hostage(),B=bossU(),J=players().find(p=>p.jedi&&p.status==='ok'),g=S.bv.guest!=null&&byId(S.bv.guest);
 return String(s||'').replace(/\{unit\}/g,u?u.n:'A squadmate').replace(/\{vip\}/g,h?h.n:'The VIP').replace(/\{boss\}/g,B?B.n:'The enemy commander')
  .replace(/\{jedi\}/g,J?J.n:'A Jedi').replace(/\{guest\}/g,g?g.n:'Ally').replace(/\{gline\}/g,g?(Object.values(GUESTS).find(x=>x.n===g.n)||{}).line||'':'')
  .replace(/\{cmd\}/g,(S.M.era||1)>=2?'Army of Light':'Republic Command')}
function bvMatch(B,ev,c){if(B.on!==ev)return false;if(B.n!=null&&(ev==='turn'?c.n!==B.n:ev==='threat'?(c.n||0)<B.n:false))return false;
 if(B.types&&!B.types.includes(S.type))return false;if(B.crisis&&!S.crisis)return false;if(B.twist&&B.twist!==S.bv.tw)return false;
 if(B.when==='runner'&&!(S.bv.run&&S.bv.run.on===1))return false;
 if(B.on==='vipHit'&&!hostage())return false;if(B.on==='bossHalf'&&!bossU())return false;return true}
function bvFire(ev,c={}){if(!bvOn())return;const b=S.bv,G=(SIG[b.sig]||{}).beats||[];
 const own=G.map((B,i)=>[B,'s'+i]).filter(([B,k])=>!b.fired[k]&&bvMatch(B,ev,c));
 for(const [B,k] of own){b.fired[k]=1;bvBeat(B,c)}
 if(G.some(B=>B.on===ev&&ev!=='turn'))return;
 const gen=BEATS.filter(B=>!b.fired[B.id]&&bvMatch(B,ev,c));if(!gen.length)return;
 if(ev==='twist'){for(const B of gen){b.fired[B.id]=1;bvBeat(B,c)}return}
 if(b.gen>=3||own.some(([B])=>B.choice)&&gen.every(B=>B.choice))return;const B=pickOne(gen);b.fired[B.id]=1;b.gen++;bvBeat(B,c)}
function bvBeat(B,c){const who=bvSub(B.who,c),txt=bvSub(B.txt,c);S.bv.comm={who,txt,turn:S.turn};log(`${who}: “${txt}”`,'beat');bvHist(`T${S.turn} ${who}: ${txt}`);
 if(B.do)bvDo(B.do,c);if(B.choice)S.bv.q.push({who,txt,a:B.choice.a,b:B.choice.b,c:{unit:c.unit}})}
const bvHist=t=>{const h=S.bv.hist=S.bv.hist||[];h.push(t);if(h.length>24)h.shift()};
// Answer the open decision (0 = first option). Called by the comm box buttons and the test bot.
function bvPick(i){if(!S||!S.bv||!S.bv.q.length)return;const q=S.bv.q.shift(),o=i?q.b:q.a;
 log(`→ ${o.label}: ${bvSub(o.txt,q.c)}`,'beat');bvHist(`→ ${o.label}`);S.bv.comm={who:'You chose',txt:`${o.label}. ${bvSub(o.txt,q.c)}`,turn:S.turn};bvDo(o.do||{},q.c);checkEnd();render();saveGame()}

// ---- Effects
function bvDo(d,c={}){const b=S.bv,ok=sqd(),J=ok.filter(u=>u.jedi),E=()=>enemies().filter(e=>e.status==='ok'&&!e.boss&&!e.key),h=hostage(),B=bossU();
 for(const [k,v] of Object.entries(d))switch(k){
  case 'aim':for(const u of ok)u.buffAim=(u.buffAim||0)+v;break;
  case 'mob':for(const u of ok){u.mob+=v;u.mobB=(u.mobB||0)+v}b.mobB=1;break;
  case 'foeAim':b.foeAim+=v;for(const e of enemies())e.aim+=v;break;
  case 'heal':for(const u of ok){const n=Math.min(v,u.max-u.hp);if(n>0){u.hp+=n;fx(u,'+'+n,'heal')}}break;
  case 'focus':for(const u of J)u.focus=Math.max(0,Math.min(u.maxF,u.focus+v));break;
  case 'threat':if(S.M.par)S.threat=Math.max(0,Math.min(5,S.threat+v));break;
  case 'obj':if(S.type==='defend')S.obj=Math.max(0,Math.min(S.M.obj,S.obj+v));break;
  case 'intel':S.intel+=v;break;
  case 'orderDark':S.orderDark+=v;break;
  case 'dark':{const t=c.unit!=null&&byId(c.unit),u=t&&t.jedi&&t.status==='ok'?t:pickOne(J);if(u)addDark(u,v);break}
  case 'stunBoss':if(B&&B.status==='ok'){B.status='stunned';fx(B,'STUNNED','defl')}break;
  case 'rootBoss':if(B){B.rooted=1;fx(B,'ROOTED','defl')}break;
  case 'hurtBoss':if(B&&B.status!=='dead')damage(B,v,null);break;
  case 'splash':if(B)for(const u of ok.filter(u=>cheb(u,B)<=1))damage(u,v,null);break;
  case 'ally':for(const g of v)bvGuest(g);break;
  case 'turns':if(S.M.turns)S.M.turns=Math.max(S.turn,S.M.turns+v);break;
  case 'res':for(const [r,n] of Object.entries(v))b.res[r]=(b.res[r]||0)+n;break;
  case 'flag':b.flags.push(v);break;
  case 'foeStun':for(const e of E().sort(()=>Math.random()-.5).slice(0,v)){e.status='stunned';fx(e,'STUNNED','defl')}break;
  case 'strafe':for(const e of enemies().filter(e=>e.status==='ok'&&!e.hid).sort(()=>Math.random()-.5).slice(0,3))damage(e,v,null);break;
  case 'shieldVip':if(h){h.shield=(h.shield||0)+v;fx(h,'SHIELD','defl')}break;
  case 'healVip':if(h&&h.status==='ok'){h.hp=Math.min(h.max,h.hp+v);fx(h,'+'+v,'heal')}break;
  case 'vipMob':if(h)h.mob+=v;break;
  case 'stabDown':{const t=c.unit!=null&&byId(c.unit);if(t&&t.status==='down'){t.stable=1;fx(t,'STABLE','heal')}break}
  case 'surrender':{const e=pickOne(E().filter(e=>!e.noCap&&!e.fanatic));if(e){e.status='surrender';e.ow=false;fx(e,'SURRENDERS','heal')}else bvDo({foeStun:1});break}
  case 'remove':for(const e of E().sort(()=>Math.random()-.5).slice(0,v)){S.units=S.units.filter(x=>x!==e);log(`${e.n} pulls out of the fight.`,'good')}break;
  case 'reinforce':dropship(v);break;
  case 'pad':if(b.pad){b.pad.n+=v;bvPadDone()}break;
  case 'lock':b.locks+=v;break;
  case 'runnerSlow':if(b.run)b.run.mob=2;break;
  case 'free':unlock(null);break}}

// ---- Twist: unstable ground. Last turn's cracks fall; new ones open near the squad. Never cuts the squad off from evac.
function bvCrack(n){const b=S.bv;for(const p of tilesWhere(c=>c==='z')){S.grid[p.y][p.x]='V';fx(p,'COLLAPSE','boom');const u=unitAt(p.x,p.y);
  if(u){if(u.status==='ok')damage(u,3,null);const to=floorNear(p,2,c=>PASS(c))[0];if(to){u.x=to.x;u.y=to.y}log(`The floor gives way under ${u.n}!`,'bad')}else log('A section of floor falls away.')}
 if(S.turn<2||tilesWhere(c=>c==='V').length>=10)return;
 const near=sqd();for(let i=0;i<n;i++){const C=tilesWhere((c,x,y)=>c==='.'&&near.some(u=>cheb(u,{x,y})<=3)).sort(()=>Math.random()-.5);
  const p=C.find(p=>bvSafeCut(p));if(!p)break;S.grid[p.y][p.x]='z';fx(p,'CRACK','dmg')}
 if(tilesWhere(c=>c==='z').length)log('The floor cracks. Those tiles fall next turn.','bad')}
function bvSafeCut(p){const E=tilesWhere(c=>c==='E');if(!E.length)return true;const g=S.grid.map(r=>[...r]);g[p.y][p.x]='V';
 const from=players().filter(u=>u.status==='ok');for(const u of from){const seen=new Set([u.x+','+u.y]),q=[[u.x,u.y]];let hit=0;
  while(q.length){const [x,y]=q.shift();if(g[y][x]==='E'){hit=1;break}for(const [dx,dy] of N4){const nx=x+dx,ny=y+dy,c=inb(nx,ny)&&g[ny][nx];
   if(c&&c!=='z'&&(PASS(c)||'dD'.includes(c))&&!seen.has(nx+','+ny)){seen.add(nx+','+ny);q.push([nx,ny])}}}if(!hit)return false}return true}

// ---- Signature primitives
function bvPadTick(cfg){const b=S.bv,on=sqd().some(u=>tile(u.x,u.y)==='U');if(!on)return;b.pad.n++;fx(sqd().find(u=>tile(u.x,u.y)==='U'),'HELD','heal');
 if(cfg.each)bvDo(cfg.each);log(cfg.need?`Pad held (${Math.min(b.pad.n,cfg.need)}/${cfg.need}).`:'Lift control held: one Threat rise will be cancelled.','good');bvPadDone()}
function bvPadDone(){const b=S.bv,cfg=SIG[b.sig].pads;if(!cfg.need||b.pad.done||b.pad.n<cfg.need)return;b.pad.done=1;if(cfg.done)bvDo(cfg.done);bvFire('padDone')}
function bvBombs(cfg){const b=S.bv;for(const m of [...b.bombs]){m.t--;if(m.t>0)continue;b.bombs=b.bombs.filter(x=>x!==m);S.grid[m.y][m.x]='r';log('A sapper charge goes off!','bad');blast(m.x,m.y,3,null);
  if(S.type==='defend'&&tilesWhere(c=>c==='O').some(o=>cheb(o,m)<=3)){S.obj=Math.max(0,S.obj-cfg.objDmg);log(`The cave mouth shakes: −${cfg.objDmg}.`,'bad')}}
 const n=cfg.plant[S.turn]||0;if(!n)return;const C=floorNear(cfg.near,cfg.r).filter(p=>!sqd().some(u=>cheb(u,p)<=1)).sort(()=>Math.random()-.5);
 for(const p of C.slice(0,n)){S.grid[p.y][p.x]='T';b.bombs.push({x:p.x,y:p.y,t:cfg.timer});fx(p,'CHARGE','dmg')}
 if(n){log(`Imperial sappers plant ${n} charge${n>1?'s':''}. Defuse within ${cfg.timer} turns.`,'bad');bvFire('bomb')}}
function bvSpread(cfg){const b=S.bv;if(!b.sp.on)return;
 for(const u of sqd().filter(u=>tile(u.x,u.y)==='Y')){if(u.jedi){addDark(u,1);fx(u,'ROT','dark')}else damage(u,1,null)}
 if(S.turn<cfg.start)return;const src={x:cfg.src[0],y:cfg.src[1]},Q=sqd(),cx=Q.reduce((s,u)=>s+u.x,0)/(Q.length||1),cy=Q.reduce((s,u)=>s+u.y,0)/(Q.length||1);
 const C=tilesWhere((c,x,y)=>c==='.'&&(N4.some(([dx,dy])=>'YP'.includes(tile(x+dx,y+dy))))&&dist({x,y},src)<=9).sort((a,c)=>dist(a,{x:cx,y:cy})-dist(c,{x:cx,y:cy}));
 for(const p of C.slice(0,cfg.per)){S.grid[p.y][p.x]='Y';fx(p,'ROT','dark')}if(C.length)log('The dark ground spreads.','dark')}
function bvBarrage(cfg){const b=S.bv;
 for(const z of b.bar.zones){fx(z,'SHELL','boom');for(const u of S.units.filter(u=>alive(u)&&u.status==='ok'&&cheb(u,z)<=1))damage(u,cfg.dmg,null);
  for(let y=z.y-1;y<=z.y+1;y++)for(let x=z.x-1;x<=z.x+1;x++)if(inb(x,y)&&TILES[S.grid[y][x]].breaks&&rnd(50))degrade(x,y)}
 if(b.bar.zones.length)log('Artillery shells land!','bad');b.bar.zones=[];
 if(b.bar.uid==null||S.turn<cfg.start)return;const T=sqd().sort(()=>Math.random()-.5).slice(0,cfg.per);
 for(const u of T){const z={x:Math.max(0,Math.min(W-1,u.x+ri(-1,1))),y:Math.max(0,Math.min(H-1,u.y+ri(-1,1)))};b.bar.zones.push(z);fx(z,'INCOMING','dmg')}
 if(T.length)log('The spotter calls in shells: red zones get hit next turn.','bad')}
function hitPylon(x,y,d){const b=S.bv,k=x+','+y;if(!b||!b.pyl||b.pyl[k]==null)return;b.pyl[k]-=d;fx({x,y},'-'+d,'dmg');
 if(b.pyl[k]>0)return log(`The ${TILES.P.n.toLowerCase()} sparks (${b.pyl[k]} left).`);delete b.pyl[k];S.grid[y][x]='r';fx({x,y},'DOWN','boom');
 const cfg=SIG[b.sig].pylons,left=Object.keys(b.pyl).length;log(left?`A ${cfg.shieldBoss?'pylon':'stone'} falls. ${left} left.`:`The last ${cfg.shieldBoss?'pylon':'stone'} falls!`,'good');
 if(b.sp&&SIG[b.sig].spread){b.sp.on=0;for(const p of tilesWhere(c=>c==='Y'))S.grid[p.y][p.x]='.'}
 if(cfg.each)bvDo(cfg.each);if(!left){if(cfg.done)bvDo(cfg.done);bvFire(cfg.doneEv||'pylonsDown')}}
const bvShielded=t=>t.boss&&S.bv&&S.bv.pyl&&Object.keys(S.bv.pyl).length&&(SIG[S.bv.sig].pylons||{}).shieldBoss;
// Runner: moves toward its getaway instead of fighting; gone if it reaches it.
const _bvEAct=eAct;eAct=async function(e){const r=S.bv&&S.bv.run;if(!r||r.uid!==e.uid||!r.on||r.on===2||e.status!=='ok')return _bvEAct(e);
 if(e.rooted){e.rooted=0;return}const m0=e.mob;e.mob=r.mob;const R=reach(e);e.mob=m0;let best=null,bd=dist(e,r.to);
 for(const k of Object.keys(R.d)){const [x,y]=k.split(',').map(Number);const d=dist({x,y},r.to);if(d<bd){bd=d;best={x,y}}}
 if(best){moveAlong(e,pathTo(e,best.x,best.y,R.prev));log(`${e.n} runs for the speeder.`,'bad')}
 if(alive(e)&&e.status==='ok'&&cheb(e,r.to)<=1){r.on=2;S.units=S.units.filter(x=>x!==e);fx(r.to,'ESCAPED','dmg');log(`${e.n} reaches the speeder and is gone.`,'bad');bvFire('runnerGone')}};
// Relic: pick up by stepping on it; dropped where the carrier falls.
const _bvLoot=lootAt;lootAt=function(u){_bvLoot(u);const r=S.bv&&S.bv.relic;if(!r||r.by!=null||u.vip||u.x!==r.x||u.y!==r.y)return;
 r.by=u.uid;u.mob--;S.grid[u.y][u.x]='.';fx(u,'HOLOCRON','heal');log(`${u.n} takes the holocron (−1 move while carrying it).`,'good');bvFire('relic')};
function bvDrop(u){const r=S.bv.relic;r.by=null;u.mob++;const p=tile(u.x,u.y)==='.'?{x:u.x,y:u.y}:floorNear(u,2)[0];if(!p)return;r.x=p.x;r.y=p.y;S.grid[p.y][p.x]='H';log(`${u.n} drops the holocron.`,'bad')}

// ---- Damage hooks: boss shield, VIP / downed / boss-half triggers, relic drop.
const _bvDmg=damage;damage=function(t,d,src){if(!S||!S.bv)return _bvDmg(t,d,src);
 if(bvShielded(t)){fx(t,'SHIELDED','defl');log(`${t.n} is untouchable while the pylons stand.`);return}
 const st=t.status,hp=t.hp;_bvDmg(t,d,src);if(S.over)return;
 if(t.vip&&t.hp<hp){bvFire('vipHit');if(S.bv.side==='vipSafe')S.bv.sideFail=1}
 if(t.side==='p'&&!t.vip&&!t.guest&&st==='ok'&&t.status==='down'){bvFire('down',{unit:t.uid});if(S.bv.side==='noDown')S.bv.sideFail=1}
 if(t.boss&&alive(t)&&t.hp*2<=t.max)bvFire('bossHalf');
 if(S.bv.relic&&S.bv.relic.by===t.uid&&t.status!=='ok')bvDrop(t)};
const _bvBlast=blast;blast=function(x,y,d,src,seen){_bvBlast(x,y,d,src,seen);if(S.bv&&S.bv.pyl)for(let yy=y-1;yy<=y+1;yy++)for(let xx=x-1;xx<=x+1;xx++)if(inb(xx,yy)&&S.grid[yy][xx]==='P')hitPylon(xx,yy,d)};
// Shooting pylons: they show up as targets like barrels and beacons (always hit).
// Quiet hands: any Focus-costing power by the squad fails it.
const _bvExec=exec;exec=function(u,k,g){if(S.bv&&S.bv.side==='quiet'&&u.side==='p'&&AB[k]&&AB[k].f)S.bv.sideFail=1;return _bvExec(u,k,g)};
const _bvShTg=AB.shoot.tg,_bvShRun=AB.shoot.run;
AB.shoot.tg=u=>{const L=_bvShTg(u);if(S.bv&&S.bv.pyl)for(const k of Object.keys(S.bv.pyl)){const [x,y]=k.split(',').map(Number);if(dist(u,{x,y})<=u.range&&los(u,{x,y}))L.push({x,y,pylon:1,chance:100})}return L};
AB.shoot.run=(u,g)=>g.pylon?(log(`${u.n} shoots the ${TILES.P.n.toLowerCase()}.`),hitPylon(g.x,g.y,ri(u.dmg[0],u.dmg[1]))):_bvShRun(u,g);

// ---- Field actions (added to the squad only on missions that need them).
Object.assign(AB,{
 defuse:{name:'Defuse charge',ic:'charge',ap:1,ctx:1,tip:'Disarm an adjacent sapper charge. 1 action.',desc:'Disarm an adjacent enemy charge before it blows. 1 action.',tg:u=>adjTiles(u,'T'),
  run:(u,g)=>{S.grid[g.y][g.x]='.';S.bv.bombs=S.bv.bombs.filter(m=>m.x!==g.x||m.y!==g.y);fx(g,'DEFUSED','heal');log(`${u.n} defuses the charge.`,'good')}},
 light:{name:'Light brazier',ic:'beacon',ap:1,ctx:1,tip:'Light an adjacent signal brazier. 1 action.',desc:'Light an adjacent signal brazier. 1 action.',tg:u=>adjTiles(u,'L'),
  run:(u,g)=>{const b=S.bv;S.grid[g.y][g.x]='J';b.sw.n++;fx(g,'LIT','heal');log(`${u.n} lights the brazier (${b.sw.n}/${b.sw.need}).`,'good');
   if(b.sw.n>=b.sw.need){const c=SIG[b.sig].switches;if(c.done)bvDo(c.done);bvFire(c.doneEv||'switchesDone')}}},
 rouse:{name:'Help up',ic:'stabilize',ap:1,ctx:1,tip:'Get an adjacent wounded Jedi back on their feet (3 HP). They fight with you. 1 action.',desc:'Get a wounded Jedi back on their feet at 3 HP. 1 action.',
  tg:u=>allyT(u,p=>p.wounded&&p.status==='down'&&cheb(u,p)===1),run:(u,g)=>{const t=g.t;t.status='ok';t.hp=3;t.wounded=0;t.ap=0;t.stable=0;fx(t,'UP','heal');log(`${u.n} gets ${t.n} back on their feet.`,'good');bvFire('rouse')}},
 wreck:{name:'Wreck',ic:'strike',ap:1,ctx:1,tip:'Hack at an adjacent pylon or stone: 3 damage. 1 action.',desc:'3 damage to an adjacent pylon or ritual stone. 1 action.',tg:u=>adjTiles(u,'P').map(p=>({...p,chance:100})),
  run:(u,g)=>{log(`${u.n} hacks at the ${TILES.P.n.toLowerCase()}.`);hitPylon(g.x,g.y,3)}}});

// ---- Results: signature rewards and flags on a win.
function sigStat(){const b=S.bv,G=SIG[b&&b.sig];if(!G)return null;let v='';
 if(b.pad)v=G.pads.need?(b.pad.done?'done ✓':`${b.pad.n}/${G.pads.need} turns held`):`${b.locks} lock${b.locks===1?'':'s'} banked`;
 if(b.run)v=b.run.on===2?'escaped':(()=>{const e=byId(b.run.uid);return !e||!alive(e)?'stopped ✓':b.run.on?'running!':'not running yet'})();
 if(b.relic)v=b.relic.by!=null?'carried':'in the vault';
 if(b.bombs)v=b.bombs.length?b.bombs.map(m=>`${m.t} turn${m.t>1?'s':''}`).join(', ')+' left':'no live charges';
 if(b.pyl&&!b.sp){const n=Object.keys(b.pyl).length;v=n?`${n} standing`:'all down ✓'}
 if(b.sw)v=`${b.sw.n}/${b.sw.need} lit`;
 if(b.wd)v=`${b.wd.filter(id=>{const u=byId(id);return u&&u.status==='ok'}).length}/${b.wd.length} on their feet`;
 if(b.sp)v=b.sp.on?`${tilesWhere(c=>c==='Y').length} rot tiles`:'cleansed ✓';
 if(b.key)v=b.key.done?'cell open ✓':'jailer holds it';
 if(b.bar)v=b.bar.uid!=null?'spotter alive':'guns blind ✓';
 return{n:G.n,v,desc:G.desc}}
function sideOk(){const b=S.bv,k=b&&b.side;if(!k||b.sideFail)return false;const E=S.units.filter(u=>u.side==='e');
 return k==='prisoner'?E.some(e=>e.status==='captured'):k==='elite'?E.some(e=>(isElite(e)||e.force)&&!alive(e)):k==='sweep'?!enemies().some(e=>e.status==='ok'):k==='pristine'?S.obj*10>=S.M.obj*9:true}
function sideStat(){const b=S.bv,k=b&&b.side;if(!k)return null;const D=SIDES[k],live=['noDown','quiet','vipSafe','pristine'].includes(k);
 return{n:D.n,desc:D.desc,v:b.sideFail?'failed ✗':sideOk()?(live?'on track':'done ✓'):'not yet',res:D.res}}
function sigWon(){const b=S.bv,G=SIG[b.sig]||{},res={...b.res},flags=[...b.flags];if(sideOk())for(const [k,v] of Object.entries(SIDES[b.side].res))res[k]=(res[k]||0)+v;
 if(b.relic&&b.relic.by!=null){const u=byId(b.relic.by);if(u&&u.status==='ok'){for(const [k,v] of Object.entries(G.relic.res))res[k]=(res[k]||0)+v;flags.push(G.relic.flag)}}
 if(b.wd)for(const id of b.wd){const u=byId(id);if(u&&u.status==='ok')for(const [k,v] of Object.entries(G.wounded.res))res[k]=(res[k]||0)+v}
 return{res,flags}}
const _bvApply=applyResults;applyResults=function(win){const out=_bvApply(win);if(!S.bv||!win||!out)return out;const {res,flags}=sigWon();
 for(const [k,v] of Object.entries(res))gain(k,v,out.res);for(const f of flags)C.flags[f]=1;if(Object.keys(res).length)out.bvRes=res;return out};
const _bvLaunch=launchMission;launchMission=function(i,ids){BV_NEXT=twistFor(C.options[i]);BV_SIDE=sideFor(C.options[i]);return _bvLaunch(i,ids)};

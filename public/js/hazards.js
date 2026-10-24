/* Biome hazards (Chat H wave 4; rebuilt by Chat S wave 9). Data: HZ_KIND, HAZARDS + hazard tiles in data-battle.js. Loads after battle.js.
   Five kinds, one rule each, same for both sides: Burn (hurt on entry + each round), Shock (pulse: live on even turns, 2 + stun),
   Slow (move ends there), Slide (keep sliding, max 3; 1 damage if you slam), Fall (chasm: push enemies over the edge).
   Weapons: anything moved by pushN (Push, Pull, Throw…) enters the hazard it lands on; Slow roots an enemy for its next turn.
   Telegraphs: hover a hazard tile for its rule; the move path warns before you click; Push shows where the target lands;
   conduits announce the turn before they go live.
   Wraps: startMission, moveAlong, reach, pushN, startPlayerTurn, tileScore, hintText, hudRender, squadScreen, panelFor. */
const HZ=c=>TILES[c]||{};
const hzLive=(c,turn=S.turn)=>{const t=HZ(c);return !!t.hurt&&(!t.pulse||turn%2===0)};
const hzSet=()=>S&&S.bv&&HAZARDS[S.bv.hz];
const hzKind=c=>HZ_KIND[HZ(c).kind];

const _hzStart=startMission;
startMission=function(id,sq,o={}){_hzStart(id,sq,o);if(!S.bv)return;const th=S.theme||'plains';
 S.bv.hz=o.hazards===false||(MISSIONS[id]||{}).noHaz?null:HAZARDS[th]?th:null;if(S.bv.hz)hzPlace(HAZARDS[th]);render();saveGame()};
function hzPlace(Z){const keep=[...S.units.filter(u=>alive(u)),...tilesWhere(c=>'OEkqCDbHTPLUG'.includes(c))];
 const free=(x,y)=>S.grid[y][x]==='.'&&!keep.some(k=>cheb(k,{x,y})<=1);let put=0;
 for(let p=0,tries=0;p<Z.patches&&tries<40;tries++){const C=tilesWhere((c,x,y)=>free(x,y)&&y>=2);if(!C.length)break;
  const s=pickOne(C),ch=pickOne(Z.tiles),n=ri(2,3),cells=[s];
  for(let i=1;i<n;i++){const b=pickOne(cells),[dx,dy]=pickOne(N4),q={x:b.x+dx,y:b.y+dy};if(inb(q.x,q.y)&&free(q.x,q.y)&&!cells.some(c=>c.x===q.x&&c.y===q.y))cells.push(q)}
  const old=cells.map(c=>S.grid[c.y][c.x]);for(const c of cells)S.grid[c.y][c.x]=ch;
  if(!HZ(ch).walk&&!hzReach()){cells.forEach((c,i)=>S.grid[c.y][c.x]=old[i]);continue}p++;put+=cells.length}
 if(put)log(`Terrain: ${Z.n}. Hover a tile to see what it does. Push enemies into it.`,'bad')}
// Every standing squad member can still walk to an evac zone (doors count as open). Maps without evac pass.
function hzReach(){const E=tilesWhere(c=>c==='E');if(!E.length)return true;
 for(const u of players().filter(u=>u.status==='ok')){const seen=new Set([u.x+','+u.y]),q=[[u.x,u.y]];let hit=0;
  while(q.length){const [x,y]=q.shift();if(S.grid[y][x]==='E'){hit=1;break}for(const [dx,dy] of N4){const nx=x+dx,ny=y+dy,c=inb(nx,ny)&&S.grid[ny][nx];
   if(c&&(PASS(c)||'dD'.includes(c))&&!seen.has(nx+','+ny)){seen.add(nx+','+ny);q.push([nx,ny])}}}if(!hit)return false}return true}

// One tile entered (walked, slid or pushed): hurt / shock, then report whether movement should stop.
function hzEnter(u){const c=tile(u.x,u.y),t=HZ(c);if(!alive(u)||u.status==='down')return true;
 if(t.hurt&&hzLive(c)){const k=hzKind(c)||{};fx(u,(k.n||t.n).toUpperCase(),'dmg');log(`${u.n} ${t.kind==='shock'?'is shocked by':t.kind==='burn'?'burns in':'is cut by'} the ${t.n.toLowerCase()}.`,u.side==='p'?'bad':'good');damage(u,t.hurt,null);
  if(t.stun&&u.status==='ok'&&!u.boss){u.ow=false;
   if(u.side==='e'){u.status='stunned';fx(u,'STUNNED','defl');log(`${u.n} is stunned by the shock.`,'good')}
   else if(S.phase==='player'){u.ap=Math.max(0,(u.ap||0)-1);fx(u,'−1 ACTION','defl');log(`${u.n} is jolted: −1 action.`,'bad')}else{u.shockAP=1;log(`${u.n} is jolted: −1 action next turn.`,'bad')}}}
 return !!t.stop||u.status!=='ok'}
// Slide while on slick tiles, the way the unit was moving. Slamming into something mid-slide hurts 1. Returns true if it moved.
function hzSlide(u,dx,dy){let moved=false;for(let i=0;i<3&&HZ(tile(u.x,u.y)).slide&&u.status==='ok';i++){const nx=u.x+dx,ny=u.y+dy;
  if(!inb(nx,ny)||!PASS(tile(nx,ny))||unitAt(nx,ny)||Math.abs(elevAt(nx,ny)-elevAt(u.x,u.y))>1){if(moved){fx(u,'SLAM','dmg');log(`${u.n} slides into ${inb(nx,ny)&&unitAt(nx,ny)?unitAt(nx,ny).n:'a wall'}.`,u.side==='p'?'bad':'good');damage(u,1,null)}break}
  if(!moved){fx(u,'SLIDE','miss');log(`${u.n} slides on the ${HZ(tile(u.x,u.y)).n.toLowerCase()}.`)}moved=true;
  _hzMove(u,[{x:nx,y:ny}]);if(hzEnter(u))break}return moved}
const _hzMove=moveAlong;
moveAlong=function(u,path){if(!hzSet())return _hzMove(u,path);
 for(const s of path){const dx=Math.sign(s.x-u.x),dy=Math.sign(s.y-u.y),c0=S.conc;_hzMove(u,[s]);if(u.x!==s.x||u.y!==s.y||u.status!=='ok'||(c0&&!S.conc))break;
  if(hzEnter(u))break;if(HZ(tile(u.x,u.y)).slide){hzSlide(u,dx,dy);break}}};
// Slow tiles: a move may end on them but never pass through.
const _hzReach=reach;
reach=function(u){const R=_hzReach(u);if(!hzSet())return R;const s=u.x+','+u.y;
 for(const k of Object.keys(R.d)){let p=R.prev[k];while(p&&p!==s){const [x,y]=p.split(',').map(Number);if(HZ(tile(x,y)).stop){delete R.d[k];break}p=R.prev[p]}}return R};

// ── Hazards as weapons. Where a shove lands: same steps as rules.js pushN, without moving anyone. ──
function hzLand(t,dx,dy,n){let x=t.x,y=t.y;for(let i=0;i<n;i++){const nx=x+dx,ny=y+dy,c=tile(nx,ny),o=inb(nx,ny)&&unitAt(nx,ny);
  if(!inb(nx,ny)||!PASS(c)||o||elevAt(nx,ny)-elevAt(x,y)>1)return{x,y,moved:x!==t.x||y!==t.y,fall:inb(nx,ny)&&!o&&HZ(c).kind==='fall'?{x:nx,y:ny}:null,slam:1};x=nx;y=ny}
 return{x,y,moved:true,fall:null,slam:0}}
const hzElite=t=>t.side!=='e'||t.boss||(typeof isElite==='function'&&isElite(t));
const _hzPushN=pushN;
pushN=function(u,t,dx,dy,n){if(!hzSet())return _hzPushN(u,t,dx,dy,n);const L=hzLand(t,dx,dy,n);
 if(L.fall){t.x=L.x;t.y=L.y;fx(L.fall,'FALL','boom');
  if(!hzElite(t)){log(`${u.n} hurls ${t.n} over the edge. Gone.`,'good');t.x=L.fall.x;t.y=L.fall.y;damage(t,99,u);return}
  log(`${t.n} goes over the edge and claws back up.`,t.side==='p'?'bad':'good');damage(t,4,u);return}
 const x0=t.x,y0=t.y;_hzPushN(u,t,dx,dy,n);if(!alive(t)||t.status!=='ok'||(t.x===x0&&t.y===y0))return;
 if(!hzEnter(t)&&HZ(tile(t.x,t.y)).slide)hzSlide(t,dx,dy);
 if(alive(t)&&HZ(tile(t.x,t.y)).kind==='slow'&&t.side==='e'){t.rooted=1;fx(t,'STUCK','defl');log(`${t.n} is stuck in the ${HZ(tile(t.x,t.y)).n.toLowerCase()}: no moving next turn.`,'good')}};

// Round start: everyone standing in a live burning/shocking tile takes it again. Conduits warn the turn before.
const _hzSPT=startPlayerTurn;
startPlayerTurn=function(){if(hzSet()&&!S.over){for(const u of S.units.filter(u=>alive(u)&&u.status==='ok'&&hzLive(tile(u.x,u.y))&&HZ(tile(u.x,u.y)).linger)){
  const t=HZ(tile(u.x,u.y));fx(u,t.n.toUpperCase(),'dmg');log(`${u.n} is still in the ${t.n.toLowerCase()}.`,u.side==='p'?'bad':'good');damage(u,t.hurt,null);if(S.over)return}
 if(tilesWhere(c=>HZ(c).pulse).length)log(S.turn%2===0?'⚡ Conduits are LIVE this turn: 2 damage + lost actions on contact.':'⚡ Conduits go live NEXT turn. Get off them, or push enemies on.',S.turn%2===0?'bad':'')}
 _hzSPT();for(const u of players())if(u.shockAP){u.shockAP=0;if(u.status==='ok')u.ap=Math.max(0,(u.ap||0)-1)}};
// AI: stay out of hurting tiles and off slick ones; respect conduits only when they will be live.
const _hzScore=tileScore;
tileScore=function(e,pos){let s=_hzScore(e,pos);if(hzSet()){const c=tile(pos.x,pos.y),t=HZ(c);if(t.hurt&&(!t.pulse||hzLive(c)||hzLive(c,S.turn+1)))s-=12*t.hurt;if(t.slide)s-=6}return s};

// ── Telegraphs ──
// What happens on a move path: damage on the way, stun, a slide at the end.
function hzPath(path){let dmg=0,stun=0,slide=0;const seen=[];
 for(const p of path||[]){const c=tile(p.x,p.y),t=HZ(c);if(!t.kind)continue;if(!seen.includes(t.n))seen.push(t.n);if(t.hurt&&hzLive(c)){dmg+=t.hurt;if(t.stun)stun=1}}
 const e=path&&path.at(-1);if(e&&HZ(tile(e.x,e.y)).slide)slide=1;return{dmg,stun,slide,names:seen}}
function hzPushHint(u,t){if(!t||t.side!=='e')return '';const ab=AB[S.mode]||{};let dx,dy,n;
 if(S.mode==='push'){dx=Math.sign(t.x-u.x);dy=Math.sign(t.y-u.y);n=2}else if(S.mode==='pull'){dx=Math.sign(u.x-t.x);dy=Math.sign(u.y-t.y);n=Math.min(3,cheb(u,t)-1)}else return '';
 if(!ab||!n)return '';const L=hzLand(t,dx,dy,n);
 if(L.fall)return hzElite(t)?`⚠ ${t.n} goes over the edge: 4 damage.`:`⚠ ${t.n} goes over the edge and is gone.`;
 const c=tile(L.x,L.y),k=HZ(c);if(!k.kind)return L.slam?`${t.n} slams into something: 2 damage.`:'';
 return `⚠ Lands on ${k.n}: ${k.kind==='burn'?k.hurt+' damage now and each round':k.kind==='shock'?(hzLive(c)?'2 damage + loses its turn':'harmless until next turn'):k.kind==='slow'?'stuck, no move next turn':k.kind==='slide'?'keeps sliding':''}.`}
const _hzHint=hintText;
hintText=function(){const h=_hzHint();try{if(!hzSet()||!S||S.over||S.phase!=='player')return h;const add=[];
 if(S.mode==='move'&&S.hpath&&S.hpath.length){const P=hzPath(S.hpath);if(P.dmg)add.push(`⚠ This path costs ${P.dmg} HP${P.stun?' and stuns you':''} (${P.names.join(', ')}).`);if(P.slide)add.push('⚠ You will slide when you land.')}
 const hv=typeof HOV!=='undefined'&&HOV;if(hv&&S.sel){const t=unitAt(hv.x,hv.y);if(t){const p=hzPushHint(S.sel,t);if(p)add.push(p)}}
 if(hv&&!add.length){const c=tile(hv.x,hv.y),k=HZ(c);if(k.kind||c==='w')add.push(`${k.n}: ${k.desc}${k.pulse?(hzLive(c)?' LIVE now.':` Live ${hzLive(c,S.turn+1)?'next turn':'in 2 turns'}.`):''}`)}
 return add.length?`${h} ${add.join(' ')}`.trim():h}catch(e){return h}};
// Briefing, Objectives row and galaxy panel: kinds with their rule and how to use them.
const hzOf=id=>{const B=MISSIONS[id]||{},th=B.theme||THEME_OF[id]||'plains';return B.noHaz?null:HAZARDS[th]};
const hzKinds=Z=>[...new Set(Z.tiles.map(c=>HZ(c).kind).filter(Boolean))];
const hzLine=Z=>hzKinds(Z).map(k=>{const K=HZ_KIND[k],T=[...new Set(Z.tiles.filter(c=>HZ(c).kind===k).map(c=>HZ(c).n))].join(', ');return `<b>${K.n}</b> (${T}): ${K.rule} <i>${K.weapon}</i>`}).join('<br>');
const hzPlain=Z=>hzLine(Z).replace(/<br>/g,' ').replace(/<[^>]+>/g,'').replace(/"/g,'&quot;');
const _hzSquad=squadScreen;squadScreen=function(i,keep){_hzSquad(i,keep);try{const o=C.options[i],Z=hzOf(o.mission),box=document.querySelector('#modal .box');if(!Z||!box||box.querySelector('.twcard.haz'))return;
 const a=box.querySelector('.twcard')||[...box.querySelectorAll(':scope > p')].find(p=>!p.classList.contains('muted'));if(a)a.insertAdjacentHTML(a.classList.contains('twcard')?'beforebegin':'afterend',`<div class="twcard haz"><b>${icon('elev')} Terrain: ${Z.n}</b><span>${hzLine(Z)}</span></div>`)}catch(e){}};
const _hzHud=hudRender;hudRender=function(){_hzHud();const Z=hzSet();if(!Z)return;const o=document.getElementById('objs');
 const pulse=tilesWhere(c=>HZ(c).pulse).length?` · ⚡ ${S.turn%2===0?'LIVE':'live next turn'}`:'';
 if(o)o.insertAdjacentHTML('afterbegin',`<div class="orow haz" title="${hzPlain(Z)}"><span>${icon('elev')} Terrain</span><b>${hzKinds(Z).map(k=>HZ_KIND[k].n).join(' · ')}${pulse}</b></div>`);
 if(S.turn%2===0)for(const p of tilesWhere(c=>c==='n')){const c=document.querySelector(`#board .cell[data-x="${p.x}"][data-y="${p.y}"]`);if(c)c.classList.add('live')}};
if(typeof panelFor==='function'){const _hzPanel=panelFor;panelFor=function(x){const h=_hzPanel(x);try{const Z=x&&x.o&&hzOf(x.o.mission);if(!Z)return h;
 return h.replace('<div class="meta twmeta">',`<div class="meta twmeta"><span class="twchip haz" title="${hzPlain(Z)}">${icon('elev')} ${Z.n}</span>`)}catch(e){return h}}}

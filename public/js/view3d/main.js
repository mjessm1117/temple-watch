// 3D battle view (Three.js r169, vendored, no build step). Exposes window.View3D; render.js calls View3D.sync() after every render().
// Game logic never waits for it: logic emits fx events (js/fx.js) and this view plays them back in order, then snaps to S.
// No WebGL (old GPU, jsdom tests) → nothing here runs and the 2D board stays.
import * as THREE from '../../vendor/three.module.min.js';
import {CamRig} from './camera.js';
import {Board,EH} from './board.js';
import {Units} from './units.js';
import {Effects} from './effects.js';
import {Labels} from './labels.js';
import {THEMES,themeOf,Scenery} from './themes.js';
import {Cine} from './cine.js';
import {forceFx} from './forcefx.js';
import {startPortraits} from './portraits.js';
import {startDiorama} from './diorama.js';
import {RV} from './rigged.js';
import {initFigures,loadModel,fileOf} from './figures.js';
import {loadProps} from './props.js';
import {kindOf} from './units.js';

const btn=document.getElementById('viewBtn'),modal=document.getElementById('modal'),KEY='tw_view';
const glOK=(()=>{try{const c=document.createElement('canvas');return !!(window.WebGLRenderingContext&&(c.getContext('webgl2')||c.getContext('webgl')))}catch(e){return false}})();
const store={get(){try{return localStorage.getItem(KEY)}catch(e){return null}},set(v){try{localStorage.setItem(KEY,v)}catch(e){}}};
const reduceMQ=matchMedia('(prefers-reduced-motion: reduce)');
let on=false,V=null;
const Q=[],waiters=[];let busy=0,slowT=0,lastS=null,labelT=0;const hpShow=new Map();
onFx((type,d)=>{if(on&&V&&S)Q.push({type,d})});
// Colorblind mode (Chat U's SETTINGS.cb): enemy red → orange, ally/good green → blue, dash gold → yellow.
const cb=()=>!!(window.SETTINGS&&SETTINGS.cb);
const unitColor=u=>u.side==='e'?(cb()?'#ff9e2c':'#ef6a5d'):u.vip?(cb()?'#5fb0ff':'#7fd99a'):u.col||'#e0bd78';

function init(){const wrap=document.querySelector('.bwrap'),host=document.createElement('div');host.className='v3';wrap.appendChild(host);
 const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});const phone=matchMedia('(pointer:coarse)').matches;renderer.setPixelRatio(Math.min(devicePixelRatio,phone?1.5:2));
 renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;renderer.outputColorSpace=THREE.SRGBColorSpace;
 renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;host.appendChild(renderer.domElement);
 const scene=new THREE.Scene();scene.background=new THREE.Color(0x070d0f);scene.fog=new THREE.Fog(0x070d0f,24,48);
 const hemi=new THREE.HemisphereLight(0xa8dce8,0x0b1518,1.1);scene.add(hemi);
 const key=new THREE.DirectionalLight(0xfff0dc,2.4);key.position.set(5,11,6);key.castShadow=true;key.shadow.mapSize.set(phone?1024:2048,phone?1024:2048);
 Object.assign(key.shadow.camera,{left:-9,right:9,top:9,bottom:-9,near:1,far:30});key.shadow.bias=-.0006;key.shadow.normalBias=.02;scene.add(key);
 const rim=new THREE.DirectionalLight(0x79d3e2,.8);rim.position.set(-6,5,-8);scene.add(rim);const scenery=new Scenery(THREE,scene),lights={hemi,key,rim};
 initFigures(THREE);const rig=new CamRig(THREE),board=new Board(THREE,scene),units=new Units(THREE,scene,board,unitColor);units.Rig=RV;const fx3=new Effects(THREE,scene,rig),labels=new Labels(host);
 const ctl=document.createElement('div');ctl.className='v3c';
 ctl.innerHTML=`<button type="button" data-c="l" title="Rotate left (Q)">⟲</button><button type="button" data-c="r" title="Rotate right (E)">⟳</button><button type="button" data-c="i" title="Zoom in (wheel)">+</button><button type="button" data-c="o" title="Zoom out (wheel)">−</button><button type="button" data-c="f" title="Reset view">⌂</button><button type="button" data-c="c" title="Cinematic cameras on/off" class="cineb"></button><span>Drag or WASD to pan · wheel zoom · Q/E rotate</span>`;
 ctl.addEventListener('click',e=>{const c=e.target.closest('[data-c]');if(!c)return;({l:()=>rig.rotate(-1),r:()=>rig.rotate(1),i:()=>rig.zoom(1/1.2),o:()=>rig.zoom(1.2),f:()=>fit(),c:()=>View3D.cinematics=!V.cine.enabled})[c.dataset.c]()});
 host.appendChild(ctl);
 const ray=new THREE.Raycaster(),ndc=new THREE.Vector2(),ground=new THREE.Plane(new THREE.Vector3(0,1,0),0),hit=new THREE.Vector3();
 const pick=e=>{if(!S||!board.rows)return null;const r=renderer.domElement.getBoundingClientRect();ndc.set((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1);ray.setFromCamera(ndc,rig.cam);
  const roots=[...units.map.values()].filter(v=>!v.gone&&v.root.visible&&v.state!=='dead').map(v=>v.root),h=ray.intersectObjects(roots,true)[0];
  if(h){let o=h.object;while(o&&!roots.includes(o))o=o.parent;const v=[...units.map.values()].find(v=>v.root===o);if(v&&alive(v.u))return{x:v.u.x,y:v.u.y}}
  const top=board.tops&&board.tops.length&&ray.intersectObjects(board.tops,false)[0];if(top)return{...top.object.userData};
  if(!ray.ray.intersectPlane(ground,hit))return null;const x=Math.floor(hit.x+board.cols/2),y=Math.floor(hit.z+board.rows/2);return x>=0&&y>=0&&x<board.cols&&y<board.rows?{x,y}:null};
 rig.bind(renderer.domElement,pick,(x,y,kind)=>{if(kind==='click')boardClick(x,y);else boardHover(x,y)});
 const resize=()=>{const w=host.clientWidth,h=host.clientHeight;if(!w||!h)return;renderer.setSize(w,h,false);rig.cam.aspect=w/h;rig.cam.updateProjectionMatrix();fx3.setScale(renderer.getPixelRatio()*h/2.2)};
 new ResizeObserver(resize).observe(host);
 const fit=()=>{if(!board.rows)return;rig.fit(board.cols,board.rows,rig.cam.aspect);const c=[[-1,-1],[1,-1],[-1,1],[1,1]].map(([a,b])=>new THREE.Vector3(a*board.cols/2,0,b*board.rows/2));
  for(let d=6;d<=32;d+=.5){rig.dist=d;rig.update(0);rig.cam.updateMatrixWorld();if(c.every(p=>{const v=p.clone().project(rig.cam);return Math.abs(v.x)<.97&&Math.abs(v.y)<.94}))break}rig.distGoal=rig.dist};
 V={renderer,scene,rig,board,units,fx3,labels,host,resize,fit,scenery,lights,cine:new Cine(THREE,rig,host,labels.el)};cineBtn();resize();
 const setReduce=()=>{units.reduce=fx3.reduce=V.cine.reduce=reduceMQ.matches};setReduce();reduceMQ.addEventListener('change',setReduce);
 let last=performance.now(),slowN=0;const loop=now=>{requestAnimationFrame(loop);const raw=(now-last)/1000,real=Math.min(.05,raw);last=now;if(!on||document.hidden||!S)return;frame(real,now/1000);
  // Adaptive quality: if frames run slow for ~2 s, drop resolution a step (to 1×), then soften shadows.
  if(raw>1/42&&raw<.5)slowN++;else slowN=Math.max(0,slowN-2);if(slowN>120){slowN=0;const pr=renderer.getPixelRatio();
   if(pr>1){renderer.setPixelRatio(Math.max(1,pr-.25));resize()}else if(renderer.shadowMap.type!==THREE.BasicShadowMap){renderer.shadowMap.type=THREE.BasicShadowMap;key.shadow.mapSize.set(1024,1024);key.shadow.map?.dispose();key.shadow.map=null}}};requestAnimationFrame(loop)}

const P=(o,y=0)=>V.board.pos(o.x,o.y,y);
const vpos=(u,y=.8)=>{const v=V.units.get(u),p=v.root.position;return p.clone().setY(Math.max(0,V.board.elev(v.vx,v.vy)*EH)+y)};
const SET=()=>window.SETTINGS||{};let rmT=0;
function frame(real,t){const {rig,board,units,fx3,labels,renderer,scene}=V;if(S!==lastS)rebuild();
 if((rmT-=real)<=0){rmT=.5;const rm=SET().reducedMotion?SET().reducedMotion():reduceMQ.matches;units.reduce=fx3.reduce=V.cine.reduce=rm;cineBtn()}
 const spd=Math.max(.25,+SET().speed||1),slow=slowT>0&&!units.reduce;if(slowT>0)slowT-=real;const dt=(slow?real*.25:real)*spd;
 pump(dt*1000);rig.update(real);V.cine.update(real);board.update(dt,t);V.scenery.update(dt,t);units.update(dt,t);fx3.update(dt);
 if((labelT-=real)<=0){labelT=.08;unitLabels()}
 if(S.smoke&&S.smoke.length&&Math.random()<real*3)for(const s of S.smoke)fx3.puff(P(s,.3),1,0x8aa2a5);
 labels.update(real,proj);if(modal.hidden)renderer.render(scene,rig.cam)}
const proj=p=>{const v=p.clone().project(V.rig.cam);if(v.z>1)return null;const c=V.renderer.domElement;return{x:(v.x+1)/2*c.clientWidth,y:(1-v.y)/2*c.clientHeight}};
function rebuild(){lastS=S;Q.length=0;busy=0;hpShow.clear();V.units.clear();V.labels.clear();const th=themeOf({...S.M,theme:S.theme||S.M.theme});V.board.setTheme(THEMES[th]);V.board.build(S.grid);V.fx3.clearKept();
 V.scenery.apply(th,V.board.cols,V.board.rows,V.lights,V.renderer);
 seen.clear();for(const u of S.units)if(u.side==='e'&&!u.hid&&alive(u))seen.add(u.uid);
 if(S.turn===1&&S.phase==='player'&&!flown.has(S)&&S.units.every(u=>u.hp===u.max)){flown.add(S);V.cine.flyover(V.board.cols,V.board.rows,`<div style="font:600 26px 'Chakra Petch',sans-serif;letter-spacing:.12em;color:#dbe7e4">${(S.M.n||'').toUpperCase()}</div><div style="font:500 13px 'IBM Plex Sans',sans-serif;color:#8aa2a5;margin-top:4px">${S.M.where||''}</div>`)}V.fit();V.units.reconcile(S.units);ui();models()}
// Lazy-load only the model files this mission's units need; swap figures in once loaded (block figures show meanwhile).
function models(){const want=new Set(S.units.map(u=>fileOf(kindOf(u))));
 const later=[...Object.values(S.M&&S.M.waves||{}).flat(),...(S.M&&S.M.reinforce||[])];
 for(const t of later)if(typeof t==='string'&&FOES[t])want.add(fileOf(kindOf({...FOES[t],side:'e',type:t})));
 want.delete(null);for(const f of want)loadModel(f).then(m=>{if(m&&V&&S){V.units.upgrade();ui()}})
 loadProps(THREE,new Set(S.grid.map(r=>[...r]).flat())).then(n=>{if(n&&V&&S)V.board.build(S.grid)})}

// Event queue: each beat waits for the previous one. A backlog (fast enemy turns) plays faster.
function pump(ms){const sp=(Q.length>6?3:Q.length>2?1.8:1)*(V.units.reduce?2:1);busy-=ms*sp;
 while(busy<=0&&Q.length){const e=Q.shift();let d=0;try{d=play(e.type,e.d)||0}catch(err){console.error(err)}busy=Math.max(busy,0)+d}
 if(busy<=0&&!Q.length){busy=0;settle();while(waiters.length)waiters.shift()()}}
function settle(){const lost=V.board.sync(S.grid);for(const l of lost)V.fx3.debris(P(l,.3),6);
 V.units.reconcile(S.units);for(const u of S.units)hpShow.set(u.uid,u.hp);reveals()}
// Enemy-reveal pan: the first time new enemies become visible (waves, hidden agents, ambushes).
const seen=new Set(),flown=new WeakSet();
function reveals(){const fresh=S.units.filter(u=>u.side==='e'&&!u.hid&&alive(u)&&!seen.has(u.uid));if(!fresh.length)return;for(const u of fresh)seen.add(u.uid);
 if(!V.cine.ready('reveal',4))return;const c=fresh.reduce((a,u)=>a.add(P(u)),new THREE.Vector3()).multiplyScalar(1/fresh.length);
 const n={};for(const u of fresh){const k=u.n.replace(/ \d+$/,'');n[k]=(n[k]||0)+1}const horror=fresh.some(u=>u.horror||u.boss);
 V.cine.reveal(c,`<div style="font:600 18px 'Chakra Petch',sans-serif;letter-spacing:.14em;color:${horror?'#ef6a5d':'#e0bd78'}">${horror?'THREAT SIGHTED':'CONTACT'}</div><div style="font:500 13px 'IBM Plex Sans',sans-serif;color:#dbe7e4">${Object.entries(n).map(([k,v])=>v>1?k+' ×'+v:k).join(' · ')}</div>`)}
function play(type,d){const {units,fx3,labels,board,rig}=V;
 switch(type){
  case 'move':{if(d.u.hid||!d.path.length)return 0;const v=units.get(d.u);if(v.state!=='ok')return 0;return v.walk([P(d.from),...d.path.map(p=>P(p))],d.path.at(-1))+40}
  case 'shot':{const a=units.get(d.a),tv=units.get(d.t),pa=P(d.from,.9),pt=tv.root.position.clone().setY(.8);a.faceTo(pt);
   if(d.label==='Force choke'){a.cast(pt,1);tv.lift(1.05);fx3.choke(pt);fx3.ring(pt.clone().setY(1.45),0xb294f5,.45,.12,.9,1.45);return 520}
   if((d.label==='lightning'||d.label==='Force choke')&&Math.random()<.5&&V.cine.ready('force',9))V.cine.forcecam(a.root.position.clone(),pt);
   if(d.label==='lightning'){a.cast(pt,1);return fx3.lightning(pa.setY(1),pt,.55)+60}
   if(d.label==='thrown saber'){a.throwAt(pt);}if(d.label==='thrown saber')return fx3.saber(pa,pt,unitColor(d.a))+40;
   const lethal=d.hit&&Q.some((e,i)=>e.type==='kill'&&e.d.t===d.t&&!Q.slice(0,i).some(o=>o.type==='shot'));
   if(lethal&&d.a.side==='p'&&(enemies().length<=1||Math.random()<.5)&&V.cine.ready('kill',7))V.cine.killcam(a.root.position.clone(),tv.root.position.clone(),d.melee?1.2:1.5);
   if(d.melee){a.swing(pt);return 210}
   a.shoot(pt);const nx=Q.findIndex(o=>o.type==='shot'),upto=nx<0?Q:Q.slice(0,nx),deflect=!d.hit&&upto.some(e=>e.type==='text'&&e.d.txt==='DEFLECT');
   // Guard can send the bolt back: the reflected hit is the next 'hit' whose source is the defender.
   const back=deflect&&upto.find(e=>e.type==='hit'&&e.d.src===d.t);
   if(deflect)setTimeout(()=>tv.block(),120);const ms=fx3.bolt(pa.setY(.95),pt,{color:boltColor(d.a),hit:d.hit,deflect:back?vpos(back.d.t,.9):deflect,w:/heavy|sithHeavy|bane/i.test(kindOf(d.a))?1.6:1})+60;
   return back?ms*2.2:ms}
  case 'hit':{const v=units.get(d.t),at=d.src?vpos(d.src):null;v.flash();if(at)v.knock(at,d.d>=4?.34:.24);fx3.sparks(vpos(d.t,.8),d.src&&d.src.side==='e'?0xff8a6a:0x9fe7ff,16);
   hpShow.set(d.t.uid,d.hp);return 130}
  case 'kill':{const v=units.get(d.t),p=vpos(d.t,.8);v.fall('dead',d.src?vpos(d.src):null);fx3.burst(p);labels.float(p.clone().setY(1.7),'KILL','kill',true);
   if(!units.reduce)slowT=.25;hpShow.set(d.t.uid,0);return 700}
  case 'down':{const v=units.get(d.t);v.fall('down',d.src?vpos(d.src):null);fx3.puff(vpos(d.t,.4),6);hpShow.set(d.t.uid,0);return 520}
  case 'explode':{const d2=fx3.explosion(P(d,.2));setTimeout(()=>{if(V&&S){const lost=board.sync(S.grid);for(const l of lost)fx3.debris(P(l,.3),8)}},120);return d2}
  case 'coverBreak':{const lost=board.sync(S.grid);for(const l of lost)fx3.debris(P(l,.3),8);return 200}
  case 'text':return textFx(d);
  case 'ability':return abilityFx(d);
  case 'bark':{const u=d.u;if(!u||u.hid)return 0;labels.bubble('b'+u.uid,()=>{const p=V.units.anchor(u);return p&&p.setY(p.y+.75)},d.txt,Math.min(4,1.6+d.txt.length/40));return 0}
 }return 0}
// Status call-outs (Chat X): each gets a color and a small effect on the unit it pops over.
const TXT={AMBUSH:['#e0bd78',1],REVEALED:['#ef6a5d',1],SPOTTED:['#ef6a5d',0],'!':['#ef6a5d',1],PANIC:['#c9a7ff',1],ANGER:['#ff6a4a',0],FROZEN:['#9fe7ff',0],
 HIDDEN:['#a8bcc0',0],QUAKE:['#e0b880',1],ION:['#6fd0ff',0],SHIELD:['#7fd99a',0],DEFLECT:['#9fe7ff',0]};
function textFx(d){const {labels,fx3,units,rig}=V,t=TXT[d.txt],p=P(d,.8),u=S.units.find(o=>o.x===d.x&&o.y===d.y&&alive(o)),v=u&&units.map.get(u.uid);
 labels.float(P(d,1.55),d.txt,d.cls||'',!!(t&&t[1]),t&&t[0]);if(!t)return 0;
 switch(d.txt){
  case 'AMBUSH':fx3.ring(p,0xe0bd78,.3,2.6,.7,.1);fx3.motes(p,0xe0bd78,20);break;
  case 'REVEALED':case 'SPOTTED':fx3.ring(p,0xef6a5d,.2,1.4,.5,.1);break;
  case '!':if(v)v.hitAnim&&v.hitAnim();break;
  case 'PANIC':fx3.glow.emit(p.clone().setY(1.5),18,{color:0xc9a7ff,spread:.8,up:.4,life:.9,size:.07,grav:0,jit:.3});if(v)v.hitAnim(1);break;
  case 'ANGER':fx3.glow.emit(p.clone().setY(.9),22,{color:0xff4a2a,spread:.9,up:1.2,life:.7,size:.08,grav:.5,jit:.3,upOnly:1});break;
  case 'FROZEN':fx3.ring(p,0x9fe7ff,.6,.3,.6,.9);fx3.sparks(p,0xcff6ff,14);break;
  case 'HIDDEN':fx3.puff(p.clone().setY(.4),10,0x2a3236);break;
  case 'QUAKE':if(!units.reduce)rig.shake(.3);fx3.ring(p,0xc8a070,.3,3.5,.8,.05);fx3.puff(p.clone().setY(.2),20,0x7a6a54);return 300;
  case 'ION':fx3.lightning(p.clone().add(new THREE.Vector3(.35,.6,0)),p.clone().add(new THREE.Vector3(-.35,.2,0)),.35,0x6fd0ff);fx3.sparks(p,0x6fd0ff,14);break;
  case 'SHIELD':fx3.ring(p,0x7fd99a,.3,.8,.5,.6);break}
 return 0}
// Blaster colors by faction: Republic blue, Empire red, Brotherhood orange, mercenaries green.
const BOLT={bhTrooper:0xff8a2a,sniper:0x8aff5a,mando:0x8aff5a};
const boltColor=u=>u.side==='p'?0x4fb4ff:BOLT[kindOf(u)]||(cb()?0xff9e2c:0xff3b2e);
const FORCE=new Set(['push','collapse','choke','stun','mindTrick','saberThrow','tremor','pull','battleMed','leap','beastCalm','forceWave','stasisField','massHeal','forceRevive','disarm']),HEAL=new Set(['heal','forceHeal','stabilize','forceRevive','reviveStim']),SHIELD=new Set(['guard','barrier','hunker','defLine','smoke']);
function abilityFx(d){const {units,fx3,rig}=V,u=units.get(d.u),k=d.k,g=d.g,tp=g&&(g.t?vpos(g.t,.8):P(g,.8));
 if(tp)u.faceTo(tp);
 if(tp&&FORCE.has(k)&&d.u.side==='p'&&Math.random()<.6&&V.cine.ready('force',9))V.cine.forcecam(u.root.position.clone(),tp);
 if(k==='leap'&&g){const ms=u.leap(P(d.from),P(g),g);setTimeout(()=>{if(!V)return;fx3.ring(P(g),0x9fe7ff,.2,1.3,.4,.06);fx3.puff(P(g,.2),8,0x6a7a80)},ms*.9);return ms}
 const ff=forceFx({k,u,tv:g&&g.t?units.get(g.t):null,from:P(d.from),tp,fx3,T:THREE,rig,reduce:units.reduce,color:new THREE.Color(unitColor(d.u)).getHex(),P});
 if(ff!=null)return ff;
 if(k==='grenade'&&g){u.throwAt(tp);return fx3.arc(P(d.from,1),P(g,.15),.5)}
 if(HEAL.has(k)&&tp){if(g&&g.t!==d.u)u.use(tp);else u.cast(null,.5);fx3.motes(tp,0x7fd99a);return 300}
 if(SHIELD.has(k)){fx3.ring(tp||vpos(d.u),k==='barrier'?0x7fd99a:0x79d3e2,.3,.9,.5,.4);return 250}
 if(k==='overwatch'||k==='suppress'||k==='mark'){u.aim(tp||u.root.position.clone().add(new THREE.Vector3(0,0,-1)),.5);if(tp&&k==='mark')fx3.ring(tp,0xef6a5d,.2,.6,.5,.9);return 200}
 if(tp&&(k==='hack'||k==='console'||k==='scan'||k==='door'))u.use(tp);if(tp&&(k==='hack'||k==='console'||k==='scan'||k==='door'))return fx3.motes(tp,0x79d3e2,12);
 return 0}

let visK='',visS=null,visT=[],lastCb=false;const board0=()=>V.board;
// UI layer: reach tiles, cover shields, targets, path, aim/intent lines, % tags. Rebuilt on every render and hover.
function ui(){if(!V||!S)return;if(cb()!==lastCb){lastCb=cb();board0().palette(lastCb);lastS=null;return View3D.sync()}const {board,units,labels}=V,sel=S.sel,can=canAct(sel)&&!S.peek&&S.phase==='player';
 const h={reach:[],hover:null,targets:[],path:[],area:null,iarea:null,smoke:S.smoke||[],shields:[],lines:[]};
 // Blue = 1 action, gold = dash (both actions), from Chat U's moveZones().
 if(can&&S.mode==='move'){const Z=typeof moveZones==='function'?moveZones(sel):{...reach(sel),mob:1e9},R=Z.d;for(const k in R){if(!(R[k]>0))continue;const [x,y]=k.split(',').map(Number),hot=!!HOV&&HOV.x===x&&HOV.y===y,dash=R[k]>Z.mob;h.reach.push({x,y,dash});if(hot)h.hover={x,y,dash};
   for(const [dx,dy] of N4){if(!inb(x+dx,y+dy))continue;const c=tile(x+dx,y+dy);if(FULL(c)||HALF(c))h.shields.push({x,y,dx,dy,full:FULL(c),hot})}}}
 for(const g of S.tg){const pk=S.pick&&S.pick.x===g.x&&S.pick.y===g.y;h.targets.push({x:g.x,y:g.y,kind:pk?'pick':g.area||g.spot?'spot':g.ally?'ally':'tgt'})}
 if(S.hpath&&S.hpath.length&&sel){const pts=[sel,...S.hpath].map(p=>P(p));for(let i=0;i<pts.length-1;i++)for(let f=0;f<1;f+=.25)h.path.push(pts[i].clone().lerp(pts[i+1],f));h.path.push(pts.at(-1))}
 if(S.pick&&sel){if(S.pick.area)h.area=S.pick;else if(!S.pick.spot)h.lines.push({a:vpos(sel,.9),b:P(S.pick,.9),color:0x79d3e2,dash:1})}
 if(S.peek&&S.peek.side==='e'&&S.phase==='player'){const it=intentOf(S.peek);const a=vpos(S.peek,.9);
  if(it.to)h.lines.push({a,b:P(it.to,.9),color:0xef6a5d,dash:1});if(it.area){h.lines.push({a,b:P(it.area,.2),color:0xef6a5d,dash:1});h.iarea=it.area}}
 // Stealth (Chat X): red = tiles an enemy would spot you on; the hidden squad is drawn ghosted.
 if(S.conc&&typeof visionTiles==='function'){const k=enemies().map(e=>e.x+','+e.y+e.status).join(';');if(visK!==k||visS!==S){visK=k;visS=S;visT=visionTiles()}h.vision=visT}
 board.highlight(h);units.marks(sel,S.peek);for(const v of units.map.values())v.ghost&&v.ghost(v.u.side==='p'&&v.u.status==='ok'&&!!(S.conc||v.u.conc))
 // % tags: same rule as the 2D board (best enemy shot in white).
 const shoot=S.info&&canAct(sel)&&S.mode==='move'&&sel.abil.includes('shoot')?targetsFor(sel,'shoot').filter(g=>g.t):[];
 const list=[...S.tg.filter(g=>!g.area&&!g.spot&&g.chance!=null),...shoot.filter(s=>!S.tg.some(g=>g.x===s.x&&g.y===s.y))].filter(g=>!g.t||!g.t.hid);
 const best=Math.max(-1,...list.filter(g=>g.t&&g.t.side==='e').map(g=>g.chance));

 // Area abilities (Chat U's areaHits): chips over every unit the hovered area would hit.
 if(S.mode!=='move'&&HOV&&typeof areaHits==='function'){const g=S.tg.find(g=>g.area&&g.x===HOV.x&&g.y===HOV.y);
  if(g)for(const a of areaHits(sel,S.mode,g)){if(!a.t||a.t.hid)continue;list.push({t:a.t,chance:a.chance,ally:a.ally,x:a.t.x,y:a.t.y,kill:a.kill})}}
 labels.setTags(list.map(g=>({p:g.t?vpos(g.t,(units.get(g.t).headY||1.2)+.55):P(g,1),html:g.chance+'%'+(g.kill?' ☠':''),cls:g.ally?'al':g.chance===best&&g.t&&g.t.side==='e'?'best':''})))}
function unitLabels(){const L=[];for(const u of S.units){const v=V.units.map.get(u.uid);if(!v||v.gone||v.state==='dead'||u.hid||!alive(u)&&u.status!=='dead')continue;
  const hp=Math.max(0,Math.min(u.max,hpShow.has(u.uid)?hpShow.get(u.uid):u.hp)),b=v.state==='down'?'down':badge(u);
  const html=`<i class="hp" style="--uc:${unitColor(u)}">${Array.from({length:u.max},(_,i)=>`<b class="${i<hp?'on':''}"></b>`).join('')}</i>${b?`<span class="bdg">${icon(b)}${u.status==='down'&&!u.stable?`<small>${u.bleed}</small>`:''}</span>`:''}${S.info?`<em>${hp}</em>`:''}`;
  L.push({key:u.uid,html,pos:()=>{const p=V.units.anchor(u);return p&&p.setY(p.y+.22)}})}
 V.labels.setUnits(L)}

function setOn(v){on=v&&glOK;document.body.classList.toggle('v3d',on);btn.textContent='View: '+(on?'3D':'2D');store.set(on?'3d':'2d');
 if(on&&!V)init();if(on&&V){lastS=null;V.resize()}if(typeof render==='function'&&S)render()}
function cineBtn(){const b=V.host.querySelector('.cineb');if(b){b.textContent='Cine: '+(V.cine.enabled?'on':'off');b.setAttribute('aria-pressed',V.cine.enabled)}}
window.View3D={get dbg(){return V},get queue(){return {n:Q.length,busy,types:Q.slice(0,6).map(e=>e.type)}},
 // Settings hook (Chat U): View3D.cinematics = true/false. Stored per browser.
 get cinematics(){return V?V.cine.enabled:(()=>{try{return localStorage.getItem('tw_cine')!=='off'}catch(e){return true}})()},
 set cinematics(v){if(V){V.cine.setEnabled(v);cineBtn()}else try{localStorage.setItem('tw_cine',v?'on':'off')}catch(e){}},
 skipCinematic(){if(V)V.cine.skip()},sync(){if(!on||!V||!S)return;if(S!==lastS)rebuild();ui()},
 // Resolves once every queued animation has played (logic may await this between enemy actions; 2D/tests resolve at once).
 idle(){return on&&V&&S&&(Q.length||busy>0)&&!document.hidden?new Promise(r=>{waiters.push(r);setTimeout(r,4000)}):Promise.resolve()},hover(){if(on&&V&&S)ui()},get on(){return on}};
if(glOK){try{startPortraits();startDiorama()}catch(e){console.warn(e)}btn.hidden=false;btn.addEventListener('click',()=>setOn(!on));setOn(store.get()!=='2d')}

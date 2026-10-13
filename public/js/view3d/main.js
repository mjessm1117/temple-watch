// 3D battle view (Three.js r169, vendored, no build step). Exposes window.View3D; render.js calls View3D.sync() after every render().
// Game logic never waits for it: logic emits fx events (js/fx.js) and this view plays them back in order, then snaps to S.
// No WebGL (old GPU, jsdom tests) → nothing here runs and the 2D board stays.
import * as THREE from '../../vendor/three.module.min.js';
import {CamRig} from './camera.js';
import {Board} from './board.js';
import {Units} from './units.js';
import {Effects} from './effects.js';
import {Labels} from './labels.js';

const btn=document.getElementById('viewBtn'),modal=document.getElementById('modal'),KEY='tw_view';
const glOK=(()=>{try{const c=document.createElement('canvas');return !!(window.WebGLRenderingContext&&(c.getContext('webgl2')||c.getContext('webgl')))}catch(e){return false}})();
const store={get(){try{return localStorage.getItem(KEY)}catch(e){return null}},set(v){try{localStorage.setItem(KEY,v)}catch(e){}}};
const reduceMQ=matchMedia('(prefers-reduced-motion: reduce)');
let on=false,V=null;
const Q=[],waiters=[];let busy=0,slowT=0,lastS=null,labelT=0;const hpShow=new Map();
onFx((type,d)=>{if(on&&V&&S)Q.push({type,d})});
const unitColor=u=>u.side==='e'?'#ef6a5d':u.vip?'#7fd99a':u.col||'#e0bd78';

function init(){const wrap=document.querySelector('.bwrap'),host=document.createElement('div');host.className='v3';wrap.appendChild(host);
 const renderer=new THREE.WebGLRenderer({antialias:true,powerPreference:'high-performance'});renderer.setPixelRatio(Math.min(devicePixelRatio,2));
 renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;renderer.outputColorSpace=THREE.SRGBColorSpace;
 renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.15;host.appendChild(renderer.domElement);
 const scene=new THREE.Scene();scene.background=new THREE.Color(0x070d0f);scene.fog=new THREE.Fog(0x070d0f,24,48);
 scene.add(new THREE.HemisphereLight(0xa8dce8,0x0b1518,1.1));
 const key=new THREE.DirectionalLight(0xfff0dc,2.4);key.position.set(5,11,6);key.castShadow=true;key.shadow.mapSize.set(2048,2048);
 Object.assign(key.shadow.camera,{left:-9,right:9,top:9,bottom:-9,near:1,far:30});key.shadow.bias=-.0006;key.shadow.normalBias=.02;scene.add(key);
 const rim=new THREE.DirectionalLight(0x79d3e2,.8);rim.position.set(-6,5,-8);scene.add(rim);
 const rig=new CamRig(THREE),board=new Board(THREE,scene),units=new Units(THREE,scene,board,unitColor),fx3=new Effects(THREE,scene,rig),labels=new Labels(host);
 const ctl=document.createElement('div');ctl.className='v3c';
 ctl.innerHTML=`<button type="button" data-c="l" title="Rotate left (Q)">⟲</button><button type="button" data-c="r" title="Rotate right (E)">⟳</button><button type="button" data-c="i" title="Zoom in (wheel)">+</button><button type="button" data-c="o" title="Zoom out (wheel)">−</button><button type="button" data-c="f" title="Reset view">⌂</button><span>Drag or WASD to pan · wheel zoom · Q/E rotate</span>`;
 ctl.addEventListener('click',e=>{const c=e.target.closest('[data-c]');if(!c)return;({l:()=>rig.rotate(-1),r:()=>rig.rotate(1),i:()=>rig.zoom(1/1.2),o:()=>rig.zoom(1.2),f:()=>fit()})[c.dataset.c]()});
 host.appendChild(ctl);
 const ray=new THREE.Raycaster(),ndc=new THREE.Vector2(),ground=new THREE.Plane(new THREE.Vector3(0,1,0),0),hit=new THREE.Vector3();
 const pick=e=>{if(!S||!board.rows)return null;const r=renderer.domElement.getBoundingClientRect();ndc.set((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1);ray.setFromCamera(ndc,rig.cam);
  const roots=[...units.map.values()].filter(v=>!v.gone&&v.root.visible&&v.state!=='dead').map(v=>v.root),h=ray.intersectObjects(roots,true)[0];
  if(h){let o=h.object;while(o&&!roots.includes(o))o=o.parent;const v=[...units.map.values()].find(v=>v.root===o);if(v&&alive(v.u))return{x:v.u.x,y:v.u.y}}
  if(!ray.ray.intersectPlane(ground,hit))return null;const x=Math.floor(hit.x+board.cols/2),y=Math.floor(hit.z+board.rows/2);return x>=0&&y>=0&&x<board.cols&&y<board.rows?{x,y}:null};
 rig.bind(renderer.domElement,pick,(x,y,kind)=>{if(kind==='click')boardClick(x,y);else boardHover(x,y)});
 const resize=()=>{const w=host.clientWidth,h=host.clientHeight;if(!w||!h)return;renderer.setSize(w,h,false);rig.cam.aspect=w/h;rig.cam.updateProjectionMatrix();fx3.setScale(renderer.getPixelRatio()*h/2.2)};
 new ResizeObserver(resize).observe(host);
 const fit=()=>{if(!board.rows)return;rig.fit(board.cols,board.rows,rig.cam.aspect);const c=[[-1,-1],[1,-1],[-1,1],[1,1]].map(([a,b])=>new THREE.Vector3(a*board.cols/2,0,b*board.rows/2));
  for(let d=6;d<=32;d+=.5){rig.dist=d;rig.update(0);rig.cam.updateMatrixWorld();if(c.every(p=>{const v=p.clone().project(rig.cam);return Math.abs(v.x)<.97&&Math.abs(v.y)<.94}))break}rig.distGoal=rig.dist};
 V={renderer,scene,rig,board,units,fx3,labels,host,resize,fit};resize();
 const setReduce=()=>{units.reduce=fx3.reduce=reduceMQ.matches};setReduce();reduceMQ.addEventListener('change',setReduce);
 let last=performance.now();const loop=now=>{requestAnimationFrame(loop);const real=Math.min(.05,(now-last)/1000);last=now;if(!on||document.hidden||!S)return;frame(real,now/1000)};requestAnimationFrame(loop)}

const P=(o,y=0)=>V.board.pos(o.x,o.y,y);
const vpos=(u,y=.8)=>{const v=V.units.get(u);return v.root.position.clone().setY(y)};
function frame(real,t){const {rig,board,units,fx3,labels,renderer,scene}=V;if(S!==lastS)rebuild();
 const slow=slowT>0&&!units.reduce;if(slowT>0)slowT-=real;const dt=slow?real*.25:real;
 pump(dt*1000);rig.update(real);board.update(dt,t);units.update(dt,t);fx3.update(dt);
 if((labelT-=real)<=0){labelT=.08;unitLabels()}
 if(S.smoke&&S.smoke.length&&Math.random()<real*3)for(const s of S.smoke)fx3.puff(P(s,.3),1,0x8aa2a5);
 labels.update(real,proj);if(modal.hidden)renderer.render(scene,rig.cam)}
const proj=p=>{const v=p.clone().project(V.rig.cam);if(v.z>1)return null;const c=V.renderer.domElement;return{x:(v.x+1)/2*c.clientWidth,y:(1-v.y)/2*c.clientHeight}};
function rebuild(){lastS=S;Q.length=0;busy=0;hpShow.clear();V.units.clear();V.labels.clear();V.board.build(S.grid);V.fit();V.units.reconcile(S.units);ui()}

// Event queue: each beat waits for the previous one. A backlog (fast enemy turns) plays faster.
function pump(ms){const sp=(Q.length>6?3:Q.length>2?1.8:1)*(V.units.reduce?2:1);busy-=ms*sp;
 while(busy<=0&&Q.length){const e=Q.shift();let d=0;try{d=play(e.type,e.d)||0}catch(err){console.error(err)}busy=Math.max(busy,0)+d}
 if(busy<=0&&!Q.length){busy=0;settle();while(waiters.length)waiters.shift()()}}
function settle(){const lost=V.board.sync(S.grid);for(const l of lost)V.fx3.debris(P(l,.3),6);
 V.units.reconcile(S.units);for(const u of S.units)hpShow.set(u.uid,u.hp)}
function play(type,d){const {units,fx3,labels,board,rig}=V;
 switch(type){
  case 'move':{if(d.u.hid||!d.path.length)return 0;const v=units.get(d.u);if(v.state!=='ok')return 0;return v.walk([P(d.from),...d.path.map(p=>P(p))],d.path.at(-1))+40}
  case 'shot':{const a=units.get(d.a),tv=units.get(d.t),pa=P(d.from,.9),pt=tv.root.position.clone().setY(.8);a.faceTo(pt);
   if(d.label==='Force choke'){a.aim(pt,1);tv.lift(1.05);fx3.choke(pt);return 520}
   if(d.label==='lightning'){a.aim(pt,.7);return fx3.lightning(pa.setY(1),pt,.55)+60}
   if(d.label==='thrown saber')return fx3.saber(pa,pt,unitColor(d.a))+40;
   if(d.melee){a.swing(pt);return 210}
   a.aim(pt,.6);const deflect=!d.hit&&Q.some((e,i)=>e.type==='text'&&e.d.txt==='DEFLECT'&&!Q.slice(0,i).some(o=>o.type==='shot'));
   return fx3.bolt(pa.setY(.95),pt,{color:d.a.side==='e'?0xff5a4a:0x6fd0ff,hit:d.hit,deflect})+60}
  case 'hit':{const v=units.get(d.t),at=d.src?vpos(d.src):null;v.flash();if(at)v.knock(at,d.d>=4?.34:.24);fx3.sparks(vpos(d.t,.8),d.src&&d.src.side==='e'?0xff8a6a:0x9fe7ff,16);
   hpShow.set(d.t.uid,d.hp);return 130}
  case 'kill':{const v=units.get(d.t),p=vpos(d.t,.8);v.fall('dead',d.src?vpos(d.src):null);fx3.burst(p);labels.float(p.clone().setY(1.7),'KILL','kill',true);
   if(!units.reduce)slowT=.25;hpShow.set(d.t.uid,0);return 700}
  case 'down':{const v=units.get(d.t);v.fall('down',d.src?vpos(d.src):null);fx3.puff(vpos(d.t,.4),6);hpShow.set(d.t.uid,0);return 520}
  case 'explode':{const d2=fx3.explosion(P(d,.2));setTimeout(()=>{if(V&&S){const lost=board.sync(S.grid);for(const l of lost)fx3.debris(P(l,.3),8)}},120);return d2}
  case 'coverBreak':{const lost=board.sync(S.grid);for(const l of lost)fx3.debris(P(l,.3),8);return 200}
  case 'text':{labels.float(P(d,1.55),d.txt,d.cls||'');return 0}
  case 'ability':return abilityFx(d);
 }return 0}
const HEAL=new Set(['heal','forceHeal','stabilize','forceRevive','reviveStim']),SHIELD=new Set(['guard','barrier','hunker','defLine','smoke']);
function abilityFx(d){const {units,fx3,rig}=V,u=units.get(d.u),k=d.k,g=d.g,tp=g&&(g.t?vpos(g.t,.8):P(g,.8));
 if(tp)u.faceTo(tp);
 if(k==='leap'&&g)return u.leap(P(d.from),P(g),g);
 if(k==='push'&&tp){u.aim(tp,.5);return fx3.wave(P(d.from,.8),tp)}
 if(k==='grenade'&&g){u.aim(tp,.5);return fx3.arc(P(d.from,1),P(g,.15),.5)}
 if(k==='collapse'&&g){u.aim(tp,.6);fx3.debris(P(g,1.6),16,0x3a4a50);fx3.puff(P(g,.4),18,0x4a5559);if(!units.reduce)rig.shake(.15);return 450}
 if(k==='choke'||k==='stun'||k==='mindTrick'){u.aim(tp,.7);if(k!=='choke')fx3.ring(tp,0xe0bd78,.2,.7,.5,.9);return k==='choke'?0:350}
 if(HEAL.has(k)&&tp){fx3.motes(tp,0x7fd99a);return 300}
 if(SHIELD.has(k)){fx3.ring(tp||vpos(d.u),k==='barrier'?0x7fd99a:0x79d3e2,.3,.9,.5,.4);return 250}
 if(k==='meditate'||k==='battleMed'){fx3.motes(vpos(d.u),0x79d3e2,26);if(k==='battleMed')fx3.ring(vpos(d.u),0x79d3e2,.4,6,.9,.3);return 350}
 if(k==='overwatch'||k==='suppress'||k==='mark'){u.aim(tp||u.root.position.clone().add(new THREE.Vector3(0,0,-1)),.5);if(tp&&k==='mark')fx3.ring(tp,0xef6a5d,.2,.6,.5,.9);return 200}
 if(tp&&(k==='hack'||k==='console'||k==='scan'||k==='door'))return fx3.motes(tp,0x79d3e2,12);
 return 0}

// UI layer: reach tiles, cover shields, targets, path, aim/intent lines, % tags. Rebuilt on every render and hover.
function ui(){if(!V||!S)return;const {board,units,labels}=V,sel=S.sel,can=canAct(sel)&&!S.peek&&S.phase==='player';
 const h={reach:[],hover:null,targets:[],path:[],area:null,iarea:null,smoke:S.smoke||[],shields:[],lines:[]};
 if(can&&S.mode==='move'){const R=reach(sel).d;for(const k in R){if(!(R[k]>0))continue;const [x,y]=k.split(',').map(Number),hot=!!HOV&&HOV.x===x&&HOV.y===y;h.reach.push({x,y});if(hot)h.hover={x,y};
   for(const [dx,dy] of N4){if(!inb(x+dx,y+dy))continue;const c=tile(x+dx,y+dy);if(FULL(c)||HALF(c))h.shields.push({x,y,dx,dy,full:FULL(c),hot})}}}
 for(const g of S.tg){const pk=S.pick&&S.pick.x===g.x&&S.pick.y===g.y;h.targets.push({x:g.x,y:g.y,kind:pk?'pick':g.area||g.spot?'spot':g.ally?'ally':'tgt'})}
 if(S.hpath&&S.hpath.length&&sel){const pts=[sel,...S.hpath].map(p=>P(p));for(let i=0;i<pts.length-1;i++)for(let f=0;f<1;f+=.25)h.path.push(pts[i].clone().lerp(pts[i+1],f));h.path.push(pts.at(-1))}
 if(S.pick&&sel){if(S.pick.area)h.area=S.pick;else if(!S.pick.spot)h.lines.push({a:vpos(sel,.9),b:P(S.pick,.9),color:0x79d3e2,dash:1})}
 if(S.peek&&S.peek.side==='e'&&S.phase==='player'){const it=intentOf(S.peek);const a=vpos(S.peek,.9);
  if(it.to)h.lines.push({a,b:P(it.to,.9),color:0xef6a5d,dash:1});if(it.area){h.lines.push({a,b:P(it.area,.2),color:0xef6a5d,dash:1});h.iarea=it.area}}
 board.highlight(h);units.marks(sel,S.peek);
 // % tags: same rule as the 2D board (best enemy shot in white).
 const shoot=S.info&&canAct(sel)&&S.mode==='move'&&sel.abil.includes('shoot')?targetsFor(sel,'shoot').filter(g=>g.t):[];
 const list=[...S.tg.filter(g=>!g.area&&!g.spot&&g.chance!=null),...shoot.filter(s=>!S.tg.some(g=>g.x===s.x&&g.y===s.y))].filter(g=>!g.t||!g.t.hid);
 const best=Math.max(-1,...list.filter(g=>g.t&&g.t.side==='e').map(g=>g.chance));
 labels.setTags(list.map(g=>({p:g.t?vpos(g.t,(units.get(g.t).headY||1.2)+.55):P(g,1),html:g.chance+'%',cls:g.ally?'al':g.chance===best&&g.t&&g.t.side==='e'?'best':''})))}
function unitLabels(){const L=[];for(const u of S.units){const v=V.units.map.get(u.uid);if(!v||v.gone||v.state==='dead'||u.hid||!alive(u)&&u.status!=='dead')continue;
  const hp=Math.max(0,Math.min(u.max,hpShow.has(u.uid)?hpShow.get(u.uid):u.hp)),b=v.state==='down'?'down':badge(u);
  const html=`<i class="hp" style="--uc:${unitColor(u)}">${Array.from({length:u.max},(_,i)=>`<b class="${i<hp?'on':''}"></b>`).join('')}</i>${b?`<span class="bdg">${icon(b)}${u.status==='down'&&!u.stable?`<small>${u.bleed}</small>`:''}</span>`:''}${S.info?`<em>${hp}</em>`:''}`;
  L.push({key:u.uid,html,pos:()=>{const p=V.units.anchor(u);return p&&p.setY(p.y+.22)}})}
 V.labels.setUnits(L)}

function setOn(v){on=v&&glOK;document.body.classList.toggle('v3d',on);btn.textContent='View: '+(on?'3D':'2D');store.set(on?'3d':'2d');
 if(on&&!V)init();if(on&&V){lastS=null;V.resize()}if(typeof render==='function'&&S)render()}
window.View3D={get dbg(){return V},sync(){if(!on||!V||!S)return;if(S!==lastS)rebuild();ui()},
 // Resolves once every queued animation has played (logic may await this between enemy actions; 2D/tests resolve at once).
 idle(){return on&&V&&S&&(Q.length||busy>0)&&!document.hidden?new Promise(r=>{waiters.push(r);setTimeout(r,4000)}):Promise.resolve()},hover(){if(on&&V&&S)ui()},get on(){return on}};
if(glOK){btn.hidden=false;btn.addEventListener('click',()=>setOn(!on));setOn(store.get()!=='2d')}

// Slow-turning 3D Jedi Temple behind the Temple base screen: the ziggurat with its five spires on Coruscant, a 3-minute
// day/night cycle, shuttles landing on two plaza pads and air taxis in the lanes (Meshy models, wave 7),
// city towers with lit windows and three lanes of air traffic. Own small renderer, 30 fps, paused unless the base
// screen is open. Reduced motion → one still frame. Built from primitives (no downloads).
// Lore (High): the Coruscant Temple is a stepped ziggurat crowned by five spires, the central one tallest.
import * as THREE from '../../vendor/three.module.min.js';
import {mergeGeometries} from '../../vendor/BufferGeometryUtils.js';
import {GLTFLoader} from '../../vendor/GLTFLoader.js';
import {MeshoptDecoder} from '../../vendor/meshopt_decoder.module.js';

let R,scene,cam,canvas,traffic=[],craft=[],sky,L={},on=false,t0=performance.now(),last=0,angle=.6,built=false;
const CSS=`canvas.dio3d{position:fixed;inset:0;width:100vw;height:100vh;z-index:9;pointer-events:none;opacity:0;transition:opacity .8s}
body.dio canvas.dio3d{opacity:1}body.dio #modal{background:linear-gradient(180deg,#05090b22,#05090b88 75%)}
body.dio #modal .box.base{background:color-mix(in srgb,var(--panel) 90%,transparent);backdrop-filter:blur(3px)}`;
const reduce=()=>window.SETTINGS&&SETTINGS.reducedMotion?SETTINGS.reducedMotion():matchMedia('(prefers-reduced-motion: reduce)').matches;

function box(w,h,d,x,y,z){return new THREE.BoxGeometry(w,h,d).translate(x,y,z)}
function frustum(rb,rt,h,y){return new THREE.CylinderGeometry(rt,rb,h,4,1).rotateY(Math.PI/4).translate(0,y+h/2,0)}
function build(){const M=(c,o={})=>new THREE.MeshStandardMaterial({color:c,roughness:.75,metalness:.15,flatShading:true,...o});
 scene=new THREE.Scene();sky=new THREE.SphereGeometry(200,24,12);const cols=[],p=sky.attributes.position,lo=new THREE.Color(0xf09a5a),mid=new THREE.Color(0x6a4a7a),hi=new THREE.Color(0x0e1530);
 for(let i=0;i<p.count;i++){const k=Math.max(0,Math.min(1,p.getY(i)/120));const c=k<.25?lo.clone().lerp(mid,k/.25):mid.clone().lerp(hi,(k-.25)/.75);cols.push(c.r,c.g,c.b)}
 sky.setAttribute('color',new THREE.Float32BufferAttribute(cols,3));const skyM=new THREE.Mesh(sky,new THREE.MeshBasicMaterial({vertexColors:true,side:THREE.BackSide,fog:false}));scene.add(skyM);L.sky=skyM;
 scene.fog=new THREE.Fog(0x3a2e44,40,150);
 const hemi=new THREE.HemisphereLight(0xc8c0e0,0x4a3424,1.7);scene.add(hemi);const sun=new THREE.DirectionalLight(0xffc080,3);sun.position.set(30,24,26);scene.add(sun);
 const fill=new THREE.DirectionalLight(0xff9a6a,1.2);fill.position.set(-30,12,-24);scene.add(fill);Object.assign(L,{hemi,sun,fill});
 // Plaza and the Temple
 const stone=M(0xb8a888),stoneD=M(0x8a7c64),gold=M(0xe0bd78,{metalness:.6,roughness:.35}),win=new THREE.MeshBasicMaterial({color:0xffc878});L.win=win;
 scene.add(new THREE.Mesh(new THREE.CylinderGeometry(26,27,1,48).translate(0,-.5,0),M(0x3a3640)));
 const tiers=[[11,10,1.4],[9.6,8.6,1.3],[8.2,7.2,1.2],[6.8,5.8,1.1]];let y=0;const T=[],W=[];
 for(const [rb,rt,h] of tiers){T.push(frustum(rb,rt,h,y));for(const s of [-1,1])for(const ax of [0,1]){const L=rt*1.2,o=(rb+rt)/2*.707+.04;W.push(ax?box(.06,.14,L,s*o,y+h*.5,0):box(L,.14,.06,0,y+h*.5,s*o))}y+=h}
 for(let i=0;i<8;i++)T.push(box(3,.18,.9,0,i*.18+.09,7.6-i*.42));// processional stairs
 scene.add(new THREE.Mesh(mergeGeometries(T.map(g=>g.toNonIndexed())),stone),new THREE.Mesh(mergeGeometries(W),win));
 const top=y,S=[],G=[];const spire=(x,z,h,r)=>{S.push(frustum(r,r*.32,h,top).translate(x,0,z));S.push(frustum(r*1.25,r*1.05,.4,top).translate(x,0,z));G.push(new THREE.ConeGeometry(r*.32,h*.14,4).rotateY(Math.PI/4).translate(x,top+h+h*.07,z))};
 spire(0,0,9,1.1);for(const [x,z] of [[-3.2,-3.2],[3.2,-3.2],[-3.2,3.2],[3.2,3.2]])spire(x,z,5.2,.7);
 scene.add(new THREE.Mesh(mergeGeometries(S.map(g=>g.toNonIndexed())),stoneD),new THREE.Mesh(mergeGeometries(G),gold));
 // City: towers with window bands in rings around the plaza (2 draw calls)
 const tw=[],lit=[];let s=7;const rnd=()=>(s=(s*16807)%2147483647)/2147483647;
 for(let i=0;i<120;i++){const a=rnd()*6.283,d=55+rnd()*90,x=Math.cos(a)*d,z=Math.sin(a)*d,w=2+rnd()*4,h=5+rnd()*rnd()*45;tw.push(box(w,h,w,x,h/2-1,z));
  for(let yy=2;yy<h-1;yy+=2.2)if(rnd()<.55)lit.push(box(w+.06,.25,w*.5,x,yy,z))}
 const cityLit=new THREE.MeshBasicMaterial({color:0xffc060});L.city=cityLit;scene.add(new THREE.Mesh(mergeGeometries(tw),M(0x3a3646,{metalness:.3})),new THREE.Mesh(mergeGeometries(lit),cityLit));
 pads(M);
 // Air traffic: three lanes of moving lights
 for(const [r,h,n,sp,c] of [[40,14,40,.05,0xffe0a0],[56,22,50,-.035,0xff8a6a],[72,30,40,.025,0x9fe7ff]]){const g=new THREE.BufferGeometry(),pos=new Float32Array(n*3),ph=[...Array(n)].map(()=>rnd()*6.283);
  g.setAttribute('position',new THREE.BufferAttribute(pos,3));const pts=new THREE.Points(g,new THREE.PointsMaterial({color:c,size:.5,sizeAttenuation:true,fog:false}));scene.add(pts);traffic.push({pos,ph,r,h,sp,g})}
 cam=new THREE.PerspectiveCamera(40,1,.5,400);built=true;ships()}
// Landing pads on the plaza (two, east and west of the stairs) with pulsing rings.
const PADS=[[-15,4],[15,4]];let padRing=null;
function pads(M){const g=[],r=[];for(const [x,z] of PADS){g.push(new THREE.CylinderGeometry(3,3.2,.35,24).translate(x,.17,z));r.push(new THREE.RingGeometry(2.3,2.6,32).rotateX(-Math.PI/2).translate(x,.37,z))}
 scene.add(new THREE.Mesh(mergeGeometries(g),M(0x55505e,{metalness:.4})));padRing=new THREE.MeshBasicMaterial({color:0x79d3e2,transparent:true,opacity:.8,side:THREE.DoubleSide});scene.add(new THREE.Mesh(mergeGeometries(r),padRing))}
// Meshy ships (models/props/shuttle.glb, airtaxi.glb): shuttles land and lift off the pads; air taxis ride the traffic lanes.
// Missing files → the light-dot traffic alone.
function ships(){const ld=new GLTFLoader();ld.setMeshoptDecoder(MeshoptDecoder);const get=n=>ld.loadAsync(new URL(`../../models/props/${n}.glb`,import.meta.url).href).then(g=>g.scene).catch(()=>null);
 const fit=(o,len)=>{const b=new THREE.Box3().setFromObject(o),sz=b.getSize(new THREE.Vector3()),k=len/Math.max(sz.x,sz.z);o.scale.setScalar(k);const w=new THREE.Group();o.position.sub(b.getCenter(new THREE.Vector3()).multiplyScalar(k));w.add(o);return w};
 get('shuttle').then(m=>{if(!m)return;PADS.forEach(([x,z],i)=>{const o=fit(m.clone(),5);scene.add(o);craft.push({o,kind:'shuttle',x,z,ph:i*.5})})});
 get('airtaxi').then(m=>{if(!m)return;for(let i=0;i<10;i++){const o=fit(m.clone(),3.6);scene.add(o);craft.push({o,kind:'taxi',r:40+(i%3)*16,h:14+(i%3)*8,a:i*.63,sp:(i%2?1:-1)*(.05-(i%3)*.01)})}})}
// Shuttle cycle (40 s): approach from far out and high, descend onto the pad, sit, lift and climb away.
const ease=k=>k*k*(3-2*k);
function moveShips(t){for(const c of craft){const o=c.o;if(c.kind==='taxi'){const a=c.a+t*c.sp;o.position.set(Math.cos(a)*c.r,c.h+Math.sin(t*.5+c.a)*.6,Math.sin(a)*c.r);o.rotation.y=-a+(c.sp>0?0:Math.PI);continue}
  const k=((t/40+c.ph)%1),dir=Math.sign(c.x),far=new THREE.Vector3(c.x+dir*70,34,c.z-50),pad=new THREE.Vector3(c.x,1.6,c.z);let p,f;
  if(k<.35){f=ease(k/.35);p=far.clone().lerp(new THREE.Vector3(c.x,1.6+(1-f)*6,c.z),f);p.y=1.6+(1-f)*32}else if(k<.6){p=pad;f=1}else{f=ease((k-.6)/.4);p=pad.clone().lerp(new THREE.Vector3(c.x-dir*70,40,c.z+50),f);p.y=1.6+f*f*38}
  o.position.copy(p);o.rotation.y=k<.35?Math.atan2(-dir*70,50)+Math.PI:k<.6?Math.PI/2*dir:Math.atan2(-dir*70,50)}}
// Day/night: one cycle every 3 minutes (dusk → night → dawn → day). Windows and the city light up at night.
const SKY=[[0xf09a5a,0x6a4a7a,0x0e1530],[0x2a2a4a,0x14183a,0x04060f],[0xf5b08a,0x9a8ab8,0x3a5a8a],[0x8ab8e0,0x4a7ab8,0x1e3a78]],LIT=[1,1.6,.6,.25];
function daylight(t){if(!L.sun)return;const P=reduce()?0:(t/180)%1*4,i=Math.floor(P),j=(i+1)%4,f=P-i,mix=(a,b)=>new THREE.Color(a).lerp(new THREE.Color(b),f);
 const lo=mix(SKY[i][0],SKY[j][0]),md=mix(SKY[i][1],SKY[j][1]),hi=mix(SKY[i][2],SKY[j][2]),p=sky.attributes.position,c=sky.attributes.color;
 for(let n=0;n<p.count;n++){const k=Math.max(0,Math.min(1,p.getY(n)/120)),v=k<.25?lo.clone().lerp(md,k/.25):md.clone().lerp(hi,(k-.25)/.75);c.setXYZ(n,v.r,v.g,v.b)}c.needsUpdate=true;
 const night=[0,1,0,0][i]*(1-f)+[0,1,0,0][j]*f,day=[0,0,0,1][i]*(1-f)+[0,0,0,1][j]*f;L.sun.intensity=3*(1-night*.8)+day;L.sun.color.copy(new THREE.Color(0xffc080).lerp(new THREE.Color(0xfff4e0),day));
 L.hemi.intensity=1.7*(1-night*.55)+day*.4;L.fill.intensity=1.2*(1-night);scene.fog.color.copy(lo.clone().lerp(hi,.5));const lit=LIT[i]*(1-f)+LIT[j]*f;
 L.win.color.setRGB(1*lit,.78*lit,.47*lit);L.city.color.setRGB(1*lit,.75*lit,.38*lit);if(padRing)padRing.opacity=.5+.4*Math.sin(t*2);R.toneMappingExposure=1.7-day*.55}
function size(){const w=innerWidth,h=innerHeight;R.setSize(w,h,false);cam.aspect=w/h;cam.updateProjectionMatrix()}
function frame(now){requestAnimationFrame(frame);if(!on||document.hidden)return;if(now-last<33)return;const dt=Math.min(.1,(now-last)/1000);last=now;
 if(!reduce())angle+=dt*.045;const t=(now-t0)/1000,d=cam.aspect<1?44:31;cam.position.set(Math.sin(angle)*d,6.5+Math.sin(t*.1)*1.2,Math.cos(angle)*d);cam.lookAt(0,7.5,0);
 for(const L of traffic){for(let i=0;i<L.ph.length;i++){const a=L.ph[i]+t*L.sp*(i%2?1:-1);L.pos[i*3]=Math.cos(a)*(L.r+(i%5));L.pos[i*3+1]=L.h+(i%4)*1.5;L.pos[i*3+2]=Math.sin(a)*(L.r+(i%5))}L.g.attributes.position.needsUpdate=true}
 moveShips(t);daylight(t);R.render(scene,cam)}
function check(){const m=document.getElementById('modal'),want=!!(m&&!m.hidden&&m.querySelector('.box.base'));if(want===on)return;on=want;
 if(on&&!R){R=new THREE.WebGLRenderer({canvas,antialias:false,powerPreference:'low-power'});R.setPixelRatio(Math.min(devicePixelRatio,1.5));R.outputColorSpace=THREE.SRGBColorSpace;
  R.toneMapping=THREE.ACESFilmicToneMapping;R.toneMappingExposure=1.7;if(!built)build();size();addEventListener('resize',size);requestAnimationFrame(frame)}
 last=0;document.body.classList.toggle('dio',on)}
export function startDiorama(){canvas=document.createElement('canvas');canvas.className='dio3d';canvas.setAttribute('aria-hidden','true');document.body.appendChild(canvas);
 const st=document.createElement('style');st.textContent=CSS;document.head.appendChild(st);
 const m=document.getElementById('modal');if(m)new MutationObserver(check).observe(m,{childList:true,attributes:true,attributeFilter:['hidden']});check()}

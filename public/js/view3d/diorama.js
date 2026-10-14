// Slow-turning 3D Jedi Temple behind the Temple base screen: the ziggurat with its five spires on Coruscant at dusk,
// city towers with lit windows and three lanes of air traffic. Own small renderer, 30 fps, paused unless the base
// screen is open. Reduced motion → one still frame. Built from primitives (no downloads).
// Lore (High): the Coruscant Temple is a stepped ziggurat crowned by five spires, the central one tallest.
import * as THREE from '../../vendor/three.module.min.js';
import {mergeGeometries} from '../../vendor/BufferGeometryUtils.js';

let R,scene,cam,canvas,traffic=[],on=false,t0=performance.now(),last=0,angle=.6,built=false;
const CSS=`canvas.dio3d{position:fixed;inset:0;width:100vw;height:100vh;z-index:9;pointer-events:none;opacity:0;transition:opacity .8s}
body.dio canvas.dio3d{opacity:1}body.dio #modal{background:linear-gradient(180deg,#05090b22,#05090b88 75%)}
body.dio #modal .box.base{background:color-mix(in srgb,var(--panel) 90%,transparent);backdrop-filter:blur(3px)}`;
const reduce=()=>window.SETTINGS&&SETTINGS.reducedMotion?SETTINGS.reducedMotion():matchMedia('(prefers-reduced-motion: reduce)').matches;

function box(w,h,d,x,y,z){return new THREE.BoxGeometry(w,h,d).translate(x,y,z)}
function frustum(rb,rt,h,y){return new THREE.CylinderGeometry(rt,rb,h,4,1).rotateY(Math.PI/4).translate(0,y+h/2,0)}
function build(){const M=(c,o={})=>new THREE.MeshStandardMaterial({color:c,roughness:.75,metalness:.15,flatShading:true,...o});
 scene=new THREE.Scene();const sky=new THREE.SphereGeometry(200,24,12),cols=[],p=sky.attributes.position,lo=new THREE.Color(0xf09a5a),mid=new THREE.Color(0x6a4a7a),hi=new THREE.Color(0x0e1530);
 for(let i=0;i<p.count;i++){const k=Math.max(0,Math.min(1,p.getY(i)/120));const c=k<.25?lo.clone().lerp(mid,k/.25):mid.clone().lerp(hi,(k-.25)/.75);cols.push(c.r,c.g,c.b)}
 sky.setAttribute('color',new THREE.Float32BufferAttribute(cols,3));scene.add(new THREE.Mesh(sky,new THREE.MeshBasicMaterial({vertexColors:true,side:THREE.BackSide,fog:false})));
 scene.fog=new THREE.Fog(0x3a2e44,40,150);
 scene.add(new THREE.HemisphereLight(0xc8c0e0,0x4a3424,1.7));const sun=new THREE.DirectionalLight(0xffc080,3);sun.position.set(30,24,26);scene.add(sun);
 const fill=new THREE.DirectionalLight(0xff9a6a,1.2);fill.position.set(-30,12,-24);scene.add(fill);
 // Plaza and the Temple
 const stone=M(0xb8a888),stoneD=M(0x8a7c64),gold=M(0xe0bd78,{metalness:.6,roughness:.35}),win=new THREE.MeshBasicMaterial({color:0xffc878});
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
 scene.add(new THREE.Mesh(mergeGeometries(tw),M(0x3a3646,{metalness:.3})),new THREE.Mesh(mergeGeometries(lit),new THREE.MeshBasicMaterial({color:0xffc060})));
 // Air traffic: three lanes of moving lights
 for(const [r,h,n,sp,c] of [[40,14,40,.05,0xffe0a0],[56,22,50,-.035,0xff8a6a],[72,30,40,.025,0x9fe7ff]]){const g=new THREE.BufferGeometry(),pos=new Float32Array(n*3),ph=[...Array(n)].map(()=>rnd()*6.283);
  g.setAttribute('position',new THREE.BufferAttribute(pos,3));const pts=new THREE.Points(g,new THREE.PointsMaterial({color:c,size:.5,sizeAttenuation:true,fog:false}));scene.add(pts);traffic.push({pos,ph,r,h,sp,g})}
 cam=new THREE.PerspectiveCamera(40,1,.5,400);built=true}
function size(){const w=innerWidth,h=innerHeight;R.setSize(w,h,false);cam.aspect=w/h;cam.updateProjectionMatrix()}
function frame(now){requestAnimationFrame(frame);if(!on||document.hidden)return;if(now-last<33)return;const dt=Math.min(.1,(now-last)/1000);last=now;
 if(!reduce())angle+=dt*.045;const t=(now-t0)/1000,d=cam.aspect<1?44:31;cam.position.set(Math.sin(angle)*d,6.5+Math.sin(t*.1)*1.2,Math.cos(angle)*d);cam.lookAt(0,7.5,0);
 for(const L of traffic){for(let i=0;i<L.ph.length;i++){const a=L.ph[i]+t*L.sp*(i%2?1:-1);L.pos[i*3]=Math.cos(a)*(L.r+(i%5));L.pos[i*3+1]=L.h+(i%4)*1.5;L.pos[i*3+2]=Math.sin(a)*(L.r+(i%5))}L.g.attributes.position.needsUpdate=true}
 R.render(scene,cam)}
function check(){const m=document.getElementById('modal'),want=!!(m&&!m.hidden&&m.querySelector('.box.base'));if(want===on)return;on=want;
 if(on&&!R){R=new THREE.WebGLRenderer({canvas,antialias:false,powerPreference:'low-power'});R.setPixelRatio(Math.min(devicePixelRatio,1.5));R.outputColorSpace=THREE.SRGBColorSpace;
  R.toneMapping=THREE.ACESFilmicToneMapping;R.toneMappingExposure=1.7;if(!built)build();size();addEventListener('resize',size);requestAnimationFrame(frame)}
 last=0;document.body.classList.toggle('dio',on)}
export function startDiorama(){canvas=document.createElement('canvas');canvas.className='dio3d';canvas.setAttribute('aria-hidden','true');document.body.appendChild(canvas);
 const st=document.createElement('style');st.textContent=CSS;document.head.appendChild(st);
 const m=document.getElementById('modal');if(m)new MutationObserver(check).observe(m,{childList:true,attributes:true,attributeFilter:['hidden']});check()}

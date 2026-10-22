// Armory 3D preview (wave 7, V2): the selected unit's 3D model turns slowly in the Armory gear panel, wearing their
// current kit. Hover (or focus) an upgrade button — armor, weapon tier, mod, color — and the model shows it on before
// you buy. Placed by watching the DOM for the Armory's `.tw .gear` panel (no edits to temple-ui.js). Own small renderer;
// stops when the panel is gone. Reduced motion → no turntable, still pose.
import * as THREE from '../../vendor/three.module.min.js';
import {initFigures,loadModel,makeFigure,fileOf} from './figures.js';
import {kindOf} from './units.js';

let R,scene,cam,canvas,wrap,fig=null,figKey='',want=null,on=false,last=0,yaw=-.5,rec=null,hov=null;
const CSS=`.arm3d{float:right;width:210px;height:280px;margin:0 0 8px 12px;border:1px solid var(--line);border-radius:8px;position:relative;
 background:radial-gradient(ellipse at 50% 85%,color-mix(in srgb,var(--holo) 22%,transparent),transparent 60%),var(--panel)}
.arm3d canvas{width:100%;height:100%;display:block}.arm3d small{position:absolute;left:8px;bottom:6px;font:500 11px var(--mono);color:var(--holo);letter-spacing:.06em;pointer-events:none}
@media(max-width:700px){.arm3d{float:none;width:100%;height:220px;margin:0 0 8px}}`;
const reduce=()=>window.SETTINGS&&SETTINGS.reducedMotion?SETTINGS.reducedMotion():matchMedia('(prefers-reduced-motion: reduce)').matches;
const isJ=r=>typeof isJedi==='function'?isJedi(r):!!(window.CLASS&&CLASS[r.cls]&&CLASS[r.cls].jedi);

function setup(){initFigures(THREE);R=new THREE.WebGLRenderer({antialias:true,alpha:true,powerPreference:'low-power'});R.setPixelRatio(Math.min(devicePixelRatio,2));
 R.outputColorSpace=THREE.SRGBColorSpace;R.toneMapping=THREE.ACESFilmicToneMapping;R.toneMappingExposure=1.2;canvas=R.domElement;
 scene=new THREE.Scene();scene.add(new THREE.HemisphereLight(0xdfefff,0x1a2224,1.4));const key=new THREE.DirectionalLight(0xfff0dc,2.6);key.position.set(1.5,2.5,3);scene.add(key);
 const rim=new THREE.DirectionalLight(0x79d3e2,2.4);rim.position.set(-2,1.8,-2.5);scene.add(rim);
 const disc=new THREE.Mesh(new THREE.CylinderGeometry(.55,.6,.06,40),new THREE.MeshStandardMaterial({color:0x15232a,metalness:.4,roughness:.5}));disc.position.y=-.03;scene.add(disc);
 const ring=new THREE.Mesh(new THREE.TorusGeometry(.58,.012,6,48),new THREE.MeshBasicMaterial({color:0x79d3e2}));ring.rotation.x=Math.PI/2;scene.add(ring);
 cam=new THREE.PerspectiveCamera(30,210/280,.05,20);cam.position.set(0,1.0,3.9);cam.lookAt(0,.85,0)}

// The kit the model should wear: the unit's gear, plus whatever upgrade button is hovered.
function kitFor(r,h){const g=r.gear||{},k={armor:g.armor,w:g.w,mods:[...(g.mods||[])],look:r.look,cls:r.cls,species:r.species};let col=r.col,tag='';
 if(h){const [a,,x]=h.split(':');if(a==='armor'){k.armor=x;tag='Preview: '+((typeof ARMOR!=="undefined"&&ARMOR[x]||{}).n||x)}else if(a==='wpn'){k.w=(k.w||0)+1;tag='Preview: weapon upgrade'}
  else if(a==='mod'&&!k.mods.includes(x)){k.mods.push(x);tag='Preview: '+((typeof MODS!=="undefined"&&MODS[x]||{}).n||x)}else if(a==='col'){col=x;tag='Preview: color'}else if(a==='saber'){tag='Preview: new saber'}}
 return {k,col,tag}}
function show(){if(!rec||!R)return;const r=rec,{k,col,tag}=kitFor(r,hov),u={n:r.n,cls:r.cls,col,side:'p',jedi:isJ(r)},kind=kindOf(u),key=[kind,col,k.armor,k.w,k.mods.join('+'),k.look,k.species].join('|');
 const lab=wrap&&wrap.querySelector('small');if(lab)lab.textContent=tag||r.n;if(key===figKey)return;want=key;
 loadModel(fileOf(kind)).then(()=>{if(want!==key)return;const F=makeFigure(kind,col||'#e0bd78',k);if(!F)return;if(fig)scene.remove(fig.obj);fig=F;figKey=key;
  const b=new THREE.Box3().setFromObject(F.obj),h=b.getSize(new THREE.Vector3()).y||1.7;F.obj.position.y-=b.min.y;F.obj.scale.multiplyScalar(1.75/h);F.obj.position.y*=1.75/h;
  scene.add(F.obj);const a=F.acts.saberIdle&&isJ(r)?F.acts.saberIdle:F.acts.gunIdle&&!isJ(r)?F.acts.gunIdle:F.acts.idle;if(a)a.play();draw(0)})}
function draw(dt){if(!fig)return;fig.mixer.update(dt);if(!reduce())yaw+=dt*.45;fig.obj.rotation.y=yaw;R.render(scene,cam)}
function frame(now){if(!on)return;requestAnimationFrame(frame);if(document.hidden||now-last<33)return;const dt=last?Math.min(.1,(now-last)/1000):0;last=now;draw(reduce()?0:dt)}

function attach(gear){const id=(document.querySelector('.ulist button.on[data-act^="arm:"]')||{}).dataset?.act?.split(':')[1];const r=id&&typeof C!=="undefined"&&C&&C.roster.find(x=>x.id===id);if(!r)return;
 if(!R)setup();wrap=document.createElement('div');wrap.className='arm3d';wrap.setAttribute('aria-hidden','true');wrap.appendChild(canvas);wrap.insertAdjacentHTML('beforeend','<small></small>');gear.prepend(wrap);
 const sz=()=>{const w=wrap.clientWidth,h=wrap.clientHeight;if(w&&h){R.setSize(w,h,false);cam.aspect=w/h;cam.updateProjectionMatrix();if(fig)R.render(scene,cam)}};sz();
 if(rec!==r){rec=r;figKey=''}hov=null;show();gear.onpointerover=gear.onfocusin=e=>{const b=e.target.closest('button[data-act]');const a=b&&!b.disabled&&/^(armor|wpn|mod|col|saber):/.test(b.dataset.act)?b.dataset.act:null;if(a!==hov){hov=a;show()}};
 gear.onpointerleave=()=>{if(hov){hov=null;show()}};if(!on){on=true;last=0;requestAnimationFrame(frame)}}
function check(){const g=document.querySelector('.tw .gear');if(!g){on=false;return}if(g.querySelector('.arm3d'))return;try{attach(g)}catch(e){console.warn('armory 3D off',e)}}
export function startArmory(){const st=document.createElement('style');st.textContent=CSS;document.head.appendChild(st);
 let q=0;new MutationObserver(()=>{if(!q){q=1;requestAnimationFrame(()=>{q=0;check()})}}).observe(document.body,{childList:true,subtree:true});check()}

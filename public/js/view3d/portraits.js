// 3D head-and-shoulders portraits, rendered once per look (kind + saber color) on a small offscreen renderer and cached
// as PNG data URLs. A DOM pass drops them into the battle roster, the Temple roster and the debrief (no edits to other
// chats' files): it watches #roster and #modal and decorates matching rows. Any element with data-pt="<roster id>" or
// data-pt="uid:<n>" also gets one, so other chats can place portraits explicitly.
import * as THREE from '../../vendor/three.module.min.js';
import {initFigures,loadModel,makeFigure,fileOf} from './figures.js';
import {kindOf} from './units.js';

const cache=new Map(),pending=new Set(),SIZE=128;let R=null,scene,cam,busy=false;
const asUnit=r=>r.side?r:{n:r.n,cls:r.cls,col:r.col,side:'p',jedi:typeof isJedi==='function'?isJedi(r):!!(window.CLASS&&CLASS[r.cls]&&CLASS[r.cls].jedi)};
const colorOf=u=>u.vip?'#7fd99a':u.col||'#e0bd78';
const keyOf=u=>kindOf(u)+'|'+colorOf(u);

function setup(){initFigures(THREE);const c=document.createElement('canvas');c.width=c.height=SIZE;
 R=new THREE.WebGLRenderer({canvas:c,alpha:true,antialias:true,preserveDrawingBuffer:true});R.setPixelRatio(1);R.setSize(SIZE,SIZE,false);
 R.outputColorSpace=THREE.SRGBColorSpace;R.toneMapping=THREE.ACESFilmicToneMapping;R.toneMappingExposure=1.2;
 scene=new THREE.Scene();scene.add(new THREE.HemisphereLight(0xdfefff,0x1a2224,1.3));
 const key=new THREE.DirectionalLight(0xfff0dc,2.6);key.position.set(1.5,2.5,3);scene.add(key);
 const rim=new THREE.DirectionalLight(0x79d3e2,2.2);rim.position.set(-2,1.5,-2.5);scene.add(rim);scene.userData.rim=rim;
 cam=new THREE.PerspectiveCamera(26,1,.05,20)}

// Returns a cached data URL, or null and starts rendering it (calls onReady when done).
export function portrait(r,onReady){if(!glOK())return null;const u=asUnit(r),k=keyOf(u);if(cache.has(k))return cache.get(k);
 if(!pending.has(k)){pending.add(k);queue.push({u,k,onReady});pump()}return null}
const queue=[];
function pump(){if(busy||!queue.length)return;busy=true;const job=queue.shift(),file=fileOf(kindOf(job.u));
 loadModel(file).then(m=>{try{if(m)cache.set(job.k,shoot(job.u))}catch(e){console.warn('portrait failed',e)}
  pending.delete(job.k);busy=false;if(job.onReady)job.onReady();(window.requestIdleCallback||setTimeout)(pump)})}
function shoot(u){if(!R)setup();const F=makeFigure(kindOf(u),colorOf(u));if(!F)return null;const o=F.obj;
 o.rotation.y=-.42;scene.add(o);const a=F.acts.idle||Object.values(F.acts)[0];if(a){a.play();F.mixer.update(.6)}o.updateMatrixWorld(true);
 const head=new THREE.Vector3();(o.getObjectByName('Head')||o).getWorldPosition(head);
 scene.userData.rim.color.set(colorOf(u));
 cam.position.set(head.x+.12,head.y+.02,head.z+.95);cam.lookAt(head.x,head.y-.1,head.z);R.render(scene,cam);const url=R.domElement.toDataURL('image/png');
 scene.remove(o);for(const m of F.mats)m.dispose();o.traverse(x=>{if(x.material&&!F.mats.includes(x.material)&&x.material.dispose)x.material.dispose()});return url}

let ok=null;const glOK=()=>ok??(ok=(()=>{try{const c=document.createElement('canvas');return !!(c.getContext('webgl2')||c.getContext('webgl'))}catch(e){return false}})());

// ---- DOM pass ----
const CSS=`img.pt3d{width:28px;height:28px;border-radius:50%;object-fit:cover;flex:none;vertical-align:middle;margin-right:6px;
 background:radial-gradient(circle at 50% 40%,color-mix(in srgb,var(--uc,#79d3e2) 35%,#16252a),#0a1214 75%);border:1px solid color-mix(in srgb,var(--uc,#79d3e2) 70%,transparent)}
#roster img.pt3d{width:24px;height:24px;margin:-4px 5px -4px -2px}.pt3d-in>svg{display:none}.pt3d-in>img.pt3d{margin:0;width:100%;height:100%}
.sum img.pt3d{width:26px;height:26px}`;
function slot(el,r,mode){if(!el||el.querySelector(':scope > img.pt3d'))return;const url=portrait(r,schedule);if(!url)return;
 const img=document.createElement('img');img.className='pt3d';img.alt='';img.src=url;img.decoding='async';const u=asUnit(r);
 if(!el.style.getPropertyValue('--uc'))img.style.setProperty('--uc',colorOf(u));
 if(mode==='in'){el.classList.add('pt3d-in');el.prepend(img)}else el.insertBefore(img,el.firstChild)}
function byName(n){n=(n||'').trim();if(!n)return null;const s=typeof S!=='undefined'&&S&&S.units.find(u=>u.side==='p'&&u.n===n);if(s)return s;
 return typeof C!=='undefined'&&C&&C.roster&&C.roster.find(r=>r.n===n)||null}
function scan(){queued=false;if(!glOK())return;
 if(typeof S!=='undefined'&&S){const ps=S.units.filter(u=>u.side==='p');for(const b of document.querySelectorAll('#roster button[data-u]')){const u=ps[+b.dataset.u];if(u)slot(b,u,'prep')}}
 for(const row of document.querySelectorAll('#modal .rrow')){const r=byName(row.querySelector('.rmain b')?.textContent);if(r)slot(row.querySelector('.mini'),r,'in')}
 for(const sp of document.querySelectorAll('#modal .sum > div > span:first-child')){const t=[...sp.childNodes].find(n=>n.nodeType===3);const r=t&&byName(t.textContent);if(r)slot(sp,r,'prep')}
 for(const el of document.querySelectorAll('[data-pt]')){const v=el.dataset.pt;let r=null;
  if(v.startsWith('uid:')&&typeof S!=='undefined'&&S)r=S.units.find(u=>u.uid===+v.slice(4));else if(typeof C!=='undefined'&&C&&C.roster)r=C.roster.find(x=>x.id===v);if(r)slot(el,r,'in')}}
let queued=false;function schedule(){if(!queued){queued=true;requestAnimationFrame(scan)}}
export function startPortraits(){if(!glOK())return;const st=document.createElement('style');st.textContent=CSS;document.head.appendChild(st);
 const mo=new MutationObserver(schedule);for(const id of ['roster','modal']){const el=document.getElementById(id);if(el)mo.observe(el,{childList:true,subtree:true})}schedule()}

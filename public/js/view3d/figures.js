// Rigged characters: CC0 Quaternius models (public/models, see CREDITS.md) dressed per unit kind with bone-attached
// low-poly gear (robes, hoods, helmets, pads, sabers, blasters). Loaded lazily the first time a 3D mission needs them;
// until then units.js draws its primitive figures. Every clip is mapped to one of our animation names below.
import {GLTFLoader} from '../../vendor/GLTFLoader.js';
import {MeshoptDecoder} from '../../vendor/meshopt_decoder.module.js';
import {clone as skClone} from '../../vendor/SkeletonUtils.js';

let T=null;const cache={};
const FILE={human:new URL('../../models/human.glb',import.meta.url).href,beast:new URL('../../models/beast.glb',import.meta.url).href};
// Meshy unit models (public/models/units/<kind>.glb, see CREDITS.md): textured, Mixamo-rigged, our clips baked in,
// bones renamed to the names below, weapons hang off a 'grip_r' node. A kind listed here that fails to load falls back to the mannequin.
export const UNITS=new Set(['jedi','trooper','scout','medic','heavy','sith','sithHeavy','mando','agent']);
const urlOf=n=>n.startsWith('u_')?new URL(`../../models/units/${n.slice(2)}.glb`,import.meta.url).href:FILE[n];
// Right hand rest matrix of human.glb: weapon parts are authored in that model's space and re-expressed relative to the hand.
const HSRC=[0,1,0,0,-1,0,0,0,0,0,1,0,-.7389,1.4408,-.0654,1];let HI=null;
const WEAP=new Set(['saber','rifle','longrifle','cannon','pistol']);
// Our names → clip names in each file (human.glb clips were renamed at build time).
const CLIPS={beast:{idle:'Idle',walk:'Walk',run:'Run',swing:'Punch',swing2:'Weapon',claw:'Punch',hit:'HitReact',knock:'HitReact',death:'Death',death2:'Death',toLay:'Death',
 getUp:'Jump_Land',jumpStart:'Jump',jumpLoop:'Jump_Idle',jumpLand:'Jump_Land',cast:'Weapon',lifted:'Duck',cheer:'Yes'}};
const legacyOf=kind=>kind==='beast'||kind==='spawn'?'beast':kind==='nexus'||kind==='nexusCore'?null:'human';
export const fileOf=kind=>UNITS.has(kind)?'u_'+kind:legacyOf(kind);
export function loadModel(name){if(!name)return Promise.resolve(null);if(cache[name])return cache[name].p;const c=cache[name]={ok:null};
 const L=new GLTFLoader();L.setMeshoptDecoder(MeshoptDecoder);
 c.p=L.loadAsync(urlOf(name)).then(g=>{const meshy=name.startsWith('u_'),h=meshy?new T.Box3().setFromObject(g.scene).getSize(new T.Vector3()).y:0;c.ok={scene:g.scene,clips:g.animations,meshy,h};return c.ok})
  .catch(e=>{if(name.startsWith('u_')){console.warn('Meshy model failed, using mannequin:',name,e);const k=name.slice(2);UNITS.delete(k);return loadModel(legacyOf(k)).then(m=>{c.ok=m||false;return m})}
   console.warn('3D model failed, using block figures:',name,e);c.ok=false;return null});
 return c.p}
export const modelOf=name=>name&&cache[name]&&cache[name].ok||null;
export function initFigures(THREE){T=THREE}

// Looks. main/joint = mannequin colors; gear = list of bone-attached parts.
const LOOK={
 jedi:{main:0xb99a6b,joint:0x4a3524,gear:['robe','tabard','hair','belt','saber']},
 trooper:{main:0xe6e8ea,joint:0x5b6168,accent:0xa8322b,gear:['helmet','pads','chest','rifle']},
 scout:{main:0xd5dbd4,joint:0x56604f,accent:0xa8322b,gear:['helmet','pads','longrifle','kama']},
 medic:{main:0xe6e8ea,joint:0x5b6168,accent:0x4fb878,gear:['helmet','pads','pack','pistol']},
 heavy:{main:0xd5d9dc,joint:0x4e545a,accent:0xa8322b,bulk:1.12,gear:['helmet','pads','chest','cannon']},
 sith:{main:0x2d2e35,joint:0x141418,accent:0x9e1f1f,visor:0xff3b2e,gear:['helmet','pads','chest','rifle']},
 sithHeavy:{main:0x26272d,joint:0x121215,accent:0x9e1f1f,visor:0xff3b2e,bulk:1.18,gear:['helmet','pads','chest','cannon']},
 mando:{main:0x6e7f8a,joint:0x2a2f33,accent:0xc49a3a,visor:0x101418,gear:['mhelm','pads','chest','rifle','jetpack']},
 agent:{main:0x3a434b,joint:0x1c2126,accent:0x6a1f1f,gear:['cap','coat','longrifle']},
 acolyte:{main:0x24191f,joint:0x0e0b0d,saber:0xff3b2e,gear:['robe','hood','belt','saber']},
 malgus:{main:0x1d1d22,joint:0x0b0b0d,accent:0x5a1414,saber:0xff3b2e,visor:0xff3b2e,bulk:1.15,gear:['mask','pads','chest','cape','saber']},
 // Era 2 (Ruusan, ~1,000 BBY): Brotherhood of Darkness.
 bhTrooper:{main:0x4a3a34,joint:0x1e1614,accent:0x8a2a1a,visor:0xff6a2a,gear:['helmet','pads','chest','rifle','kama']},
 sniper:{main:0x5a5a48,joint:0x2a2a20,accent:0x6a6a3a,gear:['hood','coat','longrifle']},
 marauder:{main:0x3a1c1c,joint:0x120808,accent:0x6a1414,saber:0xff3b2e,gear:['tabard','belt','pads','saber']},
 sithLord:{main:0x1e1a22,joint:0x0b0a0d,accent:0x4a1020,saber:0xff3b2e,gear:['robe','hood','cape','belt','saber']},
 kaan:{main:0x2a2018,joint:0x100c08,accent:0xb8862a,saber:0xff3b2e,bulk:1.05,gear:['robe','cowl','cape','belt','saber']},
 bane:{main:0x24201c,joint:0x0d0b0a,accent:0x3a2a1a,saber:0xff2a1a,visor:0xff3b2e,bulk:1.18,gear:['mask','pads','chest','robe','saber']},
 envoy:{main:0x8a8f96,joint:0x4a4f56,gear:['robe','belt','pistol']},
 civ:{main:0x9a8a66,joint:0x5a4f3a,gear:['robe','belt']}};

const mat=(c,o={})=>new T.MeshStandardMaterial({color:c,roughness:.6,metalness:.25,flatShading:true,...o});
const glow=c=>new T.MeshStandardMaterial({color:c,emissive:c,emissiveIntensity:1.8,roughness:.4});
// A part placed in model space (T-pose, meters, facing +z), then re-parented to a bone keeping its world transform.
function part(fig,bone,geo,m,s,p,r){const o=new T.Mesh(geo,m);o.scale.set(...s);o.position.set(...p);if(r)o.rotation.set(...r);o.castShadow=false;
 if(fig.userData.grip&&bone==='hand_r'){HI=HI||new T.Matrix4().fromArray(HSRC).invert();o.updateMatrix();o.matrix.premultiply(HI);o.matrix.decompose(o.position,o.quaternion,o.scale);fig.userData.grip.add(o);return o} // the skinned body casts; small gear doesn't (saves shadow draws)

 fig.add(o);o.updateMatrixWorld(true);const b=fig.getObjectByName(bone);if(b)b.attach(o);return o}

let G=null;const geos=()=>G||(G={box:new T.BoxGeometry(1,1,1),cyl:new T.CylinderGeometry(1,1,1,10),cone:new T.ConeGeometry(1,1,10,1,true),
 skirt:new T.CylinderGeometry(.62,1,1,10,1,true),sph:new T.SphereGeometry(1,12,9),hood:new T.SphereGeometry(1,12,9,0,Math.PI*2,0,Math.PI*.62),
 core:new T.CylinderGeometry(1,1,1,8)});

// Builds one figure. Returns {obj, mixer, acts, glows, mats, scale}. color = saber/unit color (hex string or number).
export function makeFigure(kind,color){const file=fileOf(kind),M=modelOf(file);if(!M)return null;
 const obj=skClone(M.scene),mats=[],g=geos();obj.updateMatrixWorld(true);
 if(file==='beast'){obj.traverse(o=>{if(o.isMesh){o.material=new T.MeshStandardMaterial({color:kind==='spawn'?0x8a8494:0x6e5644,roughness:.85,metalness:.05,flatShading:true});o.material.flatShading=true;o.castShadow=true;mats.push(o.material)}});
  const eye=glow(kind==='spawn'?0xb26bff:0xff3b2e);mats.push(eye);for(const s of [-1,1])part(obj,'Head',g.sph,eye,[.09,.06,.05],[s*.36,2.95,.62]);
  const horn=mat(kind==='spawn'?0x3a2a4a:0xd8cbb0);mats.push(horn);if(kind==='spawn')for(let i=0;i<5;i++)part(obj,'Torso',g.cone,horn,[.1,.5,.1],[(i-2)*.22,2.5-Math.abs(i-2)*.1,-.45],[-.6,0,(i-2)*-.2]);
  else for(const s of [-1,1])part(obj,'Head',g.cone,horn,[.12,.6,.12],[s*.6,3.45,.2],[.3,0,s*-.5]);
  for(const m of [eye,horn])m.userData.e0=m.emissive.clone();
  return finish(obj,M,kind,mats,[],kind==='spawn'?.36:.42)}
 const meshy=M.meshy,beastK=kind==='beast'||kind==='spawn',L=LOOK[kind]||LOOK.trooper,[mm,mj]=[mat(L.main),mat(L.joint,{metalness:.35})];
 if(meshy){obj.userData.grip=obj.getObjectByName('grip_r');obj.traverse(o=>{if(o.isMesh){o.castShadow=true;o.frustumCulled=false;o.material=o.material.clone();mats.push(o.material)}})}
 else{mats.push(mm,mj);obj.traverse(o=>{if(o.isMesh){o.castShadow=true;o.material=/Joint/.test(o.material.name)?mj:mm}})}
 const ma=mat(L.accent||L.joint),mw=mat(0x24282c,{metalness:.7,roughness:.35}),mv=L.visor?glow(L.visor):mat(0x14202a,{metalness:.6});mats.push(ma,mw,mv);
 const glows=[],bulk=L.bulk||1;
 for(const k of meshy?(beastK?[]:L.gear.filter(k=>WEAP.has(k))):L.gear)switch(k){
  case 'robe':part(obj,'pelvis',g.skirt,mm,[.2,.62,.17],[0,.66,.0]).castShadow=true;break;
  case 'cape':part(obj,'spine_03',g.box,ma,[.4,.9,.02],[0,1.0,-.13],[.08,0,0]);break;
  case 'kama':part(obj,'pelvis',g.box,ma,[.34,.3,.03],[0,.78,-.12],[.1,0,0]);break;
  case 'coat':part(obj,'pelvis',g.skirt,mm,[.18,.42,.15],[0,.8,0]);part(obj,'spine_03',g.box,ma,[.38,.05,.24],[0,1.43,0]);break;
  case 'tabard':part(obj,'spine_03',g.box,mj,[.12,.42,.24],[0,1.3,.0]);break;
  case 'hair':part(obj,'Head',g.hood,mat(0x2a1d14),[.125,.13,.13],[0,1.69,-.02],[-.35,0,0]);break;
  case 'cowl':part(obj,'spine_03',g.box,mj,[.42,.1,.26],[0,1.44,-.02]);part(obj,'spine_03',g.box,mj,[.3,.16,.08],[0,1.48,-.14],[.4,0,0]);break;
  case 'hood':part(obj,'Head',g.hood,mm,[.16,.21,.17],[0,1.62,-.015]);part(obj,'Head',g.box,mat(0x050506),[.13,.12,.03],[0,1.62,.12]);break;
  case 'belt':part(obj,'pelvis',g.cyl,mj,[.17,.06,.13],[0,1.0,0]);break;
  case 'helmet':part(obj,'Head',g.sph,mm,[.15,.16,.155],[0,1.69,.01]);part(obj,'Head',g.box,mv,[.17,.045,.06],[0,1.68,.12]);
   part(obj,'Head',g.box,ma,[.03,.07,.17],[0,1.84,.02]);break;
  case 'mhelm':part(obj,'Head',g.sph,mm,[.15,.165,.155],[0,1.69,.01]);part(obj,'Head',g.box,mv,[.17,.04,.06],[0,1.7,.125]);part(obj,'Head',g.box,mv,[.045,.13,.06],[0,1.63,.125]);break;
  case 'mask':part(obj,'Head',g.sph,mm,[.14,.16,.15],[0,1.69,.0]);part(obj,'Head',g.box,mv,[.14,.03,.05],[0,1.7,.12]);part(obj,'Head',g.box,mw,[.12,.09,.05],[0,1.6,.12]);break;
  case 'cap':part(obj,'Head',g.cyl,ma,[.13,.07,.14],[0,1.8,.0]);part(obj,'Head',g.box,ma,[.18,.015,.12],[0,1.77,.09]);break;
  case 'pads':for(const s of [-1,1])part(obj,s<0?'upperarm_r':'upperarm_l',g.sph,ma,[.12*bulk,.07,.11*bulk],[s*.19,1.46,0]);break;
  case 'chest':part(obj,'spine_03',g.box,mm,[.36*bulk,.24,.24*bulk],[0,1.3,.02]);part(obj,'spine_03',g.box,ma,[.14,.08,.03],[0,1.32,.15]);break;
  case 'pack':part(obj,'spine_03',g.box,mat(0xf2f2f2),[.26,.28,.12],[0,1.25,-.17]);part(obj,'spine_03',g.box,ma,[.1,.1,.02],[0,1.28,-.24]);break;
  case 'jetpack':for(const s of [-1,1])part(obj,'spine_03',g.cyl,ma,[.06,.3,.06],[s*.08,1.25,-.18]);break;
  // Weapons sit in the right hand (model -x side in T-pose). Grip along the fist, barrel/blade forward (+z).
  case 'saber':{const hx=-.74,hy=1.44;part(obj,'hand_r',g.cyl,mat(0xb8bcc0,{metalness:.85,roughness:.3}),[.022,.2,.022],[hx,hy,.02],[Math.PI/2,0,0]);
   const c=new T.Color(L.saber||color),core=new T.MeshBasicMaterial({color:c.clone().lerp(new T.Color(0xffffff),.45)});
   const bl=part(obj,'hand_r',g.core,core,[.016,.95,.016],[hx,hy,.6],[Math.PI/2,0,0]);
   for(const [r,o] of [[.045,.7],[.09,.22]]){const gm=new T.MeshBasicMaterial({color:c,transparent:true,opacity:o,blending:T.AdditiveBlending,depthWrite:false});
    const gl=part(obj,'hand_r',g.core,gm,[r,1,r],[hx,hy,.6],[Math.PI/2,0,0]);gl.castShadow=false;gl.userData.o=o;glows.push(gl)}
   bl.castShadow=false;bl.userData.blade=1;break}
  // Guns: barrel runs along the fingers (-x in T-pose), grip under the palm.
  case 'rifle':gun(obj,g,mw,ma,.6,.07,.1);break;
  case 'longrifle':gun(obj,g,mw,ma,.85,.06,.06);part(obj,'hand_r',g.cyl,mw,[.025,.16,.025],[-.88,1.39,0],[0,0,Math.PI/2]);break;
  case 'cannon':gun(obj,g,mw,ma,.58,.13,.2);break;
  case 'pistol':gun(obj,g,mw,ma,.26,.05,0);break}
 for(const m of mats)m.userData.e0=m.emissive.clone();
 return finish(obj,M,kind,mats,glows,(meshy?(beastK?1.55:1.15)/(M.h||1.7):1.15/1.83*bulk)*(kind==='malgus'?1.08:1))}

function gun(obj,g,mw,ma,len,th,stock){const hx=-.76,hy=1.36;part(obj,'hand_r',g.box,mw,[len,th*1.3,th],[hx-len/2+.12,hy,0]);
 part(obj,'hand_r',g.box,mw,[.05,.1,th*.9],[hx+.02,hy-.07,0]);if(stock)part(obj,'hand_r',g.box,ma,[stock,th*1.1,th*.8],[hx+.12+stock/2,hy-.02,0]);}
function finish(obj,M,kind,mats,glows,scale){obj.scale.setScalar(scale);const mixer=new T.AnimationMixer(obj),acts={},map=CLIPS[fileOf(kind)];
 const byName=Object.fromEntries(M.clips.map(c=>[c.name,c]));
 for(const k of ['idle','walk','run','aim','shoot','gunIdle','saberIdle','swing','swing2','claw','cast','channel','hit','knock','death','death2','crouch','jumpStart','jumpLoop','jumpLand','interact','kneel','cheer','look','toLay','getUp','lifted','throw','block']){
  const c=byName[map?map[k]:k];if(c)acts[k]=mixer.clipAction(c)}
 return {obj,mixer,acts,glows,mats}}

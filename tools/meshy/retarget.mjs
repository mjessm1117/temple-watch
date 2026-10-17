// Deps (not in package.json; run from a scratch folder): npm i @gltf-transform/core @gltf-transform/extensions @gltf-transform/functions meshoptimizer sharp three
// Example: node tools/meshy/retarget.mjs public/models/human.glb ~/Downloads/meshy_rigged.glb public/models/units/trooper.glb
// Bake the game's Quaternius clips (UE4 skeleton) onto a Meshy/Mixamo-rigged character.
// World-space delta retarget: q_tgt_world(t) = q_src_world(t) * inv(q_src_rest_world) * q_tgt_rest_world.
// Hips translation follows the source pelvis, scaled by hip height. Bones are renamed to the UE names the game attaches gear to.
// usage: node retarget.mjs src.glb tgt.glb out.glb
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import {MeshoptDecoder} from 'meshoptimizer';
import * as T from 'three';
await MeshoptDecoder.ready;
const {MeshoptEncoder}=await import('meshoptimizer');await MeshoptEncoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder,'meshopt.encoder':MeshoptEncoder});
const [srcP,tgtP,outP]=process.argv.slice(2);
const S=await io.read(srcP),D=await io.read(tgtP);
const M='mixamorig:';
const MAP={pelvis:'Hips',spine_01:'Spine',spine_02:'Spine1',spine_03:'Spine2',neck_01:'Neck',Head:'Head'};
for(const [s,u,m] of [['l','l','Left'],['r','r','Right']]){Object.assign(MAP,{[`clavicle_${s}`]:m+'Shoulder',[`upperarm_${s}`]:m+'Arm',[`lowerarm_${s}`]:m+'ForeArm',[`hand_${s}`]:m+'Hand',
 [`thigh_${s}`]:m+'UpLeg',[`calf_${s}`]:m+'Leg',[`foot_${s}`]:m+'Foot',[`ball_${s}`]:m+'ToeBase'});
}
// Fingers stay in the model's own rest pose (retargeted UAL fingers read as claws on Meshy hands).
const FINGERS={};for(const [s,m] of [['l','Left'],['r','Right']])for(const f of ['thumb','index','middle','ring','pinky'])for(const i of [1,2,3])FINGERS[`${f}_0${i}_${s}`]=`${m}Hand${f[0].toUpperCase()+f.slice(1)}${i}`;

function graph(doc){const r=doc.getRoot(),par=new Map(),by={};for(const n of r.listNodes()){by[n.getName()]=n;for(const c of n.listChildren())par.set(c,n)}return {r,par,by}}
const gs=graph(S),gt=graph(D);
const loc=(t,r,s)=>new T.Matrix4().compose(new T.Vector3(...t),new T.Quaternion(...r),new T.Vector3(...s));
function worldOf(g,n,localFn,cache){if(cache.has(n))return cache.get(n);const L=localFn(n),p=g.par.get(n);const w=p?worldOf(g,p,localFn,cache).clone().multiply(L):L;cache.set(n,w);return w}
const restLocal=n=>loc(n.getTranslation(),n.getRotation(),n.getScale());
const qOf=m=>{const q=new T.Quaternion();m.decompose(new T.Vector3(),q,new T.Vector3());return q};
const pOf=m=>new T.Vector3().setFromMatrixPosition(m);
const sRest=new Map(),tRest=new Map();
const sRW=n=>worldOf(gs,n,restLocal,sRest),tRW=n=>worldOf(gt,n,restLocal,tRest);

// sample a sampler at time t (LINEAR/STEP; slerp for rotations)
const deq=a=>{const o=a.getArray();if(!a.getNormalized())return o;const m={5120:127,5121:255,5122:32767,5123:65535}[a.getComponentType()];return Float32Array.from(o,v=>Math.max(v/m,-1))};
const DQ=new Map(),arr=a=>DQ.get(a)||(DQ.set(a,deq(a)),DQ.get(a));
function sample(sm,t,path){const I=arr(sm.getInput()),O=arr(sm.getOutput()),k=path==='rotation'?4:3;
 let i=0;while(i<I.length-1&&I[i+1]<=t)i++;const j=Math.min(i+1,I.length-1),a=I[i],b=I[j],f=b>a?Math.min(1,Math.max(0,(t-a)/(b-a))):0;
 const A=Array.from(O.slice(i*k,i*k+k)),B=Array.from(O.slice(j*k,j*k+k));
 if(sm.getInterpolation()==='STEP'||f===0)return A;
 if(k===4)return new T.Quaternion(...A).slerp(new T.Quaternion(...B),f).toArray();return A.map((v,x)=>v+(B[x]-v)*f)}

// Rest alignment: each bone gets a frame (bone direction + character forward/left) in both rest poses;
// align = Fsrc * inv(Ftgt) so A-pose vs T-pose and facing differences cancel.
const CHILD={pelvis:'spine_01',spine_01:'spine_02',spine_02:'spine_03',spine_03:'neck_01',neck_01:'Head'};
for(const s of ['l','r']){Object.assign(CHILD,{[`clavicle_${s}`]:`upperarm_${s}`,[`upperarm_${s}`]:`lowerarm_${s}`,[`lowerarm_${s}`]:`hand_${s}`,[`hand_${s}`]:`middle_01_${s}`,
 [`thigh_${s}`]:`calf_${s}`,[`calf_${s}`]:`foot_${s}`,[`foot_${s}`]:`ball_${s}`});for(const f of ['thumb','index','middle','ring','pinky'])for(const i of [1,2])CHILD[`${f}_0${i}_${s}`]=`${f}_0${i+1}_${s}`}
const PARENTOF=Object.fromEntries(Object.entries(CHILD).map(([a,b])=>[b,a]));
function frames(nodeOf,RW){const _n=nodeOf;const P=n=>pOf(RW(nodeOf(n))),left=P('thigh_l').sub(P('thigh_r')).normalize(),up=P('Head').sub(P('pelvis')).normalize(),fwd=new T.Vector3().crossVectors(left,up).normalize();
 const F={};const make=(d)=>{const sec=Math.abs(d.dot(fwd))>.85?left:fwd,z=new T.Vector3().crossVectors(d,sec).normalize(),y=new T.Vector3().crossVectors(z,d);return new T.Quaternion().setFromRotationMatrix(new T.Matrix4().makeBasis(d,y,z))};
 for(const b of Object.keys(MAP)){if(!nodeOf(b))continue;let a=b,c=CHILD[a];while(!c&&PARENTOF[a]){a=PARENTOF[a];c=CHILD[a]}
  if(!c||!nodeOf(c)||!nodeOf(a))continue;F[b]=make(P(c).sub(P(a)).normalize())}return F}
const FS=frames(n=>gs.by[n],sRW),FT=frames(n=>gt.by[M+(MAP[n]||FINGERS[n])],tRW);
const ALIGN={};for(const b of Object.keys(FS))if(FT[b])ALIGN[b]=FS[b].clone().multiply(FT[b].clone().invert());
const tgtBones=Object.values(MAP).map(n=>gt.by[M+n]).filter(Boolean);
const hipsT=gt.by[M+'Hips'],pelS=gs.by.pelvis;
const hScale=pOf(tRW(hipsT)).y/pOf(sRW(pelS)).y;
// target bones in parent-before-child order
const order=gt.r.listSkins()[0].listJoints();
const inv=Object.fromEntries(Object.entries(MAP).map(([s,t])=>[M+t,s]));

for(const a of D.getRoot().listAnimations())a.dispose();
for(const clip of S.getRoot().listAnimations()){
 const ch={};for(const c of clip.listChannels()){const n=c.getTargetNode().getName();(ch[n]=ch[n]||{})[c.getTargetPath()]=c.getSampler()}
 let tMax=0;for(const s of clip.listSamplers()){const I=arr(s.getInput());tMax=Math.max(tMax,I[I.length-1])}
 const fps=30,N=Math.max(2,Math.round(tMax*fps)+1),times=new Float32Array(N);for(let i=0;i<N;i++)times[i]=Math.min(tMax,i/fps);
 const rot={},hipPos=new Float32Array(N*3);for(const b of order)if(inv[b.getName()])rot[b.getName()]=new Float32Array(N*4);
 for(let f=0;f<N;f++){const t=times[f];
  const sl=n=>{const c=ch[n.getName()]||{};return loc(c.translation?sample(c.translation,t,'translation'):n.getTranslation(),c.rotation?sample(c.rotation,t,'rotation'):n.getRotation(),c.scale?sample(c.scale,t,'scale'):n.getScale())};
  const sc=new Map(),sW=n=>worldOf(gs,n,sl,sc);
  const tc=new Map(),tLocal=new Map();
  const tl=n=>tLocal.get(n)||restLocal(n),tW=n=>worldOf(gt,n,tl,tc);
  for(const b of order){const sn=inv[b.getName()];if(!sn)continue;const s=gs.by[sn];if(!s)continue;
   const qw=qOf(sW(s)).multiply(qOf(sRW(s)).invert()).multiply(ALIGN[sn]||new T.Quaternion()).multiply(qOf(tRW(b)));
   const p=gt.par.get(b),pq=p?qOf(tW(p)):new T.Quaternion();const ql=pq.clone().invert().multiply(qw).normalize();
   let tr=new T.Vector3(...b.getTranslation());
   if(b===hipsT){const d=pOf(sW(s)).sub(pOf(sRW(s))).multiplyScalar(hScale),wp=pOf(tRW(b)).add(d);
    tr=p?wp.applyMatrix4(tW(p).clone().invert()):wp;hipPos.set(tr.toArray(),f*3)}
   tLocal.set(b,new T.Matrix4().compose(tr,ql,new T.Vector3(...b.getScale())));tc.clear();
   rot[b.getName()].set(ql.toArray(),f*4)}}
 const A=D.createAnimation(clip.getName()),buf=D.getRoot().listBuffers()[0];
 const inp=D.createAccessor().setArray(times).setType('SCALAR').setBuffer(buf);
 for(const [n,arr] of Object.entries(rot)){const sm=D.createAnimationSampler().setInput(inp).setOutput(D.createAccessor().setArray(arr).setType('VEC4').setBuffer(buf)).setInterpolation('LINEAR');
  A.addSampler(sm).addChannel(D.createAnimationChannel().setTargetNode(gt.by[n]).setTargetPath('rotation').setSampler(sm))}
 const sm=D.createAnimationSampler().setInput(inp).setOutput(D.createAccessor().setArray(hipPos).setType('VEC3').setBuffer(buf)).setInterpolation('LINEAR');
 A.addSampler(sm).addChannel(D.createAnimationChannel().setTargetNode(hipsT).setTargetPath('translation').setSampler(sm))}
// grip_r: child of the right hand whose frame matches the source hand's rest frame, so code-built weapons sit the same way.
{const h=gt.by[M+'RightHand'],sh=gs.by.hand_r;const X=qOf(sRW(sh)).invert().multiply(ALIGN.hand_r).multiply(qOf(tRW(h)));
 const g=D.createNode('grip_r').setRotation(X.invert().toArray());h.addChild(g)}
// rename bones to the UE names figures.js attaches gear to
for(const [s,t] of Object.entries(MAP)){const n=gt.by[M+t];if(n)n.setName(s)}
for(const n of gt.r.listNodes())if(n.getName().startsWith(M))n.setName(n.getName().slice(M.length));
// pack: base color only, 1024px webp, quantized + meshopt
const {prune,dedup,textureCompress,quantize,meshopt,resample}=await import('@gltf-transform/functions');const sharp=(await import('sharp')).default;
for(const m of D.getRoot().listMaterials()){for(const k of ['setNormalTexture','setMetallicRoughnessTexture','setOcclusionTexture','setEmissiveTexture'])m[k](null);m.setMetallicFactor(0).setRoughnessFactor(.85)}
// Characters Meshy couldn't remesh (<300K faces) get simplified here to ~12K tris; skin weights survive (simplify only drops vertices).
{let t=0;for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives())t+=(p.getIndices()?.getCount()||0)/3;
 if(t>20000){const {simplify,weld}=await import('@gltf-transform/functions');const {MeshoptSimplifier}=await import('meshoptimizer');await MeshoptSimplifier.ready;
  await D.transform(weld(),simplify({simplifier:MeshoptSimplifier,ratio:12000/t,error:.01}));console.log('simplified',Math.round(t),'tris')}}
await D.transform(prune({keepLeaves:true}),dedup(),resample(),textureCompress({encoder:sharp,targetFormat:'webp',resize:[1024,1024],quality:82}),quantize(),meshopt({encoder:(await import('meshoptimizer')).MeshoptEncoder,level:'medium'}));
await io.write(outP,D);console.log('wrote',outP,D.getRoot().listAnimations().length,'clips');

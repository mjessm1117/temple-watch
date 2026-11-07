// Stage the existing Scout model, with a phone LOD. No Meshy calls or new design.
import fs from 'node:fs';
import {createRequire} from 'node:module';
const R=createRequire('/home/jess/projects/tw-logs/w19/art/deps/package.json');
const {NodeIO,PropertyType}=R('@gltf-transform/core');
const {ALL_EXTENSIONS,EXTTextureWebP}=R('@gltf-transform/extensions');
const {prune,dedup,unpartition,simplify}=R('@gltf-transform/functions');
const {MeshoptDecoder,MeshoptSimplifier}=R('meshoptimizer');
const sharp=R('sharp');
await MeshoptDecoder.ready;await MeshoptSimplifier.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
const soldierClips=new Set(['idle','gunIdle','run','shoot','hit','death','aim','walk']);
function removeBindPoseTracks(doc){
 for(const a of doc.getRoot().listAnimations())for(const c of [...a.listChannels()]){
  const n=c.getTargetNode(),p=c.getTargetPath(),rest=p==='translation'?n.getTranslation():p==='rotation'?n.getRotation():p==='scale'?n.getScale():null;
  if(!rest)continue;
  const s=c.getSampler(),v=s.getOutput().getArray();
  if(v.every((x,i)=>Math.abs(x-rest[i%rest.length])<1e-6)){
   a.removeChannel(c);if(!a.listChannels().some(x=>x.getSampler()===s))a.removeSampler(s);
  }
 }
}
for(const lod of [false,true]){
 const d=await io.read('godot/assets/models/units/scout.glb');
 for(const a of d.getRoot().listAnimations())if(!soldierClips.has(a.getName()))a.dispose();
 removeBindPoseTracks(d);
 if(lod){
  await d.transform(simplify({simplifier:MeshoptSimplifier,ratio:.40,error:.025}));
  for(const t of d.getRoot().listTextures()){
   t.setImage(await sharp(t.getImage()).resize(512,512).webp({quality:80}).toBuffer()).setMimeType('image/webp');
  }
  d.createExtension(EXTTextureWebP).setRequired(true);
 }
 await d.transform(prune(),dedup({propertyTypes:[PropertyType.ACCESSOR]}),unpartition());
 const name=`godot/assets/units/w19/scout${lod?'_lod1':''}.glb`;
 await io.write(name,d);
 const tris=d.getRoot().listMeshes().flatMap(m=>m.listPrimitives()).reduce((n,p)=>n+(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3,0);
 console.log(name,tris,fs.statSync(name).size,d.getRoot().listAnimations().length);
}

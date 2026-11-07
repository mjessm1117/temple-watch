// Preserve the compact W17 rig/animation buffers while adding W19 Blender meshes.
import fs from 'node:fs';
import {createRequire} from 'node:module';
const R=createRequire('/home/jess/projects/tw-logs/w19/art/deps/package.json');
const {NodeIO,PropertyType}=R('@gltf-transform/core');
const {ALL_EXTENSIONS}=R('@gltf-transform/extensions');
const {copyToDocument,createDefaultPropertyResolver,prune,dedup,unpartition}=R('@gltf-transform/functions');
const {MeshoptDecoder}=R('meshoptimizer');
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
const root='godot/assets/units',log='/home/jess/projects/tw-logs/w19/art';
const soldierClips=new Set(['idle','gunIdle','run','shoot','hit','death','aim','walk']);
for(const kind of process.argv.slice(2))for(const suffix of ['', '_lod1']){
 const source=kind==='medic'?'officer':kind;
 const old=await io.read(`${root}/w17/${source}${suffix}.glb`);
 for(const a of old.getRoot().listAnimations())if(!soldierClips.has(a.getName()))a.dispose();
 const fresh=await io.read(`${root}/w19/${kind}${suffix}.glb`);
 const original=old.getRoot().listNodes().find(n=>n.getName()==='output_unwrapped');
 const prim=original.getMesh().listPrimitives()[0];
 const pos=prim.getAttribute('POSITION'),indices=prim.getIndices();
 const input=indices.getArray(),kept=[],v=[];
 for(let i=0;i<input.length;i+=3){
   const y=[0,1,2].map(k=>{pos.getElement(input[i+k],v);return v[1]});
   if(y.reduce((a,b)=>a+b,0)/3<=1.425)kept.push(input[i],input[i+1],input[i+2]);
 }
 indices.setArray(new input.constructor(kept));
 const joints=new Map(old.getRoot().listSkins()[0].listJoints().map(n=>[n.getName(),n]));
 const resolver=createDefaultPropertyResolver(old,fresh);
 let added=0;
 for(const src of fresh.getRoot().listNodes()){
   if(!src.getMesh()||src.getName()==='output_unwrapped')continue;
   const parent=src.listParents().find(p=>joints.has(p.getName()));
   if(!parent)continue;
   const mesh=copyToDocument(old,fresh,[src.getMesh()],resolver).get(src.getMesh());
   const n=old.createNode(src.getName()).setMesh(mesh).setTranslation(src.getTranslation()).setRotation(src.getRotation()).setScale(src.getScale());
   joints.get(parent.getName()).addChild(n);added++;
 }
 await old.transform(prune(),dedup({propertyTypes:[PropertyType.ACCESSOR]}),unpartition());
 const dest=`${root}/w19/${kind}${suffix}.glb`;
 fs.copyFileSync(dest,`${log}/${kind}${suffix}-blender.glb`);
 await io.write(dest,old);
 const count=old.getRoot().listMeshes().flatMap(m=>m.listPrimitives()).reduce((n,p)=>n+(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3,0);
 console.log(kind+suffix,'new parts',added,'triangles',count,'bytes',fs.statSync(dest).size,'clips',old.getRoot().listAnimations().length);
}

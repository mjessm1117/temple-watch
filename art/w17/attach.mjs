import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
import {Matrix4} from 'three';
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const name of ['sniper','heavy','sniper_lod1','heavy_lod1']){
 const path=`godot/assets/units/w17/${name}.glb`,doc=await io.read(path),nodes=doc.getRoot().listNodes();
 const by=Object.fromEntries(nodes.map(n=>[n.getName(),n]));let attached=0;
 for(const node of nodes){
  const boneName=node.getName().includes('__hand_r')?'spine_03':node.getName().includes('__spine_03')?'spine_03':node.getName().includes('__pelvis')?'pelvis':null;
  if(!boneName)continue;
  const bone=by[boneName],world=new Matrix4().fromArray(node.getWorldMatrix());
  const inv=new Matrix4().fromArray(bone.getWorldMatrix()).invert();
  bone.addChild(node);
  node.setMatrix(inv.multiply(world).toArray());
  attached++;
 }
 const temp=path+'.tmp.glb';await io.write(temp,doc);fs.renameSync(temp,path);
 console.log(name,'attached',attached,'gear nodes');
}

import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import {MeshoptDecoder} from 'meshoptimizer';import {Matrix4} from 'three';
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const name of ['sniper','sniper_lod1']){
 const path=`godot/assets/units/w17/${name}.glb`,doc=await io.read(path);
 for(const n of doc.getRoot().listNodes())if(n.getName().includes('__hand_r')){
  const p=n.getParentNode(),w=new Matrix4().fromArray(n.getWorldMatrix());
  w.elements[12]+=.32;
  n.setMatrix(new Matrix4().fromArray(p.getWorldMatrix()).invert().multiply(w).toArray());
 }
 await io.write(path+'.tmp.glb',doc);fs.renameSync(path+'.tmp.glb',path);console.log(name,'rifle moved toward torso');
}

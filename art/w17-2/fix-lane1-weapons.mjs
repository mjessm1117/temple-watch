import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
import {Matrix4, Vector3} from 'three';
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const kind of ['sniper','heavy'])for(const suffix of ['', '_lod1']){
 const path=`godot/assets/units/w17/${kind}${suffix}.glb`,doc=await io.read(path);
 const nodes=doc.getRoot().listNodes(),by=Object.fromEntries(nodes.map(n=>[n.getName(),n]));
 const hand=by.hand_r,gun=nodes.filter(n=>n.getName().endsWith('__hand_r'));
 const receiver=gun.find(n=>n.getName().includes(kind==='heavy'?'repeater body':'precision blaster receiver'));
 if(!hand||!receiver||!gun.length)throw Error('Missing hand or weapon in '+path);
 const at=n=>new Vector3().setFromMatrixPosition(new Matrix4().fromArray(n.getWorldMatrix()));
 const grip=at(hand).add(new Vector3(kind==='heavy'?.02:0,-.035,.025));
 const old=at(receiver),delta=grip.clone().sub(old),factor=kind==='heavy'?.7:1;
 const pivot=old.clone();
 for(const n of gun){const w=new Matrix4().fromArray(n.getWorldMatrix());
  const p=new Vector3().setFromMatrixPosition(w).sub(pivot).multiplyScalar(factor).add(pivot).add(delta);
  w.setPosition(p);if(factor!==1)w.scale(new Vector3(factor,factor,factor));
  hand.addChild(n);
  const local=new Matrix4().fromArray(hand.getWorldMatrix()).invert().multiply(w);
  n.setMatrix(local.toArray());
 }
 const temp=path+'.tmp.glb';await io.write(temp,doc);fs.renameSync(temp,path);
 console.log(kind+suffix,'right-hand gear',gun.length,'scale',factor,'grip',grip.toArray());
}

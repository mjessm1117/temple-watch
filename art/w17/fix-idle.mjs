import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import {MeshoptDecoder} from 'meshoptimizer';
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const name of ['sniper','heavy','sniper_lod1','heavy_lod1']){
 const path=`godot/assets/units/w17/${name}.glb`,doc=await io.read(path),root=doc.getRoot();
 const idle=root.listAnimations().find(a=>a.getName()==='idle');if(!idle)throw Error(name+' missing idle');
 let count=0;
 for(const channel of idle.listChannels()){
  const target=channel.getTargetNode(),prop=channel.getTargetPath();
  if(prop!=='rotation'&&prop!=='translation'&&prop!=='scale')continue;
  const v=prop==='rotation'?target.getRotation():prop==='translation'?target.getTranslation():target.getScale();
  const accessor=channel.getSampler().getOutput(),array=accessor.getArray();
  for(let i=0;i<array.length;i++)array[i]=v[i%v.length];
  accessor.setArray(array);count++;
 }
 await io.write(path+'.tmp.glb',doc);fs.renameSync(path+'.tmp.glb',path);
 console.log(name,'neutral idle channels',count,'clips',root.listAnimations().length);
}

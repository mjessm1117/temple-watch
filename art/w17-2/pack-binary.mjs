import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import {MeshoptDecoder} from 'meshoptimizer';
await MeshoptDecoder.ready;const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const name of ['sniper','sniper_lod1','heavy','heavy_lod1','tech','tech_lod1','droid','droid_lod1','officer','officer_lod1']){
 const path=`godot/assets/units/w17/${name}.glb`,doc=await io.read(path),tmp=path+'.tmp.glb';
 await io.write(tmp,doc);fs.renameSync(tmp,path);
 if(fs.readFileSync(path).subarray(0,4).toString()!=='glTF')throw Error('not GLB '+name);
 console.log(name,fs.statSync(path).size);
}

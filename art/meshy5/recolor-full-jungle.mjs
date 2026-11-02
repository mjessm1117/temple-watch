import {NodeIO} from '@gltf-transform/core';
const io=new NodeIO();
for(const lod of ['', '_lod1']){
 const source=`godot/assets/maps/meshy3/cover_full_jungle_v1${lod}.glb`;
 const target=`godot/assets/maps/meshy5/cover_full_jungle_v1${lod}.glb`;
 const document=await io.read(source);
 for(const material of document.getRoot().listMaterials()){
  if(material.getName().includes('moss'))material.setBaseColorFactor([0.025,0.105,0.035,1]);
  else material.setBaseColorFactor([0.135,0.077,0.045,1]);
  material.setRoughnessFactor(1);
 }
 await io.write(target,document);
 console.log(`${source} -> ${target}`);
}

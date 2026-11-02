import {NodeIO} from '@gltf-transform/core';
const io=new NodeIO();
for(const lod of ['', '_lod1']){
 const path=`godot/assets/maps/meshy5/cover_full_jungle_v3${lod}.glb`;
 const d=await io.read(path),buffer=d.getRoot().listBuffers()[0];
 const material=d.getRoot().listMaterials()[0]||d.createMaterial('bark and moss');
 material.setName('deep brown bark and forest moss').setBaseColorFactor([1,1,1,1]).setMetallicFactor(0).setRoughnessFactor(1);
 for(const mesh of d.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
  p.setMaterial(material);
  const pos=p.getAttribute('POSITION').getArray(),normal=p.getAttribute('NORMAL')?.getArray();
  const colors=new Float32Array(pos.length/3*4);
  for(let i=0;i<pos.length;i+=3){
   const x=pos[i],y=pos[i+1],z=pos[i+2],n=normal?normal[i+1]:0;
   const grain=.82+.18*Math.sin(x*27+z*19+y*8)*Math.sin(x*13-z*17+y*23);
   const moss=Math.max(0,Math.min(1,(.33-y)*1.8+.30*Math.sin(x*19+z*11+y*7)+.12*(1-n)));
   const bark=[.16,.085,.046],green=[.036,.15,.042];
   for(let c=0;c<3;c++)colors[i/3*4+c]=(bark[c]*(1-moss)+green[c]*moss)*grain;
   colors[i/3*4+3]=1;
  }
  p.setAttribute('COLOR_0',d.createAccessor().setType('VEC4').setArray(colors).setBuffer(buffer));
 }
 await io.write(path,d);console.log(path);
}

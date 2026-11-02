import {NodeIO,getBounds} from '@gltf-transform/core';
const io=new NodeIO();
for(const [input,output] of [['art/meshy5/cover_full_jungle.A.preview.glb','art/meshy5/cover_full_jungle.A.fit.glb']]){
 const d=await io.read(input),b=getBounds(d.getRoot().getDefaultScene());
 const s=.98/Math.max(b.max[0]-b.min[0],b.max[2]-b.min[2]);
 for(const mesh of d.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
  const a=p.getAttribute('POSITION').getArray();
  for(let i=0;i<a.length;i+=3){a[i]=(a[i]-(b.min[0]+b.max[0])/2)*s;a[i+1]=(a[i+1]-b.min[1])*s;a[i+2]=(a[i+2]-(b.min[2]+b.max[2])/2)*s;}
 }
 await io.write(output,d);console.log(output,s);
}

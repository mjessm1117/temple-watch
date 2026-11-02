import {NodeIO} from '@gltf-transform/core';
const io=new NodeIO();
for(const lod of ['', '_lod1']){
 const path=`godot/assets/maps/meshy5/cover_half_snow_v1${lod}.glb`,d=await io.read(path),buffer=d.getRoot().listBuffers()[0];
 const palettes=[['charcoal rock',[.052,.073,.088,1]],['blue ice',[.19,.27,.33,1]],['snow crust',[.62,.72,.78,1]]];
 const mats=palettes.map(([name,color])=>d.createMaterial(name).setBaseColorFactor(color).setMetallicFactor(0).setRoughnessFactor(1));
 for(const mesh of d.getRoot().listMeshes())for(const p of [...mesh.listPrimitives()]){
  const idx=p.getIndices()?.getArray();if(!idx)throw Error('missing indices');
  const n=p.getAttribute('NORMAL'),pos=p.getAttribute('POSITION');
  const groups=[[],[],[]];
  for(let i=0;i<idx.length;i+=3){
   let y=0,ny=0;for(let j=0;j<3;j++){y+=pos.getElement(idx[i+j],[])[1]/3;ny+=n.getElement(idx[i+j],[])[1]/3;}
   const group=ny>.43&&y>.3?2:ny>.18&&y>.54?1:0;
   groups[group].push(idx[i],idx[i+1],idx[i+2]);
  }
  for(let g=0;g<groups.length;g++)if(groups[g].length){
   const q=d.createPrimitive().setMaterial(mats[g]).setIndices(d.createAccessor().setType('SCALAR').setArray(new Uint32Array(groups[g])).setBuffer(buffer));
   for(const semantic of p.listSemantics())q.setAttribute(semantic,p.getAttribute(semantic));
   mesh.addPrimitive(q);
  }
  mesh.removePrimitive(p);
 }
 await io.write(path,d);console.log(path);
}

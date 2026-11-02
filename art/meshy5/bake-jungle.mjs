import {NodeIO} from '@gltf-transform/core';
import sharp from 'sharp';
const io=new NodeIO();
for(const lod of ['', '_lod1']){
 const path=`godot/assets/maps/meshy5/cover_full_jungle_v2${lod}.glb`;
 const d=await io.read(path);
 let polygons='';
 for(const mesh of d.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
  const uv=p.getAttribute('TEXCOORD_0'),colors=p.getAttribute('COLOR_0'),ids=p.getIndices()?.getArray();
  if(!uv||!colors||!ids)throw Error('Missing UV/color/indices');
  for(let i=0;i<ids.length;i+=3){
   const points=[],rgb=[0,0,0];
   for(let j=0;j<3;j++){
    const q=ids[i+j],t=uv.getElement(q,[]),c=colors.getElement(q,[]);
    points.push(`${(t[0]*512).toFixed(2)},${((1-t[1])*512).toFixed(2)}`);
    for(let k=0;k<3;k++)rgb[k]+=c[k]/3;
   }
   const hex=rgb.map(v=>Math.max(0,Math.min(255,Math.round(Math.pow(v,1/2.2)*255))).toString(16).padStart(2,'0')).join('');
   polygons+=`<polygon points="${points.join(' ')}" fill="#${hex}" stroke="#${hex}" stroke-width="1"/>`;
  }
  p.setAttribute('COLOR_0',null);
 }
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512"><rect width="512" height="512" fill="#5c392b"/>${polygons}</svg>`;
 const png=await sharp(Buffer.from(svg)).png().toBuffer();
 const tex=d.createTexture('jungle_bark_moss').setImage(png).setMimeType('image/png');
 for(const m of d.getRoot().listMaterials())m.setBaseColorTexture(tex).setBaseColorFactor([1,1,1,1]);
 await io.write(path,d);console.log(path,png.length);
}

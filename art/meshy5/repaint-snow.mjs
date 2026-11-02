import {NodeIO} from '@gltf-transform/core';
import sharp from 'sharp';
const io=new NodeIO();
for(const lod of ['', '_lod1']){
 const path=`godot/assets/maps/meshy5/cover_half_snow_v1${lod}.glb`;
 const d=await io.read(path);
 let polygons='';
 for(const mesh of d.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
  const uv=p.getAttribute('TEXCOORD_0'),pos=p.getAttribute('POSITION'),ids=p.getIndices()?.getArray();
  if(!uv||!pos||!ids)throw Error('Missing UV/position/indices');
  for(let i=0;i<ids.length;i+=3){
   const vertices=[],points=[];
   for(let j=0;j<3;j++){
    const q=ids[i+j],t=uv.getElement(q,[]);vertices.push(pos.getElement(q,[]));
    points.push(`${(t[0]*512).toFixed(2)},${((1-t[1])*512).toFixed(2)}`);
   }
   const [a,b,c]=vertices,u=b.map((v,k)=>v-a[k]),v=c.map((v,k)=>v-a[k]);
   const ny=(u[2]*v[0]-u[0]*v[2])/(Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])||1);
   const y=(a[1]+b[1]+c[1])/3;
   const jitter=.88+.12*Math.sin(a[0]*37+b[2]*21+c[1]*43);
   let color;
   if(ny>.42&&y>.30)color=[.72,.80,.86];
   else if(ny>.20&&y>.57)color=[.45,.57,.64];
   else if(ny>.53&&y<.22)color=[.14,.20,.24];
   else color=[.045,.065,.084];
   const hex=color.map(v=>Math.max(0,Math.min(255,Math.round(Math.pow(v*jitter,1/2.2)*255))).toString(16).padStart(2,'0')).join('');
   polygons+=`<polygon points="${points.join(' ')}" fill="#${hex}" stroke="#${hex}" stroke-width="1"/>`;
  }
 }
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512"><rect width="512" height="512" fill="#465461"/>${polygons}</svg>`;
 const png=await sharp(Buffer.from(svg)).png().toBuffer();
 const tex=d.createTexture('dark_rock_snow_crust').setImage(png).setMimeType('image/png');
 for(const m of d.getRoot().listMaterials())m.setBaseColorTexture(tex).setBaseColorFactor([1,1,1,1]);
 await io.write(path,d);console.log(path,png.length);
}

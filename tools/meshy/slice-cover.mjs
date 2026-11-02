// Local, attribute-preserving horizontal slice or vertical side trim. Caps follow cut-edge loops.
// node tools/meshy/slice-cover.mjs source.glb output.glb cutY
// node tools/meshy/slice-cover.mjs source.glb output.glb --sides minX maxX [height=.8]
// Side planes are in uniformly height-scaled coordinates, before centering.
import fs from 'node:fs';
import {NodeIO} from '@gltf-transform/core';
import {weld,prune} from '@gltf-transform/functions';
const [source,target,yArg,left,right,height=".8"]=process.argv.slice(2);
const sides=yArg==='--sides';
const io=new NodeIO(),d=await io.read(source),buffer=d.getRoot().listBuffers()[0];
let initialScale=1;
if(sides){
 let minY=Infinity,maxY=-Infinity;
 for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives()){
  const a=p.getAttribute('POSITION').getArray();
  for(let i=1;i<a.length;i+=3){minY=Math.min(minY,a[i]);maxY=Math.max(maxY,a[i]);}
 }
 initialScale=+height/(maxY-minY);
 for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives()){
  const a=p.getAttribute('POSITION').getArray();for(let i=0;i<a.length;i++)a[i]*=initialScale;
 }
}
const planes=sides?[{axis:0,value:+left,sign:-1},{axis:0,value:+right,sign:1}]:[{axis:1,value:+yArg,sign:1}];
if(sides&&!(+left<+right&&+right-+left<=1))throw Error('Side trim must fit one tile');
let caps=0;
for(const mesh of d.getRoot().listMeshes())for(const p of mesh.listPrimitives()){
 const semantics=p.listSemantics().filter(s=>s!=='TANGENT');
 let faces=[];
 const idx=p.getIndices()?.getArray()||Array.from({length:p.getAttribute('POSITION').getCount()},(_,i)=>i);
 for(let i=0;i<idx.length;i+=3)faces.push(Array.from(idx.slice(i,i+3),id=>Object.fromEntries(semantics.map(s=>[s,p.getAttribute(s).getElement(id,[])]))));
 for(const {axis,value,sign} of planes){
  const clipped=[],edges=[];
  const inside=v=>(v.POSITION[axis]-value)*sign<=0;
  const mix=(a,b,t)=>Object.fromEntries(semantics.map(s=>[s,a[s].map((x,j)=>x+(b[s][j]-x)*t)]));
  for(const face of faces){
   const polygon=[],crossings=[];
   for(let i=0;i<3;i++){
    const a=face[i],b=face[(i+1)%3];
    if(inside(a))polygon.push(a);
    if(inside(a)!==inside(b)){
     const v=mix(a,b,(value-a.POSITION[axis])/(b.POSITION[axis]-a.POSITION[axis]));
     polygon.push(v);crossings.push(v);
    }
   }
   for(let i=1;i+1<polygon.length;i++)clipped.push([polygon[0],polygon[i],polygon[i+1]]);
   if(crossings.length===2)edges.push(crossings);
  }
  // Stitch the actual boundary, including UV seam duplicates, into closed rings.
  const key=v=>v.POSITION.map(x=>Math.round(x*1e6)).join(',');
  const adjacency=new Map();
  edges.forEach((e,i)=>e.forEach(v=>{const k=key(v);if(!adjacency.has(k))adjacency.set(k,[]);adjacency.get(k).push(i);}));
  const used=new Set();
  for(let seed=0;seed<edges.length;seed++){
   if(used.has(seed))continue;
   used.add(seed);const ring=[...edges[seed]];
   while(key(ring.at(-1))!==key(ring[0])){
    const next=(adjacency.get(key(ring.at(-1)))||[]).find(i=>!used.has(i));
    if(next===undefined)throw Error('Open slice boundary; refusing an unsealed export');
    used.add(next);const e=edges[next];ring.push(key(e[0])===key(ring.at(-1))?e[1]:e[0]);
   }
   ring.pop();if(ring.length<3)continue;
   // Ear clipping handles concave stone outlines without spanning empty space.
   const axes=[0,1,2].filter(a=>a!==axis);
   const cross=(a,b,c)=>(b.POSITION[axes[0]]-a.POSITION[axes[0]])*(c.POSITION[axes[1]]-a.POSITION[axes[1]])-(b.POSITION[axes[1]]-a.POSITION[axes[1]])*(c.POSITION[axes[0]]-a.POSITION[axes[0]]);
   let area=0;for(let i=0;i<ring.length;i++){const a=ring[i].POSITION,b=ring[(i+1)%ring.length].POSITION;area+=a[axes[0]]*b[axes[1]]-b[axes[0]]*a[axes[1]];}
   if(area<0)ring.reverse();
   const normal=[0,0,0];normal[axis]=sign;
   const anchor=ring[0];
   const capVertex=v=>({...v,NORMAL:normal,TEXCOORD_0:anchor.TEXCOORD_0.map((u,j)=>u+(v.POSITION[axes[j]]-anchor.POSITION[axes[j]])*0.015)});
   const emit=(a,b,c)=>{const tri=[a,b,c].map(capVertex);if((axis===1?-1:1)!==sign)tri.reverse();clipped.push(tri);caps++;};
   let guard=ring.length**2;
   while(ring.length>3&&guard-->0){
    let found=false;
    for(let i=0;i<ring.length;i++){
     const a=ring[(i+ring.length-1)%ring.length],b=ring[i],c=ring[(i+1)%ring.length];
     if(cross(a,b,c)<=1e-12)continue;
     if(ring.some(v=>v!==a&&v!==b&&v!==c&&cross(a,b,v)>1e-12&&cross(b,c,v)>1e-12&&cross(c,a,v)>1e-12))continue;
     emit(a,b,c);ring.splice(i,1);found=true;break;
    }
    if(!found){const i=ring.findIndex((v,j)=>Math.abs(cross(ring[(j+ring.length-1)%ring.length],v,ring[(j+1)%ring.length]))<1e-10);if(i<0)throw Error('Cannot triangulate cap');ring.splice(i,1);}
   }
   if(ring.length===3)emit(...ring);
  }
  faces=clipped;
 }
 // Recess the exposed cut surface in small facets, retaining the original course outline.
 // Move shared boundary vertices too, so the cap and wall cannot separate.
 if(sides)for(const face of faces){
  const cap=face.every(v=>Math.abs(v.NORMAL?.[0]||0)===1);
  for(const v of face)for(const plane of planes){
   if(Math.abs(v.POSITION[0]-plane.value)>1e-6)continue;
   const [,y,z]=v.POSITION;
   const chip=.012+.018*Math.abs(Math.sin(y*31+z*13))+.012*Math.abs(Math.sin(z*37-y*9));
   v.POSITION=[v.POSITION[0]-plane.sign*chip,y,z];
  }
  if(cap){
   const a=face[0].POSITION,b=face[1].POSITION,c=face[2].POSITION;
   const u=b.map((v,i)=>v-a[i]),v=c.map((v,i)=>v-a[i]);
   const n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];
   const length=Math.hypot(...n)||1;for(const vertex of face)vertex.NORMAL=n.map(x=>x/length);
  }
 }
 for(const s of semantics)p.setAttribute(s,d.createAccessor().setType(p.getAttribute(s).getType()).setArray(new Float32Array(faces.flatMap(f=>f.flatMap(v=>v[s])))).setBuffer(buffer));
 p.setAttribute('TANGENT',null).setIndices(null);
}
const lo=[Infinity,Infinity,Infinity],hi=lo.map(v=>-v);
for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives()){
 const a=p.getAttribute('POSITION').getArray();for(let i=0;i<a.length;i++){lo[i%3]=Math.min(lo[i%3],a[i]);hi[i%3]=Math.max(hi[i%3],a[i]);}
}
const size=hi.map((v,i)=>v-lo[i]),scale=sides?1:.98/Math.max(size[0],size[2]);
for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives()){
 const a=p.getAttribute('POSITION').getArray();for(let i=0;i<a.length;i++)a[i]=(a[i]-(i%3===1?lo[1]:(lo[i%3]+hi[i%3])/2))*scale;
}
await d.transform(weld(),prune());await io.write(target,d);
const report={source,planes,source_slice_bounds:{lo,hi},uniform_scale:initialScale*scale,dimensions:size.map(v=>v*scale),cap_triangles:caps};
fs.writeFileSync(target+'.json',JSON.stringify(report,null,2)+'\n');console.log(report);

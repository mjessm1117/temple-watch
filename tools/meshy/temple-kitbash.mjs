// Batch 1: salvage D's masonry; clip away its plinth and arch, add an original fallen column.
// Usage: node tools/meshy/temple-kitbash.mjs input.glb output.glb
import {NodeIO} from '@gltf-transform/core';
import sharp from 'sharp';
import {prune,weld} from '@gltf-transform/functions';
const io=new NodeIO(),d=await io.read(process.argv[2]),buffer=d.getRoot().listBuffers()[0];
const mesh=d.getRoot().listMeshes()[0],p=mesh.listPrimitives()[0];
const pos=p.getAttribute('POSITION'),lo=pos.getMin([]),hi=pos.getMax([]);
const bottom=lo[1]+(hi[1]-lo[1])*.14,top=lo[1]+(hi[1]-lo[1])*.58;
const attributes=p.listSemantics().filter(s=>s!=='TANGENT'),out=Object.fromEntries(attributes.map(s=>[s,[]]));
const indices=p.getIndices()?.getArray()||Array.from({length:pos.getCount()},(_,i)=>i);
const cut={bottom:[],top:[]};
function interpolate(a,b,t){return Object.fromEntries(attributes.map(s=>[s,a[s].map((v,i)=>v+(b[s][i]-v)*t)]));}
function clip(vertices,y,above,key){
 const result=[];
 for(let i=0;i<vertices.length;i++){
  const a=vertices[i],b=vertices[(i+1)%vertices.length],ain=above?a.POSITION[1]>=y:a.POSITION[1]<=y,bin=above?b.POSITION[1]>=y:b.POSITION[1]<=y;
  if(ain)result.push(a);
  if(ain!==bin){const v=interpolate(a,b,(y-a.POSITION[1])/(b.POSITION[1]-a.POSITION[1]));result.push(v);cut[key].push(v);}
 }
 return result;
}
function emit(a,b,c){for(const v of [a,b,c])for(const s of attributes)out[s].push(...v[s]);}
for(let i=0;i<indices.length;i+=3){
 let vertices=Array.from(indices.slice(i,i+3),index=>Object.fromEntries(attributes.map(s=>[s,p.getAttribute(s).getElement(index,[])])));
 vertices=clip(clip(vertices,bottom,true,'bottom'),top,false,'top');
 for(let j=1;j+1<vertices.length;j++)emit(vertices[0],vertices[j],vertices[j+1]);
}
// Convex caps per support block seal the local clipping planes.
function hull(points){
 points.sort((a,b)=>a.POSITION[0]-b.POSITION[0]||a.POSITION[2]-b.POSITION[2]);
 const cross=(a,b,c)=>(b.POSITION[0]-a.POSITION[0])*(c.POSITION[2]-a.POSITION[2])-(b.POSITION[2]-a.POSITION[2])*(c.POSITION[0]-a.POSITION[0]);
 const half=arr=>{const h=[];for(const v of arr){while(h.length>1&&cross(h.at(-2),h.at(-1),v)<=0)h.pop();h.push(v);}return h;};
 return [...half(points).slice(0,-1),...half([...points].reverse()).slice(0,-1)];
}
for(const key of ['bottom','top'])for(const sign of [-1,1]){
 const h=hull(cut[key].filter(v=>v.POSITION[0]*sign>=0));
 for(const v of h)if(v.NORMAL)v.NORMAL=[0,key==='top'?1:-1,0];
 for(let i=1;i+1<h.length;i++)key==='top'?emit(h[0],h[i+1],h[i]):emit(h[0],h[i],h[i+1]);
}
for(let i=0;i<out.POSITION.length;i+=3){out.POSITION[i]=(out.POSITION[i]-(lo[0]+hi[0])/2)*.98/(hi[0]-lo[0]);out.POSITION[i+1]=(out.POSITION[i+1]-bottom)*.43/(top-bottom);out.POSITION[i+2]=(out.POSITION[i+2]-(lo[2]+hi[2])/2)*.62/(hi[2]-lo[2]);}
for(const s of attributes)p.setAttribute(s,d.createAccessor().setType(p.getAttribute(s).getType()).setArray(new Float32Array(out[s])).setBuffer(buffer));
p.setAttribute('TANGENT',null).setIndices(null);
const positions=[],normals=[],uv=[],idx=[],segments=16;
const rings=[[-.48,.20],[-.46,.245],[-.40,.245],[-.38,.215],[-.34,.215],[.34,.215],[.38,.215],[.40,.245],[.46,.245],[.48,.20]];
for(const [x,r] of rings)for(let j=0;j<=segments;j++){
 const a=j/segments*Math.PI*2,flute=j%2?.94:1;
 positions.push(x,.555+Math.cos(a)*r*flute,Math.sin(a)*r*flute);normals.push(0,Math.cos(a),Math.sin(a));uv.push((x+.48)/.96,j/segments);
}
for(let i=0;i<rings.length-1;i++)for(let j=0;j<segments;j++){const a=i*(segments+1)+j,b=a+segments+1;idx.push(a,a+1,b,b,a+1,b+1);}
for(const end of [0,rings.length-1]){
 const center=positions.length/3;positions.push(rings[end][0],.555,0);normals.push(end?1:-1,0,0);uv.push(.5,.5);
 for(let j=0;j<segments;j++){const a=end*(segments+1)+j;idx.push(center,...(end?[a,a+1]:[a+1,a]));}
}
const accessor=(type,array)=>d.createAccessor().setType(type).setArray(array).setBuffer(buffer);
const markings=Array.from({length:8},(_,j)=>`<path d="M 88 ${j*32+7} l 20 9 l -20 9 M 152 ${j*32+7} l -20 9 l 20 9"/>`).join('');
const carving=await sharp(Buffer.from(`<svg width="256" height="256"><rect width="256" height="256" fill="#af946d"/><g fill="none" stroke="#746044" stroke-width="5"><path d="M 26 0 V256 M 36 0 V256 M 220 0 V256 M 230 0 V256"/>${markings}</g><g stroke="#ceb58b" stroke-width="2"><path d="M 40 0 V256 M 216 0 V256"/></g></svg>`)).png().toBuffer();
const texture=d.createTexture('Original geometric stone carving').setImage(carving).setMimeType('image/png');
const material=d.createMaterial('Original carved sandstone column').setBaseColorTexture(texture).setMetallicFactor(0).setRoughnessFactor(.95);
mesh.addPrimitive(d.createPrimitive().setAttribute('POSITION',accessor('VEC3',new Float32Array(positions))).setAttribute('NORMAL',accessor('VEC3',new Float32Array(normals))).setAttribute('TEXCOORD_0',accessor('VEC2',new Float32Array(uv))).setIndices(accessor('SCALAR',new Uint16Array(idx))).setMaterial(material));
await d.transform(weld(),prune());await io.write(process.argv[3],d);
console.log('Retained Meshy masonry; removed arch/plinth; added original 16-sided fluted column with broad end bands.');

// Deps: see retarget.mjs header. Example: node tools/meshy/prop.mjs ~/Downloads/meshy/crate.glb public/models/props/crate.glb 3000
// Meshy prop → game prop: base color only, simplified to ~TRIS triangles, 512px WebP, quantized + meshopt.
// usage: node prop.mjs in.glb out.glb [tris=4000] [--godot] [--screen-emission]
// --godot retains float attributes and PNG textures for native Godot import.
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {prune,dedup,weld,simplify,textureCompress,quantize,meshopt,flatten,join} from '@gltf-transform/functions';
import {MeshoptDecoder,MeshoptEncoder,MeshoptSimplifier} from 'meshoptimizer';import sharp from 'sharp';
await Promise.all([MeshoptDecoder.ready,MeshoptEncoder.ready,MeshoptSimplifier.ready]);
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder,'meshopt.encoder':MeshoptEncoder});
const [inP,outP,trisA]=process.argv.slice(2),TRIS=+trisA||4000;
const godot=process.argv.includes('--godot');
const D=await io.read(inP);
for(const m of D.getRoot().listMaterials()){for(const k of ['setNormalTexture','setMetallicRoughnessTexture','setOcclusionTexture','setEmissiveTexture'])m[k](null);m.setMetallicFactor(0).setRoughnessFactor(.85)}
let tris=0;for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives())tris+=(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3;
const ratio=Math.min(1,TRIS/tris);
await D.transform(prune(),dedup(),flatten(),join(),weld(),simplify({simplifier:MeshoptSimplifier,ratio,error:.02,lockBorder:false}),
 textureCompress({encoder:sharp,targetFormat:godot?'png':'webp',resize:[512,512],quality:80}),prune());
if(!godot)await D.transform(quantize(),meshopt({encoder:MeshoptEncoder,level:'medium'}));
let after=0;for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives())after+=(p.getIndices()?.getCount()||0)/3;
for(const error of [0.02,0.05,0.1,0.2]){
 if(!godot || after<=TRIS)break;
 // Attribute-aware collapse protects the screen's UV island when crossing seams.
 for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives()){
  const uv=p.getAttribute('TEXCOORD_0'),position=p.getAttribute('POSITION'),indices=p.getIndices();
  if(!uv||!indices)continue;
  const [reduced]=MeshoptSimplifier.simplifyWithAttributes(new Uint32Array(indices.getArray()),position.getArray(),3,uv.getArray(),2,[1,1],null,Math.floor(indices.getCount()*TRIS/after/3)*3,error,['Permissive']);
  indices.setArray(reduced);
 }
 await D.transform(prune());
 after=0;for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives())after+=(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3;
}
if(godot && after>TRIS)throw Error(`Cannot meet ${TRIS} triangle cap: ${after}; output not written`);
// A cyan-only emissive mask keeps the screen readable without making the metal glow.
if(godot && process.argv.includes('--screen-emission')){
 for(const m of D.getRoot().listMaterials()){
  const tex=m.getBaseColorTexture();if(!tex)continue;
  const {data,info}=await sharp(tex.getImage()).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  for(let i=0;i<data.length;i+=4){const cyan=data[i+1]>100&&data[i+2]>110&&data[i]<data[i+1]*.7; if(!cyan)data[i]=data[i+1]=data[i+2]=0;data[i+3]=255;}
  const png=await sharp(data,{raw:info}).png().toBuffer();
  m.setEmissiveTexture(D.createTexture('screen emission').setImage(png).setMimeType('image/png')).setEmissiveFactor([0.5,0.5,0.5]);
 }
}
await io.write(outP,D);console.log(outP,Math.round(tris),'→',Math.round(after),'tris');

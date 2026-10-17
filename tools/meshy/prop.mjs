// Deps: see retarget.mjs header. Example: node tools/meshy/prop.mjs ~/Downloads/meshy/crate.glb public/models/props/crate.glb 3000
// Meshy prop → game prop: base color only, simplified to ~TRIS triangles, 512px WebP, quantized + meshopt.
// usage: node prop.mjs in.glb out.glb [tris=4000]
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {prune,dedup,weld,simplify,textureCompress,quantize,meshopt,flatten,join} from '@gltf-transform/functions';
import {MeshoptDecoder,MeshoptEncoder,MeshoptSimplifier} from 'meshoptimizer';import sharp from 'sharp';
await Promise.all([MeshoptDecoder.ready,MeshoptEncoder.ready,MeshoptSimplifier.ready]);
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder,'meshopt.encoder':MeshoptEncoder});
const [inP,outP,trisA]=process.argv.slice(2),TRIS=+trisA||4000;
const D=await io.read(inP);
for(const m of D.getRoot().listMaterials()){for(const k of ['setNormalTexture','setMetallicRoughnessTexture','setOcclusionTexture','setEmissiveTexture'])m[k](null);m.setMetallicFactor(0).setRoughnessFactor(.85)}
let tris=0;for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives())tris+=(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3;
const ratio=Math.min(1,TRIS/tris);
await D.transform(prune(),dedup(),flatten(),join(),weld(),simplify({simplifier:MeshoptSimplifier,ratio,error:.02,lockBorder:false}),
 textureCompress({encoder:sharp,targetFormat:'webp',resize:[512,512],quality:80}),prune(),quantize(),meshopt({encoder:MeshoptEncoder,level:'medium'}));
let after=0;for(const me of D.getRoot().listMeshes())for(const p of me.listPrimitives())after+=(p.getIndices()?.getCount()||0)/3;
await io.write(outP,D);console.log(outP,Math.round(tris),'→',Math.round(after),'tris');

// Trim only LOD1 models that exceed the 2,500-triangle phone target.
import fs from 'node:fs';
import {createRequire} from 'node:module';
const R=createRequire('/home/jess/projects/tw-logs/w19/art/deps/package.json');
const {NodeIO}=R('@gltf-transform/core');const {ALL_EXTENSIONS}=R('@gltf-transform/extensions');
const {simplify,prune,unpartition}=R('@gltf-transform/functions');
const {MeshoptDecoder,MeshoptSimplifier}=R('meshoptimizer');
await MeshoptDecoder.ready;await MeshoptSimplifier.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const p of process.argv.slice(2)){
 const d=await io.read(p);
 const count=()=>d.getRoot().listMeshes().flatMap(m=>m.listPrimitives()).reduce((n,q)=>n+(q.getIndices()?.getCount()||q.getAttribute('POSITION').getCount())/3,0);
 const before=count();
 if(before>2500)await d.transform(simplify({simplifier:MeshoptSimplifier,ratio:Math.min(.92,2400/before),error:.03}),prune(),unpartition());
 const after=count();if(after>2500)throw Error(`${p}: ${after} triangles > 2500`);
 await io.write(p,d);console.log(p,before,after,fs.statSync(p).size);
}

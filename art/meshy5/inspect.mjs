// Local geometry audit, no Meshy calls. Usage: node inspect.mjs file.glb ...
import {NodeIO} from '@gltf-transform/core';
const io=new NodeIO();
for(const path of process.argv.slice(2)){
 const d=await io.read(path);let triangles=0;
 for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives())triangles+=(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3;
 console.log(JSON.stringify({path,triangles,materials:d.getRoot().listMaterials().length,textures:d.getRoot().listTextures().length}));
}

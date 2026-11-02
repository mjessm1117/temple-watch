import {NodeIO,getBounds} from '@gltf-transform/core';
for(const path of process.argv.slice(2)){
 const d=await new NodeIO().read(path),scene=d.getRoot().getDefaultScene()||d.getRoot().listScenes()[0];
 const b=getBounds(scene),s=b.max.map((v,i)=>+(v-b.min[i]).toFixed(3));
 let tris=0;for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives())tris+=(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3;
 const fit=Math.min(1/Math.max(s[0],s[2]),(path.includes('full')?1.85:.8)/s[1]);
 console.log(JSON.stringify({path,size:s,ratio_wh:+(s[0]/s[1]).toFixed(2),uniform_tile_height:+(s[1]/Math.max(s[0],s[2])).toFixed(3),fit_height:+(s[1]*fit).toFixed(3),tris}));
}

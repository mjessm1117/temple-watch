import {NodeIO} from '@gltf-transform/core';
const d=await new NodeIO().read(process.argv[2]);
for(const m of d.getRoot().listMaterials())console.log(m.getName(),m.getBaseColorFactor(),m.getBaseColorTexture()?.getName());

import {NodeIO} from '@gltf-transform/core';
const d=await new NodeIO().read(process.argv[2]);
for(const n of d.getRoot().listNodes())console.log(n.getName(),n.getTranslation(),n.getRotation(),n.getScale());

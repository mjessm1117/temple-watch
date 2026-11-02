import {NodeIO} from '@gltf-transform/core';import sharp from 'sharp';
const io=new NodeIO();
for(const path of process.argv.slice(2)){const d=await io.read(path);for(const tex of d.getRoot().listTextures())tex.setImage(await sharp(tex.getImage()).flip().png().toBuffer());await io.write(path,d);console.log(path)}

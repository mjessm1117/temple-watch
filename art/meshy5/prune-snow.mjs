import {NodeIO} from '@gltf-transform/core';import {prune} from '@gltf-transform/functions';
const io=new NodeIO();for(const lod of ['', '_lod1']){const path=`godot/assets/maps/meshy5/cover_half_snow_v1${lod}.glb`;const d=await io.read(path);await d.transform(prune());await io.write(path,d);console.log(path,d.getRoot().listTextures().length)}

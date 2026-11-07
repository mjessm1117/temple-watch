// The rigid diagonal sash becomes a vertical slab above the helmet in shoot.
// Remove it; crimson pauldrons keep the Officer's class accent.
import fs from 'node:fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
for (const suffix of ['', '_lod1']) {
  const file = `godot/assets/units/w17/officer${suffix}.glb`;
  const doc = await io.read(file);
  for (const node of doc.getRoot().listNodes().filter(n => n.getName().startsWith('sash diagonal'))) node.dispose();
  const temp = file + '.officer.tmp.glb'; await io.write(temp, doc); fs.renameSync(temp, file);
  console.log('OFFICER', suffix || 'full', 'sash removed');
}

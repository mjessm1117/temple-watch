import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';

await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const colors = {navy: [.045, .105, .19, 1], tan: [.59, .46, .31, 1], cream: [.83, .77, .65, 1]};
for (const kind of ['sniper', 'heavy', 'officer']) {
  const path = `godot/assets/units/w17/${kind}_lod1.glb`, doc = await io.read(path), root = doc.getRoot();
  const mesh = root.listMeshes()[0], old = mesh.listPrimitives(), pos = old[0].getAttribute('POSITION');
  const groups = {navy: [], tan: [], cream: []}, v = [];
  for (const primitive of old) {
    const indices = primitive.getIndices().getArray();
    for (let i = 0; i < indices.length; i += 3) {
      let y = 0;
      for (let j = 0; j < 3; j++) {pos.getElement(indices[i + j], v); y += v[1];}
      y = y / 3 * (kind === 'heavy' ? 1.8 / 2.05 : 1);
      const key = y > 1.29 ? 'cream' : y > .82 ? 'tan' : y > .35 ? 'navy' : kind === 'officer' ? 'tan' : 'cream';
      groups[key].push(indices[i], indices[i + 1], indices[i + 2]);
    }
  }
  for (const [key, group] of Object.entries(groups)) {
    const part = doc.createPrimitive().setIndices(doc.createAccessor(`Low ${key} indices`).setType('SCALAR').setArray(new Uint32Array(group)).setBuffer(root.listBuffers()[0]));
    for (const semantic of old[0].listSemantics().filter(s => s !== 'COLOR_0')) part.setAttribute(semantic, old[0].getAttribute(semantic));
    part.setMaterial(doc.createMaterial(`${kind} Low ${key}`).setBaseColorFactor(colors[key]).setMetallicFactor(0).setRoughnessFactor(.9));
    mesh.addPrimitive(part);
  }
  for (const primitive of old) mesh.removePrimitive(primitive);
  const materials = root.listMeshes().flatMap(m => m.listPrimitives().map(p => p.getMaterial()));
  for (const texture of root.listTextures()) {
    if (!materials.some(m => [m.getBaseColorTexture(), m.getNormalTexture(), m.getEmissiveTexture(), m.getMetallicRoughnessTexture(), m.getOcclusionTexture()].includes(texture))) texture.dispose();
  }
  for (const material of root.listMaterials()) if (!materials.includes(material)) material.dispose();
  await io.write(path + '.tmp.glb', doc);
  fs.renameSync(path + '.tmp.glb', path);
  console.log(kind, 'Low broad panels', Object.values(groups).map(x => x.length / 3));
}

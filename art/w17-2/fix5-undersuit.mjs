// Show navy fabric behind the new cream arm shells, including elbow gaps.
import fs from 'node:fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
for (const kind of ['sniper', 'heavy', 'tech', 'droid', 'officer']) for (const suffix of ['', '_lod1']) {
  const file = `godot/assets/units/w17/${kind}${suffix}.glb`;
  const doc = await io.read(file), root = doc.getRoot(), mesh = root.listMeshes()[0];
  const bones = root.listSkins()[0].listJoints().map(n => n.getName());
  let changed = 0;
  for (const primitive of [...mesh.listPrimitives()]) {
    if (!primitive.getAttribute('TEXCOORD_0')) continue;
    const joints = primitive.getAttribute('JOINTS_0'), weights = primitive.getAttribute('WEIGHTS_0');
    const indices = primitive.getIndices().getArray(), keep = [], cloth = [], ji = [], we = [];
    for (let i = 0; i < indices.length; i += 3) {
      let arm = 0;
      for (let k = 0; k < 3; k++) {
        joints.getElement(indices[i + k], ji); weights.getElement(indices[i + k], we);
        const bone = bones[ji[we.indexOf(Math.max(...we))]] || '';
        if (/^(upperarm|lowerarm)_[lr]$/.test(bone)) arm++;
      }
      (arm >= 2 ? cloth : keep).push(indices[i], indices[i + 1], indices[i + 2]);
    }
    if (!cloth.length) continue;
    changed += cloth.length / 3;
    const acc = values => doc.createAccessor('arm panel indices').setType('SCALAR').setArray(new Uint32Array(values)).setBuffer(root.listBuffers()[0]);
    const navy = doc.createMaterial(`${kind} navy woven arm undersuit`)
      .setBaseColorFactor([.07, .14, .23, 1]).setBaseColorTexture(primitive.getMaterial().getBaseColorTexture())
      .setMetallicFactor(0).setRoughnessFactor(.98);
    const part = doc.createPrimitive().setIndices(acc(cloth)).setMaterial(navy);
    for (const semantic of primitive.listSemantics()) part.setAttribute(semantic, primitive.getAttribute(semantic));
    mesh.addPrimitive(part);
    if (keep.length) primitive.setIndices(acc(keep)); else mesh.removePrimitive(primitive);
  }
  const temp = file + '.undersuit.tmp.glb'; await io.write(temp, doc); fs.renameSync(temp, file);
  console.log('UNDERSUIT', kind + suffix, 'arm triangles', changed);
}

// Add thin painted shell faces and dark joint bands to the existing skinned mesh.
// This uses the existing skin indices and bind matrices; it does not alter the rig.
import fs from 'node:fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';

await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const kinds = ['sniper', 'heavy', 'tech', 'droid', 'officer'];
const q = (a, p) => a.sort((x, y) => x - y)[Math.min(a.length - 1, Math.floor((a.length - 1) * p))];

function addQuad(doc, mesh, buffer, bone, corners, material) {
  const position = new Float32Array(corners.flat());
  const joints = new Uint16Array(16);
  const weights = new Float32Array(16);
  const normals = new Float32Array(12);
  for (let i = 0; i < 4; i++) { joints[i * 4] = bone; weights[i * 4] = 1; normals[i * 3 + 2] = 1; }
  const acc = (name, type, array) => doc.createAccessor(name).setType(type).setArray(array).setBuffer(buffer);
  mesh.addPrimitive(doc.createPrimitive()
    .setIndices(acc('plate indices', 'SCALAR', new Uint16Array([0, 1, 2, 0, 2, 3])))
    .setAttribute('POSITION', acc('plate position', 'VEC3', position))
    .setAttribute('NORMAL', acc('plate normal', 'VEC3', normals))
    .setAttribute('JOINTS_0', acc('plate joint', 'VEC4', joints))
    .setAttribute('WEIGHTS_0', acc('plate weight', 'VEC4', weights))
    .setMaterial(material));
}

for (const kind of kinds) for (const suffix of ['', '_lod1']) {
  const file = `godot/assets/units/w17/${kind}${suffix}.glb`;
  const doc = await io.read(file), root = doc.getRoot(), mesh = root.listMeshes()[0];
  const source = mesh.listPrimitives()[0], pos = source.getAttribute('POSITION');
  const joint = source.getAttribute('JOINTS_0'), weight = source.getAttribute('WEIGHTS_0');
  const bones = root.listSkins()[0].listJoints().map(n => n.getName());
  const samples = new Map();
  const xyz = [], ji = [], we = [];
  for (let i = 0; i < pos.getCount(); i++) {
    pos.getElement(i, xyz); joint.getElement(i, ji); weight.getElement(i, we);
    const index = ji[we.indexOf(Math.max(...we))];
    const list = samples.get(index) || [];
    list.push([...xyz]); samples.set(index, list);
  }
  const buffer = root.listBuffers()[0];
  const rim = doc.createMaterial(`${kind} plate worn edge`).setBaseColorFactor([.17, .22, .25, 1]).setMetallicFactor(.05).setRoughnessFactor(.87).setDoubleSided(true);
  const armor = doc.createMaterial(`${kind} painted hard plate`).setBaseColorFactor([.85, .79, .67, 1]).setMetallicFactor(0).setRoughnessFactor(.82).setDoubleSided(true);
  const suit = doc.createMaterial(`${kind} navy joint fabric`).setBaseColorFactor([.045, .105, .19, 1]).setMetallicFactor(0).setRoughnessFactor(.98).setDoubleSided(true);
  let added = 0;
  const bounds = name => {
    const index = bones.indexOf(name), v = samples.get(index);
    if (!v?.length) return null;
    return {index, x0: q(v.map(x => x[0]), .07), x1: q(v.map(x => x[0]), .93),
      y0: q(v.map(x => x[1]), .07), y1: q(v.map(x => x[1]), .93), z: q(v.map(x => x[2]), .94)};
  };
  for (const side of ['l', 'r']) {
    for (const part of ['upperarm', 'lowerarm', 'thigh']) {
      const b = bounds(`${part}_${side}`);
      if (!b) continue;
      const cx = (b.x0 + b.x1) / 2, half = (b.x1 - b.x0) * (part === 'thigh' ? .35 : .38);
      const y0 = b.y0 + (b.y1 - b.y0) * .13, y1 = b.y1 - (b.y1 - b.y0) * .13;
      const z = b.z + .006;
      addQuad(doc, mesh, buffer, b.index, [[cx - half, y0, z], [cx + half, y0, z], [cx + half, y1, z], [cx - half, y1, z]], rim);
      const inset = Math.min(.012, half * .24), trim = Math.min(.016, (y1 - y0) * .12);
      addQuad(doc, mesh, buffer, b.index, [[cx - half + inset, y0 + trim, z + .002], [cx + half - inset, y0 + trim, z + .002], [cx + half - inset, y1 - trim, z + .002], [cx - half + inset, y1 - trim, z + .002]], armor);
      added += 4;
    }
    for (const [upper, lower] of [['upperarm', 'lowerarm'], ['thigh', 'calf']]) {
      const a = bounds(`${upper}_${side}`), b = bounds(`${lower}_${side}`);
      if (!a || !b) continue;
      const cx = (b.x0 + b.x1) / 2, half = (b.x1 - b.x0) * .4;
      const y = (a.y0 + b.y1) / 2, h = Math.min(.028, (b.y1 - b.y0) * .11), z = Math.max(a.z, b.z) + .009;
      addQuad(doc, mesh, buffer, b.index, [[cx - half, y - h, z], [cx + half, y - h, z], [cx + half, y + h, z], [cx - half, y + h, z]], suit);
      added += 2;
    }
  }
  const temp = file + '.plates.tmp.glb'; await io.write(temp, doc); fs.renameSync(temp, file);
  console.log('PLATES', kind + suffix, 'added triangles', added, 'clips', root.listAnimations().length);
}

import fs from 'node:fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';

await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const base = 'godot/assets/units/w17/';
const palette = {
  navy: [.045, .105, .19, 1], tan: [.59, .46, .31, 1],
  cream: [.83, .77, .65, 1], steel: [.16, .22, .28, 1],
  sniper: [.30, .38, .20, 1], heavy: [.70, .33, .10, 1],
  tech: [.10, .45, .48, 1], droid: [.80, .66, .15, 1],
  officer: [.55, .10, .12, 1],
};

function panel(bone, kind) {
  if (/^(Head|head_end|headfront|neck_01)$/.test(bone)) return 'cream';
  if (bone.startsWith('clavicle_')) return 'accent';
  if (bone.startsWith('upperarm_')) return 'tan';
  if (bone.startsWith('lowerarm_')) return 'cream';
  if (bone.startsWith('hand_')) return 'navy';
  if (bone.startsWith('thigh_')) return 'tan';
  if (bone.startsWith('calf_')) return 'cream';
  if (bone.startsWith('foot_') || bone.startsWith('ball_')) return 'steel';
  if (bone === 'spine_02') return 'tan';
  if (bone === 'spine_03') return kind === 'sniper' ? 'tan' : 'navy';
  return 'navy';
}

function repaintBody(doc, kind) {
  const root = doc.getRoot(), mesh = root.listMeshes()[0];
  const bones = root.listSkins()[0].listJoints().map(n => n.getName());
  const source = mesh.listPrimitives();
  const groups = new Map();
  for (const primitive of source) {
    const indices = primitive.getIndices().getArray();
    const pos = primitive.getAttribute('POSITION');
    const joints = primitive.getAttribute('JOINTS_0');
    const weights = primitive.getAttribute('WEIGHTS_0');
    const parent = new Int32Array(pos.getCount()).map((_, i) => i);
    const find = x => { while (parent[x] !== x) x = parent[x] = parent[parent[x]]; return x; };
    const join = (a, b) => { parent[find(a)] = find(b); };
    for (let i = 0; i < indices.length; i += 3) {
      join(indices[i], indices[i + 1]); join(indices[i], indices[i + 2]);
    }
    const islands = new Map(), joint = [], weight = [], xyz = [];
    for (let i = 0; i < indices.length; i += 3) {
      const rootVertex = find(indices[i]);
      const island = islands.get(rootVertex) || {triangles: [], boneScores: new Map(), minY: Infinity, maxY: -Infinity};
      const scores = new Map(), center = [0, 0, 0];
      for (let k = 0; k < 3; k++) {
        const vertex = indices[i + k];
        joints.getElement(vertex, joint); weights.getElement(vertex, weight); pos.getElement(vertex, xyz);
        for (let axis = 0; axis < 3; axis++) center[axis] += xyz[axis] / 3;
        island.minY = Math.min(island.minY, xyz[1]); island.maxY = Math.max(island.maxY, xyz[1]);
        for (let n = 0; n < 4; n++) {
          scores.set(joint[n], (scores.get(joint[n]) || 0) + weight[n]);
          island.boneScores.set(joint[n], (island.boneScores.get(joint[n]) || 0) + weight[n]);
        }
      }
      island.triangles.push({indices: [indices[i], indices[i + 1], indices[i + 2]], scores, center});
      islands.set(rootVertex, island);
    }
    const dominant = scores => [...scores].sort((a, b) => b[1] - a[1])[0][0];
    for (const island of islands.values()) {
      // Compact disconnected armor pieces keep one color across their whole surface.
      const whole = island.maxY - island.minY < .34 && island.triangles.length <= 500;
      for (const triangle of island.triangles) {
        const bone = bones[dominant(whole ? island.boneScores : triangle.scores)];
        let key = panel(bone, kind);
        const [x, y, z] = triangle.center;
        if (kind === 'sniper' && key === 'cream' && Math.abs(x) < .28 && y > 1.08 && y < 1.45 && z > 0) key = 'tan';
        const list = groups.get(key) || [];
        list.push({primitive, indices: triangle.indices});
        groups.set(key, list);
      }
    }
  }
  for (const [key, triangles] of groups) {
    // Each input primitive can have distinct accessors and local indices.
    const bySource = new Map();
    for (const triangle of triangles) {
      const list = bySource.get(triangle.primitive) || [];
      list.push(...triangle.indices);
      bySource.set(triangle.primitive, list);
    }
    for (const [original, indices] of bySource) {
      const primitive = doc.createPrimitive().setIndices(doc.createAccessor(`${kind} ${key} indices`).setType('SCALAR').setArray(new Uint32Array(indices)).setBuffer(root.listBuffers()[0]));
      for (const semantic of original.listSemantics().filter(s => s !== 'COLOR_0')) primitive.setAttribute(semantic, original.getAttribute(semantic));
      const color = palette[key === 'accent' ? kind : key];
      primitive.setMaterial(doc.createMaterial(`${kind} ${key}`).setBaseColorFactor(color).setMetallicFactor(0).setRoughnessFactor(key === 'accent' ? .8 : .9));
      mesh.addPrimitive(primitive);
    }
  }
  for (const primitive of source) mesh.removePrimitive(primitive);
  return Object.fromEntries([...groups].map(([key, value]) => [key, value.length]));
}

function recolorAccessories(doc, kind) {
  const root = doc.getRoot();
  for (const mesh of root.listMeshes().slice(1)) {
    for (const primitive of mesh.listPrimitives()) {
      const material = primitive.getMaterial();
      if (!material) continue;
      const name = material.getName().toLowerCase();
      if (name === 'gold' || name === 'blue') {
        // Existing trim/sash becomes the sole class accent.
        primitive.setMaterial(doc.createMaterial(`${kind} accent trim`).setBaseColorFactor(palette[kind]).setMetallicFactor(0).setRoughnessFactor(.8));
      }
    }
  }
}

function seatHeavyPack(doc) {
  for (const node of doc.getRoot().listNodes()) {
    const name = node.getName();
    if (!name.startsWith('rocket ')) continue;
    // The spine parent is correct. The local offsets place the tubes above the helmet.
    const offset = name.startsWith('rocket backpack') ? -55 : -62;
    const t = node.getTranslation();
    node.setTranslation([t[0], t[1] + offset, t[2]]);
  }
}

async function save(path, doc) {
  const root = doc.getRoot();
  const materials = root.listMeshes().flatMap(m => m.listPrimitives().map(p => p.getMaterial()));
  for (const texture of root.listTextures()) {
    if (!materials.some(m => [m.getBaseColorTexture(), m.getNormalTexture(), m.getEmissiveTexture(), m.getMetallicRoughnessTexture(), m.getOcclusionTexture()].includes(texture))) texture.dispose();
  }
  for (const material of root.listMaterials()) if (!materials.includes(material)) material.dispose();
  const temp = path + '.fix4.tmp.glb';
  await io.write(temp, doc);
  fs.renameSync(temp, path);
}

for (const kind of ['sniper', 'heavy', 'tech', 'droid', 'officer']) {
  for (const suffix of ['', '_lod1']) {
    const path = `${base}${kind}${suffix}.glb`, doc = await io.read(path);
    if (doc.getRoot().listMeshes()[0].listPrimitives().some(p => p.getMaterial()?.getName() === `${kind} accent`)) {
      console.log('FIX4 already painted', kind + suffix);
      continue;
    }
    const counts = repaintBody(doc, kind);
    recolorAccessories(doc, kind);
    if (kind === 'heavy') seatHeavyPack(doc);
    await save(path, doc);
    console.log('FIX4', kind + suffix, counts);
  }
}

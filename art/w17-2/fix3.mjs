import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
import {Matrix4, Quaternion, Vector3} from 'three';

await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const base = 'godot/assets/units/w17/';
const colors = {
  navy: [.045, .105, .19, 1], tan: [.59, .46, .31, 1],
  cream: [.83, .77, .65, 1], steel: [.16, .22, .28, 1],
};

function panel(kind, x, y) {
  const a = Math.abs(x);
  if (kind === 'officer') {
    if (y > 1.58) return 'cream';
    if (y > 1.37) return a > .24 ? 'cream' : 'tan';
    if (y > 1.17) return a > .30 ? 'tan' : 'cream';
    if (y > .91) return a > .23 ? 'tan' : 'navy';
    if (y > .69) return a > .23 ? 'tan' : 'navy';
    if (y > .39) return 'navy';
    return 'tan';
  }
  const scale = kind === 'heavy' ? 1.8 / 2.05 : 1;
  y *= scale;
  if (y > 1.57) return 'cream';
  if (y > 1.29) return a > .23 ? 'cream' : 'tan';
  if (y > 1.10) return a > .28 ? 'tan' : 'cream';
  if (y > .86) return a > .25 ? 'tan' : 'navy';
  if (y > .61) return a > .17 ? 'tan' : 'navy';
  if (y > .38) return 'navy';
  return 'cream';
}

async function paint(kind) {
  for (const suffix of ['', '_lod1']) {
    const path = `${base}${kind}${suffix}.glb`, doc = await io.read(path), root = doc.getRoot();
    const mesh = root.listMeshes()[0], body = mesh.listPrimitives()[0], pos = body.getAttribute('POSITION');
    const indices = body.getIndices().getArray(), groups = {navy: [], tan: [], cream: [], steel: []}, v = [];
    for (let i = 0; i < indices.length; i += 3) {
      let x = 0, y = 0;
      for (let j = 0; j < 3; j++) {
        pos.getElement(indices[i + j], v);
        x += v[0]; y += v[1];
      }
      groups[panel(kind, x / 3, y / 3)].push(indices[i], indices[i + 1], indices[i + 2]);
    }
    for (const [key, group] of Object.entries(groups)) {
      if (!group.length) continue;
      const primitive = doc.createPrimitive().setIndices(doc.createAccessor(key + ' panel indices').setType('SCALAR').setArray(new Uint32Array(group)).setBuffer(root.listBuffers()[0]));
      for (const semantic of body.listSemantics().filter(s => s !== 'COLOR_0')) primitive.setAttribute(semantic, body.getAttribute(semantic));
      primitive.setMaterial(doc.createMaterial(kind + ' ' + key + ' armor').setBaseColorFactor(colors[key]).setMetallicFactor(0).setRoughnessFactor(.9));
      mesh.addPrimitive(primitive);
    }
    mesh.removePrimitive(body);
    await save(path, doc);
    console.log('PAINT', kind + suffix, pos.getCount(), 'vertices');
  }
}

function sample(doc, animation, time) {
  for (const channel of animation.listChannels()) {
    const sampler = channel.getSampler(), times = sampler.getInput().getArray();
    let i = 0;
    while (i < times.length - 2 && times[i + 1] < time) i++;
    const mix = Math.max(0, Math.min(1, (time - times[i]) / (times[i + 1] - times[i])));
    const a = [], b = [];
    sampler.getOutput().getElement(i, a);
    sampler.getOutput().getElement(i + 1, b);
    const node = channel.getTargetNode();
    if (channel.getTargetPath() === 'rotation') node.setRotation(new Quaternion(...a).slerp(new Quaternion(...b), mix).toArray());
    else {
      const v = a.map((x, j) => x + (b[j] - x) * mix);
      if (channel.getTargetPath() === 'translation') node.setTranslation(v);
      if (channel.getTargetPath() === 'scale') node.setScale(v);
    }
  }
}

const names = {
  sniper: ['precision blaster receiver', 'muzzle brake'],
  heavy: ['repeater body', 'rotary muzzle'],
  tech: ['carbine receiver', 'carbine barrel'],
  droid: ['droid blaster receiver', 'droid blaster barrel'],
  officer: ['officer pistol receiver', 'officer pistol barrel'],
};

async function aim(kind) {
  for (const suffix of ['', '_lod1']) {
    const path = `${base}${kind}${suffix}.glb`, doc = await io.read(path), root = doc.getRoot();
    const nodes = root.listNodes(), hand = nodes.find(n => n.getName() === 'hand_r');
    const find = prefix => nodes.find(n => n.getName().startsWith(prefix) && n.getName().endsWith('__hand_r'));
    const receiver = find(names[kind][0]), muzzle = find(names[kind][1]);
    if (!hand || !receiver || !muzzle) throw Error('Missing aim nodes in ' + path);
    const shoot = root.listAnimations().find(a => a.getName() === 'shoot');
    const channel = shoot.listChannels().find(c => c.getTargetNode() === hand && c.getTargetPath() === 'rotation');
    if (!channel) throw Error('Missing shoot hand rotation in ' + path);
    sample(doc, shoot, .35);
    const point = n => new Vector3().setFromMatrixPosition(new Matrix4().fromArray(n.getWorldMatrix()));
    const before = point(muzzle).sub(point(receiver)).normalize();
    const world = new Quaternion().setFromRotationMatrix(new Matrix4().extractRotation(new Matrix4().fromArray(hand.getWorldMatrix())));
    const correction = world.clone().invert().multiply(new Quaternion().setFromUnitVectors(before, new Vector3(0, 0, 1))).multiply(world);
    const output = channel.getSampler().getOutput(), arr = output.getArray();
    for (let i = 0; i < arr.length; i += 4) {
      const q = new Quaternion(arr[i], arr[i + 1], arr[i + 2], arr[i + 3]).multiply(correction).normalize();
      arr.set(q.toArray(), i);
    }
    output.setArray(arr);
    await save(path, doc);
    console.log('AIM', kind + suffix, 'before elevation', Math.asin(before.y) * 180 / Math.PI);
  }
}

async function save(path, doc) {
  const materials = doc.getRoot().listMeshes().flatMap(m => m.listPrimitives().map(p => p.getMaterial()));
  for (const texture of doc.getRoot().listTextures()) {
    if (!materials.some(m => [m.getBaseColorTexture(), m.getNormalTexture(), m.getEmissiveTexture(), m.getMetallicRoughnessTexture(), m.getOcclusionTexture()].includes(texture))) texture.dispose();
  }
  for (const material of doc.getRoot().listMaterials()) if (!materials.includes(material)) material.dispose();
  const temp = path + '.fix3.tmp.glb';
  await io.write(temp, doc);
  fs.renameSync(temp, path);
}

await paint('sniper');
// The conditional marker is checked here, immediately before the Heavy repaint step.
if (fs.existsSync('/home/jess/projects/tw-logs/w17/HEAVY-REPAINT')) await paint('heavy');
else console.log('PAINT heavy skipped: no marker');
await paint('officer');
if (!process.argv.includes('--paint-only')) for (const kind of Object.keys(names)) await aim(kind);

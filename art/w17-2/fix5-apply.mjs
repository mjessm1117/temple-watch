// Transfer Meshy's preserved UV atlas onto the existing rigged Full and Low GLBs.
// Geometry, skin, animation and hand-held weapons remain in the source files.
import fs from 'node:fs';
import sharp from 'sharp';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
import {Matrix4} from 'three';

await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const base = 'godot/assets/units/w17/';
const kinds = process.argv.slice(2).length ? process.argv.slice(2) : ['sniper', 'heavy', 'tech', 'droid', 'officer'];

async function atlas(kind) {
  const cache = `art/w17-2/fix5-${kind}-meshy.glb`;
  if (!fs.existsSync(cache)) {
    const env = fs.readFileSync('/home/jess/hive/.env', 'utf8');
    const key = process.env.MESHY_KEY || env.match(/^MESHY_KEY=(.*)$/m)?.[1]?.replace(/^['"]|['"]$/g, '');
    const ledger = JSON.parse(fs.readFileSync('art/w17-2/fix5-ledger.json', 'utf8'));
    const id = ledger.tasks.find(t => t.kind === kind && !t.retry)?.id;
    if (!key || !id) throw Error(`Cannot retrieve Meshy source for ${kind}`);
    const taskResponse = await fetch(`https://api.meshy.ai/openapi/v1/retexture/${id}`, {headers: {Authorization: `Bearer ${key}`}});
    if (!taskResponse.ok) throw Error(`Meshy task lookup failed for ${kind}: ${taskResponse.status}`);
    const task = await taskResponse.json();
    const modelResponse = await fetch(task.model_urls?.glb);
    if (!modelResponse.ok) throw Error(`Meshy model download failed for ${kind}: ${modelResponse.status}`);
    fs.writeFileSync(cache, Buffer.from(await modelResponse.arrayBuffer()));
  }
  const result = await io.read(cache);
  const image = result.getRoot().listTextures()[0]?.getImage();
  if (!image) throw Error(`Meshy returned no atlas: ${kind}`);
  const {data, info} = await sharp(image).resize(1024, 1024).removeAlpha().raw().toBuffer({resolveWithObject: true});
  // Normalize illumination so the existing material boundaries keep the
  // specified armor, undersuit and class colors while retaining painted wear.
  for (let i = 0; i < data.length; i += info.channels) {
    const luma = (data[i] * .2126 + data[i + 1] * .7152 + data[i + 2] * .0722) / 255;
    const value = Math.max(120, Math.min(255, Math.round((.89 + (luma - .55) * .65) * 255)));
    data[i] = data[i + 1] = data[i + 2] = value;
  }
  return sharp(data, {raw: info}).png({compressionLevel: 9}).toBuffer();
}

function seatTechPack(root) {
  const spine = root.listNodes().find(n => n.getName() === 'spine_03');
  if (!spine) throw Error('Tech spine_03 missing');
  for (const node of root.listNodes().filter(n => /^(tool battery backpack|pack battery)/.test(n.getName()))) {
    if (node.getParentNode() !== spine) {
      const world = new Matrix4().fromArray(node.getWorldMatrix());
      spine.addChild(node);
      const local = new Matrix4().fromArray(spine.getWorldMatrix()).invert().multiply(world);
      node.setMatrix(local.toArray());
    }
    const t = node.getTranslation();
    node.setTranslation([t[0], t[1] - 35, t[2] + (node.getName().startsWith('pack battery') ? 8 : 0)]);
  }
}

function removeOfficerSlab(root) {
  for (const node of root.listNodes().filter(n => n.getName().startsWith('short command cape'))) node.dispose();
}

for (const kind of kinds) {
  const image = await atlas(kind);
  for (const suffix of ['', '_lod1']) {
    const file = `${base}${kind}${suffix}.glb`;
    const doc = await io.read(file), root = doc.getRoot();
    const texture = doc.createTexture(`${kind} painted armor 1024`).setImage(image).setMimeType('image/png');
    const body = root.listMeshes()[0];
    if (!body?.listPrimitives().length) throw Error(`Body missing: ${file}`);
    for (const primitive of body.listPrimitives()) {
      if (!primitive.getAttribute('TEXCOORD_0')) throw Error(`UV missing: ${file}`);
      const original = primitive.getMaterial();
      const material = doc.createMaterial(original?.getName() || `${kind} armor`)
        .setBaseColorFactor(original?.getBaseColorFactor() || [1, 1, 1, 1])
        .setBaseColorTexture(texture).setMetallicFactor(0).setRoughnessFactor(.85);
      primitive.setMaterial(material);
    }
    if (kind === 'tech') seatTechPack(root);
    if (kind === 'officer') removeOfficerSlab(root);
    const temp = file + '.fix5.tmp.glb';
    await io.write(temp, doc);
    fs.renameSync(temp, file);
    const triangles = root.listMeshes().flatMap(m => m.listPrimitives()).reduce((n, p) => n + p.getIndices().getCount() / 3, 0);
    console.log('APPLIED', kind + suffix, 'triangles', triangles, 'clips', root.listAnimations().length, 'texture', image.length);
  }
}

// Retarget the original UE unit motion onto an already packed named Jedi.
// Run from a scratch directory with @gltf-transform/core, @gltf-transform/extensions,
// meshoptimizer, and three installed: node retarget-jedi16.mjs source.glb jedi.glb out.glb
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder, MeshoptEncoder} from 'meshoptimizer';
import * as T from 'three';

await MeshoptDecoder.ready;
await MeshoptEncoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'meshopt.decoder': MeshoptDecoder, 'meshopt.encoder': MeshoptEncoder,
});
const [sourcePath, targetPath, outputPath] = process.argv.slice(2);
if (!sourcePath || !targetPath || !outputPath) throw Error('source.glb target.glb output.glb required');
const source = await io.read(sourcePath), target = await io.read(targetPath);
const sourceRoot = source.getRoot(), targetRoot = target.getRoot();
const wanted = new Set(['idle', 'saberIdle', 'gunIdle', 'run', 'walk', 'swing', 'swing2',
  'cast', 'channel', 'throw', 'shoot', 'hit', 'death', 'block', 'aim']);
const S = Object.fromEntries(sourceRoot.listNodes().map(n => [n.getName(), n]));
const D = Object.fromEntries(targetRoot.listNodes().map(n => [n.getName(), n]));
const parent = root => {
  const result = new Map();
  for (const node of root.listNodes()) for (const child of node.listChildren()) result.set(child, node);
  return result;
};
const sp = parent(sourceRoot), dp = parent(targetRoot);
const matrix = (translation, rotation, scale) => new T.Matrix4().compose(
  new T.Vector3(...translation), new T.Quaternion(...rotation), new T.Vector3(...scale));
const rest = n => matrix(n.getTranslation(), n.getRotation(), n.getScale());
function world(n, parents, local, cache) {
  if (cache.has(n)) return cache.get(n);
  const p = parents.get(n), value = p ? world(p, parents, local, cache).clone().multiply(local(n)) : local(n);
  cache.set(n, value); return value;
}
const sr = new Map(), dr = new Map();
const sw = n => world(n, sp, rest, sr), dw = n => world(n, dp, rest, dr);
const position = m => new T.Vector3().setFromMatrixPosition(m);
const rotation = m => { const q = new T.Quaternion(); m.decompose(new T.Vector3(), q, new T.Vector3()); return q; };
// Forward, up, and right are measured from the actual skeleton. This maps the
// two rigs' facing directions without assuming their Blender bone rolls match.
function bodyFrame(bones, restWorld) {
  const p = name => position(restWorld(bones[name]));
  const up = p('Head').sub(p('pelvis')).normalize();
  const right = p('thigh_l').sub(p('thigh_r')).normalize();
  const forward = new T.Vector3().crossVectors(right, up).normalize();
  const side = new T.Vector3().crossVectors(up, forward).normalize();
  return new T.Quaternion().setFromRotationMatrix(new T.Matrix4().makeBasis(side, up, forward));
}
const alignment = bodyFrame(D, dw).multiply(bodyFrame(S, sw).invert());
const heightScale = position(dw(D.Head)).distanceTo(position(dw(D.pelvis))) /
  position(sw(S.Head)).distanceTo(position(sw(S.pelvis)));
const restFootFloor = Math.min(position(dw(D.foot_l)).y, position(dw(D.foot_r)).y);
const joints = targetRoot.listSkins()[0].listJoints().filter(n => S[n.getName()]);
// An animated parent must be solved before its child for local rotation output.
const depth = (n, parents) => parents.has(n) ? 1 + depth(parents.get(n), parents) : 0;
joints.sort((a, b) => depth(a, dp) - depth(b, dp));
const decode = accessor => {
  const data = accessor.getArray();
  if (!accessor.getNormalized()) return data;
  const divisor = {5120: 127, 5121: 255, 5122: 32767, 5123: 65535}[accessor.getComponentType()];
  return Float32Array.from(data, value => Math.max(-1, value / divisor));
};
const arrays = new Map();
const values = a => { if (!arrays.has(a)) arrays.set(a, decode(a)); return arrays.get(a); };
const channelsOf = clip => {
  const result = {};
  for (const channel of clip.listChannels()) {
    const bone = channel.getTargetNode().getName();
    (result[bone] ||= {})[channel.getTargetPath()] = channel.getSampler();
  }
  return result;
};
const idleSource = sourceRoot.listAnimations().find(a => a.getName() === 'idle');
const idleChannels = channelsOf(idleSource);
const idleLength = Math.max(...idleSource.listSamplers().map(s => {
  const keys = values(s.getInput()); return keys[keys.length - 1];
}));
function sample(sampler, time, path) {
  const input = values(sampler.getInput()), output = values(sampler.getOutput());
  const width = path === 'rotation' ? 4 : 3;
  let i = 0; while (i < input.length - 2 && input[i + 1] < time) i++;
  const j = Math.min(i + 1, input.length - 1), span = input[j] - input[i];
  const t = span > 0 ? Math.max(0, Math.min(1, (time - input[i]) / span)) : 0;
  const a = Array.from(output.slice(i * width, i * width + width));
  const b = Array.from(output.slice(j * width, j * width + width));
  if (sampler.getInterpolation() === 'STEP' || t === 0) return a;
  if (width === 4) return new T.Quaternion(...a).slerp(new T.Quaternion(...b), t).toArray();
  return a.map((v, k) => v + (b[k] - v) * t);
}
for (const old of targetRoot.listAnimations()) old.dispose();
const buffer = targetRoot.listBuffers()[0];
for (const original of sourceRoot.listAnimations()) {
  const name = original.getName(); if (!wanted.has(name)) continue;
  const channels = channelsOf(original);
  const duration = Math.max(...original.listSamplers().map(s => {
    const keys = values(s.getInput()); return keys[keys.length - 1];
  }));
  // UnitView returns to idle after 0.52s. Preserve the original full strike,
  // including its recovery, inside that action window.
  const outputDuration = name === 'swing' ? 0.5 : duration;
  const count = Math.max(2, Math.round(outputDuration * 30) + 1);
  const times = Float32Array.from({length: count}, (_, i) => outputDuration * i / (count - 1));
  const tracks = Object.fromEntries(joints.map(n => [n.getName(), new Float32Array(count * 4)]));
  const hips = new Float32Array(count * 3);
  for (let frame = 0; frame < count; frame++) {
    const time = times[frame] * duration / outputDuration;
    const sourceCache = new Map(), targetCache = new Map();
    const animatedSource = n => {
      // The source saber guard has a deep crouch that folds the named Meshy
      // robes. Keep its original upper-body guard over the original idle gait.
      const lower = name === 'saberIdle' && /^(pelvis|thigh_[lr]|calf_[lr]|foot_[lr]|ball_[lr])$/.test(n.getName());
      const c = (lower ? idleChannels : channels)[n.getName()] || {};
      const sampleTime = lower ? time * idleLength / duration : time;
      let poseRotation = c.rotation ? sample(c.rotation, sampleTime, 'rotation') : n.getRotation();
      if (name === 'saberIdle' && !lower && c.rotation && idleChannels[n.getName()]?.rotation) {
        const idlePose = sample(idleChannels[n.getName()].rotation, time * idleLength / duration, 'rotation');
        poseRotation = new T.Quaternion(...idlePose).slerp(new T.Quaternion(...poseRotation), 0.22).toArray();
      }
      return matrix(c.translation ? sample(c.translation, sampleTime, 'translation') : n.getTranslation(),
        poseRotation, n.getScale());
    };
    const sourceWorld = n => world(n, sp, animatedSource, sourceCache);
    const targetLocal = new Map();
    const targetWorld = n => world(n, dp, k => targetLocal.get(k) || rest(k), targetCache);
    for (const bone of joints) {
      const src = S[bone.getName()], p = dp.get(bone);
      const delta = rotation(sourceWorld(src)).multiply(rotation(sw(src)).invert());
      const worldRotation = alignment.clone().multiply(delta).multiply(alignment.clone().invert()).multiply(rotation(dw(bone)));
      const parentRotation = p ? rotation(targetWorld(p)) : new T.Quaternion();
      const localRotation = parentRotation.invert().multiply(worldRotation).normalize();
      const localPosition = new T.Vector3(...bone.getTranslation());
      if (bone.getName() === 'pelvis') {
        const offset = position(sourceWorld(src)).sub(position(sw(src))).applyQuaternion(alignment).multiplyScalar(heightScale);
        // Battle travel already drives horizontal motion. In-place feet stay on
        // the ground instead of accumulating source root motion a second time.
        offset.x = 0; offset.z = 0;
        const worldPosition = position(dw(bone)).add(offset);
        localPosition.copy(p ? worldPosition.applyMatrix4(targetWorld(p).clone().invert()) : worldPosition);
        hips.set(localPosition.toArray(), frame * 3);
      }
      tracks[bone.getName()].set(localRotation.toArray(), frame * 4);
      targetLocal.set(bone, new T.Matrix4().compose(localPosition, localRotation, new T.Vector3(...bone.getScale())));
      targetCache.clear();
    }
    if (name !== 'death') {
      const floor = Math.min(position(targetWorld(D.foot_l)).y, position(targetWorld(D.foot_r)).y);
      const lift = restFootFloor - floor;
      if (Math.abs(lift) > 0.0001) {
        const pelvis = D.pelvis, p = dp.get(pelvis);
        const corrected = position(targetWorld(pelvis)); corrected.y += lift;
        const local = p ? corrected.applyMatrix4(targetWorld(p).clone().invert()) : corrected;
        hips.set(local.toArray(), frame * 3);
      }
    }
  }
  const clip = target.createAnimation(name);
  const input = target.createAccessor().setArray(times).setType('SCALAR').setBuffer(buffer);
  const add = (node, path, data, type) => {
    const output = target.createAccessor().setArray(data).setType(type).setBuffer(buffer);
    const sampler = target.createAnimationSampler().setInput(input).setOutput(output).setInterpolation('LINEAR');
    clip.addSampler(sampler).addChannel(target.createAnimationChannel().setTargetNode(node).setTargetPath(path).setSampler(sampler));
  };
  for (const bone of joints) add(bone, 'rotation', tracks[bone.getName()], 'VEC4');
  add(D.pelvis, 'translation', hips, 'VEC3');
}
await io.write(outputPath, target);
console.log(outputPath, targetRoot.listAnimations().length, 'original clips');

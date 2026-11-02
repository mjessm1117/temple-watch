// Add a small, steady emissive beacon to the finished relay GLB.
// Usage: node art/meshy4/beacon.mjs path/to/relay.glb
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
import sharp from 'sharp';

await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const path = process.argv[2];
const doc = await io.read(path);
const root = doc.getRoot();
let lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
let tip = [0, -Infinity, 0];
for (const mesh of root.listMeshes()) for (const primitive of mesh.listPrimitives()) {
  const position = primitive.getAttribute('POSITION');
  for (let i = 0; i < position.getCount(); i++) {
    const v = position.getElement(i, []);
    if (v[1] > tip[1]) tip = [...v];
    for (let axis = 0; axis < 3; axis++) {
      lo[axis] = Math.min(lo[axis], v[axis]);
      hi[axis] = Math.max(hi[axis], v[axis]);
    }
  }
}
const height = hi[1] - lo[1];
const radius = height * 0.022;
const x = tip[0], y = tip[1] - radius * 0.3, z = tip[2];
const positions = new Float32Array([
  x, y + radius, z, x + radius, y, z, x, y, z + radius,
  x - radius, y, z, x, y, z - radius, x, y - radius, z,
]);
const faces = new Uint16Array([0,1,2, 0,2,3, 0,3,4, 0,4,1, 5,2,1, 5,3,2, 5,4,3, 5,1,4]);
const pixel = await sharp(Buffer.from([255, 62, 12, 255]), {raw: {width: 1, height: 1, channels: 4}}).png().toBuffer();
const texture = doc.createTexture('steady_red_amber_beacon').setImage(pixel).setMimeType('image/png');
const material = doc.createMaterial('steady_emissive_beacon').setBaseColorFactor([1, 0.2, 0.03, 1])
  .setEmissiveTexture(texture).setEmissiveFactor([1, 0.65, 0.25]).setDoubleSided(true);
const primitive = doc.createPrimitive().setAttribute('POSITION', doc.createAccessor().setType('VEC3').setArray(positions))
  .setIndices(doc.createAccessor().setType('SCALAR').setArray(faces)).setMaterial(material);
root.listScenes()[0].addChild(doc.createNode('steady_beacon').setMesh(doc.createMesh('beacon_octahedron').addPrimitive(primitive)));
await io.write(path, doc);
console.log(`${path}: steady textured emissive beacon, +8 triangles`);

import {execFileSync} from 'node:child_process';
import sharp from 'sharp';
import {NodeIO, PropertyType} from '@gltf-transform/core';
import {ALL_EXTENSIONS, EXTTextureWebP} from '@gltf-transform/extensions';
import {copyToDocument, createDefaultPropertyResolver, dedup, prune, simplify, unpartition} from '@gltf-transform/functions';
import {MeshoptDecoder, MeshoptSimplifier} from 'meshoptimizer';

// Run from the repository root: node art/w17-2/fix6.mjs
// This invokes Blender to generate Fix 8 gear. Then run fix7-compact.py.
await MeshoptDecoder.ready;
await MeshoptSimplifier.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const sourceBody = 'godot/assets/models/units/trooper.glb';
const output = 'godot/assets/units/w17';
const colors = {
  sniper: [.30, .38, .20], heavy: [.70, .33, .10], tech: [.10, .45, .48],
  droid: [.80, .66, .15], officer: [.55, .10, .12],
};
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const mul=(a,b)=>[
  a[3]*b[0]+a[0]*b[3]+a[1]*b[2]-a[2]*b[1],
  a[3]*b[1]-a[0]*b[2]+a[1]*b[3]+a[2]*b[0],
  a[3]*b[2]+a[0]*b[1]-a[1]*b[0]+a[2]*b[3],
  a[3]*b[3]-a[0]*b[0]-a[1]*b[1]-a[2]*b[2],
];
const rotate=(q,v)=>{const t=cross(q.slice(0,3),v).map(x=>2*x);return v.map((x,i)=>x+q[3]*t[i]+cross(q.slice(0,3),t)[i]);};

async function recolorTexture(doc, kind, lod) {
  const texture = doc.getRoot().listTextures()[0];
  const {data, info} = await sharp(texture.getImage()).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const rgb = colors[kind];
  for (let i=0; i<data.length; i+=4) {
    const [r,g,b] = [data[i],data[i+1],data[i+2]];
    // The Trooper's existing red UV islands are the pauldrons, helmet marks,
    // and small armor accents. Preserve their light and shadow variations.
    if (r > 55 && r > g*1.65 && r > b*1.55 && g < 105 && b < 105) {
      const shade = Math.max(.15, Math.min(1.5, r / 205));
      for (let c=0;c<3;c++) data[i+c] = Math.round(255*rgb[c]*shade);
    }
  }
  // Paint a narrow center stripe directly on the original helmet UVs. The
  // source helmet has no red stripe; use its own surface instead of geometry.
  const primitive=doc.getRoot().listMeshes()[0].listPrimitives()[0];
  const position=primitive.getAttribute('POSITION'), uv=primitive.getAttribute('TEXCOORD_0');
  const indices=primitive.getIndices().getArray();
  let stripePixels=0;
  for(let i=0;i<indices.length;i+=3){
    const p=[],t=[];
    for(let k=0;k<3;k++){
      const v=indices[i+k],xyz=[0,0,0],tex=[0,0];
      position.getElement(v,xyz);uv.getElement(v,tex);
      p.push(xyz);t.push([tex[0]*info.width,tex[1]*info.height]);
    }
    if(Math.max(...p.map(v=>v[1]))<1.52 || Math.min(...p.map(v=>Math.abs(v[0])))>.055 || Math.max(...p.map(v=>v[2]))<.04)continue;
    const x0=Math.max(0,Math.floor(Math.min(...t.map(v=>v[0])))),x1=Math.min(info.width-1,Math.ceil(Math.max(...t.map(v=>v[0]))));
    const y0=Math.max(0,Math.floor(Math.min(...t.map(v=>v[1])))),y1=Math.min(info.height-1,Math.ceil(Math.max(...t.map(v=>v[1]))));
    const area=(t[1][1]-t[2][1])*(t[0][0]-t[2][0])+(t[2][0]-t[1][0])*(t[0][1]-t[2][1]);
    if(Math.abs(area)<1e-5)continue;
    for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++){
      const a=((t[1][1]-t[2][1])*(x-t[2][0])+(t[2][0]-t[1][0])*(y-t[2][1]))/area;
      const b=((t[2][1]-t[0][1])*(x-t[2][0])+(t[0][0]-t[2][0])*(y-t[2][1]))/area;
      const c=1-a-b;
      if(Math.min(a,b,c)<-.001)continue;
      const xyz=[0,1,2].map(j=>a*p[0][j]+b*p[1][j]+c*p[2][j]);
      if(Math.abs(xyz[0])>.032 || xyz[1]<1.53 || xyz[1]>1.70 || xyz[2]<.045)continue;
      const o=4*(y*info.width+x),bright=(data[o]+data[o+1]+data[o+2])/3;
      if(bright<115)continue;
      const shade=Math.max(.65,Math.min(1.3,bright/210));
      for(let j=0;j<3;j++)data[o+j]=Math.round(255*rgb[j]*shade);
      stripePixels++;
    }
  }
  console.log(kind,'helmet stripe texels',stripePixels);
  const image = sharp(data,{raw:info});
  texture.setImage(await (lod ? image.resize(512, 512) : image).webp({quality:90}).toBuffer()).setMimeType('image/webp');
  doc.createExtension(EXTTextureWebP).setRequired(true);
  for (const material of doc.getRoot().listMaterials()) {
    material.setName(`${kind} accent armor`).setMetallicFactor(0).setRoughnessFactor(.8);
  }
}

// Fix 8 gear is authored in the final hand frame: +Z along the barrel.
// These anchors are the approved Fix 7 receiver transforms, so the new grip
// stays in the same palm while the body, skin, and clips remain untouched.
const gearAnchor = {
  sniper:{p:[-.012,.041,.005],q:[.620,-.594,.497,-.120]},
  heavy:{p:[-.020,.041,-.010],q:[.784,-.334,.521,.046]},
  tech:{p:[-.018,.029,.009],q:[.764,-.384,.518,.020]},
  droid:{p:[-.015,.031,.006],q:[.808,-.272,.516,.087]},
  officer:{p:[-.014,.032,.005],q:[.835,-.171,.501,.149]},
};
function attachGear(target, weapon, pack, kind) {
  const joints=new Map(target.getRoot().listSkins()[0].listJoints().map(n=>[n.getName(),n]));
  const counts={weapon:0,pack:0};
  for (const [source,bone] of [[weapon,'hand_r'],[pack,'spine_03']]) {
    if (!source) continue;
    const resolver=createDefaultPropertyResolver(target,source);
    for (const srcNode of source.getRoot().listNodes()) {
      if (!srcNode.getMesh()) continue;
      const mesh=copyToDocument(target,source,[srcNode.getMesh()],resolver).get(srcNode.getMesh());
      const node=target.createNode(`${srcNode.getName()}__${bone}`).setMesh(mesh);
      if (bone==='hand_r') {
        const {p,q}=gearAnchor[kind];
        node.setTranslation(rotate(q,srcNode.getTranslation()).map((v,i)=>v+p[i]));
        node.setRotation(mul(q,srcNode.getRotation()));
      } else {
        node.setTranslation(srcNode.getTranslation());
        node.setRotation(srcNode.getRotation());
      }
      node.setScale(srcNode.getScale());
      joints.get(bone).addChild(node);
      counts[bone==='hand_r'?'weapon':'pack']+=mesh.listPrimitives().reduce((s,p)=>s+(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3,0);
    }
  }
  return counts;
}

function removeBindPoseTracks(doc) {
  for (const animation of doc.getRoot().listAnimations()) {
    for (const channel of animation.listChannels()) {
      const node=channel.getTargetNode(), path=channel.getTargetPath();
      const rest=path==='translation'?node.getTranslation():path==='rotation'?node.getRotation():path==='scale'?node.getScale():null;
      if (!rest) continue;
      const values=channel.getSampler().getOutput().getArray();
      if (values.every((value,i)=>Math.abs(value-rest[i%rest.length])<1e-6)) {
        const sampler=channel.getSampler();
        animation.removeChannel(channel);
        if (!animation.listChannels().some(other=>other.getSampler()===sampler)) animation.removeSampler(sampler);
      }
    }
  }
}

execFileSync('blender',['-b','--factory-startup','--python','art/w17-2/fix8_gear.py'],{stdio:'inherit'});
for (const kind of Object.keys(colors)) {
  for (const lod of [false,true]) {
    const level=lod?1:0;
    const weapon=await io.read(`/tmp/w17-fix8-gear/${kind}-weapon-lod${level}.glb`);
    const pack=['heavy','tech'].includes(kind) ? await io.read(`/tmp/w17-fix8-gear/${kind}-pack-lod${level}.glb`) : null;
    const doc=await io.read(sourceBody);
    await recolorTexture(doc,kind,lod);
    if (lod) await doc.transform(simplify({simplifier:MeshoptSimplifier,ratio:.42,error:.025}));
    const counts=attachGear(doc,weapon,pack,kind);
    removeBindPoseTracks(doc);
    await doc.transform(prune(), dedup({propertyTypes:[PropertyType.ACCESSOR]}), unpartition());
    const path=`${output}/${kind}${lod?'_lod1':''}.glb`;
    await io.write(path,doc);
    const tris=doc.getRoot().listMeshes().reduce((s,m)=>s+m.listPrimitives().reduce((t,p)=>t+(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3,0),0);
    console.log(kind,lod?'LOD1':'LOD0',tris,counts,path);
  }
}

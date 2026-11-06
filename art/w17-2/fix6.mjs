import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
import sharp from 'sharp';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {copyToDocument, createDefaultPropertyResolver, simplify, unpartition} from '@gltf-transform/functions';
import {MeshoptDecoder, MeshoptSimplifier} from 'meshoptimizer';

// Run from the repository root: node art/w17-2/fix6.mjs
await MeshoptDecoder.ready;
await MeshoptSimplifier.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder': MeshoptDecoder});
const sourceBody = 'godot/assets/models/units/trooper.glb';
const output = 'godot/assets/units/w17';
const colors = {
  sniper: [.30, .38, .20], heavy: [.70, .33, .10], tech: [.10, .45, .48],
  droid: [.80, .66, .15], officer: [.55, .10, .12],
};
// Shoot-pose barrel direction and desired forward direction in the Trooper
// hand attachment's local space, measured with w17_art4_test.gd.
const aim = {
  sniper:[[-.674930,.324510,.662694],[.759833,-.442442,-.476339]],
  heavy:[[-.725629,.387963,.568285],[.786323,-.420037,-.453063]],
  tech:[[-.338233,.393474,.854855],[.776532,-.428134,-.462277]],
  droid:[[-.430777,.429436,.793735],[.786578,-.420528,-.452162]],
  officer:[[-.442912,.474092,.760964],[.786312,-.420017,-.453099]],
};
const dot=(a,b)=>a.reduce((s,v,i)=>s+v*b[i],0);
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const norm=v=>{const n=Math.hypot(...v);return v.map(x=>x/n);};
const mul=(a,b)=>[
  a[3]*b[0]+a[0]*b[3]+a[1]*b[2]-a[2]*b[1],
  a[3]*b[1]-a[0]*b[2]+a[1]*b[3]+a[2]*b[0],
  a[3]*b[2]+a[0]*b[1]-a[1]*b[0]+a[2]*b[3],
  a[3]*b[3]-a[0]*b[0]-a[1]*b[1]-a[2]*b[2],
];
const rotate=(q,v)=>{const t=cross(q.slice(0,3),v).map(x=>2*x);return v.map((x,i)=>x+q[3]*t[i]+cross(q.slice(0,3),t)[i]);};
const between=(a,b)=>norm([...cross(a,b),1+dot(a,b)]);

async function recolorTexture(doc, kind) {
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
  texture.setImage(await sharp(data,{raw:info}).png().toBuffer()).setMimeType('image/png');
  for (const material of doc.getRoot().listMaterials()) {
    material.setName(`${kind} accent armor`).setMetallicFactor(0).setRoughnessFactor(.8);
  }
}

function attachGear(target, source, kind) {
  const dstRoot=target.getRoot(), srcRoot=source.getRoot();
  const resolver=createDefaultPropertyResolver(target,source);
  const joints=new Map(dstRoot.listSkins()[0].listJoints().map(n=>[n.getName(),n]));
  const counts={weapon:0,pack:0};
  const correction=between(...aim[kind]);
  const grip=srcRoot.listNodes().find(n=>n.getMesh() && n.getName().endsWith('__hand_r') && (n.getName().includes('receiver') || n.getName().includes('repeater body')))?.getTranslation().map(v=>v*.01) || [0,0,0];
  for (const srcNode of srcRoot.listNodes()) {
    if (!srcNode.getMesh()) continue;
    const match=srcNode.getName().match(/__(hand_r|spine_03)(?:\.\d+)?$/);
    if (!match) continue;
    const bone=match[1];
    if (bone==='spine_03' && !['heavy','tech'].includes(kind)) continue;
    const name=srcNode.getName();
    // Exclude the old Officer's cape/back slab; only its sidearm transfers.
    if (kind==='officer' && bone!=='hand_r') continue;
    const mesh=copyToDocument(target,source,[srcNode.getMesh()],resolver).get(srcNode.getMesh());
    const node=target.createNode(name).setMesh(mesh);
    // Fix-4 accessories were authored on a rig with a 0.01 armature scale.
    // Bake that scale into their bone-local transforms for the Trooper rig.
    let position=srcNode.getTranslation().map(v=>v*.01);
    let rotation=srcNode.getRotation();
    if (bone==='hand_r') {
      position=rotate(correction,position.map((v,i)=>v-grip[i])).map((v,i)=>v+grip[i]);
      rotation=mul(correction,rotation);
    } else if (kind==='tech') {
      // The spine attachment is nearly vertical in shoot; 15 cm drops all
      // battery pieces below HeadTop_End without changing their grouping.
      position=[position[0]+.006,position[1]-.15,position[2]+.014];
    }
    node.setTranslation(position);
    node.setRotation(rotation);
    node.setScale(srcNode.getScale().map(v=>v*.01));
    joints.get(bone).addChild(node);
    counts[bone==='hand_r'?'weapon':'pack']+=mesh.listPrimitives().reduce((s,p)=>s+(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3,0);
  }
  return counts;
}

for (const kind of Object.keys(colors)) {
  const sourceBytes=execFileSync('git',['show',`6798e64:godot/assets/units/w17/${kind}.glb`],{maxBuffer:64*1024*1024});
  const gear=await io.readBinary(new Uint8Array(sourceBytes));
  for (const lod of [false,true]) {
    const doc=await io.read(sourceBody);
    await recolorTexture(doc,kind);
    if (lod) await doc.transform(simplify({simplifier:MeshoptSimplifier,ratio:.42,error:.025}));
    const counts=attachGear(doc,gear,kind);
    await doc.transform(unpartition());
    const path=`${output}/${kind}${lod?'_lod1':''}.glb`;
    await io.write(path,doc);
    const tris=doc.getRoot().listMeshes().reduce((s,m)=>s+m.listPrimitives().reduce((t,p)=>t+(p.getIndices()?.getCount()||p.getAttribute('POSITION').getCount())/3,0),0);
    console.log(kind,lod?'LOD1':'LOD0',tris,counts,path);
  }
}

import fs from 'fs';
import sharp from 'sharp';
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {MeshoptDecoder} from 'meshoptimizer';
import {Matrix4,Vector3} from 'three';
await MeshoptDecoder.ready;
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
for(const kind of (process.argv.slice(2).length?process.argv.slice(2):['tech','droid','officer']))for(const suffix of ['', '_lod1']){
 const path=`godot/assets/units/w17/${kind}${suffix}.glb`,doc=await io.read(path),root=doc.getRoot();
 const nodes=root.listNodes(),by=Object.fromEntries(nodes.map(n=>[n.getName(),n]));
 const hand=by.hand_r,gun=nodes.filter(n=>n.getName().endsWith('__hand_r'));
 const receiver=gun.find(n=>n.getName().includes('receiver'));
 if(!hand||!receiver||!gun.length)throw Error('missing gun grip '+path);
 const at=n=>new Vector3().setFromMatrixPosition(new Matrix4().fromArray(n.getWorldMatrix()));
 const grip=at(hand).add(new Vector3(0,-.025,.025)),delta=grip.sub(at(receiver));
 for(const n of nodes){const m=n.getName().match(/__(hand_r|spine_03|pelvis|lowerarm_l|clavicle_l|Head)$/);if(!m)continue;
  const parent=by[m[1]],world=new Matrix4().fromArray(n.getWorldMatrix());
  if(m[1]==='hand_r')world.setPosition(at(n).add(delta));
  parent.addChild(n);n.setMatrix(new Matrix4().fromArray(parent.getWorldMatrix()).invert().multiply(world).toArray());
 }
 const idle=root.listAnimations().find(a=>a.getName()==='idle');if(!idle)throw Error('missing idle '+kind);
 for(const ch of idle.listChannels()){const prop=ch.getTargetPath();if(!['rotation','translation','scale'].includes(prop))continue;
  const n=ch.getTargetNode(),v=prop==='rotation'?n.getRotation():prop==='translation'?n.getTranslation():n.getScale();
  const acc=ch.getSampler().getOutput(),arr=acc.getArray();for(let i=0;i<arr.length;i++)arr[i]=v[i%v.length];acc.setArray(arr);
 }
 if(kind!=='officer')for(const tex of root.listTextures()){
  const img=sharp(tex.getImage()),meta=await img.metadata();const {data,info}=await img.ensureAlpha().raw().toBuffer({resolveWithObject:true});
  for(let i=0;i<data.length;i+=info.channels){let r=data[i],g=data[i+1],b=data[i+2];
   if(r>g*1.16&&g>b*1.18&&r>80){let v=(r+g+b)/3,cream=v>145;
    data[i]=Math.min(255,Math.round(v*(cream?1.22:1.17)));
    data[i+1]=Math.min(255,Math.round(v*(cream?1.13:.98)));
    data[i+2]=Math.min(255,Math.round(v*(cream?.96:.73)));
   }
  }
  tex.setImage(await sharp(data,{raw:info}).webp({quality:83}).toBuffer()).setMimeType('image/webp');
  console.log('recolored',kind,suffix,meta.width,meta.height);
 }
 const temp=path+'.tmp.glb';await io.write(temp,doc);fs.renameSync(temp,path);
 let tri=0;for(const mesh of root.listMeshes())for(const p of mesh.listPrimitives())tri+=(p.getIndices()?.getCount()||0)/3;
 console.log('FINAL',kind+suffix,'triangles',Math.round(tri),'clips',root.listAnimations().length,'grip parts',gun.length);
}

import fs from 'fs';
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import {MeshoptDecoder} from 'meshoptimizer';
await MeshoptDecoder.ready;const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
const C={navy:[.04,.09,.16,1],tan:[.58,.43,.26,1],cream:[.82,.74,.58,1],steel:[.17,.22,.27,1],gold:[.72,.52,.20,1]};
for(const kind of ['tech','droid'])for(const suffix of ['', '_lod1']){
 const path=`godot/assets/units/w17/${kind}${suffix}.glb`,doc=await io.read(path),root=doc.getRoot();
 const p=root.listMeshes()[0].listPrimitives()[0],pos=p.getAttribute('POSITION'),colors=new Float32Array(pos.getCount()*4),v=[];
 for(let i=0;i<pos.getCount();i++){
  pos.getElement(i,v);const [x,y,z]=v,a=Math.abs(x);
  let key;
  if(kind==='tech'){
   if(y>1.57)key='cream';
   else if(y>1.24)key=a>.24?'cream':'tan';
   else if(y>1.08)key=a>.26?'tan':'navy';
   else if(y>.86)key=a>.25?'cream':'navy';
   else if(y>.58)key=a>.15?'navy':'tan';
   else if(y>.40)key='navy';
   else key='cream';
  }else{
   if(y>1.57)key='cream';
   else if(y>1.25)key=a>.24?'cream':'tan';
   else if(y>1.08)key=a>.26?'navy':'cream';
   else if(y>.87)key=a>.26?'tan':'navy';
   else if(y>.60)key='tan';
   else if(y>.40)key='navy';
   else key='cream';
  }
  colors.set(C[key],i*4);
 }
 const acc=doc.createAccessor('flat Temple Security panels').setType('VEC4').setArray(colors).setBuffer(root.listBuffers()[0]);
 p.setAttribute('COLOR_0',acc);p.getMaterial().setBaseColorTexture(null).setBaseColorFactor([1,1,1,1]);
 const tmp=path+'.tmp';await io.write(tmp,doc);fs.renameSync(tmp,path);console.log(kind+suffix,'flat panel vertices',pos.getCount());
}

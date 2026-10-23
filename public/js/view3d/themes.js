import {mergeGeometries} from '../../vendor/BufferGeometryUtils.js';
import {addProp} from './props.js';
// Mission themes (wave-3 contract: MISSIONS[id].theme = dock city jungle snow temple ruins plains caves).
// A theme sets the sky dome, fog, lights, board palette, scenery ringing the board, and drifting ambient particles.
// Missions without a theme get one guessed from their `where` line, so old saves still look right.
export const THEMES={
 dock:{sky:[0x0a1216,0x1b2a33],fog:[0x0d171c,26,52],hemi:[0xa8dce8,0x0b1518,1.05],key:[0xfff0dc,2.3],rim:[0x79d3e2,.8],exp:1.15,ground:0x0c1416,
  floor:['#11191d','#131d21','rgba(224,189,120,.18)','#1b262b'],wall:0x34454d,wallTop:0x46606a,trim:0xe0bd78,crate:0x6b6f72,band:0x2a2e31,metal:0x55666d,rubble:0x3a4a50,
  props:{container:10,gantry:4,light:6},part:{kind:'dust',n:120,color:0x9fb6bd}},
 city:{sky:[0x0a0a1a,0x2a1840],fog:[0x120d22,22,46],hemi:[0x9a8cff,0x10101a,.95],key:[0xffd6f0,1.9],rim:[0x5ae0ff,1.2],exp:1.2,ground:0x0b0b14,
  floor:['#12121c','#151522','rgba(255,96,190,.2)','#1d1b2b'],wall:0x2c2b3d,wallTop:0x3b3a52,trim:0xff5fbf,crate:0x5a5468,band:0x272333,metal:0x4d4a63,rubble:0x34324a,
  props:{tower:22,light:8},part:{kind:'rain',n:260,color:0x9fb0ff}},
 jungle:{sky:[0x0d1a12,0x3b5a3a],fog:[0x16261a,16,40],hemi:[0xc8f0b0,0x10200f,1.1],key:[0xfff2c8,2.0],rim:[0x9fe7a0,.6],exp:1.1,ground:0x14231a,
  floor:['#1c2b1c','#203120','rgba(160,220,140,.14)','#2a3d22'],wall:0x4a5a44,wallTop:0x5f7a4a,trim:0x9fe07f,crate:0x6d5a3a,band:0x3b3123,metal:0x56604f,rubble:0x4a5040,
  props:{tree:26,fern:30,rock:8},part:{kind:'firefly',n:70,color:0xd6ff8a}},
 snow:{sky:[0x8fa4b4,0xd8e4ec],fog:[0xc4d2dc,18,44],hemi:[0xe8f4ff,0x7a8a96,1.35],key:[0xffffff,2.1],rim:[0xa8d8ff,.5],exp:1.0,ground:0xdfe8ee,
  floor:['#c9d4dc','#d2dce3','rgba(80,120,150,.25)','#e8eef2'],wall:0x7d8f9c,wallTop:0xeef4f8,trim:0x79d3e2,crate:0x7a6544,band:0x3b3123,metal:0x6a7a84,rubble:0x9aa8b2,
  props:{pine:24,rock:12,drift:14},part:{kind:'snow',n:420,color:0xffffff}},
 temple:{sky:[0x0d0f1c,0x2a2440],fog:[0x14121e,26,52],hemi:[0xf0dcc0,0x1a1410,1.05],key:[0xffe0b0,2.4],rim:[0x79d3e2,.7],exp:1.15,ground:0x1c1712,
  floor:['#2a241c','#2f2820','rgba(224,189,120,.22)','#3a3226'],wall:0x6b5a44,wallTop:0x8a7558,trim:0xe0bd78,crate:0x6d5a3a,band:0x3b3123,metal:0x7a6a54,rubble:0x5a4c3c,
  props:{pillar:16,statue:4,brazier:6},part:{kind:'dust',n:140,color:0xffd9a0}},
 ruins:{sky:[0x3a2018,0xe09a5a],fog:[0x7a4a30,20,48],hemi:[0xffd2a0,0x2a1a10,1.1],key:[0xffb070,2.6],rim:[0xffe0c0,.5],exp:1.1,ground:0x6e5236,
  floor:['#5e4a34','#66503a','rgba(40,20,10,.3)','#73593f'],wall:0x8a6f50,wallTop:0xa88a64,trim:0xffc070,crate:0x6d5a3a,band:0x3b3123,metal:0x76624a,rubble:0x7a6448,
  props:{brokenPillar:16,rock:16},part:{kind:'dust',n:160,color:0xffd2a0}},
 plains:{sky:[0x6f9ab8,0xcfe2e0],fog:[0x9fb8b4,24,56],hemi:[0xe4f6ff,0x3a4a2a,1.25],key:[0xfff4d8,2.4],rim:[0xb8e8ff,.4],exp:1.05,ground:0x4f6a38,
  floor:['#56703c','#5c7742','rgba(30,40,20,.25)','#6b8a4a'],wall:0x7d7a6c,wallTop:0x9a9686,trim:0xe0bd78,crate:0x7a6544,band:0x3b3123,metal:0x6d6e66,rubble:0x7a7564,
  props:{tree:12,grass:60,rock:10},part:{kind:'pollen',n:90,color:0xfff2b0}},
 caves:{sky:[0x050404,0x120c08],fog:[0x0b0806,12,30],hemi:[0xc0ac9c,0x161210,1.25],key:[0xffd0a0,2.1],rim:[0xb294f5,.8],exp:1.35,ground:0x15100c,
  floor:['#2a221b','#30271f','rgba(255,170,110,.16)','#3a2f25'],wall:0x3a3028,wallTop:0x4a3d32,trim:0xb294f5,crate:0x5a4a38,band:0x2a2118,metal:0x4a4038,rubble:0x3a3028,
  props:{stalag:30,crystal:10,brazier:4},part:{kind:'ember',n:80,color:0xffa050}}};
const GUESS=[[/dock|ring|port|hangar|depot|convoy|fuel/i,'dock'],[/coruscant|nar shaddaa|lower city|vault|warehouse/i,'city'],[/dantooine|grove|plain|field|frontier|outpost/i,'plains'],
 [/cave|mine|tomb|ruusan/i,'caves'],[/ruin|ravine|cliff|balmorra|battery/i,'ruins'],[/snow|ice|hoth|ilum/i,'snow'],[/jungle|forest|yavin|kashyyyk/i,'jungle'],[/temple|shrine|sanctum/i,'temple']];
export function themeOf(M){if(M&&THEMES[M.theme])return M.theme;const w=(M&&(M.where||M.n))||'';for(const [r,t] of GUESS)if(r.test(w))return t;return 'dock'}

// Seeded random so a mission's scenery is the same every reload.
const rng=a=>()=>{a=a+0x6d2b79f5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296};
export class Scenery{
 constructor(T,scene){this.T=T;this.scene=scene;this.root=new T.Group();scene.add(this.root);this.parts=null;this.anim=[];
  const mc={};const M=(c,o={})=>{const k=c+JSON.stringify(o);return mc[k]||(mc[k]=new T.MeshStandardMaterial({color:c,roughness:.85,metalness:.1,...o}))};this.M=M;
  this.g={box:new T.BoxGeometry(1,1,1),cyl:new T.CylinderGeometry(.5,.5,1,16),cone:new T.ConeGeometry(.5,1,12),ico:new T.IcosahedronGeometry(.5,0),oct:new T.OctahedronGeometry(.5,0)}}
 apply(name,cols,rows,L,renderer){const T=this.T,th=THEMES[name]||THEMES.dock;this.name=name;this.th=th;this.root.clear();this.anim=[];
  const sc=this.scene;sc.fog=new T.Fog(th.fog[0],th.fog[1],th.fog[2]);sc.background=new T.Color(th.sky[0]);
  L.hemi.color.setHex(th.hemi[0]);L.hemi.groundColor.setHex(th.hemi[1]);L.hemi.intensity=th.hemi[2];L.key.color.setHex(th.key[0]);L.key.intensity=th.key[1];
  L.rim.color.setHex(th.rim[0]);L.rim.intensity=th.rim[1];if(renderer)renderer.toneMappingExposure=th.exp;
  // Sky dome: vertical gradient, unaffected by fog.
  const dome=new T.SphereGeometry(70,24,12),c0=new T.Color(th.sky[0]),c1=new T.Color(th.sky[1]),cols3=[];const p=dome.attributes.position;
  for(let i=0;i<p.count;i++){const k=Math.max(0,Math.min(1,.5-p.getY(i)/90));const c=c0.clone().lerp(c1,k*k);cols3.push(c.r,c.g,c.b)}
  dome.setAttribute('color',new T.Float32BufferAttribute(cols3,3));this.root.add(new T.Mesh(dome,new T.MeshBasicMaterial({vertexColors:true,side:T.BackSide,fog:false,depthWrite:false})));
  const ground=new T.Mesh(new T.CircleGeometry(60,40).rotateX(-Math.PI/2),this.M(th.ground,{roughness:1}));ground.position.y=-.41;ground.receiveShadow=true;this.root.add(ground);
  const r=rng((cols*31+rows*17+name.length*101)|0),props=[];
  for(const [k,n] of Object.entries(th.props))for(let i=0;i<n;i++){const o=this.prop(k,r,th);if(!o)continue;
   const tall=/tower|tree|pine|pillar|gantry|statue/.test(k);let x,z,n=0;do{x=(r()-.5)*(cols+(tall?22:14));z=(r()-.5)*(rows+(tall?22:14))}
   while(Math.abs(x)<cols/2+(tall?2.2:1.1)&&Math.abs(z)<rows/2+(tall?2.2:1.1)&&++n<30);if(n>=30)continue;
   o.position.set(x,-.4,z);o.rotation.y=r()*6.28;o.userData.cast=tall&&Math.abs(x)<cols/2+5&&Math.abs(z)<rows/2+5;props.push(o)}
  this.merge(props);this.particles(th.part,cols,rows)}
 // Static props → one mesh per material (+shadow flag), so ~100 props cost a handful of draw calls. Animated ones stay separate.
 merge(props){const T=this.T,live=new Set(this.anim.map(a=>a.o)),buckets=new Map();
  for(const g of props){g.updateMatrixWorld(true);g.traverse(m=>{if(!m.isMesh)return;if(live.has(m)){const c=m.clone();m.matrixWorld.decompose(c.position,c.quaternion,c.scale);this.root.add(c);this.anim.find(a=>a.o===m).o=c;return}
   const k=m.material.uuid+(g.userData.cast?'s':'');if(!buckets.has(k))buckets.set(k,{mat:m.material,cast:g.userData.cast,geos:[]});const geo=m.geometry.clone().applyMatrix4(m.matrixWorld);
   if(geo.index)buckets.get(k).geos.push(geo.toNonIndexed());else buckets.get(k).geos.push(geo)})}
  for(const b of buckets.values()){for(const g of b.geos){for(const a of Object.keys(g.attributes))if(a!=='position'&&a!=='normal'&&a!=='uv')g.deleteAttribute(a);if(!g.attributes.uv)g.setAttribute('uv',new T.Float32BufferAttribute(new Float32Array(g.attributes.position.count*2),2))}const geo=mergeGeometries(b.geos,false);if(!geo)continue;
   const o=new T.Mesh(geo,b.mat);o.castShadow=b.cast;o.receiveShadow=true;this.root.add(o)}}
 prop(k,r,th){const T=this.T,g=new T.Group(),G=this.g,M=this.M,add=(geo,m,sx,sy,sz,x=0,y=0,z=0)=>{const o=new T.Mesh(geo,m);o.scale.set(sx,sy,sz);o.position.set(x,y,z);g.add(o);return o};
  const s=.7+r()*.6;
  switch(k){
   case 'tree':{const h=2.4*s;add(G.cyl,M(0x4a3524),.25,h,.25,0,h/2);for(let i=0;i<3;i++)add(G.ico,M(i%2?0x3f6a2e:0x4f7d36),1.6*s-i*.3,1.1*s,1.6*s-i*.3,(r()-.5)*.4,h+i*.55,(r()-.5)*.4);break}
   case 'pine':{const h=.6*s;add(G.cyl,M(0x4a3524),.18,h,.18,0,h/2);for(let i=0;i<3;i++)add(G.cone,M(i?0xe8f0f4:0x2e4a3a),1.5*s-i*.4,1.2*s,1.5*s-i*.4,0,h+.5*s+i*.6*s);break}
   case 'fern':add(G.cone,M(0x3f7a34),.5*s,.5*s,.5*s,0,.25*s);add(G.cone,M(0x2f6028),.35*s,.7*s,.35*s,.2,.35*s);break;
   case 'grass':add(G.cone,M(0x6b8a3a),.18*s,.45*s,.18*s,0,.22*s);add(G.cone,M(0x7a9a42),.14*s,.35*s,.14*s,.12,.17*s);break;
   case 'rock':add(G.ico,M(th.rubble),1.1*s,.7*s,.9*s,0,.25*s);break;
   case 'drift':add(G.ico,M(0xf2f6f8),1.6*s,.4*s,1.2*s,0,.05);break;
   case 'stalag':{const h=(1+r()*2.5)*s;add(G.cone,M(th.wall),.6*s,h,.6*s,0,h/2);break}
   case 'crystal':{const h=.8*s,c=th.trim;add(G.oct,M(c,{emissive:c,emissiveIntensity:.9}),.35*s,h,.35*s,0,h/2);break}
   case 'pillar':{const h=3.2*s;if(addProp(g,'pillar',.95,h,r()*6))break;add(G.cyl,M(th.wall),.7,h,.7,0,h/2);add(G.box,M(th.wallTop),.95,.2,.95,0,h);add(G.box,M(th.wallTop),.95,.2,.95,0,.1);break}
   case 'brokenPillar':{const h=(.6+r()*2)*s;add(G.cyl,M(th.wall),.7,h,.7,0,h/2).rotation.z=(r()-.5)*.25;add(G.box,M(th.wallTop),.95,.2,.95,0,.1);
    if(r()<.4)add(G.cyl,M(th.wall),.7,1.6,.7,1.1,.35).rotation.z=Math.PI/2;break}
   case 'statue':if(addProp(g,'statue',1.2,3,0))break;add(G.box,M(th.wallTop),1,.4,1,0,.2);add(G.cone,M(th.wall),1,2.2,1,0,1.5);add(G.ico,M(th.wall),.5,.55,.5,0,2.8);break;
   case 'brazier':{if(!addProp(g,'brazier',.6,.9,r()*6))add(G.cyl,M(0x3a3028),.4,.8,.4,0,.4);const f=add(G.ico,M(0xffa040,{emissive:0xff7a20,emissiveIntensity:2}),.35,.45,.35,0,.95);this.anim.push({o:f,flick:1});break}
   case 'container':{if(addProp(g,'container',2.4,1.1,0))break;const c=[0x8a4a2a,0x2a5a7a,0x6a6f74,0x7a6a2a][Math.floor(r()*4)];add(G.box,M(c,{metalness:.4}),2.4,1.1,1,0,.55);if(r()<.5)add(G.box,M(c,{metalness:.4}),2.4,1.1,1,0,1.65).rotation.y=.1;break}
   case 'gantry':{const h=4.5*s;if(addProp(g,'gantry',2.8,h,0))break;for(const x of [-1.2,1.2])add(G.box,M(th.metal,{metalness:.5}),.25,h,.25,x,h/2);add(G.box,M(0xe0bd78,{metalness:.4}),2.8,.3,.4,0,h);break}
   case 'light':{add(G.cyl,M(th.metal),.12,2.6,.12,0,1.3);add(G.box,M(th.trim,{emissive:th.trim,emissiveIntensity:1.6}),.35,.12,.35,0,2.65);break}
   case 'tower':{const h=(4+r()*12)*s,w=1.6+r()*2;add(G.box,M(th.wall,{metalness:.3}),w,h,w,0,h/2);
    for(let y=1;y<h-.5;y+=1.1)if(r()<.7)add(G.box,M(r()<.5?0xffd27a:th.trim,{emissive:r()<.5?0xffb050:th.trim,emissiveIntensity:1.2}),w+.04,.12,w*.6,0,y);break}
   default:return null}
  return g}
 particles(o,cols,rows){const T=this.T;if(!o)return;const n=o.n,pos=new Float32Array(n*3),vel=new Float32Array(n*3),W=cols+10,D=rows+10;
  for(let i=0;i<n;i++){pos[i*3]=(Math.random()-.5)*W;pos[i*3+1]=Math.random()*6;pos[i*3+2]=(Math.random()-.5)*D;vel[i*3]=Math.random()*6.28}
  const g=new T.BufferGeometry();g.setAttribute('position',new T.BufferAttribute(pos,3));
  const c=document.createElement('canvas');c.width=c.height=32;const x=c.getContext('2d'),gr=x.createRadialGradient(16,16,0,16,16,16);
  gr.addColorStop(0,'rgba(255,255,255,1)');gr.addColorStop(.4,'rgba(255,255,255,.5)');gr.addColorStop(1,'rgba(255,255,255,0)');x.fillStyle=gr;x.fillRect(0,0,32,32);
  const add=/firefly|ember|pollen/.test(o.kind),size={snow:.09,rain:.05,dust:.05,firefly:.12,ember:.08,pollen:.06}[o.kind]||.06;
  const m=new T.PointsMaterial({color:o.color,size,map:new T.CanvasTexture(c),transparent:true,opacity:o.kind==='rain'?.5:.85,depthWrite:false,blending:add?T.AdditiveBlending:T.NormalBlending});
  const pts=new T.Points(g,m);pts.frustumCulled=false;this.root.add(pts);this.parts={pts,pos,vel,n,W,D,kind:o.kind}}
 update(dt,t){for(const a of this.anim)if(a.flick)a.o.scale.y=.45*(.85+.25*Math.sin(t*17+a.o.id)+.1*Math.sin(t*41));
  const P=this.parts;if(!P)return;const {pos,vel,n,W,D,kind}=P;
  const fall={snow:.6,rain:9,dust:.05,firefly:0,ember:-.4,pollen:.05}[kind]||0;
  for(let i=0;i<n;i++){const j=i*3,ph=vel[j];
   if(kind==='firefly'||kind==='pollen'||kind==='dust'){pos[j]+=Math.sin(t*.5+ph)*dt*.25;pos[j+2]+=Math.cos(t*.4+ph*1.3)*dt*.25;pos[j+1]+=Math.sin(t*.7+ph)*dt*.12-fall*dt}
   else{pos[j+1]-=fall*dt;if(kind==='snow'){pos[j]+=Math.sin(t+ph)*dt*.3;pos[j+2]+=dt*.15}}
   if(pos[j+1]<0)pos[j+1]+=6;if(pos[j+1]>6)pos[j+1]-=6;if(pos[j+2]>D/2)pos[j+2]-=D}
  P.pts.geometry.attributes.position.needsUpdate=true;if(kind==='firefly'||kind==='ember')P.pts.material.opacity=.6+.3*Math.sin(t*3)}
}

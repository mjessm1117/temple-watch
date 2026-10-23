// Low-poly unit figures built from primitives (no model files): Jedi with glowing sabers in the unit color,
// Republic troopers in white/red, Sith in black/red, a hulking Terentatek. Each figure stands on a miniature base
// (round = yours, square = enemy) and animates through small tweens: walk, aim, swing, hit flash, knockback, fall, lift, leap.
const KIND={
 jedi:{body:0xcdb58a,robe:0x5b402c,skin:0xc99f7c,weapon:'saber',belt:0x3a2a1e},
 trooper:{body:0xe3e6e8,accent:0xa8322b,helm:1,visor:0x15232b,weapon:'blaster',pads:1},
 scout:{body:0xd7dcd8,accent:0xa8322b,helm:1,visor:0x15232b,weapon:'rifle',pads:1},
 medic:{body:0xe3e6e8,accent:0x7fd99a,helm:1,visor:0x15232b,weapon:'pistol',pads:1,pack:1},
 heavy:{body:0xd5d9dc,accent:0xa8322b,helm:1,visor:0x15232b,weapon:'cannon',pads:1,bulk:1.18},
 sith:{body:0x34343d,accent:0xb32222,helm:1,visor:0xff3b2e,glowVisor:1,weapon:'blaster',pads:1},
 sithHeavy:{body:0x2c2c34,accent:0xb32222,helm:1,visor:0xff3b2e,glowVisor:1,weapon:'cannon',pads:1,bulk:1.25},
 agent:{body:0x39424a,robe:0x2a3036,skin:0xb08a6a,weapon:'rifle',belt:0x6a1f1f,short:1},
 acolyte:{body:0x2a1e24,robe:0x121216,skin:0x8f8f96,weapon:'saber',saber:0xff3b2e,hood:1,belt:0x5a1414},
 envoy:{body:0x8a8f96,robe:0x5d636b,skin:0xc29a7a,weapon:'pistol',belt:0x3d4248},
 civ:{body:0x8a7a5a,robe:0x6d6047,skin:0xc29a7a,weapon:null,belt:0x7fd99a,short:1}};
const ENEMY={e_trooper:'sith',e_heavy:'sithHeavy',e_agent:'agent',e_acolyte:'acolyte',e_horror:'beast',e_envoy:'envoy'},BYTYPE={nihil_raider:'nihilRaider',path_runner:'nihilRaider',nihil_storm:'nihilStorm',marchion_ro:'marchionRo',lourna_dee:'lournaDee',lourna_ret:'lournaDee',drengir:'drengir',great_progenitor:'drengir',root_mother:'drengir',nameless:'nameless',leveler:'nameless',malgus:'malgus',mando:'mando',bh_trooper:'bhTrooper',bh_sniper:'sniper',bh_marauder:'marauder',sith_lord:'sithLord',kaan:'kaan',bane:'bane',
 sith_spawn:'spawn',nexus:'nexus',nexus_core:'nexusCore'};
// Later eras: names pick a look when the icon is generic (e.g. Brotherhood Sith Lords get robes and red sabers).
const byName=n=>/sith lord|marauder|kaan|bane|dark acolyte|nightsister/i.test(n||'')?'acolyte':/sniper|bounty|agent/i.test(n||'')?'agent':/mandalorian/i.test(n||'')?'mando':null;
export const kindOf=u=>u.vip?'civ':u.jedi?(u.cls==='Defender'?'defender':'jedi'):u.side==='e'?(BYTYPE[u.type]||(u.nexus?'nexus':null)||(u.horror?'beast':null)||byName(u.n)||ENEMY[u.ic]||'sith'):({Scout:'scout',Medic:'medic',Heavy:'heavy',Shieldbearer:'shieldbearer'}[u.cls]||'trooper');
// Block-figure stand-ins for kinds that only exist as rigged models.
const BLOCK={drengir:'agent',nameless:'acolyte',defender:'jedi',shieldbearer:'trooper',nihilRaider:'agent',nihilStorm:'sithHeavy',marchionRo:'sithHeavy',lournaDee:'agent',malgus:'acolyte',mando:'trooper',bhTrooper:'sith',sniper:'agent',marauder:'acolyte',sithLord:'acolyte',kaan:'acolyte',bane:'acolyte'};
export const isNexus=k=>k==='nexus'||k==='nexusCore';
let WHITE;const lerp=(a,b,k)=>a+(b-a)*k,sm=k=>k*k*(3-2*k);

export class UV{
 constructor(U,u){this.U=U;this.T=U.T;this.uid=u.uid;this.u=u;this.kind=kindOf(u);this.mats=[];this.tw=[];this.flashK=0;this.knockV=new this.T.Vector3();
  this.vx=u.x;this.vy=u.y;this.state=u.status==='down'?'down':'ok';this.lie=this.state==='down'?1:0;this.lieAxis=new this.T.Vector3(1,0,0);this.face=u.side==='e'?0:Math.PI;
  this.root=new this.T.Group();this.body=new this.T.Group();this.root.add(this.body);this.p={};this.build();this.base();
  this.root.position.copy(U.board.pos(u.x,u.y));this.sc=this.kind==='beast'?1.3:1.18;this.root.scale.setScalar(this.sc);this.headY*=this.sc;U.scene.add(this.root);this.pose={armR:0,legs:0,lift:0,lunge:0,flail:0}}
 mat(c,o={}){const m=new this.T.MeshStandardMaterial({color:c,roughness:.65,metalness:.2,...o});m.userData.e0=m.emissive.clone();this.mats.push(m);return m}
 part(parent,geo,m,sx,sy,sz,x=0,y=0,z=0){const o=new this.T.Mesh(geo,m);o.scale.set(sx,sy,sz);o.position.set(x,y,z);o.castShadow=true;parent.add(o);return o}
 pivot(parent,x,y,z=0){const g=new this.T.Group();g.position.set(x,y,z);parent.add(g);return g}
 build(){if(this.kind==='beast'||this.kind==='spawn')return this.buildBeast();if(isNexus(this.kind))return this.buildNexus();const K=KIND[BLOCK[this.kind]||this.kind]||KIND.sith,G=this.U.geo,b=this.body,bulk=K.bulk||1;
  const mb=this.mat(K.body),ma=this.mat(K.accent||K.belt||K.body),ms=this.mat(K.skin||0xc99f7c),mr=K.robe?this.mat(K.robe):null;
  const legM=K.helm?mb:mr||mb;
  for(const s of [-1,1]){const l=this.pivot(b,s*.085*bulk,.47);this.part(l,G.box,legM,.12*bulk,.46,.13*bulk,0,-.23);this.part(l,G.box,ma,.13*bulk,.07,.15*bulk,0,-.43,.01);this.p[s<0?'legL':'legR']=l}
  this.part(b,G.box,mb,.34*bulk,.38,.21*bulk,0,.68);this.part(b,G.box,ma,.36*bulk,.06,.22*bulk,0,.5);
  if(mr)this.part(b,G.robe,mr,.25*bulk,K.short?.3:.48,.23*bulk,0,K.short?.42:.3);
  if(K.helm){this.part(b,G.box,mb,.23,.23,.25,0,.98);this.part(b,G.box,K.glowVisor?this.mat(K.visor,{emissive:K.visor,emissiveIntensity:1.6}):this.mat(K.visor),.19,.06,.05,0,.99,.12);
   }
  else{this.part(b,G.ico,ms,.12,.13,.12,0,.98);if(K.hood){this.part(b,G.cone,mr,.17,.3,.17,0,1.08);this.part(b,G.box,this.mat(0x050506),.14,.12,.04,0,.96,.1)}
   else if(this.kind==='jedi')this.part(b,G.ico,this.mat(K.belt),.125,.08,.125,0,1.05,-.01)}
  if(K.pack)this.part(b,G.box,this.mat(0xf2f2f2),.24,.26,.12,0,.72,-.15);
  if(K.pads)for(const s of [-1,1])this.part(b,G.box,ma,.14*bulk,.07,.15*bulk,s*.23*bulk,.88);
  for(const s of [-1,1]){const a=this.pivot(b,s*.225*bulk,.84);this.part(a,G.box,legM===mr?mr:mb,.1*bulk,.4,.11*bulk,0,-.2);this.part(a,G.box,ms,.08,.07,.08,0,-.41);this.p[s<0?'armL':'armR']=a}
  const w=this.pivot(this.p.armR,0,-.42);this.p.weapon=w;const mw=this.mat(0x2b2f33,{metalness:.6});
  switch(K.weapon){
   case 'saber':{this.part(w,G.cyl,this.mat(0xb8bcc0,{metalness:.8}),.026,.17,.026,0,0);const col=new this.T.Color(K.saber||this.U.color(this.u));
    const blade=this.pivot(w,0,-.08);this.p.blade=blade;
    const core=new this.T.Mesh(G.cyl,new this.T.MeshBasicMaterial({color:col.clone().lerp(new this.T.Color(0xffffff),.4)}));core.scale.set(.02,.82,.02);core.position.y=-.41;blade.add(core);
    for(const [r,o] of [[.05,.7],[.1,.25]]){const g=new this.T.Mesh(G.cyl,new this.T.MeshBasicMaterial({color:col,transparent:true,opacity:o,blending:this.T.AdditiveBlending,depthWrite:false}));
     g.scale.set(r,.86,r);g.position.y=-.41;g.userData.o=o;blade.add(g);(this.glows||(this.glows=[])).push(g)}
    w.rotation.x=-1.55;break}
   case 'rifle':this.part(w,G.box,mw,.05,.56,.07,0,-.14);this.part(w,G.box,mw,.04,.12,.09,0,.06,-.03);break;
   case 'cannon':this.part(w,G.box,mw,.11,.42,.12,0,-.1);this.part(w,G.cyl,mw,.035,.3,.035,0,-.42);this.part(w,G.box,this.mat(K.accent),.12,.06,.13,0,.03);break;
   case 'pistol':this.part(w,G.box,mw,.05,.18,.07,0,-.06);break;
   case 'blaster':this.part(w,G.box,mw,.06,.34,.08,0,-.1);this.part(w,G.box,mw,.04,.1,.08,0,.04,-.03);break}
  this.headY=1.2;this.idleArm=K.weapon==='saber'?-.7:K.weapon==='rifle'||K.weapon==='cannon'?-.9:-.15}
 // Dark Nexus (Era 2): an immobile rift of black-violet crystals over a cracked basin; the core is bigger.
 buildNexus(){const G=this.U.geo,b=this.body,core=this.kind==='nexusCore',k=core?1.35:1,T=this.T,dark=this.mat(0x1a1020,{metalness:.5,roughness:.3}),
  glow=this.mat(0x8a4dff,{emissive:0x8a4dff,emissiveIntensity:2.2}),rock=this.mat(0x2a2228);this.static=1;this.p.spin=this.pivot(b,0,0);
  this.part(b,G.ico,rock,.55*k,.12,.55*k,0,.06);for(let i=0;i<7;i++){const a=i/7*6.28,r=i?.24*k:0,h=(i?.5:.95)*k;const c=this.part(this.p.spin,G.cone,i%2?glow:dark,.09*k+(!i)*.06,h,.09*k+(!i)*.06,Math.cos(a)*r,h/2+.08,Math.sin(a)*r);c.rotation.z=i?Math.cos(a)*.35:0;c.rotation.x=i?Math.sin(a)*.35:0}
  const ring=new T.Mesh(new T.TorusGeometry(.42*k,.025,6,28),new T.MeshBasicMaterial({color:0xb294f5,transparent:true,opacity:.7,blending:T.AdditiveBlending,depthWrite:false}));ring.rotation.x=Math.PI/2;ring.position.y=.6*k;b.add(ring);this.p.ring=ring;
  this.headY=1.2*k;this.idleArm=0}
 buildBeast(){const G=this.U.geo,b=this.body,mb=this.mat(0x4d3a2c),md=this.mat(0x2e221a),mh=this.mat(0xd8cbb0),me=this.mat(0xff3b2e,{emissive:0xff3b2e,emissiveIntensity:2});
  if(this.kind==='spawn'){mb.color.setHex(0x8a8592);md.color.setHex(0x4a3f58)}
  this.part(b,G.ico,mb,.48,.42,.62,0,.78,-.05);this.part(b,G.ico,md,.34,.3,.4,0,1.02,-.22);
  const h=this.pivot(b,0,.86,.48);this.p.head=h;this.part(h,G.box,mb,.4,.34,.38,0,0,.1);this.part(h,G.box,md,.36,.12,.3,0,-.17,.14);
  for(const s of [-1,1]){this.part(h,G.cone,mh,.06,.3,.06,s*.17,.08,.2).rotation.set(1.2,0,s*.5);this.part(h,G.box,me,.06,.04,.03,s*.1,.06,.29)}
  for(const [i,x,z] of [[0,-.28,.32],[1,.28,.32],[2,-.28,-.36],[3,.28,-.36]]){const l=this.pivot(b,x,.62,z);this.part(l,G.box,md,.17,.6,.18,0,-.3);this.part(l,G.cone,mh,.05,.12,.05,0,-.62,.1).rotation.x=Math.PI;this.p['leg'+i]=l}
  this.headY=1.25;this.idleArm=0}
 base(){const T=this.T,G=this.U.geo,e=this.u.side==='e',col=new T.Color(this.U.color(this.u));
  const d=new T.Mesh(e?G.sq:G.disc,new T.MeshStandardMaterial({color:0x0c1416,roughness:.6}));d.position.y=.025;d.receiveShadow=true;this.root.add(d);
  const r=new T.Mesh(e?G.sqRing:G.ring,new T.MeshBasicMaterial({color:col}));r.position.y=.053;this.root.add(r);this.ringM=r.material;
  this.sel=new T.Mesh(e?G.sqSel:G.sel,new T.MeshBasicMaterial({color:e?col:0x79d3e2,transparent:true,opacity:.9,depthWrite:false}));this.sel.position.y=.06;this.sel.visible=false;this.root.add(this.sel);
  this.halo=new T.Mesh(G.halo,new T.MeshBasicMaterial({color:0x79d3e2,transparent:true,opacity:.13,depthWrite:false,side:T.DoubleSide,blending:T.AdditiveBlending}));
  this.halo.position.y=.6;this.halo.visible=false;this.root.add(this.halo);
  this.bleed=new T.Mesh(G.sel,new T.MeshBasicMaterial({color:0xef6a5d,transparent:true,opacity:.7,depthWrite:false}));this.bleed.position.y=.06;this.bleed.visible=false;this.root.add(this.bleed)}
 busy(){return this.tw.length>0}
 ghost(on){if(this.ghosted===on)return;this.ghosted=on;for(const m of this.mats){m.transparent=on||!!m.userData.tr;m.opacity=on?.45:1;m.depthWrite=!on;m.needsUpdate=true}}
 add(d,fn,done){this.tw.push({t:0,d:Math.max(.001,d),fn,done})}
 faceTo(p){const r=this.root.position;if(Math.hypot(p.x-r.x,p.z-r.z)>.01)this.face=Math.atan2(p.x-r.x,p.z-r.z)}
 walk(pts,tile){const per=this.U.reduce?.06:.17,segs=pts.length-1;if(segs<1){this.setTile(tile);return 0}
  this.add(per*segs,k=>{const f=Math.min(segs-.0001,k*segs),i=Math.floor(f),a=pts[i],b=pts[i+1];this.root.position.lerpVectors(a,b,f-i);if(a.distanceTo(b)>1.5)this.root.position.y+=Math.sin((f-i)*Math.PI)*.6;this.faceTo(b);this.pose.legs=Math.sin(k*segs*Math.PI*2)},
   ()=>{this.pose.legs=0;this.setTile(tile)});return per*segs*1000}
 setTile(t){this.vx=t.x;this.vy=t.y;this.root.position.copy(this.U.board.pos(t.x,t.y))}
 aim(at,d=.55){this.faceTo(at);if(this.kind==='beast')return;this.add(d,k=>{this.pose.armR=k<.7?-1.5*sm(Math.min(1,k*4)):-1.5*(1-sm((k-.7)/.3))-.001},()=>{this.pose.armR=0})}
 swing(at){this.faceTo(at);if(this.kind==='beast'){this.add(.32,k=>{this.pose.lunge=Math.sin(k*Math.PI)*.45},()=>{this.pose.lunge=0});return}
  this.add(.34,k=>{this.pose.armR=k<.35?lerp(0,-2.4,sm(k/.35)):lerp(-2.4,1.1,sm((k-.35)/.65))},()=>{this.pose.armR=0})}
 flash(){this.flashK=1}
 shoot(at){this.aim(at,.6)} cast(at,d=.7){if(at)this.aim(at,d)} throwAt(at){this.aim(at,.5)} use(at){if(at)this.faceTo(at)} block(){} hitAnim(){} cheer(){}
 knock(from,amt=.28){const r=this.root.position;this.knockV.set(r.x-from.x,0,r.z-from.z).normalize().multiplyScalar(amt)}
 fall(state,from){this.state=state;const r=this.root.position,dx=from?r.x-from.x:0,dz=from?r.z-from.z:1;this.lieAxis.set(dz,0,-dx).normalize();
  if(!this.lieAxis.lengthSq())this.lieAxis.set(1,0,0);const d=state==='dead'?.62:.8;
  this.add(d,k=>{this.lie=state==='dead'?(k<.8?sm(k/.8)*1.08:1.08-.08*Math.sin((k-.8)/.2*Math.PI)):sm(k);this.pose.flail=state==='dead'?Math.sin(k*Math.PI):0},
   ()=>{this.pose.flail=0;if(state==='dead')this.corpse()});return d*1000}
 // Bodies stay for the whole mission: darkened, blade off, base ring dimmed. Past 24 bodies the oldest sinks away.
 corpse(){if(this.isCorpse||this.gone)return;this.isCorpse=1;for(const m of this.mats){if(m.userData.c0==null)m.userData.c0=m.color.getHex();m.color.multiplyScalar(.5);m.emissive&&m.emissive.multiplyScalar(.2)}
  if(this.glows)for(const g of this.glows)g.visible=false;if(this.p.blade)this.p.blade.visible=false;this.root.traverse(o=>{if(o.userData.blade)o.visible=false});
  this.ringM.opacity=.25;this.ringM.transparent=true;this.sel.visible=this.halo.visible=this.bleed.visible=false;this.U.bodies.push(this);
  const old=this.U.bodies.filter(b=>!b.gone);if(old.length>24)old[0].sink();this.frozen=1}
 sink(){this.add(.9,k=>{this.root.position.y=-k*.5;this.root.scale.setScalar(this.sc*(1-k*.6))},()=>{this.root.visible=false;this.gone=1})}
 stand(){this.state='ok';const s=this.lie;this.add(.5,k=>{this.lie=s*(1-sm(k))})}
 lift(d=.9){this.add(d,k=>{this.pose.lift=k<.3?sm(k/.3)*.5:k<.8?.5+Math.sin(k*40)*.02:.5*(1-sm((k-.8)/.2));this.pose.legs=k<.8?Math.sin(k*30)*.5:0})}
 leap(a,b,tile){const d=this.U.reduce?.2:.55;this.faceTo(b);this.add(d,k=>{this.root.position.lerpVectors(a,b,sm(k));this.root.position.y=Math.sin(k*Math.PI)*1.2},()=>{this.root.position.y=0;this.setTile(tile)});return d*1000}
 update(dt,t){for(const w of [...this.tw]){w.t+=dt;const k=Math.min(1,w.t/w.d);w.fn(k);if(k>=1){this.tw.splice(this.tw.indexOf(w),1);if(w.done)w.done()}}
  const P=this.p,po=this.pose,b=this.body;let dy=b.rotation.y-this.face;while(dy>Math.PI)dy-=Math.PI*2;while(dy<-Math.PI)dy+=Math.PI*2;b.rotation.y-=dy*Math.min(1,dt*12);
  this.knockV.multiplyScalar(Math.max(0,1-dt*7));b.position.set(this.knockV.x,po.lift||0,this.knockV.z);
  if(po.lunge){b.position.x+=Math.sin(b.rotation.y)*po.lunge;b.position.z+=Math.cos(b.rotation.y)*po.lunge}
  const breathe=Math.sin(t*2+this.uid)*.012;
  if(this.static){P.spin.rotation.y+=dt*.6;P.ring.rotation.z+=dt*1.4;P.ring.position.y=this.headY*.5+Math.sin(t*2)*.06;P.spin.scale.setScalar(1+.04*Math.sin(t*3))}
  else if(this.kind==='beast'||this.kind==='spawn'){for(let i=0;i<4;i++)P['leg'+i].rotation.x=(po.legs||0)*.6*(i%3?1:-1);P.head.rotation.x=Math.sin(t*1.5+this.uid)*.06-(po.lunge||0)*.4;b.position.y+=breathe}
  else{const L=po.legs||0;P.legL.rotation.x=L*.6;P.legR.rotation.x=-L*.6;P.armL.rotation.x=-L*.4+(this.idleArm<-.5?-.6:0)+(po.flail||0)*-2;P.armL.rotation.z=-(po.flail||0)*.8;
   P.armR.rotation.x=(po.armR||0)+(po.armR?0:this.idleArm)+L*.3+(po.flail||0)*-2.4;P.armR.rotation.z=(po.flail||0)*.8;b.position.y+=breathe;b.rotation.z=0;
  }
  // Lying down: tip the whole figure over the fall axis, pivoting at the feet.
  const q=this.lie;this.root.quaternion.setFromAxisAngle(this.lieAxis,q*Math.PI/2*(this.kind==='beast'?.95:1));
  if(this.flashK>0){this.flashK=Math.max(0,this.flashK-dt*5);for(const m of this.mats)m.emissive.copy(m.userData.e0).lerp(WHITE,this.flashK*.85)}
  if(this.glows)for(const g of this.glows)g.material.opacity=g.userData.o*(.85+.15*Math.sin(t*23+this.uid));
  if(this.sel.visible){const s=1+.06*Math.sin(t*4);this.sel.scale.set(s,1,s)}
  if(this.bleed.visible)this.bleed.material.opacity=.35+.35*Math.sin(t*5)}
}
export class Units{
 constructor(THREE,scene,board,color){this.T=THREE;this.scene=scene;this.board=board;this.color=color;this.map=new Map();this.reduce=false;const T=THREE;
  this.geo={box:new T.BoxGeometry(1,1,1),ico:new T.IcosahedronGeometry(1,0),cyl:new T.CylinderGeometry(1,1,1,8),cone:new T.ConeGeometry(1,1,7),
   robe:new T.CylinderGeometry(.62,1,1,8),disc:new T.CylinderGeometry(.38,.4,.05,28),ring:new T.RingGeometry(.32,.39,32).rotateX(-Math.PI/2),sel:new T.RingGeometry(.44,.5,36).rotateX(-Math.PI/2),
   sq:new T.BoxGeometry(.68,.05,.68),sqRing:new T.RingGeometry(.38,.46,4,1,Math.PI/4).rotateX(-Math.PI/2),sqSel:new T.RingGeometry(.52,.58,4,1,Math.PI/4).rotateX(-Math.PI/2),
   halo:new T.CylinderGeometry(.46,.46,1.2,28,1,true)};
  WHITE=this.white=new T.Color(1,1,1);this.bodies=[]}
 // Swap block figures for rigged ones once their model file has loaded (skips anything mid-animation or dead).
 upgrade(){if(!this.Rig)return;for(const [id,v] of this.map){if(v instanceof this.Rig||v.gone||v.state==='dead'||v.busy()||!this.Rig.can(v.u))continue;
  const pos=v.root.position.clone();this.scene.remove(v.root);const n=new this.Rig(this,v.u);n.root.position.copy(pos);n.face=n.body.rotation.y=v.face;n.vx=v.vx;n.vy=v.vy;this.map.set(id,n)}}
 get(u){let v=this.map.get(u.uid);if(!v){v=this.Rig&&this.Rig.can(u)?new this.Rig(this,u):new UV(this,u);this.map.set(u.uid,v)}v.u=u;return v}
 clear(){for(const v of this.map.values())this.scene.remove(v.root);this.map.clear();this.bodies=[]}
 busy(){for(const v of this.map.values())if(v.busy())return true;return false}
 // Bring every figure in line with S (only called when no event animation is pending).
 reconcile(units){const seen=new Set();
  for(const u of units){if(u.status==='dead'&&!this.map.has(u.uid))continue;if(u.status==='captured'&&!this.map.has(u.uid))continue;
   const v=this.get(u);seen.add(u.uid);if(v.gone)continue;v.root.visible=!u.hid;
   if(u.status==='dead'||u.status==='captured'){if(v.state!=='dead'&&!v.busy()){if(u.status==='captured')v.sink(),v.state='dead';else v.fall('dead',null)}continue}
   if(!v.busy()){if(v.vx!==u.x||v.vy!==u.y)v.walk([v.root.position.clone(),this.board.pos(u.x,u.y)],u);
    if(u.status==='down'&&v.state!=='down')v.fall('down',null);else if(u.status!=='down'&&v.state==='down')v.stand()}
}
  for(const [id,v] of this.map)if(!seen.has(id)){this.scene.remove(v.root);this.map.delete(id)}}
 // Selection ring, Guard/Barrier halo, bleeding ring: follow S right away.
 marks(sel,peek){for(const v of this.map.values()){const u=v.u;v.sel.visible=!v.gone&&((u===sel&&!peek)||u===peek);
   v.halo.visible=!!(u.guard||u.barrier||u.hunker)&&u.status==='ok';v.halo.material.color.setHex(u.barrier?0x7fd99a:0x79d3e2);v.bleed.visible=u.status==='down'&&!u.stable&&v.state==='down'}}
 update(dt,t){for(const v of this.map.values())if(!v.gone)v.update(dt,t)}
 anchor(u){const v=this.map.get(u.uid);if(!v||v.gone||!v.root.visible)return null;const p=v.root.position.clone();p.y=(v.state==='ok'?v.headY:.5)+(v.pose.lift||0)*v.sc;return p}
}

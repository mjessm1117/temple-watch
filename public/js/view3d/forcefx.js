// One distinct look per Force ability (and the melee saber techniques). Called from main.js abilityFx() with
// c = {k, u (caster view), tv (target view or null), from, tp (target point or null), fx3, T, rig, reduce, color}.
// Returns ms the event queue waits, or null if the ability has no Force look here.
// Color language: blue = telekinesis, gold = mind, green = life, violet = stasis/dark, saber techniques in the caster's blade color.
const sm=k=>k*k*(3-2*k);
let GEO=null;
function geo(T){return GEO||(GEO={ring:new T.TorusGeometry(1,.04,6,40).rotateX(Math.PI/2),dome:new T.SphereGeometry(1,24,12,0,Math.PI*2,0,Math.PI/2),
 col:new T.CylinderGeometry(1,1,1,20,1,true),cres:new T.RingGeometry(.55,.8,24,1,0,Math.PI*1.2).rotateX(-Math.PI/2),
 cube:new T.BoxGeometry(1,1,1),oct:new T.OctahedronGeometry(1,0),spark:new T.SphereGeometry(1,8,6)})}
const add=(c,m,geo,d,fn)=>{const o=new c.T.Mesh(geo,m);c.fx3.add(o,d,k=>fn(o,k),()=>{c.fx3.scene.remove(o);m.dispose()});return o};
const mat=(c,col,op=.8)=>c.fx3.basic(col,op);

// Primitives
function dome(c,p,col,r,d){const m=mat(c,col,.35);m.side=c.T.DoubleSide;return add(c,m,geo(c.T).dome,d,(o,k)=>{o.position.copy(p).setY(p.y-.75);o.scale.setScalar(r*(.4+.6*sm(Math.min(1,k*3))));m.opacity=.35*(1-Math.max(0,k-.6)/.4)})}
function pillar(c,p,col,r,h,d,down){const m=mat(c,col,.5);m.side=c.T.DoubleSide;return add(c,m,geo(c.T).col,d,(o,k)=>{const f=down?sm(Math.min(1,k*2.5)):1;
 o.scale.set(r*(1-k*.5),h*f,r*(1-k*.5));o.position.copy(p).setY(down?h-h*f/2:h/2);m.opacity=.55*(1-k)})}
function groundRings(c,p,col,n,r1,d,gap=.12){for(let i=0;i<n;i++){const m=mat(c,col,.8);add(c,m,geo(c.T).ring,d,(o,k)=>{const q=Math.max(0,Math.min(1,(k*d-i*gap)/(d-i*gap)));
 o.position.copy(p).setY(.06);o.scale.setScalar(.2+q*r1);m.opacity=q>0?.8*(1-q):0})}}
function spiral(c,p,col,h,d,n=26,r=.5,up=1){const G=c.fx3.glow;let acc=0,i=0;c.fx3.add(null,d,(k,dt)=>{acc+=dt;while(acc>d/n&&i<n){acc-=d/n;i++;const a=i*.9,y=up?(i/n)*h:h-(i/n)*h,
 q=p.clone().add(new c.T.Vector3(Math.cos(a)*r*(1-i/n*.5),y,Math.sin(a)*r*(1-i/n*.5)));G.emit(q,2,{color:col,spread:.15,life:.55,size:.09,grav:0})}})}
function crescent(c,p,col,face,d=.28,big=1){const m=mat(c,col,.9);m.side=c.T.DoubleSide;return add(c,m,geo(c.T).cres,d,(o,k)=>{o.position.copy(p).setY(.9);o.rotation.y=face+(k-.5)*2.6;o.scale.setScalar(big*(.9+k*.3));m.opacity=.9*(1-k)})}
function beam(c,a,b,col,d,w=.05){const T=c.T,dir=b.clone().sub(a),len=dir.length(),m=mat(c,col,.9),o=new T.Mesh(geo(T).col,m);
 o.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),dir.clone().normalize());c.fx3.add(o,d,k=>{o.position.copy(a).addScaledVector(dir,.5);o.scale.set(w*(1-k),len,w*(1-k));m.opacity=.9*(1-k)},()=>{c.fx3.scene.remove(o);m.dispose()})}
function stream(c,a,b,col,d,n=30,size=.08){const G=c.fx3.glow;let acc=0;c.fx3.add(null,d,(k,dt)=>{acc+=dt;if(acc<.02)return;acc=0;for(let i=0;i<Math.ceil(n*.02/d);i++){
 const f=Math.random(),q=a.clone().lerp(b,f);G.emit(q,1,{color:col,spread:.3,life:.25,size,grav:0,vx:(b.x-a.x)*1.5,vz:(b.z-a.z)*1.5,vy:(b.y-a.y)*1.5})}})}

const FX={
 // Telekinesis (blue)
 push:c=>{c.u.cast(c.tp,.5);const w=c.fx3.wave(c.from.clone().setY(.8),c.tp,0x9fe7ff);stream(c,c.from.clone().setY(.9),c.tp,0x9fe7ff,.35,40);return w},
 pull:c=>{c.u.cast(c.tp,.6);c.fx3.wave(c.tp,c.from.clone().setY(.8),0x7fc8ff);stream(c,c.tp,c.from.clone().setY(.9),0x7fc8ff,.45,40);c.fx3.ring(c.tp,0x7fc8ff,1.2,.2,.4,.6);return 420},
 collapse:c=>{c.u.cast(c.tp,.8);const top=c.tp.clone().setY(2.4);stream(c,c.from.clone().setY(1.2),top,0x9fe7ff,.3,20);
  setTimeout(()=>{c.fx3.debris(top,18,0x3a4a50);c.fx3.puff(c.tp.clone().setY(.4),22,0x4a5559);if(!c.reduce)c.rig.shake(.18)},250);return 520},
 tremor:c=>{c.u.cast(c.tp,.7);const p=c.tp.clone().setY(0);groundRings(c,p,0xc8a070,4,1.8,.7);if(!c.reduce)c.rig.shake(.3);
  for(let i=0;i<10;i++){const q=p.clone().add(new c.T.Vector3((Math.random()-.5)*2.6,.1,(Math.random()-.5)*2.6));c.fx3.puff(q,3,0x7a6a54)}c.fx3.debris(p.clone().setY(.2),8,0x6a5a48);return 620},
 forceWave:c=>{c.u.cast(null,.7);const p=c.from.clone().setY(0);groundRings(c,p,0x9fe7ff,3,2.8,.55,.08);dome(c,c.from.clone().setY(.8),0x9fe7ff,2.4,.55);
  c.fx3.glow.emit(p.clone().setY(.6),50,{color:0x9fe7ff,spread:5,life:.5,size:.09,grav:0});if(!c.reduce)c.rig.shake(.12);return 560},
 leap:null, // handled by the jump itself; landing adds a ring (main.js)
 saberThrow:c=>{c.u.throwAt(c.tp);return 60}, // the thrown blade itself plays on the shot event
 disarm:c=>{c.u.cast(c.tp,.5);if(!c.tp)return 200;stream(c,c.from.clone().setY(1),c.tp,0x9fe7ff,.25,18);const T=c.T,m=new T.MeshStandardMaterial({color:0x2b2f33,metalness:.6}),
  o=new T.Mesh(geo(T).cube,m),a=c.tp.clone().setY(1),b=a.clone().add(new T.Vector3((Math.random()-.5)*2.5,0,(Math.random()-.5)*2.5)).setY(.05);
  c.fx3.add(o,.7,k=>{o.position.lerpVectors(a,b,k);o.position.y=a.y*(1-k)+Math.sin(k*Math.PI)*1.1+.05;o.scale.set(.06,.08,.4);o.rotation.x+=.4;o.rotation.y+=.2},()=>{c.fx3.scene.remove(o)});
  c.fx3.sparks(a,0xffe0a0,12);return 450},
 // Mind (gold)
 stun:c=>{c.u.cast(c.tp,.6);const h=c.tp.clone().setY(1.55);c.fx3.ring(h,0xe0bd78,.5,.15,.5,1.55);
  for(let i=0;i<3;i++){const m=mat(c,0xffe7a0,.95);add(c,m,geo(c.T).oct,1,(o,k)=>{const a=k*9+i*2.1;o.position.copy(h).add(new c.T.Vector3(Math.cos(a)*.3,Math.sin(k*20)*.03,Math.sin(a)*.3));o.scale.setScalar(.05);m.opacity=1-k})}
  if(c.tv)c.tv.hitAnim&&c.tv.hitAnim();return 380},
 mindTrick:c=>{c.u.cast(c.tp,.8);const h=c.tp.clone().setY(0);spiral(c,h,0xe0bd78,1.7,.7,30,.55,1);beam(c,c.from.clone().setY(1.5),c.tp.clone().setY(1.5),0xe0bd78,.5,.025);return 520},
 beastCalm:c=>{c.u.cast(c.tp,.9);groundRings(c,c.tp.clone().setY(0),0x9fe07f,3,1.4,.9,.2);c.fx3.motes(c.tp,0xbfffa0,26);return 520},
 // Life (green)
 forceHeal:c=>{c.u.cast(c.tp,.8);const p=(c.tp||c.from).clone().setY(0);spiral(c,p,0x7fd99a,1.8,.7,32,.45,1);pillar(c,p,0x7fd99a,.4,2,.7);c.fx3.flash(p,0x7fd99a,3);return 520},
 forceRevive:c=>{c.u.cast(c.tp,1);const p=(c.tp||c.from).clone().setY(0);pillar(c,p,0xffe7a0,.45,4,1,1);c.fx3.motes(p,0xffe7a0,30);c.fx3.flash(p,0xffe7a0,5);groundRings(c,p,0xffe7a0,2,1.2,.9);return 700},
 massHeal:c=>{c.u.cast(null,1);const p=c.from.clone().setY(0);groundRings(c,p,0x7fd99a,3,4,.8,.15);dome(c,c.from.clone().setY(.8),0x7fd99a,4,.8);
  for(const o of S.units)if(o.side==='p'&&o!==c.u.u&&alive(o)&&dist(o,c.u.u)<=4){const q=c.P(o,.2);stream(c,c.from.clone().setY(1.2),q.clone().setY(1),0x7fd99a,.5,16,.06);spiral(c,q,0x7fd99a,1.3,.6,14,.35)}return 650},
 barrier:c=>{c.u.cast(c.tp,.6);const p=(c.tp||c.from).clone().setY(.8);dome(c,p,0x7fd99a,.75,1.1);c.fx3.ring(p,0x7fd99a,.3,.9,.5,.1);return 400},
 battleMed:c=>{c.u.cast(null,1.2);const p=c.from.clone().setY(0);groundRings(c,p,0x79d3e2,3,6,1.1,.25);c.fx3.motes(c.from,0x79d3e2,30);
  for(const o of S.units)if(alive(o)&&o!==c.u.u&&dist(o,c.u.u)<=6){const q=c.P(o,1);if(o.side==='p')beam(c,c.from.clone().setY(1.4),q,0x79d3e2,.8,.02);else c.fx3.ring(q,0xb294f5,.6,.2,.6,1.4)}return 650},
 meditate:c=>{c.u.cast(null,1);spiral(c,c.from.clone().setY(0),0x79d3e2,1.4,.8,24,.45);return 450},
 // Stasis / shadow (violet)
 stasisField:c=>{c.u.cast(null,1);const p=c.from.clone().setY(0);dome(c,c.from.clone().setY(.8),0xb294f5,3.2,1.1);groundRings(c,p,0xb294f5,2,3.2,.6);
  for(const o of S.units)if(o.side==='e'&&alive(o)&&!o.hid&&dist(o,c.u.u)<=3){const q=c.P(o,.9),m=mat(c,0xc9b4ff,.4);add(c,m,geo(c.T).cube,1.1,(b,k)=>{b.position.copy(q);b.scale.set(.75,1.7,.75);b.rotation.y=k*.6;m.opacity=.4*(1-Math.max(0,k-.7)/.3)})}return 700},
 shadowStep:c=>{const a=c.from.clone().setY(.4);c.fx3.puff(a,16,0x1a1420);c.fx3.glow.emit(a,20,{color:0x8a4dff,spread:1.5,life:.4,size:.07});
  if(c.tp){const b=c.tp.clone().setY(.4);setTimeout(()=>{c.fx3.puff(b,12,0x1a1420);c.fx3.glow.emit(b,16,{color:0x8a4dff,spread:1.2,life:.4,size:.07})},180)}return 260},
 choke:()=>0, // the 'Force choke' shot event plays the lift + tightening ring
 // Saber techniques (caster's blade color)
 sweep:c=>{crescent(c,c.from,c.color,0,.35,1.6);crescent(c,c.from,c.color,Math.PI,.35,1.6);return 120},
 flurry:c=>{const f=c.tp?Math.atan2(c.tp.x-c.from.x,c.tp.z-c.from.z):0;for(let i=0;i<3;i++)setTimeout(()=>crescent(c,c.tp||c.from,c.color,f+i*1.1,.2,.7),i*90);return 120},
 mightyBlow:c=>{if(c.tp){setTimeout(()=>{groundRings(c,c.tp.clone().setY(0),0xffd27a,2,1.3,.4);c.fx3.sparks(c.tp,0xffd27a,26);if(!c.reduce)c.rig.shake(.2)},260)}return 120},
 precisionStrike:c=>{if(c.tp){beam(c,c.from.clone().setY(1),c.tp.clone().setY(1),c.color,.25,.03);c.fx3.flash(c.tp,c.color,2)}return 120},
 guard:c=>{c.u.block&&c.u.block();c.fx3.ring(c.from.clone().setY(.4),0x79d3e2,.3,.9,.5,.4);return 250},
};
export function forceFx(c){const f=FX[c.k];return f?f(c):null}

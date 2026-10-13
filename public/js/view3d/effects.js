// Combat effects: blaster bolts, sparks, smoke, explosions, debris, Force push waves, lightning, heal motes, grenade arcs, thrown sabers.
// Every effect returns how long the event queue should wait (ms) before the next beat plays.
const VS=`attribute vec3 pc;attribute float pa;attribute float ps;uniform float uScale;varying float vA;varying vec3 vC;
void main(){vA=pa;vC=pc;vec4 mv=modelViewMatrix*vec4(position,1.);gl_PointSize=min(ps*uScale/-mv.z,42.);gl_Position=projectionMatrix*mv;}`;
const FS=`varying float vA;varying vec3 vC;void main(){float r=length(gl_PointCoord-.5);if(r>.5)discard;gl_FragColor=vec4(vC,vA*smoothstep(.5,.05,r));}`;
class PS{
 constructor(T,scene,max,add){this.T=T;this.max=max;this.n=0;this.list=[];const g=new T.BufferGeometry();
  for(const [k,s] of [['position',3],['pc',3],['pa',1],['ps',1]])g.setAttribute(k,new T.BufferAttribute(new Float32Array(max*s),s).setUsage(T.DynamicDrawUsage));
  this.u={uScale:{value:260}};this.pts=new T.Points(g,new T.ShaderMaterial({vertexShader:VS,fragmentShader:FS,uniforms:this.u,transparent:true,depthWrite:false,blending:add?T.AdditiveBlending:T.NormalBlending}));
  this.pts.frustumCulled=false;this.pts.renderOrder=add?8:7;this.g=g;scene.add(this.pts)}
 emit(p,n,o={}){const c=new this.T.Color(o.color??0xffffff);for(let i=0;i<n&&this.list.length<this.max;i++){const sp=o.spread??2,a=Math.random()*Math.PI*2,u=Math.random()*2-1,r=Math.sqrt(1-u*u);
   this.list.push({x:p.x+(Math.random()-.5)*(o.jit||0),y:p.y+(Math.random()-.5)*(o.jit||0),z:p.z+(Math.random()-.5)*(o.jit||0),
    vx:r*Math.cos(a)*sp*Math.random()+(o.vx||0),vy:Math.abs(u)*sp*Math.random()*(o.upOnly?1:Math.sign(u)||1)+(o.up||0),vz:r*Math.sin(a)*sp*Math.random()+(o.vz||0),
    life:0,max:(o.life||.6)*(.6+Math.random()*.6),s0:o.size||.12,s1:o.grow??(o.size||.12)*.3,g:o.grav??-6,drag:o.drag??1.5,c})}}
 update(dt){const P=this.g.attributes,L=this.list;let j=0;
  for(let i=0;i<L.length;i++){const q=L[i];q.life+=dt;if(q.life>=q.max)continue;const k=q.life/q.max,d=Math.max(0,1-q.drag*dt);
   q.vx*=d;q.vz*=d;q.vy=q.vy*d+q.g*dt;q.x+=q.vx*dt;q.y=Math.max(.02,q.y+q.vy*dt);q.z+=q.vz*dt;
   P.position.setXYZ(j,q.x,q.y,q.z);P.pc.setXYZ(j,q.c.r,q.c.g,q.c.b);P.pa.setX(j,1-k*k);P.ps.setX(j,q.s0+(q.s1-q.s0)*k);L[j++]=q}
  L.length=j;this.g.setDrawRange(0,j);for(const k of ['position','pc','pa','ps'])P[k].needsUpdate=true}
}
export class Effects{
 constructor(THREE,scene,rig){const T=THREE;this.T=T;this.scene=scene;this.rig=rig;this.reduce=false;this.items=[];
  this.glow=new PS(T,scene,900,true);this.smoke=new PS(T,scene,500,false);
  this.lights=[0,1].map(()=>{const l=new T.PointLight(0xffa040,0,7,1.6);scene.add(l);return l});this.li=0;
  this.boltGeo=new T.CylinderGeometry(.03,.03,.5,6).rotateX(Math.PI/2);this.glowGeo=new T.CylinderGeometry(.075,.075,.62,6).rotateX(Math.PI/2);
  this.sph=new T.IcosahedronGeometry(1,1);this.box=new T.BoxGeometry(1,1,1);this.ringGeo=new T.TorusGeometry(1,.05,6,32).rotateX(Math.PI/2)}
 setScale(px){this.glow.u.uScale.value=this.smoke.u.uScale.value=260*px}
 basic(c,o=.9){return new this.T.MeshBasicMaterial({color:c,transparent:true,opacity:o,blending:this.T.AdditiveBlending,depthWrite:false})}
 add(obj,d,fn,done){if(obj)this.scene.add(obj);this.items.push({obj,t:0,d,fn,done})}
 flash(p,color=0xffa040,i=14){const l=this.lights[this.li++%2];l.color.setHex(color);l.position.copy(p).setY(p.y+.6);l.intensity=i;l.userData.k=i}
 sparks(p,color=0xffd27a,n=18){this.glow.emit(p,n,{color,spread:3.2,life:.45,size:.09,grav:-9,jit:.08})}
 puff(p,n=8,color=0x58666b){this.smoke.emit(p,n,{color,spread:.6,up:.8,life:1.1,size:.3,grow:.9,grav:.2,drag:2,jit:.2})}
 // Blaster bolt: travels the line of fire. Miss = flies on past, deflect = sent off sideways.
 bolt(a,b,{color=0xef6a5d,hit=true,deflect=false}={}){const T=this.T,dir=b.clone().sub(a),len=dir.length(),sp=this.reduce?60:26,end=b.clone();
  if(!hit&&!deflect){const side=new T.Vector3(-dir.z,0,dir.x).normalize().multiplyScalar((Math.random()<.5?-1:1)*.45);end.add(side).add(dir.clone().normalize().multiplyScalar(1.4))}
  const g=new T.Group(),m=new T.Mesh(this.boltGeo,new T.MeshBasicMaterial({color:new T.Color(color).lerp(new T.Color(0xffffff),.6)})),h=new T.Mesh(this.glowGeo,this.basic(color,.6));
  g.add(m,h);g.position.copy(a);g.lookAt(end);this.glow.emit(a,5,{color,spread:1,life:.15,size:.12});const d=a.distanceTo(end)/sp,tHit=len/sp;
  this.add(g,d,k=>g.position.lerpVectors(a,end,k),()=>{this.scene.remove(g);if(!hit&&!deflect)this.puff(end,3)});
  if(deflect)this.add(null,tHit,()=>{},()=>{this.sparks(b,0x9fe7ff,14);const out=b.clone().add(new T.Vector3((Math.random()-.5)*6,1.5,(Math.random()-.5)*6));this.bolt(b,out,{color,hit:false})});
  return tHit*1000}
 // Kill beat: sparks + smoke burst, camera nudge, light flash.
 burst(p,color=0xffb070){this.sparks(p,color,30);this.puff(p,14,0x3e4a4f);this.flash(p,color,2.5);if(!this.reduce){this.rig.nudge(p,.35);this.rig.shake(.05)}}
 explosion(p){const T=this.T,f=new T.Mesh(this.sph,this.basic(0xffa040,1));f.position.copy(p).setY(.4);
  this.add(f,.45,k=>{f.scale.setScalar(.15+k*.95);f.material.opacity=.85*(1-k);f.material.color.setHSL(.08-.06*k,1,.6-.3*k)},()=>this.scene.remove(f));
  this.glow.emit(p.clone().setY(.4),60,{color:0xffb050,spread:5,life:.6,size:.13,grav:-7});this.puff(p.clone().setY(.5),26,0x2f383c);this.flash(p,0xff9030,7);
  this.ring(p,0xffb050,.2,1.8,.4);this.debris(p,10,0x4a3d2c);if(!this.reduce)this.rig.shake(.22);return 450}
 debris(p,n=8,color=0x5a6a70){const T=this.T,mat=new T.MeshStandardMaterial({color,flatShading:true});
  for(let i=0;i<n;i++){const o=new T.Mesh(this.box,mat),s=.06+Math.random()*.1;o.scale.set(s,s,s);o.position.copy(p).setY(.3+Math.random()*.3);o.castShadow=true;
   const v=new T.Vector3((Math.random()-.5)*4,2+Math.random()*3,(Math.random()-.5)*4),w=new T.Vector3(Math.random()*9,Math.random()*9,0);
   this.add(o,1.4,(k,dt)=>{v.y-=12*dt;o.position.addScaledVector(v,dt);if(o.position.y<s/2){o.position.y=s/2;v.y*=-.3;v.x*=.6;v.z*=.6}o.rotation.x+=w.x*dt;o.rotation.y+=w.y*dt;if(k>.8)o.scale.setScalar(s*(1-k)*5)},()=>this.scene.remove(o))}}
 ring(p,color,r0=.2,r1=1.2,d=.4,y=.15){const o=new this.T.Mesh(this.ringGeo,this.basic(color,.9));o.position.copy(p).setY(y);
  this.add(o,d,k=>{o.scale.setScalar(r0+(r1-r0)*k);o.material.opacity=.9*(1-k)},()=>this.scene.remove(o));return d*1000}
 // Force push: a cone of rings rolling from caster to target.
 wave(a,b,color=0x9fe7ff){const dir=b.clone().sub(a);for(let i=0;i<4;i++){const o=new this.T.Mesh(this.ringGeo,this.basic(color,.8));o.lookAt(dir);o.rotateX(Math.PI/2);
   this.add(o,.4+i*.06,k=>{o.position.lerpVectors(a,b,k).setY(.7);o.scale.setScalar(.15+k*.55);o.material.opacity=.8*(1-k*k)},()=>this.scene.remove(o))}
  this.glow.emit(b.clone().setY(.7),16,{color,spread:2,life:.4,size:.1});return 380}
 lightning(a,b,d=.5,color=0xc9a7ff){const T=this.T,N=12,g=new T.BufferGeometry(),pos=new Float32Array(N*3);g.setAttribute('position',new T.BufferAttribute(pos,3));
  const ln=new T.Line(g,new T.LineBasicMaterial({color,transparent:true,opacity:1,blending:T.AdditiveBlending,depthWrite:false})),ln2=ln.clone();ln2.material=ln.material.clone();ln2.material.color.setHex(0xffffff);
  const gr=new T.Group();gr.add(ln,ln2);let acc=0;
  this.add(gr,d,(k,dt)=>{acc+=dt;if(acc<.03)return;acc=0;for(let i=0;i<N;i++){const f=i/(N-1),j=i&&i<N-1?.22:0;pos[i*3]=a.x+(b.x-a.x)*f+(Math.random()-.5)*j;
    pos[i*3+1]=a.y+(b.y-a.y)*f+(Math.random()-.5)*j;pos[i*3+2]=a.z+(b.z-a.z)*f+(Math.random()-.5)*j}g.attributes.position.needsUpdate=true;
   this.glow.emit(b,2,{color,spread:1.5,life:.25,size:.08})},()=>{this.scene.remove(gr);g.dispose()});this.flash(b,color,2);return d*1000}
 motes(p,color=0x7fd99a,n=22){this.glow.emit(p.clone().setY(.3),n,{color,spread:.5,up:1.4,life:.9,size:.08,grav:.5,jit:.5,upOnly:1});return 300}
 choke(p){this.glow.emit(p.clone().setY(1),24,{color:0xb294f5,spread:.6,up:.3,life:.8,size:.07,grav:0,jit:.5});return 0}
 arc(a,b,d=.5,color=0x8aa2a5){const o=new this.T.Mesh(this.sph,new this.T.MeshStandardMaterial({color}));o.scale.setScalar(.07);
  this.add(o,d,k=>{o.position.lerpVectors(a,b,k);o.position.y=a.y+(b.y-a.y)*k+Math.sin(k*Math.PI)*1.6},()=>this.scene.remove(o));return d*1000}
 saber(a,b,color){const T=this.T,g=new T.Group(),bl=new T.Mesh(new T.CylinderGeometry(.03,.03,.8,6),new T.MeshBasicMaterial({color:new T.Color(color).lerp(new T.Color(0xffffff),.6)})),
   gl=new T.Mesh(new T.CylinderGeometry(.07,.07,.86,6),this.basic(color,.5));bl.rotation.z=gl.rotation.z=Math.PI/2;g.add(bl,gl);const d=a.distanceTo(b)/(this.reduce?40:14);
  this.add(g,d*2,k=>{const f=k<.5?k*2:2-k*2;g.position.lerpVectors(a,b,f);g.rotation.y+=.5},()=>this.scene.remove(g));return d*1000}
 update(dt){for(const it of [...this.items]){it.t+=dt;const k=Math.min(1,it.t/it.d);it.fn(k,dt);if(k>=1){this.items.splice(this.items.indexOf(it),1);if(it.done)it.done()}}
  for(const l of this.lights)if(l.intensity>0)l.intensity=Math.max(0,l.intensity-l.userData.k*dt*4);this.glow.update(dt);this.smoke.update(dt)}
}

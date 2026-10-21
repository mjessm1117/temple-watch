// XCOM-style camera rig: mouse drag orbits (left), right/middle drag or WASD pans, Q/E snap 90°, wheel zoom, shake + nudge for impact.
// focus(p) glides to a unit; aim(from,to) blends into an over-the-shoulder shot view (aim(null) blends back). Touch: one finger pans, pinch zooms.
const ease=(k,dt)=>1-Math.exp(-k*dt);
export class CamRig{
 constructor(THREE){this.T=THREE;this.cam=new THREE.PerspectiveCamera(38,1,.1,120);
  this.target=new THREE.Vector3();this.goal=new THREE.Vector3();this.yaw=0;this.yawGoal=0;this.pitch=1.06;this.dist=18;this.distGoal=18;
  this.shakeAmt=0;this.nudgeV=new THREE.Vector3();this.bounds={x:5,z:6};this.keys=new Set();
  this.pitchGoal=this.pitch;this.aimK=0;this.aimP=new THREE.Vector3();this.aimL=new THREE.Vector3();this.aimOn=false}
 fit(cols,rows,aspect){this.bounds={x:cols/2,z:rows/2};this.goal.set(0,0,0);this.yaw=this.yawGoal;this.target.copy(this.goal);
  const need=Math.max(rows*.95,cols/Math.max(.6,aspect)*1.05);this.distGoal=this.dist=Math.min(30,Math.max(9,need*1.25))}
 rotate(dir){const q=Math.PI/2;this.yawGoal=(Math.round(this.yawGoal/q)+dir)*q}
 orbit(dyaw,dpitch){this.yawGoal+=dyaw;this.pitchGoal=Math.max(.62,Math.min(1.36,this.pitchGoal+dpitch))}
 clamp(){this.goal.x=Math.max(-this.bounds.x,Math.min(this.bounds.x,this.goal.x));this.goal.z=Math.max(-this.bounds.z,Math.min(this.bounds.z,this.goal.z))}
 focus(p){this.goal.set(p.x,0,p.z);this.clamp()}
 // Over-the-shoulder: behind the shooter, offset to their right, looking past them at the target.
 aim(from,to){if(!from||!to){this.aimOn=false;return}const d=to.clone().sub(from).setY(0);if(d.lengthSq()<.01)d.set(0,0,-1);d.normalize();
  const r=new this.T.Vector3(-d.z,0,d.x),far=Math.min(1,from.distanceTo(to)/10);
  this.aimP.copy(from).addScaledVector(d,-2.6-far).addScaledVector(r,1.1).setY(from.y+2.5+far*1.4);this.aimL.copy(to).setY(to.y-.3).lerp(from,.15);this.aimOn=true}
 zoom(f){this.distGoal=Math.min(30,Math.max(5,this.distGoal*f))}
 // World units under one screen pixel at the target (so a dragged finger keeps the same patch of ground under it).
 perPx(h){return 2*this.dist*Math.tan(this.cam.fov*Math.PI/360)/Math.max(200,h)}
 panW(right,fwd){this.pan(right/(this.dist*.05),fwd/(this.dist*.05))}
 pan(right,fwd){const s=Math.sin(this.yawGoal),c=Math.cos(this.yawGoal),k=this.dist*.05;
  this.goal.x+=(c*right-s*fwd)*k;this.goal.z+=(-s*right-c*fwd)*k;
  this.clamp()}
 shake(a){this.shakeAmt=Math.max(this.shakeAmt,a)}
 nudge(toward,a=.35){this.nudgeV.copy(toward).sub(this.target).setY(0).clampLength(0,1).multiplyScalar(a)}
 update(dt){const k=this.keys,p=dt*14;
  if(k.has('a')||k.has('arrowleft'))this.pan(-p,0);if(k.has('d')||k.has('arrowright'))this.pan(p,0);
  if(k.has('w')||k.has('arrowup'))this.pan(0,p);if(k.has('s')||k.has('arrowdown'))this.pan(0,-p);
  this.yaw+=(this.yawGoal-this.yaw)*ease(9,dt);this.pitch+=(this.pitchGoal-this.pitch)*ease(9,dt);this.dist+=(this.distGoal-this.dist)*ease(8,dt);this.target.lerp(this.goal,ease(8,dt));
  this.nudgeV.multiplyScalar(1-ease(4,dt));this.shakeAmt*=1-ease(7,dt);
  const t=this.target.clone().add(this.nudgeV),h=Math.cos(this.pitch)*this.dist,j=this.shakeAmt,r=()=>(Math.random()-.5)*j;
  this.cam.position.set(t.x+Math.sin(this.yaw)*h+r(),t.y+Math.sin(this.pitch)*this.dist+r(),t.z+Math.cos(this.yaw)*h+r());
  this.aimK+=((this.aimOn?1:0)-this.aimK)*ease(this.aimOn?6:8,dt);if(this.aimK<.002)this.aimK=0;
  if(this.aimK){const k=this.aimK*this.aimK*(3-2*this.aimK);this.cam.position.lerp(this.aimP,k);this.cam.lookAt(t.clone().lerp(this.aimL,k))}else this.cam.lookAt(t)}
 // Mouse + keyboard. onTile(x,y,kind) gets 'click' / 'hover'; pick(ev) returns a tile or null.
 bind(dom,pick,onTile){let down=null,dragged=false;
  dom.addEventListener('contextmenu',e=>e.preventDefault());
  dom.addEventListener('wheel',e=>{e.preventDefault();this.zoom(e.deltaY>0?1.12:1/1.12)},{passive:false});
  // Two-finger pinch zooms on phones/tablets; one finger pans, tap selects.
  const pts=new Map();let pinch=0,ang=0,mid=null;const gap=()=>{const[a,b]=[...pts.values()];return Math.hypot(a.x-b.x,a.y-b.y)||1},
   angle=()=>{const[a,b]=[...pts.values()];return Math.atan2(b.y-a.y,b.x-a.x)},center=()=>{const[a,b]=[...pts.values()];return{x:(a.x+b.x)/2,y:(a.y+b.y)/2}};
  dom.addEventListener('pointerdown',e=>{pts.set(e.pointerId,{x:e.clientX,y:e.clientY});if(pts.size===2){pinch=gap();ang=angle();mid=center();down=null;dragged=true;return}
   down={x:e.clientX,y:e.clientY,b:e.button,orbit:e.pointerType==='mouse'&&e.button===0&&!e.shiftKey};dragged=false;dom.setPointerCapture(e.pointerId)});
  const lift=e=>{pts.delete(e.pointerId);if(pts.size<2){pinch=0;mid=null}};dom.addEventListener('pointercancel',lift);
  dom.addEventListener('pointermove',e=>{if(pts.has(e.pointerId))pts.set(e.pointerId,{x:e.clientX,y:e.clientY});
   if(pinch&&pts.size===2){const g=gap(),a=angle(),m=center();this.zoom(pinch/g);pinch=g;let da=a-ang;if(da>Math.PI)da-=2*Math.PI;if(da<-Math.PI)da+=2*Math.PI;this.yawGoal+=da;ang=a;
    const k=this.perPx(dom.clientHeight);this.panW(-(m.x-mid.x)*k,(m.y-mid.y)*k);mid=m;return}
   if(down){const dx=e.clientX-down.x,dy=e.clientY-down.y;if(!dragged&&Math.hypot(dx,dy)>7)dragged=true;
    if(dragged){if(down.orbit)this.orbit(-dx*.008,dy*.004);else{const k=this.perPx(dom.clientHeight);this.panW(-dx*k,dy*k/Math.sin(this.pitch))}down.x=e.clientX;down.y=e.clientY;return}}
   const t=pick(e);onTile(t?t.x:-1,t?t.y:-1,'hover')});
  dom.addEventListener('pointerup',e=>{lift(e);const was=down;down=null;if(!was||dragged||was.b!==0)return;const t=pick(e);if(t)onTile(t.x,t.y,'click')});
  dom.addEventListener('pointerleave',()=>onTile(-1,-1,'hover'));
  dom.addEventListener('auxclick',e=>e.preventDefault());
  const typing=()=>{const a=document.activeElement;return a&&/INPUT|TEXTAREA|SELECT/.test(a.tagName)};
  document.addEventListener('keydown',e=>{if(typing()||!document.getElementById('modal').hidden)return;const key=e.key.toLowerCase();
   if(key==='q')this.rotate(-1);else if(key==='e')this.rotate(1);else if(key==='+'||key==='=')this.zoom(1/1.15);else if(key==='-')this.zoom(1.15);
   else if(/^(w|a|s|d|arrow(up|down|left|right))$/.test(key)){this.keys.add(key);if(key.startsWith('arrow'))e.preventDefault()}});
  document.addEventListener('keyup',e=>this.keys.delete(e.key.toLowerCase()));
  window.addEventListener('blur',()=>this.keys.clear())}
}

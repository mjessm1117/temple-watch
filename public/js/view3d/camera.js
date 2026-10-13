// XCOM-style camera rig: fixed tilt, 90° rotate (Q/E), wheel zoom, WASD/arrow or drag to pan, shake + nudge for impact.
const ease=(k,dt)=>1-Math.exp(-k*dt);
export class CamRig{
 constructor(THREE){this.T=THREE;this.cam=new THREE.PerspectiveCamera(38,1,.1,120);
  this.target=new THREE.Vector3();this.goal=new THREE.Vector3();this.yaw=0;this.yawGoal=0;this.pitch=1.06;this.dist=18;this.distGoal=18;
  this.shakeAmt=0;this.nudgeV=new THREE.Vector3();this.bounds={x:5,z:6};this.keys=new Set()}
 fit(cols,rows,aspect){this.bounds={x:cols/2,z:rows/2};this.goal.set(0,0,0);this.yaw=this.yawGoal;this.target.copy(this.goal);
  const need=Math.max(rows*.95,cols/Math.max(.6,aspect)*1.05);this.distGoal=this.dist=Math.min(30,Math.max(9,need*1.25))}
 rotate(dir){this.yawGoal+=dir*Math.PI/2}
 zoom(f){this.distGoal=Math.min(30,Math.max(5,this.distGoal*f))}
 pan(right,fwd){const s=Math.sin(this.yawGoal),c=Math.cos(this.yawGoal),k=this.dist*.05;
  this.goal.x+=(c*right-s*fwd)*k;this.goal.z+=(-s*right-c*fwd)*k;
  this.goal.x=Math.max(-this.bounds.x,Math.min(this.bounds.x,this.goal.x));this.goal.z=Math.max(-this.bounds.z,Math.min(this.bounds.z,this.goal.z))}
 shake(a){this.shakeAmt=Math.max(this.shakeAmt,a)}
 nudge(toward,a=.35){this.nudgeV.copy(toward).sub(this.target).setY(0).clampLength(0,1).multiplyScalar(a)}
 update(dt){const k=this.keys,p=dt*14;
  if(k.has('a')||k.has('arrowleft'))this.pan(-p,0);if(k.has('d')||k.has('arrowright'))this.pan(p,0);
  if(k.has('w')||k.has('arrowup'))this.pan(0,p);if(k.has('s')||k.has('arrowdown'))this.pan(0,-p);
  this.yaw+=(this.yawGoal-this.yaw)*ease(9,dt);this.dist+=(this.distGoal-this.dist)*ease(8,dt);this.target.lerp(this.goal,ease(8,dt));
  this.nudgeV.multiplyScalar(1-ease(4,dt));this.shakeAmt*=1-ease(7,dt);
  const t=this.target.clone().add(this.nudgeV),h=Math.cos(this.pitch)*this.dist,j=this.shakeAmt,r=()=>(Math.random()-.5)*j;
  this.cam.position.set(t.x+Math.sin(this.yaw)*h+r(),t.y+Math.sin(this.pitch)*this.dist+r(),t.z+Math.cos(this.yaw)*h+r());
  this.cam.lookAt(t)}
 // Mouse + keyboard. onTile(x,y,kind) gets 'click' / 'hover'; pick(ev) returns a tile or null.
 bind(dom,pick,onTile){let down=null,dragged=false;
  dom.addEventListener('contextmenu',e=>e.preventDefault());
  dom.addEventListener('wheel',e=>{e.preventDefault();this.zoom(e.deltaY>0?1.12:1/1.12)},{passive:false});
  dom.addEventListener('pointerdown',e=>{down={x:e.clientX,y:e.clientY,b:e.button};dragged=false;dom.setPointerCapture(e.pointerId)});
  dom.addEventListener('pointermove',e=>{
   if(down){const dx=e.clientX-down.x,dy=e.clientY-down.y;if(!dragged&&Math.hypot(dx,dy)>7)dragged=true;
    if(dragged){const s=.9/Math.max(300,dom.clientWidth)*30;this.pan(-dx*s,dy*s);down.x=e.clientX;down.y=e.clientY;return}}
   const t=pick(e);onTile(t?t.x:-1,t?t.y:-1,'hover')});
  dom.addEventListener('pointerup',e=>{const was=down;down=null;if(!was||dragged||was.b!==0)return;const t=pick(e);if(t)onTile(t.x,t.y,'click')});
  dom.addEventListener('pointerleave',()=>onTile(-1,-1,'hover'));
  const typing=()=>{const a=document.activeElement;return a&&/INPUT|TEXTAREA|SELECT/.test(a.tagName)};
  document.addEventListener('keydown',e=>{if(typing()||!document.getElementById('modal').hidden)return;const key=e.key.toLowerCase();
   if(key==='q')this.rotate(-1);else if(key==='e')this.rotate(1);else if(key==='+'||key==='=')this.zoom(1/1.15);else if(key==='-')this.zoom(1.15);
   else if(/^(w|a|s|d|arrow(up|down|left|right))$/.test(key)){this.keys.add(key);if(key.startsWith('arrow'))e.preventDefault()}});
  document.addEventListener('keyup',e=>this.keys.delete(e.key.toLowerCase()));
  window.addEventListener('blur',()=>this.keys.clear())}
}

// Rigged unit figure: same verbs as the block figure (UV in units.js) but driven by skeletal clips.
// Base loop picks itself every frame (idle by weapon, run while moving, crouch beside cover, overwatch aim, lifted, lying);
// one-shots (shoot, swing, cast, hit, death…) play over it and fade back.
import {UV,kindOf} from './units.js';
import {makeFigure,modelOf,fileOf} from './figures.js';
const sm=k=>k*k*(3-2*k);
const GUN={trooper:1,scout:1,medic:1,heavy:1,sith:1,sithHeavy:1,mando:1,agent:1,envoy:1,shieldbearer:1,nihilRaider:1,nihilStorm:1,marchionRo:1,lournaDee:1};

export class RV extends UV{
 static can(u){return !!modelOf(fileOf(kindOf(u)))}
 build(){const T=this.T,F=makeFigure(this.kind,this.U.color(this.u),this.u.kit);this.F=F;this.body.add(F.obj);this.mats.push(...F.mats);this.glows=F.glows.length?F.glows:null;
  this.headY=this.kind==='beast'?1.45:1.2;this.idleArm=0;this.cur=null;this.curName='';this.one=null;this.moving=0;this.coverT=0;this.cover=false;this.swingN=0;
  F.mixer.addEventListener('finished',e=>{if(this.one&&e.action===this.one.a&&!this.one.hold)this.one=null});
  this.pose={armR:0,legs:0,lift:0,lunge:0,flail:0};this.init()}
 init(){if(this.state==='down'){this.act('toLay',{once:1,hold:1,fade:0});if(this.cur)this.cur.time=this.cur.getClip().duration}else this.act(this.baseName(),{fade:0})}
 act(name,{once=0,speed=1,fade=.15,hold=0}={}){const a=this.F.acts[name];if(!a)return 0;const T=this.T;
  if(!once&&this.cur===a)return 0;a.reset();a.enabled=true;a.timeScale=speed;a.setLoop(once?T.LoopOnce:T.LoopRepeat,Infinity);a.clampWhenFinished=!!once;a.setEffectiveWeight(1);a.play();
  if(this.cur&&this.cur!==a&&fade)a.crossFadeFrom(this.cur,fade,false);else if(this.cur&&this.cur!==a)this.cur.stop();
  this.cur=a;this.curName=name;this.one=once?{a,hold:!!hold}:null;return a.getClip().duration/speed*1000}
 release(){if(this.one&&this.one.hold&&this.state==='ok')this.one=null}
 baseName(){const u=this.u;if(this.pose.lift>.05)return 'lifted';if(this.moving)return 'run';if(this.kind==='beast')return 'idle';
  if(u.ow&&GUN[this.kind])return 'aim';if(this.cover&&GUN[this.kind])return 'crouch';
  return this.kind==='jedi'||this.kind==='defender'||this.kind==='acolyte'||this.kind==='malgus'?'saberIdle':GUN[this.kind]?'gunIdle':'idle'}
 walk(pts,tile){const per=this.U.reduce?.06:.2,segs=pts.length-1;if(segs<1){this.setTile(tile);return 0}this.moving=1;this.one=null;
  this.add(per*segs,k=>{const f=Math.min(segs-.0001,k*segs),i=Math.floor(f),a=pts[i],b=pts[i+1];this.root.position.lerpVectors(a,b,f-i);if(a.distanceTo(b)>1.5)this.root.position.y+=Math.sin((f-i)*Math.PI)*.6;this.faceTo(b)},
   ()=>{this.moving=0;this.setTile(tile)});return per*segs*1000}
 shoot(at){this.faceTo(at);if(this.kind==='beast')return this.swing(at);this.act(GUN[this.kind]?'shoot':'cast',{once:1,speed:1.3})}
 aim(at,d=.55){if(at)this.faceTo(at);if(this.kind==='beast')return;this.act(GUN[this.kind]?'aim':'cast',{once:1,hold:1,speed:1.2});this.add(d,()=>{},()=>this.release())}
 cast(at,d=.7){if(at)this.faceTo(at);if(this.kind==='beast')return;if(d>.9){this.act('channel',{once:0});this.one={a:this.cur,hold:1};this.add(d,()=>{},()=>this.release())}else this.act('cast',{once:1,speed:1.2})}
 throwAt(at){this.faceTo(at);this.act(this.F.acts.throw?'throw':'cast',{once:1,speed:1.7})}
 use(at){if(at)this.faceTo(at);this.act('interact',{once:1,speed:1.6})}
 block(){if(this.F.acts.block)this.act('block',{once:1,speed:1.8})}
 cheer(){this.act('cheer',{once:1})}
 swing(at){this.faceTo(at);const two=this.swingN++%2&&this.F.acts.swing2;this.act(two?'swing2':this.kind==='beast'&&this.swingN%2?'claw':'swing',{once:1,speed:two?1:this.kind==='beast'?1.3:2.2})}
 flash(){this.flashK=1;this.hitAnim()}
 hitAnim(big){if(this.state!=='ok')return;this.act(big&&this.F.acts.knock?'knock':'hit',{once:1,speed:1.1,fade:.06})}
 knock(from,amt=.28){super.knock(from,amt);if(amt>.3)this.hitAnim(1)}
 fall(state,from){this.state=state;if(from)this.faceTo(from);this.moving=0;const dead=state==='dead';
  const ms=this.act(dead?(this.uid%2?'death':'death2'):'toLay',{once:1,hold:1,speed:dead?1.4:2.4,fade:.08});
  if(dead)this.add(ms/1000+.1,()=>{},()=>this.corpse());return Math.min(ms,dead?900:700)}
 stand(){this.state='ok';this.one=null;this.act('getUp',{once:1,speed:1.4})}
 lift(d=.9){this.add(d,k=>{this.pose.lift=k<.3?sm(k/.3)*.5:k<.8?.5+Math.sin(k*40)*.02:.5*(1-sm((k-.8)/.2))},()=>{this.pose.lift=0})}
 leap(a,b,tile){const d=this.U.reduce?.2:.6;this.faceTo(b);this.act('jumpStart',{once:1,hold:1,speed:3,fade:.05});
  this.add(d,k=>{this.root.position.lerpVectors(a,b,sm(k));this.root.position.y+=Math.sin(k*Math.PI)*1.2;if(k>.25&&this.curName==='jumpStart')this.act('jumpLoop',{once:1,hold:1})},
   ()=>{this.setTile(tile);this.one=null;this.act('jumpLand',{once:1,speed:2.4,fade:.05})});return d*1000}
 update(dt,t){for(const w of [...this.tw]){w.t+=dt;const k=Math.min(1,w.t/w.d);w.fn(k);if(k>=1){this.tw.splice(this.tw.indexOf(w),1);if(w.done)w.done()}}
  const b=this.body;let dy=b.rotation.y-this.face;while(dy>Math.PI)dy-=Math.PI*2;while(dy<-Math.PI)dy+=Math.PI*2;b.rotation.y-=dy*Math.min(1,dt*12);
  this.knockV.multiplyScalar(Math.max(0,1-dt*7));b.position.set(this.knockV.x,this.pose.lift||0,this.knockV.z);
  if((this.coverT-=dt)<=0){this.coverT=.4;const u=this.u;this.cover=typeof N4!=='undefined'&&u.status==='ok'&&N4.some(([dx,dy])=>{const c=tile(u.x+dx,u.y+dy);return inb(u.x+dx,u.y+dy)&&(HALF(c)||FULL(c))})}
  if(!this.one&&this.state==='ok'){const n=this.baseName();if(n!==this.curName)this.act(n,{fade:n==='run'?.1:.25})}
  if(!this.frozen)this.F.mixer.update(dt);
  if(this.flashK>0){this.flashK=Math.max(0,this.flashK-dt*5);for(const m of this.mats)if(m.userData.e0)m.emissive.copy(m.userData.e0).lerp(this.U.white,this.flashK*.85)}
  if(this.glows)for(const g of this.glows)g.material.opacity=g.userData.o*(.85+.15*Math.sin(t*23+this.uid));
  if(this.sel.visible){const s=1+.06*Math.sin(t*4);this.sel.scale.set(s,1,s)}
  if(this.bleed.visible)this.bleed.material.opacity=.35+.35*Math.sin(t*5)}
}

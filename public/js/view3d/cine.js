// Cinematic camera beats: mission-start flyover, kill cam, Force-power cam, enemy-reveal pan.
// Each beat borrows the camera from the rig for ~1–4 s and hands it back with a blend. Click, Esc, Space or Enter skips.
// Off switch: View3D.cinematics = false (stored in localStorage 'tw_cine'); reduced motion also turns them off.
const KEY='tw_cine',sm=k=>k*k*(3-2*k);
export class Cine{
 constructor(T,rig,host,labelsEl){this.T=T;this.rig=rig;this.host=host;this.labelsEl=labelsEl;this.cur=null;this.back=0;this.cool={};this.reduce=false;
  try{this._en=localStorage.getItem(KEY)!=='off'}catch(e){this._en=true}
  this.from={p:new T.Vector3(),l:new T.Vector3()};this.tmp={p:new T.Vector3(),l:new T.Vector3()};
  const card=document.createElement('div');card.setAttribute('aria-live','polite');
  card.style.cssText='position:absolute;left:0;right:0;bottom:16%;text-align:center;pointer-events:none;opacity:0;transition:opacity .35s;z-index:4;text-shadow:0 2px 8px #000';
  host.appendChild(card);this.card=card;
  const hint=document.createElement('div');hint.textContent='Click or Esc to skip';
  hint.style.cssText='position:absolute;right:12px;top:10px;font:500 11px "IBM Plex Mono",monospace;color:#dbe7e4;opacity:0;transition:opacity .3s;pointer-events:none;z-index:4;letter-spacing:.08em';
  host.appendChild(hint);this.hint=hint;
  const skip=e=>{if(!this.cur)return;e.stopPropagation();e.preventDefault();this.skip()};
  host.addEventListener('pointerdown',skip,true);host.addEventListener('pointerup',e=>{if(this.cur||this.justSkipped){e.stopPropagation();this.justSkipped=0}},true);
  document.addEventListener('keydown',e=>{if(this.cur&&/^(Escape| |Enter)$/.test(e.key)){e.preventDefault();e.stopImmediatePropagation();this.skip()}},true)}
 // Chat U's Settings panel (window.SETTINGS.cine) is the switch when present; otherwise our own stored flag.
 get enabled(){return window.SETTINGS&&'cine' in SETTINGS?!!SETTINGS.cine:this._en}
 get on(){return this.enabled&&!this.reduce}
 setEnabled(v){this._en=!!v;if(window.SETTINGS){SETTINGS.cine=!!v;if(typeof saveSettings==='function')saveSettings()}else try{localStorage.setItem(KEY,v?'on':'off')}catch(e){}if(!v)this.skip()}
 // Ready to start a beat of this kind? (cooldown in seconds keeps them from repeating every shot)
 ready(kind,cd){const now=performance.now()/1000;if(!this.on||this.cur||(this.cool[kind]||0)>now)return false;this.cool[kind]=now+cd;return true}
 // shot(k) → {p, l}: camera position + look-at for progress k (0–1). d = seconds.
 play(kind,d,shot,o={}){if(!this.on)return 0;const c=this.rig.cam;this.from.p.copy(c.position);this.from.l.copy(this.rig.target);
  this.cur={kind,t:0,d,shot,ease:o.ease??.35};this.labelsEl.style.transition='opacity .25s';this.labelsEl.style.opacity=o.labels?'.85':'0';this.hint.style.opacity='.7';
  if(o.title){this.card.innerHTML=o.title;this.card.style.opacity='1'}else this.card.style.opacity='0';return d*1000}
 skip(){if(!this.cur)return;this.cur=null;this.justSkipped=1;this.end()}
 end(){this.cur=null;this.back=.45;this.labelsEl.style.opacity='';this.hint.style.opacity='0';this.card.style.opacity='0'}
 // Called after rig.update each frame. Returns true while it owns the camera.
 update(dt){const c=this.rig.cam,T=this.T;
  if(this.cur){const s=this.cur;s.t+=dt;const k=Math.min(1,s.t/s.d),v=s.shot(k,dt),e=s.ease?Math.min(1,sm(Math.min(1,s.t/s.ease))):1;
   this.tmp.p.copy(this.from.p).lerp(v.p,e);this.tmp.l.copy(this.from.l).lerp(v.l,e);c.position.copy(this.tmp.p);c.lookAt(this.tmp.l);this.last={p:this.tmp.p.clone(),l:this.tmp.l.clone()};
   if(k>=1)this.end();return true}
  if(this.back>0&&this.last){this.back-=dt;const k=sm(Math.max(0,this.back/.45));c.position.lerp(this.last.p,k);const l=this.rig.target.clone().lerp(this.last.l,k);c.lookAt(l);return true}
  return false}
 // ---- Beats ----
 // Opening sweep: high orbit around the board settling into the normal view.
 flyover(cols,rows,title){const T=this.T,R=Math.max(cols,rows),c0=new T.Vector3();
  return this.play('fly',3.6,k=>{const a=-1.1+k*1.1,dist=R*1.5-k*R*.35,h=R*1.1-k*R*.3,e=sm(k);
   const p=new T.Vector3(Math.sin(a+this.rig.yaw)*dist,h,Math.cos(a+this.rig.yaw)*dist),end=this.rig.cam.position;
   return{p:k>.8?p.lerp(end,sm((k-.8)/.2)):p,l:c0.clone().lerp(this.rig.target,e)}},{ease:0,title})}
 // Over-the-shoulder on the shooter, low, looking at the target. a/b = world positions.
 killcam(a,b,d=1.5){const T=this.T,dir=b.clone().sub(a).setY(0).normalize(),side=new T.Vector3(-dir.z,0,dir.x);
  return this.play('kill',d,k=>({p:a.clone().addScaledVector(dir,-1.7+k*.4).addScaledVector(side,.65).setY(a.y+1.35-k*.15),l:b.clone().setY(b.y+.2).lerp(a,.12-k*.12)}),{ease:.3})}
 // Slow arc around the caster toward the target.
 forcecam(a,b,d=1.25){const T=this.T,mid=a.clone().lerp(b,.4),dir=b.clone().sub(a).setY(0).normalize(),side=new T.Vector3(-dir.z,0,dir.x);
  return this.play('force',d,k=>({p:a.clone().addScaledVector(dir,-2.4).addScaledVector(side,2-k*1.1).setY(a.y+2-k*.35),l:mid.clone().setY(.8)}),{ease:.3})}
 // Swing over to newly spotted enemies, hold, then hand back.
 reveal(p,title,d=1.6){const T=this.T,dir=p.clone().sub(this.rig.target).setY(0);if(dir.lengthSq()<.01)dir.set(0,0,-1);dir.normalize();
  return this.play('reveal',d,k=>({p:p.clone().addScaledVector(dir,3.6).setY(3.4),l:p.clone().setY(.6)}),{ease:.45,title,labels:1})}
}

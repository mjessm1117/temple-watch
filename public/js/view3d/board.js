import {mergeGeometries} from '../../vendor/BufferGeometryUtils.js';
// Map geometry from S.grid + floor highlights. Half cover is waist-high (crates, consoles, barrels), full cover is tall (walls, pillars, doors).
// Rebuilds only tiles whose character changed; anything that lost cover reports back so effects can throw debris.
const HALF_H=.55,FULL_H=1.55;
const ALIAS={B:'#',h:'c',b:'k',C:'q',X:'Q'};
// Raised ground (contract: TILES[c].elev 0–2, set by Chat X). Each level lifts the tile, its cover and its units by EH.
export const EH=.45,elevOf=c=>(TILES[c]||{}).elev||0;
export const tileH=c=>{const h=(TILES[c]||{}).h||0;return h>=2?FULL_H:h>=1?HALF_H:h>0?.2:0};
export class Board{
 constructor(THREE,scene){this.T=THREE;this.scene=scene;this.root=new THREE.Group();scene.add(this.root);this.tiles=new Map();this.grid=null;
  const M=(c,o={})=>new THREE.MeshStandardMaterial({color:c,roughness:.8,metalness:.15,flatShading:true,...o});
  this.m={wall:M(0x2b3e46),wallTop:M(0x35505a),trim:M(0x79d3e2,{emissive:0x79d3e2,emissiveIntensity:.5}),crate:M(0x7a6544),band:M(0x3b3123),
   barrel:M(0xa8342a,{emissive:0x3a0804}),stripe:M(0xe0bd78,{emissive:0x3a2a08}),metal:M(0x4a5d64,{metalness:.5}),dark:M(0x17242a),
   screen:M(0x79d3e2,{emissive:0x79d3e2,emissiveIntensity:1.1}),clue:M(0xe0bd78,{emissive:0xe0bd78,emissiveIntensity:.9}),
   done:M(0x7fd99a,{emissive:0x7fd99a,emissiveIntensity:.9}),lock:M(0xef6a5d,{emissive:0xef6a5d,emissiveIntensity:1}),rubble:M(0x3a4a50),
   evac:new THREE.MeshBasicMaterial({color:0x7fd99a,transparent:true,opacity:.28,depthWrite:false})};
  this.box=new THREE.BoxGeometry(1,1,1);this.cyl=new THREE.CylinderGeometry(.5,.5,1,10);
  const hm=(c,o)=>new THREE.MeshBasicMaterial({color:c,transparent:true,opacity:o,depthWrite:false});
  this.hm={reach:hm(0x2f9dff,.5),dash:hm(0xffb21e,.5),hover:hm(0x7fc8ff,.85),hoverDash:hm(0xffd166,.85),reachEdge:hm(0x9fe3ff,.95),dashEdge:hm(0xffe08a,.95),tgt:hm(0xef6a5d,.85),ally:hm(0x7fd99a,.85),spot:hm(0x79d3e2,.7),pick:hm(0xffffff,.95),
   area:hm(0x79d3e2,.2),iarea:hm(0xef6a5d,.22),path:hm(0x79d3e2,.95),smoke:hm(0x8aa2a5,.22),vis:new THREE.MeshBasicMaterial({map:this.hatch(),transparent:true,opacity:.85,depthWrite:false})};
  this.plane=new THREE.PlaneGeometry(.92,.92).rotateX(-Math.PI/2);this.ring=new THREE.RingGeometry(.34,.44,24).rotateX(-Math.PI/2);this.frame=new THREE.RingGeometry(.55,.64,4,1,Math.PI/4).rotateX(-Math.PI/2);
  this.dot=new THREE.CircleGeometry(.06,10).rotateX(-Math.PI/2);this.hl=new THREE.Group();scene.add(this.hl);this.pool={};
  this.shieldTex=[this.shieldTexture(false),this.shieldTexture(true)];this.lines=new THREE.Group();scene.add(this.lines);this.anim=[]}
 pos(x,y,h=0){const r=this.grid&&this.grid[y];return new this.T.Vector3(x+.5-this.cols/2,h+(r?elevOf(r[x])*EH:0),y+.5-this.rows/2)}
 elev(x,y){const r=this.grid&&this.grid[y];return r&&r[x]!=null?elevOf(r[x]):0}
 // Theme palette (themes.js): recolors shared materials; the floor texture is redrawn on the next build.
 setTheme(th){this.pal=th;const m=this.m;for(const [k,v] of [['wall',th.wall],['wallTop',th.wallTop],['crate',th.crate],['band',th.band],['metal',th.metal],['rubble',th.rubble]])m[k].color.setHex(v);
  m.trim.color.setHex(th.trim);m.trim.emissive.setHex(th.trim);m.dark.color.setHex(th.ground)}
 build(grid){this.clear();this.rows=grid.length;this.cols=grid[0].length;this.grid=grid.map(r=>[...r]);this.tops=[];
  const T=this.T,base=new T.Mesh(new T.BoxGeometry(this.cols+.6,.4,this.rows+.6),this.m.dark);base.position.y=-.2;base.receiveShadow=true;this.root.add(base);
  this.floorMat=new T.MeshStandardMaterial({map:this.floorTexture(),roughness:.9,metalness:.1});const floor=new T.Mesh(new T.PlaneGeometry(this.cols,this.rows).rotateX(-Math.PI/2),this.floorMat);
  floor.position.y=.001;floor.receiveShadow=true;this.root.add(floor);
  const rim=new T.Mesh(new T.BoxGeometry(this.cols+.7,.05,this.rows+.7),this.m.trim);rim.position.y=-.03;this.root.add(rim);
  for(let y=0;y<this.rows;y++)for(let x=0;x<this.cols;x++)this.setTile(x,y,grid[y][x]);this.batch()}
 clear(){for(const c of [...this.root.children])this.root.remove(c);this.tiles.clear();this.anim=[];this.bRoot=null}
 // Returns tiles that lost cover since the last sync (for debris).
 sync(grid){if(!this.grid||grid.length!==this.rows||grid[0].length!==this.cols){this.build(grid);return[]}const lost=[];
  for(let y=0;y<this.rows;y++)for(let x=0;x<this.cols;x++){const c=grid[y][x],o=this.grid[y][x];if(c===o)continue;
   if(tileH(c)<tileH(o))lost.push({x,y,h:tileH(o),c:o});this.grid[y][x]=c;this.setTile(x,y,c)}if(this.dirty)this.batch();return lost}
 // Static tile pieces → one merged mesh per material + shadow flag (~200 meshes become ~15 draw calls). Animated bits and raised tops stay live.
 batch(){this.dirty=0;const T=this.T;if(this.bRoot){this.root.remove(this.bRoot);this.bRoot.traverse(o=>o.geometry&&o.geometry.dispose())}this.bRoot=new T.Group();
  const live=new Set(this.anim.map(a=>a.o)),tops=new Set(this.tops),B=new Map();this.root.updateMatrixWorld(true);
  for(const g of this.tiles.values())g.traverse(o=>{if(!o.isMesh||live.has(o)||tops.has(o))return;o.visible=false;const k=o.material.uuid+(o.castShadow?'s':'');
   if(!B.has(k))B.set(k,{m:o.material,cast:o.castShadow,g:[]});let ge=o.geometry.index?o.geometry.toNonIndexed():o.geometry.clone();ge.applyMatrix4(o.matrixWorld);
   for(const a of Object.keys(ge.attributes))if(a!=='position'&&a!=='normal'&&a!=='uv')ge.deleteAttribute(a);if(!ge.attributes.uv)ge.setAttribute('uv',new T.Float32BufferAttribute(new Float32Array(ge.attributes.position.count*2),2));B.get(k).g.push(ge)});
  for(const b of B.values()){const ge=mergeGeometries(b.g,false);if(!ge)continue;const m=new T.Mesh(ge,b.m);m.castShadow=b.cast;m.receiveShadow=true;this.bRoot.add(m)}this.root.add(this.bRoot)}
 setTile(x,y,c){this.dirty=1;const e=elevOf(c);c=ALIAS[c]||(TILES[c]&&TILES[c].as3d)||c;const k=x+','+y,old=this.tiles.get(k);if(old){this.root.remove(old);this.anim=this.anim.filter(a=>a.g!==old);this.tops=this.tops.filter(t=>t.parent!==old)}
  let g=this.make(c,x,y);if(e>0)g=this.platform(g||new this.T.Group(),x,y,e,c);if(!g)return this.tiles.delete(k);g.position.copy(this.pos(x,y));g.traverse(o=>{if(o.isMesh){o.castShadow=o.userData.noShadow?false:true;o.receiveShadow=true}});
  this.root.add(g);this.tiles.set(k,g)}
 make(c,x,y){const T=this.T,g=new T.Group(),m=this.m,add=(geo,mat,sx,sy,sz,px=0,py=0,pz=0,ry=0)=>{const o=new T.Mesh(geo,mat);o.scale.set(sx,sy,sz);o.position.set(px,py,pz);o.rotation.y=ry;g.add(o);return o};
  const seed=(x*73+y*37)%7;
  switch(c){
   case '#':add(this.box,m.wall,1,FULL_H,1,0,FULL_H/2);add(this.box,m.wallTop,1.02,.08,1.02,0,FULL_H);for(const [sx,sz,px,pz] of [[1.02,.03,0,.5],[1.02,.03,0,-.5],[.03,1.02,.5,0],[.03,1.02,-.5,0]])add(this.box,m.trim,sx,.03,sz,px,FULL_H+.05,pz).userData.noShadow=1;break;
   case 'O':{add(this.cyl,m.metal,.8,.5,.8,0,.25);add(this.cyl,m.wall,.22,FULL_H,.22,0,FULL_H/2+.2);const r=add(new T.TorusGeometry(.32,.03,6,24),m.screen,1,1,1,0,1.25);r.rotation.x=Math.PI/2;
    r.userData.noShadow=1;this.anim.push({g,o:r,spin:1.5});add(new T.OctahedronGeometry(.12),m.screen,1,1,1,0,FULL_H+.35).userData.noShadow=1;break}
   case 'd':case 'D':case '_':{add(this.box,m.wall,.16,FULL_H,1,-.42,FULL_H/2);add(this.box,m.wall,.16,FULL_H,1,.42,FULL_H/2);add(this.box,m.wallTop,1,.2,1,0,FULL_H-.1);
    if(c!=='_'){add(this.box,m.metal,.68,FULL_H-.2,.14,0,(FULL_H-.2)/2);add(this.box,c==='D'?m.lock:m.screen,.5,.05,.16,0,.95).userData.noShadow=1}
    if(this.isNS(x,y))g.rotation.y=Math.PI/2;break}
   case 'c':add(this.box,m.crate,.78,HALF_H,.78,0,HALF_H/2,0,seed*.08);add(this.box,m.band,.8,.07,.8,0,HALF_H*.7,0,seed*.08);add(this.box,m.band,.8,.07,.8,0,HALF_H*.25,0,seed*.08);break;
   case 'x':add(this.cyl,m.barrel,.5,HALF_H+.05,.5,0,(HALF_H+.05)/2);add(this.cyl,m.stripe,.52,.08,.52,0,.36);add(this.cyl,m.dark,.36,.04,.36,0,HALF_H+.07);break;
   case 'k':add(this.box,m.metal,.7,HALF_H,.45,0,HALF_H/2);{const s=add(this.box,m.screen,.6,.32,.04,0,HALF_H+.18,.12);s.rotation.x=-.4;s.userData.noShadow=1}break;
   case 'q':case 'Q':add(this.box,m.metal,.42,HALF_H,.42,0,HALF_H/2);{const s=add(new T.OctahedronGeometry(.16),c==='q'?m.clue:m.done,1,1.4,1,0,HALF_H+.25);s.userData.noShadow=1;this.anim.push({g,o:s,spin:1.2})}break;
   case 'r':for(let i=0;i<4;i++){const o=add(this.box,m.rubble,.22+.08*((seed+i)%3),.12+.05*(i%2),.25,((seed*3+i*5)%7-3)*.09,.07,((seed*5+i*3)%7-3)*.09,i+seed);o.rotation.x=.2*i}break;
   case 'E':{const p=add(this.plane,m.evac,1,1,1,0,.02);p.userData.noShadow=1;const r=add(this.ring,m.done,.8,1,.8,0,.025);r.userData.noShadow=1;this.anim.push({g,o:r,pulse:1})}break;
   default:return null}
  return g}
 // A raised tile: a block down to the floor with the floor texture on top, lit lips on sides that drop, ramps where TILES[c].ramp.
 platform(g,x,y,e,c){const T=this.T,h=e*EH,m=this.m,G=this.grid,cap=new T.PlaneGeometry(1,1).rotateX(-Math.PI/2),uv=cap.attributes.uv;
  for(let i=0;i<uv.count;i++)uv.setXY(i,(x+uv.getX(i))/this.cols,1-(y+1-uv.getY(i))/this.rows);
  const top=new T.Mesh(cap,this.floorMat);top.position.y=.004;top.userData={x,y};top.receiveShadow=true;g.add(top);this.tops.push(top);
  const blk=new T.Mesh(this.box,m.wall);blk.scale.set(1,h,1);blk.position.y=-h/2;g.add(blk);
  for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){const n=(G[y+dy]||[])[x+dx];if(n==null)continue;const ne=elevOf(n);if(ne>=e)continue;
   const lip=new T.Mesh(this.box,m.trim);lip.scale.set(dx?.04:1,.04,dy?.04:1);lip.position.set(dx*.5,.02,dy*.5);lip.userData.noShadow=1;g.add(lip);
   // One-level drop to walkable ground: a ramp if the tile is marked ramp, otherwise two steps. Two levels = cliff (lip only).
   if(e-ne===1&&(TILES[n]||{}).walk){const d=EH;if((TILES[c]||{}).ramp){const len=.46,r=new T.Mesh(this.box,m.wallTop);r.scale.set(dx?Math.hypot(len,d):.7,.05,dy?Math.hypot(len,d):.7);
     const ang=Math.atan2(d,len);r.position.set(dx*(.5+len/2),-d/2,dy*(.5+len/2));if(dx)r.rotation.z=dx*ang;else r.rotation.x=-dy*ang;r.castShadow=false;g.add(r)}
    else for(let i=1;i<=2;i++){const st=new T.Mesh(this.box,m.wallTop),dep=.16*i;st.scale.set(dx?dep:.6,d*(3-i)/3,dy?dep:.6);st.position.set(dx*(.5+dep/2),-d+d*(3-i)/6,dy*(.5+dep/2));g.add(st)}}}
  return g}
 isNS(x,y){const w=c=>'#OdD_'.includes(c);const g=this.grid;return w((g[y-1]||[])[x]||'#')&&w((g[y+1]||[])[x]||'#')}
 update(dt,t){for(const a of this.anim){if(a.spin)a.o.rotation.y+=dt*a.spin;if(a.pulse){const s=.75+.15*Math.sin(t*3);a.o.scale.set(s,1,s)}}
  for(const o of this.lines.children)if(o.userData.flow){o.userData.flow.t=(o.userData.flow.t+dt*1.6)%1;const f=o.userData.flow;o.position.lerpVectors(f.a,f.b,f.t)}}
 floorTexture(){const s=48,c=document.createElement('canvas');c.width=this.cols*s;c.height=this.rows*s;const g=c.getContext('2d'),P=this.pal&&this.pal.floor||['#0e1a1e','#0f1c20','rgba(121,211,226,.22)','#14242a'];
  g.fillStyle='#0c171a';g.fillRect(0,0,c.width,c.height);let sd=7;const rnd=()=>(sd=(sd*16807)%2147483647)/2147483647;
  for(let y=0;y<this.rows;y++)for(let x=0;x<this.cols;x++){g.fillStyle=(x+y)%2?P[1]:P[0];g.fillRect(x*s+1,y*s+1,s-2,s-2);
   g.fillStyle=P[3];for(let i=0;i<7;i++){const w=2+rnd()*6;g.globalAlpha=.25+rnd()*.35;g.fillRect(x*s+rnd()*(s-w),y*s+rnd()*(s-w),w,w*(.4+rnd()))}g.globalAlpha=1}
  g.strokeStyle=P[2];g.lineWidth=1.5;for(let x=0;x<=this.cols;x++){g.beginPath();g.moveTo(x*s,0);g.lineTo(x*s,c.height);g.stroke()}
  for(let y=0;y<=this.rows;y++){g.beginPath();g.moveTo(0,y*s);g.lineTo(c.width,y*s);g.stroke()}
  const t=new this.T.CanvasTexture(c);t.colorSpace=this.T.SRGBColorSpace;t.anisotropy=4;return t}
 // Enemy sight while concealed: red diagonal hatching with a border, readable on every theme.
 hatch(){const c=document.createElement('canvas');c.width=c.height=64;const g=c.getContext('2d');const c0=this.cbHatch?'255,158,44':'255,59,46';g.fillStyle=`rgba(${c0},.18)`;g.fillRect(0,0,64,64);
  g.strokeStyle=`rgba(${c0},.75)`;g.lineWidth=5;for(let i=-64;i<128;i+=16){g.beginPath();g.moveTo(i,0);g.lineTo(i+64,64);g.stroke()}
  g.lineWidth=3;g.strokeRect(1.5,1.5,61,61);const t=new this.T.CanvasTexture(c);t.colorSpace=this.T.SRGBColorSpace;return t}
 palette(cb){const h=this.hm;h.tgt.color.setHex(cb?0xff9e2c:0xef6a5d);h.iarea.color.setHex(cb?0xff9e2c:0xef6a5d);h.ally.color.setHex(cb?0x5fb0ff:0x7fd99a);
  h.dash.color.setHex(cb?0xf5e663:0xffb21e);h.hoverDash.color.setHex(cb?0xf5e663:0xffd166);h.dashEdge.color.setHex(cb?0xfff3a0:0xffe08a);this.cbHatch=cb;h.vis.map.dispose();h.vis.map=this.hatch();h.vis.needsUpdate=true}
 shieldTexture(full){const c=document.createElement('canvas');c.width=c.height=64;const g=c.getContext('2d');g.beginPath();
  g.moveTo(32,6);g.lineTo(54,14);g.lineTo(54,32);g.bezierCurveTo(54,46,44,54,32,59);g.bezierCurveTo(20,54,10,46,10,32);g.lineTo(10,14);g.closePath();
  g.lineWidth=6;g.strokeStyle='#79d3e2';g.fillStyle='#79d3e2';if(full)g.fill();g.stroke();
  const t=new this.T.CanvasTexture(c);t.colorSpace=this.T.SRGBColorSpace;return t}
 // Highlights: pooled meshes, re-laid each sync. h = {reach,hover,targets,path,area,iarea,smoke,shields,lines}
 take(key,geo,mat){const p=this.pool[key]||(this.pool[key]={list:[],i:0});let o=p.list[p.i++];
  if(!o){o=mat.isSpriteMaterial?new this.T.Sprite(mat):new this.T.Mesh(geo,mat);o.renderOrder=2;p.list.push(o);this.hl.add(o)}o.visible=true;return o}
 highlight(h){for(const p of Object.values(this.pool)){p.i=0;for(const o of p.list)o.visible=false}
  for(const c of [...this.lines.children]){this.lines.remove(c);c.geometry.dispose();c.material.dispose()}const hm=this.hm,lift=(x,y,dy=.012)=>this.pos(x,y,dy);
  for(const t of h.vision||[])this.take('vis',this.plane,hm.vis).position.copy(lift(t.x,t.y,.008));
  for(const t of h.reach){this.take(t.dash?'dash':'reach',this.plane,t.dash?hm.dash:hm.reach).position.copy(lift(t.x,t.y));
   this.take(t.dash?'dashE':'reachE',this.frame,t.dash?hm.dashEdge:hm.reachEdge).position.copy(lift(t.x,t.y,.013))}
  if(h.hover)this.take(h.hover.dash?'hovD':'hov',this.plane,h.hover.dash?hm.hoverDash:hm.hover).position.copy(lift(h.hover.x,h.hover.y,.014));
  for(const t of h.targets){const o=this.take('t_'+t.kind,t.kind==='spot'?this.plane:this.ring,hm[t.kind]);o.position.copy(lift(t.x,t.y,.02))}
  for(const p of h.path){const o=this.take('dot',this.dot,hm.path);o.position.copy(p).setY(p.y+.03)}
  for(const [k,a] of [['area',h.area],['iarea',h.iarea]])if(a){const o=this.take(k,this.plane,hm[k]);o.position.copy(lift(a.x,a.y,.016));o.scale.set(3.26,1,3.26)}
  for(const s of h.smoke){const o=this.take('smk',this.plane,hm.smoke);o.position.copy(lift(s.x,s.y,.03));o.scale.set(3.2,1,3.2)}
  if(!this.smat)this.smat=[0,1].map(i=>new this.T.SpriteMaterial({map:this.shieldTex[i],transparent:true,depthTest:false}));
  for(const s of h.shields){const o=this.take('sh'+(s.full?1:0),null,this.smat[s.full?1:0]);o.position.copy(this.pos(s.x,s.y,.42)).add(new this.T.Vector3(s.dx*.42,0,s.dy*.42));
   const k=s.hot?.46:.3;o.scale.set(k,k,1);o.material.opacity=1;o.renderOrder=5}
  for(const l of h.lines)this.drawLine(l)}
 drawLine({a,b,color,dash}){const T=this.T,ge=new T.BufferGeometry().setFromPoints([a,b]),
  ln=new T.Line(ge,new T.LineDashedMaterial({color,dashSize:dash?.18:10,gapSize:dash?.12:0,transparent:true,opacity:.95,depthTest:false}));
  ln.computeLineDistances();ln.renderOrder=6;this.lines.add(ln);
  const d=new T.Mesh(new T.SphereGeometry(.06,8,6),new T.MeshBasicMaterial({color,depthTest:false}));d.renderOrder=6;d.userData.flow={a,b,t:0};this.lines.add(d)}
}

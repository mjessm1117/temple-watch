// 3D galaxy behind the Galaxy map (wave 7, V2): a slowly turning spiral of ~9K stars, tilted to match the map's region
// ellipses, with a glowing core and a still background starfield. The SVG map stays on top and keeps every click.
// Placed by watching the DOM for svg.gmap (no edits to galaxy.js). Own small renderer, 30 fps, paused when the map
// is not on screen. Reduced motion → one still frame.
import * as THREE from '../../vendor/three.module.min.js';

let R,scene,cam,canvas,svg,disc,core,on=false,last=0,spin=0,ro=null;
const CSS=`.gleft{position:relative}canvas.g3d{position:absolute;left:0;top:0;pointer-events:none;border-radius:8px;z-index:0}
.gmap.g3on{position:relative;z-index:1;background:transparent!important}
.gmap.g3on .greg{fill:color-mix(in srgb,var(--holo) 2%,transparent)}.gmap.g3on .greg.on{fill:color-mix(in srgb,var(--holo) 12%,transparent)}`;
const reduce=()=>window.SETTINGS&&SETTINGS.reducedMotion?SETTINGS.reducedMotion():matchMedia('(prefers-reduced-motion: reduce)').matches;

// Soft round sprite so points read as glowing stars, not squares.
function dot(){const c=document.createElement('canvas');c.width=c.height=32;const g=c.getContext('2d'),r=g.createRadialGradient(16,16,0,16,16,16);
 r.addColorStop(0,'rgba(255,255,255,1)');r.addColorStop(.25,'rgba(255,255,255,.7)');r.addColorStop(1,'rgba(255,255,255,0)');g.fillStyle=r;g.fillRect(0,0,32,32);
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t}
function pts(pos,col,size,tex,opacity=1){const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setAttribute('color',new THREE.Float32BufferAttribute(col,3));
 return new THREE.Points(g,new THREE.PointsMaterial({size,map:tex,vertexColors:true,transparent:true,opacity,depthWrite:false,blending:THREE.AdditiveBlending,sizeAttenuation:false}))}

// Built once from the first map (layout is fixed); galaxy.js re-renders the SVG on every click, we just re-attach.
// Map geometry from the SVG itself: core position and the outer ring (so the spiral lines up with the regions).
function geo(){const E=[...svg.querySelectorAll('ellipse.greg')];if(!E.length)return{cx:300,cy:190,rx:260,ry:.55};
 const big=E.reduce((a,e)=>+e.getAttribute('rx')>+a.getAttribute('rx')?e:a);return{cx:+big.getAttribute('cx'),cy:+big.getAttribute('cy'),rx:+big.getAttribute('rx'),ry:+big.getAttribute('ry')/+big.getAttribute('rx')}}

function build(){const G=geo(),tex=dot();scene=new THREE.Scene();
 // Orthographic camera in SVG units (600×380 viewBox), looking down a tilted axis so a circle reads as the map's ellipse.
 cam=new THREE.OrthographicCamera(0,600,0,-380,-1000,1000);cam.position.set(0,0,500);
 let s=11;const rnd=()=>(s=(s*16807)%2147483647)/2147483647,gs=()=>{let u=0;for(let i=0;i<4;i++)u+=rnd();return u/2-1};
 // Background stars (still, cover the whole map).
 {const P=[],C=[];for(let i=0;i<700;i++){P.push(rnd()*600,-rnd()*380,-200);const b=.35+rnd()*.5,w=rnd();C.push(b*(.8+w*.2),b*(.85+w*.15),b)}scene.add(pts(P,C,1.6,tex,.8))}
 // The disc: two log-spiral arms + scatter, colored blue-white on the arms, gold toward the core, a few red giants.
 disc=new THREE.Group();disc.position.set(G.cx,-G.cy,0);disc.rotation.x=-Math.acos(Math.min(.99,G.ry));scene.add(disc);
 const R0=G.rx*1.08,P=[],C=[],blue=new THREE.Color(0x9fd8ff),white=new THREE.Color(0xeaf4ff),gold=new THREE.Color(0xffd79a),red=new THREE.Color(0xff8a6a);
 for(let i=0;i<14000;i++){const arm=i%2,t=Math.pow(rnd(),.6),r=t*R0,halo=rnd()<.25,a=arm*Math.PI+t*3.1+gs()*(halo?1.6:.45+.4*(1-t)),sc=(halo?18:9)+r*.12;
  const x=Math.cos(a)*r+gs()*sc,y=Math.sin(a)*r+gs()*sc,z=gs()*(5+12*(1-t));P.push(x,y,z);
  const c=rnd()<.03?red.clone():t<.25?gold.clone().lerp(white,t/.25):white.clone().lerp(blue,Math.min(1,(t-.25)*1.6)),b=(halo?.18:.3)+rnd()*.4;C.push(c.r*b,c.g*b,c.b*b)}
 disc.add(pts(P,C,1.6,tex,.85));
 // Core glow: a big soft sprite.
 core=new THREE.Sprite(new THREE.SpriteMaterial({map:tex,color:0xffe6b8,transparent:true,opacity:.75,depthWrite:false,blending:THREE.AdditiveBlending}));
 core.scale.set(G.rx*.55,G.rx*.55*G.ry,1);core.position.set(G.cx,-G.cy,10);scene.add(core)}

function place(){if(!svg||!canvas)return;const w=svg.clientWidth,h=svg.clientHeight;if(!w||!h)return;
 canvas.style.left=svg.offsetLeft+'px';canvas.style.top=svg.offsetTop+'px';canvas.style.width=w+'px';canvas.style.height=h+'px';R.setSize(w,h,false);render()}
function render(){if(R&&scene)R.render(scene,cam)}
function frame(now){if(!on)return;requestAnimationFrame(frame);if(document.hidden||now-last<33)return;const dt=Math.min(.1,(now-last)/1000);last=now;
 if(reduce())return;spin+=dt*.012;disc.rotation.z=spin;core.material.opacity=.68+.07*Math.sin(now/1300);render()}

function attach(el){svg=el;if(!R){R=new THREE.WebGLRenderer({antialias:true,alpha:true,powerPreference:'low-power'});R.setPixelRatio(Math.min(devicePixelRatio,2));R.outputColorSpace=THREE.SRGBColorSpace;canvas=R.domElement;canvas.className='g3d';canvas.setAttribute('aria-hidden','true')}
 if(!scene)build();el.classList.add('g3on');el.before(canvas);ro?.disconnect();ro=new ResizeObserver(place);ro.observe(el);place();if(disc)disc.rotation.z=spin;
 if(!on){on=true;last=0;requestAnimationFrame(frame)}}
function check(){const el=document.querySelector('svg.gmap');if(el===svg&&el&&el.isConnected)return;
 if(!el){on=false;svg=null;ro?.disconnect();return}try{attach(el)}catch(e){console.warn('galaxy 3D off',e);on=false}}
export function startGalaxy(){const st=document.createElement('style');st.textContent=CSS;document.head.appendChild(st);
 let q=0;new MutationObserver(()=>{if(!q){q=1;requestAnimationFrame(()=>{q=0;check()})}}).observe(document.body,{childList:true,subtree:true});check()}

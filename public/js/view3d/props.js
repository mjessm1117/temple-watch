// Meshy map props (public/models/props/<name>.glb, see CREDITS.md). Loaded once per page, then the board swaps its
// primitive crates/barrels/consoles for them on the next build. A prop that isn't listed or fails to load keeps the primitive.
import {GLTFLoader} from '../../vendor/GLTFLoader.js';
import {MeshoptDecoder} from '../../vendor/meshopt_decoder.module.js';
// Themes that borrow another theme's wall (their own Meshy walls kept coming out with openings).
export const WALL_OF=t=>'wall_'+({temple:'ruins',dock:'city'}[t]||t);
export const PROPS=new Set(['crate','barrel','console','terminal','relay','rubble','pillar','statue','brazier','container','gantry',
 ...['dock','city','jungle','snow','temple','ruins','plains','caves'].flatMap(t=>['wall_'+t,'door_'+t])]); // wall/door kit per theme (board.js)
// tile char → prop file
export const PROP_OF={c:'crate',h:'crate',x:'barrel',k:'console',b:'console',q:'terminal',Q:'terminal',C:'terminal',X:'terminal',r:'rubble',O:'relay'};
const cache={};let T=null;
// Quantized vertex data can't survive the board's merge (applyMatrix4 on int16 clamps), so props get float geometry once.
function floaty(g){for(const [k,a] of Object.entries(g.attributes))if(!(a.array instanceof Float32Array)){const f=new Float32Array(a.count*a.itemSize);
 for(let i=0;i<a.count;i++)for(let j=0;j<a.itemSize;j++)f[i*a.itemSize+j]=a.getComponent?a.getComponent(i,j):[a.getX,a.getY,a.getZ,a.getW][j].call(a,i);g.setAttribute(k,new T.BufferAttribute(f,a.itemSize))}return g}
// chars: tile chars on the map; extra: scenery prop names (themes.js). Only listed props are fetched.
export function loadProps(THREE,chars,extra=[]){T=THREE;const names=new Set([...[...chars].map(c=>PROP_OF[c]),...extra].filter(n=>n&&PROPS.has(n)));
 return Promise.all([...names].map(n=>cache[n]?cache[n].p:(cache[n]={p:(()=>{const L=new GLTFLoader();L.setMeshoptDecoder(MeshoptDecoder);
  return L.loadAsync(new URL(`../../models/props/${n}.glb`,import.meta.url).href).then(g=>{const s=g.scene;s.updateMatrixWorld(true);
   const root=new T.Group();s.traverse(o=>{if(o.isMesh){const m=new T.Mesh(floaty(o.geometry.clone()).applyMatrix4(o.matrixWorld),o.material);root.add(m)}});
   // Doors: turn so the wide side runs along x, the way board.js lays a closed door before rotating it for N–S corridors.
   if(n.startsWith('door_')){const z=new T.Box3().setFromObject(root).getSize(new T.Vector3());if(z.z>z.x)for(const m of root.children)m.geometry.rotateY(Math.PI/2)}
   const b=new T.Box3().setFromObject(root);cache[n].ok={root,size:b.getSize(new T.Vector3()),min:b.min.clone(),c:b.getCenter(new T.Vector3())};return 1})
   .catch(e=>{console.warn('prop failed, keeping primitive:',n,e);PROPS.delete(n);return 0})})()}).p)).then(r=>r.some(Boolean))}
// Adds the prop for tile char (or prop name) c to group g, fitted to footprint w (tiles) and height h. Returns false if not loaded.
// fill: stretch height to exactly h (wall kit: full cover must look full height).
export function addProp(g,c,w,h,yaw,fill){const P=cache[PROP_OF[c]||c],M=P&&P.ok;if(!M)return false;const o=M.root.clone();
 const kw=w/Math.max(M.size.x,M.size.z),k=fill?kw:Math.min(kw,h/M.size.y),ky=fill?h/M.size.y:k;o.scale.set(k,ky,k);o.rotation.y=yaw||0;
 const off=new T.Vector3(-M.c.x,-M.min.y,-M.c.z).multiply(new T.Vector3(k,ky,k)).applyAxisAngle(new T.Vector3(0,1,0),yaw||0);o.position.copy(off);g.add(o);return true}

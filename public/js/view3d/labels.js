// HTML labels pinned to 3D positions: unit HP bars + status badges, hit-% tags, floating damage text, the KILL popup.
export class Labels{
 constructor(host){this.el=document.createElement('div');this.el.className='v3l';host.appendChild(this.el);this.units=new Map();this.tags=[];this.floats=[]}
 node(cls,html){const n=document.createElement('div');n.className=cls;n.innerHTML='<div class="in"></div>';n.firstChild.innerHTML=html;this.el.appendChild(n);return n}
 // list: [{key, html, pos()}]
 setUnits(list){const keep=new Set();for(const it of list){keep.add(it.key);let n=this.units.get(it.key);
   if(!n){n={el:this.node('v3u','')};this.units.set(it.key,n)}if(n.html!==it.html){n.el.firstChild.innerHTML=it.html;n.html=it.html}n.pos=it.pos}
  for(const [k,n] of this.units)if(!keep.has(k)){n.el.remove();this.units.delete(k)}}
 setTags(list){for(const t of this.tags)t.el.remove();this.tags=list.map(t=>({el:this.node('v3t '+(t.cls||''),t.html),p:t.p}))}
 float(p,txt,cls='',big=false,color=null){const el=this.node('v3f '+cls+(big?' big':''),txt);if(color){el.firstChild.style.color=color;el.firstChild.style.textShadow='0 0 10px '+color+'99, 0 2px 4px #000'}this.floats.push({el,p:p.clone(),t:0,d:big?1.1:1.15})}
 // Speech bubble pinned over a unit (story barks). pos() follows the unit; fades after d seconds. One bubble per unit at a time.
 bubble(key,pos,txt,d=2.6){const old=this.floats.find(f=>f.key===key);if(old){old.el.remove();this.floats.splice(this.floats.indexOf(old),1)}
  const el=this.node('v3f bark','');const s=el.firstChild;s.textContent=txt;Object.assign(s.style,{font:"500 12px 'IBM Plex Sans',sans-serif",color:'#dbe7e4',background:'#0d181bE6',border:'1px solid #79d3e266',
   borderRadius:'8px',padding:'4px 8px',width:'max-content',maxWidth:'220px',whiteSpace:'normal',textAlign:'center',transform:'translate(-50%,-100%)',boxShadow:'0 4px 12px #0008',textShadow:'none'});
  this.floats.push({el,key,pos,p:null,t:0,d,still:1})}
 clear(){this.el.innerHTML='';this.units.clear();this.tags=[];this.floats=[]}
 update(dt,proj){const place=(el,p,dy=0)=>{const s=p&&proj(p);if(!s){el.style.visibility='hidden';return}el.style.visibility='';el.style.transform=`translate(${s.x}px,${s.y+dy}px)`};
  for(const n of this.units.values())place(n.el,n.pos());for(const t of this.tags)place(t.el,t.p);
  this.floats=this.floats.filter(f=>{f.t+=dt;if(f.t>=f.d){f.el.remove();return false}place(f.el,f.pos?f.pos():f.p,f.still?0:-f.t*34);f.el.style.opacity=f.t<.6*f.d?1:1-(f.t-.6*f.d)/(.4*f.d);return true})}
}

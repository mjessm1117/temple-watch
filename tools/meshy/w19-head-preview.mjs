// One paid Meshy preview per invocation. The durable credit log is updated before submission.
import fs from 'node:fs';
import path from 'node:path';

const names = {
  sniper: 'Isolated stylized low-poly sci-fi sniper helmet, deep olive hood over a compact navy armored face mask, one large side-mounted scope lens and a narrow dark visor. Closed helmet, no face or skin, no shoulders, no bust, no body, no stand, clean strong silhouette, flat painted panels.',
  heavy: 'Isolated stylized low-poly sci-fi heavy infantry helmet, oversized bulky full-face shell, broad angular cheek guards, thick brow and narrow dark visor, burnt orange side armor plates on tan and navy base. Closed helmet, no face or skin, no shoulders, no bust, no body, no stand, clean strong silhouette, flat painted panels.',
  tech: 'Isolated stylized low-poly sci-fi engineer helmet, compact tan armored shell, large teal twin goggles projecting forward and one tall slender antenna rising from the left side, navy lower mask. Closed helmet, no face or skin, no shoulders, no bust, no body, no stand, clean strong silhouette, flat painted panels.',
  officer: 'Isolated stylized low-poly sci-fi field officer peaked helmet, strong forward projecting cap brim and short crimson crest, tan armored crown, navy dark face visor, small rank badge. Closed helmet, no face or skin, no shoulders, no bust, no body, no stand, clean strong silhouette, flat painted panels.',
  medic: 'Isolated stylized low-poly sci-fi combat medic helmet, rounded tan armored shell, raised white forehead panel bearing a clear red medical cross, navy enclosed visor, small white side panels. Closed helmet, no face or skin, no shoulders, no bust, no body, no stand, clean strong silhouette, flat painted panels.',
  droid: 'Isolated stylized low-poly friendly combat droid head, visibly mechanical boxy angular skull with two circular yellow optical eyes, exposed navy jaw grille, small yellow side receivers, tan armor panels. No human face or skin, no shoulders, no bust, no body, no stand, clean strong silhouette, flat painted panels.'
};
const name = process.argv[2];
if (!names[name]) throw Error('Expected one of: '+Object.keys(names).join(', '));
if (!process.env.MESHY_KEY) throw Error('MESHY_KEY missing');
const out = '/home/jess/projects/tw-logs/w19/art';
fs.mkdirSync(out,{recursive:true});
const log = path.join(out,'credits.log');
const lines = fs.existsSync(log) ? fs.readFileSync(log,'utf8').trim().split('\n').filter(Boolean) : [];
if (lines.some(x=>x.includes('pending'))) throw Error('Pending credit entry: resolve before next submission');
const spent = lines.reduce((n,x)=>{const [a,b]=x.split(' / ');return n+Number(a)-Number(b)},0);
if (spent+20>120) throw Error(`120 credit cap: ${spent} spent; preview would cost 20`);
const base='https://api.meshy.ai/openapi';
const headers={Authorization:'Bearer '+process.env.MESHY_KEY,'Content-Type':'application/json'};
async function request(url,init={}) {const r=await fetch(base+url,{headers,...init});const j=await r.json();if(!r.ok)throw Error(`${url}: ${r.status} ${JSON.stringify(j)}`);return j;}
async function balance(){return (await request('/v1/balance')).balance;}
const before=await balance();
const entry=`${before} / pending / ${name} helmet preview`;
lines.push(entry);fs.writeFileSync(log,lines.join('\n')+'\n');
fs.writeFileSync(path.join(out,`${name}-prompt.txt`),names[name]+'\n');
let task;
try {
  task=(await request('/v2/text-to-3d',{method:'POST',body:JSON.stringify({mode:'preview',prompt:names[name],ai_model:'meshy-6',should_remesh:true,target_polycount:2500,topology:'triangle'})})).result;
  fs.writeFileSync(path.join(out,`${name}-task.txt`),task+'\n');
} finally {
  const after=await balance();
  lines[lines.length-1]=`${before} / ${after} / ${name} helmet preview`;
  fs.writeFileSync(log,lines.join('\n')+'\n');
  console.log(`${name}: ${before} -> ${after}`);
}
for (;;) {
  const j=await request('/v2/text-to-3d/'+task);
  if(j.status==='SUCCEEDED'){
    for(const [url,file] of [[j.model_urls?.glb,`${name}-preview.glb`],[j.thumbnail_url,`${name}-preview.png`]]){
      if(url){const r=await fetch(url);if(!r.ok)throw Error(`download ${file}: ${r.status}`);fs.writeFileSync(path.join(out,file),Buffer.from(await r.arrayBuffer()));}
    }
    console.log(`${name}: downloaded`);break;
  }
  if(['FAILED','CANCELED'].includes(j.status))throw Error(`${name}: ${j.status} ${JSON.stringify(j.task_error)}`);
  await new Promise(r=>setTimeout(r,8000));
}

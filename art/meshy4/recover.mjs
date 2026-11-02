import fs from 'node:fs';
const dir='art/meshy4',api='https://api.meshy.ai/openapi';
const headers={Authorization:'Bearer '+process.env.MESHY_KEY};
const ledger=JSON.parse(fs.readFileSync(dir+'/ledger.json'));
for(const t of ledger.tasks){
 if(!t.id){t.status='INTERRUPTED_BEFORE_TASK_ID';continue;}
 for(;;){
  const r=await fetch(api+'/v2/text-to-3d/'+t.id,{headers});if(!r.ok)throw Error('poll HTTP '+r.status);
  const result=await r.json();t.status=result.status;
  if(result.status==='SUCCEEDED'){
   const r=await fetch(result.model_urls.glb);if(!r.ok)throw Error('download HTTP '+r.status);
   fs.writeFileSync(`${dir}/${t.asset}.${t.letter}.preview.glb`,Buffer.from(await r.arrayBuffer()));break;
  }
  if(['FAILED','CANCELED'].includes(result.status))break;
  await new Promise(r=>setTimeout(r,8000));
 }
 fs.writeFileSync(dir+'/ledger.json',JSON.stringify(ledger,null,2)+'\n');
 console.log(t.asset,t.letter,t.status);
}
const b=await(await fetch(api+'/v1/balance',{headers})).json();
fs.writeFileSync(dir+'/balance-after.json',JSON.stringify(b,null,2)+'\n');
fs.writeFileSync(dir+'/ledger.json',JSON.stringify(ledger,null,2)+'\n');

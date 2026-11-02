import fs from 'node:fs';
const dir = 'art/meshy4';
const ledgerPath = `${dir}/ledger.json`;
const api = 'https://api.meshy.ai/openapi';
const headers = {Authorization: 'Bearer ' + process.env.MESHY_KEY};
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const ledger = JSON.parse(fs.readFileSync(ledgerPath));
const pending = ledger.tasks.filter(t => t.id && !fs.existsSync(`${dir}/${t.asset}.${t.letter}.${t.mode === 'refine' ? 'raw' : 'preview'}.glb`));
await Promise.all(pending.map(async task => {
  const output = `${dir}/${task.asset}.${task.letter}.${task.mode === 'refine' ? 'raw' : 'preview'}.glb`;
  for (;;) {
    const response = await fetch(`${api}/v2/text-to-3d/${task.id}`, {headers});
    if (!response.ok) throw Error(`${task.id}: HTTP ${response.status}`);
    const result = await response.json();
    task.status = result.status;
    if (result.status === 'SUCCEEDED') {
      const download = await fetch(result.model_urls.glb);
      if (!download.ok) throw Error(`${task.id}: download HTTP ${download.status}`);
      fs.writeFileSync(output, Buffer.from(await download.arrayBuffer()));
      console.log(`${task.asset} ${task.letter} ${task.mode} complete`);
      break;
    }
    if (['FAILED', 'CANCELED'].includes(result.status)) {
      console.log(`${task.asset} ${task.letter} ${task.mode} ${result.status}`);
      break;
    }
    await sleep(10000);
  }
}));
fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 2) + '\n');

// One paid retexture per class. Usage: node art/w17-2/fix5-meshy.mjs [class]
// Reads the key locally; never logs it or signed asset URLs.
import fs from 'node:fs';
import path from 'node:path';

const env = fs.readFileSync('/home/jess/hive/.env', 'utf8');
const key = process.env.MESHY_KEY || env.match(/^MESHY_KEY=(.*)$/m)?.[1]?.replace(/^['"]|['"]$/g, '');
if (!key) throw Error('MESHY_KEY unavailable');
const api = 'https://api.meshy.ai/openapi/v1';
const headers = {Authorization: `Bearer ${key}`, 'Content-Type': 'application/json'};
const ledgerPath = 'art/w17-2/fix5-ledger.json';
const accents = {sniper: 'olive', heavy: 'burnt orange', tech: 'teal', droid: 'signal yellow', officer: 'crimson'};
const retry = process.argv.includes('--retry');
const resume = process.argv.includes('--resume');
const named = process.argv.slice(2).find(arg => !arg.startsWith('--'));
const kinds = named ? [named] : Object.keys(accents);
const save = ledger => fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 2) + '\n');
const request = async (route, body) => {
  const response = await fetch(api + route, {headers, ...(body ? {method: 'POST', body: JSON.stringify(body)} : {})});
  const data = await response.json();
  if (!response.ok) throw Error(`${route} HTTP ${response.status}: ${JSON.stringify(data)}`);
  return data;
};
const balance = async () => (await request('/balance')).balance;
const ledger = fs.existsSync(ledgerPath) ? JSON.parse(fs.readFileSync(ledgerPath)) : {before: await balance(), cap: 190, tasks: []};
save(ledger);
console.log('START_BALANCE', ledger.before);
for (const kind of kinds) {
  if (!accents[kind]) throw Error(`Unknown class ${kind}`);
  const existing = ledger.tasks.find(task => task.kind === kind && !!task.retry === retry);
  if (existing && !resume) { console.log('EXISTS', kind, retry ? 'retry' : 'first'); continue; }
  if (resume && !existing?.id) throw Error(`No submitted task to resume: ${kind}`);
  if (retry && !ledger.tasks.some(task => task.kind === kind && task.status === 'SUCCEEDED')) throw Error(`No first result to retry: ${kind}`);
  const now = await balance();
  const spent = ledger.tasks.reduce((sum, task) => sum + (task.cost ?? task.estimate ?? 0), 0);
  if (!resume && spent + 10 > ledger.cap) throw Error(`Credit cap would be exceeded: spent ${spent}, next estimate 10`);
  const prompt = retry
    ? `${kind === 'droid' ? 'Armored Republic battle droid' : 'Fully sealed Republic trooper'}, every arm and leg covered by opaque rigid ceramic armor plates, thick cream gauntlets and thigh guards, warm tan chest and shin plates, crisp dark seams and scraped pale edges, dark navy woven undersuit ONLY at elbow knee neck and waist gaps, bold ${accents[kind]} shoulder pauldrons and helmet stripe, stylized hand-painted game texture, no exposed flesh, no beige fabric limbs, no camouflage or mottled pattern`
    : `${kind === 'droid' ? 'Star Wars Republic battle droid plating' : 'Star Wars Republic trooper armor'}, hard painted armor plates in warm tan and cream with worn edges, dark navy fabric undersuit visible at elbows knees neck and waist, ${accents[kind]} shoulder pauldrons and helmet stripe, matte, hand-painted stylized game texture, no camouflage, no skin showing`;
  const model = fs.readFileSync(`godot/assets/units/w17/${kind}.glb`);
  const body = {model_url: `data:application/octet-stream;base64,${model.toString('base64')}`, text_style_prompt: prompt, ai_model: 'meshy-7', enable_original_uv: true, enable_pbr: false, texture_resolution: '2k', target_formats: ['glb']};
  const entry = existing || {kind, retry, prompt, before: now, estimate: 10, status: 'SUBMITTING'};
  if (!resume) {
    ledger.tasks.push(entry); save(ledger);
    const submission = await request('/retexture', body);
    entry.id = submission.result; entry.status = 'SUBMITTED'; entry.after_submission = await balance(); save(ledger);
    console.log('SUBMITTED', kind, entry.id, 'balance', entry.after_submission);
  }
  let task;
  for (;;) {
    task = await request(`/retexture/${entry.id}`);
    if (['SUCCEEDED', 'FAILED', 'CANCELED'].includes(task.status)) break;
    await new Promise(resolve => setTimeout(resolve, 8000));
  }
  entry.status = task.status; entry.cost = task.consumed_credits ?? entry.before - await balance(); entry.after = await balance();
  if (task.status === 'SUCCEEDED') {
    const url = task.model_urls?.glb;
    if (!url) throw Error(`No GLB for ${kind}`);
    const result = await fetch(url);
    if (!result.ok) throw Error(`GLB download failed for ${kind}: ${result.status}`);
    fs.writeFileSync(path.join('art/w17-2', `fix5-${kind}${retry ? '-retry' : ''}-meshy.glb`), Buffer.from(await result.arrayBuffer()));
  } else entry.error = task.task_error;
  save(ledger);
  console.log('FINISHED', kind, entry.status, 'credits', entry.cost, 'balance', entry.after);
}
ledger.after = await balance(); save(ledger);
console.log('END_BALANCE', ledger.after, 'SPENT', ledger.before - ledger.after);

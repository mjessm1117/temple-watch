// Rig the seven selected Meshy refinements. Key comes only from MESHY_KEY.
// Usage: node docs/godot/w15/jedi/rig.mjs /tmp/w15-jedi-raw
import fs from 'node:fs';

const key = process.env.MESHY_KEY;
if (!key) throw new Error('MESHY_KEY required');
const out = process.argv[2];
if (!out) throw new Error('output directory required');
const ledgerPath = `${out}/ledger.json`;
const ledger = JSON.parse(fs.readFileSync(ledgerPath, 'utf8'));
const ids = process.argv[3] ? [process.argv[3]] : ['kira', 'tor', 'satele', 'ressa', 'kell', 'tem', 'sava'];
const headers = { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' };
const api = 'https://api.meshy.ai/openapi';
const save = () => fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 2) + '\n');
async function request(path, init = {}) {
  const response = await fetch(api + path, { headers, ...init });
  const body = await response.json();
  if (!response.ok) throw new Error(`${path}: ${response.status} ${JSON.stringify(body)}`);
  return body;
}
async function balance() { return (await request('/v1/balance')).balance; }
async function wait(taskId) {
  for (;;) {
    const job = await request(`/v1/rigging/${taskId}`);
    if (job.status === 'SUCCEEDED') return job;
    if (job.status === 'FAILED' || job.status === 'CANCELED') throw new Error(`${taskId}: ${JSON.stringify(job.task_error)}`);
    await new Promise(resolve => setTimeout(resolve, 8000));
  }
}
for (const id of ids) {
  const chosen = ledger.tasks.findLast(t => t.asset === id && t.mode === 'refine' && t.status === 'SUCCEEDED');
  if (!chosen || chosen.status !== 'SUCCEEDED') throw new Error(`Missing refined ${id}`);
  let task = ledger.tasks.findLast(t => t.asset === id && t.mode === 'rig' && t.status !== 'REJECTED_422');
  if (!task) {
    const cost = 5;
    const spent = ledger.tasks.reduce((sum, t) => sum + t.cost, 0);
    if (spent + cost > 500) throw new Error(`500 credit cap: stopped before ${id} rig`);
    task = { asset: id, mode: 'rig', cost, before: await balance(), status: 'SUBMITTING' };
    ledger.tasks.push(task); save();
    let result;
    try {
      result = await request('/v1/rigging', { method: 'POST', body: JSON.stringify({ input_task_id: chosen.id, height_meters: 1.8 }) });
    } catch (error) {
      task.cost = 0;
      task.status = 'REJECTED';
      task.error = String(error);
      save();
      throw error;
    }
    task.id = result.result;
    task.after = await balance();
    task.status = 'SUBMITTED'; save();
    console.log(id, 'rig', task.id, task.before, task.after);
  }
  const result = await wait(task.id);
  const url = result.result.rigged_character_glb_url;
  const file = await fetch(url);
  if (!file.ok) throw new Error(`${id}: download ${file.status}`);
  fs.writeFileSync(`${out}/${id}.rig.glb`, Buffer.from(await file.arrayBuffer()));
  task.status = 'SUCCEEDED';
  task.completion_balance = await balance(); save();
  console.log(id, 'rig complete');
}

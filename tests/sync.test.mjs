// End-to-end check: laptop saves, phone loads the same game via sync code. Uses a fake KV store.
import { onRequest } from '../functions/api/save.js';
import { JSDOM } from 'jsdom';
import fs from 'fs';
const kv = new Map();
const env = { SAVES: { get: async k => kv.get(k) ?? null, put: async (k, v) => kv.set(k, v) } };
const html = fs.readFileSync(new URL('../dist/temple-watch.html', import.meta.url), 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fail = 0; const check = (ok, msg) => { console.log((ok ? 'PASS ' : 'FAIL ') + msg); if (!ok) fail++; };
function device() {
  const w = new JSDOM(html, { runScripts: 'dangerously', url: 'https://tw.pages.dev/' }).window;
  w.fetch = async (u, o) => { const r = await onRequest({ request: new Request('https://tw.pages.dev' + u, { method: o.method, headers: o.headers, body: o.body }), env }); return { ok: r.ok, json: () => r.json() }; };
  return w;
}
async function enterCode(w, code) { const d = w.document; d.querySelector('#syncBtn').click(); d.querySelector('#syncIn').value = code; d.querySelector('#syncOk').click(); await sleep(80); }
const A = device(); await enterCode(A, 'jedi-council');
A.document.querySelector('[data-c="supply"]').click(); await sleep(20);
A.eval('S.units[0].x=2;S.units[0].y=6'); await A.eval('endTurn()'); await sleep(100);
check(kv.size === 1, 'laptop save reached the server');
const B = device(); await enterCode(B, 'jedi-council');
const c = B.document.querySelector('#cont'); check(!!c, 'phone sees Continue mission');
c && c.click();
check(B.eval('S.turn') === A.eval('S.turn'), 'phone resumes the same turn');
check(B.eval('S.units[0].x+","+S.units[0].y') === '2,6', 'phone sees the same unit positions');
const bad = await (await onRequest({ request: new Request('https://x/api/save', { headers: { 'x-sync': 'abc' } }), env })).json();
check(/6-64/.test(bad.error), 'short codes are rejected');
const none = await (await onRequest({ request: new Request('https://x/api/save', { headers: { 'x-sync': 'abcdefg' } }), env: {} })).json();
check(/not connected/.test(none.error), 'missing storage gives a clear error');
process.exit(fail ? 1 : 0);

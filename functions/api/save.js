// Cloud saves: GET/PUT /api/save. One save per sync code (code is hashed, never stored).
// Uses the KV binding SAVES (declared in wrangler.toml).
const json = (o, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' } });

async function keyFor(code) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('tw1:' + code));
  return 'save:' + [...new Uint8Array(buf)].map(b => b.toString(16).padStart(2, '0')).join('');
}

export async function onRequest({ request, env }) {
  if (!env.SAVES) return json({ error: 'Save storage is not connected yet.' }, 503);
  const code = (request.headers.get('x-sync') || '').trim();
  if (code.length < 6 || code.length > 64) return json({ error: 'Sync code must be 6-64 characters.' }, 400);
  const key = await keyFor(code);

  if (request.method === 'GET') {
    const v = await env.SAVES.get(key);
    return new Response(v || 'null', { headers: { 'content-type': 'application/json', 'cache-control': 'no-store' } });
  }
  if (request.method === 'PUT') {
    const body = await request.text();
    if (body.length > 500000) return json({ error: 'Save too large.' }, 413);
    try { JSON.parse(body); } catch { return json({ error: 'Bad save data.' }, 400); }
    await env.SAVES.put(key, body);
    return json({ ok: true });
  }
  return json({ error: 'Method not allowed.' }, 405);
}

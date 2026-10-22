/* Temple Watch service worker (A2). Network first: online = always the newest build from the last push.
   Offline (or network slower than 4 s with a cached copy) = the last copy this device saw. Saves live in localStorage, untouched here. */
const CACHE='tw-v1';
self.addEventListener('install',e=>{self.skipWaiting();
 // Pre-cache the shell: the page plus every script/stylesheet it lists, so a fresh install works offline.
 e.waitUntil(caches.open(CACHE).then(async c=>{const r=await fetch('./',{cache:'no-cache'});if(!r.ok)return;await c.put('./',r.clone());
  const html=await r.text(),urls=[...html.matchAll(/(?:src|href)="([^"#:]+)"/g)].map(m=>m[1]);
  await Promise.all(urls.map(u=>c.add(u).catch(()=>{})))}).catch(()=>{}))});
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{const q=e.request,u=new URL(q.url);
 if(q.method!=='GET'||u.pathname.startsWith('/api/')||!/^https?:$/.test(u.protocol))return; // saves + sync always hit the network
 const key=q.mode==='navigate'?'./':q;
 e.respondWith((async()=>{const c=await caches.open(CACHE),hit=await c.match(key,{ignoreSearch:q.mode==='navigate'});
  const net=fetch(q).then(r=>{if(r.ok||r.type==='opaque')c.put(key,r.clone()).catch(()=>{});return r});
  if(!hit)return net;
  const slow=new Promise(res=>setTimeout(()=>res(hit),4000));
  return Promise.race([net.catch(()=>hit),slow])})())});

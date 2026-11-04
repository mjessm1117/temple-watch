#!/usr/bin/env python3
"""Version Godot's offline cache from build contents and activate updates."""
from pathlib import Path
import hashlib
import re
import sys
root = Path(sys.argv[1])
worker = root / 'index.service.worker.js'
source = worker.read_text()
hash_value = hashlib.sha256()
hash_value.update(b'web3-sw-v2')
for path in sorted(root.glob('index.*')):
    if path == worker:
        continue
    hash_value.update(path.name.encode())
    hash_value.update(hashlib.sha256(path.read_bytes()).digest())
version = 'web3-' + hash_value.hexdigest()[:20]
source, count = re.subn(r"const CACHE_VERSION = '[^']+';", f"const CACHE_VERSION = '{version}';", source)
assert count == 1
old = "event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));"
assert old in source
source = source.replace(old, "event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES.map((file) => new Request(file, {cache: 'reload'})))).then(() => self.skipWaiting()));")
old_fetch = 'response = await self.fetch(event.request);'
assert old_fetch in source
source = source.replace(old_fetch, "response = await self.fetch(event.request, {cache: 'reload'});")
source += "\nself.addEventListener('activate', (event) => { event.waitUntil(self.clients.claim()); });\n"
worker.write_text(source)
print('Offline cache version:', version)

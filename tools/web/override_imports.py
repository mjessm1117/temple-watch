#!/usr/bin/env python3
"""Set phone-friendly texture imports in the disposable Godot tree only."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
changed = 0
for path in (root / 'assets').rglob('*.import'):
    if not path.name.lower().endswith(('.png.import', '.webp.import', '.jpg.import', '.jpeg.import')):
        continue
    text = path.read_text()
    if 'compress/mode=' not in text:
        continue
    lines = []
    for line in text.splitlines():
        if line.startswith('compress/mode='):
            line = 'compress/mode=1'  # Lossy, decoded universally by WebGL 2.
        elif line.startswith('compress/lossy_quality='):
            line = 'compress/lossy_quality=0.60'
        elif line.startswith('process/size_limit='):
            line = 'process/size_limit=512'
        lines.append(line)
    new_text = '\n'.join(lines) + '\n'
    if new_text != text:
        path.write_text(new_text)
        changed += 1
print(f'Web-only texture import overrides: {changed}')

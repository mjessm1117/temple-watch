#!/usr/bin/env python3
"""Discard transient imported textures after GLB extraction has settled."""
from pathlib import Path
import sys
root = Path(sys.argv[1]) / '.godot/imported'
files = list(root.glob('*.ctex'))
for path in files:
    path.unlink()
print(f'Forcing final texture import: {len(files)} transient CTEX files')

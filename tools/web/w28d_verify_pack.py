#!/usr/bin/env python3
"""Reject a Godot Web PCK whose generated project settings are empty."""
import struct
import sys
from pathlib import Path

pack = Path(sys.argv[1]).read_bytes()
marker = b"project.binary"
index = pack.find(marker)
if index < 0 or index < 4 or struct.unpack_from("<I", pack, index - 4)[0] != 16:
    raise SystemExit("Web pack has no project.binary entry")
offset, size = struct.unpack_from("<QQ", pack, index + 16)
if size < 16 or offset + size > len(pack):
    raise SystemExit(f"Web pack has invalid project.binary size: {size}")
print(f"Web project.binary: {size} bytes")

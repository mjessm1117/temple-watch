"""Retain original named clips and verify GLB structure after Blender export."""
import json
import struct
from pathlib import Path

ROOT = Path.cwd()
results = json.loads((ROOT / "docs/godot/blender2/decimate-results.json").read_text())

def read(path):
    raw = path.read_bytes()
    assert raw[:4] == b"glTF"
    n = struct.unpack_from("<I", raw, 12)[0]
    return json.loads(raw[20:20+n]), raw[20+n:]

for row in results:
    src = ROOT / "godot/assets" / row["source"]
    dst = ROOT / row["v2"]
    original, _ = read(src)
    candidate, tail = read(dst)
    names = [a["name"] for a in original.get("animations", [])]
    if names:
        by_name = {a["name"]: a for a in candidate.get("animations", [])}
        assert all(name in by_name for name in names), row["source"]
        candidate["animations"] = [by_name[name] for name in names]
    for key in ("skins", "images", "textures", "materials"):
        assert len(candidate.get(key, [])) == len(original.get(key, [])), (row["source"], key)
    source_attrs = original["meshes"][0]["primitives"][0]["attributes"]
    v2_attrs = candidate["meshes"][0]["primitives"][0]["attributes"]
    for attr in ("TEXCOORD_0", "JOINTS_0", "WEIGHTS_0"):
        if attr in source_attrs:
            assert attr in v2_attrs, (row["source"], attr)
    data = json.dumps(candidate, separators=(",", ":")).encode()
    data += b" " * (-len(data) % 4)
    content = struct.pack("<I4s", len(data), b"JSON") + data + tail
    dst.write_bytes(struct.pack("<4sII", b"glTF", 2, 12 + len(content)) + content)
    row["animations"] = len(names)
    row["skins"] = len(original.get("skins", []))
    row["source_bytes"] = src.stat().st_size
    row["v2_bytes"] = dst.stat().st_size
    print(row["source"], row["before"], row["after"], names[:2], len(names))
(ROOT / "docs/godot/blender2/decimate-results.json").write_text(json.dumps(results, indent=2) + "\n")

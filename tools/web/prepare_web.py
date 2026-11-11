#!/usr/bin/env python3
"""Make a disposable Godot source tree for the Web export."""
from __future__ import annotations
import argparse
import json
import re
import shutil
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "godot"
RASTER = {".png", ".webp", ".jpg", ".jpeg"}
# Raster folders the game loads at runtime by path; kept in the web copy.
RUNTIME_RASTER_DIRS = ("assets/loadout/icons13/", "assets/story/portraits14/", "assets/portraits/jedi/",
                       "assets/maps/w23_terrain/", "assets/temple/surface_atlas.png")


def glb_images_embedded(path: Path) -> bool:
    data = path.read_bytes()
    if data[:4] != b"glTF":
        return False
    length = struct.unpack_from("<I", data, 12)[0]
    doc = json.loads(data[20:20 + length])
    return all("bufferView" in image and "uri" not in image for image in doc.get("images", []))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    dest = args.destination.resolve()
    if dest.exists():
        raise SystemExit(f"Destination already exists: {dest}")
    props_text = (SOURCE / "data/maps/props.json").read_text()
    # These scripts are authoring and screenshot tools; only props.json selects
    # Meshy variants for the actual game. Check all game data before exclusion.
    game_data = "\n".join(p.read_text(errors="ignore") for p in (SOURCE / "data").rglob("*.json"))
    runtime_scripts = "\n".join(p.read_text(errors="ignore") for p in (SOURCE / "scripts").rglob("*.gd")
        if not re.search(r"(_capture|_stage|_slice|_trim|_preview)\.gd$", p.name))
    mesh_cuts = set()
    for path in (SOURCE / "assets/maps").glob("meshy*/*.glb"):
        resource = "res://" + path.relative_to(SOURCE).as_posix()
        if resource not in game_data and resource not in runtime_scripts:
            mesh_cuts.add(path.relative_to(SOURCE).as_posix())
    # Images in these GLBs are embedded buffer views. Standalone raster files
    # were extracted for art review and have no direct runtime load paths.
    all_glbs = list((SOURCE / "assets").rglob("*.glb"))
    if not all(glb_images_embedded(p) for p in all_glbs):
        raise SystemExit("An asset GLB has an external image dependency")
    direct_rasters = [p for p in re.findall(r"res://assets/[^\s\"']+?\.(?:png|webp|jpe?g)", runtime_scripts + game_data, re.I)
        if not p.removeprefix("res://").startswith(RUNTIME_RASTER_DIRS)]
    if direct_rasters:
        raise SystemExit(f"Raster paths used directly: {direct_rasters}")
    if "res://tests/" in runtime_scripts + game_data + (SOURCE / "project.godot").read_text():
        raise SystemExit("Game files refer to the test directory")
    # Godot's icon/boot art lives outside assets and remains in the copy.
    raster_cuts = {p.relative_to(SOURCE).as_posix() for p in (SOURCE / "assets").rglob("*")
        if p.suffix.lower() in RASTER and not p.relative_to(SOURCE).as_posix().startswith(RUNTIME_RASTER_DIRS)}
    excluded = mesh_cuts | raster_cuts
    excluded_imports = {name + ".import" for name in excluded}
    def ignore(directory: str, names: list[str]) -> set[str]:
        folder = Path(directory).relative_to(SOURCE)
        return {name for name in names if name == ".godot" or (folder == Path('.') and name == 'tests') or (folder / name).as_posix() in excluded | excluded_imports}
    shutil.copytree(SOURCE, dest, ignore=ignore)
    # The real project and its import files are never edited. If an image is
    # added as a direct runtime asset in future, the check above stops export.
    print(f"Web copy: omitted {len(mesh_cuts)} unused Meshy GLBs, {len(raster_cuts)} duplicate rasters")
    print(f"Source bytes omitted: {sum((SOURCE / p).stat().st_size for p in excluded):,}")
    (dest.parent / "web-exclusions.txt").write_text("\n".join(sorted(excluded)) + "\n")

if __name__ == "__main__":
    main()

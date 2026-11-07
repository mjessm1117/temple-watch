# W17 soldier model wire

## Changed

- Battle `UnitView` selects the approved W17 GLB by soldier class. Both LOD0 and LOD1 use the imported Trooper animation rig; the paired meshes switch at 26 world units using Godot visibility ranges, and both animation players receive the same clips and speed.
- The armory loads the same W17 GLB for each class at the existing Trooper scale and framing. Its extra procedural blaster is suppressed for these models because their approved weapons are already in the GLB.
- Sniper, Tech, Droid, and Officer now have soldier unit definitions and campaign class stats. Barracks candidates rotate through all eight soldier classes. Heavy keeps its existing stats and unit data; only the battle and armory model changes. The 5 → 6 → 7 squad-size rule is unchanged.
- `godot/tests/w17_wire_test.gd` covers model selection, both LODs, the 15,000-triangle LOD0 cap, idle/run/shoot/hit playback, and actual barracks hiring. Its `--capture` path places all five classes in a battle and captures the three requested shots.

## Rank-1 stats and existing ability proxies

| Class | HP | Aim | Move | Damage | Range | Armor | Existing ability used for signature |
|---|---:|---:|---:|---:|---:|---:|---|
| Sniper | 7 | 82 | 5 | 4–7 | 12 | 1 | Deadeye, with Mark for target setup |
| Heavy | 8 | 60 | 4 | 3–6 | 7 | 2 | Grenade (existing Heavy base kit) |
| Tech | 7 | 68 | 5 | 3–5 | 7 | 1 | Hack, with Scan and Shield Drone support |
| Droid | 9 | 72 | 5 | 3–6 | 8 | 2 | Shield Drone, with Rapid Fire |
| Officer | 8 | 72 | 5 | 3–5 | 8 | 1 | Rally, with Mark |

These are campaign class stats. Heavy's row is unchanged. The W17 class signatures in the design document (Squadsight, Rocket, Probe Droid, Rebuild, Take That Shot) need the later class engine; the listed abilities are existing playable approximations. Heavy's legacy player deployment still uses the Soldier unit template before campaign stats are applied.

LOD0 triangle counts are Sniper 5,477; Heavy 5,769; Tech 5,525; Droid 5,425; Officer 5,221. All are below 15,000.

## Web package

The Web export uses `all_resources`; `tools/web/prepare_web.py` excludes duplicate review rasters but retains all ten W17 GLBs. The final `.pck` contains paths for the five LOD0 and five LOD1 models.

| Build | `index.pck` bytes |
|---|---:|
| Main `482183c`, same export pipeline | 29,888,040 |
| W17 wire | 37,030,836 |
| Increase | **7,142,796 bytes (6.81 MiB)** |

The increase is below the 12 MB target. Both exports used `tools/web/export_web.sh` and the same Godot binary.

## Evidence

- [Phone battle](../shots/w17-wire-battle.png) — 844×390, Low.
- [Armory sheet](../shots/w17-wire-armory.png) — one view per class.
- [Desktop battle](../shots/w17-wire-desktop.png) — 1366×768.
- W17 wire test: 139 checks, 0 failures. `./godot/test.sh`: exit 0, zero `SCRIPT ERROR`, zero failures; Normal rescue bot 9/20 wins. Headless import and `git diff --check` also passed.

## Remaining gaps

The capture path is a debug fixture. It uses real battle and armory views while arranging all five classes for a single shot. It does not add a permanent five-class squad or change squad capacity. The later W17 core lane owns the distinct class signatures, chains, rank kits, and Droid rebuild behavior.

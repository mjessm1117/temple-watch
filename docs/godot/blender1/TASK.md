# TASK: Blender cleanup of the Meshy models the Godot game ships (lane tw-blender1)

## Goal
Use headless Blender to clean the Meshy `.glb` models that the **Godot game actually loads**. Fix only real problems, with no visual regressions. Make cleaned copies with a `_v2` suffix and never overwrite the shipped files. Finish with in-game before/after screenshots.

## Context
- House MD scanned `public/models` (59 files). That folder belongs to the **frozen old web game** and is OUT OF SCOPE. Do not touch `public/**`.
- The flags from that scan are probably also present in the Godot copies:
  1. Stray "Icosphere" helper meshes on units (80 faces, no material, ~2 m, at the origin).
  2. Props centered on the origin instead of standing on the floor. This may be intentional; check the loader.
  3. Off-center pivots or geometry below the floor on some units.
- Godot load paths to inventory:
  - `godot/scripts/combat_scene.gd:47-50`, which loads `res://assets/models/units/*.glb` and `props/*.glb`.
  - `res://assets/maps/**` (including meshy1 and `props.json`), `res://assets/loadout/models`, `res://assets/temple`, `res://assets/galaxy`, `res://../art/meshy1c`.
  - Grep for every other `.glb` reference.
- Tools on the box:
  - Blender 5.2.2: `/snap/bin/blender`
  - Scan: `blender -b --factory-startup --python /home/jess/hive/tools/blender/scan-models.py -- <folder> <out.csv>`
  - Previews: `/home/jess/hive/tools/blender/preview-sheet.py` (4-angle PNG + JSON). Read its header for usage.
  - Always delete Blender's default cube when you script.
- Phone budget: keep within the current per-model triangle counts. No decimation unless a model is clearly over budget AND the result looks identical at the battle camera.

## Steps
1. Run `godot --headless --path godot --import` in this worktree first.
2. Inventory every `.glb` the Godot game loads. Scan each folder and write the results to `docs/godot/blender1/scan.csv`.
3. Make a call on each flag and record it:
   - Stray helper mesh: delete it only if no code references it and it has no material.
   - Floor/pivot: read the loader and stage code (`combat_scene.gd`, the map renderer, the `meshy*_stage.gd` AABB code) and check whether it already offsets the model.
     - If it compensates, leave the model as is and write down why.
     - If not, fix the model.
4. Export the fixed models as `<name>_v2.glb` in a staging folder (e.g. `godot/assets/models_v2/...`).
   - Exclude that folder from the web export (`export_presets.cfg` exclude filter) so the phone download does not grow. Report the pck size before/after.
   - Do NOT repoint shipped code to the v2 files. Swapping them in needs Jess's OK.
5. Make before/after preview sheets with preview-sheet.py for every changed model, in `docs/godot/blender1/previews/`.
6. Take in-game before/after captures at the real battle camera with a test-only capture script that loads original vs v2 side by side. Cover units and props, at 1366x768 and phone 844x390. Save to `docs/godot/shots/blender1-*.png`.
7. Write `docs/godot/blender1/REPORT.md` with one row per model: issue, decision, tris before/after, bounds before/after. Add a short entry to `art/LOG.md`.

## Gate
- `godot --headless --import`
- `./godot/test.sh`: exit 0, 0 SCRIPT ERROR lines, every suite 0 failures, Normal rescue band unchanged.
- `git diff --check` clean.

## Boundaries / file lease
- MAY write:
  - new `_v2` .glb files (+ .import/textures) in the staging folder
  - `export_presets.cfg` (exclude filter only)
  - `docs/godot/blender1/**`, `docs/godot/shots/blender1-*`, `art/LOG.md`
  - a new test-only capture script under `godot/tests/` or `godot/tools/` named `blender1_*`
- MUST NOT modify:
  - any existing `.glb`
  - `public/**` or other web-game files
  - shipped gameplay or loader scripts
  - `godot/test.sh` (unless you are adding a blender1 suite)
- Never spend Meshy credits.
- Commit locally on branch `art/blender1`. Never push.
- Do the work yourself. Do not delegate or spawn subagents.

## Resume note (2026-11-04 19:08)
The machine restarted 2 minutes into the first run. `docs/godot/blender1/scan.csv` (97 rows) already exists from that run; reuse it unless stale. Write any logs under `docs/godot/blender1/` or `/home/jess/projects/tw-logs/`, never `/tmp` (it is wiped when the machine restarts).

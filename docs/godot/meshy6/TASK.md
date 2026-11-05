# TASK: Meshy batch 6, remake the 7 blocky cover props (lane tw-meshy6)

Worktree `/home/jess/projects/tw-blender1`, branch `art/blender1` (HEAD 9844802). Jess approved the spend on 2026-11-05 (ask-d7c8e70d): about 350 credits, **hard cap 490**.

## Context
Read these first:
- the shortlist and the reasons each prop reads as a box: `docs/godot/blender2/REPORT.md`, section "Blocky props"
- the contact sheet: `docs/godot/shots/blender2-blocky-props.jpg`
- earlier batch ledgers, prompts and costs: `art/LOG.md`
- the method: `/home/jess/hive/skills/meshy-art-director/SKILL.md`. It covers reference first, cheap previews, render-and-critique, and refining only the winners.

The tools are in `tools/meshy/`. `prop.mjs` fits and simplifies to about 1.5K triangles. Also use `gen.mjs`, `inspect.mjs` and `contact-sheet.mjs`. The key is `MESHY_KEY` in `/home/jess/hive/.env`. Never print the key or commit it.

The seven props are:
1. temple orange rock pile
2. dock pale half cover
3. plains dry stone half cover
4. city half cover
5. ruins half cover
6. cave half cover
7. jungle procedural bag stack, a new GLB to replace the code-built stack later

## Goal
For each prop, make a replacement that reads as natural, irregular cover at the battle camera. It must keep the same half-cover height and fit inside the same tile footprint, so line of sight and cover don't change. It must also match its theme's palette.

## Steps
1. **Budget.** Read the balance with a read-only GET before you start and log it. Keep a running ledger in `docs/godot/meshy6/ledger.md` listing each call and its credits.
   - Stop immediately when cumulative spend would pass **490**.
   - Plan for 2 previews plus 1 refine per prop.
2. **Previews.** For each prop, make 2 previews. Render each one with Blender headless (the `/home/jess/hive/tools/blender/preview-sheet.py` header has the usage) and critique it against the "why blocky" reason. If both are bad, a third preview is allowed only while you are under the cap.
3. **Refine and fit.** Refine only the winner. Fit it with `prop.mjs`: at most 1.5K triangles (the phone budget), floor-fit, and footprint at most 1 tile. Make an `_lod1` if the existing cover set uses one.
4. **Stage.** Save the new files as `godot/assets/maps/meshy6/cover_half_<theme>_v6.glb`. **Do not change** any loader, `map_art_*` or theme script, and **do not touch** any existing GLB. The Wave 13 gfx lane owns those scripts tonight, so wiring the new props in happens later.
5. **Evidence.**
   - **In-game A/B captures.** Add a test-only capture script, `godot/tests/meshy6_capture.gd`, that builds each theme's rescue board at the battle camera. It draws the old prop on the left and the v6 prop on the right, at 1366x768 and 844x390. Save the shots as `docs/godot/shots/meshy6-<theme>-<size>.png`.
   - **Contact sheet.** Combine all of them into one sheet, `docs/godot/shots/meshy6-before-after.jpg`, with the old version on top and the new one below.
   - **Web export.** Keep the capture script excluded from the web export, the same way `blender1_capture.gd` is.
6. **Report.** Write `docs/godot/meshy6/REPORT.md`, with one row per prop:
   - credits spent
   - triangles
   - footprint and height compared with the original
   - pass/fail and why
   - the exact wiring change needed later (file and line)

   Add an entry to `art/LOG.md` with the batch total and the ending balance.

## Gate
- `godot --headless --path godot --import` (the binary is at `/home/jess/projects/.tools/godot/godot` if `godot` is not on PATH)
- `./godot/test.sh`: exit 0, 0 SCRIPT ERROR lines, every suite at 0 failures, Normal rescue at 9-11/20
- `git diff --check` is clean

## File lease
- **May write:**
  - `godot/assets/maps/meshy6/**`
  - `godot/tests/meshy6_*`
  - `docs/godot/meshy6/**`
  - `docs/godot/shots/meshy6-*`
  - `art/LOG.md`
  - `export_presets.cfg`, only to add the exclusion
- **Nothing else.**

Commit locally on `art/blender1`. Never push. Do the work yourself, with no subagents. Logs go under `docs/godot/meshy6/`, never `/tmp`.

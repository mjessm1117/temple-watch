# Task: tw-w23-integrate
# Merge all 5 W23 lanes, apply cross-lane wiring, gate, XCOM compare, ship Wave 23.

## Goal
Merge the five W23 lane branches into main, resolve conflicts (test.sh), verify/apply two cross-lane wiring edits, pass the full gate, take XCOM comparison screenshots, and ship W23 to GitHub Pages.

## Context
- Main repo: /home/jess/projects/temple-watch
- Godot binary: /home/jess/projects/.tools/godot/godot (4.7.2)
- Base: main b8a8bde4 (W22 shipped, 98 suites)
- 5 lane branches (all off b8a8bde4):
  - w23/terrain  → 4722b6e  (map_art_geometry, map_art_batch, map_art_edges, map_art_grid, terrain shader, atlas, terrain23_test, test.sh)
  - w23/units    → 5a8044f  (unit_view, models/units/**, units/w17/** + 5 LOD2 models, units23_test, feelcam22_test, test.sh)
  - w23/lightfx  → d11bc6e  (combat_scene, env_art, fx, gfx_theme_presets, graphics_settings, w23_lightfx_ambient, w23_lightfx_billboards, assets/vfx, lightfx23_test, gfx13_test, gfx_night1_test, impact22_test, map14_test, test.sh)
  - w23/spaces   → fe5ea63  (campaign/temple_view, temple_geometry, galaxy_art, galaxy_map, galaxy_details, assets/temple/**, assets/galaxy/**, spaces23_test, test.sh)
  - w23/uiart    → 4f79267  (hud_phone, hud_phone_layout, hud_phone_action_art, hud_phone_camera_art, hud_controls, battle12_aim, story14_comms, campaign/ui, campaign/temple, campaign/galaxy, campaign/squad, campaign/loadout_arsenal, story/story_screen, assets/fonts/**, assets/icon/**, uiart23_test, test.sh)
- XCOM 2 reference shots: /home/jess/projects/tw-reference/ (private — NEVER commit)
- Logs: /home/jess/projects/tw-logs/w23/integrate/ (mkdir -p)

## Conflict-prone files — read both sides before resolving
1. **godot/test.sh** — all 5 lanes added 1 registration line each. After all merges, all 5 must be present: terrain23_test, units23_test, lightfx23_test, spaces23_test, uiart23_test. Never silently drop a line.
2. **godot/tests/feelcam22_test.gd** — modified by lane 2 (units, 1 assertion for saber halo). Lightfx also runs the same test suite but did NOT edit this file. Keep lane 2's assertion change.
3. **godot/tests/impact22_test.gd** — modified by lane 3 (lightfx, 2 assertions for pooled sparks/blast). Keep lane 3's changes.

## Steps

### Step 0 — Create integrate branch and merge all 5 lanes
```bash
cd /home/jess/projects/temple-watch
git checkout b8a8bde4 -b w23/integrate
git merge --no-ff w23/terrain  -m "W23 integrate: merge terrain lane (4722b6e)"
git merge --no-ff w23/units    -m "W23 integrate: merge units lane (5a8044f)"
git merge --no-ff w23/lightfx  -m "W23 integrate: merge lightfx lane (d11bc6e)"
git merge --no-ff w23/spaces   -m "W23 integrate: merge spaces lane (fe5ea63)"
git merge --no-ff w23/uiart    -m "W23 integrate: merge uiart lane (4f79267)"
```
For every conflict: read both sides carefully. Keep all functional changes from both sides.

After all 5 merges, verify test.sh has all 5 new suite registrations:
```bash
grep -E 'terrain23|units23|lightfx23|spaces23|uiart23' godot/test.sh
```
Must show exactly 5 lines. If any are missing, add them to the suites section.

### Step 1 — Verify cross-lane wiring activates
These are guarded calls each lane left for integration. No new code needed; just verify the guards resolved.

#### 1a. Saber halo — lightfx calls unit_view.set_saber_halo
Lane 3 (lightfx) added a guarded call in `combat_scene.gd`. Lane 2 (units) exposed `func set_saber_halo(enabled: bool)` in `unit_view.gd`. After both lanes merge, the guard should flip from "method absent" to "method present".

Verify:
```bash
grep -n 'set_saber_halo\|has_method.*saber' godot/scripts/combat_scene.gd | head -5
grep -n 'set_saber_halo' godot/scripts/unit_view.gd | head -5
```
Both must show hits. If `combat_scene.gd` has no such call, add it:
- Find where combat_scene.gd iterates unit views (likely in `_process` or after a tier change).
- Add: `if unit_view.has_method("set_saber_halo"): unit_view.set_saber_halo(gfx_tier >= 2)` or the equivalent pattern matching lane 3's existing tier logic.

#### 1b. Temple + galaxy safe rect — uiart calls spaces methods
Lane 4 (spaces) exposed `set_ui_safe_rect(rect: Rect2)` in `campaign/temple_view.gd` and `campaign/galaxy_map.gd`. Lane 5 (uiart) owns `campaign/temple.gd` and `campaign/galaxy.gd` and should have guarded calls that forward the HUD-computed safe rect.

Verify:
```bash
grep -n 'set_ui_safe_rect\|has_method.*safe' godot/scripts/campaign/temple.gd godot/scripts/campaign/galaxy.gd | head -10
grep -n 'set_ui_safe_rect' godot/scripts/campaign/temple_view.gd godot/scripts/campaign/galaxy_map.gd | head -5
```
If the guarded calls are present in temple.gd and galaxy.gd: nothing to do — they activate now.
If either is missing, add it in the appropriate layout/resize handler:
```gdscript
if temple_view != null and temple_view.has_method("set_ui_safe_rect"):
    temple_view.set_ui_safe_rect(hud_safe_rect)
```
Use the same pattern for galaxy.gd / galaxy_map.

After wiring verification/edits, commit:
"W23 integrate: saber halo + safe_rect wiring"

### Step 2 — Check foliage/banner wind gap
Lane 1 (terrain) flagged that foliage/banner wind was lane 3's work. Lane 3 (lightfx) flagged it was lane 1's asset work.

Check whether either landed it:
```bash
grep -rn 'wind\|banner\|foliage' godot/scripts/map_art_geometry.gd godot/scripts/w23_lightfx_ambient.gd 2>/dev/null | head -10
```
If neither implemented it: log the gap in `/home/jess/projects/tw-logs/w23/integrate/KNOWN-GAPS.md`:
"Foliage/banner wind: neither terrain nor lightfx implemented; gap 10 partial — haze and motes land, wind deferred to W24."
Do NOT hold the ship for this.

### Step 3 — Full gate
Rsync textures (worktrees don't have untracked .webp files):
```bash
rsync -av --include='*.webp' --include='*.webp.import' --include='*.glb.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/units/ ./godot/assets/units/
rsync -av --include='*.webp' --include='*.webp.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/characters/ ./godot/assets/characters/
```

Headless import:
```bash
/home/jess/projects/.tools/godot/godot --headless --path godot/ --import --quit-after 180 2>&1 | tail -5
```

Full gate:
```bash
mkdir -p /home/jess/projects/tw-logs/w23/integrate
./godot/test.sh > /home/jess/projects/tw-logs/w23/integrate/gate.log 2>&1
echo "GATE_EXIT=$?"
grep -E 'SCRIPT ERROR|failures|Normal' /home/jess/projects/tw-logs/w23/integrate/gate.log | tail -20
```
Must exit 0, 0 SCRIPT ERROR, 0 failures, Normal rescue 9–11/20.
If any suite fails: diagnose exact error, fix only the failing assertion, re-run, repeat.
Do NOT proceed to ship with any failure.

Also capture Low draw count at 390×844 after the gate map battle sequence and log it:
```bash
# Run the audit capture driver at 390×844 Low to get combined draw/triangle count
# Log to /home/jess/projects/tw-logs/w23/integrate/perf-combined.txt
# Format: "portraits draws=NNN tris=NNN  landscape draws=NNN tris=NNN"
```
Target ≤150 portrait draws; document the actual number. If above 150, log as a known gap — do NOT hold ship.

### Step 4 — Screenshots + XCOM comparison
Take phone-size screenshots (844×390 Low) of:
- w23-battle.png — battle view showing terrain variety and lighter grid
- w23-aim.png — aim view with one compact odds card, unobstructed sight line
- w23-impact.png — blast/hit frame showing pooled flash + smoke
- w23-temple.png — Temple room with focal props and varied lighting
- w23-galaxy.png — galaxy phone view showing scaled planet + mission card

Also take:
- w23-units.png — unit close view showing armor accents and LOD

Save all to /home/jess/projects/tw-logs/w23/integrate/.

Compare with XCOM 2 reference shots in /home/jess/projects/tw-reference/.
Write /home/jess/projects/tw-reference/W23-GAPS.md (3–8 visual gaps vs XCOM 2).

Combine W23 shots + XCOM reference into one side-by-side JPG:
/home/jess/projects/tw-logs/w23/integrate/w23-xcom-compare.jpg

Create a before/after report sheet (W22 vs W23, 4 key screens, one JPG):
/home/jess/projects/tw-logs/w23/integrate/w23-report-sheet.jpg
Use W22 reference captures from /home/jess/projects/tw-logs/w22/integrate/ as "before".

### Step 5 — Merge and ship
1. Confirm current branch and target:
```bash
git branch --show-current   # must be w23/integrate
git -C /home/jess/projects/temple-watch log --oneline -3  # confirm main base b8a8bde
```

2. Merge w23/integrate into main:
```bash
git -C /home/jess/projects/temple-watch merge --no-ff w23/integrate \
  -m "W23: terrain + cover variety, unit LOD + armor, Low phone haze/contacts/VFX, Temple cutaway + galaxy scale, battle HUD and UI tokens"
```

3. Push origin main:
```bash
git -C /home/jess/projects/temple-watch push origin main
git -C /home/jess/projects/temple-watch ls-remote origin main
```
Local HEAD must equal remote.

4. Tag last-good:
```bash
git -C /home/jess/projects/temple-watch tag -f last-good
git -C /home/jess/projects/temple-watch push origin last-good --force
```

5. Web export:
```bash
cd /home/jess/projects/temple-watch && tools/web/export_web.sh 2>&1 | tail -20
```

6. Push to tw-play-site (DO NOT SKIP):
```bash
rsync -av /home/jess/projects/temple-watch/build/web/ /home/jess/projects/temple-watch-play/
cd /home/jess/projects/temple-watch-play
git add -A
git commit -m "W23 ship"
git push
```

7. Verify live:
```bash
curl -sI https://mjessm1117.github.io/temple-watch-play/index.pck | head -4
```
Confirm HTTP 200. File size must differ from W22 (was 45,326,076 bytes).

### Step 6 — Write deliverables
Save to /home/jess/projects/tw-logs/w23/integrate/RESULT.md:
```
PASS
Suites: N, Failures: 0, SCRIPT ERRORs: 0
Normal rescue: N/20
Low portrait draws: NNN (target ≤150; known gap if above)
Live pck: 200, SIZE bytes
Gate log: /home/jess/projects/tw-logs/w23/integrate/gate.log
Report sheet: /home/jess/projects/tw-logs/w23/integrate/w23-report-sheet.jpg
XCOM compare: /home/jess/projects/tw-logs/w23/integrate/w23-xcom-compare.jpg
W23 GAPS: /home/jess/projects/tw-reference/W23-GAPS.md
Main: <SHA> (remote matches)
Play site: <SHA> (remote matches)
```

## Boundaries
- May edit: godot/scripts/combat_scene.gd (saber halo wiring only, if not already present)
- May edit: godot/scripts/campaign/temple.gd and campaign/galaxy.gd (set_ui_safe_rect wiring only, if not already present)
- May edit: godot/test.sh (only to ensure all 5 new suites are registered)
- May edit: any test file ONLY to fix an assertion broken by the lane merges — read the exact error first
- Do NOT modify lane-committed game logic unless a SCRIPT ERROR forces it — then fix only the broken line
- Never commit /home/jess/projects/tw-reference/ content to the game repo
- Always confirm target branch is main before pushing to origin
- Write logs to /home/jess/projects/tw-logs/w23/integrate/, never /tmp
- Duplicate kill cue fix is in lane 2 (units); do not reapply

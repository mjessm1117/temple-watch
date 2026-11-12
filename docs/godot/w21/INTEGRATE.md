# Task: tw-w21-integrate
# Merge all 4 W21 lanes, wire cross-lane connections, gate, XCOM compare, ship Wave 21.

## Goal
Merge the four W21 lane branches into main, apply the cross-lane wiring that each lane
flagged (Arsenal route, Settings entry, Back route), pass the full gate, take XCOM
comparison screenshots, and ship W21 to GitHub Pages.

## Context
- Main repo: /home/jess/projects/temple-watch
- Godot binary: /home/jess/projects/.tools/godot/godot (4.7.2)
- Base: main b0eb42f7 (W20 shipped, 85 suites)
- 4 lane commits to merge (each branched off b0eb42f7):
  - w21/temple  → b5e57ea  (10 files: temple.gd, temple_view.gd, home_badges, home_tabs, research_screen, phone_layout, test.sh, temple21_test, home14_test, home_ui_test)
  - w21/galaxy  → ffd2c2b  (5 files: galaxy.gd, galaxy_map.gd, sith_screen.gd, galaxy21_test, test.sh)
  - w21/menus   → 60f9b89  (12 files: menu.gd, campaign_bridge.gd, hud_phone.gd, opening.gd, story_screen.gd, save_slots.gd, save_load.gd, save_load.tscn, test.sh, home14_test, graphics_test, menus21_test)
  - w21/armory  → 5b014e6  (19 files: squad.gd, ui.gd, promotion_screen.gd, strat_ui.gd, loadout_arsenal.gd, loadout_details.gd, loadout_skill_tree.gd, graphics_options.gd, style21_feedback.gd, style21_preferences.gd, fonts×6, test.sh, armory21_test)
- XCOM 2 reference shots: /home/jess/projects/tw-reference/ (private — NEVER commit)
- Logs: /home/jess/projects/tw-logs/w21/integrate/ (mkdir -p)

## Conflict-prone files (modified by multiple lanes — read before resolving)
- godot/test.sh — all 4 lanes added 1 suite line each. After merges, all 4 lines must be present:
  temple21_test, galaxy21_test, menus21_test, armory21_test.
- godot/tests/home14_test.gd — modified by temple AND menus. After merge, both sets of
  changes must be present. Run the suite standalone to confirm after resolution.

## Steps

### Step 0 — Merge all 4 lanes
From the main repo worktree (w21/integrate branch branched off b0eb42f7):
```bash
git checkout -b w21/integrate
git merge --no-ff w21/temple  -m "W21 integrate: merge temple lane (b5e57ea)"
git merge --no-ff w21/galaxy  -m "W21 integrate: merge galaxy lane (ffd2c2b)"
git merge --no-ff w21/menus   -m "W21 integrate: merge menus lane (60f9b89)"
git merge --no-ff w21/armory  -m "W21 integrate: merge armory lane (5b014e6)"
```
For any conflict: read both sides, keep all functional changes from both. Never silently
drop a change from either side.

After all 4 merges, verify test.sh contains ALL new suite registrations:
```bash
grep -E 'temple21|galaxy21|menus21|armory21' godot/test.sh
```
Must show 4 lines. If any are missing, add them to the suites section.

### Step 1 — Apply cross-lane wiring fixes
These 5 edits wire the entry points that each lane intentionally left for the integrate lane.
Read each file before editing. Make the minimum edit needed.

#### 1a. temple.gd — Arsenal page routes to Squad.open_from_temple
In `godot/scripts/campaign/temple.gd`, inside `_change_page`:
- Find the Arsenal/Loadout branch (currently a stub or placeholder).
- Replace the stub with: `Squad.open_from_temple(get_tree(), selected_id)`
  where `selected_id` is the currently highlighted Jedi id (may be `""` for no selection).
- In `_ready` or `_on_enter_tree`: restore `selected_id` from
  `campaign.state.armory_selected_id` if it exists (may be a new field added by armory lane).

#### 1b. temple.gd — Settings label calls open_settings
In `godot/scripts/campaign/temple.gd`, inside the Settings button/label handler
(added by temple lane in `_build_shell` or `_command`):
- Replace any placeholder with: `CampaignFlow.open_settings()`
  (menus lane built this method in campaign_bridge.gd).

#### 1c. squad.gd — Back button calls back_from_squad
In `godot/scripts/campaign/squad.gd`, inside `_build_footer` or the Back handler:
- Wire Back to: `CampaignFlow.back_from_squad()`
  (menus lane built this method).

#### 1d. menu.gd + hud_phone.gd — settings entries call GraphicsOptions.build_settings_panel
In `godot/scripts/menu.gd`, inside `_phone_settings` (or equivalent phone settings entry):
- Replace any inline settings content or placeholder with:
  `GraphicsOptions.build_settings_panel(settings_container)` or similar,
  using the container/panel node that menu.gd already has for settings content.

In `godot/scripts/hud_phone.gd`, inside `_show_settings`:
- Same: call `GraphicsOptions.build_settings_panel(container)`.

(Armory lane built `GraphicsOptions.build_settings_panel`. Menus lane built the entry points
that call it but left the implementation as a temporary placeholder.)

#### 1e. campaign_bridge.gd — open_settings uses real settings panel
In `godot/scripts/campaign_bridge.gd`, inside `open_settings()`:
- Remove or replace any temporary graphics/placeholder content.
- Call or display `GraphicsOptions.build_settings_panel(panel)` or the equivalent
  node created in armory lane's `style21_preferences.gd`.

After all 5 edits: commit with message
"W21 integrate: wire Arsenal, Settings, and Back across lanes"

### Step 2 — Verify legacy tests pass
Run the suites most likely to be affected by cross-lane merges:
```bash
mkdir -p /home/jess/projects/tw-logs/w21/integrate

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/home14_test.gd -- 2>&1 | tail -10 \
  > /home/jess/projects/tw-logs/w21/integrate/home14-diag.log
grep -E 'SCRIPT ERROR|failures|HOME14' /home/jess/projects/tw-logs/w21/integrate/home14-diag.log

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/home_ui_test.gd -- 2>&1 | tail -10 \
  > /home/jess/projects/tw-logs/w21/integrate/home_ui-diag.log
grep -E 'SCRIPT ERROR|failures|HOME_UI' /home/jess/projects/tw-logs/w21/integrate/home_ui-diag.log
```
If either has failures or SCRIPT ERRORs: diagnose exact line from the log and fix only
that assertion. Do not touch game code — only update the test to match current behavior.
Commit any test fixes: "W21 integrate: fix home14/home_ui assertions after lane merge"

### Step 3 — Full gate
Rsync textures (worktree won't have untracked .webp files from main repo):
```bash
rsync -av --include='*.webp' --include='*.webp.import' --include='*.glb.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/units/ \
  ./godot/assets/units/

rsync -av --include='*.webp' --include='*.webp.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/characters/ \
  ./godot/assets/characters/
```

Headless import:
```bash
/home/jess/projects/.tools/godot/godot --headless --path godot/ --import --quit-after 180 2>&1 | tail -5
```

Full gate:
```bash
./godot/test.sh > /home/jess/projects/tw-logs/w21/integrate/gate.log 2>&1
echo "GATE_EXIT=$?"
grep -E 'SCRIPT ERROR|failures|Normal' /home/jess/projects/tw-logs/w21/integrate/gate.log | tail -20
```

Must exit 0, 0 SCRIPT ERROR, 0 failures, Normal rescue 9–11/20.
If any suite fails: diagnose exact error, fix only the failing assertion, re-run, repeat.
Do NOT proceed to ship with any failure.

### Step 4 — Screenshots + XCOM comparison
Take phone-size screenshots (844x390) of:
- w21-temple.png — Temple home screen showing room drill-in
- w21-galaxy.png — Galaxy/campaign map, portrait view
- w21-menus.png — Save slot screen or settings screen
- w21-armory.png — Armory/loadout or skill tree
Save to /home/jess/projects/tw-logs/w21/integrate/.

Compare with XCOM 2 reference shots in /home/jess/projects/tw-reference/.
Write /home/jess/projects/tw-reference/W21-GAPS.md (3–8 visual gaps vs XCOM 2).

Combine W21 shots + XCOM reference into one side-by-side JPG:
/home/jess/projects/tw-logs/w21/integrate/w21-xcom-compare.jpg

Create a before/after report sheet (W20 vs W21, 2 key screens):
/home/jess/projects/tw-logs/w21/integrate/w21-report-sheet.jpg
Use W20 reference shots from /home/jess/projects/tw-logs/w20/integrate/p2/ as "before".

### Step 5 — Merge and ship

1. Confirm current branch and target:
```bash
git branch --show-current   # must be w21/integrate
git -C /home/jess/projects/temple-watch log --oneline -3  # confirm main base
```

2. Merge w21/integrate into main repo:
```bash
git -C /home/jess/projects/temple-watch merge --no-ff w21/integrate \
  -m "W21: Temple portrait hub, Galaxy + Shadow War portrait, menus + saves, armory style"
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
git commit -m "W21 ship"
git push
```

7. Verify live:
```bash
curl -sI https://mjessm1117.github.io/temple-watch-play/index.pck | head -4
```
Confirm HTTP 200. File size must differ from W20 (was 44,344,944 bytes).

### Step 6 — Write deliverables
Save to /home/jess/projects/tw-logs/w21/integrate/RESULT.md:
```
PASS
Suites: N, Failures: 0, SCRIPT ERRORs: 0
Normal rescue: N/20
Live pck: 200, SIZE bytes
Gate log: /home/jess/projects/tw-logs/w21/integrate/gate.log
Report sheet: /home/jess/projects/tw-logs/w21/integrate/w21-report-sheet.jpg
XCOM compare: /home/jess/projects/tw-logs/w21/integrate/w21-xcom-compare.jpg
W21 GAPS: /home/jess/projects/tw-reference/W21-GAPS.md
Main: <SHA> (remote matches)
Play site: <SHA> (remote matches)
```

## Boundaries
- May edit: godot/scripts/campaign/temple.gd, squad.gd, campaign_bridge.gd,
  menu.gd, hud_phone.gd (wiring only — do not rearchitect)
- May edit: godot/tests/home14_test.gd, godot/tests/home_ui_test.gd
  (only to fix assertions broken by lane merges — read the exact error first)
- May edit: godot/test.sh (only to ensure all 4 new suites are registered)
- Do NOT modify game logic or scene structure beyond the 5 wiring fixes above.
- Do NOT modify lane-committed files (temple_view.gd, galaxy.gd, loadout_arsenal.gd, etc.)
  unless a SCRIPT ERROR forces it — then fix only the broken line.
- Never commit /home/jess/projects/tw-reference/ content to the game repo.
- Always confirm target branch is main before pushing to origin.
- Write logs to /home/jess/projects/tw-logs/w21/integrate/, never /tmp.

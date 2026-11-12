# Task: tw-w20-integrate
# Fix known test breaks, wire suites, gate, XCOM comparison, ship Wave 20.

## Goal
Fix 4 known assertion breaks from W20 lanes, wire new test suites into test.sh,
pass the full gate, do XCOM side-by-side, and ship W20 to GitHub Pages.

## Context
- Main repo: /home/jess/projects/temple-watch
- Godot binary: /home/jess/projects/.tools/godot/godot (4.7.2)
- Task runs from a worktree branched off local main (all 6 W20 lanes merged).
- Last shipped: af28fe9 (W19). Local main ead414d is 6 wave merges ahead, unpushed.
- XCOM 2 reference shots: /home/jess/projects/tw-reference/ (private — NEVER commit to game repo)
- Logs: /home/jess/projects/tw-logs/w20/integrate/ (mkdir -p)

## Known breaks to fix

### 1. cam16_test.gd — 2 failures
Old assertions expect yaw == PI/4 (fixed 45° camera). W20 camera lane now computes
yaw dynamically via BattleCamera.battle_heading(mission), which returns a snapped
multiple of PI/4 based on enemy/objective positions.
Fix: update the 2 failing assertions to check the angle is a finite float snapped to
a multiple of PI/4, not assert it equals exactly PI/4.

### 2. loop_test.gd — flow failures
Old test expects game state machine: START → Temple.
W20 story lane inserted an opening cinematic: START → "opening" → Temple.
Fix: update loop_test expected transition sequence to include the new "opening" state.

### 3. loadout_details.gd — may have SCRIPT ERRORs in squad card callback
W20 story and loadout lanes modified campaign_bridge.gd. The loadout lane touched
loadout_details.gd (4 lines), but verify no SCRIPT ERRORs remain by checking the
first gate run. If errors found, trace the broken callback and fix.

### 4. tap16_test.gd — 74 failures
Old test asserts primary buttons >= 56px and rejects the map drawer overlay.
W20 strategy/phone lanes changed button minimums (44px per OWNER rule 12).
Fix: update size threshold from 56 to 44, and update any assertion that rejects the
new drawer overlay (it is now valid UI).

## Steps

### Step 0 — Read first
Before writing any fix:
- Read godot/tests/cam16_test.gd (find the 2 yaw assertions)
- Read godot/tests/loop_test.gd (find the state sequence assertions)
- Read godot/tests/tap16_test.gd (find the button size check)
- Read godot/test.sh (find the suite registration section)

### Step 1 — Fix assertions
Fix all 4 items. After EACH fix, run the specific suite to confirm it passes before moving on:
```bash
/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/cam16_test.gd -- 2>&1 | tail -5
```

For loadout_details.gd: first run `./godot/test.sh 2>&1 | grep "SCRIPT ERROR" | head -10`
to find exact error lines before editing.

### Step 2 — Wire 4 new test suites into test.sh
Read test.sh. Find the suite list section. Add (loadout20 is already wired by the loadout lane):
- godot/tests/camera20_test.gd
- godot/tests/story20_test.gd
- godot/tests/strategy20_test.gd
- godot/tests/art20_test.gd

Commit: "W20 integrate: fix cam16/loop/tap16 assertions, wire camera20/story20/strategy20/art20 suites"

### Step 3 — Gate (rsync textures first, then import, then test.sh)
This worktree lacks untracked .webp textures from the main repo. Run in this order:

1. Rsync untracked textures:
```bash
rsync -av --include='*.webp' --include='*.webp.import' --include='*.glb.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/units/ \
  ./godot/assets/units/
```

2. Headless import:
```bash
/home/jess/projects/.tools/godot/godot --headless --path godot/ --import --quit-after 180 2>&1 | tail -5
```

3. Full gate:
```bash
mkdir -p /home/jess/projects/tw-logs/w20/integrate
./godot/test.sh > /home/jess/projects/tw-logs/w20/integrate/gate.log 2>&1
echo "GATE_EXIT=$?"
grep -E 'SCRIPT ERROR|failures|Normal' /home/jess/projects/tw-logs/w20/integrate/gate.log | tail -20
```

Must exit 0, 0 SCRIPT ERROR, 0 failures, Normal rescue 9–11/20.
If ANY suite fails, diagnose and fix before proceeding.

### Step 4 — Take 4 phone-size screenshots (844x390)
Use the existing screenshot tooling (tools/screenshot_scene.gd or gate runner pattern).
Save:
- w20-battle.png — battle map view, units visible
- w20-aim.png — aim/targeting active
- w20-temple.png — Temple home screen
- w20-galaxy.png — galaxy/campaign map

All saved to /home/jess/projects/tw-logs/w20/integrate/.

Compare with XCOM 2 reference shots in /home/jess/projects/tw-reference/.
Write /home/jess/projects/tw-reference/W20-GAPS.md with 3–8 visual gap items.

Combine into one side-by-side JPG (W20 shots + XCOM reference shots):
/home/jess/projects/tw-logs/w20/integrate/w20-xcom-compare.jpg

### Step 5 — Before/after report sheet
Create a 2-panel before/after JPG: W19 reference vs W20 for 2 key screens.
Use any existing screenshots from docs/godot/shots/ or tw-logs/w18/ or tw-logs/w19/ as "before".
Save to /home/jess/projects/tw-logs/w20/integrate/w20-report-sheet.jpg.

### Step 6 — Merge integrate branch into main repo and ship

1. Merge w20/integrate into main repo (from main repo, not from worktree):
```bash
git -C /home/jess/projects/temple-watch merge --no-ff w20/integrate \
  -m "W20 integrate: test fixes, all suites wired, gate clean"
```

2. Push main to origin:
```bash
git -C /home/jess/projects/temple-watch push origin main
```
Verify: `git -C /home/jess/projects/temple-watch ls-remote origin main`
Local HEAD must equal remote.

3. Tag last-good:
```bash
git -C /home/jess/projects/temple-watch tag -f last-good
git -C /home/jess/projects/temple-watch push origin last-good --force
```

4. Web export (from main repo root):
```bash
cd /home/jess/projects/temple-watch && tools/web/export_web.sh 2>&1 | tail -20
```

5. Push to tw-play-site (DO NOT SKIP — export_web.sh only builds to build/web/, does NOT push):
```bash
# Find tw-play-site path (check export_web.sh script for the rsync target, likely temple-watch-play):
SITE_DIR=$(grep -E 'rsync|temple-watch-play' /home/jess/projects/temple-watch/tools/web/export_web.sh | head -3)
# Then rsync build output to the site and push:
rsync -av /home/jess/projects/temple-watch/build/web/ /home/jess/projects/temple-watch-play/
cd /home/jess/projects/temple-watch-play
git add -A
git commit -m "W20 ship"
git push
```

6. Verify live:
```bash
curl -sI https://mjessm1117.github.io/temple-watch-play/index.pck | head -4
```
Confirm HTTP 200. File size must differ from W19 (was 42,965,660 bytes).

### Step 7 — Write deliverables
Save to /home/jess/projects/tw-logs/w20/integrate/RESULT.md:
```
PASS|FAIL
Suites: N, Failures: 0, SCRIPT ERRORs: 0
Normal rescue: N/20
Live pck: 200, SIZE bytes
Gate log: /home/jess/projects/tw-logs/w20/integrate/gate.log
Report sheet: /home/jess/projects/tw-logs/w20/integrate/w20-report-sheet.jpg
XCOM compare: /home/jess/projects/tw-logs/w20/integrate/w20-xcom-compare.jpg
W20 GAPS: /home/jess/projects/tw-reference/W20-GAPS.md
```

## Boundaries
- May edit: godot/tests/cam16_test.gd, godot/tests/loop_test.gd, godot/tests/tap16_test.gd,
  godot/scripts/campaign/loadout_details.gd, godot/test.sh
- Read the failing test lines before writing any fix. Never guess.
- Do NOT modify gameplay scripts beyond the broken callbacks above.
- Never commit /home/jess/projects/tw-reference/ content to the game repo.
- Always confirm target branch is main before pushing to origin.
- Write logs to /home/jess/projects/tw-logs/w20/integrate/, never /tmp.

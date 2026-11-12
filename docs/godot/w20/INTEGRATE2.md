# Task: tw-w20-integrate2
# Fix 3 remaining legacy test failures, run full gate, ship Wave 20.
# Pass 1 already committed: cam16/loop/tap16 fixes + all W20 suites wired.

## Goal
Fix 3 legacy tests broken by W20 lanes, pass the full gate (85 suites, 0 failures),
take XCOM comparison screenshots, and ship Wave 20.

## Context
- Main repo: /home/jess/projects/temple-watch
- Godot binary: /home/jess/projects/.tools/godot/godot (4.7.2)
- Base: current local main (d472034) — all W20 lanes + pass-1 test fixes merged.
- Already passing: camera20, story20, strategy20, art20, loadout20 — 0 failures each.
- 85 suites registered. 3 still fail (new test run to confirm before editing):
  1. screens_test.gd — opening cinematic flow + SCRIPT ERROR
  2. integration_test.gd — first-mission guard + SCRIPT ERROR
  3. home13_test.gd — Galaxy Back closes details first
- XCOM 2 reference shots: /home/jess/projects/tw-reference/ (private — NEVER commit to game repo)
- Logs: /home/jess/projects/tw-logs/w20/integrate/ (already exists)

## Steps

### Step 0 — Diagnose exact failures
Run only the 3 failing suites to get the exact error messages:
```bash
mkdir -p /home/jess/projects/tw-logs/w20/integrate/p2

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/screens_test.gd -- 2>&1 | tail -20 \
  > /home/jess/projects/tw-logs/w20/integrate/p2/screens-diag.log

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/integration_test.gd -- 2>&1 | tail -20 \
  > /home/jess/projects/tw-logs/w20/integrate/p2/integration-diag.log

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/home13_test.gd -- 2>&1 | tail -20 \
  > /home/jess/projects/tw-logs/w20/integrate/p2/home13-diag.log

grep -E 'SCRIPT ERROR|assert|FAIL|ERROR:|Parse' \
  /home/jess/projects/tw-logs/w20/integrate/p2/{screens,integration,home13}-diag.log
```

Read each test file BEFORE editing it. Understand what the test checks, then make the
minimum fix to match current W20 behavior.

### Step 1 — Fix screens_test.gd
Root cause: W20 story lane added opening.tscn + opening.gd, changing game flow from
START → Temple to START → opening → Temple.
Expected fix: update the screen-flow assertions to include the opening cinematic state.
If SCRIPT ERROR is from a changed function name/signature (game.gd or campaign_bridge.gd
changed in W20 lanes), find the new function name and update the test.
Confirm passes: run the suite standalone, confirm 0 failures, 0 SCRIPT ERROR.

### Step 2 — Fix integration_test.gd
Root cause: opening cinematic + loadout flow changes (campaign_bridge.gd, squad.gd) may
have changed what happens on first game start. The "first-mission guard" check likely
asserts the first mission setup.
Expected fix: update integration_test to match the new flow (opening → loadout → first mission).
If SCRIPT ERROR: trace the exact line in the diagnostic log and fix the broken reference.
Confirm passes: run standalone, 0 failures, 0 SCRIPT ERROR.

### Step 3 — Fix home13_test.gd
Root cause: W20 strategy lane resized galaxy.gd (74 lines). "Galaxy Back closes details first"
suggests a nav assertion about what happens when Back is pressed while a galaxy detail panel
is open. The strategy lane may have changed the state flow.
Expected fix: update the assertion to match current galaxy.gd Back button behavior.
Confirm passes: run standalone, 0 failures, 0 SCRIPT ERROR.

### Step 4 — Commit and run full gate
Commit all 3 fixes:
"W20 integrate pass 2: fix screens/integration/home13 test assertions"

Then run the full gate with rsync textures + headless import:
```bash
# Rsync untracked textures (worktree won't have them):
rsync -av --include='*.webp' --include='*.webp.import' --include='*.glb.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/units/ \
  ./godot/assets/units/

# Headless import:
/home/jess/projects/.tools/godot/godot --headless --path godot/ --import --quit-after 180 2>&1 | tail -5

# Full gate:
./godot/test.sh > /home/jess/projects/tw-logs/w20/integrate/p2/gate.log 2>&1
echo "GATE_EXIT=$?"
grep -E 'SCRIPT ERROR|failures|Normal' /home/jess/projects/tw-logs/w20/integrate/p2/gate.log | tail -20
```

Must exit 0, 0 SCRIPT ERROR, 0 failures, Normal rescue 9–11/20.
If any suite still fails: read the exact error and fix before proceeding.

### Step 5 — Screenshots + XCOM comparison
Take phone-size screenshots (844x390) of:
- w20-battle.png — battle map view, units visible
- w20-aim.png — aim/targeting active
- w20-temple.png — Temple home screen
- w20-galaxy.png — galaxy/campaign map
Save to /home/jess/projects/tw-logs/w20/integrate/p2/.

Compare with XCOM 2 reference shots in /home/jess/projects/tw-reference/.
Write /home/jess/projects/tw-reference/W20-GAPS.md (3–8 visual gaps vs XCOM 2).

Combine W20 shots + XCOM reference into one side-by-side JPG:
/home/jess/projects/tw-logs/w20/integrate/p2/w20-xcom-compare.jpg

Create a before/after report sheet (W19 vs W20, 2 key screens):
/home/jess/projects/tw-logs/w20/integrate/p2/w20-report-sheet.jpg

### Step 6 — Merge and ship
1. Merge this branch into main repo:
```bash
git -C /home/jess/projects/temple-watch merge --no-ff w20/integrate2 \
  -m "W20 integrate pass 2: fix screens/integration/home13, gate clean"
```

2. Push origin main:
```bash
git -C /home/jess/projects/temple-watch push origin main
git -C /home/jess/projects/temple-watch ls-remote origin main
```
Local HEAD must equal remote.

3. Tag last-good:
```bash
git -C /home/jess/projects/temple-watch tag -f last-good
git -C /home/jess/projects/temple-watch push origin last-good --force
```

4. Web export:
```bash
cd /home/jess/projects/temple-watch && tools/web/export_web.sh 2>&1 | tail -20
```

5. Push to tw-play-site (DO NOT SKIP — export_web.sh only builds to build/web/):
```bash
# Find where the site lives and push (likely temple-watch-play):
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
Save to /home/jess/projects/tw-logs/w20/integrate/p2/RESULT.md:
```
PASS
Suites: 85, Failures: 0, SCRIPT ERRORs: 0
Normal rescue: N/20
Live pck: 200, SIZE bytes
Gate log: /home/jess/projects/tw-logs/w20/integrate/p2/gate.log
Report sheet: /home/jess/projects/tw-logs/w20/integrate/p2/w20-report-sheet.jpg
XCOM compare: /home/jess/projects/tw-logs/w20/integrate/p2/w20-xcom-compare.jpg
W20 GAPS: /home/jess/projects/tw-reference/W20-GAPS.md
```

## Boundaries
- May edit: godot/tests/screens_test.gd, godot/tests/integration_test.gd, godot/tests/home13_test.gd
- Read the exact diagnostic error BEFORE writing any fix.
- Do NOT modify gameplay scripts unless the test references a function that was renamed —
  then update only the function call in the test, not the game code.
- Never commit /home/jess/projects/tw-reference/ content to the game repo.
- Write logs to /home/jess/projects/tw-logs/w20/integrate/p2/, never /tmp.
- Always confirm target branch is main before pushing to origin.

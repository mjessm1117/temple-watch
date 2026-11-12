# W25 Ship Spec

## Goal
Merge Wave 25 (Menus & Temple deepening) onto main, pass the gate, take screenshots,
do the XCOM 2 side-by-side, push + tag last-good, export to web, and write the
wave report content.

## Context
- Main repo: `/home/jess/projects/temple-watch` (branch main, HEAD 4f2e4c7)
- Integrate worktree: `/home/jess/projects/tw-w25/integrate` (branch w25/integrate, HEAD 3e70738)
- 15 commits above base 4f2e4c7 on w25/integrate (see git log)
- Uncommitted on integrate: `godot/tests/galaxy25_test.gd` — legitimate test fixes
  (super.advance_strategy_day25, NoClockCampaign class, contact income settle check,
  real scan site check). NOT debug prints. Commit them first.
- Godot binary: `/home/jess/projects/.tools/godot/godot`
- Play site: `/home/jess/projects/tw-play-site` (GitHub Pages)
- XCOM 2 reference shots: `/home/jess/projects/tw-reference/phone/` (never commit these)
- Log dir: `/home/jess/projects/tw-logs/w25/ship/`

## Steps

### Step 1 — Commit galaxy25_test.gd cleanup
In `/home/jess/projects/tw-w25/integrate`:
```bash
git add godot/tests/galaxy25_test.gd
git commit -m "fix(galaxy25_test): super.advance_strategy_day25, NoClockCampaign, contact income settle"
```

### Step 2 — Merge onto main
In `/home/jess/projects/temple-watch`:
```bash
git fetch origin
git checkout main
git merge --no-ff w25/integrate -m "Wave 25: Temple deepening, economy loop, galaxy contacts, roster care, menus"
```
Resolve no conflicts expected (integrate was based on main 4f2e4c7).

### Step 3 — Headless import + full gate
```bash
/home/jess/projects/.tools/godot/godot --headless --import 2>&1 | tail -10
./godot/test.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/ship/gate.log
```
Must exit 0, 0 SCRIPT ERRORs, 0 failures, Normal rescue 9–11/20.
If gate fails: DO NOT push. Write BLOCKED in `/home/jess/projects/tw-logs/w25/ship/BLOCKED.md` and stop.

### Step 4 — Screenshots
Take 4 screenshots at 844x390 (phone portrait) and 1366x768 (desktop) of:
1. Temple home (rooms visible)
2. Galaxy map (contacts / deadline rail visible)
3. Battle view (phone)
4. Armory or roster (squads / care)

Tool: `node /home/jess/hive/tools/screenshot.cjs <url> <path>`
Local server: `godot --headless --export-web` or use the existing live build for reference.
Save as: `/home/jess/projects/tw-logs/w25/ship/w25-phone-{name}.png`

Then combine into ONE JPG sheet (≤10MB, Discord limit):
```bash
ffmpeg -i /home/jess/projects/tw-logs/w25/ship/w25-phone-*.png \
  -filter_complex "tile=2x2" /home/jess/projects/tw-logs/w25/ship/w25-report-sheet.jpg
```

### Step 5 — XCOM 2 side-by-side
Reference shots: `/home/jess/projects/tw-reference/phone/` and `/home/jess/projects/tw-reference/`
Compare:
- Temple home vs XCOM Avenger base
- Galaxy vs XCOM tactical globe / strategy layer
- Battle vs XCOM combat

List the top 3 remaining gaps in `/home/jess/projects/tw-logs/w25/ship/XCOM-GAPS.md`.
Do NOT copy reference images anywhere near the repo.

### Step 6 — npm test (web game guard)
In `/home/jess/projects/temple-watch`:
```bash
npm test 2>&1 | tail -10
```
Must exit 0, 0 FAIL.

### Step 7 — Push main + tag last-good
```bash
git push origin main
git tag -f last-good
git push origin last-good --force
```

### Step 8 — Web export
```bash
cd /home/jess/projects/temple-watch
bash tools/web/export_web.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/ship/export.log
```
Check for `[ DONE ] savepack` in export.log. If the export script exits non-zero but
index.pck exists and is > 10 MB, the SIGABRT benign crash pattern — treat as success.

Then push the play site:
```bash
cd /home/jess/projects/tw-play-site
rsync -a --delete /home/jess/projects/temple-watch/build/web/ .
git add -A
git commit -m "W25 ship: Temple deepening, economy, galaxy contacts, roster care"
git push origin main
```

### Step 9 — Verify live
```bash
curl -sI https://mjessm1117.github.io/temple-watch-play/index.pck | head -5
```
Must return HTTP 200. Record the Content-Length.

### Step 10 — Write wave report content
Write to `/home/jess/projects/tw-logs/w25/ship/REPORT.md`:

```
# W25 Wave Report

## Before/After
[path to w25-report-sheet.jpg]

## What changed for the player (3 bullets)
- Temple home: ...
- Galaxy map: ...
- Between missions: ...

## Phone link
https://mjessm1117.github.io/temple-watch-play/

## Known gaps vs XCOM 2
[top 3 from XCOM-GAPS.md]
```

Fill in the bullets based on the actual changes in the wave (from git log).
Plain English only. No commit hashes, no test counts.

## Outputs
- Gate log: `/home/jess/projects/tw-logs/w25/ship/gate.log`
- Report sheet: `/home/jess/projects/tw-logs/w25/ship/w25-report-sheet.jpg`
- XCOM gaps: `/home/jess/projects/tw-logs/w25/ship/XCOM-GAPS.md`
- Wave report: `/home/jess/projects/tw-logs/w25/ship/REPORT.md`
- Play site SHA: record in `/home/jess/projects/tw-logs/w25/ship/deploy.txt`

## Quality gate (all must pass before push)
- Godot gate: exit 0, 0 SCRIPT ERRORs, 0 failures, Normal rescue 9/20
- npm test: exit 0, 0 FAIL
- curl live pck: HTTP 200

## Boundaries
- Touch only the merge + test.sh artifacts. No new feature work.
- Do not commit XCOM 2 reference images anywhere near the repo.
- Do not use `git stash -u` or `git clean -fd` (untracked fleet files).
- If the gate fails, STOP and write BLOCKED. Do not push a broken build.
- The old web game in `public/` is frozen — do not touch it.

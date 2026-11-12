# W26 Integrate Spec

## Goal
Merge all 4 Wave 26 lanes, run the full gate, and ship to main + play site.

## Context
- Base commit: ce62160 (W25 main / last-good)
- Project root: /home/jess/projects/temple-watch
- Branches to merge (all off ce62160):
  - w26/gate  — difficulty: 4 enemies (was 6), all in front arc, reinforcements deferred to T3+
  - w26/side  — friend/foe colors: enemy RED rim+band, ally BLUE rim+band, cover tints
  - w26/hud   — phone HUD: tofu glyphs, AP ring inside button, portrait 52px, objective expand
  - w26/preview — test assertion update for HUD range alpha constant
- Play site: /home/jess/projects/tw-play-site
- Export: tools/export_web.sh (check index.pck existence on non-zero exit — SIGABRT benign)
- Gate clean = 0 test failures AND 0 SCRIPT ERRORs. GL texture leak lines ("leaked N bytes") at shutdown are benign, NOT failures.

## Steps

### 1. Create integration worktree
```
mkdir -p /home/jess/projects/tw-logs/w26/integrate
git worktree add /home/jess/projects/temple-watch-w26-integrate -b w26/integrate ce62160
cd /home/jess/projects/temple-watch-w26-integrate
```

### 2. Merge lanes in order (fail fast on conflict)
```
git merge --no-edit w26/gate
git merge --no-edit w26/side
git merge --no-edit w26/hud
git merge --no-edit w26/preview
```
If ANY merge conflict: STOP immediately, report the conflicting files, do not proceed.

### 3. Headless import
```
/home/jess/projects/.tools/godot/godot --headless --path godot --import \
  > /home/jess/projects/tw-logs/w26/integrate/import.log 2>&1
```

### 4. Full gate
```
bash godot/test.sh > /home/jess/projects/tw-logs/w26/integrate/gate.log 2>&1
```
Parse gate.log:
- Sum all "N failures" values — must be 0.
- Count "SCRIPT ERROR" lines — must be 0.
- Ignore "leaked N bytes" (benign GL cleanup).
If failures > 0 or SCRIPT ERRORs > 0: report and STOP. Do NOT ship.

### 5. Commit integration
```
git add -A
git commit -m "Wave 26: Battle difficulty, friend/foe colors, phone HUD readability

- First battle: 4 enemies (was 6), all in front arc, reinforcements deferred to T3+
- Enemy rim/band: RED; ally rim/band: BLUE — clear side reads at a glance
- Cover tints: full cover blue-grey, half cover warm-tan
- Phone HUD: tofu glyphs replaced, AP ring inside button slot
- Phone HUD: portrait 52px, objective label fills strip, alert hides during CONTACT radio

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### 6. Fast-forward main + tag
```
cd /home/jess/projects/temple-watch
git fetch . w26/integrate:main
git tag -f last-good main
git push origin main --tags
```

### 7. Export + push play site
```
cd /home/jess/projects/temple-watch-w26-integrate
bash tools/export_web.sh > /home/jess/projects/tw-logs/w26/integrate/export.log 2>&1
export_exit=$?
if [ -f build/web/index.pck ]; then
  rsync -av --delete build/web/ /home/jess/projects/tw-play-site/
  cd /home/jess/projects/tw-play-site
  git add -A
  git commit -m "W26: Battle difficulty, colors, phone HUD"
  git push origin main
  echo "PLAY_SITE_PUSHED=1"
else
  echo "ERROR: index.pck missing, export failed"
  exit 1
fi
```

### 8. Live screenshot
```
node /home/jess/hive/tools/screenshot.cjs \
  https://mjessm1117.github.io/temple-watch-play/ \
  /home/jess/projects/tw-logs/w26/report/live-phone.png
```

### 9. XCOM side-by-side note
List top 3 remaining gaps vs XCOM iOS shots in /home/jess/projects/tw-reference/phone/. Write to /home/jess/projects/tw-logs/w26/report/GAPS.md.

## Output
- main + last-good = new W26 commit
- Play site live: https://mjessm1117.github.io/temple-watch-play/
- Gate log: /home/jess/projects/tw-logs/w26/integrate/gate.log
- Screenshots: /home/jess/projects/tw-logs/w26/report/

## Boundaries
- No new code. Integrate only.
- Merge conflicts → stop and report.
- Gate failures → stop and report. Never ship a red gate.
- Do not modify any lane branches (w26/gate, w26/side, w26/hud, w26/preview).

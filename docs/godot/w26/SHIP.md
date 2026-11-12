# W26 Ship Spec

## Context
- w26/integrate is at commit d676da7 (gate passed: 0 failures, 0 SCRIPT ERRORs)
- Verified by: /home/jess/projects/tw-logs/w26/fix4/gate.log (task-09c7e4c5)
- main/last-good still at ce62160 (W25). Play site still W25.
- Worktree: /home/jess/projects/temple-watch-w26-integrate

## Steps

### 1. Verify pre-ship state
```
cd /home/jess/projects/temple-watch-w26-integrate
git log --oneline -2
git status --short --untracked-files=no
```
Confirm HEAD = d676da7, working tree clean.

### 2. Fast-forward main to W26
```
cd /home/jess/projects/temple-watch
git fetch . w26/integrate:main
git log --oneline main -1
```
Confirm main is now at d676da7 (or latest on w26/integrate).

### 3. Tag last-good + push
```
git tag -f last-good main
git push origin main --tags
git ls-remote origin main refs/tags/last-good
```
Confirm remote main = d676da7.

### 4. Export web build
```
cd /home/jess/projects/temple-watch-w26-integrate
mkdir -p /home/jess/projects/tw-logs/w26/ship
bash tools/export_web.sh > /home/jess/projects/tw-logs/w26/ship/export.log 2>&1
export_exit=$?
if [ -f build/web/index.pck ]; then
    echo "EXPORT_OK: $(stat -c%s build/web/index.pck) bytes"
else
    echo "EXPORT_FAILED: index.pck not found"
    exit 1
fi
```
(Exit code non-zero is benign if index.pck exists — SIGABRT at shutdown.)

### 5. Push play site
```
rsync -av --delete build/web/ /home/jess/projects/tw-play-site/
cd /home/jess/projects/tw-play-site
git add -A
git commit -m "W26: Battle difficulty, colors, phone HUD

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push origin main
git log --oneline -1
```

### 6. Screenshots (for wave report)
Take a screenshot of the live play site after GitHub Pages deploys (~2 min):
```
sleep 90
node /home/jess/hive/tools/screenshot.cjs \
  https://mjessm1117.github.io/temple-watch-play/ \
  /home/jess/projects/tw-logs/w26/report/live-title.png
```

Also take headless in-battle screenshots at 844×390 and 390×844:
```
mkdir -p /home/jess/projects/tw-logs/w26/report
xvfb-run -a /home/jess/projects/.tools/godot/godot \
  --path /home/jess/projects/temple-watch-w26-integrate/godot \
  --rendering-method gl_compatibility --resolution 844x390 \
  -s tests/battle26_visual_test.gd -- --graphics=low --screenshot=/home/jess/projects/tw-logs/w26/report/battle-landscape.png 2>/dev/null || true
```
(If battle26_visual_test doesn't exist, skip the headless battle shot — the live site screenshot is sufficient.)

### 7. XCOM side-by-side gaps
Check /home/jess/projects/tw-reference/phone/ for XCOM reference shots.
Write /home/jess/projects/tw-logs/w26/report/GAPS.md:
Top 3 remaining gaps vs XCOM iOS phone, specific and player-visible.

### 8. Report summary
Write /home/jess/projects/tw-logs/w26/report/WAVE-REPORT.md:
- 3 player-visible bullets (what changed in this wave, plain English)
- Play link
- Known gaps vs XCOM

## Output
- main + last-good = W26 commit
- Play site live: https://mjessm1117.github.io/temple-watch-play/
- Screenshots: /home/jess/projects/tw-logs/w26/report/
- Report: /home/jess/projects/tw-logs/w26/report/WAVE-REPORT.md

## Boundaries
- Do NOT modify any game code. Ship only.
- If git push fails: report the error and stop.
- If export produces 0-byte or missing index.pck: stop and report.

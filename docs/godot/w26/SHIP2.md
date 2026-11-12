# W26 Ship2 — Export + Play Site + Screenshots

## Context
- main + last-good = d676da7 (W26, confirmed on remote)
- Play site still at W25. This task completes the ship.
- Worktree for export: /home/jess/projects/temple-watch-w26-integrate

## Steps

### 1. Export web build
```
cd /home/jess/projects/temple-watch-w26-integrate
mkdir -p /home/jess/projects/tw-logs/w26/ship
bash tools/export_web.sh > /home/jess/projects/tw-logs/w26/ship/export.log 2>&1
export_exit=$?
if [ -f build/web/index.pck ]; then
    echo "EXPORT_OK: $(stat -c%s build/web/index.pck) bytes"
else
    echo "EXPORT_FAILED: index.pck not found (exit $export_exit)"
    cat /home/jess/projects/tw-logs/w26/ship/export.log | tail -20
    exit 1
fi
```
(Non-zero exit is OK if index.pck exists — SIGABRT benign.)

### 2. Push play site
```
rsync -av --delete build/web/ /home/jess/projects/tw-play-site/
cd /home/jess/projects/tw-play-site
git add -A
git commit -m "W26: Battle difficulty, colors, phone HUD

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push origin main
git log --oneline -1
echo "PLAY_SITE_PUSHED"
```

### 3. Wait and screenshot
GitHub Pages takes ~90s to deploy.
```
sleep 100
mkdir -p /home/jess/projects/tw-logs/w26/report
node /home/jess/hive/tools/screenshot.cjs \
  https://mjessm1117.github.io/temple-watch-play/ \
  /home/jess/projects/tw-logs/w26/report/live-title.png
```

### 4. Write wave report
Write /home/jess/projects/tw-logs/w26/report/WAVE-REPORT.md with:
- Commit: d676da7
- Pack size (from EXPORT_OK line)
- Play link
- 3 player-visible bullets (see below — do NOT invent, use exactly these):
  1. First battle starts with 4 enemies (down from 6) — all in front of you, none hiding behind
  2. Allies glow BLUE, enemies glow RED — instant friend/foe read at a glance
  3. Phone HUD: readable fonts (tofu boxes gone), AP ring inside the button, objective text no longer cut off
- Known W26 gaps vs XCOM:
  1. Reinforcement arrival still text-only (no dramatic "INBOUND" animation/sound)
  2. Enemy color reads fine but unit art still looks similar at low phone detail
  3. Portrait phone mode chip layout is tighter than XCOM (less breathing room around status chips)

## Boundaries
- No game code changes.
- If export fails (missing index.pck): report and stop.
- If play site push fails: report exact git error.

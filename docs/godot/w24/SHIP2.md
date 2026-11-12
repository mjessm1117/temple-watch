# W24 Ship — Export + Push Only

## Context
Merge already done: main is at 4d9605dd (W24). Import sanity passed (0 SCRIPT ERROR).
The only failure was web export — prepare_web.py now includes w23_terrain/ and surface_atlas.png
in RUNTIME_RASTER_DIRS (1-line fix already applied to tools/web/prepare_web.py).

## Steps

### 1. Stage and commit the prepare_web.py fix
```
cd /home/jess/projects/temple-watch
git add tools/web/prepare_web.py
git commit -m "Add W23 terrain textures + surface atlas to RUNTIME_RASTER_DIRS"
```

### 2. Export web pack
```
bash tools/web/export_web.sh > /home/jess/projects/tw-logs/w24/ship/export.log 2>&1
rc=$?
tail -5 /home/jess/projects/tw-logs/w24/ship/export.log
printf 'EXPORT_EXIT=%s\n' "$rc"
```
If EXPORT_EXIT != 0, STOP and print the last 40 lines of export.log.
If EXPORT_EXIT=0, confirm build/web/index.pck exists and record its byte size.

### 3. Tag + push main
```
git tag -f last-good HEAD
git push origin main
git push -f origin last-good
```

### 4. Push phone site
```
rsync -av --delete build/web/ /home/jess/projects/tw-play-site/
cd /home/jess/projects/tw-play-site
git add -A
git commit -m "W24: battle feel + controls"
git push origin main
```
Confirm push succeeded and record the site commit SHA.

### 5. Screenshots
```
mkdir -p /home/jess/projects/tw-logs/w24/ship
node /home/jess/hive/tools/screenshot.cjs https://mjessm1117.github.io/temple-watch-play/ /home/jess/projects/tw-logs/w24/ship/w24-phone-title.png
```

Take one more phone-portrait headless screenshot of a battle scene if possible using:
```
/home/jess/projects/.tools/godot/godot --headless --path /home/jess/projects/temple-watch/godot \
  -s tests/battle_capture.gd --resolution 390x844 2>/home/jess/projects/tw-logs/w24/ship/battle-capture.log
```
(If that script doesn't exist, skip it — the title screenshot is enough.)

Combine w24-phone-title.png and any battle shots into a 2-panel contact sheet:
```
ffmpeg -y -i /home/jess/projects/tw-logs/w24/ship/w24-phone-title.png \
  -vf "scale=750:-1" /home/jess/projects/tw-logs/w24/ship/w24-wave-report-sheet.jpg 2>/dev/null || \
  cp /home/jess/projects/tw-logs/w24/ship/w24-phone-title.png /home/jess/projects/tw-logs/w24/ship/w24-wave-report-sheet.jpg
```

### 6. Write SHIP-RESULT.md
Write /home/jess/projects/tw-logs/w24/ship/SHIP-RESULT.md with:
- main SHA
- last-good SHA
- site commit SHA
- pack byte size
- export exit code
- screenshot path(s)

## Boundaries
- Do NOT re-run the full test suite.
- Do NOT modify any game code or test files.
- If the export still fails, STOP and report the first error line.
- If the site push fails, STOP and report.

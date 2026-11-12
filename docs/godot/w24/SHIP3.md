# W24 Ship — Push + Screenshots Only

## Context
Main is at e6bf997 (prepare_web.py fix committed). The web pack already exists:
  build/web/index.pck   46,360,224 bytes   (W24)
Godot crashed on shutdown after completing the export (SIGABRT). The pack is valid.
Do NOT re-run export_web.sh. Just push and ship.

## Step 0: Fix export_web.sh for future waves
The Godot headless exporter can SIGABRT on exit after a successful pack. The script currently
treats non-zero exit as a hard failure. Fix line 14 to tolerate this:

Open tools/web/export_web.sh. Find this line (around line 14):
```
"$godot_bin" --headless --path "$work_dir/godot" --export-release Web "$export_dir/index.html" > "$work_dir/export.log" 2>&1 || { cat "$work_dir/export.log"; exit 1; }
```

Replace with:
```bash
"$godot_bin" --headless --path "$work_dir/godot" --export-release Web "$export_dir/index.html" > "$work_dir/export.log" 2>&1 || {
    # Godot may SIGABRT on shutdown after a successful export (headless crash-on-exit).
    # Treat as success if index.pck was written; fail only if it is missing.
    if [ ! -f "$export_dir/index.pck" ]; then
        cat "$work_dir/export.log"; exit 1
    fi
    echo "Godot exited non-zero (crash on shutdown) but index.pck exists — treating export as success" >&2
}
```

Stage and commit this fix:
```
git add tools/web/export_web.sh
git commit -m "Tolerate Godot headless crash-on-exit after successful export"
```

## Step 1: Tag + push main
```
git tag -f last-good HEAD
git push origin main
git push -f origin last-good
```
Record the main SHA and confirm push output shows "main -> main".

## Step 2: Push phone site
```
rsync -av --delete build/web/ /home/jess/projects/tw-play-site/
cd /home/jess/projects/tw-play-site
git add -A
git commit -m "W24: battle feel + controls"
git push origin main
```
Record the site commit SHA. Confirm push succeeded.

## Step 3: Screenshots
```
mkdir -p /home/jess/projects/tw-logs/w24/ship
node /home/jess/hive/tools/screenshot.cjs https://mjessm1117.github.io/temple-watch-play/ /home/jess/projects/tw-logs/w24/ship/w24-phone-title.png
```
Wait 10 seconds for GitHub Pages to update if needed (site just pushed).

Combine the before/after sheet from integrate with the phone title:
```
cp /home/jess/projects/tw-logs/w24/integrate/2026-11-11-w24-integrate-sheet.jpg /home/jess/projects/tw-logs/w24/ship/w24-wave-sheet.jpg
```

## Step 4: Write SHIP-RESULT.md
Write /home/jess/projects/tw-logs/w24/ship/SHIP-RESULT.md with:
- main SHA (after the export_web fix commit)
- last-good SHA  
- site commit SHA
- pack size: 46,360,224 bytes
- screenshot path(s)
- Status: SHIPPED

## Boundaries
- Do NOT re-run any tests or the export.
- Do NOT modify any game code or test files.
- If main push fails (rejected), STOP and report.
- If site push fails, STOP and report.

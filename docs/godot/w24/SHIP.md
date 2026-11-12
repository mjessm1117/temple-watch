# W24 Ship Spec

## Goal
Merge w24/integrate (108bb381) into main, export the web pack, push main+last-good, and push the phone site. The integrate gate already passed (110 suites 0 fail 0 SCRIPT ERROR Normal 9/20). Re-run a quick sanity import but do NOT re-run the full 110-suite test; that would take too long and already passed.

## Context
- Main repo: /home/jess/projects/temple-watch
- Integrate worktree: /home/jess/projects/tw-w24/integrate (branch w24/integrate, HEAD 108bb381)
- Phone site worktree: /home/jess/projects/tw-play-site
- Current main: aa19dd05
- Target: merge 108bb381 into main, export web pack, push, ship

## Steps

### 1. Merge w24/integrate into main
In /home/jess/projects/temple-watch:
```
git fetch origin
git checkout main
git merge --no-ff /home/jess/projects/tw-w24/integrate/w24/integrate_branch || git merge --no-ff refs/heads/w24/integrate
```
If the branch name doesn't resolve, run: git -C /home/jess/projects/tw-w24/integrate log -1 --format="%H" to get the commit SHA (108bb381) and merge it directly:
```
git merge --no-ff 108bb381 -m "Merge W24 (battle feel + controls): 6 lanes, 110 suites 0 fail"
```

### 2. Quick sanity import
```
cd /home/jess/projects/temple-watch/godot
godot --headless --import 2>&1 | grep -E "(SCRIPT ERROR|Parse Error|ERROR)" | head -20
```
Confirm 0 SCRIPT ERROR lines. If any appear, STOP and report them.

### 3. Export web pack
```
cd /home/jess/projects/temple-watch
bash tools/export_web.sh 2>&1 | tail -20
```
Confirm EXPORT_EXIT=0 and the pack file exists at build/web/index.pck. Record byte size.

### 4. Tag last-good
```
cd /home/jess/projects/temple-watch
git tag -f last-good HEAD
git push origin main --follow-tags
git push origin :refs/tags/last-good 2>/dev/null; git push origin last-good
```

### 5. Push phone site
```
cd /home/jess/projects/temple-watch
bash tools/ship_site.sh 2>&1 | tail -20
```
OR if that script doesn't exist, do it manually:
```
# rsync web build into tw-play-site
rsync -av build/web/ /home/jess/projects/tw-play-site/
cd /home/jess/projects/tw-play-site
git add -A
git commit -m "W24: battle feel + controls (108bb381)"
git push origin main
```

### 6. Take screenshots for the wave report
Take 4 screenshots of the shipped build using the screenshot tool:
```
node /home/jess/hive/tools/screenshot.cjs https://mjessm1117.github.io/temple-watch-play/ /home/jess/projects/tw-logs/w24/ship/w24-phone-title.png
```
Also take a portrait battle screenshot and PC battle screenshot if possible using headless capture.

Combine into a 2×2 or 1×4 grid JPG at /home/jess/projects/tw-logs/w24/ship/w24-wave-report-sheet.jpg using node/sharp or ffmpeg.

### 7. XCOM 2 compare
Reference shots are in /home/jess/projects/tw-reference/. Find the most relevant PC battle reference.
Make a side-by-side /home/jess/projects/tw-logs/w24/ship/w24-xcom-compare.jpg showing:
- Our portrait aim view vs XCOM 2 aim view
- Our PC battle vs XCOM 2 PC battle

### 8. Write result
Write /home/jess/projects/tw-logs/w24/ship/SHIP-RESULT.md with:
- main SHA after merge
- last-good SHA
- site commit SHA
- pack byte size
- import sanity result
- screenshot paths

## Boundaries
- Do NOT re-run the full 110-suite test.sh — it already passed on 108bb381.
- Do NOT modify any game code, specs, or tests.
- Do NOT push to any branch other than origin/main and origin/last-good (and the site).
- If the merge has conflicts, STOP and report the conflicting files.
- If EXPORT_EXIT != 0, STOP and report the error.
- If the site push fails, STOP and report.

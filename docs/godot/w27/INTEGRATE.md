# W27 Integrate Spec

## Context
- Base: d676da7 (W26, main + last-good)
- 4 lanes, all clean, all gated, all committed:
  - A opening: fb0cda7 (tw-w27/opening, branch w27/opening)
  - B preview: dfe4760 (tw-w27/preview, branch w27/preview)
  - C phone: 5b876c0 (tw-w27/phone, branch w27/phone)
  - D impact: a09f53a (tw-w27/impact, branch w27/impact)
- File leases are disjoint — no merge conflicts expected.
- Worktree for integration: /home/jess/projects/tw-w27/integrate (branch w27/integrate)

## Steps

### 1. Create integrate worktree
```
cd /home/jess/projects/temple-watch
git worktree add ../tw-w27/integrate -b w27/integrate d676da7
cd /home/jess/projects/tw-w27/integrate
git log --oneline -1
```
Confirm HEAD = d676da7.

### 2. Merge all 4 lanes in order (A → B → C → D)
```
git merge --no-ff fb0cda7 -m "Merge W27 lane A: opening squad cover and recoverable gate defense"
git merge --no-ff dfe4760 -m "Merge W27 lane B: tactical route risk preview"
git merge --no-ff 5b876c0 -m "Merge W27 lane C: phone combat decisions readability and tap targets"
git merge --no-ff a09f53a -m "Merge W27 lane D: combat impacts and movement at phone scale"
git log --oneline -5
```
If any merge conflict: STOP and report the conflicting files. Do NOT resolve automatically.

### 3. Register new tests in test.sh
Read godot/test.sh. Find where the existing wave tests are registered (look for opening27_test, tactics27_test, phone27_test, impact27_test — if already registered by lanes, skip). Add any missing ones:
- opening27_test.gd
- tactics27_test.gd
- phone27_test.gd
- impact27_test.gd

Commit the test.sh update if changed:
```
git add godot/test.sh
git commit -m "Register W27 tests in test.sh" --allow-empty
```

### 4. Headless import
```
mkdir -p /home/jess/projects/tw-logs/w27/integrate
/home/jess/projects/.tools/godot/godot --headless --path godot --import 2>&1 | tee /home/jess/projects/tw-logs/w27/integrate/import.log
grep -c "ERROR" /home/jess/projects/tw-logs/w27/integrate/import.log || true
```
Target: 0 ERRORs (GL texture leak warnings at shutdown are benign).

### 5. Full gate
```
bash godot/test.sh > /home/jess/projects/tw-logs/w27/integrate/gate.log 2>&1
gate_exit=$?
grep -E "[0-9]+ failures" /home/jess/projects/tw-logs/w27/integrate/gate.log | grep -v "0 failures" | head -20
grep "SCRIPT ERROR" /home/jess/projects/tw-logs/w27/integrate/gate.log | head -10
grep "rescue bot normal:" /home/jess/projects/tw-logs/w27/integrate/gate.log
echo "GATE_EXIT=$gate_exit"
```
Target: 0 failures, 0 SCRIPT ERRORs, Normal rescue bot 9–11/20.

### 6. Draw call check (portrait Low)
```
grep -E "draw_calls_max|draw_calls_end" /home/jess/projects/tw-logs/w27/integrate/gate.log | tail -5
```
Note the portrait peak draw count. Audit target was ≤150 (phone lane attempted this). Report actual number regardless.

### 7. If gate green: fast-forward main + push + tag
```
cd /home/jess/projects/temple-watch
git fetch . w27/integrate:main
git tag -f last-good main
git push origin main
git push origin refs/tags/last-good --force
git ls-remote origin main refs/tags/last-good
```
Confirm remote main = last-good = the integrate commit.

### 8. Export web build
```
cd /home/jess/projects/tw-w27/integrate
bash tools/web/export_web.sh > /home/jess/projects/tw-logs/w27/integrate/export.log 2>&1
export_exit=$?
if [ -f build/web/index.pck ]; then
    echo "EXPORT_OK: $(stat -c%s build/web/index.pck) bytes (exit $export_exit)"
else
    echo "EXPORT_FAILED: index.pck not found (exit $export_exit)"
    tail -20 /home/jess/projects/tw-logs/w27/integrate/export.log
    exit 1
fi
```
(Non-zero exit OK if index.pck exists — SIGABRT is benign.)

### 9. Push play site
```
rsync -a --delete --exclude='.git' build/web/ /home/jess/projects/temple-watch-play/
cd /home/jess/projects/temple-watch-play
git -c user.email="jmolasky@ovationco.com" -c user.name="Jess Molasky" add -A
git -c user.email="jmolasky@ovationco.com" -c user.name="Jess Molasky" commit -m "W27: Opening cover, tactical preview, phone HUD, combat impact

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push origin main
git log --oneline -1
echo "PLAY_SITE_PUSHED"
```

### 10. Wait and screenshot
```
until curl -sf https://mjessm1117.github.io/temple-watch-play/ | grep -q "index.pck" 2>/dev/null; do sleep 10; done
mkdir -p /home/jess/projects/tw-logs/w27/report
node /home/jess/hive/tools/screenshot.cjs \
  https://mjessm1117.github.io/temple-watch-play/ \
  /home/jess/projects/tw-logs/w27/report/live-title.png
echo "SCREENSHOT_OK"
```

### 11. Write wave report
Write /home/jess/projects/tw-logs/w27/report/WAVE-REPORT.md:
- Integrate commit SHA
- Pack size
- Play link: https://mjessm1117.github.io/temple-watch-play/
- 3 player-visible bullets (use EXACTLY these):
  1. Opening battle: your squad starts behind cover with a clear line to the gate — no longer standing in the open getting shot
  2. Before you move, a danger card shows which tile puts you in someone's crosshairs and what they'll do
  3. Hits, misses, deaths, and movement all read bigger and snappier on phone — each weapon type looks different now
- Known W27 gaps:
  1. AI still doesn't throw grenades — no enemy explosive telegraphing
  2. Portrait aim card improved but phone draw count still above 150 target (report actual number)
  3. Miss and kill animations improved but no physics ragdoll — procedural tilts only

## Boundaries
- Merge conflicts: STOP and report. Do NOT auto-resolve.
- If gate fails with new failures (not known pre-existing): report exactly which test and what message. Write a fix spec only if the fix is 1 file; otherwise STOP and report.
- If export fails (missing index.pck): STOP and report.
- If play site push fails: report exact git error.
- Do NOT modify game code during integrate. Merge + test.sh registration only.
- Keep git identity flags on all play site commits: `-c user.email=... -c user.name=...`

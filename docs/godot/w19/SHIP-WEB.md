# W19 Ship — push to main + publish phone site

## Goal
Merge w19/integrate into main, push origin, tag last-good, run web export, verify live. Commit locally only until ready. No subagents.

## Setup
The integrate worktree is at /home/jess/projects/tw-w19/integrate, branch w19/integrate, HEAD af28fe95960eb8b36598622d43b76485c8816d47. The main repo is at /home/jess/projects/temple-watch.

## Steps

### 1. Merge integrate into main (in the main repo)
```bash
cd /home/jess/projects/temple-watch
git fetch origin
git checkout main
git merge --ff-only w19/integrate
# If ff-only fails (should not), do: git merge --no-ff w19/integrate -m "Wave 19: rank-up screen, low aim camera, rank story, Training Room, soldier art pass 5"
git log --oneline -4
```

### 2. Quick sanity check (no full gate — already gated at af28fe9)
```bash
git diff 89b5341..HEAD --check
rg -c 'SCRIPT ERROR' /home/jess/projects/tw-logs/w19/integrate/gate.log || echo "0 script errors confirmed"
```

### 3. Push to origin
```bash
git push origin main
git rev-parse origin/main  # confirm it matches local HEAD
```

### 4. Tag last-good
```bash
git tag -f last-good
git push origin last-good --force
```

### 5. Web export and publish
```bash
cd /home/jess/projects/temple-watch
bash tools/web/export_web.sh
```
This exports the web build and pushes it to the tw-play-site repo (GitHub Pages). Check its exit code; if non-zero, report the error.

### 6. Verify live
```bash
sleep 90   # allow GitHub Pages to propagate
curl -s -o /dev/null -w "%{http_code} %{size_download}" https://mjessm1117.github.io/temple-watch-play/index.pck
# Should be: 200 and size > 36000000
node /home/jess/hive/tools/screenshot.cjs https://mjessm1117.github.io/temple-watch-play/ /home/jess/projects/tw-logs/w19/ship/live-phone.png --viewport 844x390
```

### 7. Update OUTPUT-LOG (in this repo, not agent files)
Write one line to /home/jess/projects/tw-logs/w19/ship/SHIP-SUMMARY.txt:
```
WAVE=19 SHA=<main HEAD> SITE=<site commit> PCK_BYTES=<curl size> HTTP=200 PAGE_ERROR_COUNT=0
```

## Expected output
Final message:
- EXPORT_EXIT (0 = good)
- main HEAD SHA
- Site commit SHA
- Live pck HTTP status and byte count
- Page error count
- Path to live screenshot: tw-logs/w19/ship/live-phone.png
- Path to ship summary: tw-logs/w19/ship/SHIP-SUMMARY.txt

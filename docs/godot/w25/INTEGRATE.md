# W25 Integrate Spec

## Goal
Merge all 5 W25 lanes into a single `w25/integrate` branch, wire the cross-lane contracts,
run the full gate, capture screenshots, and produce RESULT.md. Do NOT push to main.

## Context

Base SHA: `4f2e4c7ba126ddb89909e4724a7c5adabc94d8db` (W24 main)

Lane commits (all verified clean — gate passed on each):
- `w25/temple`  → `76d5a9bcf86953be16c85475f984c61f3a876717`  at /home/jess/projects/tw-w25/temple
- `w25/economy` → `de521ed`  at /home/jess/projects/tw-w25/economy
- `w25/galaxy`  → `13380e4`  at /home/jess/projects/tw-w25/galaxy
- `w25/roster`  → `00d1e3f`  at /home/jess/projects/tw-w25/roster
- `w25/menus`   → `2b5346c`  at /home/jess/projects/tw-w25/menus

Main repo: /home/jess/projects/temple-watch

## Steps

### 1. Create a fresh integrate worktree
```
cd /home/jess/projects/temple-watch
git worktree add /home/jess/projects/tw-w25/integrate -b w25/integrate 4f2e4c7b
```

### 2. Merge all 5 lanes (order: temple → economy → galaxy → roster → menus)
In /home/jess/projects/tw-w25/integrate:
```
git merge --no-ff 76d5a9bcf86953be16c85475f984c61f3a876717 -m "Merge W25 lane A: temple"
git merge --no-ff de521ed -m "Merge W25 lane B: economy"
git merge --no-ff 13380e4 -m "Merge W25 lane C: galaxy"
git merge --no-ff 00d1e3f -m "Merge W25 lane D: roster"
git merge --no-ff 2b5346c -m "Merge W25 lane E: menus"
```
If any merge fails with conflicts, resolve conservatively (keep both features) and
record each conflict file in RESULT.md.

### 3. Run headless import
```
/home/jess/projects/.tools/godot/godot --headless --import 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/import.log
```
Check: 0 SCRIPT ERROR, 0 Parse Error. If any appear, STOP and report them.

### 4. Wire cross-lane contracts
These are the guarded wiring points. Each uses `has_method()` so it fails safe if the
other lane isn't present. Apply as a single commit after all merges and import are clean.

**A. Temple calls open_room_story25() on room entry**
In `godot/scripts/campaign/temple.gd`, the `_open_room(id, target)` method already has
a guarded call added by the temple lane. Verify it is present:
```gdscript
if not room_story_attempted.has(id):
    room_story_attempted[id] = true
    var flow := get_node("/root/CampaignFlow")
    if flow.has_method("open_room_story25"):
        flow.call("open_room_story25", ...)
```
If missing, add it. This should already be there from the temple lane.

**B. Temple Medical calls Squad.open_from_temple()**
In `temple.gd`, `_open_medical25()` already guards:
```gdscript
static func open_from_temple(tree, room, id): ...
```
Check that `strat_roster.gd` has `open_from_temple` method from the roster lane.
If not, add a stub that calls `Squad.open_from_temple`.

**C. Temple consumes economy priority snapshot**
In `temple.gd` or `w25_temple_stage.gd`, find where `priority_room` is set. Ensure it
calls `campaign.has_method("strategic_snapshot25")` guard before using
`campaign.strategic_snapshot25().priority_room`. Should already be in temple lane code.

**D. Galaxy calls launch_ready25() on marker selection**
In `godot/scripts/campaign/galaxy.gd` (or galaxy-related script), find the spot where
a mission marker is selected/confirmed. Add guarded call:
```gdscript
if has_method("launch_ready25"):
    call("launch_ready25")
```
Or if the menus lane put `launch_ready25` on `CampaignFlow`, call it there.

**E. Galaxy exposes / routes to open_intel_view25()**
In the Galaxy screen or CampaignFlow, ensure `open_intel_view25()` method exists
(added by galaxy lane in `w25_galaxy_strategy.gd`). The comms room route in `temple.gd`
already has a guard calling it.

**F. Galaxy calls economy tick when scan committed**
In the galaxy scan commit path (w25_galaxy_strategy.gd `settle_months` or scan confirm),
add guarded call:
```gdscript
if campaign.has_method("advance_strategy_day25"):
    campaign.call("advance_strategy_day25", scan_days, "scan:" + site_id)
```

**G. Economy calls contact-income hook at month rollover**
In `w25_economy_contracts.gd` `monthly_credits25()` or the month-tick function,
ensure contact income is settled. This should already be in the economy lane's
`settle_months()` call. Verify it runs when Galaxy is not open.

**H. Economy personnel UI calls Roster.patient_actions25()**
In `strat_ui.gd` or the personnel panel, add guarded call:
```gdscript
var people_script := preload("res://scripts/w25_roster_people.gd")
if people_script.has_method("patient_actions"):
    var actions = people_script.patient_actions(c, soldier_id)
```
The economy lane calls this `patient_actions25` — check if the roster lane named it
`patient_actions` (the roster lane code uses `patient_actions`, not `patient_actions25`).
Use whatever name the roster lane defined.

**I. Menus routes Comms to open_intel_view25()**
In `w25_menus_room_story.gd` or `w25_menus_readiness.gd`, ensure the Comms room
destination is `open_intel_view25()`. The menus lane already has this via the
`W25UI.defer_story_route` guard. Verify after merge.

**J. Menus supplies launch_ready25()**
The menus lane's readiness system exposes `launch_ready25()`. Ensure it is callable
from Galaxy (see D). If Galaxy calls it on CampaignFlow, make sure CampaignFlow
delegates to the readiness system.

After wiring, commit:
```
git add -A
git commit -m "W25 integrate: cross-lane wiring (10 guarded contracts)"
```

### 5. Run full gate
```
mkdir -p /home/jess/projects/tw-logs/w25/integrate
cd /home/jess/projects/tw-w25/integrate/godot
bash test.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/test.log
```
Check: exit 0, 0 failures, 0 SCRIPT ERROR, Normal rescue ≥9/20.
If any failure: diagnose, fix, re-run. If >2 test failures, write a fix spec and report.

### 6. Measure draws
Run the standard draw-capture script:
```
/home/jess/projects/.tools/godot/godot --headless \
  -s tests/battle_capture.gd --resolution 390x844 \
  2>/home/jess/projects/tw-logs/w25/integrate/draws-portrait.log
/home/jess/projects/.tools/godot/godot --headless \
  -s tests/battle_capture.gd --resolution 1280x720 \
  2>/home/jess/projects/tw-logs/w25/integrate/draws-landscape.log
```
Record peak portrait Low draws. W24 shipped at 178 — flag if above 190.

### 7. Screenshots
```
mkdir -p /home/jess/projects/tw-logs/w25/integrate
# Temple home
/home/jess/projects/.tools/godot/godot --headless \
  -s tests/temple_capture.gd --resolution 390x844 \
  2>/dev/null
# Battle
/home/jess/projects/.tools/godot/godot --headless \
  -s tests/battle_capture.gd --resolution 390x844 \
  2>/dev/null
```
If capture scripts don't exist, take 2 screenshots of the live build using
`node /home/jess/hive/tools/screenshot.cjs` on the GitHub Pages URL (but note it
won't be updated yet — these are pre-ship captures for the report).

Combine into a 2×2 or 1×4 contact sheet JPG at:
`/home/jess/projects/tw-logs/w25/integrate/2026-11-11-w25-integrate-sheet.jpg`

Use ffmpeg to combine (max width 1500px):
```
ffmpeg -y \
  -i /path/to/before1.png -i /path/to/after1.png \
  -i /path/to/before2.png -i /path/to/after2.png \
  -filter_complex "..." \
  /home/jess/projects/tw-logs/w25/integrate/2026-11-11-w25-integrate-sheet.jpg
```

### 8. XCOM 2 side-by-side comparison
Reference shots are in /home/jess/projects/tw-reference/ (NEVER commit these — repo is public).

W25 adds Temple depth and menus. Find the most relevant XCOM 2 reference showing:
- XCOM 2 Avenger base screen (rooms, staff, resources)
- XCOM 2 squad roster screen

Make a side-by-side:
- Our Temple home vs XCOM 2 Avenger
- Our squad screen vs XCOM 2 roster

Save to /home/jess/projects/tw-reference/w25-side-by-side.jpg (outside the repo).
List the main gaps vs XCOM 2 for the wave report.

### 9. Write RESULT.md
Write /home/jess/projects/tw-logs/w25/integrate/RESULT.md:
- Integrate commit SHA on w25/integrate
- Gate: import result, test.sh result (N suites, N failures, N SCRIPT ERROR), Normal rescue
- Portrait Low peak draw count
- Pack size (get from: `wc -c godot/export/index.pck` if exists, else skip)
- Wiring contracts applied (list all 10)
- Known gaps vs XCOM 2
- Screenshot paths
- Status: INTEGRATE CLEAN (or BLOCKED with reason)

## Output
- Branch: w25/integrate committed in /home/jess/projects/tw-w25/integrate
- Logs: /home/jess/projects/tw-logs/w25/integrate/
- RESULT.md at that path

## Boundaries
- Do NOT push to main or origin/main.
- Do NOT merge w25/integrate into main — that happens in the ship task.
- Do NOT run Meshy or add new art.
- Do NOT modify CLAUDE.md, IDENTITY.md, AGENTS.md, SOUL.md, CODING-STANDARDS.md.
- Do NOT modify any file outside godot/scripts/, godot/data/, godot/tests/, godot/test.sh,
  or docs/godot/w25/.
- If the gate fails after 2 fix attempts, STOP and write a report with the failing test
  output. Do not keep trying.
- If the XCOM 2 reference images don't exist in tw-reference/, skip the side-by-side
  and note it in RESULT.md.
- Never commit XCOM 2 reference images — the repo is public.

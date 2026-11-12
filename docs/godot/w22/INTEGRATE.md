# Task: tw-w22-integrate
# Merge all 6 W22 lanes, apply cross-lane wiring, fix 3 portrait issues, gate, XCOM compare, ship Wave 22.

## Goal
Merge the six W22 lane branches into main, resolve conflicts, apply the five cross-lane wiring
edits that each lane intentionally left out-of-lease, pass the full gate, take XCOM comparison
screenshots, and ship W22 to GitHub Pages.

## Context
- Main repo: /home/jess/projects/temple-watch
- Godot binary: /home/jess/projects/.tools/godot/godot (4.7.2)
- Base: main 81c76442 (W21 shipped, 91 suites)
- 6 lane branches (all off 81c76442):
  - w22/threat      → ba2b26d  (mission_pressure, reinforcement_marker, enemy11_plate, villain11_battle, threat22_test, test.sh)
  - w22/impact      → e5a0a83  (audio, fx, unit_view, impact22_test, test.sh)
  - w22/storycontent→ 8caa335  (9 JSON + story14_beats, story_choices, story_engine, villain11_arc, storycontent22_test, story20_test, test.sh)
  - w22/feelcam     → 3570b14  (game, cam_combat, combat_turns, enemy_presentation, cine15_shot, battle16_killcam, 3×feelcam22_*, feelcam22_test, test.sh)
  - w22/decision    → 8436585  (combat_targeting, decision22_threat, hud_controls, hud_night1, hud_phone, hud_phone_action_art, input_controls, map_art_grid, test.sh, decision22_test, hud_night1_test)
  - w22/storydelivery→ 1bc084e (campaign_bridge, journal_night1, opening, story_screen, story14_comms, story14_portraits, 3×storydelivery22_*, storydelivery22_test, story14_test, test.sh)
- XCOM 2 reference shots: /home/jess/projects/tw-reference/ (private — NEVER commit)
- Logs: /home/jess/projects/tw-logs/w22/integrate/ (mkdir -p)

## Conflict-prone files — read both sides before resolving
1. **godot/test.sh** — all 6 lanes added 1 registration line each. After all merges, all 6 must be
   present: feelcam22_test, impact22_test, decision22_test, threat22_test, storycontent22_test,
   storydelivery22_test. Never silently drop a line.
2. **godot/scripts/hud_phone.gd** — modified by BOTH w22/decision (C) and w22/storydelivery (F).
   C thinned the action tray and updated grid/aim colours; F added radio card + portrait opening.
   Keep all changes from both. This is the highest-risk conflict.
3. **godot/scripts/story/villain11_arc.gd** — modified by BOTH w22/storycontent (E, authored
   dialogue) and w22/threat (D, state machine). Keep all changes from both.

## Steps

### Step 0 — Create integrate branch and merge all 6 lanes
```bash
cd /home/jess/projects/temple-watch
git checkout 81c76442 -b w22/integrate
git merge --no-ff w22/threat       -m "W22 integrate: merge threat lane (ba2b26d)"
git merge --no-ff w22/impact       -m "W22 integrate: merge impact lane (e5a0a83)"
git merge --no-ff w22/storycontent -m "W22 integrate: merge storycontent lane (8caa335)"
git merge --no-ff w22/feelcam      -m "W22 integrate: merge feelcam lane (3570b14)"
git merge --no-ff w22/decision     -m "W22 integrate: merge decision lane (8436585)"
git merge --no-ff w22/storydelivery -m "W22 integrate: merge storydelivery lane (1bc084e)"
```
For every conflict: read both sides carefully. Keep all functional changes from both.
Never silently drop a change from either side.

After all 6 merges, verify test.sh has all 6 new suite registrations:
```bash
grep -E 'feelcam22|impact22|decision22|threat22|storycontent22|storydelivery22' godot/test.sh
```
Must show exactly 6 lines. If any are missing, add them to the suites section.

### Step 1 — Apply cross-lane wiring edits (5 edits)
These edits wire the connections each lane guarded but couldn't complete inside its own lease.
Read each file before editing. Make the minimum edit needed.

#### 1a. combat_scene.gd::arrange_labels — guard portrait Rect2
In `godot/scripts/combat_scene.gd`, inside `arrange_labels()`:
- Find the line that constructs a Rect2 for the label placement zone (something like
  `Rect2(Vector2(220, 64), viewport - Vector2(485, 302))` or similar).
- Wrap the construction so that if `viewport.x <= 485` or `viewport.y <= 302`, the labels
  are simply hidden instead of constructing a negative-dimension Rect2.
- Both lane C and lane F flagged this; it produces errors at 390×844 portrait.
- Minimum edit: add a guard before the Rect2 construction.

#### 1b. battle12_aim.gd::setup() — reflow portrait aim strip
In `godot/scripts/battle12_aim.gd`, inside `setup()` (or the layout function that positions
the Confirm and Cancel buttons):
- At 390×844 (portrait, viewport.x < viewport.y), reduce the horizontal margin so that both
  Confirm and Cancel buttons remain fully visible with at least 8 px inset from each edge.
- Lane A flagged this: at 390 px wide, the aim strip clips the action buttons off-screen.
- Minimum edit: detect portrait orientation and adjust the horizontal anchor/margin for the
  two action buttons only.

#### 1c. campaign_bridge.gd::debrief — pass units to start_debrief
In `godot/scripts/campaign_bridge.gd`, inside `debrief()` or the method that calls
`start_debrief(...)`:
- Add `"units": result.units` (or the equivalent unit-list field on the result object) to
  the dict or arguments passed to `start_debrief`.
- Lane E added `story14_beats.pick_bark` which uses unit data to select actor-specific
  barks; this feeds the debrief screen with real unit names.
- If `result.units` doesn't exist, check what field holds the mission unit list and use that.
- Minimum edit: one additional key in the existing call.

#### 1d. story14_comms.gd — wire pick_bark into show_radio
In `godot/scripts/story14_comms.gd`, inside the event handler that shows battle barks
(look for a call to `show_radio` or the radio card display function):
- Before calling `show_radio`, call `story14_beats.pick_bark(actor, target, bondmate, villain)`
  with the available context from the current event.
  - `actor`: the unit firing or reacting (may be their id string)
  - `target`: the unit being targeted or killed (may be their id string or null)
  - `bondmate`: a unit with a bond to actor (may be null)
  - `villain`: the active villain id if present (may be null)
- Use the return value of `pick_bark` as the text passed to `show_radio`.
- If any of actor/target/bondmate/villain is not available in context, pass null/empty.
- Lane E implemented `pick_bark`; lane F implemented `show_radio`; this wires them together.
- Minimum edit: add the pick_bark call before show_radio in the existing handler.

#### 1e. hud_phone.gd::_update_actions — allow 2 primary actions in portrait tray
In `godot/scripts/hud_phone.gd`, inside `_update_actions()` (or the method that decides
which actions appear in the bottom tray):
- When the tray height is less than 192 px (portrait layout), allow 2 primary actions instead
  of 1. Put any additional actions under a "More" button or collapsed row.
- Lane F flagged this: in portrait the action bar clips to 1 button and the second action
  is unreachable.
- If C's merge already changed this method, add this portrait check on top.
- Minimum edit: change the primary-action cap from 1 to 2 when `tray_height < 192`.

After all 5 edits: commit with message
"W22 integrate: combat_scene portrait guard, aim strip, bark wiring, portrait tray"

### Step 2 — Verify villain11_arc.gd has both sides merged correctly
Run:
```bash
grep -c 'intro\|retreat\|arrival\|presence' godot/scripts/story/villain11_arc.gd
```
Should return > 0 hits. If villain11_arc.gd lost either E's authored dialogue fields
(intro, retreat lines) or D's state machine (arrival/presence/retreat states), re-merge
that file from the worktrees and re-apply both sides.

### Step 3 — Verify legacy tests pass on the highest-risk files
```bash
mkdir -p /home/jess/projects/tw-logs/w22/integrate

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/hud_night1_test.gd -- 2>&1 | tail -10 \
  > /home/jess/projects/tw-logs/w22/integrate/hud_night1-diag.log
grep -E 'SCRIPT ERROR|failures|HUD_NIGHT1' /home/jess/projects/tw-logs/w22/integrate/hud_night1-diag.log

/home/jess/projects/.tools/godot/godot --headless --path godot/ \
  --script tests/story20_test.gd -- 2>&1 | tail -10 \
  > /home/jess/projects/tw-logs/w22/integrate/story20-diag.log
grep -E 'SCRIPT ERROR|failures|STORY20\|story20' /home/jess/projects/tw-logs/w22/integrate/story20-diag.log
```
If either has failures or SCRIPT ERRORs: diagnose exact line from the log and fix only
that assertion. Do not touch game code — only update the test to match current behaviour.
Commit any test fixes: "W22 integrate: fix hud_night1/story20 assertions after lane merge"

### Step 4 — Full gate
Rsync textures (worktree won't have untracked .webp files from main repo):
```bash
rsync -av --include='*.webp' --include='*.webp.import' --include='*.glb.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/units/ \
  ./godot/assets/units/

rsync -av --include='*.webp' --include='*.webp.import' \
  --include='*/' --exclude='*' \
  /home/jess/projects/temple-watch/godot/assets/characters/ \
  ./godot/assets/characters/
```

Headless import:
```bash
/home/jess/projects/.tools/godot/godot --headless --path godot/ --import --quit-after 180 2>&1 | tail -5
```

Full gate:
```bash
./godot/test.sh > /home/jess/projects/tw-logs/w22/integrate/gate.log 2>&1
echo "GATE_EXIT=$?"
grep -E 'SCRIPT ERROR|failures|Normal' /home/jess/projects/tw-logs/w22/integrate/gate.log | tail -20
```
Must exit 0, 0 SCRIPT ERROR, 0 failures, Normal rescue 9–11/20.
If any suite fails: diagnose exact error, fix only the failing assertion, re-run, repeat.
Do NOT proceed to ship with any failure.

### Step 5 — Screenshots + XCOM comparison
Take phone-size screenshots (844×390) of:
- w22-battle.png — Battle view showing the lighter movement grid and cover shields on hover
- w22-aim.png — Aim card showing large hit%, two modifiers, FLANKED badge
- w22-story.png — A story radio card or debrief screen showing actor-specific bark
- w22-threat.png — End Turn HUD chip showing wave forecast (threat_summary)
Save to /home/jess/projects/tw-logs/w22/integrate/.

Also take a 390×844 portrait shot of the aim strip to confirm Confirm + Cancel are visible:
- w22-aim-portrait.png

Compare with XCOM 2 reference shots in /home/jess/projects/tw-reference/.
Write /home/jess/projects/tw-reference/W22-GAPS.md (3–8 visual gaps vs XCOM 2).

Combine W22 shots + XCOM reference into one side-by-side JPG:
/home/jess/projects/tw-logs/w22/integrate/w22-xcom-compare.jpg

Create a before/after report sheet (W21 vs W22, 3 key screens, one JPG):
/home/jess/projects/tw-logs/w22/integrate/w22-report-sheet.jpg
Use W21 reference captures from /home/jess/projects/tw-logs/w21/integrate/ as "before".

### Step 6 — Merge and ship
1. Confirm current branch and target:
```bash
git branch --show-current   # must be w22/integrate
git -C /home/jess/projects/temple-watch log --oneline -3  # confirm main base 81c76442
```

2. Merge w22/integrate into main:
```bash
git -C /home/jess/projects/temple-watch merge --no-ff w22/integrate \
  -m "W22: enemy turn pacing, hit/blast feedback, lighter grid, aim clarity, threat preview, story delivery"
```

3. Push origin main:
```bash
git -C /home/jess/projects/temple-watch push origin main
git -C /home/jess/projects/temple-watch ls-remote origin main
```
Local HEAD must equal remote.

4. Tag last-good:
```bash
git -C /home/jess/projects/temple-watch tag -f last-good
git -C /home/jess/projects/temple-watch push origin last-good --force
```

5. Web export:
```bash
cd /home/jess/projects/temple-watch && tools/web/export_web.sh 2>&1 | tail -20
```

6. Push to tw-play-site (DO NOT SKIP):
```bash
rsync -av /home/jess/projects/temple-watch/build/web/ /home/jess/projects/temple-watch-play/
cd /home/jess/projects/temple-watch-play
git add -A
git commit -m "W22 ship"
git push
```

7. Verify live:
```bash
curl -sI https://mjessm1117.github.io/temple-watch-play/index.pck | head -4
```
Confirm HTTP 200. File size must differ from W21 (was 45,258,604 bytes).

### Step 7 — Write deliverables
Save to /home/jess/projects/tw-logs/w22/integrate/RESULT.md:
```
PASS
Suites: N, Failures: 0, SCRIPT ERRORs: 0
Normal rescue: N/20
Live pck: 200, SIZE bytes
Gate log: /home/jess/projects/tw-logs/w22/integrate/gate.log
Report sheet: /home/jess/projects/tw-logs/w22/integrate/w22-report-sheet.jpg
XCOM compare: /home/jess/projects/tw-logs/w22/integrate/w22-xcom-compare.jpg
W22 GAPS: /home/jess/projects/tw-reference/W22-GAPS.md
Main: <SHA> (remote matches)
Play site: <SHA> (remote matches)
```

## Boundaries
- May edit: godot/scripts/combat_scene.gd (arrange_labels portrait guard only)
- May edit: godot/scripts/battle12_aim.gd (setup() portrait strip reflow only)
- May edit: godot/scripts/campaign_bridge.gd (debrief units pass-through only — do not rearchitect)
- May edit: godot/scripts/story14_comms.gd (pick_bark wiring only)
- May edit: godot/scripts/hud_phone.gd (portrait tray cap only, as part of merge conflict)
- May edit: godot/test.sh (only to ensure all 6 new suites are registered)
- May edit: godot/tests/hud_night1_test.gd and godot/tests/story20_test.gd
  (only to fix assertions broken by lane merges — read the exact error first)
- Do NOT modify lane-committed game logic (audio.gd, fx.gd, hud_controls.gd, etc.)
  unless a SCRIPT ERROR forces it — then fix only the broken line.
- Never commit /home/jess/projects/tw-reference/ content to the game repo.
- Always confirm target branch is main before pushing to origin.
- Write logs to /home/jess/projects/tw-logs/w22/integrate/, never /tmp.

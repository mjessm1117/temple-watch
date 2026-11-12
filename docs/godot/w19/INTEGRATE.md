# W19 Integrate + Gate + XCOM sheet

## Goal
Merge all 4 W19 branches into w19/integrate, run the full gate, produce the XCOM side-by-side, then output a summary. Commit locally only. No push, merge to main, or tag.

## Branches to merge (in order)
All worktrees are under /home/jess/projects/tw-w19/:

1. `w19/rankup`  HEAD 0e93646  — promotion_screen.gd, rankup_badge.gd, story14_portraits.gd, rankup19_test.gd
2. `w19/battle`  HEAD 220ec22  — cam_combat.gd, battle12_aim.gd, hud_phone.gd, hud_phone_action_art.gd, cine15_capture.gd, battle19_test.gd
3. `w19/temple`  HEAD 0de9ec6  — training_room19.gd, rank19_beats.gd, mentor17.gd, progression.gd, state.gd, strat_ops.gd, strat_roster.gd, temple.gd, temple_rooms.gd, integration.gd, campaign_bridge.gd, journal_night1.gd, temple19_test.gd
4. `w19/art`     HEAD 41f5ad2  — soldier art GLBs (godot/assets/units/w19/)

## Setup steps
```
# 1. Create the integrate worktree off main 89b5341
cd /home/jess/projects/temple-watch
git worktree add ../tw-w19/integrate w19/integrate 2>/dev/null || git worktree add ../tw-w19/integrate -b w19/integrate 89b5341
cd /home/jess/projects/tw-w19/integrate

# 2. Headless import (required for every new worktree)
godot --headless --import 2>&1 | tail -5

# 3. Merge each branch
git merge --no-ff w19/rankup  -m "Merge w19/rankup: XCOM rank-up screen (0e93646)"
git merge --no-ff w19/battle  -m "Merge w19/battle: low aim camera + HUD nits (220ec22)"
git merge --no-ff w19/temple  -m "Merge w19/temple: rank story + training room (0de9ec6)"
git merge --no-ff w19/art     -m "Merge w19/art: soldier art pass 5 (41f5ad2)"
```

## Expected conflicts and resolutions
- **test.sh**: Each of rankup, battle, and temple added exactly 1 line to register its test suite (rankup19, battle19, temple19). The art branch does not touch test.sh. Keep ALL added lines — the final test.sh should run all three new suites. Example conflict block:
  ```
  <<<<<<< HEAD
      "rankup19_test" "rankup19"
  =======
      "battle19_test" "battle19"
  >>>>>>> w19/battle
  ```
  Resolution: include both lines. If a 3-way conflict from temple also appears, include all three. Never drop an existing suite line.
- **No other expected conflicts**: the file leases for each lane were disjoint. If any other conflict appears, resolve conservatively (keep both sides where additive; check that no test suite is dropped).

## Gate
After all merges succeed:
```
bash godot/test.sh > /home/jess/projects/tw-logs/w19/integrate/gate.log 2>&1
rg -c 'SCRIPT ERROR' /home/jess/projects/tw-logs/w19/integrate/gate.log || true
rg 'Normal rescue bot' /home/jess/projects/tw-logs/w19/integrate/gate.log | tail -1
```
Gate passes when: exit 0, 0 SCRIPT ERROR, 0 nonzero failure summaries. Normal rescue 9-11/20 is expected.

## XCOM side-by-side
Produce a 2-column JPG comparing W19 screens to matching XCOM 2 reference shots. Use XCOM reference shots from /home/jess/projects/tw-reference/ (outside the repo; never commit them). Produce 4 comparison pairs:
1. Rank-up screen vs XCOM rank-up (tw-reference/w19-rankup-side-by-side.jpg already produced by rankup lane; copy or re-use)
2. Aim close-up vs XCOM aim (tw-reference/w19-aim-side-by-side.jpg already produced by battle lane)
3. Training Room vs XCOM Avenger (tw-reference/w19-training-side-by-side.jpg already produced by temple lane)
4. Phone HUD 844×390 tactical view vs XCOM phone HUD

If a reference shot for pair 4 doesn't exist in tw-reference/, take a tactical shot of the game at 844×390 and place it next to the best available HUD reference. Save the combined sheet to /home/jess/projects/tw-reference/w19-side-by-side.jpg.

## W19 Gaps
Write /home/jess/projects/tw-reference/W19-GAPS.md listing the visible gaps vs XCOM 2 (3-7 items max, player-visible language, no code references).

## Output
Logs go to /home/jess/projects/tw-logs/w19/integrate/.
Final message:
- Integrate SHA (HEAD after all merges)
- Gate: suites count, failures, SCRIPT ERROR count, Normal x/20
- Sheet paths: tw-reference/w19-side-by-side.jpg + W19-GAPS.md
- Any resolved conflicts listed
- Commit locally only. NO push, merge to main, or tag.

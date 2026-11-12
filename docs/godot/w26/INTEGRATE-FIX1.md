# W26 Integrate Fix 1 — decision22_test 4 failures

## Context
- Working directory: /home/jess/projects/temple-watch-w26-integrate (w26/integrate branch, all 4 lanes merged)
- Gate failed: 4 failures in decision22_test, 0 SCRIPT ERRORs, 0 other failures
- main/last-good/play site are still W25 (ce62160). Do NOT touch them until gate is green.

## Failures (from gate.log line ~550-573)
```
ERROR: End Turn chip fits two lines while counting D's numeric threats
  decision22_test.gd:227
ERROR: portrait chip prioritizes objective and exposed threats
  decision22_test.gd:228
ERROR: merged threat API populates phone chip
  decision22_test.gd:231
ERROR: UnitCard respects 12px side margin at (844, 390): [P: (2.5, 260.8333), S: (124.0, 63.0)]
  decision22_test.gd:62 (layout_check)
```

## Root cause hypothesis
The W26 HUD lane changed hud_phone.gd:
1. Added `heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL` → may push UnitCard position to x < 12px
2. Changed portrait from 44→52px → may affect layout of the chip strip
3. Added `alerts.card.modulate.a = 0.0` on CONTACT radio → may hide the chip the test expects to see

The decision22_test assertions at lines 227-228-231 check threat chip content/priority. The layout_check at line 62 checks UnitCard ≥12px side margin.

## Fix approach

### Step 1: Read the failing test assertions
Read decision22_test.gd lines 55-70 (layout_check) and 220-235 (the failing run block). Understand exactly what each check expects.

### Step 2: Read the W26 HUD diff
Read godot/scripts/hud_phone.gd. Focus on:
- What `heading.size_flags_horizontal = SIZE_EXPAND_FILL` does to child layout
- What the portrait 52px change does to sibling widths
- What `alerts.card.modulate.a = 0.0` does to chip visibility

### Step 3: Diagnose
For each failure, determine:
- Is this a **test assertion that needs updating** (new behavior is correct, test was written for old layout)?
- Or is this a **real regression** (W26 HUD change broke something that should still work)?

The UnitCard margin failure (x=2.5 instead of ≥12) suggests real regression — the card is too close to the edge.

### Step 4: Fix
**Priority: fix the real regression first.** If the heading SIZE_EXPAND_FILL is pushing the UnitCard too far left, consider whether a minimum left padding or an anchor fix resolves it without reverting the other HUD improvement.

For test assertion updates (lines 227-228-231): only update if the new behavior is intentionally correct per the W26 spec (fewer enemies / simpler threat display is expected for the first mission). Do NOT update assertions just to pass — they must reflect correct behavior.

### Step 5: Run focused test
```
cd /home/jess/projects/temple-watch-w26-integrate
/home/jess/projects/.tools/godot/godot --headless --path godot --import > /dev/null 2>&1
xvfb-run -a /home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility --resolution 844x390 -s tests/decision22_test.gd -- --graphics=low 2>&1 | tee /home/jess/projects/tw-logs/w26/fix1/decision22.log
```
Target: `DECISION22 TEST RESULTS: 61 checks, 0 failures`

### Step 6: Full gate
```
bash godot/test.sh > /home/jess/projects/tw-logs/w26/fix1/gate.log 2>&1
```
Parse: total failures = 0, SCRIPT ERRORs = 0.

### Step 7: Commit
If gate is green:
```
git add -A
git commit -m "Fix decision22 layout regression from W26 HUD changes

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
Report the fix and the gate result. Do NOT push to main — that is the integrate task's job on the next run.

## Boundaries
- Only edit files in the integrate worktree (/home/jess/projects/temple-watch-w26-integrate).
- Only change hud_phone.gd, hud_phone_layout.gd, and/or decision22_test.gd.
- No new features, no scope creep.
- If more than 3 files need changing: STOP and report what you found.
- If after one fix attempt the gate still has failures: STOP and report the remaining failures with exact error messages.

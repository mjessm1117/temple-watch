# W25 Integrate Fix

## Context
Working in: /home/jess/projects/tw-w25/integrate (branch w25/integrate, HEAD f8afef1)

The integrate blocked on galaxy25_test.gd — 14 failures + 10 SCRIPT ERROR stack overflows.
Root causes are documented in /home/jess/projects/tw-logs/w25/integrate/FIX-SPEC.md.
Read that file first.

## Goal
Fix galaxy25_test.gd per the 4 root causes in FIX-SPEC.md, then pass the full gate.
Make all changes in /home/jess/projects/tw-w25/integrate/godot/.

## Required changes (from FIX-SPEC.md)

1. **Recursive stack overflow**: `ScanCampaign.advance_strategy_day25()` in the test fixture
   calls `advance_days()`, which now calls `advance_strategy_day25()` — infinite loop.
   Fix the fixture to invoke the base `advance_days()` implementation directly.
   Preserve: call counter and event interruption behavior in the fixture.

2. **Obsolete guard assertions**: The test expects `Campaign.new()` to lack
   `advance_strategy_day25()`. After the economy merge, real Campaign has this method.
   Use a minimal no-clock fixture for the missing-method guard.
   Add an assertion that the real Campaign exposes an ENABLED Scan action.

3. **Mission confirmation route changed**: The test expects mission confirmation to open
   the old Briefing. The menus lane now routes it via `CampaignFlow.launch_ready25()` to
   the readiness scene. Update the assertion to check for the readiness screen and its
   Back return path, including the selected mission.

4. **Scan interruption + contact income**: After fixing the fixture (item 1 above), recheck
   these assertions. Contact income must settle on month rollover even if Galaxy is closed
   (`state.gd::_month_tick()` now calls `Strategy25.settle_months()`).

## Steps

1. Read /home/jess/projects/tw-logs/w25/integrate/FIX-SPEC.md for exact detail.
2. Read /home/jess/projects/tw-logs/w25/integrate/w25-targeted.log to see the exact
   failure output for each of the 14 failures.
3. Apply the minimum necessary changes to galaxy25_test.gd (and only that file, unless
   another test file also needs updating for the same root cause).
4. Run focused galaxy25 test first:
   ```
   /home/jess/projects/.tools/godot/godot --headless \
     -s tests/galaxy25_test.gd 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/galaxy25-recheck.log
   ```
   Confirm: 0 SCRIPT ERROR, 0 failures, expected check count reached.
   If still failing: fix and rerun. Max 2 more attempts, then STOP and report.

5. Run full gate:
   ```
   cd /home/jess/projects/tw-w25/integrate/godot
   bash test.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/test-final.log
   ```
   Check: exit 0, 0 failures, 0 SCRIPT ERROR, Normal rescue ≥9/20.

6. Run git diff --check to confirm no whitespace issues.

7. Commit on w25/integrate:
   ```
   git add godot/tests/galaxy25_test.gd
   git commit -m "W25 integrate: fix galaxy25 test fixture for economy merge"
   ```
   Record the final SHA.

8. Update /home/jess/projects/tw-logs/w25/integrate/RESULT.md:
   - Set Status: INTEGRATE CLEAN
   - Add final commit SHA
   - Add gate results (suite count, failures, SCRIPT ERROR count, Normal rescue)

## Boundaries
- Work only in /home/jess/projects/tw-w25/integrate/
- Change only test files (godot/tests/). Do NOT change game code (godot/scripts/, godot/data/).
- Do NOT merge or push to main.
- If the gate still fails after 2 fix attempts, STOP and write an updated FIX-SPEC.md with
  the new failure output. Do not keep trying.

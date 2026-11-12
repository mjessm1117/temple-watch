# W25 Integrate Fix 2 — Diagnose and fix final galaxy25 assertion

## Context
Working in: /home/jess/projects/tw-w25/integrate (branch w25/integrate, HEAD f8afef1)
The galaxy25_test.gd has already been edited (not yet committed).

The compound readiness assertion has been split into separate checks with print diagnostics.
Run the focused galaxy25 test to see which condition actually fails.

## Steps

### 1. Run focused galaxy25 test
```
cd /home/jess/projects/tw-w25/integrate/godot
/home/jess/projects/.tools/godot/godot --headless \
  -s tests/galaxy25_test.gd 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/galaxy25-diag.log
```
Look for the LAUNCH DEBUG print line to see actual values.
Then look for which check() calls failed (each prints "ERROR: <name>").

### 2. Fix the actual failure
Based on the LAUNCH DEBUG output, fix the assertion or the underlying code:

**If `scene != Readiness25` (scene is still the galaxy or null):**
  - `_launch()` returned early. This means the contact guard triggered.
  - Check if `chosen_region` was added to contacts. Add a print before `_launch()` to verify.
  - If the guard is the problem: in galaxy.gd `_launch()` add a check that the contacts
    list is fully initialized before the guard: call `Strategy25.ensure(campaign.state)`
    before the guard check.
  - Alternatively: have the guard check `campaign.state.get("w25_contacts",[])` to avoid
    the `ensure()` side effect.

**If `launch_index != 1`:**
  - `launch_ready25()` found the mission at a different index than 1.
  - Check: `_prepare_briefing25()` sets `campaign.state.launch_index = index`.
    Verify that `launch_ready25(mission_id)` finds the option at index 1.
  - Fix: ensure `_select(1)` is called on galaxy before `_launch()` (already done in test).

**If `launch_option.mission != chosen_id`:**
  - The option's mission field uses a different key or format.
  - Check `options[1]` structure — does it have `.mission` or `.id` or `.n`?
  - Fix the assertion to use the correct field.

**If `ReadyBack button not found`:**
  - The readiness scene didn't add the button with name "ReadyBack".
  - Check `w25_menus_readiness.gd` — the button is at line 42 as `back.name = "ReadyBack"`.
  - Might be a timing issue — the scene wasn't fully initialized yet.

### 3. After fixing, run focused galaxy25 test again
Confirm: 0 failures, 0 SCRIPT ERROR.

### 4. Run full gate
```
cd /home/jess/projects/tw-w25/integrate/godot
bash test.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/test-final2.log
```
Check: exit 0, 0 failures, 0 SCRIPT ERROR, Normal rescue ≥9/20.
Run `git diff --check` after.

### 5. Commit
```
cd /home/jess/projects/tw-w25/integrate
git add godot/tests/galaxy25_test.gd
git commit -m "W25 integrate: fix galaxy25 readiness assertion and await"
```
(Remove the LAUNCH DEBUG print lines from the test before committing — keep it clean.)
Record the final commit SHA.

### 6. Update RESULT.md
Set Status: INTEGRATE CLEAN in /home/jess/projects/tw-logs/w25/integrate/RESULT.md.

## Boundaries
- Change only test files (godot/tests/). Do NOT change game code (godot/scripts/, godot/data/).
- Do NOT merge or push to main.
- If the full gate still fails after 2 more fix attempts, STOP with the full error output.
- Remove the LAUNCH DEBUG print before the final commit.

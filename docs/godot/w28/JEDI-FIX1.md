# W28 Jedi Lane Fix 1

## Goal
One failing check in jedi_tiers28_test.gd: Sentinel Padawan Guard does not deflect a blaster bolt.
Also: "Knight rank 3 required" lock message is not visible in loadout_arsenal.gd.
Commit all Lane A staged work (core.json, battle_bridge.gd, gear.gd, armory12_test.gd, jedi_tiers28_test.gd) plus these two fixes, then run the full gate.

## Context
Worktree: /home/jess/projects/tw-w28/jedi  
Lane A base SHA: a5c1a37f  
Staged (not yet committed):
- godot/data/campaign/core.json
- godot/scripts/campaign/battle_bridge.gd
- godot/scripts/campaign/gear.gd
- godot/tests/armory12_test.gd
Untracked (not staged):
- godot/tests/jedi_tiers28_test.gd

The full suite (121 suites, 0 failures, 0 SCRIPT ERRORs) already passes.
The lane-specific test jedi_tiers28_test.gd has 42 checks, 1 failure:
  "Sentinel Padawan Guard deflects blaster bolt" — Guard ability does not reduce incoming damage.

## File Lease (extended)
- godot/data/campaign/core.json (already staged)
- godot/scripts/campaign/battle_bridge.gd (already staged)
- godot/scripts/campaign/gear.gd (already staged)
- godot/tests/armory12_test.gd (already staged)
- godot/tests/jedi_tiers28_test.gd (new, untracked)
- godot/scripts/mission.gd  ← EXTENSION: needed for Guard deflection
- godot/scripts/campaign/loadout_arsenal.gd  ← EXTENSION: needed for lock message

## Steps

1. Read godot/tests/jedi_tiers28_test.gd to understand exactly what the Guard test asserts.
   The test likely sets up a Jedi with the Guard ability, fires a blaster attack at it, and
   checks that the damage received is reduced (or zero).

2. Read godot/scripts/mission.gd — find where abilities modify incoming damage (look for
   "guard", "deflect", "ability", "damage" in the ability-resolution path).

3. Fix mission.gd: when the targeted unit has Guard active, intercept the damage and
   reduce it per the Guard ability's block value. The fix must not break any other
   existing test assertions.

4. Read godot/scripts/campaign/loadout_arsenal.gd — find where rank-lock messages are
   displayed. The message "Knight rank 3 required" must appear in the lock chip for
   abilities that require Knight rank 3.

5. Fix loadout_arsenal.gd: surface the rank requirement string so the UI shows it.
   Match the existing message format used by other rank locks.

6. Run the lane test only first to confirm 42/42 pass:
   /home/jess/projects/.tools/godot/godot --headless --path godot \
     -s tests/jedi_tiers28_test.gd \
     --rendering-method gl_compatibility --resolution 390x844
   Must show: JEDI_TIERS28 TEST RESULTS: 42 checks, 0 failures

7. Stage all files: the 4 previously staged files, jedi_tiers28_test.gd, mission.gd,
   loadout_arsenal.gd (only if modified). git diff --check must pass.

8. Run the full suite to confirm 0 failures and 0 SCRIPT ERRORs still hold:
   cd godot && bash test.sh > /home/jess/projects/tw-logs/w28/jedi/full-test-fix1.log 2>&1
   Parse: suites count, script_errors=0, failure_lines=[].

9. If gate is green: commit with message "Add Jedi tier ranks and Guard deflection"
   Confirm commit SHA with git rev-parse --short HEAD.

10. Report: commit SHA, jedi_tiers28 42/42, full suite counts, 0 fail 0 SCRIPT ERROR.

## Boundaries
- Only touch the 7 files listed in the lease.
- Do not modify test.sh.
- Do not alter any existing test assertions except armory12_test.gd (already staged).
- If the Guard fix touches battle logic shared with other abilities, make it conditional
  on Guard specifically (guard ability id or flag).
- Do not commit if the full suite has any failure or SCRIPT ERROR.

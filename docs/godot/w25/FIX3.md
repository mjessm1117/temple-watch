# W25 Integrate Fix 3 — galaxy_view_test launch flow

## Goal
Fix the one remaining gate failure in tw-w25/integrate:
`galaxy_view_test.gd` lines 96-97 fail because the W25 galaxy lane changed
`_launch()` to route through `launch_ready25()` → readiness screen instead of
going directly to `briefing.tscn`. The test checks the old (pre-W25) behavior.

## Context
- Working directory: `/home/jess/projects/tw-w25/integrate`
- Current HEAD: `f8afef1` (on branch w25/integrate)
- Godot binary: `/home/jess/projects/.tools/godot/godot`
- Gate command: `./godot/test.sh` — must exit 0, 0 fail, 0 SCRIPT ERROR, Normal 9/20
- Fix scope: `godot/tests/galaxy_view_test.gd` ONLY (and test.sh if needed).
  Do NOT touch galaxy.gd, campaign_bridge.gd, or any game logic.

## Root Cause
`galaxy.gd _launch()` now calls `launch_ready25(mission_id)` when the method
exists. That function (in campaign_bridge.gd) calls `_prepare_briefing25(index)`
(which sets `campaign.state.launch_option` and `launch_index`) and then
`_show_ready25()` which puts the readiness screen as `current_scene` — NOT
`briefing.tscn`.

The old test at lines 95-108 of `galaxy_view_test.gd`:
- Line 96: `check(current_scene.scene_file_path.ends_with("briefing.tscn"), ...)`
  → fails because current_scene is now the readiness screen
- Line 97: `check(str(flow.campaign.state.launch_option.mission) == mission_id, ...)`
  → if `launch_ready25` returned early (active guard), `launch_option` was never set;
  the dot-access on a Dictionary with no key throws SCRIPT ERROR

## Fix Instructions

1. Read `godot/tests/galaxy_view_test.gd` lines 90-115 fully.

2. Read `godot/scripts/campaign/galaxy.gd` lines 337-345 (the `_launch` function).

3. Read `godot/scripts/campaign_bridge.gd` lines 184-233
   (the `prepare_briefing`, `_prepare_briefing25`, `launch_ready25`, `_show_ready25` block).

4. Read `godot/scripts/w25_menus_readiness.gd` — find what `scene_file_path`
   returns for this scene (or what `get_script().resource_path` gives), so you
   know what to check for instead of `briefing.tscn`.

5. Determine whether after `view._launch() + await frames()` the test can
   distinguish the W25 path (readiness screen) from the old path (briefing).
   The check should pass on BOTH paths (W25 and pre-W25).

6. Update `galaxy_view_test.gd`:
   - Lines 96-98: replace the hard `briefing.tscn` check with a check that
     accepts the new W25 path. If the readiness screen appears, verify
     `launch_option` and `launch_index` using safe `.get()` access on the
     Dictionary, not bare dot-notation. If briefing appears (pre-W25 fallback),
     the existing checks can stay.
   - Lines 107-108: same pattern for the second offer test.
   - Only change what breaks. Do not rewrite the whole test.

7. Run the focused suite first:
   ```bash
   cd /home/jess/projects/tw-w25/integrate
   /home/jess/projects/.tools/godot/godot --headless --import 2>&1 | tail -5
   /home/jess/projects/.tools/godot/godot --headless \
     --path godot \
     --script tests/runner.gd \
     -- suite=galaxy_view_test 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/fix3-galaxy-view.log
   ```
   Must show 0 failures and 0 SCRIPT ERRORs.

8. Run the full gate:
   ```bash
   cd /home/jess/projects/tw-w25/integrate
   ./godot/test.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/fix3-full-gate.log
   ```
   Must exit 0, 0 failures, 0 SCRIPT ERRORs, Normal 9/20.

9. If gate passes: `git add godot/tests/galaxy_view_test.gd && git commit -m "fix(galaxy_view_test): accept W25 readiness-screen launch path"`

10. If the test update alone is insufficient (e.g., `launch_ready25` guard prevents
    `launch_option` from ever being set in a test context), then also read
    `campaign_bridge.gd` around the `active` flag to understand why, and patch
    either the guard or the test setup — MINIMUM change, no redesign.

## Output
- Fix3 gate log at `/home/jess/projects/tw-logs/w25/integrate/fix3-full-gate.log`
- Committed on branch `w25/integrate` with 0 failures gate

## Boundaries
- Touch ONLY `godot/tests/galaxy_view_test.gd` (and optionally campaign_bridge.gd
  guard fix if needed). No galaxy.gd changes, no game-logic changes.
- Do not add new test helpers or test files.
- Do not change galaxy25_test.gd (that one already passes).
- If you need more than 2 attempts at this test fix, STOP and write BLOCKED in
  `/home/jess/projects/tw-logs/w25/integrate/fix3-result.md` with the exact
  error and your diagnosis.

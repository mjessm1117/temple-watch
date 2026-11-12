# W25 Integrate Fix 4 — galaxy_view_test + integration_test

## Goal
Fix two remaining gate failures in tw-w25/integrate, both test-only:
1. `galaxy_view_test.gd` — W25 changed `_launch()` to route through a readiness
   screen. Test checks were updated in Fix3 but left uncommitted. Apply them.
2. `integration_test.gd:39` — W25 changed `open_intelligence()` to call
   `galaxy.open_intel_view25()` instead of creating `flow.intelligence`. The
   test calls `flow.intelligence._choose()` after `queue_free()`.

## Context
- Working directory: `/home/jess/projects/tw-w25/integrate`
- Current HEAD: `f8afef1` (on branch w25/integrate)
- Fix3 left galaxy_view_test.gd changes uncommitted and produced a result file
  at `/home/jess/projects/tw-logs/w25/integrate/fix3-result.md`
- Gate log at `/home/jess/projects/tw-logs/w25/integrate/fix3-full-gate.log`
- Godot binary: `/home/jess/projects/.tools/godot/godot`

## Fix 1 — galaxy_view_test.gd (from Fix3 patch, re-apply it)

Apply these exact changes to `godot/tests/galaxy_view_test.gd`:

**Before line 95** (after `await shot("briefing")`):
Add: `flow.active = true`

**Lines 96-98** (replace):
```
# OLD:
check(current_scene.scene_file_path.ends_with("briefing.tscn"),"Selected offer opens existing briefing")
check(str(flow.campaign.state.launch_option.mission) == mission_id,"Briefing receives unchanged mission ID")
check(int(flow.campaign.state.launch_index) == 0,"Briefing receives unchanged offer index")

# NEW:
check(current_scene.scene_file_path.ends_with("briefing.tscn") or (current_scene.get_script() != null and current_scene.get_script().resource_path.ends_with("w25_menus_readiness.gd")),"Selected offer opens briefing or readiness")
check(str(flow.campaign.state.get("launch_option", {}).get("mission", "")) == mission_id,"Briefing receives unchanged mission ID")
check(int(flow.campaign.state.get("launch_index", -1)) == 0,"Briefing receives unchanged offer index")
```

**Line 108** (replace):
```
# OLD:
check(str(flow.campaign.state.launch_option.mission) == "rescue" and int(flow.campaign.state.launch_index) == 1,"Second offer launches its own mission ID, not first offer")

# NEW:
check(current_scene.scene_file_path.ends_with("briefing.tscn") or (current_scene.get_script() != null and current_scene.get_script().resource_path.ends_with("w25_menus_readiness.gd")),"Second offer opens briefing or readiness")
check(str(flow.campaign.state.get("launch_option", {}).get("mission", "")) == "rescue" and int(flow.campaign.state.get("launch_index", -1)) == 1,"Second offer launches its own mission ID, not first offer")
```

## Fix 2 — integration_test.gd lines 34-41

**Problem:** After `flow.open_intelligence()`, the W25 path calls
`galaxy.open_intel_view25()` and returns without setting `flow.intelligence`.
The test calls `flow.intelligence._choose(...)` on the freed instance.

**Step 1:** Read `godot/scripts/campaign/galaxy.gd` and find `open_intel_view25()`.
Check what node/scene it creates or exposes, and how to reach the intel panel.
Specifically: does it set a property on the galaxy, add a child with a known
class, or expose the panel some other way?

**Step 2:** Read `godot/scripts/campaign_bridge.gd` lines 530-545 to verify
the W25 open_intelligence() guard path.

**Step 3:** Update `integration_test.gd` lines 34-41 to:
- Find the intel panel (wherever W25 put it) rather than relying on `flow.intelligence`
- If `flow.intelligence` is valid after `open_intelligence()`, use it (pre-W25 path)
- If not, look for the panel in the galaxy scene tree (W25 path)
- Update line 40: replace bare `c.state.launch_option.sith_offer_id` with
  `c.state.get("launch_option", {}).get("sith_offer_id", "")`
- Update line 40: check briefing.tscn OR the W25 readiness script (same as Fix 1 pattern)

Minimal change: only update the lines that break. Do not restructure the test.

## Verification

1. Run focused suite first:
```bash
cd /home/jess/projects/tw-w25/integrate
/home/jess/projects/.tools/godot/godot --headless --import 2>&1 | tail -5
/home/jess/projects/.tools/godot/godot --headless \
  --path godot \
  --script tests/runner.gd \
  -- suite=galaxy_view_test 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/fix4-galaxy-view.log
/home/jess/projects/.tools/godot/godot --headless \
  --path godot \
  --script tests/runner.gd \
  -- suite=integration_test 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/fix4-integration.log
```
Both must show 0 failures and 0 SCRIPT ERRORs.

2. Run full gate:
```bash
cd /home/jess/projects/tw-w25/integrate
./godot/test.sh 2>&1 | tee /home/jess/projects/tw-logs/w25/integrate/fix4-full-gate.log
```
Must exit 0, 0 failures, 0 SCRIPT ERRORs, Normal 9/20.

3. If gate passes:
```bash
git add godot/tests/galaxy_view_test.gd godot/tests/integration_test.gd
git commit -m "fix(tests): update galaxy_view + integration tests for W25 intel view and readiness-screen launch path"
```

## Boundaries
- Touch ONLY `godot/tests/galaxy_view_test.gd` AND `godot/tests/integration_test.gd`.
- Do NOT change game logic (galaxy.gd, campaign_bridge.gd, w25_menus_readiness.gd, etc.).
- Minimum changes — only the lines that actually fail.
- If a third distinct test file fails (not these two), STOP and write BLOCKED in
  `/home/jess/projects/tw-logs/w25/integrate/fix4-result.md` with the exact error.

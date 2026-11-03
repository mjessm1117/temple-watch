# Night 1b addendum — finish era-transition arc resolution (2026-11-03)

You already did most of docs/godot/night1/STORY2.md in this worktree (uncommitted changes present — keep them, do not reset). You reported: the era 2 gate is incomplete because the era transition replaces the roster before the step-3 resolution can reward that character.

## Lease extension (granted)
In addition to the STORY2.md lease you may edit:
- godot/scripts/story/story_engine.gd — ONLY a small call/hook. It is ~570 lines and must stay under 600; put logic in arc_night1.gd or arc_rewards.gd.
- godot/scripts/campaign_bridge.gd — ONLY to show pending arc resolutions before the era roster swap (e.g. queue the step-3 dialogue(s) before advance_era replaces the roster, then continue the era transition and interlude as today).

## Requirement
When era 2 starts with an arc at step 2 and that character alive, the player sees that character's step-3 resolution BEFORE the roster swap, and its reward lands (or carries forward in a way the test proves). Dead characters still close with a memorial line. Era interlude still shows after.

## Verification
Add tests to story_night1_test.gd for this path. ./godot/test.sh exit 0, 0 SCRIPT ERROR, all suites 0 failures, Normal rescue 10/20. Then commit everything (STORY2 work + this) with message "Give each Jedi arc its own rewards and slower pacing". Do not push. Do not delegate or spawn subagents.

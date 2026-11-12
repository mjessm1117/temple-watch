# W23 Look / Graphics — shared rules for all 5 lanes

Jess picked all 5 lanes (ask-4aab69d1). Source of truth for gaps, causes and leases:
/home/jess/projects/tw-logs/w23/audit/AUDIT-REPORT.md (read it first, plus its captures/ and perf-metrics.json).

## Setup (same pattern as docs/godot/w22/COMMON.md "Setup", with w22 -> w23)
- Worktree /home/jess/projects/tw-w23/<lane> on new branch w23/<lane> off main b8a8bde.
- rsync the untracked godot/assets + addons from /home/jess/projects/temple-watch, then `godot --headless --import` before any test.
- Godot binary: /home/jess/projects/.tools/godot/godot.

## Rules
- Write ONLY inside your lease (paths relative to godot/) plus new `scripts/w23_<lane>_*.gd` helpers, your test `tests/<lane>23_test.gd`, and ONE added line in test.sh.
- game.gd, project.godot, data/rules, map collision: read-only for everyone.
- Need a change in another lane's file? Do not touch it. List it under "Integrate asks" in your RESULT.md.
- Any call into another lane's helper is guarded (has_method / has_signal) so each lane passes alone.
- Legacy test assertion edits only with a one-line reason each in RESULT.md.
- Files stay under 600 lines (split into w23_<lane>_* helpers).
- New art: free only. Shader/lighting, Blender (blender -b --factory-startup, delete default objects first), or CC0 from Poly Haven / ambientCG / Kenney (no logo) / Quaternius. Record source URL + licence in your asset folder's CREDITS.md. Resize to mobile atlases (512² default, 1024² max) and add LODs.
- NO Meshy calls, no credit spend (the optional 70-credit quote is not approved). Never print MESHY_KEY.
- Never copy XCOM 2 reference images into the repo (public). Side-by-sides live in tw-logs only.
- No commits to main, no push, no `git stash -u`, no `git clean`, never delete untracked files.

## Phone budget (hard)
- Baseline = audit perf-metrics.json. Compatibility/GLES3 Low tier is the phone target: <=150 draw calls, <=300K visible tris, <=256 MB VRAM, 60 fps goal.
- No lane may raise Low draw calls or triangles on the gate map (390x844 and 1280x720) by more than 5% vs baseline. Lanes 1 and 3 should bring gate Low to <=150 draws.
- Pack growth caps (production-filtered export, vs 45.3 MB): lane1 2.0 MB, lane2 1.5 MB, lane3 0.5 MB, lane4 0.5 MB, lane5 0.5 MB.
- Everything fancier than Low is optional tier with auto-fallback.

## Gate (each lane, in its worktree)
- `godot --headless --import` exit 0; `./godot/test.sh` exit 0; 0 "SCRIPT ERROR"; 0 failures; Normal rescue 9-11/20; `git diff --check` clean.
- Your <lane>23_test.gd covers your gaps with yes/no checks (perf counters + visual-state asserts).

## Proof (outputs under /home/jess/projects/tw-logs/w23/<lane>/)
- 2026-11-10-<lane>-sheet.jpg: before/after pairs at 390x844 Low and 1280x720 High for each gap you fixed (4-8 panels, one JPG).
- Optional private compare with the audit's XCOM ref (same folder, never the repo).
- RESULT.md: commit sha, files changed, gate numbers, perf table before/after (draws, tris, fps proxy, pack delta), gaps fixed vs not, legacy test edits + reasons, Integrate asks.

## Finish
- Commit on w23/<lane> (message ends with: Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>). Do not merge or push.
- Final message: commit sha, gate numbers, perf delta, sheet path, integrate asks.

## Cross-lane contracts
1. Lane 4 adds `func set_ui_safe_rect(rect: Rect2) -> void` to temple_view.gd AND galaxy_map.gd: 3D framing keeps the focused room / planet inside the screen area NOT covered by `rect`.
2. Lane 5 calls it (guarded) from campaign/temple.gd and campaign/galaxy.gd with the rect of its room sheet / selected-mission card.
3. Lane 3 owns combat_scene.gd + graphics_settings.gd tier hooks. Others needing a tier flag read `GraphicsSettings` (read-only) or ask via Integrate asks.
4. Lane 2 exposes `func set_saber_halo(enabled: bool)` on unit_view.gd if lane 3 wants a tier toggle; lane 3 calls it guarded. Lane 2 builds the cheap halo mesh, lane 3 decides tier.
5. Lane 5 owns campaign/ui.gd shared palette/type tokens; others read them only.

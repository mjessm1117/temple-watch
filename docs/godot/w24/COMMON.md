# W24 Battle feel + Controls — shared rules for all 6 lanes

Jess picked all 6 lanes (ask-9a14bd71): battle A feelcam, B impact, D threat + controls camgest, command, hud.
Battle lanes C (decision) and E (phone/perf) from the battle audit were folded into the controls lanes below.
Sources of truth (read your rows first, plus the captures):
- /home/jess/projects/tw-logs/w24/audit/AUDIT-REPORT.md (battle gaps B1-B15)
- /home/jess/projects/tw-logs/w24/controls/CONTROLS-REPORT.md (controls gaps K1-K12)
- Jess playtest notes: /home/jess/projects/tw-logs/w20/2026-11-09-jess-playtest-notes.md

## Setup (same as docs/godot/w23/COMMON.md, with w23 -> w24)
- Worktree /home/jess/projects/tw-w24/<lane> on new branch w24/<lane> off main aa19dd0.
- rsync untracked godot/assets + addons from /home/jess/projects/temple-watch, then `godot --headless --import` before any test.
- Godot binary: /home/jess/projects/.tools/godot/godot.

## Leases (paths under godot/scripts/ unless noted; EXCLUSIVE)
| Lane | Owns | Gaps |
|---|---|---|
| feelcam | game.gd, cam_combat.gd, combat_turns.gd, enemy_presentation.gd, cine15_shot.gd, battle16_killcam.gd, feelcam22_events.gd | B3 trigger, B4, B6 show, B8 show, B9 trigger, B11 show, B14 beat; K2 game side, K11 lock state, zoom clamp unify |
| impact | fx.gd, audio.gd, unit_view.gd, effects_jedi.gd, effects_soldier.gd, w23_lightfx_billboards.gd | B3, B7, B8 VFX, B9, B10, B11, B14 footfall |
| threat | ai.gd, combat_mission.gd, mission_pressure.gd, reinforcement_marker.gd, enemy11_plate.gd, mission.gd, abilities_engine.gd | B2 data, B6 reason, B7 segment types, B8 leap event, B13 data, B14 cover-break cause |
| camgest | touch_input.gd, battle11_camera.gd, hud_phone_camera_art.gd, map_art_batch.gd, map_art_geometry.gd, map_art_edges.gd | K1, K2 touch side, K5, initial heading, B5 (portrait Low <=150 draws) |
| command | input_controls.gd, combat_targeting.gd, battle12_aim.gd, map_art_grid.gd | K4, K6, K7, K8, K10, B2 preview, B12 data |
| hud | hud_phone.gd, hud_phone_layout.gd, hud_phone_action_art.gd, hud_controls.gd, hud_ability_button.gd, graphics_options.gd, hud_night1.gd | K3, K9, K11 cue, K12, B1 layout, B12 show, B13 show, B15 |

## Rules
- Write ONLY your lease plus new `scripts/w24_<lane>_*.gd` helpers, ONE test `tests/<lane>24_test.gd`, and ONE added line in test.sh.
- project.godot, data/rules, map collision, other lanes' files: read-only. Need a change there? List it under "Integrate asks" in RESULT.md.
- Every call into another lane's API is guarded (has_method / has_signal) so each lane passes alone.
- Do NOT change game rules, hit math, AI decisions or balance. Presentation, input and feedback only. Normal rescue must stay 9-11/20.
- Legacy test assertion edits only with a one-line reason each in RESULT.md.
- Files stay under 600 lines (split into w24_<lane>_* helpers).
- New art: free only (procedural shader/geometry, Blender headless, or CC0 with CREDITS.md entry). NO Meshy calls. Never print MESHY_KEY.
- Never copy XCOM 2 reference images into the repo (public). Compares live in tw-logs only.
- No commits to main, no push, no `git stash -u`, no `git clean`, never delete untracked files.
- Keep: 44 px minimum touch targets, iPhone drag scrolling, the threat chip, non-blocking radio cards, Fire -> target -> Confirm, the 2-action rule.

## Phone budget (hard)
- Low tier on gate map at 390x844 and 1280x720: no lane raises draw calls or triangles more than 5% vs aa19dd0 (camgest must LOWER portrait Low to <=150 in a real battle-state counter, not a headless 0-draw read).
- Pack growth caps vs 46.3 MB: impact 1.0 MB, every other lane 0.3 MB.
- Input latency: tap -> visible response <=100 ms on Low (measure frames).

## Cross-lane contracts (implement yours; call others guarded)
1. feelcam (game.gd) exposes `cancel_camera_glide24() -> void` (kills select/focus tween, keeps current pivot). camgest calls it when a drag passes its threshold.
2. feelcam exposes `is_input_busy24() -> bool` and signal `input_busy_changed24(busy: bool)`. hud shows a small busy cue; command queues only safe selections while busy.
3. feelcam (cam_combat.gd) exposes `set_battle_safe_rect24(rect: Rect2)`: aim/shot framing keeps shooter + target inside the screen NOT covered by rect. hud calls it with the odds card / tray rect.
4. feelcam exposes `preview_route24(path: Array)` (optional gentle camera hint toward a long route end). command may call it.
5. impact exposes `impact24_cue(kind: String, pos: Vector3, power: float = 1.0)` (kinds: hit, crit, miss_near, kill, blast, saber, force, leap_land, cover_break) and on unit_view `travel24(path: Array, dash: bool, segments: Array = [])` and `fall24(variant: int, dir: Vector3)`. feelcam triggers them.
6. threat (mission.gd / combat_mission.gd) exposes `route_threat24(path: Array, actor_id) -> Dictionary` ({overwatch_tiles, reveal_tiles, flanked_end, danger_index}) using the SAME per-tile rule as the real overwatch check; `intent_reason24(event: Dictionary) -> String` (short why: "Flanking", "Overwatch", "Objective", "Grenade cluster"); `route_segments24(path) -> Array` (walk/vault/climb/door per step); leap emits start+end in its event.
7. command (combat_targeting.gd) exposes `decision_details24(attacker, target) -> Array` of {label, value} for every hit modifier; hud renders them. command owns key semantics and exposes `bindings24() -> Dictionary` (action -> key list); hud's settings screen reads/remaps through it.
8. Controls settings live in `user://controls24.cfg`, section "controls", keys: cam_sensitivity (float 0.5-2.0, default 1.0), invert_pan (bool false), invert_rotate (bool false), edge_pan (bool true), confirm_move (bool true on touch, false on mouse), keymap (Dictionary). hud writes it; camgest/command/feelcam read it with ConfigFile + defaults (no cross-lane class references).

## Gate (each lane, in its worktree)
- `godot --headless --import` exit 0; `./godot/test.sh` exit 0; 0 "SCRIPT ERROR"; 0 failures; Normal rescue 9-11/20; `git diff --check` clean.
- Your <lane>24_test.gd checks each gap you own with yes/no asserts (simulated touch/mouse/key events, timings, rects, counters).

## Proof (under /home/jess/projects/tw-logs/w24/<lane>/)
- 2026-11-11-<lane>-sheet.jpg: before/after at 390x844 Low and 1280x720 for each fixed gap (4-8 panels, one JPG). Timing gaps: frame strips.
- RESULT.md: commit sha, files changed, gate numbers, before/after table (taps, ms, draws, tris, pack delta), gaps fixed vs not, legacy test edits + reasons, Integrate asks.

## Finish
- Commit on w24/<lane> (message ends with: Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>). Do not merge or push.
- Final message: commit sha, gate numbers, before/after, sheet path, integrate asks.

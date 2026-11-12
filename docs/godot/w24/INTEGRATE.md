# W24 integrate — merge 6 lanes, wire cross-lane APIs, gate, ship

## Goal

Merge all 6 W24 lanes into a single `w24/integrate` branch, apply the cross-lane wiring edits the lane reports called out, verify the combined gate is green (import + full test suite exit 0, 0 SCRIPT ERROR, Normal rescue ≥7/20), measure combined portrait Low draw count and reduce toward ≤150, then push to main and update the phone site.

## Context

Base: `aa19dd05` on `main`. Six lane branches all verified clean:

| Lane | Branch | Commit | Key deliverable |
|---|---|---|---|
| feelcam (A) | w24/feelcam | b262b9b | 280ms shot blend, 55ms hit stop, 255ms kill-cam, enemy turn 4.67→1.57s |
| impact (B) | w24/impact | 6bfb043 | Pooled hit/blast cues, directional falls, dash-aware travel, weighted movement |
| threat (D) | w24/threat | 7d33d9e | Per-tile route danger, intent reasons, reinforcement cue data, cover-break causes |
| camgest | w24/camgest | d10643f | Bounded rotation, glide-cancel on drag, board pans only from map (not UI), draws 178→176 |
| command | w24/command | 0769186 | PC 1-click move, Y=Overwatch, End/Backspace=End Turn, R=reload, target swipe |
| hud | w24/hud | 8d8f750 | Portrait layout fixed (0 button overlap), compact aim card, settings with controls panel |

Worktree path: `/home/jess/projects/tw-w24/integrate`. Use Godot at `/home/jess/projects/.tools/godot/godot`.
Logs path: `/home/jess/projects/tw-logs/w24/integrate/` (create if absent).
Phone site repo: `/home/jess/projects/tw-play-site`.
Reference shots (private, never commit): `/home/jess/projects/tw-reference/`.

## Setup

```bash
cd /home/jess/projects/temple-watch
git worktree add ../tw-w24/integrate -b w24/integrate aa19dd05
```

## Merge order

Merge in this order to minimize conflicts. Each branch has disjoint file leases so conflicts are unlikely; if one occurs, resolve in favour of the later branch's changes and note it.

```bash
cd /home/jess/projects/tw-w24/integrate
git merge w24/threat    # data APIs; no file overlap
git merge w24/impact    # fx/audio/unit_view; no overlap with threat
git merge w24/feelcam   # game.gd + cam_combat.gd; uses threat+impact guarded APIs
git merge w24/command   # input_controls/combat_targeting/battle12_aim; no overlap
git merge w24/camgest   # touch_input + battle11_camera + 4 test assertion updates
git merge w24/hud       # hud_phone/hud_controls/hud_phone_layout/hud_phone_action_art/hud_ability_button/graphics_options + 2 new scripts
```

After all 6 merges, run `godot --headless --import` and verify exit 0 with 0 SCRIPT ERRORs before continuing.

## Cross-lane wiring edits (7 required)

Apply these edits after all 6 merges. Use `has_method` guards on all cross-lane API calls so either side can ship safely without the other.

### 1. feelcam → impact: hit direction and event cues

In `godot/scripts/game.gd`, in the shot/kill/leap/cover beat handlers added by the feelcam lane, add guarded calls to impact's exposed APIs:

```gdscript
# ordinary hit
if fx.has_method("impact24_cue"): fx.impact24_cue(kind, hit_world_pos)
# kill
if fx.has_method("fall24"): fx.fall24(impact_direction_normalized)
# Jedi Leap land
if fx.has_method("leap24_land"): fx.leap24_land(land_world_pos)
# cover destruction
if fx.has_method("cover_break24"): fx.cover_break24(cover_world_pos)
```

The impact lane exposes `impact24_cue(kind, pos)`, `fall24(dir)`, `leap24_land(pos)`, `cover_break24(pos)` on `fx.gd`. The feelcam lane added placeholder stubs or beat hooks; wire them here.

### 2. feelcam + threat → impact: dash state and route segments to travel24

In `game.gd` (or the unit movement path in `combat_mission.gd`), when a unit begins its move animation, call:

```gdscript
if fx.has_method("travel24"):
    var segs = mission.route_threat24(actor_id) if mission.has_method("route_threat24") else []
    fx.travel24(segs, is_dash)
```

`route_threat24` returns the threat-annotated segment list from the threat lane. `is_dash` comes from the dash flag already computed in `combat_mission.gd`.

### 3. feelcam → hud: safe rect for portrait aim card

In `game.gd`, after the aim card is positioned in portrait mode (in the aim setup path added or modified by the feelcam lane), call:

```gdscript
if hud_phone.has_method("set_battle_safe_rect24"):
    hud_phone.set_battle_safe_rect24(aim_card_screen_rect)
```

The HUD lane exposes `set_battle_safe_rect24(rect: Rect2)` on `hud_phone.gd`. The cam_combat lane uses it to keep the shot framing clear of the aim card.

### 4. feelcam → hud: busy-input signal

In `game.gd`, when the animation lock changes (the `is_animating` guard in the feelcam lane), emit the busy signal:

```gdscript
if hud_phone.has_method("set_input_busy24"):
    hud_phone.set_input_busy24(is_busy)
```

The HUD lane listens to this in `w24_hud_feedback.gd` to show the brief busy cue (gap K11).

### 5. hud → camgest: gate ability-drag board pan

In `hud_phone.gd`, the ability-button drag path (around line 312–319 as audited) fans into a board-pan call. Gate it so the gesture system stays in control:

```gdscript
# before the board-pan call in the ability drag handler:
if cam.touch.has_method("gesture_owns_touch24") and cam.touch.gesture_owns_touch24():
    return  # gesture system owns this touch; don't pan
```

This completes controls gap K5 (dragging an ability button pans the board).

### 6. hud → command: wire bindings24 in settings

In `w24_hud_controls_settings.gd`, the key-remap rows show as a read-only list when `bindings24` is absent. After merging command, `input_controls.gd` now exposes `get_bindings24()` and `set_binding24(action, key)`. Update the settings script:

```gdscript
if game.input.has_method("get_bindings24"):
    var b = game.input.get_bindings24()
    _populate_key_rows(b)   # make rows editable
    _connect_save(game.input, "set_binding24")
```

This turns the read-only remap list into a live editable panel.

### 7. command → threat: confirm live route hazard markers

In `input_controls.gd`, the route-preview threat query is already guarded (command lane). After merging threat, the guard fires. Confirm the tile-hover overlay shows overwatch-lane and reveal markers from `mission.route_threat24`. If the visual overlay in `map_art_grid.gd` needs a call to display the threat data, add it here.

## Draw-count reduction pass

After all merges and wiring edits, run the timed battle probe at 390×844 Low Compatibility (select → move preview → move → aim → fire → enemy turn) and record peak draw calls.

**Expected range:** 180–190 (HUD lane added ~8, camgest removed ~2 on the standalone baseline of 178).  
**Target:** ≤150.

If peak draws exceed 150, audit `godot/scripts/map_art_batch.gd` and `godot/scripts/hud_phone.gd` for the largest contributors:
- Merge material buckets in `map_art_batch.gd` (audit gap #5; drawing the same material in multiple passes costs draws)
- Reduce idle-state UI layers in portrait HUD (the HUD lane added new overlay nodes)
- Look for redundant `CanvasItem` draw calls in `hud_phone_layout.gd`

Do NOT remove a visual feature silently. If you cannot reach ≤150 without breaking something, document the remaining count and the blocker in RESULT.md and stop.

## Gate

Run all checks in this order:

1. `godot --headless --path godot --import` → must exit 0, must have 0 SCRIPT ERROR lines
2. `./godot/test.sh` → must exit 0, 0 failures, 0 SCRIPT ERROR lines
3. Normal rescue bot score ≥7/20 (consistent with W22–W24 baselines of 9/20)
4. `git diff --check` → clean
5. Portrait 390×844 Low peak draw calls: measure and record (target ≤150)
6. Desktop 1280×720 Low peak draw calls: measure and record

If the gate fails after 3 fix attempts on any single wiring item, write the failure to RESULT.md, leave `main` untouched, and stop. Do NOT ship a broken build.

## Updated test assertions

After wiring and before the gate, run `./godot/test.sh`. If assertions fail because combined behaviour differs from standalone (e.g., a layout assertion that assumed an API was absent), update the assertion to match the correct combined behaviour. Record each change in RESULT.md under "Updated test assertions." Do NOT relax an assertion that tests a spec-required feature.

## Ship

Once the gate passes:

```bash
# In the integrate worktree
git checkout main 2>/dev/null || true  # integrate branch merges INTO main
# Actually: push the integrate branch to main
git push origin w24/integrate:main
git push origin main --tags  # push last-good tag

# Update phone site
cd /home/jess/projects/temple-watch
./tools/prepare_web.py        # or equivalent export step
rsync -a --delete build/web/ /home/jess/projects/tw-play-site/
cd /home/jess/projects/tw-play-site
git add -A && git commit -m "W24 ship" && git push
```

Tag `last-good` on the new main commit:
```bash
cd /home/jess/projects/temple-watch
git tag -f last-good HEAD
git push origin last-good --force
```

## Output

Write `/home/jess/projects/tw-logs/w24/integrate/RESULT.md` with:
- Commit SHA on main after push
- Gate summary: suite count, failures, SCRIPT ERRORs, Normal rescue score
- Combined portrait 390×844 Low peak draw calls (before and after draw-reduction pass)
- Pack size in bytes (compare with W23 baseline 46,314,028)
- List of updated test assertions with reason
- List of any gaps not fully closed (with reason)

Write a combined before/after sheet:
`/home/jess/projects/tw-logs/w24/integrate/2026-11-11-w24-integrate-sheet.jpg`

Use ImageMagick or Python PIL to tile the top before/after pairs from each lane's proof sheets into one JPEG (aim for ≤2 MB, max 1600px wide). Include: portrait aim before/after, shot camera before/after, hit impact before/after, phone controls before/after, PC hotkeys before/after.

## Boundaries

- File lease: all files under `godot/` within the integrate worktree
- Do NOT modify `docs/godot/w24/INTEGRATE.md`
- Do NOT use Meshy or add new binary art assets
- Do NOT start W25 work
- Do NOT push `last-good` tag to any ref other than `last-good`
- If `godot --headless --export` aborts with exit 134 but the .pck file was written and has expected size, treat it as a successful export (known Godot headless export pattern)
- Never restart any Fleet process manager from inside this task

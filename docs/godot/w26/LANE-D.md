# W26 Lane D — Tactical Preview
Read COMMON.md first: docs/godot/w26/COMMON.md
Read audit: /home/jess/projects/tw-logs/w26/audit/AUDIT-REPORT.md

## Goal
Move range, enemy sight, and hover-tile odds/cover card closer to XCOM X2–X4.

## Changes

### 1. Move range (hud_controls.gd:85-91, map_art_grid.gd:71-88)
Current: filled translucent tile boxes covering terrain. Change to: thin perimeter outline only (cyan for safe, yellow if any enemy can see that tile). Fill should be very low alpha (≤0.08) or none. The outline style is similar to XCOM X3. This frees up terrain visibility while keeping the range legible.

### 2. Enemy sight danger tiles (map_art_grid.gd:150-156, input_controls.gd:75-99)
On T1 (and whenever a unit is selected before moving), draw a low-alpha danger tint on tiles that are in enemy sight range. Color: faint red (alpha ≤0.15). This is an always-visible indicator before the player commits to a move — not just during route preview. Only tiles in LOS of an awake enemy unit.

### 3. Route preview (input_controls.gd:75-99)
When hovering a destination tile, show the route with a single cyan path line, plus danger tiles along the route highlighted orange. Keep the existing overwatch/reveal markers; just add the path line.

### 4. Hover card (hud_controls.gd:99-129, hud_controls.gd:406-424, hud_phone.gd:198-241)
When hovering over a tile or unit:
- Show a compact anchored card (top-right corner on landscape, below objective chip on portrait).
- Card content: hit %, cover shields (directional), "seen by N" count.
- Do NOT show the card when the player is not in select/move/aim mode.
- Card must not overlap the action buttons.

### 5. Expose preview API
`preview26(tile: Vector2i, actor_id: int) -> Dictionary` with keys: `{cover_pct, flanked, seen_by, hit_pct_vs_nearest, route_safe}`. Lane C may call this to render the card.

## File lease (exclusive)
- godot/scripts/hud_controls.gd
- godot/scripts/input_controls.gd
- godot/scripts/map_art_grid.gd
- godot/scripts/combat_targeting.gd
- godot/tests/preview26_test.gd (create new)

## Test (preview26_test.gd)
- Assert move range tile fill alpha ≤ 0.1 in hud_controls constants.
- Assert danger tint is added for enemy-visible tiles (probe: place one enemy, check tile in its LOS gets tint flag).
- Assert `preview26` returns expected keys for a valid tile.
- Capture move-range screenshot at 852×393 — outline style visible.

## Boundaries
- Do NOT touch hud_phone_layout, unit_view, mission_*, reinforcement_marker, relay.json.
- Do NOT change actual combat hit calculations — display only.
- Do NOT break existing aim card or Overwatch overlay.

## Output
Commit on branch w26/preview. Leave w26/preview checked out. Screenshots at 852×393 showing outline move range and danger tiles. Gate passes (exit 0, 0 fail, 0 SCRIPT ERROR).

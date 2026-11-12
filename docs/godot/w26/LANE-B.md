# W26 Lane B — Side and Cover Visuals
Read COMMON.md first: docs/godot/w26/COMMON.md
Read audit: /home/jess/projects/tw-logs/w26/audit/AUDIT-REPORT.md

## Goal
Make ally vs enemy instantly readable at phone scale. Add cover height differentiation.

## Changes
1. **Side chevrons/pips**: in `unit_view.gd`, add a colored chevron or diamond shape drawn above/near unit HP plate. Ally = saturated cyan (#00d4ff or similar). Enemy = saturated red (#ff3030). Shape and color together — not just rim. Size must be visible at 852×393 Low (at least 10–12 px wide in world space).
2. **HP plate color**: ally plates use stronger cyan background, enemy use stronger red. Currently pale — increase saturation/opacity.
3. **Armor accent stripe**: in `gfx_unit_readability.gd`, increase rim alpha from ~0.45 to 0.72. Also add a colored accent stripe on the shoulder/chest area of the material using existing material param (not Meshy; use shader uniform if available, or modulate material color channel).
4. **Expose palette**: `side_color26(side: String) -> Color` returns the canonical cyan/red for that side. Lane C reads this.
5. **Cover height**: in `map_art_geometry.gd`, give full cover objects a distinct material tint (slightly darker/cooler) vs half cover (slightly warmer). Just a uniform color shift — no new meshes. Keep rule cover values unchanged.
6. **enemy_presentation.gd**: if this file sets any visual override that conflicts with the above, align it to the new palette.

## XCOM 2 reference
Audit saw X7 uses saturated cyan/red pips adjacent to HP; side identity survives small phone view. Match that principle.

## File lease (exclusive)
- godot/scripts/unit_view.gd
- godot/scripts/gfx_unit_readability.gd
- godot/scripts/map_art_geometry.gd
- godot/scripts/enemy_presentation.gd
- godot/tests/side26_readability_test.gd (create new)

## Test (side26_readability_test.gd)
- Assert `side_color26("ally")` returns a blue-ish color (R < G < B, or B channel > 0.5).
- Assert `side_color26("enemy")` returns a red-ish color (R channel > 0.5, B < R).
- Assert ally rim alpha ≥ 0.70 in gfx_unit_readability.gd constants.
- Assert full cover and half cover use different material tints (different color values).

## Boundaries
- Do NOT touch hud_*, mission_*, relay.json, or any file not in lease.
- Do NOT use Meshy or add new 3D models.
- Keep all existing combat rule values (cover bonus percentages) unchanged.

## Output
Commit on branch w26/side. Leave w26/side checked out. Screenshots at 852×393 and 390×844 showing ally/enemy in battle — side difference should be clear. Gate passes (exit 0, 0 fail, 0 SCRIPT ERROR).

# Jedi Temple environment art

The rescue board is drawn by `godot/scripts/env_art.gd` from the live `rescue.json` mission grid. The rules remain in `mission.gd` and `shot.gd`. A tile's visible form follows its rule glyph:

| Glyph | Art |
| --- | --- |
| `.` | Worn stone flagstones, grout, occasional chips and small growth |
| `^` | Raised pale stone terrace at 0.7 m |
| `M` | Raised marble terrace at 1.4 m with carved risers |
| `#` | Full-height carved wall, broken column, or guardian statue |
| `c`, `h` | Waist-high stone cover and reinforced barricade |
| `k` | Waist-high holo-terminal |
| `r` | Loose rubble after cover breaks |
| `E` | Cyan evacuation inlay |

The mission is surrounded by ruined columns, planters, braziers, a temple gate with spires, and a distant Coruscant silhouette. A sun crest is inlaid in the open lower courtyard. Stone color, grain, edge wear, and moss are procedural in `godot/assets/env/stone.gdshader`; no external textures or models were added. Golden-hour sun, cool fill, depth fog, and brazier lights are configured by `env_art.gd` when the board is created. Braziers flicker in `_process`.

Repeated floor, trim, wall, vegetation, and skyline pieces are grouped into `MultiMeshInstance3D` batches. Only substantial structures cast shadows; flagstones and small details do not, which keeps software capture and shadow rendering practical. The Force Push code already calls `_build_terrain()` when a cover tile changes. That call now rebuilds art from the current mission grid, so a broken wall or barricade becomes rubble while the existing chunk effect plays.

## Tuning

- Adjust palette and procedural surface parameters in `_setup_resources()` and `stone.gdshader`.
- Adjust cover heights in `_wall()`, `_low_wall()`, and `_terminal()` while keeping `#` visibly taller than `c`, `h`, and `k`.
- Adjust non-playable scenery in `_backdrop()` and `_temple_gate()`; these are outside the 26 × 26 rule grid.
- Adjust sun, fill, fog, and sky in `_configure_lighting()`. Brazier range and energy live in `_brazier()`.
- The game uses the mission's live glyphs, so new rubble from Force Push requires no art data edit.

## Verification and captures

Actual `./godot/test.sh` result on Godot 4.7.2: **140 checks, 0 failures; Normal rescue bot 11/20 wins (55%)**. The test count includes concurrent AI and difficulty work. Both PNGs were captured with Forward+ software Vulkan under `xvfb-run`; RTX frame rate was not measured. The closeup uses a posed squad beside the mission's real cover, with the HUD hidden for the art still.

```bash
xvfb-run -a -s '-screen 0 1366x768x24' /home/jess/projects/.tools/godot/godot --path godot --resolution 1366x768 -s res://scripts/env_capture.gd -- overview
xvfb-run -a -s '-screen 0 1366x768x24' /home/jess/projects/.tools/godot/godot --path godot --resolution 1366x768 -s res://scripts/env_capture.gd -- closeup
```

![Whole temple battlefield](shots/art-overview.png)

![Squad beside carved stone cover](shots/art-closeup.png)

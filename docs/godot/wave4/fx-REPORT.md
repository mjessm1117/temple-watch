# FX lane report

## Player changes

- Units ease into turns before shooting or casting, blend into run and action clips, lean into attacks, flinch on hits, and fall sideways on death. Movement plays synthesized footsteps.
- Shots have a brief muzzle light, bright traveling core, short tracer, impact sparks, and bounded persistent ground scorches. Misses have a synthesized whiz.
- Saber strikes add light, a short trail, ignition and clash accents. Force Push has a fast expanding wave and debris.
- Sounds use layered synthesized voices and a quiet looping ambience. Individual samples and voice gain are limited to leave mix headroom. All assets are generated in code.
- `set_cover`, `stagger_to`, and `hit_stop` are implemented for integration after this lane merges.

## See it in game

Start the rescue mission. Move a squad member, then use Shoot, Strike, or Push. A staged shot is shown in [wave4-fx-shot.png](../shots/wave4-fx-shot.png), captured at 1366×768 with `res://scripts/fx_capture.gd`.

## Tests

- `./godot/test.sh`: 140 checks, 0 failures, no script errors.
- `godot --headless --path godot -s res://tests/fx_test.gd`: 10 checks, 0 failures.
- Godot still reports resource/object leak warnings on scene teardown. Frame time at 1366×768 has not been measured.

## Integration requests

- `godot/scripts/game.gd`, `_refresh`: after each unit view is created or updated, call `view.set_cover(1 if Shot.in_cover(mission, Shot.pos(u)) else 0)`; use `2` if full cover can be determined for the relevant incoming direction. This activates the cover crouch pose.
- `godot/scripts/game.gd`, `_attack`: replace the Push target's `travel([destination])` call with `stagger_to(destination)`. After a damaging hit, call `sound.play("hit")`. For a crit or kill, call `fx.hit_stop()` after the result is known. These calls use the hooks implemented here.
- `godot/tests/run.gd`, `run`: optionally preload and invoke `res://tests/fx_test.gd` as part of the standard test gate; the focused test currently runs as a separate command because `run.gd` is outside the file lease.

## Open problems

- Cover crouch, Push stagger, and crit/kill hit stop need the integration calls above.
- No sustained saber hum or true screen space refraction yet. The current saber ignition and Force Push wave are short procedural cues.
- The 60 fps target needs an in-game frame timing pass after branch integration.

# Wave 16 `show` report

## Goals

| Goal | Result | Evidence |
| --- | --- | --- |
| Seven named Jedi portraits | **FAIL** overall: story, comms, debrief, and Temple roster pass; deployment roster still uses `armory` lane's generic `loadout_actor.gd` portrait model. That file is outside this lane's lease. | [Before sheet](../../shots/wave16-show-before-portraits.png), [after sheet](../../shots/wave16-show-after-portraits.png), [phone roster](../../shots/wave16-show-after-roster-phone.png) |
| Jedi in story scenes | **PASS**. The shared portrait resolver now returns each Jedi's baked model portrait; troopers and villains retain their existing images. | [Phone before](../../shots/wave16-show-before-story-phone.png), [phone after](../../shots/wave16-show-after-story-phone.png), [desktop after](../../shots/wave16-show-after-story-desktop.png) |
| Jedi in built Temple rooms | **PASS**. Active named Jedi occupy completed rooms. Low uses a static idle pose on the 1.4K-triangle LOD and adds no lights. Phone room face chips make the occupants identifiable while keeping room labels legible. | [Phone before](../../shots/wave16-show-before-temple-phone.png), [phone after](../../shots/wave16-show-after-temple-phone.png), [desktop before](../../shots/wave16-show-before-temple-desktop.png), [desktop after](../../shots/wave16-show-after-temple-desktop.png) |

## Render cost

| Capture | Draws before → after | Triangles before → after |
| --- | ---: | ---: |
| Temple, 844×390 Compatibility/Low | 280 → 284 (+1.4%) | 175,600 → 176,507 (+0.5%) |
| Temple, 1366×768 High | 429 → 431 | 241,458 → 247,458 |
| Kira story, 844×390 Low | 98 → 98 | 64,725 → 64,725 |
| Kira story, 1366×768 High | 116 → 116 | 131,781 → 131,781 |

The seven shipped portrait PNGs total 489,016 bytes; this is below the 3 MB lane budget. No Low post-process was added. Captures were opened and visually checked at their native sizes.

## Gate

Fresh-worktree import and final headless import both exited 0. `./godot/test.sh` exited 0: 62 suite result lines reported 0 failures, including `show16_test.gd` (36 checks), `home14_test.gd` (101 phone and 59 desktop checks), and `story14_test.gd` (188 checks). There were 0 `SCRIPT ERROR`, 0 parse errors, and 0 failure lines. Normal rescue was 9/20. `git diff --check` was clean. See [test.log](test.log) and [import.log](import.log).

## Integration note

The deployment squad roster creates its portrait from `loadout_actor.gd`, which is leased to `armory`. Its generic Jedi model is the remaining roster identity gap. `armory` can use `jedi_models.gd`'s public `scene_for_id()` with `Jedi.id_for({"name": r.n})`, or load `res://assets/portraits/jedi/<id>.png` for a static card.

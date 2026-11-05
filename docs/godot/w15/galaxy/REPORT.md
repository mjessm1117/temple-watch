# Wave 15 galaxy lane

## Changes

- Replaced the map's art materials with procedural spiral dust, a shaded per-biome planet surface, a red Sith territory with a soft border, and pulsing curved hyperspace routes. The existing 3D stars and rotating planets remain in use.
- Low uses two backdrop layers (nebula and stars) and two planet noise samples. Medium/High add a distant dust layer and a third planet detail sample.
- Selecting a signal still zooms to its planet and now shows a holo card with name, biome, and threat. The briefing panel, phone MORE button, tabs, and mission launch remain available.

## Measured rendering work

Same campaign fixture, scene, window size, and renderer for each before/after pair. Draw calls and primitives are the maximum over 30 settled frames, including the UI and subviewport.

| View | Draw calls | Primitives |
| --- | ---: | ---: |
| Low Compatibility, 844×390 phone before | 102 | 43,696 |
| Low Compatibility, 844×390 phone after | 103 | 43,831 |
| High Forward+, 1366×768 desktop before | 145 | 82,878 |
| High Forward+, 1366×768 desktop after | 147 | 83,015 |

Low adds one draw call (+1.0%), below the 117 ceiling (+15% from 102). The Low capture used Mesa llvmpipe under Xvfb; these counts verify rendering work, not actual phone frame rate. A 60 fps device result needs a physical phone run. No Low post-process was added.

## Captures

All six real-window PNGs were inspected at native size.

| State | Phone 844×390 | Desktop 1366×768 |
| --- | --- | --- |
| Before | [phone](../../shots/wave15-galaxy-before-phone.png) | [desktop](../../shots/wave15-galaxy-before-desktop.png) |
| After | [phone](../../shots/wave15-galaxy-after-phone.png) | [desktop](../../shots/wave15-galaxy-after-desktop.png) |
| Selected Sith frontier | [phone](../../shots/wave15-galaxy-selected-phone.png) | [desktop](../../shots/wave15-galaxy-selected-desktop.png) |

## Gate

`galaxy15_test` checks all 14 theme materials, seven curved routes, Sith tint, focus zoom, briefing and MORE access, and the Low draw ceiling. The rendered phone run passed 42 checks and the desktop run passed 38, each with zero failures.

Final headless import exited 0. `./godot/test.sh` exited 0 across 57 Godot invocations, with zero `SCRIPT ERROR`, parse errors, or suite failures. The new headless suites passed 39 phone and 36 desktop checks; the existing galaxy view suite passed 62. Normal rescue won 9/20. `git diff --check` was clean.

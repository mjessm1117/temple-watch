# Lane: fx — animation, impact and sound that make actions land
Read WAVE4.md first; its rules apply. Branch: wave4/fx.

FILE LEASE: `godot/scripts/unit_view.gd`, `godot/scripts/fx.gd`, `godot/scripts/audio.gd`, new files `godot/scripts/fx_*.gd`, `godot/scripts/audio_*.gd`, `godot/assets/fx/**`, `godot/assets/audio/**`, new test file `godot/tests/fx_test.gd`.

Goal: every move, shot, strike and death should feel weighty, like XCOM 2. Improve existing functions IN PLACE keeping their names and signatures, so game.gd picks up the upgrade with no changes. New hooks go in Integration requests.
- Units: smooth animation blending, turn-to-face before acting, crouch/lean when in cover, hit flinch, stagger on Push, readable death falls; footsteps.
- Shots: muzzle flash with a short light, bright bolt with glow and light, impact sparks, scorch decals that persist, near-miss whiz; crit/kill gets a brief hit-stop.
- Sabers: ignite/hum, swing trail, clash sparks; Force Push distortion wave and debris.
- Sound: richer synthesized SFX and a low ambience loop; mix so nothing clips. Only procedural/synth or files you generate; no downloaded or copyrighted assets.
- Keep everything short and skippable; 60 fps at 1366×768.

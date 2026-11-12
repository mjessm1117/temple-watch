# W22 lane B — Impact, animation and audio (task tw-w22-impact)

First read /home/jess/projects/temple-watch/docs/godot/w22/COMMON.md and follow it exactly. Your lane name is `impact`, so your worktree is /home/jess/projects/tw-w22/impact on branch w22/impact, off 81c7644.

## Goal
Fix: Battle problems #5, #6, #10, #11, #15 and the footfall part of #13. Use the audit rows for causes, files and lines.

## Work
- Normal hit: a cheap emissive flash/rim on the target, a recoil reaction and a distinct contact sound. Add a hit-stop only on crit/kill (within the COMMON budget).
- Explosion: a two-stage blast silhouette that stays readable at Low, a sub-bass impact sound and a capped camera impulse. Expose the impulse as a function A can call; do not edit A's files.
- Saber: a quiet looping hum while the blade is active, plus a rim flash at clash.
- Kill: a kill sting and a longer visible fall. The body stays readable, with a budgeted corpse count (at most 6 live).
- Footstep/dust punctuation on moves.
- Music: a lightweight procedural or synth loop with crossfades for calm, contact, enemy phase and victory. It respects mute/volume. Keep added audio assets under 1.5 MB total; synthesized audio is preferred.
- Story stings for `villain`, `radio`, `alert`, `victory` and `defeat`.
- Implement contract 3.

## File lease (you may write ONLY these)
`godot/scripts/fx.gd`, `godot/scripts/audio.gd`, `godot/scripts/unit_view.gd`, `godot/scripts/effects_jedi.gd`, `godot/scripts/effects_soldier.gd`, new `godot/scripts/impact22_*.gd`, new audio files under `godot/assets/audio/w22/`, `godot/tests/impact22_test.gd`

Every other file is read-only. Changes needed elsewhere go under Integrate asks.

## Test
New suite `godot/tests/impact22_test.gd`, registered with one line in test.sh. It covers each Work bullet with real assertions (numbers, not just "exists").

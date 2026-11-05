# Wave 14 story lane

## Player change

- Briefings, debriefs, and Temple conversations now show a baked speaker portrait and name plate. Dialogue advances by tap and has a visible Skip control.
- Debriefs close with one squad beat drawn from death, wound, kills, bond, or safe return.
- Battle comms show a short, nonblocking portrait bark for first contact, ally down, objective complete, villain appearance, and last enemy. Each of the 21 named heroes has three data lines for each trigger. Barks fade within 2.7 seconds.
- Two new bond-gated Temple scenes continue Kira and Tor's watch and Rhal and Ilsa's route record.
- Twenty-one named heroes, four villains, and the Council have static 256×320 portraits baked from the existing unit GLBs with a lit SubViewport and team-coloured frame. The web asset retention list includes the portrait folder.

## Screenshots

- [Before phone](../../shots/wave14-story-before-phone.png) · [After phone](../../shots/wave14-story-after-phone.png) — 844×390
- [Before desktop](../../shots/wave14-story-before-desktop.png) · [After desktop](../../shots/wave14-story-after-desktop.png) — 1366×768

## Performance, Compatibility/Low

| Briefing capture | Before | After |
| --- | ---: | ---: |
| Phone draw calls | 96 | 99 |
| Phone triangles | 64,745 | 64,845 |
| Desktop draw calls | 131 | 122 |
| Desktop triangles | 143,342 | 131,979 |

Portraits are static rasters. Phone story no longer creates the offscreen live holo and portrait SubViewports. No new post effect, combat stat, action, or AI change.

## Remaining gaps and handoff

- XCOM 2 still has bespoke facial performances, voiced comms, and authored mission cinematics. These portraits share the existing unit models by class.
- The only `combat_scene.gd` hook is one `process_frame` signal connection to `story14_comms.gd`. It reads battle state and draws UI; it does not mutate battle state.
- No cross-lane request.

## Gate

- Import: clean.
- `./godot/test.sh`: exit 0; zero `SCRIPT ERROR` lines; every suite has zero failures; Normal rescue 9/20. `story14_test`: 148 checks, 0 failures on Low. Full results are in `test.log`.
- Web retention check: all 26 portrait PNGs match `RUNTIME_RASTER_DIRS`.
- `git diff --check`: clean.

## Fix pass — 2026-11-05

- Rebuilt all 26 portraits with deterministic per-ID material tint, camera angle and crop, key/rim light, and frame accents. Villains use red/black low-key lighting. The Council now has a blue three-figure hologram and a three-mark sigil card. The inspected [portrait sheet](portraits-sheet.png) shows 26 visibly distinct portraits; all 26 PNG MD5 hashes are unique. `story14_test` checks every hash.
- Desktop briefing has one large speaker portrait, which updates with the speaker and caption. Skip is a compact top-right control. Phone spacing was tightened so the advance control and short objective are visible.
- Replaced the after shots with captures taken after reveal. Added debrief shots with Kira's character beat and a phone battle comms bark:
  - [Briefing phone](../../shots/wave14-story-after-phone.png) and [desktop](../../shots/wave14-story-after-desktop.png)
  - [Debrief phone](../../shots/wave14-story-debrief-phone.png) and [desktop](../../shots/wave14-story-debrief-desktop.png)
  - [Battle comms phone](../../shots/wave14-story-comms-phone.png)
- Inspected all five final shots. Final briefing captures: phone 95 draw calls / 64,927 triangles; desktop 117 draw calls / 132,043 triangles. Portraits remain static rasters; no live portrait draw cost or new post effect.
- Gate: headless import exit 0; `./godot/test.sh` exit 0, zero `SCRIPT ERROR` lines, zero failures in every suite, Normal rescue 9/20; `story14_test` 177 checks and zero failures; `git diff --check` clean. Logs: `import-fix.log`, `test-fix.log`, `story14-fix.log`.

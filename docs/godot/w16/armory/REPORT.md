# Wave 16 armory report

## Goals

| Goal | Result | Evidence |
| --- | --- | --- |
| Selected Jedi hero | **PASS** | The armory uses the public Jedi model lookup for all seven named Jedi, with the generic Jedi as fallback. Troopers retain their class model. [Kira](../../shots/wave16-armory-after-desktop-high-u1-mk2.png), [Tor](../../shots/wave16-armory-after-desktop-high-u2-mk2.png), [Satele](../../shots/wave16-armory-after-desktop-high-u1-satele-mk2.png); the test checks all seven mappings and the fallback. |
| Fitted tier armor | **PASS** | Blender exports curved chest, pauldron, bracer, and greave pieces for Mk I padded, Mk II plated, and Mk III ornate armor. Bone rest transforms fit each body; three chest-depth adjustments handle different robe silhouettes. Every piece has a smaller Low LOD and stays under 1.5K triangles. [Mk I](../../shots/wave16-armory-after-desktop-high-u1-mk1.png), [Mk II](../../shots/wave16-armory-after-desktop-high-u1-mk2.png), [Mk III](../../shots/wave16-armory-after-desktop-high-u1-mk3.png), [armored trooper](../../shots/wave16-armory-after-desktop-high-u3-mk2.png). |
| Rendered gear art | **PASS** | Blender-rendered 256 px transparent art covers three saber hilts, five Kyber colors, blaster, modules, and three Jedi/trooper armor sets. The slot grid uses matching 128 px thumbnails. Selected art occupies a 200 px desktop or 120 px phone card with labels outside the image. [Desktop](../../shots/wave16-armory-after-desktop-high-u1-mk2.png), [phone](../../shots/wave16-armory-after-phone-low-u1-mk2.png). |

All captures were opened and inspected at their native sizes. Additional [Ressa](../../shots/wave16-armory-after-desktop-high-u1-ressa-mk2.png), [Kell](../../shots/wave16-armory-after-desktop-high-u1-kell-mk2.png), [Sava](../../shots/wave16-armory-after-desktop-high-u1-sava-mk2.png), and [Tem](../../shots/wave16-armory-after-desktop-high-u1-tem-mk2.png) shots cover the remaining Jedi. The Satele, Ressa, Kell, Sava, and Tem captures substitute a named recruited Jedi into the first roster slot for repeatable visual inspection.

## Performance

| View | Before draws / tris | After draws / tris | Change |
| --- | ---: | ---: | ---: |
| 844 × 390 Compatibility/Low, Kira Mk II | [113 / 26,201](../../shots/wave16-armory-before-phone-low-u1-mk2.png) | [117 / 19,602](../../shots/wave16-armory-after-phone-low-u1-mk2.png) | +3.5% / −25.2% |
| 1366 × 768 Forward+/High, Kira Mk II | [153 / 47,632](../../shots/wave16-armory-before-desktop-high-u1-mk2.png) | [161 / 34,866](../../shots/wave16-armory-after-desktop-high-u1-mk2.png) | +5.2% / −26.8% |
| 844 × 390 Compatibility/Low, armored trooper | [110 / 24,385](../../shots/wave16-armory-before-phone-low-u3-mk2.png) | [113 / 25,085](../../shots/wave16-armory-after-phone-low-u3-mk2.png) | +2.7% / +2.9% |
| 1366 × 768 Forward+/High, armored trooper | [154 / 44,346](../../shots/wave16-armory-before-desktop-high-u3-mk2.png) | [160 / 46,178](../../shots/wave16-armory-after-desktop-high-u3-mk2.png) | +3.9% / +4.1% |

Both Low views stay under the +15% draw and +20% triangle ceilings. Low adds no post effect. Source GLBs and PNGs total 1,140,281 bytes; their imported cache totals 539,276 bytes, together below the +3 MB web pack allowance. Xvfb software-rendered FPS samples vary with concurrent host load; the 60 FPS phone target needs a device run.

## Gate

- Final headless import: exit 0; [log](import.log).
- `armory16_test`: 155 checks, 0 failures; `armory15_test`: 50 checks, 0 failures; `armory13_test`: 253 checks, 0 failures.
- Full `./godot/test.sh`: exit 0; 62 zero-failure lines, 0 `SCRIPT ERROR`, 0 `ERROR:` or nonzero failure matches; Normal rescue **9/20**. [Log](test.log).
- `git diff --check`: clean.

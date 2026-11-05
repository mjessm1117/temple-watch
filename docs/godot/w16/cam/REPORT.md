# Wave 16 `cam` report

## Goals

| Goal | Result | Evidence |
| --- | --- | --- |
| Grounded 3/4 tactical camera | PASS | Opens at 53° pitch and 45° yaw; phone framing keeps all four squad members and nearby cover above the action HUD. Q/E still rotates 90°. Zooming to 44 moves to a 78° overhead view, and zooming back restores the tactical pitch. [Phone before](../../shots/wave16-cam-before-phone-low-temple-tactical.png) → [after](../../shots/wave16-cam-after-phone-low-temple-tactical.png); [desktop before](../../shots/wave16-cam-before-desktop-high-temple-tactical.png) → [after](../../shots/wave16-cam-after-desktop-high-temple-tactical.png); [phone overhead](../../shots/wave16-cam-after-phone-low-temple-overhead.png), [desktop overhead](../../shots/wave16-cam-after-desktop-high-temple-overhead.png). |
| Aim and impact light | PASS | Low uses one shadowless aim omni and a rim material on shooter and target, with no DOF or new post process. Medium/High use key and rim lights, a soft key shadow and existing far DOF. [Phone aim before](../../shots/wave16-cam-before-phone-low-temple-aim.png) → [after](../../shots/wave16-cam-after-phone-low-temple-aim.png); [desktop aim before](../../shots/wave16-cam-before-desktop-high-temple-aim.png) → [after](../../shots/wave16-cam-after-desktop-high-temple-aim.png). |
| Jedi kill close-up | PASS | A named Jedi killing blow replays `swing` in a 0.64 s close-up, then returns to the tactical view. Cinematics Off suppresses it; skipping restores the camera. Actual Kira Venn strike: [phone 3-frame strip](../../shots/wave16-cam-after-phone-low-temple-kill-strip.png), [desktop 3-frame strip](../../shots/wave16-cam-after-desktop-high-temple-kill-strip.png). |

All linked captures are native 844×390 Compatibility/Low or 1366×768 Forward+/High framebuffer PNGs. Each was opened and visually inspected.

## Render counters

| View | Low draws before → after | Low triangles before → after |
| --- | ---: | ---: |
| Phone tactical | 75 → 74 | 99,170 → 100,026 |
| Phone aim | 96 → 95 | 63,889 → 63,833 |
| Phone overhead | — → 85 | — → 109,160 |
| Phone Jedi kill, frames 1/2/3 | — → 45/45/43 | — → 47,931/62,205/62,193 |

The matching High tactical view measured 120 → 123 draws and 211,634 → 217,710 triangles. High aim measured 99 → 162 draws and 133,361 → 417,875 triangles; the added shadow pass accounts for much of this increase. Low tactical and aim stay within the +15% draw and +20% triangle limits. No new binary game assets were added. The Low 60 fps target still needs a physical phone measurement; software-renderer captures are not that measurement.

## Gate

Pending final full-suite result.

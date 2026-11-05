# Wave 13 armory report

## Player-visible changes

- Every loadout slot now has a baked gear image. Armor images are cropped renders of the existing Jedi and trooper GLBs; saber, blaster, kit, modules, crystal, form and path use a Godot SubViewport bake of the gear shapes already represented by the game. The PNGs load as ordinary textures, so no viewport renders at runtime.
- Slot names fit at phone and desktop sizes. The form tile shows the full **Shii-Cho** name; its tooltip retains **Shii-Cho (Form I)**. Each card shows a readable Mk label and three tier pips. Mk II and III get stronger cyan and gold colors.
- The inspected hero has a warm key, cyan rim and floor pool on Medium/High. Low keeps its prior light count and post settings.
- Title, graphics settings, research and forge now use the same dark translucent panel, thin accent border and button states as the armory. The shared style helper only applies to these screens.

## Captures

| Size | Before | After |
| --- | --- | --- |
| 844×390 | [phone before](../../shots/wave13-armory-before-phone.png) | [phone after](../../shots/wave13-armory-after-phone.png) |
| 1366×768 | [desktop before](../../shots/wave13-armory-before-desktop.png) | [desktop after](../../shots/wave13-armory-after-desktop.png) |

Also: [phone upgrade picker](../../shots/wave13-armory-after-phone-upgrade.png), [Low phone](../../shots/wave13-armory-low-phone.png), [title desktop](../../shots/wave13-armory-menu-desktop.png), [title phone](../../shots/wave13-armory-menu-phone.png).

## Performance and verification

| Capture | Draw calls | Rendered primitives / approximate triangles | FPS sample |
| --- | ---: | ---: | ---: |
| Low 844×390 | 77 | 22,279 | 23 |
| High 844×390 | 113 | 41,086 | 64 |
| High 1366×768 | 141 | 42,794 | 26 |

These are Godot frame monitors in an Xvfb window on this machine. The FPS values vary under concurrent tests and are **not a phone forecast**. Low's estimated frame rate from this sample is 23 fps in Xvfb; actual device profiling remains necessary. The Low scene adds zero lights, zero floor geometry and zero post effects compared with Wave 12. Static PNGs replace the previous SVG slot textures. No GLBs or gameplay settings changed.

- Import: [final import log](import-final.log), exit 0.
- New `armory13` suite: 92 checks, 0 failures; checks both sizes, all slot art and text bounds, Mk II/III markers, the showroom and Low light count.
- Full [`./godot/test.sh`](test.log): exit 0; every suite reports 0 failures; 0 `SCRIPT ERROR` lines; Normal rescue 9/20, inside the required 9–11/20 band.
- `git diff --check`: clean.

## Remaining gaps vs XCOM 2

The equipment art is compact and stylized; XCOM 2 has larger, highly detailed weapon renders and material previews. The hero still has a simple hangar backdrop and limited gear variation on the body. The phone inspector uses scrolling to retain 44 px touch targets. There are no cross-lane requests from this work.

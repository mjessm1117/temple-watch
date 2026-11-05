# Wave 13 armory fix (lane tw-w13-armory2)

Same worktree, branch `w13/armory`, on top of b25ca75. Same rules and file lease as `/home/jess/projects/tw-w13/WAVE13.md` (armory lane). Commit locally only; never push. Do the work yourself, with no subagents.

## Problems found in review of `docs/godot/shots/wave13-armory-after-phone.png` (844x390)
1. **The Mk line is clipped on every slot card.** "Mk II" and "Mk I" and the tier pips are cut off at the bottom edge of the card, and only the top half of the text shows. This is exactly the gap the spec told this lane to fix. The `armory13` suite passed anyway, so its text-bounds check is not testing what is on screen.
2. **The gear art is too small.** The icons are about 20 px on phone and about 24 px on desktop, while the panel has about 70 px of empty space below the slot grid on phone. Use that space:
   - make the cards taller;
   - make the icons at least 40 px tall on phone and 48 px on desktop;
   - make sure the Mk label and its pips sit fully inside the card.

## Output
- Fix both problems at 844x390 and 1366x768. Keep 44 px touch targets and the "Shii-Cho" fix.
- **Fix the `armory13` test** so it fails on the old clipping. It must check that each Mk label's global rect lies fully inside its card's global rect after layout, at both sizes. Then make it pass.
- Recapture the after shots with the same names, overwriting them.
- Run the full gate from WAVE13.md:
  - headless import first;
  - `./godot/test.sh` exits 0, with 0 SCRIPT ERROR lines, every suite at 0 failures, and Normal rescue at 9-11/20;
  - `git diff --check` is clean.
- Update REPORT.md. Commit.

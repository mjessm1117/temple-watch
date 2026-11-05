# Wave 14 integrate fix pass (tw-w14-intfix)

Worktree `/home/jess/projects/tw-w14/integrate`, branch `w14/integrate`. All 4 lanes are merged here (battle, map, home, story). Hard rules from `/home/jess/projects/tw-w14/WAVE14.md` apply:
- Do the work yourself; no subagents.
- Commit locally only; never push.
- No Meshy credits.
- Never commit anything from /home/jess/projects/tw-reference.

FIRST: `/home/jess/projects/.tools/godot/godot --headless --path godot --import` (new worktree, needed before any test).

## File lease
- battle camera/framing: `godot/scripts/battle11_camera.gd` and the phone tactical camera code it uses, plus battle14 test/capture;
- `godot/scripts/story14_bake.gd`, `godot/assets/story/portraits14/*.png`, story14 test;
- `CLAUDE.md` at the repo root;
- `godot/test.sh` only to add lines;
- shots/logs under `docs/godot/w14/intfix/`.

## Fixes
1. **Phone tactical framing (844x390, battle start and after selecting a unit).** The squad currently sits tiny in the top-left with lots of empty floor. Centre the camera on the selected unit (or the squad centroid at mission start), with nearby enemies or cover in frame. The selected unit should be at least ~45 px tall, clear of the top HUD and bottom action bar. Desktop framing must not regress. Add a battle14 check: on phone, the selected unit's screen position is inside the middle 60% of the screen and its height is at least 40 px.
2. **Villain portraits look identical.** bane, kaan and malgus are the same red armoured body with the same pose. Give each villain a different base model or silhouette, using only existing GLBs (for example heavy armour, hooded robe and officer), plus a different pose/angle and a distinct accent. They keep the red/black low-key palette.
   - The white-trooper group (bo, bren, dace, grak, halden, ilo, jace, rhal, varra) reads as one trooper recoloured. Use the free levers more strongly: camera angle (3/4 left vs right, profile), crop (head-and-shoulders vs waist-up), helmet tint and shoulder colour.
   - The Council should show 2–3 hologram silhouettes, not one.
   - Data-driven only. Keep the md5-unique test.
   - Rebuild `docs/godot/w14/intfix/portraits-sheet.png` and LOOK at it at phone size.
3. **Refresh the root `CLAUDE.md` for the Godot game.** Make it a small, surgical rewrite.
   - Drop the old web-game layout, Cloudflare-deploy-on-push, desktop-first and Coordinator text. Mention that the old web game in `public/` is frozen, and that `npm test` still guards it before a push.
   - Add the following:
     - the Godot 4.7.2 project in `godot/`, with its binary path;
     - phone first: 844x390, Compatibility/Low, 60fps target, mobile poly budgets;
     - the gate: headless import, then `./godot/test.sh` exits 0 with 0 SCRIPT ERROR, 0 failures in every suite and Normal rescue 9–11/20, then `git diff --check`;
     - web export: `tools/web/export_web.sh` → GitHub Pages site temple-watch-play;
     - release model: ship once per wave and tag `last-good`;
     - never commit XCOM 2 reference images (the repo is public);
     - files under ~600 lines.
   - Keep the "Working with Jess" section.
   - Under 80 lines.

## Gate
- headless import;
- `./godot/test.sh` exits 0, with 0 SCRIPT ERROR, 0 failures in every suite and Normal rescue 9–11/20;
- `git diff --check` is clean.

Then recapture into `docs/godot/w14/intfix/` and LOOK at each shot:
- phone tactical at battle start;
- phone tactical after selecting a second unit;
- desktop tactical;
- the portrait sheet.

Commit.

## Output
Final message:
- PASS/FAIL for items 1–3;
- the selected unit's px height and screen position on phone;
- the unique portrait count;
- the shot paths;
- the gate numbers.

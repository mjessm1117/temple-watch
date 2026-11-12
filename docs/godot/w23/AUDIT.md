# W23 Look / Graphics Audit (READ-ONLY)

Owner: temple-watch. Jess picked W23 = Look / graphics (ask-43c77f19).
Goal: rank the biggest visual gaps vs XCOM 2 on PHONE and PC, then propose 3-5 fix lanes with disjoint file leases. No code changes.

## Setup
- Worktree: /home/jess/projects/tw-w23/audit on new branch w23/audit off main b8a8bde.
- Same setup as docs/godot/w22/COMMON.md "Setup" (rsync untracked godot/assets + addons, then `godot --headless --import`). Godot: /home/jess/projects/.tools/godot/godot.
- Do NOT edit tracked game files. Capture scripts may live in tw-logs/w23/audit/tools/ (outside the repo).
- Outputs go ONLY to /home/jess/projects/tw-logs/w23/audit/.

## Read first
- tw-reference/W22-GAPS.md and W20-GAPS.md (open visual gaps), tw-reference/*.jpg (XCOM 2 refs; private, never copy into repo).
- docs/godot/RENDER-UPGRADE.md, graphics tiers code (graphics_options.gd and the tier hooks), docs/godot/w20 art20 notes.

## Steps
1. Capture inventory, landscape 1280x720 AND portrait 390x844, Low and High tier:
   battle (gate defense map + 2 other themes: overview, unit close, aim view, kill cam, enemy turn), Temple hub + 2 rooms, galaxy map, armory/squad, opening story page, debrief.
2. Battle map look: terrain materials/texture detail, tiling, edges, cover props (blockiness, scale, variety), lighting (key/fill/rim, shadows, fog, time-of-day mood per theme), color grading, ambient life (dust, particles, banners, foliage motion).
3. Units: Jedi + soldier + enemy models at play-camera distance: readability, silhouette, materials, idle/run/shoot anim quality, saber glow, team color, LOD pops.
4. VFX: blaster bolts, saber hits, Force effects, blasts, smoke, impact decals vs XCOM 2.
5. UI art: HUD skin, fonts, icons, panels, portraits, consistency across battle/Temple/galaxy/menus (one visual language or several?).
6. Temple + galaxy: depth, lighting, set dressing vs Avenger / Geoscape refs.
7. Phone performance per tier: fps, frame ms, draw calls, triangles, texture memory, pck size impact. Budget: 60fps target on Compatibility/GLES3, mobile poly counts + LODs. Flag anything over budget.
8. Asset source plan per gap: shader/lighting (free), Blender pass (free), CC0 libraries (Poly Haven/ambientCG/Kenney/Quaternius, list licence), or Meshy (quote credits per piece; DO NOT spend, DO NOT call the Meshy API).

## Output
- AUDIT-REPORT.md (<200 lines):
  - Top 15 visual gaps ranked by player impact, each: where, screenshot file, XCOM 2 ref file, cause (file:line or asset path), fix idea, source (free/CC0/Meshy+credits), phone perf risk.
  - Perf table per tier (landscape + portrait).
  - Proposed 3-5 lanes with DISJOINT write leases (exact file/asset-dir lists), one test name each (`<lane>23_test.gd`), and which gaps each fixes. Shared files go to one lane; others get guarded hooks.
  - Meshy quote total (if any) as a separate optional line.
- 2026-11-10-look-audit-sheet.jpg: one JPG, 4-6 panels, ours vs XCOM 2 ref side by side (sheet lives in tw-logs only, never the repo).
- Final message: top 5 gaps, lane split, Meshy quote, sheet path.

## Boundaries
- Read-only for the repo. No commits, no pushes, no Meshy calls, no deletes of untracked files, no `git stash -u` / `git clean`.
- Never print MESHY_KEY. Never copy XCOM 2 images into the repo.

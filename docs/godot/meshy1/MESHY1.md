# Meshy batch 1: art-director loop on two map assets (Godot game)
Jess (11-02): "can you drive meshy like my claude has done in the past?" Key is live. Follow /home/jess/hive/skills/meshy-art-director/SKILL.md exactly (read it first).
Key: load with `set -a; . /home/jess/hive/.env; set +a` → env MESHY_KEY. NEVER print, echo, log or write the key anywhere. Do not `cat` .env.

Work on branch meshy/batch1 in this worktree. Godot 4.7.2 at /home/jess/projects/.tools/godot/godot; run `godot --headless --editor --import --quit` in godot/ first.

HARD BUDGET: 200 credits total for this batch. Check balance before and after with GET https://api.meshy.ai/openapi/v1/balance (log numbers only). Stop immediately if the next call would exceed 200 spent. Max 8 previews + 2 refines. No rigging.

Assets (both seen at the default battle camera, ~25 units away, plus action cam close-ups):
1. `obj_terminal` — mission objective data terminal / console (hack/relay objectives). Must read instantly as "the thing to interact with": chunky standing console, angled screen, cable bundle, emissive screen area. Budget ~4K tris after simplify.
2. `cover_half_temple` — half-cover barricade for temple/ruins themes: fallen carved column + stone blocks, 1 tile wide, 0.7–0.9 tall in game units. Budget ~3K tris.
Style anchor: the existing GLBs in godot/assets/maps and the wave9 screenshots (docs/godot/shots/wave9-*.png). Stylized, chunky, readable silhouette, matte (not glossy). Original designs only, Star Wars-inspired, no XCOM or Lucasfilm assets or names.

Loop per asset:
1. Brief → art/briefs/<asset>.md (what, camera distance, poly budget, style anchors, NOT-list).
2. Add a preview-only mode to tools/meshy/gen.mjs (e.g. `--preview-only` writes `<asset>.<letter>.preview.glb`) and a refine-by-preview-id mode. Reuse existing code; keep file small.
3. 3–4 previews per asset from different prompt angles (silhouette words / material words / era words). Letters A–D.
4. Render every preview to PNG (Godot headless/real-window capture is fine) and actually look. Score 1–5 on silhouette at game distance, style match, cleanliness, polycount fit. Write scores in art/LOG.md.
5. Refine only the winner per asset (texture prompt, enable_pbr false). Simplify/fit with tools/meshy/prop.mjs or Godot import LOD to the budget.
6. Integrate as NEW files with a suffix (godot/assets/maps/meshy1/<asset>_v1.glb); never overwrite shipped models. Wire: terminal objective model and temple/ruins half cover use the new GLB, behind a single data switch in themes.json/props.json so it can be reverted in one line. No rule/walk/cover/LOS change. Record provenance in godot/assets/maps/provenance.json (Meshy, task ids).
7. Screenshots at 1920x1080 real window, HUD visible, same camera: docs/godot/shots/meshy1-<asset>-before.png and -after.png, plus a contact sheet docs/godot/shots/meshy1-previews.png showing all previews labeled A–D with scores.
8. Log in art/LOG.md: asset, letter, task ids, credits spent (balance before/after), verdict. Losers stay on disk labeled (art/meshy1/, gitignored if >5MB total; else commit).

Gates: ./godot/test.sh exits 0, no failures, no SCRIPT ERROR. Files < 600 lines. Commit locally on meshy/batch1. No push, no subagents. Web game (public/, functions/, tests/, worker.js) frozen.

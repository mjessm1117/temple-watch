# Task: Temple Watch Tooling Lane (tw-tooling-checks)
# Jess ask-0cde197d, cortana spec 2026-11-10-temple-watch-checks-spec.md

## Goal
Add screenshot-and-critique loop + code checks to the Temple Watch repo.
Five deliverables, committed one at a time, progress.txt updated after each.
NO gameplay or balance changes. NO system packages (ask House if one is needed).

## Context
- Repo: /home/jess/projects/temple-watch
- Godot binary: /home/jess/projects/.tools/godot/godot (4.7.2)
- Web game: tools/inline.js build, 20 node tests in `npm test`, devDep = jsdom only
- Godot port: godot/ directory, tests in godot/tests/, run via ./godot/test.sh
- godot_ai addon: at repo root /addons/godot_ai/ — WRONG location (needs godot/addons/)
- uv: NOT installed (flag in progress.txt; use pip for gdtoolkit instead)

## Output
Create progress.txt in the project root. Update it after every commit.
Format: one line per item — DONE/IN_PROGRESS/BLOCKED + brief note.

## Boundaries
- Files: tests/, tools/, addons/, godot/addons/, godot/tests/, package.json, biome.json, .github/workflows/, godot/project.godot, progress.txt
- Do NOT edit any .gd gameplay files, scenes, or assets
- Do NOT modify godot/test.sh (only ADD a new gate script if needed)
- Max file size 600 lines

---

## Step 1 — Move godot_ai addon + live screenshot

1. Create `godot/addons/` directory.
2. Copy `/addons/godot_ai/` → `godot/addons/godot_ai/` (rsync or cp -r).
3. In `godot/project.godot`, under `[editor_plugins]`, add `enabled="res://addons/godot_ai/plugin.cfg"` if the section exists, or create it. Read the file first to see the existing format.
4. Take a headless screenshot of the main battle scene:
   ```
   /home/jess/projects/.tools/godot/godot --headless --path godot/ --quit-after 300 \
     --script tools/screenshot_scene.gd 2>&1 | tail -20
   ```
   Write `tools/screenshot_scene.gd` to load the main battle scene and save a PNG to `/home/jess/projects/tw-logs/tooling/battle-engine.png`:
   ```gdscript
   extends SceneTree
   func _initialize():
       var vp = get_root()
       vp.size = Vector2i(844, 390)
       # load main battle scene
       var scene_path = "res://godot/scenes/battle/battle_map.tscn"
       if not ResourceLoader.exists(scene_path):
           # fallback: find any .tscn in scenes/
           scene_path = "res://godot/scenes/main.tscn"
       var scene = load(scene_path)
       if scene:
           var node = scene.instantiate()
           get_root().add_child(node)
           await get_tree().create_timer(2.0).timeout
           var img = vp.get_texture().get_image()
           img.save_png("/home/jess/projects/tw-logs/tooling/battle-engine.png")
           print("SCREENSHOT SAVED")
       quit()
   ```
   If the scene path isn't right, check godot/scenes/ for the battle scene filename first.
   Ensure /home/jess/projects/tw-logs/tooling/ exists (mkdir -p).
5. Verify the PNG exists and is > 10KB. If the headless renderer can't save a viewport PNG (common with Compatibility renderer), use:
   ```
   /home/jess/projects/.tools/godot/godot --headless --path godot/ --take-screenshot /home/jess/projects/tw-logs/tooling/battle-engine.png --quit-after 180
   ```
   Or export a frame via the existing gate runner pattern if neither works — document whatever method succeeds.
6. Commit: "tooling: move godot_ai to godot/addons/ + headless screenshot tool"
7. Update progress.txt: `DONE step1 — addon moved, battle-engine.png at tw-logs/tooling/`

---

## Step 2 — Web visual baselines (Playwright)

1. Install Playwright as a devDependency:
   ```
   npm install --save-dev @playwright/test
   npx playwright install chromium
   ```
2. Create `tests/visual/playwright.config.js`:
   - baseURL: `http://localhost:3000` (or the port the web game serves on)
   - Use `webServer` to start the dev server if needed (check package.json scripts for a serve command)
   - viewport: iPhone (`{ width: 390, height: 844 }`) and desktop (`{ width: 1280, height: 800 }`)
3. Create `tests/visual/baseline.spec.js` — screenshot 5 screens:
   - title screen (default landing)
   - map screen
   - battle screen
   - armory screen
   - campaign screen
   Navigate to each URL or interaction path that shows those screens.
   On first run, save baselines to `tests/visual/screenshots/baseline/`.
4. Add a diff step: if a screenshot differs from baseline by >2% pixels (using `expect(page).toHaveScreenshot({ maxDiffPixelRatio: 0.02 })`), the test fails.
5. Add `"test:visual": "playwright test"` to package.json scripts.
6. Run the visual test once to generate baselines: `npm run test:visual -- --update-snapshots`
7. Run again without update flag to confirm it passes: `npm run test:visual`
8. Commit: "tooling: Playwright visual baselines (5 screens, 390+1280px)"
9. Update progress.txt.

---

## Step 3 — Code checks (Biome + gdtoolkit)

### Web: Biome + TypeScript checkJs

1. Install Biome: `npm install --save-dev @biomejs/biome`
2. Init config: `npx @biomejs/biome init` → creates `biome.json`
3. Edit `biome.json`:
   - Set `linter.enabled: true`, `formatter.enabled: true`
   - Include `["tools/**/*.js", "tests/**/*.js"]`
   - Ignore `node_modules`, `build/`
4. Run `npx @biomejs/biome check --diagnostic-level=warn tools/ tests/ 2>&1 | tail -20` to see baseline warning count. Write that count to `tools/lint-baseline.json` as `{"biome_warnings": N}`.
5. Add `tsconfig.json` with `checkJs: true` and `allowJs: true` targeting `tools/*.js`. Run `npx tsc --noEmit 2>&1 | wc -l` for baseline TS error count → store in lint-baseline.json as `ts_errors: N`.
6. Add npm scripts:
   - `"lint": "biome check tools/ tests/"`
   - `"typecheck": "tsc --noEmit"`
7. Add a gate assertion in a new `tests/lint_gate.test.js` using node:test:
   ```js
   // lint counts must only go down
   import { readFileSync } from 'fs'
   const baseline = JSON.parse(readFileSync('tools/lint-baseline.json'))
   // actual counts are computed via child_process.execSync
   // test passes if current <= baseline
   ```
8. Commit: "tooling: Biome + checkJs lint gate (baseline counts in tools/lint-baseline.json)"

### Godot: gdtoolkit

1. Install gdtoolkit via pip3: `pip3 install gdtoolkit`
   If pip3 is not available, install via `python3 -m pip install gdtoolkit`.
   If this fails and system pip is blocked, use `python3 -m pip install --user gdtoolkit`.
2. Run baseline lint on all GD files:
   ```
   gdlint godot/ 2>&1 | grep -c "^E" || echo 0
   ```
   Store in `tools/lint-baseline.json` as `gdlint_errors: N`.
3. Run format check (dry run, no changes):
   ```
   gdformat --check godot/ 2>&1 | tail -20
   ```
   Store unformatted file count in `tools/lint-baseline.json` as `gdformat_unformatted: N`.
4. Add a shell script `tools/lint_godot.sh`:
   ```sh
   #!/bin/bash
   set -e
   ERRORS=$(gdlint godot/ 2>&1 | grep -c "^E" || echo 0)
   BASELINE=$(python3 -c "import json; print(json.load(open('tools/lint-baseline.json'))['gdlint_errors'])")
   if [ "$ERRORS" -gt "$BASELINE" ]; then
     echo "FAIL: gdlint errors $ERRORS > baseline $BASELINE"; exit 1
   fi
   echo "PASS: gdlint $ERRORS errors (<= baseline $BASELINE)"
   ```
   Make it executable.
5. Commit: "tooling: gdtoolkit lint gate (baseline in lint-baseline.json)"
6. Update progress.txt.

---

## Step 4 — gdUnit4 headless runner

1. Check if gdUnit4 is already in the project: `ls godot/addons/gdUnit4/ 2>/dev/null`
   If missing: download the latest stable gdUnit4 release ZIP from GitHub (gdUnit4 plugin), extract `addons/gdUnit4/` into `godot/addons/gdUnit4/`.
   The repo is https://github.com/MikeSchulze/gdUnit4 — find the latest release tag.
2. Enable the plugin: in `godot/project.godot` add `"res://addons/gdUnit4/plugin.cfg"` to `editor_plugins.enabled` (same pattern as godot_ai).
3. Import the project headless to register the new addon:
   `/home/jess/projects/.tools/godot/godot --headless --path godot/ --import --quit-after 180`
4. Port 2 existing test files. Look at the existing `godot/tests/` files for patterns. Create:
   - `godot/tests/unit/battle_unit_test.gd` — port 2 assertions from one existing test suite
   - `godot/tests/unit/class_system_test.gd` — port 2 assertions from another
   Each file: `extends GdUnitTestSuite`, methods named `test_*`.
5. Run gdUnit4 headless:
   ```
   /home/jess/projects/.tools/godot/godot --headless --path godot/ \
     -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
     --add "res://tests/unit/" --continue 2>&1 | tail -30
   ```
   Confirm exit 0 and both test methods pass.
6. Add a `tools/run_gdunit4.sh` script that wraps the above command.
7. Commit: "tooling: gdUnit4 headless runner + 2 ported tests"
8. Update progress.txt.

---

## Step 5 — Critique step (pre-wave gate hook)

1. Create `tools/critique.sh`:
   ```sh
   #!/bin/bash
   # Usage: ./tools/critique.sh <screenshot.png> [<screenshot2.png> ...]
   # Sends screenshots to a fresh Claude run with the grading rubric
   RUBRIC="tools/critique-rubric.md"
   SCREENSHOTS="$@"
   echo "Running critique on: $SCREENSHOTS"
   claude -p "$(cat $RUBRIC)" --image $SCREENSHOTS 2>&1
   ```
2. Create `tools/critique-rubric.md` with the PASS/FAIL checklist:
   ```markdown
   # Temple Watch Visual Critique Rubric

   Grade each attached screenshot. Output: one line per criterion, format: PASS/FAIL — [criterion] — [one sentence observation].

   Criteria:
   1. Unit readability — can you distinguish individual units at a glance at battle distance?
   2. Battlefield readability — is the map/grid clear, with visible cover and elevation?
   3. Holo war-table aesthetic — does the visual feel like a holographic tactical display (blue/teal glows, clean geometric overlays)?
   4. Visual hierarchy — do the most important elements (selected unit, targets, action bar) draw the eye first?
   5. Tap targets — do all visible buttons appear to be at least 44px tall?
   6. Contrast — does text on any background panel pass readable contrast (not washed out)?
   7. iPhone touch-drag — are scrollable areas marked with visible scroll indicators, and do action areas avoid the bottom safe zone?
   8. XCOM feel — does the overall layout feel like a mobile XCOM 2 screen, not a web game?

   For any FAIL: add one sentence on what specifically to fix.
   ```
3. Run the critique on the battle-engine.png from Step 1:
   ```
   ./tools/critique.sh /home/jess/projects/tw-logs/tooling/battle-engine.png 2>&1
   ```
   Save the output to `/home/jess/projects/tw-logs/tooling/critique-sample.txt`.
4. If any FAIL items appear: pick the easiest visual fix (e.g. contrast, overlay opacity), make ONE targeted change to the relevant .gd or .tscn UI file, re-run the headless screenshot, re-run the critique, confirm that item flips to PASS. Save the before/after as `critique-before.png` and `critique-after.png` in tw-logs/tooling/.
   - If no FAIL items appear: introduce a deliberate test failure (e.g. temporarily reduce a UI element's alpha to 0.1), screenshot it, run critique (should get a FAIL), restore the fix, screenshot again, confirm PASS. This proves the loop works.
5. Add a note to `tools/critique-rubric.md` documenting the one caught FAIL and fix.
6. Commit: "tooling: critique shell script + rubric + sample run with before/after"
7. Update progress.txt: `DONE step5 — critique loop working, before/after at tw-logs/tooling/`

---

## Final check

After all 5 steps are committed:
1. Run `npm test` (all 20 node tests + lint gate + visual baselines) → confirm exit 0
2. Run `./godot/test.sh` from the project root → confirm exit 0, 0 FAIL, 0 SCRIPT ERROR
3. Run `./tools/run_gdunit4.sh` → confirm exit 0
4. Run `./tools/lint_godot.sh` → confirm PASS
5. Print lint-baseline.json contents to progress.txt
6. Update progress.txt: `ALL DONE — npm test exit 0, test.sh exit 0, gdunit4 exit 0, lint PASS`

## Note on uv / godot-ai MCP
- uv is NOT installed on this machine. The godot_ai addon has been moved to godot/addons/ (Step 1), but the MCP server (tools/mcp/bin/godot-ai) needs uv to start. The addon is wired; the MCP is waiting for House to install uv.
- Document this in progress.txt as: `BLOCKED uv-mcp — addon wired, MCP server needs uv (House installing)`

# Graphics tiers: performance A/B check

## Why
REPORT.md shows High at 25 fps avg (62.8 ms p95 frame) on an RTX 4090 under Xvfb. Wave 9 measured ~245 fps (9.1 ms p95) on the same machine. We need to know whether the tiers code slowed the game down or whether the test setup did.

## Do
1. Make a temporary worktree of the base commit 7c682bd (`git worktree add /tmp/tw-perf-base 7c682bd`). Copy in only the measurement harness (godot/tests/graphics-render.sh plus whatever capture script it needs, with the tier-setting calls removed) so the base runs today's code unchanged.
2. Run the identical measurement (same map `cache`, seed 17, 1366×768, VSync off, same warmup and frame count, same display/GPU env vars) on:
   a. base 7c682bd
   b. gfx/tiers on High
   c. gfx/tiers on Low
   Run each one 3 times and take the median. Also run (a) and (b) once with the same method wave 9 used (see docs/godot/wave9/ and its perf test), so the numbers can be compared with 245 fps.
3. If (b) is more than 10% slower than (a) on avg fps or p95 frame time, find the cause in the tiers code and fix it. High must stay pixel-identical to today. Re-measure.
4. If the gap is only the harness (a ≈ b), say so plainly and fix the harness so it reports realistic numbers if possible.
5. Append a "Performance A/B" section to docs/godot/tiers/REPORT.md with a table (base / High / Low: avg fps, p95 ms, draws, primitives), the cause, and the verdict.
6. `./godot/test.sh` exit 0, 0 SCRIPT ERROR, all suites 0 failures, Normal 10/20. Commit on gfx/tiers. Don't push. Remove the /tmp worktree when done (`git worktree remove`).

## File lease
Same as TIERS.md (graphics_*.gd, map_presentation.gd, combat_scene.gd graphics hooks, godot/tests/graphics*, godot/test.sh, docs/godot/tiers/**). Do NOT touch props.json, meshy assets, art/, tools/meshy/, maps, balance, or web files. If the cause is outside the lease, describe it in REPORT.md and stop.

# W26 Integrate Fix 3 — threat24_test 1 failure (ENTRY vs INBOUND)

## Context
- Working directory: /home/jess/projects/temple-watch-w26-integrate (w26/integrate branch)
- fix1+fix2 changes are UNCOMMITTED in the worktree: hud_phone_layout.gd, decision22_test.gd. Keep them.
- main/last-good/play site are still W25 (ce62160). Do NOT touch them.

## Remaining failure (from /home/jess/projects/tw-logs/w26/fix2/gate.log line 851)
```
THREAT24: 35 checks, 1 failures
```

## Diagnosed cause
threat24_test.gd:91 asserts:
```
marker.wave_label.text.contains("ENTRY") and marker.wave_label.text.contains(str(wave.count)) and marker.wave_label.text.contains(str(wave.turns))
```

But reinforcement_marker.gd (changed in W26 gate lane) now formats the label as:
- `arrow + " INBOUND"` (when no matching wave found)
- `"%s %d in %dT" % [arrow, count, turns]` (when a matching wave found)

The old "ENTRY" string no longer exists. The W26 change is intentional — the marker now shows "3 in 2T" format which is more readable. The test assertion needs to match the new format.

## Fix
In threat24_test.gd:91, replace the "ENTRY" check with a check that the text contains the count and turns in the new format.

The new format when a wave is found: `"%s %d in %dT"` — this always contains:
- The count as a decimal number  
- "in" (as a word)
- The turns followed by "T"

The simplest correct assertion:
```gdscript
check(marker.visible and not marker.wave_label.text.contains("INBOUND") and marker.wave_label.text.contains(str(wave.count)) and marker.wave_label.text.contains(str(wave.turns)), "entry marker shows count and turn")
```

Or even simpler — just check that it's visible and contains the count and turns (the core behavior the test cares about):
```gdscript
check(marker.visible and marker.wave_label.text.contains(str(wave.count)) and marker.wave_label.text.contains(str(wave.turns)), "entry marker shows count and turn")
```

Pick whichever is cleaner. The test name "entry marker shows count and turn" is still valid — that's what the check verifies.

## Steps

### Step 1: Read the test file
Read godot/tests/threat24_test.gd lines 85-100 to confirm the exact assertion text and context.

### Step 2: Apply the fix
Edit threat24_test.gd:91 to remove `text.contains("ENTRY")` and keep the count/turn checks. The test must still verify the core behavior: when a wave matches a tile, the marker shows the wave's count and turns.

### Step 3: Run focused threat24 test
```
mkdir -p /home/jess/projects/tw-logs/w26/fix3
xvfb-run -a /home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility --resolution 844x390 -s tests/threat24_test.gd -- --graphics=low 2>&1 | tee /home/jess/projects/tw-logs/w26/fix3/threat24.log
grep 'THREAT24:'  /home/jess/projects/tw-logs/w26/fix3/threat24.log
```
Target: `THREAT24: 35 checks, 0 failures`

### Step 4: Full gate
```
bash godot/test.sh > /home/jess/projects/tw-logs/w26/fix3/gate.log 2>&1
```
Parse: total failures = 0, SCRIPT ERRORs = 0.

### Step 5: Commit ALL fix1+fix2+fix3 changes together if gate is green
Stage exactly: godot/scripts/hud_phone_layout.gd, godot/tests/decision22_test.gd, godot/tests/threat24_test.gd
Restore the shot PNGs (they should not be staged):
```
git restore -- docs/godot/shots/wave16-cam-after-phone-low-temple-aim.png docs/godot/shots/wave16-cam-after-phone-low-temple-tactical.png
git add godot/scripts/hud_phone_layout.gd godot/tests/decision22_test.gd godot/tests/threat24_test.gd
git commit -m "Fix test assertions for W26 HUD and reinforcement marker changes

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git log --oneline -1
```

Report: the commit SHA, the focused test result, and the gate result.

## Boundaries
- Only change threat24_test.gd (and the already-modified hud_phone_layout.gd, decision22_test.gd).
- The fix MUST verify behavior, not just delete the failing check. Keep the count + turns assertions.
- If the full gate still has failures after this fix: report them. Do NOT loop or speculate — report exactly what failed.

# W26 Integrate Fix 2 — decision22 portrait chip (1 remaining failure)

## Context
- Working directory: /home/jess/projects/temple-watch-w26-integrate (w26/integrate branch)
- Fix1 changes are UNCOMMITTED in the worktree: hud_phone_layout.gd, decision22_test.gd
  These are good fixes — keep them. Build on top of them.
- main/last-good/play site are still W25 (ce62160). Do NOT touch them.

## Remaining failure (from /home/jess/projects/tw-logs/w26/fix1/gate.log line 551)
```
ERROR: D threat chip is two readable lines at (390, 844)
  decision22_test.gd:75 (layout_check)
```
The 844×390 landscape run passed. Only the 390×844 portrait run fails.

## Root cause
Portrait mode is 390px wide (vs 844px landscape). The D threat chip's text — probably something like "D: 3 threats" or similar numeric display — is wrapping to two lines at that narrow width.

## Fix approach

### Step 1: Read the test to understand what's expected
Read decision22_test.gd lines 65-85 (the layout_check function and around line 75). Understand:
- What is the "D threat chip"? (the unit chip showing threats for unit D)
- What text is in it at portrait size?
- What does "two readable lines" actually check?

### Step 2: Read hud_phone_layout.gd to find the chip
Find where the threat chip's label/container is built. Focus on:
- Font size for the chip text
- Min-size or truncation settings
- Whether the chip has portrait-specific sizing

### Step 3: Fix the chip layout for portrait
Options (pick the least invasive one that works):
a. If the chip has a fixed/minimum width: adjust it slightly for portrait so the text fits on one line
b. If the chip has a font size that's too large: reduce it by 1-2px
c. If the chip text is verbose ("3 threats"): shorten it to fit ("3 T" or use numeric only)

The goal is to make the chip text fit in ONE readable line at 390px wide without breaking landscape.

### Step 4: Verify with focused portrait test
```
mkdir -p /home/jess/projects/tw-logs/w26/fix2
xvfb-run -a /home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility --resolution 390x844 -s tests/decision22_test.gd -- --graphics=low 2>&1 | tee /home/jess/projects/tw-logs/w26/fix2/decision22-portrait.log
```
Target: `DECISION22 TEST RESULTS: 31 checks, 0 failures`

Also run landscape to confirm no regression:
```
xvfb-run -a /home/jess/projects/.tools/godot/godot --path godot --rendering-method gl_compatibility --resolution 844x390 -s tests/decision22_test.gd -- --graphics=low 2>&1 | tee /home/jess/projects/tw-logs/w26/fix2/decision22-landscape.log
```
Target: `DECISION22 TEST RESULTS: 61 checks, 0 failures`

### Step 5: Full gate
```
bash godot/test.sh > /home/jess/projects/tw-logs/w26/fix2/gate.log 2>&1
```
Parse: total failures = 0, SCRIPT ERRORs = 0.

### Step 6: Commit all fix1+fix2 changes together if gate is green
```
git add godot/scripts/hud_phone_layout.gd godot/tests/decision22_test.gd
# (and any other changed files from your fix)
git commit -m "Fix decision22 layout regression from W26 HUD changes

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git log --oneline -1
```

Report: the commit SHA, test results, gate result.
Do NOT fast-forward main or push anything — that is the final integrate step.

## Boundaries
- Only edit hud_phone_layout.gd and/or decision22_test.gd (and any file you already changed in fix1).
- If more than 2 files need new changes: STOP and report.
- If the chip display genuinely cannot fit in portrait, it may be correct to update the test assertion — but document why.
- Do NOT revert fix1 changes.

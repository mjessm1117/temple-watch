# W21 COMMON rules (all four lanes) — Menus & Temple

Jess chose Menus & Temple for Wave 21 (ask-97670432) and all four lanes (ask-f623aa7b). The evidence is in the audit:
- report: /home/jess/projects/tw-logs/w21/audit/AUDIT-REPORT.md (read your lane's problem rows, the tap-target table and the XCOM notes)
- sheet: /home/jess/projects/tw-logs/w21/audit/2026-11-10-audit-sheet.jpg

## Setup (do this first, exactly)
```
cd /home/jess/projects/temple-watch
git worktree add -b w21/<lane> /home/jess/projects/tw-w21/<lane> b0eb42f
rsync -a --ignore-existing /home/jess/projects/temple-watch/godot/assets/ /home/jess/projects/tw-w21/<lane>/godot/assets/
cd /home/jess/projects/tw-w21/<lane>/godot && /home/jess/projects/.tools/godot/godot --headless --import
```
The rsync copies untracked textures that the import needs. Skipping it, or skipping the import, causes false SCRIPT ERRORs. In W20 that failed a gate.

## Rules
- Write ONLY the files in your lane's lease. Everything else is read-only.
- Exception 1: add one line to `godot/test.sh` to register your new test suite. Change nothing else there.
- Exception 2: you may update assertions in an existing `godot/tests/*.gd` file, but only when your intended change makes the old assertion wrong (for example, a layout or flow that changed on purpose). Never weaken a test to hide a bug. List every such edit in your report, with a reason.
- Needs a change in a file another lane owns? Do NOT edit it. Write it under "Integrate asks" in your report: the file, the function and the one-line change.
- Phone first. Check 844x390 (landscape) and 390x844 (portrait), Compatibility/Low. Also check 1366x768 desktop.
- Every tappable control must be at least 44 logical px and at least 12 px from the screen edge, with no overlaps. Text must be at least 14 px on phone and meet WCAG AA contrast (4.5:1).
- Scroll lists must stay finger-draggable, including drags that start on a button or card. Any new scroll area needs a drag test.
- Keep files under ~600 lines; split into new files inside your lease folder if needed. New files you create are inside your lease.
- No subagents. No Meshy spending. Never print MESHY_KEY. Never commit XCOM images. Port mechanics only.
- Do not merge, push or tag. Commit on your branch `w21/<lane>` only. Do not delete untracked files.

## Gate (must pass in your worktree before you finish)
1. `godot --headless --import` exits 0.
2. `./godot/test.sh` exits 0, with 0 `SCRIPT ERROR` and 0 failures in every suite, including your new one. Normal rescue lands at 9-11/20.
3. `git diff --check` is clean.

## Proof
Make a before/after sheet at /home/jess/projects/tw-logs/w21/<lane>/2026-11-10-<lane>-sheet.jpg. It has at most 6 panels and shows the main screens at 844x390 and 390x844. "Before" comes from main b0eb42f.

## Final message
- the commit SHA
- files changed
- new suite pass count, plus total suites and failures
- the Normal score
- the sheet path
- legacy-test edits, with reasons
- Integrate asks
- anything left undone

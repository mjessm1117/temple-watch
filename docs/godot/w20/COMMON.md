# W20 COMMON (every lane reads this first)
Base: local main 53322ee (includes phone-layout fix). Jess's iPhone notes: /home/jess/projects/tw-logs/w20/2026-11-09-jess-playtest-notes.md. His shots: /home/jess/projects/tw-logs/w20/jess-shots/. Audit (causes + line numbers): /home/jess/projects/tw-logs/w20/audit/AUDIT-REPORT.md.
Setup (exact, in order):
  cd /home/jess/projects/temple-watch && git worktree add ../tw-w20/<lane> -b w20/<lane> 53322ee
  cd /home/jess/projects/temple-watch && git ls-files -o --exclude-standard godot/assets | rsync -a --files-from=- ./ ../tw-w20/<lane>/
  cd ../tw-w20/<lane>/godot && /home/jess/projects/.tools/godot/godot --headless --import
Rules: commit locally on w20/<lane> only. No push/merge/tag. No subagents. Stay inside your file lease; if you need a file outside it, note it in your final message instead of editing. Files < 600 lines. Product copy speaks to the player, never about the build. Phone = target: check 844x390 AND iPhone emulation 956x440 @3x (phone_layout test override) AND desktop 1366x768. Every tappable control >= 44 logical px, not clipped. Never commit XCOM images. Never print MESHY_KEY; 0 Meshy credits.
Gate: import, ./godot/test.sh exit 0, 0 SCRIPT ERROR, 0 failures in every suite, Normal rescue 9-11/20, git diff --check. Add your own suite to test.sh (one line). Logs + shots to /home/jess/projects/tw-logs/w20/<lane>/ (never /tmp).
Proof: before/after sheet JPG (<= 6 panels) at /home/jess/projects/tw-logs/w20/<lane>/2026-11-10-<lane>-sheet.jpg. LOOK at it and fix what looks wrong before finishing.
Final message: SHA, sheet path, gate numbers (suites, fails, SCRIPT ERROR, Normal x/20), files touched, anything you needed outside your lease.

# W26 read-only audit — Battle: difficulty, friend/foe colors, phone HUD

Jess picked W26 focus "Battle — difficulty, colors, phone HUD" (ask-1a247e5b) after playing the W24 build on his iPhone (landscape).
His words: "First battle needs to be a bit easier I lost to easily." "Gameplay needs improvement." "Still far from xcom." "Story is good."

Worktree: /home/jess/projects/tw-w26/audit (branch w26/audit off main ce62160; untracked assets already copied). Run `godot --headless --import` in godot/ first. Godot: /home/jess/projects/.tools/godot/godot.
Output dir: /home/jess/projects/tw-logs/w26/audit/ (outside the public repo).

## Inputs (read first)
- /home/jess/projects/tw-logs/w25/2026-11-10-jess-playtest-notes.md: Jess's notes, plus my read of his 2 shots and 10 XCOM 2 iOS shots.
- Jess shots: /home/jess/projects/tw-logs/w25/playtest/2026-11-10-jess-01-battle-t1.png (gate defense T1) and -02-defeat-story.png.
- XCOM 2 iOS shots: /home/jess/projects/tw-reference/phone/2026-11-10-xcom2-ios-01..10.png (PRIVATE: never copy into the repo).
- Prior battle audit for baselines: /home/jess/projects/tw-logs/w24/audit/AUDIT-REPORT.md and docs/godot/w24/COMMON.md (lease map).

## Measure (live build, not code reading alone)
1. Difficulty: first mission (Temple outer gate defense). Record enemy count and pod layout at T1, how many squad members start flanked or with no cover, and enemy damage vs squad HP. Run reinforcement timing and an automated bot win rate over 20 seeds on Normal, using the existing rescue-bot harness pattern (add a temporary harness only in the worktree; do not commit). Compare with XCOM 2's first mission pattern: concealed start, pods unaware, the player picks the ambush. Propose 3-5 concrete knobs (pod count, spawn distance, activation rule, concealment/ambush turn, first-mission damage) with the expected win rate for each. Normal rescue 9-11/20 is a separate test that must stay.
2. Friend/foe: list every place sides are shown (unit materials, rim/outline, HP bars, plates, selection rings, minimap). Measure color distance between ally and enemy troopers at Low tier at 852x393. Compare with XCOM's cyan friend / red foe pips and chevrons.
3. Battle readability: cover readability on the terrain (half vs full), enemy sight/danger tiles, move range presentation (filled tiles vs outline), hover cover shields and the hit % preview before committing. Compare with XCOM shots X2-X4, X8.
4. Phone HUD at 852x393 (Jess's iPhone landscape), 844x390 and 390x844 on Low:
   - Every tofu glyph. Check font coverage for every string and icon codepoint used by the battle HUD, OBJ chip and right rail, and name the font and codepoint each one fails.
   - Every truncation (e.g. "12/", "GUAR").
   - Every overlap (AP rings over labels, HOLD ZONE over the objective).
   - Unexplained labels (e.g. "5 EXPOSED").
   - Any control under 44 px.
   Compare the layout with XCOM shot X6 (portraits top-left, left action rail, top-right system buttons, big Move/Objectives bottom-right) and X5 (one-line comms objective at start).
5. Defeat/story page: does "YOUR DECISION" still show with no choices after W25 (menus lane claimed a fix)? Re-check it.

## Output
- AUDIT-REPORT.md: baselines table, then the Top 15 gaps ranked by player impact (cause file:line, fix idea, size S/M/L, phone risk), then 3-5 proposed implementation lanes with EXCLUSIVE write leases (exact files, one test each, disjoint) and cross-lane contracts, in the same format as /home/jess/projects/tw-logs/w25/audit/AUDIT-REPORT.md. State a Meshy credit quote (expected: none; free art only).
- 2026-11-11-battle-audit-sheet.jpg: ONE JPG, 4-6 panels: Jess's shot vs current build at 852x393 vs the matching XCOM shot (sheet lives in tw-logs only), plus the tofu/overlap map.
- captures/*.png for each finding.

## Boundaries
- Read-only for the repo: no commits, no edits to tracked files, no push, no `git stash -u`, no `git clean`, never delete untracked files. Temporary harness/capture scripts live under /home/jess/projects/tw-logs/w26/audit/tools/.
- No Meshy calls. Never print MESHY_KEY. Never copy XCOM images into the repo.
- Final message: top 5 gaps, the first-mission win-rate baseline, proposed lanes with leases, sheet path.

Do not delegate or spawn subagents; do the work yourself.

# W20 Audit: reproduce Jess's iPhone playtest notes and map the fixes (lane tw-w20-audit)

Main repo /home/jess/projects/temple-watch, HEAD fbc2447. This lane is **read-only for game code**: no edits under godot/, no commits to game files, no push/merge/tag. No subagents.

## Goal
Jess played the live phone build on iPhone and gave these notes (full text: /home/jess/projects/tw-logs/w20/2026-11-09-jess-playtest-notes.md):
1. The game starts on a weird page. It should open on the story.
2. The story needs about 10x more.
3. After the story, lead straight to the squad loadout. There the player equips gear AND equips skills up to level 3 of the skill tree.
4. Choices must have noticeable differences and benefits. The skill tree is key.
5. The graphics feel weird and blocky. They can be playful but must feel nice.
6. The map camera is stuck facing backwards, and the camera controls badly on phone.
7. Buttons need appropriate sizing.
8. The Temple must be BIG, and the galaxy map BIG.

For each note, find the cause and the exact files involved. That evidence feeds the W20 fix lanes.

## Steps
1. **First-run flow.** Do a fresh save (clear user:// save) at 844x390, Compatibility/Low. Capture every screen from boot to the first battle, then write down the screen order. Find the scene/script that decides the first screen. Answer two questions: what is the "weird page", and where does the story currently appear?
2. **Story inventory.** List every story beat/screen, its word count and where it fires. Estimate total story words before the first mission and across the campaign.
3. **Loadout + skill tree.** Map what exists today:
   - armory/loadout screens
   - gear slots
   - the progression/rank/ability data (176 abilities, chains)
   - promotion_screen
   - whether a player can pick skills before mission 1
   - how many tiers exist and what the choices actually change in combat

   Capture screenshots. Flag choices whose numbers barely differ (for example, under 10% effect difference).
4. **Camera.**
   - Reproduce "facing backwards". Capture the initial battle camera yaw versus where the squad, enemies and objective are, on the defend-gate first mission and 2 other maps.
   - Find the code that sets the initial yaw and any phone-specific override.
   - Map phone touch camera controls (drag rotate, pinch zoom, pan) and how they conflict with tap-to-move. Note the touch thresholds.
5. **Buttons.** At 844x390 and 390x844, measure every tappable control on title, story, Temple home, galaxy, armory and battle HUD. List any that are under 44 px or over ~15% of screen height, and any that overlap or crowd. Output a table.
6. **Temple + galaxy size.** Screenshot both at 844x390. Measure what fraction of the screen the actual Temple/galaxy view fills compared with UI chrome.
7. **Blocky look.** Screenshot battle at a normal camera distance plus a close-up. List the top 10 things that read "blocky":
   - low-poly props
   - flat cubes for terrain
   - unit proportions
   - lighting and colour

   Name the asset files behind each.
8. **XCOM 2 reference.** The game is installed under ~/snap/steam (see docs/XCOM2-STUDY.md for the earlier REA study). Use the existing study and tw-reference/ shots. For each area (start flow, loadout/skills, camera, Temple/Avenger, Geoscape), write 2–3 lines on how XCOM 2 does it. Never copy XCOM assets into the repo.

## Output
- Screens go to /home/jess/projects/tw-logs/w20/audit/ (PNG).
- Make one contact sheet at /home/jess/projects/tw-logs/w20/audit/2026-11-09-audit-sheet.jpg with at most 8 panels.
- Write the report to /home/jess/projects/tw-logs/w20/audit/AUDIT-REPORT.md. For each note it gives: cause, files and line ranges, a proposed fix, and size (S/M/L). The report ends with a proposed W20 lane split. Lanes need disjoint file leases, with each lane's files listed.
- Final message: report path, sheet path, and a 1-line cause for each of the 8 notes.

## Boundaries
- Do not edit or commit under godot/, tools/, or docs/ except new files in docs/godot/w20/.
- Never commit XCOM images.
- Never print MESHY_KEY. Spend no Meshy credits.
- Capture scripts may live in /home/jess/projects/tw-logs/w20/audit/scripts/.

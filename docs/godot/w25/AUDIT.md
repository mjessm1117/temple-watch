# W25 Audit: Menus & Temple DEEPENING (read-only, lane tw-w25-audit)

Jess picked "Menus & Temple deepening" (ask-918c20c0). W21 already polished these screens. W25 is about DEPTH: what the player can decide and do between missions, and whether the Temple feels like XCOM 2's Avenger (a living base you build, staff and plan from). The look also gets re-checked after W21 and W23.

## Setup
- Worktree /home/jess/projects/tw-w25/audit on a new branch w25/audit off last-good 4f2e4c7 (W24 shipped).
- rsync the untracked godot/assets and addons from /home/jess/projects/temple-watch, then run `godot --headless --import`. Binary: /home/jess/projects/.tools/godot/godot.
- Read-only for tracked files: no edits, commits, pushes, merges or tags. Capture scripts go in /home/jess/projects/tw-logs/w25/audit/scripts/.
- Captures at 390x844 (portrait), 844x390 (landscape) and 1366x768, Compatibility/Low. Use three saves:
  - a fresh save
  - a save after mission 1
  - a mid-campaign save (about 5 missions in: roster grown, research done, rooms unlocked). Script it if it doesn't exist.

## Read first
- /home/jess/projects/tw-logs/w21/audit/AUDIT-REPORT.md: the W21 baseline. Re-check each of its top 15 problems and mark it FIXED, PARTIAL or OPEN with evidence.
- docs/godot/w21/*.md for what the W21 lanes built.
- /home/jess/projects/tw-reference/ (W21-GAPS.md if present, Avenger and menu frames) and docs/XCOM2-STUDY.md. These are private: never copy them into the repo.
- Jess's notes: /home/jess/projects/tw-logs/w20/2026-11-09-jess-playtest-notes.md. He asked for a big Temple, a big galaxy map, story leading into loadout, and a skill tree that is key.

## Measure
1. **Depth inventory.** This is the core of the audit. For every Temple room and menu, list the real decisions a player makes there and the resources they trade. Compare each with its XCOM 2 counterpart:
   - building and clearing facilities, power, and staffing engineers/scientists
   - the research queue and Proving Ground projects
   - the armory: loadouts, weapon mods, PCS, and customizing looks
   - the Guerrilla Tactics School and squad size
   - the infirmary (wounds, fatigue, will)
   - the Resistance comms and contacts, and the Shadow Chamber
   - the memorial and bar (soldier bonds and character)
   - Dark Events and the Avatar countdown
   - scanning on the Geoscape, plus supply drops and income

   Mark each one MISSING, SHALLOW (shown but no real choice), or DEEP. Port mechanics only.
2. **Economy loop.** Map the resources (names, sources and sinks) and the time pressure. Does the player ever face a hard trade-off between missions? Count meaningful decisions per between-mission visit on the mid-campaign save. XCOM 2 typically gives 3–6.
3. **Temple alive check.** Look for staff and figures in rooms, room states (building, idle, needs attention), ambient motion and light, camera moves between rooms, and badges. Compare against the Avenger cutaway.
4. **Flow re-check.** Count the taps to do each of these from Temple home:
   - equip
   - research
   - hire
   - heal
   - launch a mission
   - read the story/journal

   Also check for dead ends, Back traps and portrait reachability.
5. **Menus re-check.** Cover the title, settings (including the new W24 controls panel), pause, save/load, debrief and promotion. Check:
   - consistent W23 tokens
   - contrast AA
   - tofu and clipped text
   - 44 px targets
   - iPhone drag-scroll on every list (OWNER rule 12)
6. **Story hooks.** List where the Temple delivers story between missions (comms, journal, characters reacting) and where it's silent.

## Output (only to /home/jess/projects/tw-logs/w25/audit/)
- **AUDIT-REPORT.md** (under 200 lines). It contains:
  - the W21 re-check table
  - the depth inventory table: our Temple feature, XCOM 2 equivalent, and MISSING/SHALLOW/DEEP
  - the economy map
  - the **top 15 gaps** ranked by player impact, each with cause (file:line), fix idea, size S/M/L, and phone risk
  - **proposed 3–6 lanes** with DISJOINT write leases (exact file lists), one test each (`godot/tests/<lane>25_test.gd`), the gaps each lane fixes, and cross-lane contracts as guarded has_method hooks. Each shared file goes to one owner.
  - flag any lane that needs new art: free source first (Blender, shader or CC0). List a Meshy credit quote separately, only if truly needed. NEVER call Meshy.
- **2026-11-11-temple-audit-sheet.jpg**: one JPG with 4–8 panels, our screens next to the Avenger refs.
- **Final message**: top 5 gaps in one line each, the lane split, any Meshy quote, and the sheet path.

## Boundaries
- No Meshy calls; never print MESHY_KEY. Never copy XCOM 2 images or text into the repo (it is public).
- Never delete untracked files. No `git stash -u` and no `git clean`.
- Do not delegate or spawn subagents.

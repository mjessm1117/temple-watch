# W22 Story Audit (lane tw-w22-story-audit)

Main repo: /home/jess/projects/temple-watch, at HEAD 81c7644 (W21 shipped). This lane is **read-only for game code**:
- no edits under godot/, tools/, or docs/ (except new files in docs/godot/w22/)
- no commits, push, merge or tag
- no subagents

A separate battle-feel audit (tw-w22-audit) runs at the same time. Do not touch its output folder tw-logs/w22/audit/.

## Goal
Jess added **Story** to Wave 22, next to Battle feel. W20 already expanded the story: an 8-screen opening and briefings about 5x longer (docs/godot/w20/STORY.md). Find out how the story feels NOW to a player, especially **inside and around battle**, where it overlaps with battle feel. The output feeds fix lanes that run next to the battle-feel lanes.

## Setup
Run `godot --headless --import` first. The binary is /home/jess/projects/.tools/godot/godot. Capture at 844x390 (Compatibility/Low) and 1366x768. Play from a fresh save through the opening, mission 1 (Temple gate defense), the debrief, the Temple, and at least 2 more missions. Use the rescue bot or scripted inputs to drive play.

## Steps
1. **Story inventory.** List every place story text or a character moment appears, with its files and data (godot/data/story and the scripts that read it):
   - opening
   - briefings
   - in-battle lines (mission start, reinforcements, objective change, unit hurt or killed, villain appearance, turn-limit warnings)
   - debriefs
   - rank-up story
   - Temple room dialogue
   - journal
   - Sith/Shadow War text
   - bonds and choices

   For each one, give word counts and say how often a player sees it.
2. **Story in battle.** XCOM 2 keeps the story alive mid-mission: radio chatter from Central/Bradford, squad barks on kill/hurt/flank, VO on objective changes, and a villain taunt. List:
   - what we have now
   - what fires never or too rarely
   - what has no speaker portrait or name
   - what blocks play (a modal pop-up) when it should be a non-blocking banner
3. **Characters.** For each named character (the 7 Jedi, the commander/advisor voices, the villain), note:
   - how often they speak
   - whether their voice is distinct
   - whether their portrait or model appears when they speak
   - whether their bonds and choices pay off later

   Flag characters who are named but do nothing.
4. **Arc and pacing.** Map the campaign arc, mission by mission. Find the following:
   - stretches with no story beat
   - repeated or generic lines
   - beats that contradict each other
   - choices that have no consequence
   - the villain's presence over time
5. **Text quality.** Find:
   - typos
   - tone breaks
   - walls of text on the phone (more than ~60 words on one screen at 844x390)
   - text clipped in its box
   - tap-to-continue friction (count the taps per story screen)
   - skip, fast-forward and log availability
6. **Delivery feel.** Check:
   - typewriter speed
   - portrait framing
   - camera use for story beats (cutaways and close-ups during battle)
   - music and sting cues
   - whether story screens look like the rest of the W21 style (ui.gd tokens, Noto fonts)
7. **XCOM 2 notes.** Use docs/XCOM2-STUDY.md and the tw-reference/ material. For each area above, write 2–3 lines on how XCOM 2 delivers story (mission radio, Avenger cutscenes, Chosen taunts, soldier bonds, the post-mission debrief). Port mechanics only. Never copy any text or assets.

## Output
- Captures go to /home/jess/projects/tw-logs/w22/story-audit/. Scripts go in /home/jess/projects/tw-logs/w22/story-audit/scripts/.
- Make one contact sheet at /home/jess/projects/tw-logs/w22/story-audit/2026-11-10-story-audit-sheet.jpg, with at most 8 panels.
- Write the report to /home/jess/projects/tw-logs/w22/story-audit/AUDIT-REPORT.md. It needs:
  - the inventory table
  - the in-battle story table
  - the character table
  - the arc map
  - the top 12 story problems, ranked by how much a player would notice them, each with cause, files and line ranges, proposed fix and size (S/M/L)
  - the XCOM notes
- End the report with a **proposed story lane split** of 1–2 lanes with disjoint file leases, and list every file each lane may write.
  - Name each test as `godot/tests/<lane>22_test.gd`.
  - Mark any file that a battle-feel lane would also likely need. These include combat HUD, banner/toast, camera and audio files. For each one, say which side should own it, and propose a small hook or API the story lane can call instead of editing that file.
- Final message: report path, sheet path, top 5 problems in one line each, the lane split, and the shared-file list.

## Boundaries
- Read-only game code, as above.
- Never commit XCOM material. Never print MESHY_KEY. Spend no Meshy credits.
- Do not delete or move untracked files in the repo.

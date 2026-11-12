# W22 lane F — Story delivery in and around battle (task tw-w22-storydelivery)

First read /home/jess/projects/temple-watch/docs/godot/w22/COMMON.md and follow it exactly. Your lane name is `storydelivery`, so your worktree is /home/jess/projects/tw-w22/storydelivery on branch w22/storydelivery, off 81c7644.

## Goal
Fix: Story problems #3, #4 (delivery), #5 (paging), #7 (wiring), #9 (passing units), #11 and #12. Use the audit rows for causes, files and lines.

## Work
- Turn-2 story beat: information becomes a non-blocking radio card (contract 7). A real tactical choice becomes a compact end-of-turn prompt with the battlefield still visible, not a full-screen modal that disables input.
- Wire `battle_event` (guarded) through `campaign_bridge.gd` → E's `pick_bark` (guarded; fall back to the existing barks) → `show_radio`, with the COMMON rate limits.
- Villain reveal: a portrait/name card plus B's `cue("villain")` and A's `cue_story("villain", pos)` (both guarded).
- Pass the real `units` and mission result to `start_debrief`.
- Paging: story_screen and opening auto-page any text over 60 words at sentence breaks, with a page counter and a Skip/Fast-forward. Count taps per screen before and after.
- Transcript: keep a bounded narrative-only transcript (speaker, turn, text; max 40 lines) and show it in the journal (journal_night1). If it needs to persist, put it in the campaign dict that campaign_bridge already holds; if that needs state.gd, write an Integrate ask instead.
- Story screens use the W21 ui.gd tokens and Noto fonts.

## File lease (you may write ONLY these)
`godot/scripts/story/opening.gd`, `godot/scripts/story/story_screen.gd`, `godot/scripts/story/journal_night1.gd`, `godot/scripts/story14_comms.gd`, `godot/scripts/story14_portraits.gd`, `godot/scripts/campaign_bridge.gd`, new `godot/scripts/storydelivery22_*.gd`, `godot/tests/storydelivery22_test.gd`

Every other file is read-only. Changes needed elsewhere go under Integrate asks.

## Test
New suite `godot/tests/storydelivery22_test.gd`, registered with one line in test.sh. It covers each Work bullet with real assertions (numbers, not just "exists").

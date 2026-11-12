# W22 lane E — Story content, barks and continuity (task tw-w22-storycontent)

First read /home/jess/projects/temple-watch/docs/godot/w22/COMMON.md and follow it exactly. Your lane name is `storycontent`, so your worktree is /home/jess/projects/tw-w22/storycontent on branch w22/storycontent, off 81c7644.

## Goal
Fix: Story problems #1, #2, #4 (lines), #6 (villain lines), #7 (actor choice), #8, #9 (debrief composition), #10 and the content half of #5. Use the audit rows for causes, files and lines.

## Work
- Fix the gate win continuity: the post-gate scene must match "attackers withdrew". Keep the choice effect IDs and a real ethics choice.
- Give the first chosen crisis (rescue, shrine or archive) a 60-90-word bridge and a specific 1-2-line debrief linking gate → envoy.
- Barks: write actor-specific kill, hurt, flank, crit, miss and reveal lines for each of the 7 Jedi (kira, tor, satele, ressa, kell, sava, tem), plus advisor fallbacks. Each line is at most 14 words, in that character's distinct voice, and names the bondmate where it fits. Implement contract 6 (`pick_bark`): the affected unit first, then the bondmate, then the advisor.
- Villain: a named intro line, a taunt and a different retreat line.
- Put the speaker in every W10 beat row (no Council default).
- Debrief: compose a short priority line from the objective, casualties, the chosen mid-beat and a named participant. Use the `units` that F will pass to `start_debrief`; handle the case where they are missing. Trim repeated prose.
- Give each of the 14 shared-label pair/squad scenes 1 tailored choice pair that names the actual pair.
- Text on phone: split any story page over 60 words at real beat breaks (opening, story20 expansion). Keep the total story volume (Jess asked for MORE story in W20). Report the word count before and after.
- Original writing only. No XCOM or Star Wars film text. Tone: earnest Jedi drama with dry wit, never parody.

## File lease (you may write ONLY these)
`godot/data/story/opening.json`, `godot/data/story/story20-expansion.json`, `godot/data/story/story14-barks.json`, `godot/data/story/wave10-choices.json`, `godot/data/story/wave10-talks.json`, `godot/data/story/wave11-scenes.json`, `godot/data/story/wave11-villain.json`, `godot/data/story/night1-arcs.json`, `godot/data/story/night1-callbacks.json`, `godot/data/story/data-saga.json`, `godot/data/story/data-story.json` (crisis briefs and the barks section only), `godot/scripts/story/story_engine.gd`, `godot/scripts/story/story_choices.gd`, `godot/scripts/story/story14_beats.gd`, `godot/scripts/story/arc_night1.gd`, `godot/scripts/story/villain11_arc.gd`, `godot/scripts/story/scenes11_squad.gd`, `godot/tests/storycontent22_test.gd`

Every other file is read-only. Changes needed elsewhere go under Integrate asks.

## Test
New suite `godot/tests/storycontent22_test.gd`, registered with one line in test.sh. It covers each Work bullet with real assertions (numbers, not just "exists").

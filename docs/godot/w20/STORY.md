# W20 lane A — open on the story, ~10x more story (lane name: story)
Read COMMON.md first. Worktree ../tw-w20/story.
## Jess wants
"It starts on a weird page. Should start with story. Story could be enhanced by about 10x. You should immediately get led to your squad loadout."
Today: START → Temple → Sith "Shadow War" intelligence panel with empty lists (the weird page). About 85 story words before mission 1.
## Do
1. New campaign (fresh save) flow: title START → NEW opening story sequence → first mission briefing (Temple Outer Gate defend, expanded) → squad loadout (existing squad.tscn route) → battle. Continue on an existing save keeps its saved stage. The Sith intelligence panel must not show before the first mission ends; queue it after, and never show it with empty lists (hide empty sections or show a one-line "No Sith movements detected yet").
2. Opening story: 800–1,100 words over 6–9 paced screens (typewriter + tap to advance, a visible Skip that goes straight to the briefing). Use existing characters and lore already in data/story (Kira Venn, Tor, the Temple, the Sith threat); keep it consistent with existing campaign beats. Use existing portraits/Jedi library renders and existing story screen styling; phone layout must read well at 956x440@3 (big readable text, no scroll walls).
3. Expand the first briefing to ~150–250 words with clear stakes and objective (hold the gate ~6 turns).
4. Expand campaign story ~3–5x where it is thinnest: the 18 story-mission briefings and debriefs and the first 10 Council events (target 120–250 words each). Keep IDs, choice effects and unlock triggers unchanged.
5. Remove the title-page vision blurb wall from the first impression (keep it short or move it under an About button).
6. Write the full opening text also to /home/jess/projects/tw-logs/w20/story/2026-11-10-opening-story.md so Jess can read it.
## File lease
godot/project.godot (main scene only), godot/scenes/menu.tscn, briefing.tscn, dialogue.tscn, new godot/scenes/opening*.tscn, godot/scripts/menu.gd, godot/scripts/campaign_bridge.gd, godot/scripts/story/**, godot/data/story/**, godot/scripts/campaign/sith_screen.gd, new tests/story20_test.gd.
## Tests (story20)
Fresh save: first screen after START is the opening story (not Temple/Sith); opening body words >= 800; Skip reaches the briefing; after the briefing the next scene is squad; Continue on a mid-campaign save is unchanged; Sith panel never renders with zero entries; story-mission briefing word totals at least 3x the fbc2447 baseline.
Sheet: title, 2 opening screens, briefing, then squad screen reached, at 956x440@3.

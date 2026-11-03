# Night 1b — Personal arcs: unique rewards + real pacing, 2026-11-03

## Goal
Night 1 arcs (docs/godot/night1/STORY-REPORT.md, godot/data/story/night1-arcs.json, scripts/story/arc_night1.gd) all end with the same reward pair and resolve after 2 missions. Make each arc feel like that character's own.

## Requirements
1. Each of the 6 arcs (Kira, Tor, Rhal, Ilsa, Bren, Grak) gets its own pair of resolution rewards that fit the character and their class, using only existing stat/state fields (read how bonus.*, dark, resources, staff/temple fields are applied — don't invent new combat rules). Examples of the spirit: Bren = infirmary heals faster or +medkit; Ilsa = +intel per month or reveal enemy count in briefings; Grak = Mandalorian ally favor; Rhal = squad will; Kira = +sight/aim on overwatch; Tor = mercy/Darkness reduction. One option stays "lighter" path, one "harder/darker" with a real trade-off. If a reward needs a hook outside the lease, choose a different reward instead.
2. Pacing: step 1 after 1 mission (keep), step 2 after 3 missions OR bond level 1 with anyone, step 3 after 6 missions OR era 2 start. Rescale fixtures/tests accordingly.
3. Each step-3 choice shows its effect text on the button (like briefing options do).
4. Journal hint lines update to say what unlocks the next step ("After 2 more missions").
5. Old saves mid-arc keep their current step.

## Boundaries
Plain GDScript, files <600 lines (story_engine.gd is 570 — put new code in arc_night1.gd or a new arc_rewards.gd). No balance-breaking (no reward bigger than +10 will, +2 crit, +1 resource per month). Original prose only. No network/Meshy. Do not touch public/, functions/, tests/ (web), worker.js, wrangler.toml, HUD/graphics/fx files, campaign/temple*.gd, home_*.gd. Do not delegate or spawn subagents.

## File lease
godot/data/story/night1-arcs.json, godot/scripts/story/arc_night1.gd, journal_night1.gd, new godot/scripts/story/arc_rewards.gd, story_screen.gd (only step-3 effect text), godot/tests/story_night1_test.gd, docs/godot/night1/STORY-REPORT.md (update arc table), docs/godot/shots/night1-story-arc-*.png.

## Verification
1. story_night1_test.gd: each arc's two rewards apply and differ from every other arc; pacing gates (missions / bond / era) open each step exactly when stated; old mid-arc save keeps step; death still closes arc.
2. ./godot/test.sh exit 0, 0 SCRIPT ERROR, all suites 0 failures, Normal rescue 10/20.
3. Re-capture night1-story-arc-resolution.png showing effect text on choices.
4. Commit: "Give each Jedi arc its own rewards and slower pacing". Do not push.

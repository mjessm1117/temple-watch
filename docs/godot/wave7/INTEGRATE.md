# Wave 7 integrate: wire the four lanes into one playable game (read WAVE7.md first)
Branch wave7/integrate (worktree ~/projects/tw-wave7/integrate). The four lanes are already merged here: missions 27b837e, combat fea3c8d, sith f2e640a, strategy daba301.
First run `godot --headless --editor --import --quit` in godot/ (Godot at /home/jess/projects/.tools/godot/godot).

LEASE: anything under godot/ plus docs/godot/wave7/integrate-REPORT.md and docs/godot/shots/wave7-final-*. Web game (public/, functions/, tests/, worker.js) stays frozen. Local commits only, no push, no subagents. GDScript files stay under 600 lines (split by topic).

Goal: a player starting a new campaign meets every wave 7 system in the real game, not only in standalone tests.

Work list. Read the "Integration requests" section of every lane report (docs/godot/wave7/{missions,combat,sith,strategy}-REPORT.md) and wire ALL of them. These are the known ones:
1. Test gate: ./godot/test.sh currently exits 1 on an obsolete rescue-fallback assertion (the missions lane removed that fallback). Update the assertion to the new behavior; do not weaken other checks.
2. Missions + combat:
   - Reconcile combat_mission.gd (`Mission.adopt`) with the new mission.gd.
   - Wire the combat Interact action to `Mission.interact()` / `Mission.interactables()` for hack, relay, sabotage, rescue and civilians.
   - Battle scene builds the mission's own map, theme and props through map_presentation.gd, not the fixed rescue env.
   - Objective text in the HUD comes from the mission family, not "Free Mira".
   - Show overwatch zones, reinforcement announcements one turn ahead, and phase changes to evac.
   - The missions concealment flag drives combat concealment.
   - Two-front missions (mission_fronts.gd) are called from campaign advancement.
3. Sith into the campaign:
   - Create SithLayer from campaign state and save it with old-save defaults.
   - Call `advance_day()` on the day tick and `month_end()` at month end. Feed mission results back.
   - Galaxy shows Dark Events, the counter-mission choice, rival ambush/rescue/stronghold/pursuit missions and the Darkness segments with the next escalation date.
   - `rival_for_mission()` spawns the named rival in battle with their strengths and weaknesses.
   - The council report screen opens at month end.
   - Retaliation missions use the missions lane's retaliation family.
4. Strategy into battle and campaign:
   - 5–6 soldier squads launch through battle_bridge and spawn correctly.
   - Learned and trained abilities are active in battle.
   - Fatigue and wounds apply from the mission result.
   - Covert-op captures can be rescued.
   - The new Galaxy field-ops panel, tactical settings, voices and Padawan proximity bonus are wired.
   - Expose the Darkness and month hooks the sith lane uses (one source of truth: do not keep two Darkness meters that disagree; Order Darkness 0–100 and Sith Darkness segments may coexist only if both are shown clearly).
5. Polish found in review:
   - Battle unit name/HP labels overlap when soldiers stand close; stack or fade them.
   - Battle ability bar shows about 20 buttons; group them (core actions always visible, techniques in a second row or popup) so it reads at 1366x768.
   - Temple cutaway room labels crowd each other; show fewer by default and full details on hover.

Gates (all required):
- `./godot/test.sh` exits 0, no failures, no SCRIPT ERROR.
- Every standalone test passes: sith_test, strategy_test, combat7_test, missions_test, temple_view_test, loadout_test, galaxy_view_test, screens_test.
- Bot bands per 20 games: Story ≥14, Normal 9–12, Hard 4–7, Legend 1–3 (rescue fixture).
- Add a campaign bot check that plays at least one mission from every family (rescue, hack, relay, defend, retaliation, sabotage, ambush) through the real bridge on Normal and reports win rate per family. Families far outside 30–80% wins get retuned via difficulty/mission data; report the numbers.
- Add an integration test proving: new campaign → month end fires council report; a Sith Dark Event is counterable from the galaxy; a 5-soldier squad launches; an Interact objective completes in a real battle.

Report docs/godot/wave7/integrate-REPORT.md:
- every integration request from the four reports marked wired / skipped (with reason);
- player-visible changes;
- bot numbers;
- real-window screenshots docs/godot/shots/wave7-final-*.png of: galaxy with Sith ops + Darkness, a non-rescue mission map in battle with the cleaned-up HUD, a 5-soldier loadout, the Temple build grid, the council report.
Then commit on wave7/integrate.

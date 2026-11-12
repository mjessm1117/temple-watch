# W25 lane: menus (E)

Read /home/jess/projects/temple-watch/docs/godot/w25/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w25/menus, branch w25/menus off 4f2e4c7. Test: godot/tests/menus25_test.gd. Proof: /home/jess/projects/tw-logs/w25/menus/.

Goal: every menu works on a phone, the Temple rooms talk, and launching a mission is short.
- G1: shared Settings/Controls becomes a full-screen phone sheet (campaign_bridge.gd:49-66). Wrap it in touch_scroll.gd, give it a sticky Back and title bar, and save the scroll position. At 390x844, a finger drag must reach the last remap row and Back. Same sheet from title, pause and battle.
- G6 room story: create data/story/room_story25.json with 1-2 short beats per room (Archives, Forge, Medical, Comms, Barracks, Memorial, Council). Use existing named characters in the current story voice; Jess said "Story is good", so match it. At least 4 beats have a 2-option choice with a small persistent effect through existing state calls, plus a Journal follow-up line. Implement `CampaignFlow.open_room_story25(room_id) -> bool` (contract 3). Beats are due by campaign progress, shown once, saved in w25_ keys, non-blocking, and must not hide the room for more than the dialogue card.
- G12 story side: Memorial beats let the player answer a fallen soldier's memory (bond or resolve effect, small). Barracks beats offer an optional bond conversation between two living soldiers.
- G14: implement `CampaignFlow.launch_ready25(mission_id)` (contract 6). Show ONE readiness page: the briefing line, squad with readiness, and Deploy with a single confirm. Launch goes from 5 taps to <=3 after the Galaxy marker. Story briefing beats still play. Keep `open_intelligence()` and route it to galaxy's `open_intel_view25()` guarded.
- G15: save/load highlights the current save and shows its date and mission (save_load.gd:45-59). Shared ui.gd tokens: lift secondary and hint text to >=14 px at AA contrast, which fixes the shortcut hint that is below AA.
- Defeat page (from Jess's shot): the "YOUR DECISION" header sat under "Tap to Advance" with no visible choices. Make the choices visible without scrolling at 390x844 and 844x390, or drop the header when there are none.
- Test: drag reaches the last remap + Back at 390x844, scroll position saved, room beat plays once and its effect saves, launch tap count <=3, the defeat page decision is visible, text size and contrast on the shared tokens.

Do not delegate or spawn subagents; do the work yourself.

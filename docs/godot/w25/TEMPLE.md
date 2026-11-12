# W25 lane: temple (A)

Read /home/jess/projects/temple-watch/docs/godot/w25/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w25/temple, branch w25/temple off 4f2e4c7. Test: godot/tests/temple25_test.gd. Proof: /home/jess/projects/tw-logs/w25/temple/.

Goal: the Temple home reads like the Avenger cutaway. People and room work are the focus, labels stay at the edges, and each room leads to its job in one tap.
- G2: priority badges and plates no longer cover the cutaway (temple_view.gd:170-194). Use compact edge badges (one glyph + count, >=14 px, AA) and ONE task rail card that shows `strategic_snapshot25().top_priority` (contract 1, guarded; fallback = today's highest badge). Keep the centre of the screen for rooms and figures at 844x390 and 390x844.
- G7 stage side: a staffed room shows its worker as the focal figure. Scale the existing figure up, give it a work pose or loop and a glowing project prop (procedural), and show a progress ring in the room. Selecting Archives frames the archivist before the research list opens. Keep the first study above the fold.
- G10 entry: the Medical room opens roster `open_from_temple("medical")` (contract 4, guarded; fallback = today's Roster route). The room shows a wounded count and the soonest return ETA.
- G13 spatial side: tapping an empty or sealed bay in the cutaway selects it in place (highlight + preview card). The build preview content comes from economy's strat_ui; call it guarded and fall back to today's build grid.
- G12 room button: Memorial gets a "Remember" action that calls `CampaignFlow.open_room_story25("memorial")` (contract 3, guarded; hide the action if absent or it returns false).
- Room story: on room select, call `open_room_story25(room_id)` guarded once per room per visit, so beats never repeat-spam.
- Comms room: route to `CampaignFlow.open_intelligence()` guarded (fallback = today's Galaxy route).
- At 390x844 the room drawer must not hide the selected room's figures (shrink or offset the camera).
- Life: idle figures walk short paths between rooms where corridors exist. Keep it cheap (instanced, no new skeletons) and inside the 5% draw/tri budget.
- Test: badges/plates rect-free of the centre stage region at both orientations; each room tap reaches the right screen; fallbacks work with the contracts absent.

Do not delegate or spawn subagents; do the work yourself.

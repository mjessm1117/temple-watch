# W25 lane: galaxy (C)

Read /home/jess/projects/temple-watch/docs/godot/w25/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w25/galaxy, branch w25/galaxy off 4f2e4c7. Test: godot/tests/galaxy25_test.gd. Proof: /home/jess/projects/tw-logs/w25/galaxy/.

Goal: the galaxy map plays like XCOM's Geoscape. You choose where to spend days scanning, build contacts to reach new regions, and always see the deadlines.
- G3 scan sites: 2-3 scan sites on the map at a time (data in galaxy.json), each with a reward (Cr/Intel/Kyber/recruit/lead) and a day cost. "Scan here" commits days through economy's `advance_strategy_day25` (contract 2, guarded; hide scanning if absent). Events that pop during the scan stop it and show what happened. The threat countdown stays visible while scanning.
- G4 contacts: regions start uncontacted except home. Making contact costs Intel + Cr and is capped by contact slots (start 2; Comms staffing or research can add more, read only from state). Uncontacted regions show missions as rumours and give no income. Contacted regions add monthly income and reveal Sith operations. Store this as w25_ keys owned by you. Show the contact choice above the fold on Galaxy.
- G8: with a mission selected in portrait, keep a mini region strip plus deadline and reward chips visible. Do not replace the whole map (galaxy.gd:95-116,269-278).
- G9: Galaxy has an Intel workbench that links Sith operations, the counter-op choice and the research it unlocks (sith_screen.gd:19-90). Implement `open_intel_view25()` for CampaignFlow to route Comms there.
- G14 map side: with a mission selected, "Ready" calls `CampaignFlow.launch_ready25(mission_id)` (contract 6, guarded; fallback = today's Briefing path). Back keeps the selection.
- Test: a portrait scan commit advances days via the contract and pays out; contact cap enforced; deadline chips visible with a selection; Back round trip keeps the selection; works with contracts absent.

Do not delegate or spawn subagents; do the work yourself.

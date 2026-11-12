# W25 lane: economy (B)

Read /home/jess/projects/temple-watch/docs/godot/w25/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w25/economy, branch w25/economy off 4f2e4c7. Test: godot/tests/economy25_test.gd. Proof: /home/jess/projects/tw-logs/w25/economy/.

Goal: resources and days force real choices between missions, the way XCOM's supplies and scan time do. The player can see each trade before making it.
- G5 balance: the audit's five-win save banks 958 Cr with nothing to buy (state.gd:247-269,283-290; core.json START_RES 500). Rebalance receipts, prices and upkeep so that after 5 wins on Normal the player can afford about 2 of their 3-4 wanted purchases. Write a deterministic sim in the test: 5 missions with fixed outcomes, then check the credits band at each month end and log the table in RESULT.md. Normal rescue must stay 9-11/20, and early game must stay affordable (first room buildable by month 1).
- G3 time side: implement `advance_strategy_day25(days, reason)` (contract 2). It is the single tick path for builds, research, heal, threats and upkeep, and today's day advance should go through it. The "Scan N days" button is galaxy's UI; you own the tick and the save.
- Forecast: implement `strategic_snapshot25()` (contract 1) with an honest `forecast_month_credits` (stipend + upkeep + troop pay) and a `top_priority` rule (idle lab > idle forge > power over cap > unbuilt urgent room > threat). home_resources shows a compact one-line forecast ("+212 Cr at month end") that stays one card at 390 px.
- G7 research side: research_screen shows who is working, ETA in days, and what the result unlocks, before the list. One project at a time stays (exclusivity test).
- G13 preview side: strat_ui build flow becomes select bay -> preview (cost, power use vs cap, adjacency bonus, finish date from snapshot) -> Confirm. Expose `build_preview25(bay_id, wing_id) -> Dictionary` so temple can show it in place. Fix the build grid's horizontal overflow at 390 px (strat_ui.gd:26-37).
- strat_ui personnel: draw roster's `patient_actions25` (guarded) where staff/Medical actions appear.
- Council: if a stipend or upkeep change affects strat_council text, update the numbers so they stay true.
- Test: the 5-mission sim band, queue exclusivity, an old save loading with defaults, tick equivalence (advance 15 days via the old path vs advance_strategy_day25 gives the same state), no overflow at 390x844.

Do not delegate or spawn subagents; do the work yourself.

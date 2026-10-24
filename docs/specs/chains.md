# Chains & hazards (Chat S, wave 9, 2026-10-23)

Jess's calls (form, 2026-10-23): chaining is **in battle**, on one character and across the squad. Split: **R** = one unit chains (kill → bonus AP, perks); **S** = squad chains between squadmates. Hazards rebuilt as **weapons**. Battle twists that chain are **warned one turn ahead**. Story threads across months are **shelved** (backlog below).

## Squad chains (`battle.js`, numbers `CHAIN` in `data-battle.js`)
- Every squadmate who acts on an enemy this turn is noted on it (`t.touch`, cleared each player turn).
- Attacking an enemy that *other* squadmates already acted on adds links: **+10 aim per squadmate before you (max +20)**; a **×3** chain also does **+1 damage**. Shows in the odds panel as `Squad chain ×N`.
- Any action counts as a setup: shot, Push, Pull, Stun, Mark, Disarm…
- **Push into Overwatch:** shoving an enemy past a squadmate on Overwatch triggers their shot.
- HUD row "Squad chain" shows the best chain this turn; hits float `CHAIN ×N`.

## Hazards (`hazards.js`, data `HZ_KIND` + tiles in `data-battle.js`)
Five kinds, one rule each, same for both sides:

| Kind | Tiles | Rule | As a weapon |
|---|---|---|---|
| Burn | Lava (2), Acid pool (1) | Damage on entry and each round you stay | Push in: burns now and every round |
| Shock | Live conduit | Live on even turns, warned the turn before. 2 damage; enemies lose their turn, troops lose 1 action | Push onto a live conduit |
| Slow | Mud, Thorns (+1) | Move ends there | Push in: enemy stuck next turn |
| Slide | Ice, Fuel slick | Keep sliding up to 3; 1 damage if you slam | Push on: it slides and slams |
| Fall | Chasm | Nobody walks in | Push over: troopers gone; elites/bosses take 4 |

Telegraphs: hover any hazard for its rule; the move path warns ("This path costs 2 HP"); in Push/Pull mode, hovering an enemy shows where it lands; conduits log "live next turn" / "LIVE". Briefing and Objectives list the kinds with rule + weapon line.

## Chained twists (`TWISTS[x].chain`, engine `chTick` in `battle.js`)
Crisis missions only. Each link is announced the turn before it lands.
- **cascade** (city/dock/caves/ruins/temple): dropship → ground cracks (red tiles fall next turn) → uplink pad (hold 1 turn-start: gunship strafe).
- **manhunt** (plains/jungle/snow/ruins): hunters land → officer runs to call the fleet (kill/stun him within 3 turns) → gunship strafe + Intel, or a full dropship.
Measured (weak bot, 16 games, Normal): archive 9→10, rescue 13→14, sabotage 10→12 wins. No harder than without.

## Backlog: story threads (shelved)
Month-to-month threads with a Temple tracker, darker branches when a step is missed, 3–4 Era 1 arcs feeding the Malgus finale via `FINALE` rows (data-saga.js). Picks already made: tracker visible, missed step turns darker, arcs feed Malgus.

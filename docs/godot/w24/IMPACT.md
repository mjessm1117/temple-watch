# W24 lane: impact

Read /home/jess/projects/temple-watch/docs/godot/w24/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w24/impact, branch w24/impact off aa19dd0. Test: godot/tests/impact24_test.gd. Proof: /home/jess/projects/tw-logs/w24/impact/.

Goal: every hit, miss, kill, blast and move has weight on phone Low without breaking budget.
- Contract 5 (impact24_cue, travel24, fall24) - each works when called alone and is a no-op for unknown kinds.
- B3: cheap emissive hit shape + spark burst + layered sound per weapon (blaster, saber, Force); pooled.
- B11: miss = bolt passes and hits a surface near the target (scorch + whiz sound) + target flinch.
- B9: 3+ procedural fall variants (stumble back, knee drop, spin) chosen by hit direction (unit_view.gd:314-340); keep body-hold and 6-corpse cap.
- B10: pooled low-cost smoke column + ground shock ring for blasts (fx.gd:345-367, w23_lightfx_billboards.gd:9-27). Low tier: <=2 extra draws per blast, auto-cull after 1.5 s.
- B7: travel24 dash cadence ~1.4x walk with lean; vault/climb/door segments get a short hop/step beat when segments are given (walk otherwise).
- B8: leap_land shock + dust; B14: footstep sounds synced to foot contacts (volume-limited, max 2 concurrent).
- Measure blast frame time on Low 390x844 before/after; report peak draws during a blast.

Do not delegate or spawn subagents; do the work yourself.

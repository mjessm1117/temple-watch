# W24 lane: camgest

Read /home/jess/projects/temple-watch/docs/godot/w24/COMMON.md first; it holds setup, leases, contracts, budget, gate, proof and finish rules.
Worktree /home/jess/projects/tw-w24/camgest, branch w24/camgest off aa19dd0. Test: godot/tests/camgest24_test.gd. Proof: /home/jess/projects/tw-logs/w24/camgest/.

Goal: the phone camera does what the finger says, and portrait Low hits the 150-draw target.
- K1: two-finger rotate is continuous and bounded (no 90-degree jump at 0.35 rad, touch_input.gd:17,79-89); gesture lock decides pinch vs rotate vs pan from the first 12 px/0.1 rad, honoring invert_rotate + cam_sensitivity from controls24.cfg.
- K2: past the drag threshold call cancel_camera_glide24 (guarded) and keep the manual pivot; no snap-back (measure pivot drift after release, target <0.05 units).
- K5: a touch that starts on any Control (ability tray, buttons, cards) never pans the board until release (touch_input.gd:38-40,90-99).
- Initial heading: battle11_camera.gd:8-32 - check every map family starts facing the enemy approach / objective from the squad side (Jess saw it backwards). Fix and test per map.
- Pinch zoom range 9-65 to match feelcam.
- Simulated finger-drag tests (OWNER rule 12): drags starting on a unit, a tile, a button, the tray; check no page rubber-band paths (touch-action on web shell is out of lease - list as Integrate ask if needed).
- B5: bring gate portrait Low to <=150 draws in a real battle-state counter by merging material buckets / static batches (map_art_batch.gd:100-107,147-155, geometry, edges). No visible quality loss; before/after shots at 390x844 Low.

Do not delegate or spawn subagents; do the work yourself.

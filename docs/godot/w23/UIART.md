# W23 Lane 5 — UI art + layout (lane id: uiart)
Read COMMON.md first. Gaps 3, 4, 8, 14, 15 + UI side of 12 and 13.
Lease: scripts/hud_phone.gd, hud_phone_layout.gd, hud_phone_action_art.gd, hud_phone_camera_art.gd, hud_controls.gd, battle12_aim.gd, story14_comms.gd, campaign/ui.gd, campaign/temple.gd, campaign/galaxy.gd, campaign/squad.gd, campaign/loadout_arsenal.gd, story/story_screen.gd; assets/fonts/**, assets/icon/**, assets/loadout/icons/**, assets/loadout/icons13/**, assets/ui/armory16/**, and under assets/ui/: jedi.glb, jedi_texture_0.webp, scout.glb, scout_texture_0.webp, airtaxi.glb, airtaxi_0.webp, CREDITS.md. Test: uiart23_test.gd.
Goal: one visual language across battle, story, Temple, galaxy, armory; the HUD stops covering the fight.
1. PC battle HUD: fewer persistent panels, no repeated status, target/action first.
2. Phone aim: ONE compact anchored odds card, clear sight line between shooter and target; 44 px targets kept.
3. Portrait battle: one alert layer at top (reveal/turn/radio queue, no overlap) and one action tray with safe edges.
4. Armory phone: fix vertical text clipping, reflow portrait card, hero unit lit (squad.gd/loadout_arsenal.gd).
5. Shared palette/type/icon tokens in campaign/ui.gd applied to story/debrief cards, battle, Temple, galaxy.
6. Temple room sheet shorter + contextual; galaxy selected-mission card shows threat + reward; call set_ui_safe_rect (contract 2, guarded).
7. Keep every W21/W22 behavior: threat chip by End Turn, radio cards non-blocking, 44 px, iPhone drag scrolling (OWNER rule 12: drag starting on a button/card must scroll).

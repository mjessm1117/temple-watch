# Wave 18 Jedi paths — distinct abilities

Seven playable paths each offer 13 rank 1–7 choices and one Grand Master signature. All 49 shipped definitions retain their IDs and numbers. These tables describe the current executable JSON, including riders. Chain tags in the last columns still apply and consume across the squad.

## Ability tables

### Guardian

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Deflect (`guardian_deflect`) | Padawan I | Guard, +12 defense; shield 2 self | SHIELDED | READY |
| Challenging Glare (`guardian_challenging_glare`) | Padawan II | suppressed at 68%; range 4; TAUNTED target; +3 defense self | TAUNTED | MARKED |
| Brace (`guardian_brace`) | Padawan II | Guard, +16 defense; +5 defense self; shield 1 self | SHIELDED | INSPIRED |
| Soresu Circle (`guardian_soresu_circle`) | Knight I | Aura +9 ally aim / -5 enemy aim; range 4; shield 3 all allies | SHIELDED | SHIELDED |
| Djem So Riposte (`guardian_djem_so_riposte`) | Knight I | 3–6 damage at 81%; melee; range 1.5; guard + reaction watch; damage 2 target | STAGGERED | PINNED |
| Interpose (`guardian_interpose`) | Knight II | Ally +16 aim, +17 defense; range 5; shield 5 target; +3 defense self | SHIELDED | SHIELDED |
| Breaking Parry (`guardian_breaking_parry`) | Knight II | 4–6 damage at 84%; range 1.5; disarm target; shield 2 self | EXPOSED | TAUNTED |
| Living Rampart (`guardian_living_rampart`) | Master I | Aura +13 ally aim / -7 enemy aim; range 5; shield 5 all allies; +4 defense all allies | INSPIRED | READY |
| Hammer Return (`guardian_hammer_return`) | Master I | 5–9 damage at 87%; melee; range 1.5; damage 2 target; shield 3 self | STAGGERED | EXPOSED |
| Bastion Wave (`guardian_bastion_wave`) | Master II | Wave 6 damage, 71% stun; range 4.9; shield 3 all allies; TAUNTED all enemies | STAGGERED | LIFTED |
| Sundering Counter (`guardian_sundering_counter`) | Master II | 6–9 damage at 90%; melee; range 1.5; guard + reaction watch; disarm target | PINNED | STAGGERED |
| Citadel Oath (`guardian_citadel_oath`) | Council Master | Aura +17 ally aim / -9 enemy aim; range 6; shield 7 all allies; cleanse all allies | SHIELDED | INSPIRED |
| Unyielding Judgment (`guardian_unyielding_judgment`) | Council Master | 7–9 damage at 93%; melee; range 1.5; guard + reaction watch; damage 4 target; TAUNTED target | TAUNTED | MARKED |
| Aegis (`guardian_grand_aegis`) | Grand Master | Guard; shield 14 all allies; TAUNTED all enemies; +10 defense all allies; once per mission | SHIELDED | SHIELDED |

Grand Master signature: Aegis shields every ally and taunts every enemy while raising squad defense.

### Knight

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Form Switch (`knight_form_switch`) | Padawan I | Ally +7 aim, +8 defense; range 3; switches stance | ATTUNED | INSPIRED |
| Opening Form (`knight_opening_form`) | Padawan II | 3–5 damage at 78%; range 4.6; +3 defense self | EXPOSED | MARKED |
| Centered Breath (`knight_centered_breath`) | Padawan II | Recover 2 Focus; shield 2 self | ATTUNED | SHIELDED |
| Vanguard Advance (`knight_vanguard_advance`) | Knight I | 4–5 damage at 81%; range 4.9; shield 3 self; +4 aim self | STAGGERED | EXPOSED |
| Force Balance (`knight_force_balance`) | Knight I | Push 2 tiles; 3 collision damage; range 4; focus 1 self | PINNED | LIFTED |
| Sweeping Form (`knight_sweeping_form`) | Knight II | 5–8 damage at 84% ×2 hits; range 5.2; STAGGERED area enemies | STAGGERED | PINNED |
| Force Channel (`knight_force_channel`) | Knight II | Recover 3 Focus; action 1 self; +2 defense self | INSPIRED | ATTUNED |
| Rallying Stance (`knight_rallying_stance`) | Master I | Aura +13 ally aim / -7 enemy aim; range 5; +5 aim all allies; READY all allies | READY | INSPIRED |
| Force Lash (`knight_force_lash`) | Master I | 5–9 damage at 87%; range 5.5; focus 2 self; damage 2 target | EXPOSED | PINNED |
| Balanced Assault (`knight_balanced_assault`) | Master II | 7–8 damage at 90% ×2 hits; range 5.8; shield 4 self; damage 2 target | MARKED | STAGGERED |
| Focus Exchange (`knight_focus_exchange`) | Master II | Ally +22 aim, +23 defense; range 6; focus 2 target; shield 4 target | ATTUNED | SHIELDED |
| Unified Forms (`knight_unified_forms`) | Council Master | Aura +17 ally aim / -9 enemy aim; range 6; +8 aim all allies; +8 defense all allies | INSPIRED | READY |
| Adaptive Mastery (`knight_adaptive_mastery`) | Council Master | 7–9 damage at 93%; range 6.1; consumes a present tag for +3 damage, then STAGGERED | — | — |
| Convergence (`knight_grand_convergence`) | Grand Master | Recover 2 Focus; action 1 all allies; focus 2 all allies; INSPIRED all allies; once per mission | ATTUNED | INSPIRED |

Grand Master signature: Convergence grants the entire squad an extra action, Focus, and INSPIRED.

### Duelist

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Kill Chain (`duelist_kill_chain`) | Padawan I | 1–3 damage at 75%; range 1.5; kill refunds 1 action once/turn | STAGGERED | EXPOSED |
| Vaulting Cut (`duelist_vaulting_cut`) | Padawan II | 3–5 damage at 78%; melee; range 1.5; +5 aim self; EXPOSED target | EXPOSED | STAGGERED |
| Duel Read (`duelist_duel_read`) | Padawan II | marked at 68%; range 4; +4 defense self | MARKED | PINNED |
| Ataru Leap (`duelist_ataru_leap`) | Knight I | Leap to tile, cloak, next strike aim +20; range 4; shield 2 self | ATTUNED | READY |
| Makashi Feint (`duelist_makashi_feint`) | Knight I | stunned at 73%; range 4; disarm target | STAGGERED | EXPOSED |
| Aerial Flurry (`duelist_aerial_flurry`) | Knight II | 5–8 damage at 84% ×3 hits; melee; range 1.5; damage 2 target; +5 aim self | STAGGERED | LIFTED |
| Disarming Edge (`duelist_disarming_edge`) | Knight II | 4–6 damage at 84%; range 1.5; disarm target; damage 1 target | PINNED | MARKED |
| Whirling Reprisal (`duelist_whirling_reprisal`) | Master I | Wave 5 damage, 65% stun; range 4.5; guard + reaction watch; damage 2 target | STAGGERED | EXPOSED |
| Measured Lunge (`duelist_measured_lunge`) | Master I | 5–9 damage at 87%; melee; range 1.5; +7 aim self; damage 2 target | EXPOSED | STAGGERED |
| Falling Star (`duelist_falling_star`) | Master II | 7–8 damage at 90% ×2 hits; melee; range 1.5; damage 3 target; STAGGERED area enemies | MARKED | LIFTED |
| Perfect Riposte (`duelist_perfect_riposte`) | Master II | Guard, +32 defense; guard + reaction watch; shield 5 self | SHIELDED | INSPIRED |
| Cyclone Blade (`duelist_cyclone_blade`) | Council Master | Wave 7 damage, 77% stun; range 5.3; damage 3 area enemies; +8 aim self | STAGGERED | PINNED |
| Final Measure (`duelist_final_measure`) | Council Master | 7–9 damage at 93%; melee; range 1.5; damage 5 target; action 1 self | EXPOSED | MARKED |
| Thousand Cuts (`duelist_grand_thousand_cuts`) | Grand Master | 5–7 damage at 95%; melee; range 1.5; jumps up to 4 foes after kills; once per mission | STAGGERED | EXPOSED |

Grand Master signature: Thousand Cuts starts in melee and jumps to the next nearby foe after each kill.

### Sage

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Telekinetic Throw (`sage_telekinetic_throw`) | Padawan I | 1–3 damage at 75%; range 4.3; EXPOSED target | EXPOSED | PINNED |
| Lift (`sage_lift`) | Padawan II | stunned at 68%; range 4; hold target; LIFTED target | LIFTED | PINNED |
| Insight Mark (`sage_insight_mark`) | Padawan II | marked at 70%; range 4; reveal target; +3 aim self | MARKED | EXPOSED |
| Force Cascade (`sage_force_cascade`) | Knight I | Wave 3 damage, 53% stun; range 3.7; LIFTED area enemies | EXPOSED | LIFTED |
| Seer Sight (`sage_seer_sight`) | Knight I | Ally +13 aim, +14 defense; range 4; reveal all enemies; +4 aim target | ATTUNED | SHIELDED |
| Crushing Grip (`sage_crushing_grip`) | Knight II | 5–8 damage at 84%; range 5.2; hold target; damage 2 target | PINNED | LIFTED |
| Premonition (`sage_premonition`) | Knight II | Aura +11 ally aim / -6 enemy aim; range 5; reveal all enemies; +5 defense all allies | INSPIRED | READY |
| Shatterpoint (`sage_shatterpoint`) | Master I | 6–8 damage at 87%; range 5.5; damage 4 target; EXPOSED target | EXPOSED | MARKED |
| Foresight (`sage_foresight`) | Master I | marked at 83%; range 5; reveal all enemies; +3 aim all allies | MARKED | STAGGERED |
| Gravity Well (`sage_gravity_well`) | Master II | Area 5–7 damage; breaks 7 cover; range 6; hold area enemies; LIFTED area enemies | LIFTED | PINNED |
| Psychic Lance (`sage_psychic_lance`) | Master II | 6–9 damage at 90%; pierces a second foe; range 5.8; damage 3 target; LIFTED target | STAGGERED | IONIZED |
| Singular Focus (`sage_singular_focus`) | Council Master | 8–11 damage at 93%; pierces a second foe; range 6.1; focus 2 self; damage 5 target; hold target | PINNED | LIFTED |
| Far Seeing (`sage_far_seeing`) | Council Master | Aura +17 ally aim / -9 enemy aim; range 6; reveal all enemies; +7 aim all allies; MARKED all enemies | ATTUNED | INSPIRED |
| Force Maelstrom (`sage_grand_maelstrom`) | Grand Master | Area 10–13 damage; breaks 10 cover; range 8; damage 8 area enemies; LIFTED area enemies; hold area enemies; once per mission | LIFTED | PINNED |

Grand Master signature: Force Maelstrom hits a distant area hard, lifts it, and holds survivors.

### Consular

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Battle Meditation (`consular_battle_meditation`) | Padawan I | Aura +5 ally aim / -3 enemy aim; range 3; focus 1 all allies | INSPIRED | READY |
| Gentle Touch (`consular_gentle_touch`) | Padawan II | Heal 3; revive 2; range 4; cleanse target | SHIELDED | BURNING |
| Open Mind (`consular_open_mind`) | Padawan II | Ally +10 aim, +11 defense; range 4; focus 1 target | ATTUNED | SHIELDED |
| Renewal (`consular_renewal`) | Knight I | Heal 4; revive 2; range 4; cleanse target; shield 2 target | INSPIRED | BURNING |
| Mind Trick (`consular_mind_trick`) | Knight I | tricked at 73%; range 4; focus 1 self | STAGGERED | STAGGERED |
| Healing Current (`consular_healing_current`) | Knight II | Squad heal 5; range 5; cleanse all allies | SHIELDED | INSPIRED |
| Diplomatic Pressure (`consular_diplomatic_pressure`) | Knight II | suppressed at 78%; range 5; +3 aim all allies; EXPOSED target | EXPOSED | STAGGERED |
| Force Sanctuary (`consular_force_sanctuary`) | Master I | Aura +13 ally aim / -7 enemy aim; range 5; shield 4 all allies; focus 1 all allies | SHIELDED | READY |
| Persuasion (`consular_persuasion`) | Master I | suppressed at 83%; range 5; disarm target; focus 1 self | TAUNTED | EXPOSED |
| Life Weave (`consular_life_weave`) | Master II | Heal 7; revive 4; range 6; cleanse target; shield 5 target; focus 1 target | ATTUNED | SHIELDED |
| Pacifying Word (`consular_pacifying_word`) | Master II | stunned at 88%; range 6; disarm target; heal 2 all allies | PINNED | STAGGERED |
| Circle of Life (`consular_circle_of_life`) | Council Master | Squad heal 8; range 6; cleanse all allies; shield 4 all allies | INSPIRED | ATTUNED |
| Accord of Minds (`consular_accord_of_minds`) | Council Master | Aura +18 ally aim / -9 enemy aim; range 6; focus 2 all allies; ATTUNED all allies | ATTUNED | INSPIRED |
| Living Force (`consular_grand_living_force`) | Grand Master | Squad heal 12; range 8; heal 12 all allies; cleanse all allies; INSPIRED all allies; shield 6 all allies; once per mission | SHIELDED | BURNING |

Grand Master signature: Living Force heals the whole squad, removes disabling conditions, inspires, and shields.

### Sentinel

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Force Cloak (`sentinel_force_cloak`) | Padawan I | Leap to tile, cloak, next strike aim +12; range 3; reveal area enemies | ATTUNED | READY |
| Shadow Mark (`sentinel_shadow_mark`) | Padawan II | marked at 68%; range 4; reveal target; EXPOSED target | MARKED | EXPOSED |
| Watchman’s Eye (`sentinel_watchmans_eye`) | Padawan II | Ally +10 aim, +11 defense; range 4; reveal all enemies; shield 2 target | READY | INSPIRED |
| Silent Strike (`sentinel_silent_strike`) | Knight I | 4–5 damage at 81%; range 4.9; damage 2 target; reveal target | EXPOSED | MARKED |
| Sabotage (`sentinel_sabotage`) | Knight I | suppressed at 73%; range 4; disarm target; IONIZED target | IONIZED | STAGGERED |
| Hidden Blade (`sentinel_hidden_blade`) | Knight II | 5–8 damage at 84%; range 5.2; damage 3 target; disarm target | STAGGERED | MARKED |
| Tracking Pulse (`sentinel_tracking_pulse`) | Knight II | marked at 78%; range 5; reveal all enemies; MARKED all enemies | MARKED | PINNED |
| Veiled Assault (`sentinel_veiled_assault`) | Master I | 6–8 damage at 87%; range 5.5; damage 4 target; shield 2 self | EXPOSED | STAGGERED |
| Vigilant Net (`sentinel_vigilant_net`) | Master I | stunned at 83%; range 5; hold target; reveal all enemies | PINNED | EXPOSED |
| Phantom Circuit (`sentinel_phantom_circuit`) | Master II | 7–8 damage at 90%; pierces a second foe; range 5.8; damage 3 target; IONIZED target; shield 2 self | IONIZED | MARKED |
| Relentless Watch (`sentinel_relentless_watch`) | Master II | Aura +15 ally aim / -8 enemy aim; range 6; reveal all enemies; +6 aim all allies | READY | INSPIRED |
| Midnight Verdict (`sentinel_midnight_verdict`) | Council Master | 8–11 damage at 93%; pierces a second foe; range 6.1; damage 5 target; disarm target; reveal target | STAGGERED | PINNED |
| Unseen Tribunal (`sentinel_unseen_tribunal`) | Council Master | 7–9 damage at 93%; range 6.1; damage 4 target; EXPOSED all enemies; reveal all enemies | EXPOSED | MARKED |
| Eclipse (`sentinel_grand_eclipse`) | Grand Master | Reveal all enemies; MARKED and disarm all enemies; +15 aim all allies; once per mission | IONIZED | EXPOSED |

Grand Master signature: Eclipse exposes every enemy, marks them, disarms them, and raises allied aim.

### Wayseeker

| Ability | Rank | Executed effect | Applies | Consumes |
|---|---|---|---|---|
| Tremor (`wayseeker_tremor`) | Padawan I | Area 1–2 damage; breaks 2 cover; range 3; hold area enemies | STAGGERED | PINNED |
| Root Snare (`wayseeker_root_snare`) | Padawan II | stunned at 68%; range 4; hold target; shield 1 self | PINNED | STAGGERED |
| Shelter Stone (`wayseeker_shelter_stone`) | Padawan II | Ally +10 aim, +11 defense; range 4; shield 4 target | SHIELDED | READY |
| Fault Line (`wayseeker_fault_line`) | Knight I | Area 2–4 damage; breaks 4 cover; range 4; hold area enemies; shield 2 self | EXPOSED | PINNED |
| Beastcall (`wayseeker_beastcall`) | Knight I | suppressed at 73%; range 4; TAUNTED all enemies; shield 2 all allies | TAUNTED | MARKED |
| Grasping Earth (`wayseeker_grasping_earth`) | Knight II | Pull 2 tiles; 4 collision damage; range 5; hold target; shield 3 self | PINNED | LIFTED |
| Pack Ward (`wayseeker_pack_ward`) | Knight II | Aura +11 ally aim / -6 enemy aim; range 5; shield 4 all allies; READY all allies | SHIELDED | INSPIRED |
| Quake Burst (`wayseeker_quake_burst`) | Master I | Wave 5 damage, 65% stun; range 4.5; hold all enemies; damage 2 target | STAGGERED | BURNING |
| Wild Pursuit (`wayseeker_wild_pursuit`) | Master I | 5–9 damage at 87%; range 5.5; damage 2 target; action 1 self; PINNED target | MARKED | PINNED |
| Rising Shelf (`wayseeker_rising_shelf`) | Master II | stunned at 88%; range 6; hold target; LIFTED target; shield 2 all allies | LIFTED | STAGGERED |
| Guardian Roar (`wayseeker_guardian_roar`) | Master II | Aura +15 ally aim / -8 enemy aim; range 6; TAUNTED all enemies; +7 defense all allies | INSPIRED | SHIELDED |
| Worldroot (`wayseeker_worldroot`) | Council Master | Area 6–8 damage; breaks 8 cover; range 6; hold area enemies; shield 5 all allies; PINNED area enemies | PINNED | EXPOSED |
| Alpha Bond (`wayseeker_alpha_bond`) | Council Master | Aura +17 ally aim / -9 enemy aim; range 6; shield 7 all allies; +5 aim all allies; INSPIRED all allies | ATTUNED | READY |
| Living Mountain (`wayseeker_grand_living_mountain`) | Grand Master | Area 8–10 damage; breaks 10 cover; range 7; damage 6 area enemies; hold all enemies; shield 12 all allies; PINNED all enemies; once per mission | STAGGERED | LIFTED |

Grand Master signature: Living Mountain shatters ground, roots and pins enemies, and shelters the squad.

## Implementation and balance

- New riders use the shared effect resolver plus `effects_jedi.gd` for cleanse, reveal, boosts, disarm, hold, guard reaction watch, and kill jumping. Existing shipped definitions are unchanged.
- All seven Grand Master choices carry `once_per_mission` metadata and a mission-length 1,000,000,000-turn lockout. Their short battle button labels and full promotion names both include “Once per mission”. The current HUD paints a numeric lockout over a used button; that HUD belongs to the separate lane.
- Mechanical signatures compare effect kind, target, numeric fields, status, and executable riders from JSON. They exclude names, rank, prose, and chain tags. A second structural comparison also ignores numeric tuning: all 98 new abilities still differ.
- Padawan remains below a fresh soldier; Master and Grand Master retain the W17 power curve. Each path applies and consumes at least three shared tags.

## Verification

- Headless import: exit 0. `./godot/test.sh`: exit 0, zero `SCRIPT ERROR`, every suite at zero failures, Normal rescue 9/20. `jedi18_test`: 776 checks, 0 failures.
- [Sage promotion, 844×390](jedi/promotion-sage-844x390.png); [Guardian promotion, 844×390](jedi/promotion-guardian-844x390.png); [Guardian narrow check, 667×375](jedi/promotion-guardian-667x375.png); [Once-per-mission battle button](jedi/battle-consular-grand-button.png); [Living Force firing in battle](jedi/battle-consular-living-force.png).
- Logs: `/home/jess/projects/tw-logs/w18/jedi/`.

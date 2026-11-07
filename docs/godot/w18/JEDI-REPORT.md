# Wave 18 Jedi paths

Seven playable Jedi paths have 13 rank 1–7 choices and one rank 8 Grand Master signature each. The 49 shipped Jedi definitions retain their IDs and values. Knight, Duelist, and Sage now have tactical templates, campaign stats, kits, and promotion trees.

## Ability tables

Tags listed below are the `chain` tags applied and consumed; consuming a tag grants its listed bonus in the class JSON and advances squad Momentum. Ally and enemy scopes use the shared W17 tag vocabulary.

### Guardian

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Deflect (`guardian_deflect`) | Padawan I | Guard with +12 defense | SHIELDED | READY |
| Challenging Glare (`guardian_challenging_glare`) | Padawan II | Suppressed attempt, 68% chance, 4 range | TAUNTED | MARKED |
| Brace (`guardian_brace`) | Padawan II | Guard with +16 defense | SHIELDED | INSPIRED |
| Soresu Circle (`guardian_soresu_circle`) | Knight I | Aura: allies +9 aim; foes -5 aim | SHIELDED | SHIELDED |
| Djem So Riposte (`guardian_djem_so_riposte`) | Knight I | Attack 3–6 damage, 81% hit, 1.5 range | STAGGERED | PINNED |
| Interpose (`guardian_interpose`) | Knight II | Grant +16 aim and +17 defense for one turn | SHIELDED | SHIELDED |
| Breaking Parry (`guardian_breaking_parry`) | Knight II | Attack 4–6 damage, 84% hit, 1.5 range | EXPOSED | TAUNTED |
| Living Rampart (`guardian_living_rampart`) | Master I | Aura: allies +13 aim; foes -7 aim | INSPIRED | READY |
| Hammer Return (`guardian_hammer_return`) | Master I | Attack 5–9 damage, 87% hit, 1.5 range | STAGGERED | EXPOSED |
| Bastion Wave (`guardian_bastion_wave`) | Master II | Force wave for 6 damage; 71% stun chance | STAGGERED | LIFTED |
| Sundering Counter (`guardian_sundering_counter`) | Master II | Attack 6–9 damage, 90% hit, 1.5 range | PINNED | STAGGERED |
| Citadel Oath (`guardian_citadel_oath`) | Council Master | Aura: allies +17 aim; foes -9 aim | SHIELDED | INSPIRED |
| Unyielding Judgment (`guardian_unyielding_judgment`) | Council Master | Attack 7–9 damage, 93% hit, 1.5 range | TAUNTED | MARKED |
| Grand Master Aegis (`guardian_grand_aegis`) | Grand Master | Aura: allies +19 aim; foes -10 aim; 99-turn cooldown | SHIELDED | SHIELDED |

### Knight

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Form Switch (`knight_form_switch`) | Padawan I | Free stance swap: Force Adept +8 aim or Shii-Cho +8 defense; 2-turn cooldown | ATTUNED | INSPIRED |
| Opening Form (`knight_opening_form`) | Padawan II | Attack 3–5 damage, 78% hit, 4.6 range | EXPOSED | MARKED |
| Centered Breath (`knight_centered_breath`) | Padawan II | Recover 2 Focus | ATTUNED | SHIELDED |
| Vanguard Advance (`knight_vanguard_advance`) | Knight I | Attack 4–5 damage, 81% hit, 4.9 range | STAGGERED | EXPOSED |
| Force Balance (`knight_force_balance`) | Knight I | Move foe 2 tiles; 3 collision damage | PINNED | LIFTED |
| Sweeping Form (`knight_sweeping_form`) | Knight II | Attack 5–8 damage, 84% hit, 5.2 range | STAGGERED | PINNED |
| Force Channel (`knight_force_channel`) | Knight II | Recover 3 Focus | INSPIRED | ATTUNED |
| Rallying Stance (`knight_rallying_stance`) | Master I | Aura: allies +13 aim; foes -7 aim | READY | INSPIRED |
| Force Lash (`knight_force_lash`) | Master I | Attack 5–9 damage, 87% hit, 5.5 range | EXPOSED | PINNED |
| Balanced Assault (`knight_balanced_assault`) | Master II | Attack 7–8 damage, 90% hit, 5.8 range | MARKED | STAGGERED |
| Focus Exchange (`knight_focus_exchange`) | Master II | Grant +22 aim and +23 defense for one turn | ATTUNED | SHIELDED |
| Unified Forms (`knight_unified_forms`) | Council Master | Aura: allies +17 aim; foes -9 aim | INSPIRED | READY |
| Adaptive Mastery (`knight_adaptive_mastery`) | Council Master | Attack 7–9 damage; consume one present tag for +3 damage, then stagger | STAGGERED | Any one present |
| Grand Master Convergence (`knight_grand_convergence`) | Grand Master | Aura: allies +19 aim; foes -10 aim; 99-turn cooldown | ATTUNED | INSPIRED |

### Duelist

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Kill Chain (`duelist_kill_chain`) | Padawan I | Attack 1–3 damage, 75% hit, 1.5 range; killing blow refunds 1 action once/turn | STAGGERED | EXPOSED |
| Vaulting Cut (`duelist_vaulting_cut`) | Padawan II | Attack 3–5 damage, 78% hit, 4.6 range | EXPOSED | STAGGERED |
| Duel Read (`duelist_duel_read`) | Padawan II | Marked attempt, 68% chance, 4 range | MARKED | PINNED |
| Ataru Leap (`duelist_ataru_leap`) | Knight I | Relocate and cloak; next strike +20 aim | ATTUNED | READY |
| Makashi Feint (`duelist_makashi_feint`) | Knight I | Stunned attempt, 73% chance, 4 range | STAGGERED | EXPOSED |
| Aerial Flurry (`duelist_aerial_flurry`) | Knight II | Attack 5–8 damage, 84% hit, 5.2 range | STAGGERED | LIFTED |
| Disarming Edge (`duelist_disarming_edge`) | Knight II | Attack 4–6 damage, 84% hit, 1.5 range | PINNED | MARKED |
| Whirling Reprisal (`duelist_whirling_reprisal`) | Master I | Force wave for 5 damage; 65% stun chance | STAGGERED | EXPOSED |
| Measured Lunge (`duelist_measured_lunge`) | Master I | Attack 5–9 damage, 87% hit, 1.5 range | EXPOSED | STAGGERED |
| Falling Star (`duelist_falling_star`) | Master II | Attack 7–8 damage, 90% hit, 5.8 range | MARKED | LIFTED |
| Perfect Riposte (`duelist_perfect_riposte`) | Master II | Guard with +32 defense | SHIELDED | INSPIRED |
| Cyclone Blade (`duelist_cyclone_blade`) | Council Master | Force wave for 7 damage; 77% stun chance | STAGGERED | PINNED |
| Final Measure (`duelist_final_measure`) | Council Master | Attack 7–9 damage, 93% hit, 1.5 range | EXPOSED | MARKED |
| Grand Master Thousand Cuts (`duelist_grand_thousand_cuts`) | Grand Master | Area blast 7–9 damage; breaks 9 cover; 99-turn cooldown | STAGGERED | EXPOSED |

### Sage

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Telekinetic Throw (`sage_telekinetic_throw`) | Padawan I | Attack 1–3 damage, 75% hit, 4.3 range; ignores cover | EXPOSED | PINNED |
| Lift (`sage_lift`) | Padawan II | Stunned attempt, 68% chance, 4 range | LIFTED | PINNED |
| Insight Mark (`sage_insight_mark`) | Padawan II | Marked attempt, 70% chance, 4 range | MARKED | EXPOSED |
| Force Cascade (`sage_force_cascade`) | Knight I | Force wave for 3 damage; 53% stun chance | EXPOSED | LIFTED |
| Seer Sight (`sage_seer_sight`) | Knight I | Grant +13 aim and +14 defense for one turn | ATTUNED | SHIELDED |
| Crushing Grip (`sage_crushing_grip`) | Knight II | Attack 5–8 damage, 84% hit, 5.2 range | PINNED | LIFTED |
| Premonition (`sage_premonition`) | Knight II | Aura: allies +11 aim; foes -6 aim | INSPIRED | READY |
| Shatterpoint (`sage_shatterpoint`) | Master I | Attack 6–8 damage, 87% hit, 5.5 range | EXPOSED | MARKED |
| Foresight (`sage_foresight`) | Master I | Marked attempt, 83% chance, 5 range | MARKED | STAGGERED |
| Gravity Well (`sage_gravity_well`) | Master II | Area blast 5–7 damage; breaks 7 cover | LIFTED | PINNED |
| Psychic Lance (`sage_psychic_lance`) | Master II | Attack 6–9 damage, 90% hit, 5.8 range | STAGGERED | IONIZED |
| Singular Focus (`sage_singular_focus`) | Council Master | Attack 8–11 damage, 93% hit, 6.1 range | PINNED | LIFTED |
| Far Seeing (`sage_far_seeing`) | Council Master | Aura: allies +17 aim; foes -9 aim | ATTUNED | INSPIRED |
| Grand Master Force Maelstrom (`sage_grand_maelstrom`) | Grand Master | Area blast 7–9 damage; breaks 9 cover; 99-turn cooldown | LIFTED | PINNED |

### Consular

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Battle Meditation (`consular_battle_meditation`) | Padawan I | Aura: allies +5 aim; foes -3 aim | INSPIRED | READY |
| Gentle Touch (`consular_gentle_touch`) | Padawan II | Heal 3 or revive for 2 HP | SHIELDED | BURNING |
| Open Mind (`consular_open_mind`) | Padawan II | Grant +10 aim and +11 defense for one turn | ATTUNED | SHIELDED |
| Renewal (`consular_renewal`) | Knight I | Heal 4 or revive for 2 HP | INSPIRED | BURNING |
| Mind Trick (`consular_mind_trick`) | Knight I | Trick a staggered foe, 73% chance, 4 range; recover 1 Focus | STAGGERED | STAGGERED |
| Healing Current (`consular_healing_current`) | Knight II | Heal allies in 5 range for 5 HP | SHIELDED | INSPIRED |
| Diplomatic Pressure (`consular_diplomatic_pressure`) | Knight II | Suppressed attempt, 78% chance, 5 range | EXPOSED | STAGGERED |
| Force Sanctuary (`consular_force_sanctuary`) | Master I | Aura: allies +13 aim; foes -7 aim | SHIELDED | READY |
| Persuasion (`consular_persuasion`) | Master I | Suppressed attempt, 83% chance, 5 range | TAUNTED | EXPOSED |
| Life Weave (`consular_life_weave`) | Master II | Heal 7 or revive for 4 HP | ATTUNED | SHIELDED |
| Pacifying Word (`consular_pacifying_word`) | Master II | Stunned attempt, 88% chance, 6 range | PINNED | STAGGERED |
| Circle of Life (`consular_circle_of_life`) | Council Master | Heal allies in 6 range for 8 HP | INSPIRED | ATTUNED |
| Accord of Minds (`consular_accord_of_minds`) | Council Master | Aura: allies +18 aim; foes -9 aim | ATTUNED | INSPIRED |
| Grand Master Living Force (`consular_grand_living_force`) | Grand Master | Heal allies in 7 range for 9 HP; 99-turn cooldown | SHIELDED | BURNING |

### Sentinel

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Force Cloak (`sentinel_force_cloak`) | Padawan I | Relocate and cloak; next strike +12 aim | ATTUNED | READY |
| Shadow Mark (`sentinel_shadow_mark`) | Padawan II | Marked attempt, 68% chance, 4 range | MARKED | EXPOSED |
| Watchman’s Eye (`sentinel_watchmans_eye`) | Padawan II | Grant +10 aim and +11 defense for one turn | READY | INSPIRED |
| Silent Strike (`sentinel_silent_strike`) | Knight I | Attack 4–5 damage, 81% hit, 4.9 range | EXPOSED | MARKED |
| Sabotage (`sentinel_sabotage`) | Knight I | Suppressed attempt, 73% chance, 4 range | IONIZED | STAGGERED |
| Hidden Blade (`sentinel_hidden_blade`) | Knight II | Attack 5–8 damage, 84% hit, 5.2 range | STAGGERED | MARKED |
| Tracking Pulse (`sentinel_tracking_pulse`) | Knight II | Marked attempt, 78% chance, 5 range | MARKED | PINNED |
| Veiled Assault (`sentinel_veiled_assault`) | Master I | Attack 6–8 damage, 87% hit, 5.5 range | EXPOSED | STAGGERED |
| Vigilant Net (`sentinel_vigilant_net`) | Master I | Stunned attempt, 83% chance, 5 range | PINNED | EXPOSED |
| Phantom Circuit (`sentinel_phantom_circuit`) | Master II | Attack 7–8 damage, 90% hit, 5.8 range | IONIZED | MARKED |
| Relentless Watch (`sentinel_relentless_watch`) | Master II | Aura: allies +15 aim; foes -8 aim | READY | INSPIRED |
| Midnight Verdict (`sentinel_midnight_verdict`) | Council Master | Attack 8–11 damage, 93% hit, 6.1 range | STAGGERED | PINNED |
| Unseen Tribunal (`sentinel_unseen_tribunal`) | Council Master | Attack 7–9 damage, 93% hit, 6.1 range | EXPOSED | MARKED |
| Grand Master Eclipse (`sentinel_grand_eclipse`) | Grand Master | Area blast 7–9 damage; breaks 9 cover; 99-turn cooldown | IONIZED | EXPOSED |

### Wayseeker

| Ability | Rank | Effect | Applies | Consumes |
|---|---|---|---|---|
| Tremor (`wayseeker_tremor`) | Padawan I | Area blast 1–2 damage; breaks 2 cover | STAGGERED | PINNED |
| Root Snare (`wayseeker_root_snare`) | Padawan II | Stunned attempt, 68% chance, 4 range | PINNED | STAGGERED |
| Shelter Stone (`wayseeker_shelter_stone`) | Padawan II | Grant +10 aim and +11 defense for one turn | SHIELDED | READY |
| Fault Line (`wayseeker_fault_line`) | Knight I | Area blast 2–4 damage; breaks 4 cover | EXPOSED | PINNED |
| Beastcall (`wayseeker_beastcall`) | Knight I | Suppressed attempt, 73% chance, 4 range | TAUNTED | MARKED |
| Grasping Earth (`wayseeker_grasping_earth`) | Knight II | Move foe 2 tiles; 4 collision damage | PINNED | LIFTED |
| Pack Ward (`wayseeker_pack_ward`) | Knight II | Aura: allies +11 aim; foes -6 aim | SHIELDED | INSPIRED |
| Quake Burst (`wayseeker_quake_burst`) | Master I | Force wave for 5 damage; 65% stun chance | STAGGERED | BURNING |
| Wild Pursuit (`wayseeker_wild_pursuit`) | Master I | Attack 5–9 damage, 87% hit, 5.5 range | MARKED | PINNED |
| Rising Shelf (`wayseeker_rising_shelf`) | Master II | Stunned attempt, 88% chance, 6 range | LIFTED | STAGGERED |
| Guardian Roar (`wayseeker_guardian_roar`) | Master II | Aura: allies +15 aim; foes -8 aim | INSPIRED | SHIELDED |
| Worldroot (`wayseeker_worldroot`) | Council Master | Area blast 6–8 damage; breaks 8 cover | PINNED | EXPOSED |
| Alpha Bond (`wayseeker_alpha_bond`) | Council Master | Aura: allies +17 aim; foes -9 aim | ATTUNED | READY |
| Grand Master Living Mountain (`wayseeker_grand_living_mountain`) | Grand Master | Area blast 7–9 damage; breaks 9 cover; 99-turn cooldown | STAGGERED | LIFTED |

## New effect types

`kill_refund`, `stance_switch`, and `adaptive_consume` live in `godot/scripts/effects_jedi.gd` and are called through one fallback registration line in `ability_chains.gd`. Kill Chain grants one action on a killing blow, once per turn. Form Switch changes between Force Adept aim and Shii-Cho defense. Adaptive Mastery consumes one tag that was already present before it applies STAGGERED. Other abilities use existing native effects and shared chain effects.

## Balance and compatibility

- Rank power stays at Padawan 50–70 versus fresh soldier 100, Knight 90–140, Master 260–300, Council Master 340, and Grand Master 420. The base rank table remains owned by core.
- Grand Master signatures are large area or squad effects with a 99-turn cooldown and primary-only capstone flag. Rank 7 abilities are also primary-only.
- New IDs use path prefixes. Nineteen shared legacy IDs already occur in multiple class files with identical definitions, including soldier files outside this lane. The new test rejects any new duplicate or conflicting definition across all 15 files.
- The promotion tree offers one rank 1 signature, two rank 2 choices, one choice per branch at ranks 3–7, and the shared path Grand Master choice at rank 8. Cross-training remains governed by core rank caps.

## Verification

- `jedi18_test`: 653 checks, 0 failures in the final full-suite run. It verifies schemas, 13+1 counts, shared tags, new effect signatures, shipped Jedi definitions, rank curve, cross-path chains, and Kill Chain.
- Headless import: exit 0. `./godot/test.sh`: exit 0, zero `SCRIPT ERROR`, every suite zero failures, Normal rescue 9/20.
- [Sage promotion, 844×390](jedi/promotion-sage-844x390.png); [Guardian promotion, 844×390](jedi/promotion-guardian-844x390.png); [Guardian Deflect in battle](jedi/battle-guardian-deflect.png).
- Run logs: `/home/jess/projects/tw-logs/w18/jedi/`.

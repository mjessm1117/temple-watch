# Wave 18 soldier classes

Eight soldier paths contain 13 abilities each (104 definitions). New IDs use their class prefix. Shipped Trooper, Scout, and Medic ability IDs and original fields are unchanged; rank and capstone metadata place them in the new trees. Rank 7 choices are primary-class capstones.

## Soldier — Armor and explosives

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Thermal Detonator (`trooper_thermal_detonator`) | 1 | Area blast 4–5; cover 5 | EXPOSED | MARKED |
| Suppress (`suppress`) | 2 | Suppressed target (100% chance) | — | — |
| Rapid Fire (`rapidFire`) | 2 | Weapon shot | — | — |
| Breach Charge (`trooper_breach_charge`) | 3 | Area blast 2–3; cover 3 | PINNED | MARKED |
| Hunker Down (`hunker`) | 3 | Hunker for 30 defense | — | — |
| Rally (`rally`) | 4 | Buff allies within 4 tiles | — | — |
| Armor Piercer (`trooper_armor_piercer`) | 4 | Weapon shot +3 damage | EXPOSED | STAGGERED |
| Firebreak (`trooper_firebreak`) | 5 | Area blast 3–4; cover 5 | BURNING | STAGGERED |
| Shoot (`shoot`) | 5 | Weapon shot | — | — |
| Overwatch (`overwatch`) | 6 | Set overwatch stance | — | — |
| Counter Barrage (`trooper_counter_barrage`) | 6 | Weapon shot +4 damage | STAGGERED | STAGGERED |
| Assault Storm (`trooper_assault_storm`) | 7 | Area blast 4–5; cover 7 | IONIZED | STAGGERED |
| Grenadier Finale (`trooper_grenadier_finale`) | 7 | Area blast 5–6; cover 8 | EXPOSED | IONIZED |

## Heavy — Tank and explosives

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Rocket (`heavy_rocket`) | 1 | Area blast 5–7; cover 6 | EXPOSED | IONIZED |
| Breaching Shell (`heavy_breaching_shell`) | 2 | Area blast 2–3; cover 2 | BURNING | IONIZED |
| Shield Wall (`heavy_shield_wall`) | 2 | Buff allies within 3 tiles | SHIELDED | ATTUNED |
| Shrapnel Net (`heavy_shrapnel_net`) | 3 | Area blast 2–3; cover 3 | PINNED | IONIZED |
| Juggernaut Push (`heavy_juggernaut_push`) | 3 | Marked target (74% chance) | IONIZED | IONIZED |
| Demolition Line (`heavy_demolition_line`) | 4 | Area blast 3–4; cover 4 | EXPOSED | PINNED |
| Armor Lock (`heavy_armor_lock`) | 4 | Set overwatch stance | ATTUNED | READY |
| Ion Buster (`heavy_ion_buster`) | 5 | Area blast 3–4; cover 5 | BURNING | PINNED |
| Fortress Fire (`heavy_fortress_fire`) | 5 | Weapon shot +3 damage | MARKED | PINNED |
| Siege Breaker (`heavy_siege_breaker`) | 6 | Area blast 4–5; cover 6 | STAGGERED | PINNED |
| Body Block (`heavy_body_block`) | 6 | Give ally 5 shield | ATTUNED | INSPIRED |
| Armageddon (`heavy_armageddon`) | 7 | Area blast 4–5; cover 7 | EXPOSED | EXPOSED |
| Unbroken (`heavy_unbroken`) | 7 | Buff allies within 5 tiles | SHIELDED | SHIELDED |

## Sniper — Long range

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Squadsight (`sniper_squadsight`) | 1 | Weapon shot +2 damage at extended sight | MARKED | LIFTED |
| Spotter Round (`sniper_spotter_round`) | 2 | Marked target (71% chance) | MARKED | EXPOSED |
| Quickdraw (`sniper_quickdraw`) | 2 | Weapon shot +1 damage | STAGGERED | EXPOSED |
| Dead Eye (`sniper_dead_eye`) | 3 | Weapon shot +2 damage | IONIZED | EXPOSED |
| Cover Splitter (`sniper_cover_splitter`) | 3 | Weapon shot +2 damage | EXPOSED | LIFTED |
| Eagle Perch (`sniper_eagle_perch`) | 4 | Set overwatch stance | READY | ATTUNED |
| Crossfire (`sniper_crossfire`) | 4 | Weapon shot +3 damage | BURNING | LIFTED |
| Gravity Sight (`sniper_gravity_sight`) | 5 | Weapon shot +3 damage | MARKED | LIFTED |
| Ricochet (`sniper_ricochet`) | 5 | Weapon shot +3 damage | STAGGERED | LIFTED |
| Execution Order (`sniper_execution_order`) | 6 | Weapon shot +4 damage | IONIZED | LIFTED |
| Duel Trigger (`sniper_duel_trigger`) | 6 | Weapon shot +4 damage | EXPOSED | MARKED |
| One Shot (`sniper_one_shot`) | 7 | Weapon shot +4 damage | PINNED | MARKED |
| Hail of Lead (`sniper_hail_of_lead`) | 7 | Weapon shot +5 damage | BURNING | MARKED |

## Scout — Sneak and damage

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Concealment (`scout_concealment`) | 1 | Enter concealment | READY | SHIELDED |
| Mark (`mark`) | 2 | Marked target (100% chance) | — | — |
| Run & Gun (`runGun`) | 2 | Ap | — | — |
| Vanish (`scout_vanish`) | 3 | Enter concealment | ATTUNED | INSPIRED |
| Deadeye (`deadeye`) | 3 | Weapon shot +3 damage | — | — |
| Spotter (`spotter`) | 4 | Squadsight | — | — |
| Ghost (`ghost`) | 4 | Reconceal | — | — |
| Snipe (`snipe`) | 5 | Weapon shot +2 damage | — | — |
| Hunker Down (`hunker`) | 5 | Hunker for 30 defense | — | — |
| Shoot (`shoot`) | 6 | Weapon shot | — | — |
| Overwatch (`overwatch`) | 6 | Set overwatch stance | — | — |
| Saboteur Trap (`scout_saboteur_trap`) | 7 | Area blast 4–5; cover 7 | MARKED | STAGGERED |
| Ambush (`scout_ambush`) | 7 | Weapon shot +4 damage | EXPOSED | STAGGERED, EXPOSED, MARKED |

## Medic — Healer

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Bacta Spray (`medic_bacta_spray`) | 1 | Heal allies within 3 tiles by 3 | INSPIRED, SHIELDED, READY | BURNING, STAGGERED, PINNED |
| Medkit (`heal`) | 2 | Heal 4 HP; revive 2 | — | — |
| Revive Stim (`reviveStim`) | 2 | Heal 2 HP; revive 2 | — | — |
| Toxin Dart (`medic_toxin_dart`) | 3 | Stunned target (75% chance) | STAGGERED, EXPOSED, IONIZED | MARKED, PINNED, BURNING |
| Smoke (`smoke`) | 3 | Smoke grants cover defense | — | — |
| Hack (`hack`) | 4 | Open nearby consoles | — | — |
| Combat Protocol (`protocol`) | 4 | Weapon shot at extended sight | — | — |
| Shield Drone (`shieldDrone`) | 5 | Give ally 4 shield | — | — |
| Scan Clue (`scan`) | 5 | Scan mission clue | — | — |
| Shoot (`shoot`) | 6 | Weapon shot | — | — |
| Overwatch (`overwatch`) | 6 | Set overwatch stance | — | — |
| Med Beacon (`medBeacon`) | 7 | Heal allies within 3 tiles by 2 | — | — |
| Hack Droid (`hackDroid`) | 7 | Stunned target (60% chance) | — | — |

## Tech — Engineer

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Probe Droid (`tech_probe_droid`) | 1 | Weapon shot +1 damage at extended sight; tech damage | IONIZED | EXPOSED |
| EMP Burst (`tech_emp_burst`) | 2 | Area blast 2–3; cover 2 | IONIZED | LIFTED |
| Remote Shield (`tech_remote_shield`) | 2 | Give ally 2 shield | SHIELDED | READY |
| Slicer Ping (`tech_slicer_ping`) | 3 | Stunned target (73% chance) | BURNING | LIFTED |
| Turret Pin (`tech_turret_pin`) | 3 | Weapon shot +2 damage; tech damage | PINNED | LIFTED |
| Override (`tech_override`) | 4 | Stunned target (90% chance) | STAGGERED | IONIZED |
| Field Repair (`tech_field_repair`) | 4 | Give ally 4 shield | ATTUNED | INSPIRED |
| Ion Spike (`tech_ion_spike`) | 5 | Weapon shot +3 damage; tech damage | EXPOSED | MARKED |
| Barrier Grid (`tech_barrier_grid`) | 5 | Buff allies within 4 tiles | SHIELDED | SHIELDED |
| Signal Jam (`tech_signal_jam`) | 6 | Stunned target (79% chance) | BURNING | MARKED |
| Drone Relay (`tech_drone_relay`) | 6 | Give ally 5 shield | ATTUNED | SHIELDED |
| Total Shutdown (`tech_total_shutdown`) | 7 | Area blast 4–5; cover 7 | STAGGERED | MARKED |
| Engineer Network (`tech_engineer_network`) | 7 | Buff allies within 5 tiles | SHIELDED | ATTUNED |

## Droid — Modules

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Rebuild (`droid_rebuild`) | 1 | Restore 4 HP and 2 shield | READY | ATTUNED |
| Repeater Module (`droid_repeater_module`) | 2 | Weapon shot +1 damage | PINNED | STAGGERED |
| Shield Module (`droid_shield_module`) | 2 | Give ally 2 shield | SHIELDED | READY |
| Sensor Module (`droid_sensor_module`) | 3 | Stunned target (73% chance) | MARKED | STAGGERED |
| Jetpack Module (`droid_jetpack_module`) | 3 | Leap | EXPOSED | PINNED |
| Flamer Module (`droid_flamer_module`) | 4 | Area blast 3–4; cover 4 | BURNING | IONIZED |
| Med Module (`droid_med_module`) | 4 | Give ally 4 shield | INSPIRED | INSPIRED |
| Targeting Protocol (`droid_targeting_protocol`) | 5 | Weapon shot +3 damage | PINNED | MARKED |
| Servo Lock (`droid_servo_lock`) | 5 | Suppressed target (78% chance) | BURNING | IONIZED |
| Reactive Plate (`droid_reactive_plate`) | 6 | Set overwatch stance | ATTUNED | INSPIRED |
| Ion Relay (`droid_ion_relay`) | 6 | Weapon shot +4 damage | STAGGERED | IONIZED |
| Omni Frame (`droid_omni_frame`) | 7 | Buff allies within 5 tiles | SHIELDED | SHIELDED |
| Core Overload (`droid_core_overload`) | 7 | Area blast 5–6; cover 8 | EXPOSED | PINNED |

## Officer — Command

| Ability | Rank | Effect | Applies | Consumes |
|---|---:|---|---|---|
| Take That Shot (`officer_take_that_shot`) | 1 | Give ally one action | ATTUNED | SHIELDED |
| Command Mark (`officer_command_mark`) | 2 | Marked target (71% chance) | MARKED | PINNED |
| Rally Line (`officer_rally_line`) | 2 | Buff allies within 3 tiles | INSPIRED | ATTUNED |
| Coordinated Fire (`officer_coordinated_fire`) | 3 | Weapon shot +2 damage | STAGGERED | MARKED |
| Fallback Order (`officer_fallback_order`) | 3 | Give ally 3 shield | ATTUNED | ATTUNED |
| Ready Signal (`officer_ready_signal`) | 4 | Buff allies within 4 tiles | READY | READY |
| Tactical Feint (`officer_tactical_feint`) | 4 | Stunned target (76% chance) | PINNED | EXPOSED |
| Focus Fire (`officer_focus_fire`) | 5 | Weapon shot +3 damage | BURNING | EXPOSED |
| Hold Fast (`officer_hold_fast`) | 5 | Buff allies within 4 tiles | ATTUNED | READY |
| Battle Plan (`officer_battle_plan`) | 6 | Give ally 5 shield | INSPIRED | INSPIRED |
| Counter Order (`officer_counter_order`) | 6 | Weapon shot +4 damage | IONIZED | EXPOSED |
| Full Assault (`officer_full_assault`) | 7 | Buff allies within 5 tiles | READY | INSPIRED |
| Perfect Command (`officer_perfect_command`) | 7 | Give ally one action | ATTUNED | INSPIRED |

## Droid modules

Three slots start with Repeater, Shield, and Sensor. The six choices are Repeater (PINNED fire), Shield (SHIELDED support), Sensor (MARKED targeting), Jetpack (mobility and EXPOSED setup), Flamer (BURNING area fire), and Med (healing). The module helper maps each selection to its tactical ability, rejects duplicate slots, and persists choices in the campaign save. Promotion-screen selection and loadout application await the requested file-lease extension. Heavy campaign deployment likewise needs the class-kind lookup in `battle_bridge.gd`. Scout Concealment and Vanish need the one-line exemption in `mission.gd` to survive the shared post-ability reset. Rebuild keeps a lethal hit at 1 HP and restores health when used.

## Effects and balance

- No new effect type was needed. `effects_soldier.gd` adds the Droid lethal-damage rule and module selection helper; `ability_chains.gd` has one hook. Tech Override currently stuns a Droid; actual allegiance control needs a new effect and engine hook beyond the current lease.
- Rank power remains 100 for a Recruit, 50 for a Padawan, 90 for an early Knight, 220 for a Commander, and 260 for a Master. The new class kits start with a signature and two class actions. Trooper, Scout, and Medic retain their fixed-battle kits until campaign-only starter additions can be wired in `combat_loadout.gd`; rank 7 capstones retain the Master advantage.
- Existing Trooper, Scout, and Medic abilities retain their IDs and all shipped fields and numbers. A 26-definition fixture in `soldier18_shipped.json` checks every original field.
- The inherited class files already share 12 legacy ability IDs across the 15 classes. Those IDs must remain for saved units and the shipped-ability requirement. All new soldier IDs and new effect signatures are unique.

## Verification

- Headless import: exit 0, no script errors.
- Soldier suite: 457 checks, 0 failures, including Tech→Heavy and Officer→Scout chains.
- Legacy combat: 394 checks, 0 failures; Normal rescue 9/20. Missions11: 156 checks, 0 failures; Normal rescue 9/20.
- The full `test.sh` run stopped at Cine15 Low: 93 draws against its 85-call ceiling. Restoring the fixed-battle kits brought isolated Cine15 to 19 checks, 0 failures. Every later suite passed when run directly. The remaining full-gate blocker is W17 core: 22 exact-equality assertions for added rank metadata and replacement proxy kits. No `SCRIPT ERROR` occurred.

## Captures

- [Sniper promotion](soldier/promotion-sniper-844x390.png)
- [Droid promotion before module controls](soldier/promotion-droid-844x390.png)
- [Squadsight battle frame](soldier/battle-sniper-squadsight-844x390.png)

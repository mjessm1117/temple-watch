# Wave 18 soldier classes

Eight paths have 104 definitions. The 78 class-prefixed abilities have 78 distinct mechanical signatures computed from effect types, scopes, numbers, range, cooldown, and status, excluding tag names. Soldier rank 1 is power 100; Padawan is 50; Master is 260. Shipped legacy IDs and their original fields remain intact.

## Abilities

### Trooper — Armor and explosives

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Thermal Detonator (`trooper_thermal_detonator`) | 1 | Detonate cover and set the area on fire. | EXPOSED | MARKED |
| Suppress (`suppress`) | 2 | Legacy status with shipped values. | — | — |
| Rapid Fire (`rapidFire`) | 2 | Legacy attack with shipped values. | — | — |
| Breach Charge (`trooper_breach_charge`) | 3 | Breach cover and root enemies in the debris. | PINNED | MARKED |
| Hunker Down (`hunker`) | 3 | Legacy hunker with shipped values. | — | — |
| Rally (`rally`) | 4 | Legacy aura with shipped values. | — | — |
| Armor Piercer (`trooper_armor_piercer`) | 4 | Pierce cover and continue through a second target. | EXPOSED | STAGGERED |
| Firebreak (`trooper_firebreak`) | 5 | Burn an area while the trooper braces behind armor. | BURNING | STAGGERED |
| Shoot (`shoot`) | 5 | Legacy attack with shipped values. | — | — |
| Overwatch (`overwatch`) | 6 | Legacy overwatch with shipped values. | — | — |
| Counter Barrage (`trooper_counter_barrage`) | 6 | Fire two counter rounds and a fragmentation hit. | STAGGERED | STAGGERED |
| Assault Storm (`trooper_assault_storm`) | 7 | Once per mission: Breach an area and release the assault squad. | IONIZED | STAGGERED |
| Grenadier Finale (`trooper_grenadier_finale`) | 7 | Once per mission: Risky inferno that roots surviving enemies. | EXPOSED | IONIZED |

### Heavy — Tank and siege

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Rocket (`heavy_rocket`) | 1 | Rocket doubles into ionized armor and strips reactions. | EXPOSED | IONIZED |
| Breaching Shell (`heavy_breaching_shell`) | 2 | Blast cover, interrupt overwatch, and brace the gunner. | BURNING | IONIZED |
| Shield Wall (`heavy_shield_wall`) | 2 | Shield nearby allies while holding your ground. | SHIELDED | ATTUNED |
| Shrapnel Net (`heavy_shrapnel_net`) | 3 | Pin enemies in a shrapnel field so they cannot move. | PINNED | IONIZED |
| Juggernaut Push (`heavy_juggernaut_push`) | 3 | Drive one enemy three tiles back and crush it against cover. | IONIZED | IONIZED |
| Demolition Line (`heavy_demolition_line`) | 4 | Lay an explosive line with secondary fragmentation. | EXPOSED | PINNED |
| Armor Lock (`heavy_armor_lock`) | 4 | Lock armor, hunker down and gain a shield. | ATTUNED | READY |
| Ion Buster (`heavy_ion_buster`) | 5 | Ion shell drains shields, stuns Droids, and interrupts overwatch. | BURNING | PINNED |
| Fortress Fire (`heavy_fortress_fire`) | 5 | Double fire from a reinforced position. | MARKED | PINNED |
| Siege Breaker (`heavy_siege_breaker`) | 6 | Collapse a siege line and stun enemies inside it. | STAGGERED | PINNED |
| Body Block (`heavy_body_block`) | 6 | Take the threat onto yourself and shield the ally you guard. | ATTUNED | INSPIRED |
| Armageddon (`heavy_armageddon`) | 7 | Once per mission: A devastating blast that risks allies and ruins cover. | EXPOSED | EXPOSED |
| Unbroken (`heavy_unbroken`) | 7 | Once per mission: Fortify and heal the whole squad behind a shield wall. | SHIELDED | SHIELDED |

### Sniper — Long range precision

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Squadsight (`sniper_squadsight`) | 1 | Fire beyond sight through one enemy; a lifted target takes bonus damage. | MARKED | LIFTED |
| Spotter Round (`sniper_spotter_round`) | 2 | Mark a target and call one ally into a squadsight follow-up shot. | MARKED | EXPOSED |
| Quickdraw (`sniper_quickdraw`) | 2 | Two quick shots without ending the turn. | STAGGERED | EXPOSED |
| Dead Eye (`sniper_dead_eye`) | 3 | A precision shot ignores cover and raises critical chance. | IONIZED | EXPOSED |
| Cover Splitter (`sniper_cover_splitter`) | 3 | Pierce a line of targets and brace behind the rifle. | EXPOSED | LIFTED |
| Eagle Perch (`sniper_eagle_perch`) | 4 | Hold an overwatch lane from a fortified perch. | READY | ATTUNED |
| Crossfire (`sniper_crossfire`) | 4 | Call another shooter into the target and add a grazing hit. | BURNING | LIFTED |
| Gravity Sight (`sniper_gravity_sight`) | 5 | Track a target through terrain and suppress its reaction. | MARKED | LIFTED |
| Ricochet (`sniper_ricochet`) | 5 | Shot ricochets to exactly one nearby second enemy. | STAGGERED | LIFTED |
| Execution Order (`sniper_execution_order`) | 6 | Execute a wounded mark with a cover-piercing critical shot. | IONIZED | LIFTED |
| Duel Trigger (`sniper_duel_trigger`) | 6 | Trade a shot and recover an action behind a guard. | EXPOSED | MARKED |
| One Shot (`sniper_one_shot`) | 7 | Once per mission: A killing line through cover and armor. | PINNED | MARKED |
| Hail of Lead (`sniper_hail_of_lead`) | 7 | Once per mission: Four shots and suppressive damage to every foe. | BURNING | MARKED |

### Scout — Sneak and burst damage

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Concealment (`scout_concealment`) | 1 | Conceal and set a defensive decoy. | READY | SHIELDED |
| Mark (`mark`) | 2 | Legacy status with shipped values. | — | — |
| Run & Gun (`runGun`) | 2 | Legacy ap with shipped values. | — | — |
| Vanish (`scout_vanish`) | 3 | Vanish and immediately reposition. | ATTUNED | INSPIRED |
| Deadeye (`deadeye`) | 3 | Legacy attack with shipped values. | — | — |
| Spotter (`spotter`) | 4 | Legacy squadsight with shipped values. | — | — |
| Ghost (`ghost`) | 4 | Legacy reconceal with shipped values. | — | — |
| Snipe (`snipe`) | 5 | Legacy attack with shipped values. | — | — |
| Hunker Down (`hunker`) | 5 | Legacy hunker with shipped values. | — | — |
| Shoot (`shoot`) | 6 | Legacy attack with shipped values. | — | — |
| Overwatch (`overwatch`) | 6 | Legacy overwatch with shipped values. | — | — |
| Saboteur Trap (`scout_saboteur_trap`) | 7 | Once per mission: Trap an area, root survivors and pin them. | MARKED | STAGGERED |
| Ambush (`scout_ambush`) | 7 | Once per mission: Strike through cover and cash in three primed tags. | EXPOSED | STAGGERED, EXPOSED, MARKED |

### Medic — Healing and toxins

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Bacta Spray (`medic_bacta_spray`) | 1 | Spray and cleanse the squad while restoring health. | INSPIRED, SHIELDED, READY | BURNING, STAGGERED, PINNED |
| Medkit (`heal`) | 2 | Legacy heal with shipped values. | — | — |
| Revive Stim (`reviveStim`) | 2 | Legacy heal with shipped values. | — | — |
| Toxin Dart (`medic_toxin_dart`) | 3 | Toxin dart poisons its target for damage each turn. | STAGGERED, EXPOSED, IONIZED | MARKED, PINNED, BURNING |
| Smoke (`smoke`) | 3 | Legacy area_buff with shipped values. | — | — |
| Hack (`hack`) | 4 | Legacy hack with shipped values. | — | — |
| Combat Protocol (`protocol`) | 4 | Legacy attack with shipped values. | — | — |
| Shield Drone (`shieldDrone`) | 5 | Legacy buff with shipped values. | — | — |
| Scan Clue (`scan`) | 5 | Legacy scan with shipped values. | — | — |
| Shoot (`shoot`) | 6 | Legacy attack with shipped values. | — | — |
| Overwatch (`overwatch`) | 6 | Legacy overwatch with shipped values. | — | — |
| Med Beacon (`medBeacon`) | 7 | Once per mission. Med Beacon. | — | — |
| Hack Droid (`hackDroid`) | 7 | Once per mission. Hack Droid. | — | — |

### Tech — Gadgets and hacks

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Probe Droid (`tech_probe_droid`) | 1 | Remote probe marks contacts even beyond line of sight. | IONIZED | EXPOSED |
| EMP Burst (`tech_emp_burst`) | 2 | EMP blast drains shields and stuns droids. | IONIZED | LIFTED |
| Remote Shield (`tech_remote_shield`) | 2 | Project a shield to an ally and retain a small reserve. | SHIELDED | READY |
| Slicer Ping (`tech_slicer_ping`) | 3 | Ping and ionize enemy signals while recovering the slicer action. | BURNING | LIFTED |
| Turret Pin (`tech_turret_pin`) | 3 | A turret double-taps and pins its target. | PINNED | LIFTED |
| Override (`tech_override`) | 4 | Override a droid into the player squad for the rest of the battle. | STAGGERED | IONIZED |
| Field Repair (`tech_field_repair`) | 4 | Repair a wounded ally and reinforce its plating. | ATTUNED | INSPIRED |
| Ion Spike (`tech_ion_spike`) | 5 | A cover-proof ion shot that empties shields. | EXPOSED | MARKED |
| Barrier Grid (`tech_barrier_grid`) | 5 | Project a defensive grid over the whole squad. | SHIELDED | SHIELDED |
| Signal Jam (`tech_signal_jam`) | 6 | Jam enemy weapons and suppress the marked contact. | BURNING | MARKED |
| Drone Relay (`tech_drone_relay`) | 6 | Relay a fresh action and shield to one ally. | ATTUNED | SHIELDED |
| Total Shutdown (`tech_total_shutdown`) | 7 | Once per mission: Global ion surge with a droid-ending EMP blast. | STAGGERED | MARKED |
| Engineer Network (`tech_engineer_network`) | 7 | Once per mission: Repair and coordinate the whole squad. | SHIELDED | ATTUNED |

### Droid — Swappable modules

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Rebuild (`droid_rebuild`) | 1 | Rebuild a wrecked chassis in place. | READY | ATTUNED |
| Repeater Module (`droid_repeater_module`) | 2 | Repeater module lays three suppressive shots. | PINNED | STAGGERED |
| Shield Module (`droid_shield_module`) | 2 | Shield module reinforces its target and nearby squad. | SHIELDED | READY |
| Sensor Module (`droid_sensor_module`) | 3 | Sensor module marks every visible enemy. | MARKED | STAGGERED |
| Jetpack Module (`droid_jetpack_module`) | 3 | Jetpack leap gains a landing shield. | EXPOSED | PINNED |
| Flamer Module (`droid_flamer_module`) | 4 | Flamer blankets an area in lasting fire and panics survivors. | BURNING | IONIZED |
| Med Module (`droid_med_module`) | 4 | Med module treats its target and self-repairs. | INSPIRED | INSPIRED |
| Targeting Protocol (`droid_targeting_protocol`) | 5 | Targeting computer ignores cover and primes follow-up shots. | PINNED | MARKED |
| Servo Lock (`droid_servo_lock`) | 5 | Servo lock immobilizes a target and tears its joints. | BURNING | IONIZED |
| Reactive Plate (`droid_reactive_plate`) | 6 | Reactive plate hunkers and charges a shield. | ATTUNED | INSPIRED |
| Ion Relay (`droid_ion_relay`) | 6 | Ion relay pierces a line and ionizes hostiles. | STAGGERED | IONIZED |
| Omni Frame (`droid_omni_frame`) | 7 | Once per mission: Omni-frame gives each ally an action and reinforced plating. | SHIELDED | SHIELDED |
| Core Overload (`droid_core_overload`) | 7 | Once per mission: Sacrifice chassis integrity to ignite a huge blast. | EXPOSED | PINNED |

### Officer — Commands and buffs

| Ability | Rank | Mechanical effect | Applies | Consumes |
|---|---:|---|---|---|
| Take That Shot (`officer_take_that_shot`) | 1 | Give an ally an action and prepare its overwatch. | ATTUNED | SHIELDED |
| Command Mark (`officer_command_mark`) | 2 | Mark an enemy for allied accuracy and disrupt its aim. | MARKED | PINNED |
| Rally Line (`officer_rally_line`) | 2 | Rally allies with aim and battlefield first aid. | INSPIRED | ATTUNED |
| Coordinated Fire (`officer_coordinated_fire`) | 3 | Call another ally to shoot the marked target. | STAGGERED | MARKED |
| Fallback Order (`officer_fallback_order`) | 3 | Order an ally to withdraw with a fresh action and shield. | ATTUNED | ATTUNED |
| Ready Signal (`officer_ready_signal`) | 4 | Signal every ally to gain an action. | READY | READY |
| Tactical Feint (`officer_tactical_feint`) | 4 | Feint into a suppression that exposes the enemy. | PINNED | EXPOSED |
| Focus Fire (`officer_focus_fire`) | 5 | Concentrate allied fire on one marked foe. | BURNING | EXPOSED |
| Hold Fast (`officer_hold_fast`) | 5 | Hold a defensive formation and shield the squad. | ATTUNED | READY |
| Battle Plan (`officer_battle_plan`) | 6 | Give an ally initiative and keep your own command action. | INSPIRED | INSPIRED |
| Counter Order (`officer_counter_order`) | 6 | Order a countershot and stun the foe. | IONIZED | EXPOSED |
| Full Assault (`officer_full_assault`) | 7 | Once per mission: Order a squad-wide attack with ready follow-ups. | READY | INSPIRED |
| Perfect Command (`officer_perfect_command`) | 7 | Once per mission: Double an ally command and guard the squad. | ATTUNED | INSPIRED |

## Capstones — one unique moment each

Each rank-7 choice is labelled “Once per mission” in promotion. A single mission charge gates each soldier path; Medic’s shipped Med Beacon charge remains its original field.

- **Assault Storm (Trooper):** Breach blast gives every ally an action and exposes enemies in the impact area.
- **Grenadier Finale (Trooper):** A friendly-fire inferno roots survivors and spreads burning.
- **Armageddon (Heavy):** The strongest cover-breaking blast also endangers allies and stuns survivors.
- **Unbroken (Heavy):** Fortifies and heals every ally behind a shared shield wall.
- **One Shot (Sniper):** One cover-ignoring critical line pierces another enemy and adds a finishing hit.
- **Hail of Lead (Sniper):** Four aimed shots into one target graze every other enemy.
- **Saboteur Trap (Scout):** An area trap roots and pins survivors after its blast.
- **Ambush (Scout):** A cover-proof critical attack cashes in three separate target tags.
- **Med Beacon (Medic):** A field beacon heals every ally, shields the squad, and refunds the medic’s action.
- **Hack Droid (Medic):** The hack stuns its Droid target, ionizes all enemies, and shields all allies.
- **Total Shutdown (Tech):** The EMP blast deals extra Droid damage and ionizes every enemy.
- **Engineer Network (Tech):** The squad gains repair, aim, shields, and a self action.
- **Omni Frame (Droid):** The chassis gives an action and reinforced plating to every ally.
- **Core Overload (Droid):** A self-damaging friendly-fire blast ignites everyone in the area.
- **Full Assault (Officer):** Every ally receives an action and a ready follow-up.
- **Perfect Command (Officer):** One ally gains two actions while the whole squad gains shields.

## Engine wiring

- Heavy campaign deployment uses its `heavy_soldier` unit kind. Campaign starter kits include signature plus two actions. Droid module swaps replace the three installed tactical buttons, persist in the campaign save, and appear as a separate promotion choice.
- Sniper Ricochet bounces to exactly one nearby second enemy; Execution Order doubles damage below half HP; Spotter Round calls one allied squadsight follow-up. Tech Override converts an enemy Droid to an ally. Body Block taunts enemies and shields its protected ally. These use the existing soldier damage hook and shipped effect primitives.
- Scout Concealment and Vanish preserve concealment through the mission ability wrapper. Rank-7 abilities use one mission charge.

## Verification

Final headless import exited 0. `./godot/test.sh` exited 0 with zero `SCRIPT ERROR`, zero `ERROR:`, and zero failing suites. Core17 passed 276 checks; Soldier18 passed 506; Cine15 Low and Medium passed 19 and 4. Normal rescue won 9/20. Logs: `/home/jess/projects/tw-logs/w18/soldier/import-verified.log` and `/home/jess/projects/tw-logs/w18/soldier/full-test-final2.log`. The soldier suite also exercises campaign Droid swaps, Heavy deployment, Scout concealment, one-use capstones, and named attack mechanics.

## Captures (844×390)

- [Sniper promotion](soldier/promotion-sniper-844x390.png)
- [Droid promotion with module choice](soldier/promotion-droid-844x390.png)
- [Squadsight battle](soldier/battle-sniper-squadsight-844x390.png)

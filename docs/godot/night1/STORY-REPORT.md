# Night 1 story report

The existing Temple Codex opens the Journal through its new **Journal** tab. The hook is in `story_screen.gd` (`_build_codex`); `strat_ui.gd` needed no new navigation hook. The same Temple Codex button reaches it.

## Choice callbacks

Each line appears only when its saved flag is set. Resource rewards are granted once per callback across the save; text can recur in later eligible scenes.

| Flag | Scene | Remembered action and effect |
|---|---|---|
| `e1_strike_known` | briefing | You questioned the envoy; his warning puts guards on the west stair. (intel +1) |
| `e1_ambush_ready` | debrief | You kept the warning within the Order; the ambush teams are already in place. (favor +1) |
| `archive_backup` | talk | You copied the Archives to a hidden colony; one sealed index returns. (credits +10) |
| `e1_traitors` | vote | You kept the traitor list; the names narrow this search. (intel +1) |
| `e1_vault_read` | briefing | You opened the Ossus vault; its map marks a safer route. (favor +1) |
| `e1_defector` | debrief | You took in the Imperial defector; her report identifies a patrol. (credits +10) |
| `e1_refugees_in` | talk | You sheltered the Taris refugees; they warn you of a tunnel. (intel +1) |
| `e1_mando_honor` | vote | You honored the Mandalorian duel; the clan sends a scout. (favor +1) |
| `saresh_deal` | briefing | You made a deal with Saresh; his promised name reaches the Temple. (text only) |
| `e1_eleena_tracked` | debrief | You tracked Eleena Daru; her shuttle trace cuts through the noise. (text only) |
| `e1_docks_guarded` | talk | You posted Temple Guards at the docks; their watch catches a signal. (text only) |
| `e1_hutt_sold` | vote | You let the Hutt hold the schedule; the enemy now knows the patrol gaps. (text only) |
| `kira_foresight` | briefing | You believed Kira’s vision; she recognizes the shape of this attack. (text only) |
| `tor_light` | debrief | You let Tor release Kessra; a former enemy passes on a warning. (text only) |
| `tor_blood` | talk | You allowed Tor’s revenge; the silence between you follows this vote. (text only) |
| `ilsa_loyal` | vote | You paid Ilsa’s debts; she brings the Council an unaltered report. (text only) |
| `bren_clinic` | briefing | You opened Bren’s clinic; its patients know who crossed the lower city. (text only) |
| `grak_envoy` | debrief | You sent Grak as envoy; Clan Ordo answers his call. (text only) |
| `e2_bane_tracked` | talk | You sent trackers after the lone Sith; their last coordinates remain on file. (text only) |
| `e3_beacon_warned` | vote | You warned the Senate about Ro; the Beacon crew has time to prepare. (text only) |

## Starting roster personal arcs

The shipped starting roster has **two Jedi** (Kira and Tor) and four non-Jedi (Rhal, Ilsa, Bren, Grak). All six receive an arc; their existing classes and roles remain intact.

| Character | Step 1: Temple talk | Step 2: briefing | Step 3: resolution |
|---|---|---|---|
| Kira Venn | Kira keeps a second watch over the docking ring. She asks whether a warning is still useful when no one wants to hear it. | Kira marks a route through the service gantries. She asks you to trust the map she made by hand. | Kira has watched the gates for three nights. She asks whether to lead the next watch or finally sleep.; first choice +5 will, second +1 crit and +1 Darkness |
| Tor Saalen | Tor checks the treatment cells after lights out. He wants to know who will protect a prisoner when the guns fall silent. | Tor spots a wounded attacker by the east bulkhead. He asks for a corridor to bring them in alive. | Tor has kept a list of the wounded on both sides. He asks whether to take responsibility for their care.; first choice +5 will, second +1 crit and +1 Darkness |
| Sgt. Rhal Dax | Rhal sets an extra place in the mess. He says a squad needs room for whoever comes home late. | Rhal points to a service lift he secured before dawn. He asks you to move the squad through it. | Rhal has trained a replacement for every post. He asks whether to stay on the line or teach the next watch.; first choice +5 will, second +1 crit and +1 Darkness |
| Ilsa Myr | Ilsa listens to old comms after the Temple sleeps. She has found a voice she knows in an enemy transmission. | Ilsa traces the voice to a relay beneath the street. She asks for a quiet approach. | Ilsa has the source file and a name. She asks whether to put it before the Council.; first choice +5 will, second +1 crit and +1 Darkness |
| Doc Bren | Bren has moved a cot into the corridor. He says a locked infirmary helps no one outside it. | Bren spots an unused medical store near the objective. He asks for a minute to collect it. | Bren has treated everyone who reached his door. He asks whether the ward should remain open after the siege.; first choice +5 will, second +1 crit and +1 Darkness |
| Grak Ordo | Grak polishes a cracked plate of armor. He says the clan gave it to him when he chose to guard this gate. | Grak identifies a clan mark on a supply crate. He asks to challenge its bearer openly. | Grak has an offer to return home. He asks whether his watch here is finished.; first choice +5 will, second +1 crit and +1 Darkness |

Every arc opens its talk after one completed mission. The next briefing advances the arc, and a Temple conversation after two completed missions resolves it. If the character dies before resolution, the arc closes and the Journal adds a memorial line. `bonus.will`, `bonus.crit`, and `dark` use existing roster fields and battle stat calculation.

## Journal and era interludes

- Journal shows current era, saved key choice sentences, active arc hints, and fallen memorials. It is reachable from Temple → Codex → Journal.
- Era 1→2 and 2→3 transitions display a short recap of up to three recorded actions and one continue choice. The interlude is saved as a pending dialogue, so reloading resumes it.
- Old saves default `personal_arcs`, `memorials`, `callback_seen`, and `callback_rewarded` through `StoryEngine.ensure_state` during campaign load.

## Captures

- [night1-story-callback-briefing.png](../shots/night1-story-callback-briefing.png) — 1920×1080.
- [night1-story-arc-talk.png](../shots/night1-story-arc-talk.png) — 1920×1080.
- [night1-story-arc-resolution.png](../shots/night1-story-arc-resolution.png) — 1920×1080.
- [night1-story-journal.png](../shots/night1-story-journal.png) — 1920×1080.
- [night1-story-interlude.png](../shots/night1-story-interlude.png) — 1920×1080.

## Verification

- Godot 4.7.2 headless import completed.
- `story_night1_test.gd`: 141 checks, 0 failures. It covers all 20 callbacks with and without flags, eight mechanical effects, recurring text without repeated rewards, six three-step arc fixtures and deaths, Journal sections, both interludes, and old save load.
- `story_bonds_test.gd`: 452 checks, 0 failures.
- Full `./godot/test.sh`: exit 0, every suite 0 failures, 0 `SCRIPT ERROR`; Normal rescue bot 10/20 wins; campaign suite 45 checks, 0 failures.

## Skipped

- The request for six **starting Jedi** could not be met without changing the shipped roster: it contains only two Jedi. Four arcs therefore belong to the existing non-Jedi starting companions. No roster classes were changed.

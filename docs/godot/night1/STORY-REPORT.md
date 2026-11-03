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

| Character | Step 1: Temple talk | Step 2: briefing | Step 3: resolution rewards |
|---|---|---|---|
| Kira Venn | Questions whether an unwelcome warning matters. | Maps a route through the service gantries. | Lead the watch: Kira deflect +5. Watch every gate: Kira aim +5, Darkness +1. |
| Tor Saalen | Asks who protects prisoners after the guns fall silent. | Opens a corridor for a wounded attacker. | Take the ward: Tor will +5, Darkness −1. Use forbidden strength: Tor maximum Force +1, Darkness +1. |
| Sgt. Rhal Dax | Keeps a place for the late returning squadmate. | Secures a service lift for the squad. | Stay on the line: Rhal will +8. Command the hard watch: Rhal aim +4, Darkness +1. |
| Ilsa Myr | Finds a familiar voice in enemy comms. | Traces the voice to a street relay. | Submit evidence: intel +1, Ilsa aim +3. Hide the source: Ilsa crit +2, Darkness +1. |
| Doc Bren | Moves a cot outside the infirmary. | Recovers an unused medical store. | Keep the ward open: Bren gains one medkit per battle. Reserve the ward: Bren HP +1, Darkness +1. |
| Grak Ordo | Remembers the clan oath that brought him to the gate. | Challenges the bearer of a clan marked crate. | Stay: Grak armor +1. Pursue the clan debt: Grak gains one grenade per battle, Darkness +1. |

The first Temple talk opens after one completed mission. The briefing opens after three completed missions or any bond reaches level 1. Resolution opens after six completed missions or at era 2 start. The Journal names the remaining missions and the alternate gate. A death before resolution closes the arc and adds a memorial line. Rewards use existing roster bonuses, Darkness, and intel; no new battle effects are introduced. Existing saves retain their arc step.

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
- `story_night1_test.gd`: 249 checks, 0 failures. It covers callbacks, both unique rewards for all six arcs, mission/bond/era gates, deaths, Journal sections, interludes, and old and mid-arc save loads.
- `story_bonds_test.gd`: 452 checks, 0 failures.
- Full `./godot/test.sh`: exit 0, every suite 0 failures, 0 `SCRIPT ERROR`; Normal rescue bot 10/20 wins; campaign suite 45 checks, 0 failures.

## Skipped

- The request for six **starting Jedi** could not be met without changing the shipped roster: it contains only two Jedi. Four arcs therefore belong to the existing non-Jedi starting companions. No roster classes were changed.

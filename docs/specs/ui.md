# Temple Watch — Look & Feel Spec (Chat D)

Written 2026-10-12. Owner of code: Coordinator (E). This spec does not touch `claude/src/`.
**Mockup:** https://claude.ai/artifact/SRkgNQRXHFiAF5QK7bETVK (battle screen, clickable; its source is the reference implementation for tokens, overlays and the odds panel).

## 1. Decisions (Jess, 2026-10-12)

| Topic | Decision |
|---|---|
| Look | **Holo war-table, sharpened.** Keep the dark blue hologram table; add real icons, glow on selection, clearer color roles. Single dark theme. |
| Tokens | **Class icon in a ring.** Players = circle ring in unit color; enemies = rounded square, red. Initials retired. |
| Enemy intent | **Shown only when you tap an enemy.** Dashed red line to its likely target + one-line plan in the side sheet. |
| Mockups | Battle screen only (built). Other screens are wireframes below. |
| Fonts | Keep Chakra Petch (display), IBM Plex Sans (body), IBM Plex Mono (numbers). No change. |
| Sound | None in v1 (locked). |

## 2. Color roles

Every color means one thing. Never reuse a role color for decoration.

| Token | Hex | Role | Contrast on panel `#0f191c` |
|---|---|---|---|
| `--bg` | `#0a1113` | page | — |
| `--panel` | `#0f191c` | board, sheets | — |
| `--raise` | `#15232a` | buttons, tiles | — |
| `--line` | `#22363c` | borders, empty pips | — |
| `--grid` | `#1a2b30` | board grid lines (new) | — |
| `--fg` | `#dbe7e4` | main text, best-shot tag | 14.1 : 1 |
| `--dim` | `#8aa2a5` | secondary text (was `#83999c`) | 6.6 : 1 |
| `--holo` | `#79d3e2` | player UI: selection, reach, shot line, Focus | 10.4 : 1 |
| `--troop` | `#e0bd78` | troop ring color | 10.0 : 1 |
| `--sith` | `#ef6a5d` | enemies, damage, enemy intent (was `#e2574b`, 4.8 : 1) | 5.9 : 1 |
| `--dark` | `#b294f5` | Darkness only | 7.2 : 1 |
| `--good` | `#7fd99a` | heals, captures, ally targets | 10.5 : 1 |
| Jedi colors | per unit (`#62b3ff`, `#72e0a4`, …) | Jedi ring = saber color; picked in recruit editor | — |

Contrast: measured with the WCAG formula here (sourced method; High confidence). All text roles pass AA (4.5 : 1).

## 3. Token system

| Part | Player | Enemy |
|---|---|---|
| Shape | circle, inset 9% of tile | rounded square (radius 22%), inset 9% |
| Ring | 2px, unit color (Jedi) or `--troop` | 2px `--sith` |
| Fill | ring color at 14% over `--bg` | same rule |
| Icon | class icon, `--uc`, ~60% of tile | enemy type icon |
| HP | segmented bar under the token, one segment per HP | same |
| Status | 16px badge, top-right, icon from status set | same |
| Selected | 2px gap + 2px `--holo` ring + 14px holo glow | — |
| Guard | soft halo (3px ring at 35%) plus Guard badge | — |
| Spent (no actions) | 60% opacity | — |
| Down | 45% opacity, dotted ring, Down badge, bleed turns in badge | — |
| Surrendered | dashed ring, flag badge | — |
| Stunned | desaturated, spiral badge | — |

Info toggle (minimal by default, locked): **off** = icon + HP bar + status badge. **on** = adds HP number and stat grid in the sheet.

### Icons
24×24 viewBox, stroke-only: `fill:none; stroke:currentColor; stroke-width:2; stroke-linecap:round; stroke-linejoin:round`. Put them once as `<symbol id="i-<key>">` and use `<svg class="ic"><use href="#i-<key>"/></svg>`. Total ≈2 KB. Drawn by Claude; checked for legibility at 32 px (heavy/grenade/consular were redrawn after the first pass read as ♂ symbols).

Keys starting `e_` are enemies. `e_droid`, `e_raider`, `e_horror` cover later eras (spec A rosters). Abilities without their own icon reuse one: `heal` → `medic`, `stun` → `stunned`, `subdue` → `captured`, `guard`/`overwatch` → status icons.

```json
{
  "guardian": "M15 2v12M13 14h4M14 14v6h2v-6M3 6l5-2 5 2v5c0 4-2.5 6-5 7-2.5-1-5-3-5-7z",
  "consular": "M17 2v12M15 14h4M16 14v6h2v-6M3 7c2 2.5 2 7.5 0 10M7 5c3 3.5 3 10.5 0 14",
  "sentinel": "M5 3l10 10M19 3L9 13M14 14l4 4M10 14l-4 4",
  "wayseeker": "M15 2v12M13 14h4M14 14v6h2v-6M2 10a5 5 0 1 0 10 0a5 5 0 1 0-10 0M7 6.5l1.5 3.5L7 13.5 5.5 10z",
  "soldier": "M2 11h15l2-2h3v4h-4l-2 2h-3l-1 4H9l1-4H2z",
  "scout": "M5 12a7 7 0 1 0 14 0a7 7 0 1 0-14 0M12 2v6M12 16v6M2 12h6M16 12h6",
  "medic": "M9 3h6v6h6v6h-6v6H9v-6H3V9h6z",
  "heavy": "M2 9h14v6H2zM16 10.5h6v3h-6M5 15v5h3v-5M9 9V6h4v3",
  "e_trooper": "M5 14a7 7 0 0 1 14 0v5h-4l-1-3h-4l-1 3H5zM8 12h8",
  "e_heavy": "M4 14a8 8 0 0 1 16 0v6H4zM7 12h10M8 17h8",
  "e_acolyte": "M12 2C7 2 5 8 5 14v7h14v-7c0-6-2-12-7-12zM9 13h6l-1 3h-4z",
  "e_droid": "M7 8h10v8H7zM10 11v1M14 11v1M12 4v4M10 4h4M9 16v5M15 16v5",
  "e_raider": "M5 12a7 7 0 0 1 14 0v3H5zM5 15l3 5h8l3-5M9 11h6",
  "e_horror": "M2 12c3-5 7-7 10-7s7 2 10 7c-3 5-7 7-10 7s-7-2-10-7zM10 12a2 2 0 1 0 4 0a2 2 0 1 0-4 0M12 5V2M12 22v-3M5 7L3 5M19 7l2-2M5 17l-2 2M19 17l2 2",
  "guard": "M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z",
  "overwatch": "M2 12c3-5 6-7 10-7s7 2 10 7c-3 5-6 7-10 7s-7-2-10-7zM9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
  "stunned": "M12 12a1 1 0 0 1 2 0a3 3 0 0 1-6 0a5 5 0 0 1 10 0a7 7 0 0 1-14 0",
  "surrender": "M6 21V3M6 4h12l-3 4 3 4H6",
  "down": "M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0M12 8v8M8 12h8",
  "darkness": "M15 3a9 9 0 1 0 6 15A7 7 0 0 1 15 3z",
  "captured": "M3 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0M13 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0",
  "cover_half": "M3 13h18v7H3z",
  "cover_full": "M4 3h16v18H4zM4 9h16M4 15h16M10 3v6M14 9v6M10 15v6",
  "relay": "M12 2v6M8 4l4 4 4-4M6 22l6-14 6 14M8 17h8",
  "strike": "M4 20L18 6M15 3l6 6M3 21l2-2",
  "shoot": "M3 12h13M13 7l6 5-6 5",
  "push": "M3 12h7M7 8l4 4-4 4M14 5c2 2 3 4 3 7s-1 5-3 7M18 3c3 3 4 6 4 9s-1 6-4 9",
  "throw": "M5 17c2-8 7-12 16-12M17 2l4 3-3 4M2 15h6v6H2z",
  "collapse": "M3 4h18v16H3zM12 4l-2 5 3 3-2 4 1 4",
  "choke": "M8 20v-6M8 14V5M11 14V3M14 14V4M17 14V7M8 14c0 4 2 6 5 6s4-2 4-6",
  "meditate": "M10 5a2 2 0 1 0 4 0a2 2 0 1 0-4 0M4 20c2-3 5-4 8-4s6 1 8 4M7 13l5 2 5-2M12 9v7",
  "grenade": "M5 13a7 7 0 1 0 14 0a7 7 0 1 0-14 0M5 13h14M9 10h6M12 3v3"
}
```

## 4. Screens (phone first, ~400 px wide)

Common frame: status strip on top, content, one primary button at the bottom within thumb reach. Laptop (≥860 px): content left, sheet right, same components.

| Screen | Job | Priority |
|---|---|---|
| Mission (battle) | fight | v0.2 — mockup built |
| Debrief | results, XP, injuries | v0.2 |
| Temple base | spend resources, rooms, Council | v0.2 (if spec B's slice includes it) |
| Squad select | pick 6 for a mission | v0.2 |
| Galaxy map + list | choose next mission/crisis | v0.3 |
| Recruit editor | name, look, color, path | v0.3 |

```
MISSION                         DEBRIEF
┌──────────────────────────┐   ┌──────────────────────────┐
│TEMPLE WATCH  T3/8 ▮▮▮▯ 14│   │DEBRIEF · TURN 8          │
│ ─ PLAYER PHASE · TURN 3 ─│   │RELAY HELD                │
│┌────────────────────────┐│   │1–2 line outcome          │
││        10×12 board     ││   │──────────────────────────│
││   tokens · overlays    ││   │(K) Kira  +40 XP  ▲Rank 2 │
│└────────────────────────┘│   │(D) Dax   +25 XP  wounded │
│(K) Kira Venn  Knight     │   │(G) Grak  † One w/ Force  │
│HP ▮▮▮▮▮▮▮▯▯  AP ▮▮ F ▮▮▮▯│   │──────────────────────────│
│[Strike][Guard][Push][Thr]│   │Intel +2  Kyber +1        │
│[Choke][Medit]            │   │Order Darkness ▮▮▯▯▯ 2    │
│ odds panel (aim mode)    │   │Council note (1 line)     │
│[      END TURN      ]    │   │[    RETURN TO TEMPLE   ] │
└──────────────────────────┘   └──────────────────────────┘

TEMPLE BASE                     SQUAD SELECT
┌──────────────────────────┐   ┌──────────────────────────┐
│Cr 420 In 6 Ky 2 SF 3 Rc 1│   │MISSION: Rescue at Taris  │
│ERA: OLD REPUBLIC · Mo 3  │   │Slots 6 · Jedi 1–3        │
│──────────────────────────│   │[(K)][(T)][ + ][ + ][+][+]│
│▸ Archives    Lv2  [▲]    │   │──────────────────────────│
│▸ Forge       Lv1  [▲]    │   │(K) Kira  Guardian R2 ✓   │
│▸ Infirmary   Lv1  2 hurt │   │(T) Tor   Consular R1 ✓   │
│▸ Barracks    6/8         │   │(D) Dax   Soldier  R2     │
│──────────────────────────│   │(I) Ilsa  Scout    R1     │
│COUNCIL  5 seats · 1 vote │   │(B) Bren  Medic  wounded ✕│
│(Y)(M)(V)( )( )           │   │──────────────────────────│
│[  GALAXY MAP  ] [ SQUAD ]│   │[       LAUNCH          ] │
└──────────────────────────┘   └──────────────────────────┘

GALAXY MAP (toggle: Map | List)  RECRUIT EDITOR
┌──────────────────────────┐   ┌──────────────────────────┐
│[ Map ][ List ]   Mo 3    │   │NEW RECRUIT    (◯ preview)│
│   ·Taris ⚠2              │   │Name [____________]       │
│        ·Coruscant ◆      │   │Type  Jedi ▸ Troop        │
│  ·Ruusan      ·Korriban☠ │   │Path [Guard][Cons][Sent][W]│
│──────────────────────────│   │Saber color ● ● ● ● ●     │
│⚠ Taris: raiders · 2 mo   │   │Species/look  ◀ 3 ▶       │
│  Reward Cr150 In2        │   │Trait 1 [Steady ▾]        │
│  Ignore → SF −1          │   │Trait 2 [Bold ▾]          │
│[      SEND SQUAD     ]   │   │[      ADD TO ORDER    ]  │
└──────────────────────────┘   └──────────────────────────┘
```

Resource icons for the base (5 resources, from README): Credits, Intel, Kyber, Senate Favor, Recruits. Use text abbreviations (`Cr In Ky SF Rc`) in v0.2; icons can follow in v0.3. Field lists for base and recruit editor follow spec B; the wireframes show layout only.

## 5. Combat feedback

| Moment | What the player sees | Built in mockup |
|---|---|---|
| Select unit | holo ring + glow; sheet shows HP, actions, Focus, abilities | yes |
| Move | reach tiles lit `--holo` 13%; cover squares on lit tiles (hollow = half, solid = full, kept from v0.1); hovered/tapped tile draws a solid holo path from unit to tile, dot at end | yes (Kira) |
| Aim | red % tag on each valid target; **best** odds tag white; animated dashed holo shot line to the chosen target | yes (Ilsa) |
| Odds panel | Aim, each modifier on its own line (cover −20, range, flank +, stunned +30), total %, damage range, "kills on hit" when max ≥ HP | yes |
| Confirm | aiming is two taps: tap target → odds panel → **Confirm shot**. Prevents fat-finger shots on phones | yes |
| Damage numbers | `-4` rises 16 px and fades over 1.1 s (v0.1 already does this); MISS gray, DEFLECT holo, crit `-6!` larger | v0.1 |
| Enemy intent | tap enemy → dashed red line to target, or arc + red 3×3 area for a grenade; one line in sheet ("Shoot the relay · 50%"). Note: "best guess, can change if you move first" | yes |
| Turn banner | full-width bar under the strip: "PLAYER PHASE · TURN 3" (holo) / "SITH PHASE" (red); letter-spacing sweep in 0.6 s | yes |
| Enemy turn | camera stays; acting enemy gets a red glow; 380 ms per move, 500 ms per attack (v0.1 timings keep) | — |
| Wave arrival | top strip "Wave" chip pulses; red edge flash on north rows for 0.8 s | — |
| Relay hit | relay chip meter drops; relay tiles flash red once | — |

Implementation note (inference, Med confidence): intent should come from the AI's real choice, not a guess. Run `eAttacks`/`tileScore` for that enemy against the current board when tapped and show the top result. It can differ from what actually happens because players move first; the sheet text says so.

## 6. Animation (CSS only, all cheap)

| Name | Where | Spec |
|---|---|---|
| `sweep` | turn banner | letter-spacing .6em → .18em, opacity 0 → 1, 0.6 s ease-out |
| `dash` | shot line, intent line | stroke-dashoffset loop, 1 s linear |
| `rise` | damage numbers | translateY −16 px + fade, 1.1 s (existing) |
| select glow | token | box-shadow, no animation (static is enough) |
| flash | wave / relay hit | background pulse once, 0.8 s |
| token move | units | **optional v0.3**: FLIP translate 120 ms per tile. v0.2 keeps instant moves |

All of the above stop under `prefers-reduced-motion: reduce` (damage numbers just appear and disappear).

## 7. Accessibility

| Rule | Value |
|---|---|
| Tap targets | ability buttons ≥ 58 px tall, others ≥ 44 px (above the 40 px floor) |
| Board tiles | at 400 px phone width a tile is ~37 px. Below the 40 px floor; accepted because the confirm step protects attacks. Do **not** shrink the board further |
| Contrast | every text role ≥ 4.5 : 1 (table §2) |
| Not color alone | every state also has a shape: enemy = square, status = badge icon, best shot = white tag, intent = dashed line |
| Focus | 2px holo outline on all buttons and tiles |
| Live text | battle log and sheet use `aria-live="polite"` |
| Reduced motion | see §6 |

## 8. Handoff to the Coordinator

Smallest change set that gets v0.1 to this look (estimate: ~150 changed lines, Med confidence):

1. Add the icon JSON (§3) and inject `<symbol>`s once at start (mockup: 1 line).
2. Swap `token()` to icon + segmented HP + status badge (copy mockup `tok()`).
3. Replace `.pct` tags with red/white tags; add `<svg class="over" viewBox="0 0 10 12">` over the board for shot path, move path and intent lines.
4. Ability buttons: icon + name + cost (mockup `.act`), 4 columns.
5. Odds panel + Confirm button: split `exec()` into pick target → confirm.
6. Tap-enemy intent: reuse `eAttacks(e,e)` for the target; draw line or blast area.
7. Turn banner element; colors updated per §2 (`--dim`, `--sith`, new `--grid`).

Mockup source is in the artifact above; it is static (no game logic) and safe to copy CSS and render helpers from.

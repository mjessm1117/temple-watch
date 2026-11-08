# Wave 18 combo HUD

## Player view

- Twelve combo tags have distinct drawn glyphs and colors. Up to three appear above a unit, followed by `+N` when more are present. Each badge has a 44 × 44 touch area; tapping it explains the tag. Repeated taps on `+N` cycle through explanations for hidden tags.
- The phone action bar shows three squad chain Momentum pips. At zero they sit in the existing action hint to preserve the Low tactical draw ceiling; as the meter fills they move into a dedicated plate. At three, **Momentum Strike** appears and grants the selected unit one action through `AbilityChains.claim_momentum_strike`. It greys out after use for that turn. This reads `chain_momentum`, separate from the older `mission.momentum` meter.
- A consumed tag creates a noninteractive, 1.2 second floating callout. The HUD compares tag snapshots; it does not change chain resolution or mission logic.
- Ability buttons draw apply and consume tag marks. A green outline shows when the current target has a tag the ability consumes. The aim confirm button shows the same marks and readiness tint.
- Tag and pip drags retain camera panning. Ability tray scrolling no longer resets when the selected unit or AP changes.

## Evidence

| Check | Result |
| --- | --- |
| Headless import | Exit 0, no script errors |
| `hud18_test` | 68 checks, 0 failures at 844 × 390 and 667 × 375 |
| Existing `phone17_test` | 663 checks, 0 failures |
| `cine15_test` Low draw gate | 19 checks, 0 failures after zero pip layout adjustment |
| Full `godot/test.sh` | Exit 0; every suite 0 failures; 0 `SCRIPT ERROR`; Normal rescue bot 9/20 |

Screenshots: [844 × 390](hud/battle-844x390.png) and [667 × 375](hud/battle-667x375.png). Both show two tagged units, full Momentum, and a MARKED chain callout.

The capture uses a synthetic MARKED chain fixture to hold the visual state. Gameplay tests also exercise the existing chain resolver directly. No reference image or new texture was added.

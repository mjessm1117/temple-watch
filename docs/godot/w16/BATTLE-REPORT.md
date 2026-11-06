# W16 battle lane report

## Battle basics

| Item | Status | Evidence |
| --- | --- | --- |
| End Turn and phone HUD | **PASS** in Godot at 844×390 and 390×844. The single header row exceeded the scaled logical width. End Turn now has its own top row and a 42 px touch target; the overlay accounts for reported safe-area insets. Godot uses `canvas_items` stretch with `expand` aspect. **GAP:** a live iPhone Safari run with its address bar shown is still needed. `godot/web/shell.html` sizes `html`, `body`, and the canvas to `height: 100%`; that may explain Jess's empty band when Safari changes its visual viewport. The scroll lane should verify the canvas against `visualViewport.height` with the address bar shown and set `viewport-fit=cover` for safe-area handling. This lane did not edit web files or `tools/web/`. | [before](../shots/w16-battle-hud-before.png) · [after](../shots/w16-battle-hud-after.png) |
| Move range | **PASS.** Low's instanced grid was moving fills under the floor and multiplying their alpha almost to zero. One-action blue and dash amber fills now keep their borders and visible opacity. | [before](../shots/w16-battle-move-before.png) · [after](../shots/w16-battle-move-after.png) |
| Path cost and action economy | **PASS.** The phone preview says “1 action · 1 action remains” or “DASH: ends turn.” Rules tests confirm a short move leaves one action for shooting or overwatch. | [before](../shots/w16-battle-path-before.png) · [after](../shots/w16-battle-path-after.png) |
| Touch camera | **PASS.** One finger pans after a dead zone, two-finger twists rotate in 90° steps, and pinch zooms. A second free-rotation handler in `cam_combat.gd` was the spin source. Pitch stays clamped by `_update_camera`; phone framing keeps selected and aimed units clear of the taller HUD. Desktop mouse and keyboard controls remain. | [before](../shots/w16-battle-camera-before.png) · [after](../shots/w16-battle-camera-after.png) |
| Overwatch | **PASS.** A single ground arc with translucent fill and an edge replaces per-tile dots; a sprite eye marks the guarding unit. The arc is a full circle because the actual overwatch rule fires in every direction. | [before](../shots/w16-battle-overwatch-before.png) · [after](../shots/w16-battle-overwatch-after.png) |
| HP/AP glyphs | **PASS.** The unit panel draws HP circles and AP bars. Phone cards use numeric AP; `galaxy_details.gd` uses numeric risk and unrest. | [before](../shots/w16-battle-hud-before.png) · [after](../shots/w16-battle-hud-after.png) |

## First mission and squad

I kept the `relay` layout for the first battle because its central objective, three approach lanes, and near-gate deployment positions make the hold legible immediately.

| Item | Status | Evidence |
| --- | --- | --- |
| Temple outer gate | **PASS.** The first campaign mission keeps the existing `relay` defend map family, with a Temple theme, gate prop, and objective name and blurb in mission data. All initial attackers are visible. The ground zone and all entry lanes are marked before waves arrive; incoming enemies arrive visible and awake. Hold six enemy turns to win; lose if the gate falls, the zone is overrun, or the squad falls. The HUD reads `HOLD 2/6` after two turns. | [start before](../shots/w16-battle-defend-before.png) · [start after](../shots/w16-battle-defend-after.png) · [counter before](../shots/w16-battle-hold-before.png) · [counter after](../shots/w16-battle-hold-after.png) |
| Story text | **PASS.** The relay mission's name, location, brief, goal, outcomes, bonus label, and Zym quote changed to fit the gate. Jess retains the story taste call. | Mission data and `data-story.json` |
| Squad size | **PASS.** Capacity is 5→6→7; the normal front cap is 7 and the twin second-front cap remains 4. The six-person starting roster already supplies five deployable members; no Jedi was added. Seven deploy cards fit 844×390, and the deployment test checks seven legal spawn tiles on every campaign map. | Phone layout and strategy/mission tests |

## Render and gate

- Low Compatibility overwatch: **130 → 133** draw calls (**+3**, limit +5), measured in the same battle state with overwatch off and on.
- Normal rescue bot: **9/20** wins. First defend mission bot: **12/20** wins. The larger squad required a later evacuation wave and an extra duel defender; focused Ruusan bots pass at **8/20** and **14/20**.
- Headless import: **PASS**, exit 0.
- Full `./godot/test.sh`: **PASS**, exit 0; zero `SCRIPT ERROR` and zero failures in every suite.
- `git diff --check`: **PASS**.
- The screenshots are 844×390 Compatibility captures from the same deterministic states on the pre-lane revision and this branch. They are renderer evidence; they are not Safari captures.

# Temple home screen polish

## Changes

- **Temple drawing:** Every projected room target now shows its full name and a short state line. Built wings show their level and readiness; unused wings, annexes, spires, and sealed vaults have gold dashed outlines with construction or excavation prompts. The 14 planets remain in the home backdrop, while their small 3D name labels are hidden there. Room hit targets and navigation actions are unchanged.
- **Tabs:** All nine tabs retain their routes and have vector icons. The open station gets a gold edge and brighter fill. Counts and explanations come from the current save: available missions, idle research, ready modules or free build slots, wounded or tired soldiers, and the monthly Council vote. Counts disappear when their conditions clear. Council and Settings remain reachable from Command.
- **Top bar and status:** The resource row spells out Credits, Intel, Kyber, Senate Favor, and Recruits, with tooltips describing use and sources. The left readout keeps roster, wing, mission, staff, squad, Sith Darkness, and shortcut details with tighter spacing. Power and projected insufficient Credits turn red with explanations.

## Resource and power meanings

`SF` was **Senate Favor** (`state.res.favor`): it raises the monthly stipend, changes through missions and Council choices, and falls when monthly costs cannot be paid. `Rc` was **Recruits** (`state.res.recruits`): it is spent to hire troops or staff and grows monthly, including Barracks staff production.

`POWER used / capacity` is from `strat_base.gd`: used is the sum of each built wing's fixed power cost, also counting the wing currently under construction. Capacity starts at 8 and each relay adds 4. If used exceeds capacity, `Base.operational` returns false for built wings, stopping powered production, module use, and operational bonuses. This is presentation only; no costs, thresholds, or rules changed.

## Captures

| State | 1366 × 768 before | 1366 × 768 after | 1920 × 1080 before | 1920 × 1080 after |
| --- | --- | --- | --- | --- |
| Arrival | [before](../shots/home-before-arrival.png) | [after](../shots/home-after-arrival.png) | [before](../shots/home-before-arrival-1920.png) | [after](../shots/home-after-arrival-1920.png) |
| Built | [before](../shots/home-before-built.png) | [after](../shots/home-after-built.png) | [before](../shots/home-before-built-1920.png) | [after](../shots/home-after-built-1920.png) |
| Hover | [before](../shots/home-before-hover.png) | [after](../shots/home-after-hover.png) | [before](../shots/home-before-hover-1920.png) | [after](../shots/home-after-hover-1920.png) |
| Research | [before](../shots/home-before-research.png) | [after](../shots/home-after-research.png) | [before](../shots/home-before-research-1920.png) | [after](../shots/home-after-research-1920.png) |

[Live badges at arrival](../shots/home-badges.png) shows Council, Build, and Galaxy prompts together.

## Verification and limits

The new `home_ui_test.gd` saves and reloads fixtures for room plates, icon placement, tab highlights, each alert condition, full resource names, and over-capacity power. Existing `temple_view_test.gd` continues to exercise room hover, click, and tab routes. This host's Xvfb returns 1079 rows for a requested 1080-row window, so the final row is repeated in the large PNGs to keep the evidence at exactly 1920 × 1080. No requested work was left out.

# W20 lane D — big Temple, big galaxy map, strategy button sizes (lane name: strategy)
Read COMMON.md first. Worktree ../tw-w20/strategy.
## Jess wants
"The temple needs to be big. The galaxy map big."
The audit measured the Temple building at 24% of the screen and the galaxy chart at 29%. The 116 px header and 72 px footer cut across it, and the right panel takes ~290 px. The Galaxy Regions tab is 22x53 px.
## Do
1. **Temple home.**
   - The Temple fills >= 65% of the screen on phone. Use thin top and bottom bars, overlays that collapse, and a camera size/framing that fits the building to the screen.
   - Rooms are tappable, with labels readable at phone size.
   - Pinch/drag to look around is optional but nice.
2. **Galaxy map.**
   - The chart fills >= 70% of the screen on phone.
   - The details/region panel becomes a slide-in sheet or drawer that appears only when a site is selected (XCOM Geoscape: the map dominates, and info appears for the selected site).
3. **Strategy screens button sizing.** Temple, galaxy and home cards must all be >= 44 logical px and unclipped, at 956x440@3 and 844x390.
4. Desktop 1366x768 must still look right.
## File lease
- godot/scenes/temple.tscn, galaxy.tscn
- scripts/campaign/temple.gd, temple_view.gd, temple_geometry.gd, temple_rooms.gd
- scripts/campaign/galaxy*.gd, scripts/campaign/home*.gd, scripts/campaign/ui.gd, scripts/campaign/strat_ui.gd
- scripts/phone_layout.gd, godot/assets/temple/**, godot/assets/ui/planet.gdshader
- new tests/strategy20_test.gd
## Tests (strategy20)
- Temple building screen fraction >= 0.65 and galaxy chart fraction >= 0.70 at 956x440@3 and 844x390.
- All controls >= 44 px and inside the viewport.
- Desktop 1366x768 is unchanged in function.

Sheet: Temple before and after, galaxy before and after, galaxy with a site selected.

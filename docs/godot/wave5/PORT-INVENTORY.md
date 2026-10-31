# Wave 5 web source inventory

Every JavaScript file under `public/js/` is listed. Counts are physical lines from the frozen web source. “Ported” includes a documented partial port where shown; the campaign report lists remaining behavior.

| Web file | System | Lines | Godot status |
|---|---|---:|---|
| `public/js/abilities.js` | Battle rules or skills | 217 | Skills lane |
| `public/js/ai.js` | Battle rules or skills | 156 | Skills lane |
| `public/js/arsenal.js` | Campaign shell | 62 | Ported in this lane |
| `public/js/base.js` | Web UI, rendering, or integration | 54 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/battle-ui.js` | Battle rules or skills | 43 | Skills lane |
| `public/js/battle.js` | Battle rules or skills | 296 | Skills lane |
| `public/js/campaign.js` | Campaign shell | 91 | Ported in this lane |
| `public/js/console.js` | Web UI, rendering, or integration | 42 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/darkness.js` | Campaign shell | 87 | Ported in this lane — Gardens and redemption offers; mercy and mentoring deferred |
| `public/js/data-arsenal.js` | Campaign shell | 90 | Ported in this lane |
| `public/js/data-battle.js` | Battle rules or skills | 238 | Skills lane |
| `public/js/data-campaign.js` | Campaign shell | 58 | Ported in this lane |
| `public/js/data-codex.js` | Story, eras, codex, or Temple life | 353 | Story lane |
| `public/js/data-era2.js` | Story, eras, codex, or Temple life | 281 | Story lane |
| `public/js/data-era3.js` | Story, eras, codex, or Temple life | 279 | Story lane |
| `public/js/data-galaxy.js` | Campaign shell | 74 | Ported in this lane |
| `public/js/data-identity.js` | Campaign shell | 40 | Ported in this lane |
| `public/js/data-legacy.js` | Campaign shell | 90 | Ported in this lane |
| `public/js/data-life.js` | Story, eras, codex, or Temple life | 74 | Story lane |
| `public/js/data-maps-era2.js` | Map data or terrain | 68 | Maps lane |
| `public/js/data-maps.js` | Map data or terrain | 346 | Maps lane |
| `public/js/data-modules.js` | Campaign shell | 44 | Ported in this lane |
| `public/js/data-saga.js` | Story, eras, codex, or Temple life | 279 | Story lane |
| `public/js/data-skills.js` | Battle rules or skills | 183 | Skills lane |
| `public/js/data-story.js` | Story, eras, codex, or Temple life | 295 | Story lane |
| `public/js/data-teams.js` | Campaign shell | 16 | Ported in this lane |
| `public/js/data-trees.js` | Campaign shell | 113 | Ported in this lane |
| `public/js/data-wings.js` | Campaign shell | 32 | Ported in this lane |
| `public/js/data.js` | Battle rules or skills | 194 | Skills lane |
| `public/js/fieldops.js` | Campaign shell | 62 | Ported in this lane — send, odds and resolution; spawning and expiry deferred |
| `public/js/fx.js` | Web UI, rendering, or integration | 22 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/galaxy.js` | Campaign shell | 105 | Ported in this lane |
| `public/js/hack.js` | Web UI, rendering, or integration | 30 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/hazards.js` | Map data or terrain | 104 | Maps lane |
| `public/js/hud-xcom.js` | Battle rules or skills | 8 | Skills lane |
| `public/js/icons.js` | Web UI, rendering, or integration | 93 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/identity.js` | Campaign shell | 87 | Ported in this lane — nickname and deeds; voices and Padawan proximity deferred |
| `public/js/input.js` | Battle rules or skills | 74 | Skills lane |
| `public/js/legacy.js` | Campaign shell | 160 | Ported in this lane — bonds, drills, retirement; secrets and Council support deferred |
| `public/js/map-open.js` | Map data or terrain | 44 | Maps lane |
| `public/js/maps.js` | Map data or terrain | 107 | Maps lane |
| `public/js/menu.js` | Web UI, rendering, or integration | 53 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/power.js` | Battle rules or skills | 130 | Skills lane |
| `public/js/render.js` | Web UI, rendering, or integration | 126 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/rules.js` | Battle rules or skills | 186 | Skills lane |
| `public/js/saga.js` | Story, eras, codex, or Temple life | 171 | Story lane |
| `public/js/save.js` | Campaign shell | 33 | Ported in this lane — local save/load; remote sync deferred |
| `public/js/screens.js` | Web UI, rendering, or integration | 19 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/skills.js` | Battle rules or skills | 60 | Skills lane |
| `public/js/state.js` | Battle rules or skills | 19 | Skills lane |
| `public/js/story-era2.js` | Story, eras, codex, or Temple life | 100 | Story lane |
| `public/js/story-era3.js` | Story, eras, codex, or Temple life | 157 | Story lane |
| `public/js/story.js` | Story, eras, codex, or Temple life | 196 | Story lane |
| `public/js/swarm.js` | Web UI, rendering, or integration | 29 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/teams.js` | Campaign shell | 102 | Ported in this lane — formation and auto resolution; fatigue and detailed risk deferred |
| `public/js/temple-build.js` | Temple presentation | 152 | Deferred to Wave 6 — temple cutaway placement and adjacency depend on later spatial UI |
| `public/js/temple-data.js` | Campaign shell | 64 | Ported in this lane |
| `public/js/temple-kits.js` | Battle rules or skills | 21 | Skills lane |
| `public/js/temple-life.js` | Story, eras, codex, or Temple life | 127 | Story lane |
| `public/js/temple-map.js` | Temple presentation | 49 | Deferred to Wave 6 — web floor-plan presentation needs a Godot room-map pass |
| `public/js/temple-modules.js` | Campaign shell | 117 | Ported in this lane — wing actions; undercroft and spires deferred |
| `public/js/temple-ops.js` | Campaign shell | 110 | Ported in this lane — research, stress and recovery; Sith ops deferred |
| `public/js/temple-prog.js` | Campaign shell | 129 | Ported in this lane |
| `public/js/temple-ui.js` | Campaign shell | 94 | Ported in this lane — console stations; Council and recruit UI deferred |
| `public/js/temple.js` | Campaign shell | 137 | Ported in this lane — roster, promotions, assignment and gear; recruiting and quests deferred |
| `public/js/turns.js` | Battle rules or skills | 157 | Skills lane |
| `public/js/tutorial.js` | Story, eras, codex, or Temple life | 25 | Story lane |
| `public/js/twin.js` | Web UI, rendering, or integration | 50 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/ui-codex.js` | Story, eras, codex, or Temple life | 87 | Story lane |
| `public/js/ui-hud.js` | Battle rules or skills | 85 | Skills lane |
| `public/js/ui-settings.js` | Web UI, rendering, or integration | 30 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/ui-tree.js` | Battle rules or skills | 37 | Skills lane |
| `public/js/util.js` | Web UI, rendering, or integration | 12 | Deferred to Wave 6 — web DOM, input, and presentation integration |
| `public/js/view3d/armory3d.js` | 3D presentation | 45 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/board.js` | 3D presentation | 171 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/camera.js` | 3D presentation | 62 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/cine.js` | 3D presentation | 64 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/diorama.js` | 3D presentation | 81 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/effects.js` | 3D presentation | 90 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/figures.js` | 3D presentation | 168 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/forcefx.js` | 3D presentation | 71 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/galaxy3d.js` | 3D presentation | 54 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/labels.js` | 3D presentation | 20 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/main.js` | 3D presentation | 247 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/portraits.js` | 3D presentation | 57 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/props.js` | 3D presentation | 28 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/rigged.js` | 3D presentation | 56 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/themes.js` | 3D presentation | 102 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |
| `public/js/view3d/units.js` | 3D presentation | 151 | Deferred to Wave 6 — web 3D rendering and art need a Godot presentation pass |

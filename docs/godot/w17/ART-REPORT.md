# W17 Sniper and Heavy art report

## Credit ledger

Planned: 3 previews × 20 + 2 refines × 10 + 2 rigs × 5 = **90 credits**, hard cap **100**. Every paid submission is entered below before the call. Balance and task IDs are retained in `art/w17/ledger.json`.

| Call | Running reserved before | Expected cost | Running reserved after | Result |
|---|---:|---:|---:|---|
| Sniper A preview | 0 | 20 | 20 | Succeeded (`01a1af16-afd1-71df-a0dc-9c9b347ea847`) |
| Heavy A preview | 20 | 20 | 40 | Succeeded (`01a1af16-d1db-7417-9802-31ffcaa48b0a`) |
| Sniper B preview | 40 | 20 | 60 | Succeeded (`01a1af18-3fae-74c7-a4f5-1a75e97a7109`) |
| Heavy A refine | 60 | 10 | 70 | Succeeded (`01a1af18-d4d9-771c-b760-73e247c48792`) |
| Sniper A refine | 70 | 10 | 80 | Succeeded (`01a1af19-b2c1-71c4-ab90-f92ff808df66`) |
| Heavy A rig | 80 | 5 | 85 | Succeeded (`01a1af1a-06c1-7555-8a76-15971813a8e2`) |
| Sniper A rig | 85 | 5 | 90 | Succeeded (`01a1af1a-e282-7727-8f51-016da93390d9`) |

**Total: 90/100 credits.** The Meshy balance moved from 14,265 to 14,175 across this lane's seven calls. No paid retry or further generation was submitted.

## References and preview decisions

Both briefs cite the current player trooper and scout, with `sithHeavy` as the black/red enemy contrast. The existing trooper is white/red and the scout is muted green; the new class pair follows the requested tan, deep blue, cream and Jedi emblem palette.

| Preview | Silhouette | Style | Clean | Triangle fit | Decision |
|---|---:|---:|---:|---:|---|
| Sniper A | 3/5 | 4/5 | 4/5 | 5/5 | Chosen: lean visor, hip sidearm; no generated rifle or hood |
| Sniper B | 2/5 | 3/5 | 4/5 | 5/5 | Rejected: bulkier vest, still no rifle |
| Heavy A | 4/5 | 4/5 | 4/5 | 5/5 | Chosen: largest, broad plate silhouette; no generated repeater or rocket pack |

The scoped rifle, rotary repeater and rocket backpack were built locally from simple meshes after refinement. They are grouped under the spine rig node so they follow the torso. This keeps their position stable in idle and run, but the hands do not grip them precisely during shoot. The Sniper's visor satisfies the hood-or-visor brief; the Heavy has an exposed face rather than a closed helmet. The small gold chest marks suggest the Jedi emblem but are not legible at phone battle distance.

## Final models

| Class | Main triangles | Low triangles | Texture | Clips | Critique |
|---|---:|---:|---|---:|---|
| Sniper | 12,570 | 1,913 | 1024² WebP | 29 | Lean silhouette, visor, visible sidearm and long scope rifle. The downsampled texture is busy at phone distance, and the rifle looks mounted alongside the torso rather than held. |
| Heavy | 13,072 | 2,281 | 1024² WebP | 29 | Broadest soldier, strong tan/blue/cream read, rotary muzzle and raised rocket tubes. The launcher is less clear from the front and the repeater is not hand-gripped. |

Both are staged under `godot/assets/units/w17/` and absent from battle/roster wiring. The four GLBs are embedded binaries. The animation names include `idle`, `run`, `shoot`, `hit`, and `death`; the idle clip was neutralized to the bind pose after the first retarget made both bodies lean forward. Godot smoke playback passed for idle, run, shoot, hit and death on both main models and both LODs, with finite bone translations. Run and shoot were also rendered close: shoot presents the weapons, while Heavy run pitches far forward. Hit and death passed playback checks but were not visually judged; core should review their poses before gameplay wiring. The contact sheet and both 844×390 Low captures are under `docs/godot/shots/`.

## Verification

- Headless Godot import: exit 0, no `SCRIPT ERROR` or `ERROR:` on the final packaged assets.
- Main and Low counts measured from the staged GLBs; each has 29 clips and one 1024×1024 texture. Close Low LOD review preserved both silhouettes and weapons, with visible armor faceting on Heavy.
- Godot clip smoke test: idle, run, shoot, hit and death played on both classes and both LODs; 20/20 checks passed.
- Full `./godot/test.sh`: exit 0, zero `SCRIPT ERROR`, zero failures; Normal rescue 9/20.
- `git diff --check` and staged diff check: clean. Test-run screenshot changes were restored.

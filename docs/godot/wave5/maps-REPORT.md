# Wave 5 rescue map report

## Player changes

The rescue courtyard now offers three broad approaches to Mira instead of narrow wall openings. Each approach stays at least three tiles wide, with a half-cover position at least every four steps. The eastern terrace has two ramp entries and remains a flank route. The shortest three-wide path from the squad entry to Mira is 21 steps, down from 29.

The first patrol is spread so the squad can choose its approach while the four difficulty settings retain their intended pressure.

## How to see it

Launch `res://scenes/rescue.tscn` directly. The overview shows the left, center, and eastern approaches and the raised eastern flank.

## Verification

`./godot/test.sh`: **209 checks passed / 0 failed; no script errors**. The map test checks three distinct three-tile-wide routes, cover gaps of at most four steps, the 21-step shortest approach, and two ramps to high ground. Twenty fixed-seed bot games per difficulty: **Story 18/20, Normal 12/20, Hard 7/20, Legend 2/20**; all meet their required bands.

## Screenshot

- [Rescue map overview](../shots/wave5-maps-overview.png), captured by loading `res://scenes/rescue.tscn` directly with `env_capture.gd`.

## Integration requests

None.

## Open problems

Godot still reports ObjectDB leak warnings at test teardown. It reported no script errors.

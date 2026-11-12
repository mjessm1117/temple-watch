# W26 Common Context

Base SHA: ce62160 (main, last-good). Branch off ce62160 for your lane.

## W26 Goals (Jess ask-1a247e5b + ask-43f7daeb)
1. First battle too hard — fewer enemies, same open gate defense, all start in front, reinforcements later.
2. Friend/foe colors — ally and enemy troopers look too similar at phone scale.
3. Phone HUD — tofu glyphs, crowded labels, AP ring overlapping captions.

## Audit findings (tw-logs/w26/audit/AUDIT-REPORT.md)
- 12/20 bot wins on Normal seeds 1–20; all losses = zone overrun.
- Six enemies active at T1 (two pods, both awake) vs five squad members.
- East pod recommended for delayed activation (not full removal); tune to 13–16/20 bot.
- Ally/enemy white armor similar; rim is narrow; HP plates tiny.
- Bundled fonts lack U+2212 (minus), U+25CF (bullet), U+25CB, and camera glyphs — Linux fallback masks them, iOS will show tofu.
- AP ring and caption share same 48×44 slot; top objective strip crowded.

## Cross-lane contracts
- Lane A exposes: `opening_contact26(m)` and `next_wave26(m)` (read-only dicts).
- Lane B exposes: `side_color26(side)` palette function.
- Lane C reads A and B APIs via `has_method` guard only.
- Lane D emits `preview26(tile, actor_id)` with cover/sight/odds/route; C may render it.

## Rules (non-negotiable)
- Do NOT touch: legacy rescue fixture, generic Normal rescue balance, any file not in your lease.
- NEW helper files must use your lane's prefix (e.g., `w26a_`, `w26c_`).
- Run `godot --headless --import` before any test run.
- Gate: `godot/test.sh` exit 0, 0 fail, 0 SCRIPT ERROR.
- Capture 852×393 and 390×844 Low screenshots before finishing.
- Read AUDIT-REPORT.md before writing any code.
- No Meshy, no new 3D assets. Code + existing art only.

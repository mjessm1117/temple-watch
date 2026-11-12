# W26 Lane C — Phone HUD and Glyphs
Read COMMON.md first: docs/godot/w26/COMMON.md
Read audit: /home/jess/projects/tw-logs/w26/audit/AUDIT-REPORT.md

## Goal
Fix tofu glyphs, crowded top strip, AP ring/caption collision, reinforcement cue, name clipping. Layout closer to XCOM X5/X6.

## Changes

### 1. Glyph fixes (hud_phone.gd, hud_phone_camera_art.gd, decision22_threat.gd, hud_phone_action_art.gd)
Replace all missing glyphs with either:
- ASCII fallback (minus sign → "-", bullet → "·"), OR
- Draw as a ColorRect/polygon shape (AP filled dot = small filled circle drawn as a polygon, not unicode)
Priority: U+2212 minus in OBJ chip (iOS tofu risk) and U+25CF bullet in AP pips.
Camera control icons (↶ ↷ ⌖) in `hud_phone_camera_art.gd:11-14` → use text labels "L" "R" "C" or draw arrow shapes.

### 2. AP ring / caption (hud_phone_action_art.gd:25-85, hud_phone.gd:163-174)
Separate the AP badge from the action caption: caption goes BELOW the button (not inside the 48×44 area), or the ring moves outside the touch surface. Each action button must have its label readable without overlapping the ring. All buttons must still be ≥44×44 touch area.

### 3. Objective strip (hud_phone.gd:82-90, decision22_threat.gd:18-35)
"5 EXPOSED / OBJ −10 +1 IN" → split into two items:
- Left/top: "5 in enemy sight" (plain text)
- Right/small: zone HP icon + arrival countdown (use "-" for minus, ASCII digits for count)
Group reveal line must wrap at the label width; truncate to "GROUP 2 · 3 hostiles" if still >label width.

### 4. Reinforcement cue (reinforcement_marker.gd:38-58)
Make inbound marker compact: show only entry side arrow + turn count at the board edge, not floating center-left. Text: "→ 2 in 1T" style. Keep it out of the main combat view.

### 5. Name clipping (hud_phone.gd:109-112, hud_phone.gd:438-447)
Two-line name support: if name > ~10 chars, split to rank on line 1, surname on line 2. Or use short rank token ("Sgt. R.D" abbreviation). Do NOT just widen the plate.

### 6. Layout improvement (hud_phone_layout.gd:13-41)
Move toward XCOM X6 layout: portraits top-left, action buttons on side, Move/Objectives anchored bottom-right. This is a medium change — do your best within the existing layout system without a full rebuild. Prioritize the portrait-top-left change if the full layout is too large.

### 7. Cross-lane reads (use has_method guards)
- Read Lane A's `opening_contact26(m)` to show "EAST FLANK APPROACHING" when pod activates.
- Read Lane B's `side_color26(side)` for HP plate color if available.

## File lease (exclusive)
- godot/scripts/hud_phone.gd
- godot/scripts/hud_phone_layout.gd
- godot/scripts/hud_phone_action_art.gd
- godot/scripts/hud_phone_camera_art.gd
- godot/scripts/decision22_threat.gd
- godot/scripts/reinforcement_marker.gd
- godot/tests/phone26_hud_test.gd (create new)

## Test (phone26_hud_test.gd)
- Assert no U+2212 or U+25CF literal strings in hud_phone.gd (replaced with safe ASCII or drawn shapes).
- Assert reinforcement_marker text does not contain unicode non-ASCII symbols.
- Assert action button min size ≥ 44 in layout constants.
- Assert caption does not share the same VBox/slot as the AP ring (structural check).
- Capture at 852×393 and 390×844 Low showing the HUD; include in output captures.

## Boundaries
- Do NOT touch mission_*, unit_view, map_art, hud_controls, relay.json.
- Do NOT break existing battle logic — this is display only.

## Output
Commit on branch w26/hud. Leave w26/hud checked out. Screenshots at 852×393, 844×390, 390×844. Gate passes (exit 0, 0 fail, 0 SCRIPT ERROR).

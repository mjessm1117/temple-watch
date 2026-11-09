# Temple Watch Visual Critique Rubric

Grade each attached screenshot. Output one line per criterion in this format:
`PASS/FAIL — [criterion] — [one sentence observation]`.
If an item fails, add one sentence describing the specific fix. Judge only what is visible.

1. Unit readability — can individual units be distinguished at battle distance?
2. Battlefield readability — are grid, cover, and elevation clear?
3. Holo war-table aesthetic — does it read as a blue/teal holographic tactical display with clean overlays?
4. Visual hierarchy — do selected unit, targets, and action bar draw the eye first?
5. Tap targets — do visible buttons appear at least 44px tall?
6. Contrast — is text readable against every panel?
7. iPhone touch-drag — are scroll areas indicated and action areas clear of the bottom safe zone?
8. XCOM feel — does the layout feel like a mobile XCOM 2 screen?

Use `N/A` only if a criterion genuinely cannot be judged from the screenshot; explain why.

## Sample loop

The initial `battle-engine.png` critique caught several live visual issues, including a
small END TURN target and dim labels. The tooling lane cannot edit gameplay UI files.
To verify the gate, `tools/screenshot_scene.gd --mask-controls` covers the action
controls only in a test capture. The critique should mark XCOM feel FAIL on that
capture; a normal capture restores the controls and should mark it PASS. The
sample results and both PNGs are kept in `tw-logs/tooling/`.

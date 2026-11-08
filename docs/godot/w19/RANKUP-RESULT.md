# Rank-up screen implementation

- Replaced the promotion list with a full-screen portrait, rank transition, stat-gain strip, scrollable rank grid, and explicit ability confirmation.
- Added code-drawn Jedi and soldier rank insignia. The incoming badge animates for 0.55 seconds and a touch skips the flourish.
- Preserved mentor, droid module, path blend, and cross-training actions below the grid. Ability selection still calls `Progression.choose` and campaign save.
- One-line card effects use class descriptions where present and derive a short summary from unchanged ability fields otherwise.
- The rankup19 suite checks 667×375, 844×390, 1366×768, choice and confirm, locked rows, touch drag from a card, flourish skip, and campaign promotion through its next choice.
- Captures: `tw-logs/w19/rankup/2026-11-07-rankup-sheet.jpg`. The XCOM comparison is at `tw-reference/w19-rankup-side-by-side.jpg`; source reference art remains outside the repository.

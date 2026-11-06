# Resume lane `tw-w16-scroll2` (continue the interrupted scroll lane)

The first run of `docs/godot/w16/SCROLL-FIX.md` stopped partway: the Codex model hit capacity. Its work is still **uncommitted** in this worktree (`git status`). Do not throw it away. Read `SCROLL-FIX.md` (the full spec still applies) and `git diff`, then finish the job.

## Known state
- Done (uncommitted): `godot/web/shell.html` visible-viewport canvas + overscroll CSS; scroll deadzone/PASS changes; new test `godot/tests/scroll16_test.gd`.
- Failing: `SCROLL16: roster card drag scrolls`. The test runs with `touchscreen: false`, so check whether the horizontal roster `ScrollContainer` (`screen.card_scroll`) only drag-scrolls when touch is detected. Either way the real iPhone needs it to work, so fix the root cause. Don't weaken the test.
- Also check `document.addEventListener('touchmove', preventDefault)` in shell.html. Godot's canvas still has to receive touch drags. Confirm it doesn't stop drags inside the game.

## Then
Finish the remaining SCROLL-FIX items (the audit of every ScrollContainer, the headless Chrome iPhone shots if possible), run the full gate, write `SCROLL-REPORT.md`, and commit locally on `w16/integrate`. Same boundaries as SCROLL-FIX.md: no push, tag or export, and don't touch the battle lane's files.

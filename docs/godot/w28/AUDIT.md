# W28 Class System Audit — read-only, off c507f7b

## Goal
Understand what's already built and what's missing from the full class system before writing lane specs. No game code changes — audit only.

## Background
- W17 (dcfebd2): 5 soldier classes (Medic, Tech, Sniper, Heavy, Trooper) shipped as models + borrowed abilities. Jedi classes have no progression system yet.
- W18 (89b5341): 176 unique class abilities built with rank system + balance pass.
- Design doc: tw-logs/w17/2026-11-06-class-roster.md (Jess's full class roster spec).
- Jess's vision (ask-59ac225c, ask-bf5fd36d): 15 classes total; Jedi Padawan→Knight→Master→Council Master→Grand Master; soldiers start stronger but Masters+ become OP; blend up to 3 classes per unit; all skills unique AND chain/enhance for the unit and squad; mentor/legacy system.
- Soldier subclasses still to design: Scout/Rogue, Droid (with modules). Full list: Medic, Tech, Sniper, Heavy, Trooper, Scout/Rogue, Droid + Jedi paths (Guardian, Consular, Sentinel + subpaths at higher ranks).

## Setup
```
mkdir -p /home/jess/projects/tw-logs/w28/audit
cd /home/jess/projects/temple-watch
git worktree add ../tw-w28/audit -b w28/audit c507f7b 2>&1 | tail -3
cd /home/jess/projects/tw-w28/audit
/home/jess/projects/.tools/godot/godot --headless --path godot --import 2>&1 | grep -c ERROR | head -5 || true
```

## Audit steps

### 1. Inventory current class state
```
# Count classes, abilities, Jedi progression hooks
grep -rn "class_id\|class_name\|\"medic\"\|\"tech\"\|\"sniper\"\|\"heavy\"\|\"trooper\"\|\"scout\"\|\"droid\"\|\"Padawan\"\|\"Knight\"\|\"Master\"" godot/data/ godot/scripts/ 2>/dev/null | grep -v ".gd.uid" | head -60
wc -l godot/data/abilities/*.json 2>/dev/null | tail -1
wc -l godot/data/classes/*.json 2>/dev/null | tail -1
ls godot/data/classes/ 2>/dev/null
```

### 2. Measure current skill tree / class blend implementation
Read these files (line counts, key functions):
```
wc -l godot/scripts/abilities_engine.gd godot/scripts/class_engine.gd 2>/dev/null || wc -l godot/scripts/abilities*.gd godot/scripts/class*.gd 2>/dev/null
grep -n "blend\|momentum\|chain\|tier\|rank\|Padawan\|Knight\|Master" godot/scripts/abilities_engine.gd 2>/dev/null | head -30
```

### 3. Run current class test to see pass rate
```
mkdir -p /home/jess/projects/tw-logs/w28/audit
xvfb-run -a /home/jess/projects/.tools/godot/godot --headless --path godot --rendering-method gl_compatibility --resolution 844x390 -s tests/roster25_test.gd -- --graphics=low 2>&1 | tee /home/jess/projects/tw-logs/w28/audit/roster-test.log | grep -E "ROSTER|failures"
# Also run ability/class test if one exists
ls godot/tests/ | grep -iE "class|ability|skill"
```

### 4. Bot win-rate baseline (3 difficulty tiers, 20 seeds each)
Run opening gate battle bot at Normal and Hard to get baseline before class system changes:
```
xvfb-run -a /home/jess/projects/.tools/godot/godot --headless --path godot --rendering-method gl_compatibility --resolution 844x390 -s tests/opening27_test.gd -- --graphics=low 2>&1 | tee /home/jess/projects/tw-logs/w28/audit/opening27-baseline.log | grep -E "wins|OPENING27 RESULTS"
```

### 5. Identify the gaps — write gap list
Based on the inventory, write /home/jess/projects/tw-logs/w28/audit/GAPS.md:
- What's missing from each class (which soldiers need new abilities, which Jedi tier gates are absent)
- Whether blend-3-classes logic exists in abilities_engine.gd
- Whether Momentum/chain tags exist
- Whether mentor/legacy hooks exist
- Current hire/promote flow vs Jedi tier progression
- Skill tree UI: does one exist? Can players see/choose abilities?

### 6. Propose W28 lanes with file leases
Based on the gaps, write /home/jess/projects/tw-logs/w28/audit/LANES.md:
- Up to 4 lanes with disjoint file leases
- Recommended order of importance
- Each lane's one test, its gaps addressed, and cross-lane contracts (guarded has_method calls)
- Estimated player-visible payoff per lane

## Expected output
- /home/jess/projects/tw-logs/w28/audit/GAPS.md (ranked gap list)
- /home/jess/projects/tw-logs/w28/audit/LANES.md (lane specs for w28)
- /home/jess/projects/tw-logs/w28/audit/roster-test.log
- Summary: how many classes exist, how many abilities, what blend/chain/tier mechanics are in vs missing

## Boundaries
- Read-only. Do NOT modify any game file.
- Do NOT run the full test suite — just the roster test + opening27 baseline.
- If a data file or script doesn't exist where expected, note it and move on.

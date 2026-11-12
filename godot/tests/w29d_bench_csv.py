"""Collect the canonical Godot benchmark's 20-seed before/after logs."""
import csv
import sys
from pathlib import Path

MISSIONS = ("relay", "rescue", "archive", "envoy")
DIFFICULTIES = ("normal", "hard")
BOTS = ("old", "new")
AFTER = {
    ("relay", "normal", "old"): "relay-contact-old.log",
    ("relay", "normal", "new"): "relay-contact-new.log",
    ("relay", "hard", "old"): "relay-hard-final-old.log",
    ("relay", "hard", "new"): "relay-hard-final-new.log",
    ("rescue", "normal", "old"): "rescue-final-old.log",
    ("rescue", "normal", "new"): "rescue-final-new.log",
    ("rescue", "hard", "old"): "bench-after-old.log",
    ("rescue", "hard", "new"): "bench-after-new.log",
    ("archive", "normal", "old"): "archive-verified-normal-old.log",
    ("archive", "normal", "new"): "archive-verified-normal-new.log",
    ("archive", "hard", "old"): "archive-verified-hard-old.log",
    ("archive", "hard", "new"): "archive-verified-hard-new.log",
    ("envoy", "normal", "old"): "envoy-final-normal-old.log",
    ("envoy", "normal", "new"): "envoy-final-normal-new.log",
    ("envoy", "hard", "old"): "envoy-final-hard-old.log",
    ("envoy", "hard", "new"): "envoy-final-hard-new.log",
}


def parse(path: Path, mission: str, difficulty: str, bot: str) -> list[dict]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        fields = line.split(",")
        if len(fields) < 8 or fields[:4] != ["BENCH", mission, difficulty, bot]:
            continue
        rows.append({
            "seed": int(fields[4]),
            "win": int(fields[5] == "win"),
            "retained_injuries": int(fields[6]),
            "turn": int(fields[7]),
            "reason": fields[8] if len(fields) > 8 else "",
        })
    assert sorted(row["seed"] for row in rows) == list(range(1, 21)), (path, mission, difficulty, bot)
    return rows


def main() -> None:
    log_dir = Path(sys.argv[1])
    output = log_dir / "bench.csv"
    with output.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=("stage", "mission", "difficulty", "bot", "seed", "win", "retained_injuries", "turn", "reason"))
        writer.writeheader()
        for stage in ("before", "after"):
            for mission in MISSIONS:
                for difficulty in DIFFICULTIES:
                    for bot in BOTS:
                        name = f"bench-before-{bot}.log" if stage == "before" else AFTER[(mission, difficulty, bot)]
                        rows = parse(log_dir / name, mission, difficulty, bot)
                        for row in rows:
                            writer.writerow({"stage": stage, "mission": mission, "difficulty": difficulty, "bot": bot, **row})
                        print(stage, mission, difficulty, bot, sum(row["win"] for row in rows), "/20")
    print(output)


if __name__ == "__main__":
    main()

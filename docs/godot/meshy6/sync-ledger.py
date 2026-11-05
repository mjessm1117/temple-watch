"""Mirror gen.mjs's durable task ledger into the requested human ledger."""
import json
from pathlib import Path

root = Path(__file__).parent
ledger = json.loads((root / "tasks/ledger.json").read_text())
lines = [
    "# Meshy batch 6 credit ledger", "",
    "Read-only `GET /openapi/v1/balance`: **15,150 credits** at start (2026-11-04 UTC). Authorized hard cap: **490 credits**. Planned: 14 previews × 20 + 7 refines × 10 = **350 credits**. Three third previews were approved by the brief because both first candidates missed the silhouette target.", "",
    "| Call | Asset | Variant | Mode | Task ID | Credits | Balance after | Status |", "|---:|---|---|---|---|---:|---:|---|",
]
for n, task in enumerate(ledger["tasks"], 1):
    lines.append(f"| {n} | {task['asset']} | {task['letter']} | {task['mode']} | `{task.get('id', '?')}` | {task['cost']} | {task.get('after', '?')} | {task['status']} |")
spent = sum(task["cost"] for task in ledger["tasks"])
lines += ["", f"**Submitted spend: {spent}/490 credits.** Last observed batch balance: **{ledger['tasks'][-1].get('after', '?')}**. Account balance can change independently of this batch.", ""]
(root / "ledger.md").write_text("\n".join(lines))

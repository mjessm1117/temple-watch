# W16 armor Meshy credit ledger

Read-only `GET /openapi/v1/balance` started at **14,375**. This lane submitted **100/120 authorized credits**: four previews at 20 and two refines at 10. The ending observed account balance was **14,265**. Its 110-credit drop includes a 10-credit balance change between the Mk III preview and Mk I retry that is not associated with a task submitted by this lane; submitted lane task charges total 100.

| Piece | Variant | Mode | Task ID | Charge | Balance before | Balance after | Result |
|---|---|---|---|---:|---:|---:|---|
| Mk I | A | Preview | `01a1ade6-ca3c-7611-a4e8-ceeb227044ba` | 20 | 14,375 | 14,355 | Succeeded; long robe, rejected for refinement |
| Mk II | A | Preview | `01a1ade6-d385-73a5-8f17-14ff22be995e` | 20 | 14,355 | 14,335 | Succeeded; accepted |
| Mk III | A | Preview | `01a1ade6-dd07-75df-a899-3849291f6355` | 20 | 14,335 | 14,315 | Succeeded; accepted |
| Mk I | B | Preview | `01a1ade8-d066-72b4-8fe8-8ce690540763` | 20 | 14,305 | 14,285 | Succeeded; body and arms, rejected for refinement |
| Mk II | A | Refine | `01a1ade9-1cd5-7329-a154-453d257e5e7c` | 10 | 14,285 | 14,275 | Succeeded |
| Mk III | A | Refine | `01a1ade9-29e3-7462-85c0-6dddaa153a2d` | 10 | 14,275 | 14,265 | Succeeded |

All balances are read-only observations immediately around submission. Both Mk I previews missed the brief, so neither was refined. The staged Mk I is the first Meshy preview shell, locally cropped and given matte cloth and belt colors.

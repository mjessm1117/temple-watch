# Meshy batch 4 — resume (tech lead decision 2026-11-01)

Read docs/godot/meshy4/MESHY4.md (original spec, all rules still apply) and docs/godot/meshy4/REPORT.md (where you stopped).

## Decision on the blocker
Relay: use a **steady emissive beacon** (bright red/amber light baked as emissive texture). No blink, no runtime/animation change. The blinking requirement is dropped. Do not touch batching code.

## Budget
100 of 300 credits are spent (balance 9,785). **Hard cap: 200 more credits** (stop if the balance would drop below 9,585). Reuse the paid previews; never resubmit them.

## Do
1. cover_full_temple: refine **C** (colonnade + lintel, scored 4). Tech lead reviewed it and agrees. Texture it in the temple column palette, fit to the full-cover size, uniform scale only, LOD0 ≤3K / LOD1 ≤800.
2. cover_full_snow: refine **A** (ice spire, scored 4). The texture must show dark rock under the snow and ice, not pure white (pure white was the original problem). Same LOD caps.
3. cover_half_snow: generate up to 3 previews (low snow drift over rocks/crates, wider than tall). Refine only one that scores ≥4.
4. obj_relay: generate up to 3 previews (lattice mast + dish + base housing + steady beacon). Refine only one that scores ≥4.
5. Integrate the accepted ones (props.json entries for these 4 only), then take the after screenshots and stage shots the original spec asks for, and finish REPORT.md (accepted/rejected, credits, tris, before→after).
6. `./godot/test.sh` exit 0, 0 SCRIPT ERROR, all suites 0 failures. Commit on meshy/batch4. Don't push.

The file lease is the same as MESHY4.md. If something outside it is needed again, skip that asset, keep its current model and note it in REPORT.md. Finish the rest; don't stop the whole batch.

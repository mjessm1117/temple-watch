# Renderer upgrade proposal (11-02, for Jess)
Premise check: house-md relayed "three.js WebGPU". That's the web game, which is frozen. The live game is Godot 4.7.2 Forward+ (Vulkan). So the upgrade is Godot settings/features, not three.js.

Case against first:
- Art, not renderer, is the bottleneck: models are low-detail; fancy lighting on plain boxes still looks plain.
- Perf: wave 9 reached 245 fps mean / 9.1 ms p95. SDFGI/volumetric fog can cost 3–8 ms on a 4090 and far more on a Windows laptop (future export target).
- Tuning risk: GI on procedural geometry causes light leaks/flicker; needs per-theme tuning.

Case for:
- Big headroom (245 fps) to spend.
- Cheap wins: TAA/FSR2 (no jaggies), volumetric fog + light shafts, SSR on wet/metal floors, SDFGI bounce light, DOF on action cam, color grading per theme, Poly Haven PBR ground textures.

Options:
A. Quality preset "High": SDFGI + volumetric fog + TAA + SSR + per-theme grading, toggle in settings, keep 60 fps floor (≈1 Codex lane).
B. A + Poly Haven PBR ground/rock textures and Meshy hero props (art + renderer together).
C. Wait: do Meshy batch first, upgrade renderer after models improve.
Recommendation: C then A (art first, then light it). Confidence Med.

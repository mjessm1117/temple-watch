# Renderer upgrade proposal (11-02, for Jess) — v2 with mobile constraint
Premise check: house-md relayed "three.js WebGPU". That is the frozen web game. The live game is Godot 4.7.2 Forward+ (Vulkan). Godot equivalents:
- WebGL2 baseline = Godot **Compatibility** renderer (OpenGL ES 3 / WebGL2). Runs on phones and in browsers.
- "Optional WebGPU" = Godot **Forward+** (Vulkan/D3D12/Metal) as the desktop-only high tier. Godot WebGPU export: not something I can confirm exists in 4.7 (Low confidence) — don't plan on it.
- Fallback: game picks tier at startup from the renderer/GPU it gets; user can override in Settings.

Case against first:
- Art, not renderer, is the bottleneck: plain models under fancy light still look plain.
- Mobile cuts the ceiling: SSAO, SDFGI, volumetric fog, SSR do not exist in Compatibility. Every look must have a cheap fallback, so each effect costs double work.
- Wave 9's look already relies on SSAO and soft shadows; the phone tier will look noticeably flatter.
- Windows-laptop and phone perf is unmeasured; numbers below are estimates until tested on a real device.

Case for:
- Desktop has headroom (245 fps mean / 9.1 ms p95 on largest map).
- Baked look (lightmaps, painted AO in textures, decals) helps BOTH tiers, and is the right way to look good on phones.

Quality tiers (estimates, to verify on device):
| Tier | Renderer | Effects | Target |
|---|---|---|---|
| Low (phones, old laptops) | Compatibility | 1 shadowed light, baked AO/lightmaps, vertex fog, FXAA, no post | 30 fps floor, 60 goal |
| Medium (laptops) | Forward+ | + SSAO half-res, TAA/FSR, glow | 60 |
| High (desktop) | Forward+ | + SDFGI, volumetric fog, SSR, DOF on action cam, color grade | 60+ |

Phone budget (Low tier, mid-range phone; estimates, Med confidence):
- Draw calls ≤150 per frame (MultiMesh/batching already in place: 99 on desktop).
- Triangles on screen ≤300K.
- Units: LOD0 ≤8K tris, LOD1 ≤2.5K, LOD2 ≤800. Props/cover: ≤3K LOD0, ≤800 LOD1. Objectives ≤4K.
- Textures: ≤1024² for units/hero props, ≤512² for props, ASTC/ETC2 compressed, one atlas per theme where possible. Total VRAM ≤256 MB.
- Lights: ≤1 shadowed directional + ≤4 unshadowed local (already capped at 4).
- Meshy rule: every Meshy asset ships with 3 LODs inside these caps (Godot import LOD + prop.mjs simplify).

Options:
A. Tier system + Low/Compatibility path first (prove it runs on a phone-class renderer), then High extras.
B. Desktop High extras first (SDFGI, fog, SSR), Low tier later.
C. Art first (Meshy batches + Poly Haven textures within the phone budget), then A.
Recommendation: C then A. Art inside the budget now avoids redoing models later. Confidence Med.

#!/usr/bin/env bash
set -euo pipefail
for asset in cover_full_temple cover_full_snow cover_half_snow obj_relay; do
 for letter in A B C; do
  node tools/meshy/gen.mjs art/meshy4 "$asset" --preview-only --letter "$letter" --brief "art/meshy4/$asset.json" --submit-only
 done
done
for asset in cover_full_temple cover_full_snow cover_half_snow obj_relay; do
 for letter in A B C; do
  node tools/meshy/gen.mjs art/meshy4 "$asset" --preview-only --letter "$letter" --brief "art/meshy4/$asset.json" --resume
 done
done

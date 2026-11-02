#!/usr/bin/env bash
set -euo pipefail
set -a
. /home/jess/hive/.env
set +a
check_balance() {
  local cost="$1" balance
  balance="$(node -e 'fetch("https://api.meshy.ai/openapi/v1/balance",{headers:{Authorization:"Bearer "+process.env.MESHY_KEY}}).then(r=>r.json()).then(j=>console.log(j.balance))')"
  if (( balance - cost < 9585 )); then
    echo "STOP: balance $balance, next task $cost, floor 9585" >&2
    exit 2
  fi
  echo "balance before next task: $balance"
}
submit_refine() {
  local asset="$1" letter="$2" id="$3"
  check_balance 10
  node tools/meshy/gen.mjs art/meshy4 "$asset" --refine-preview "$id" --letter "$letter" --brief "art/meshy4/$asset.json" --submit-only
}
submit_preview() {
  local asset="$1" letter="$2"
  check_balance 20
  node tools/meshy/gen.mjs art/meshy4 "$asset" --preview-only --letter "$letter" --brief "art/meshy4/$asset.json" --submit-only
}
submit_refine cover_full_temple C 01a19b41-6f27-770b-a956-07c6a8848a37
submit_refine cover_full_snow A 01a19b41-7787-7758-af7a-86fffb6b6eef
for asset in cover_half_snow obj_relay; do
  for letter in A B C; do
    submit_preview "$asset" "$letter"
  done
done

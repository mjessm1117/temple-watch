#!/usr/bin/env bash
# Build, smoke-test and publish the Windows desktop build as the newest GitHub Release.
# Only run when Jess asks ("push to Windows").
#   tools/release_windows.sh            build + test + upload (becomes /releases/latest)
#   tools/release_windows.sh --dry-run  build + test + zip only, no upload
set -euo pipefail

REPO="mjessm1117/temple-watch"
ASSET="TempleWatch-Windows.zip"   # stable name: /releases/latest/download/$ASSET always works
GODOT="${GODOT:-/home/jess/projects/.tools/godot/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/windows"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

die() { echo "RELEASE FAILED: $*" >&2; exit 1; }
step() { echo "== $*"; }

cd "$ROOT"
VER="$("$GODOT" --version | sed -E 's/^([0-9.]+)\.stable.*/\1/')"
SHA="$(git rev-parse --short HEAD)"
DATE="$(date +%F)"
TAG="godot-windows-$DATE-$SHA"
BUILD="$DATE, commit $SHA, Godot $VER"
[ -z "$(git status --porcelain --untracked-files=no -- godot)" ] || die "godot/ has uncommitted changes; commit first"

step "1/6 export templates ($VER)"
TPL="$HOME/.local/share/godot/export_templates/$VER.stable"
if [ ! -f "$TPL/windows_release_x86_64.exe" ]; then
  local_tmp="$(mktemp -d)"
  curl -fsSL -o "$local_tmp/t.tpz" "https://github.com/godotengine/godot/releases/download/$VER-stable/Godot_v$VER-stable_export_templates.tpz"
  mkdir -p "$TPL"
  unzip -q -o -j "$local_tmp/t.tpz" 'templates/version.txt' 'templates/windows_*' -d "$TPL"
  rm -f "$local_tmp/t.tpz"; rmdir "$local_tmp"
fi

step "2/6 import + export"
mkdir -p "$OUT"; rm -f "$OUT/TempleWatch.exe"
( cd godot && "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
  timeout 900 "$GODOT" --headless --path . --export-release "Windows Desktop" ../build/windows/TempleWatch.exe > "$OUT/export.log" 2>&1 ) || die "export failed (see $OUT/export.log)"
[ -s "$OUT/TempleWatch.exe" ] || die "no exe produced"
! grep -qE 'SCRIPT ERROR|Parse Error' "$OUT/export.log" || die "script errors during export"

step "3/6 smoke test (boot exported pack under Xvfb)"
SMOKE="$(mktemp -d)"
for scene in "" res://scenes/rescue.tscn res://scenes/temple.tscn res://scenes/galaxy.tscn; do
  timeout 150 xvfb-run -a -s "-screen 0 1366x768x24" "$GODOT" --main-pack "$OUT/TempleWatch.exe" \
    --resolution 1366x768 --fixed-fps 30 --write-movie "$SMOKE/f.png" --quit-after 60 $scene > "$SMOKE/log" 2>&1 || true
  n="$(ls "$SMOKE"/f*.png 2>/dev/null | wc -l)"
  [ "$n" -ge 30 ] || die "smoke ${scene:-menu}: only $n frames"
  ! grep -qE 'SCRIPT ERROR|Parse Error|ERROR:' "$SMOKE/log" || die "smoke ${scene:-menu}: errors in log"
  cp "$(ls "$SMOKE"/f*.png | tail -1)" "$OUT/smoke-$(basename "${scene:-menu}" .tscn).png"
  rm -f "$SMOKE"/f*.png
done
rm -f "$SMOKE"/*; rmdir "$SMOKE"   # --write-movie also leaves an audio file

step "4/6 secret scan"
if [ -f /home/jess/hive/.env ]; then
  while IFS='=' read -r k v; do
    v="${v%\"}"; v="${v#\"}"
    [ ${#v} -ge 16 ] && grep -qaF -- "$v" "$OUT/TempleWatch.exe" && die "secret $k found in exe"
  done < <(grep -E '^[A-Z0-9_]+=' /home/jess/hive/.env)
fi
! grep -qaE 'msy_[A-Za-z0-9]{10}|ghp_[A-Za-z0-9]{20}|sk-[A-Za-z0-9]{20}' "$OUT/TempleWatch.exe" || die "key-like string in exe"

step "5/6 zip"
sed "s/{{BUILD}}/$BUILD/" tools/windows/INSTALL.md > "$OUT/INSTALL.md"
rm -f "$ROOT/build/$ASSET"
( cd "$OUT" && zip -q -9 "$ROOT/build/$ASSET" TempleWatch.exe INSTALL.md )
ls -la "$ROOT/build/$ASSET"
if [ "$DRY" = 1 ]; then echo "DRY RUN OK: $ROOT/build/$ASSET ($BUILD), not uploaded"; exit 0; fi

step "6/6 upload + verify"
# Tag sits on GitHub main (local commits may be unpushed); the title records the real build commit.
gh release create "$TAG" "$ROOT/build/$ASSET" -R "$REPO" --target main --latest \
  --title "Temple Watch — Windows ($DATE, $SHA)" --notes-file "$OUT/INSTALL.md"
DL="https://github.com/$REPO/releases/latest/download/$ASSET"
CHECK="$(mktemp)"
curl -fsSL -o "$CHECK" "$DL" || die "latest download not reachable"
cmp -s "$CHECK" "$ROOT/build/$ASSET" || die "latest download differs from local zip (latest may not have moved)"
rm -f "$CHECK"
echo "RELEASE OK: https://github.com/$REPO/releases/tag/$TAG"
echo "Latest: https://github.com/$REPO/releases/latest"

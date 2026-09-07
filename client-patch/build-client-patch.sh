#!/usr/bin/env bash
# build-client-patch.sh — produce the player-facing client-patch/out/patch-V.mpq:
# mod-individual-progression's own patch-V (its Spell.dbc/SkillLineAbility.dbc) + this mod's
# custom VISIBLE spell rows merged in. Players copy the result to World of Warcraft/Data/.
#
# Usage: client-patch/build-client-patch.sh [--from-ip | --base <patch-V.mpq>]
#   --from-ip (default)  git clone --depth 1 IP, extract optional/patch-V.7z (needs 7z)
#   --base FILE          merge into an already-downloaded patch-V.mpq
# Needs client-patch/mpqpack + mpqread (client-patch/build-mpqpack.sh) and uv or python3+PyYAML.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/client-patch/out"; mkdir -p "$OUT_DIR"
MODE="${1:---from-ip}"
case "$MODE" in
  --from-ip)
    command -v 7z >/dev/null || { echo "ERROR: 7z (p7zip) required to extract IP's patch-V.7z" >&2; exit 1; }
    TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
    echo "==> Fetching mod-individual-progression (shallow) for optional/patch-V.7z"
    git clone -q --depth 1 https://github.com/ZhengPeiRu21/mod-individual-progression.git "$TMP/ip"
    7z x -y -o"$TMP/v" "$TMP/ip/optional/patch-V.7z" >/dev/null
    BASE="$(find "$TMP/v" -type f -iname 'patch-V.mpq' | head -1)"
    [[ -n "$BASE" ]] || { echo "ERROR: patch-V.mpq not found inside IP's patch-V.7z" >&2; exit 1; } ;;
  --base) BASE="${2:?--base needs a path}" ;;
  *) echo "usage: $0 [--from-ip | --base <patch-V.mpq>]" >&2; exit 2 ;;
esac
bash "$ROOT/client-patch/merge-into-patch.sh" "$BASE" "$OUT_DIR/patch-V.mpq"
echo "==> Done: $OUT_DIR/patch-V.mpq — copy to each client's World of Warcraft/Data/"

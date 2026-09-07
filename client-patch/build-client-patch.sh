#!/usr/bin/env bash
# build-client-patch.sh — produce the player-facing patch-V.mpq: mod-individual-progression's own
# patch-V (its Spell.dbc / SkillLineAbility.dbc) + this mod's custom VISIBLE spell rows merged in.
# Players copy the result to World of Warcraft/Data/.
#
# Usage: client-patch/build-client-patch.sh [--from-ip | --base <patch-V.mpq>] [--out FILE] [--mode auto|native|docker]
#   --from-ip (default)  fetch IP (git clone --depth 1) and extract optional/patch-V.7z as the base
#   --base FILE          merge into a patch-V.mpq you already have
#   --out FILE           default client-patch/out/patch-V.mpq
#   --mode               auto (default; also $ERA_MPQ_MODE): use the native tools when they are ALL present
#                        (mpqpack+mpqread, python3+PyYAML or uv, 7z for --from-ip); otherwise build and run
#                        everything inside a throwaway Docker image (client-patch/Dockerfile) — so a host
#                        with only Docker still gets the full patch. `native` / `docker` force one path.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CP="$ROOT/client-patch"
MODE="${ERA_MPQ_MODE:-auto}"; SRC="--from-ip"; BASE=""; OUT="$CP/out/patch-V.mpq"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-ip) SRC="--from-ip"; shift ;;
    --base) SRC="--base"; BASE="${2:?--base needs a path}"; shift 2 ;;
    --out) OUT="${2:?--out needs a path}"; shift 2 ;;
    --mode) MODE="${2:?--mode needs auto|native|docker}"; shift 2 ;;
    *) echo "usage: $0 [--from-ip | --base <patch-V.mpq>] [--out FILE] [--mode auto|native|docker]" >&2; exit 2 ;;
  esac
done
[[ "$SRC" == "--base" && ! -f "$BASE" ]] && { echo "ERROR: base mpq $BASE not found" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
IP_URL="https://github.com/ZhengPeiRu21/mod-individual-progression.git"

have_native () {
  [[ -x "$CP/mpqpack" && -x "$CP/mpqread" ]] || return 1
  command -v uv >/dev/null 2>&1 || python3 -c 'import yaml' >/dev/null 2>&1 || return 1
  [[ "$SRC" == "--base" ]] || command -v 7z >/dev/null 2>&1 || return 1
  return 0
}
can_build_native () {
  for t in git cmake gcc g++ make; do command -v "$t" >/dev/null 2>&1 || return 1; done
  command -v uv >/dev/null 2>&1 || python3 -c 'import yaml' >/dev/null 2>&1 || return 1
  [[ "$SRC" == "--base" ]] || command -v 7z >/dev/null 2>&1 || return 1
  return 0
}

if [[ "$MODE" == "auto" ]]; then
  if have_native; then MODE=native
  elif command -v docker >/dev/null 2>&1; then MODE=docker
  elif can_build_native; then MODE=native
  else
    echo "ERROR: cannot build the client patch on this host — need EITHER Docker, OR: git cmake gcc g++ make" >&2
    echo "       zlib1g-dev libbz2-dev, python3 + PyYAML (or uv), and 7z (p7zip-full) for --from-ip." >&2
    exit 1
  fi
fi

fetch_ip_base () {   # $1 = scratch dir; prints the extracted patch-V.mpq path
  git clone -q --depth 1 "$IP_URL" "$1/ip" >&2
  7z x -y -o"$1/v" "$1/ip/optional/patch-V.7z" >/dev/null
  find "$1/v" -type f -iname 'patch-V.mpq' | head -1
}

case "$MODE" in
  native)
    if [[ ! -x "$CP/mpqpack" || ! -x "$CP/mpqread" ]]; then
      echo "==> Building mpqpack/mpqread (StormLib)"; bash "$CP/build-mpqpack.sh"
    fi
    if [[ "$SRC" == "--from-ip" ]]; then
      TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
      echo "==> Fetching mod-individual-progression for optional/patch-V.7z"
      BASE="$(fetch_ip_base "$TMP")"; [[ -n "$BASE" ]] || { echo "ERROR: patch-V.mpq not inside IP's patch-V.7z" >&2; exit 1; }
    fi
    bash "$CP/merge-into-patch.sh" "$BASE" "$OUT" ;;
  docker)
    command -v docker >/dev/null 2>&1 || { echo "ERROR: --mode docker but docker is not installed" >&2; exit 1; }
    IMG="mod-era-talents-mpq:local"
    echo "==> Building the MPQ tool image ($IMG; cached after the first run)"
    docker build -q -t "$IMG" "$CP" >/dev/null
    OUTDIR="$(cd "$(dirname "$OUT")" && pwd)"; OUTNAME="$(basename "$OUT")"
    ARGS=(--rm -u "$(id -u):$(id -g)" -v "$ROOT:/work:ro" -v "$OUTDIR:/out")
    if [[ "$SRC" == "--base" ]]; then
      BASEDIR="$(cd "$(dirname "$BASE")" && pwd)"; ARGS+=(-v "$BASEDIR:/base:ro")
      SCRIPT="bash /work/client-patch/merge-into-patch.sh /base/$(basename "$BASE") /out/$OUTNAME"
    else
      echo "==> Fetching mod-individual-progression for optional/patch-V.7z (inside the container)"
      SCRIPT="set -e; git clone -q --depth 1 $IP_URL /tmp/ip; 7z x -y -o/tmp/v /tmp/ip/optional/patch-V.7z >/dev/null; B=\$(find /tmp/v -type f -iname 'patch-V.mpq' | head -1); [ -n \"\$B\" ]; bash /work/client-patch/merge-into-patch.sh \"\$B\" /out/$OUTNAME"
    fi
    docker run "${ARGS[@]}" "$IMG" bash -c "$SCRIPT" ;;
  *) echo "ERROR: unknown --mode $MODE" >&2; exit 2 ;;
esac
echo "==> Done: $OUT — copy to each client's World of Warcraft/Data/"

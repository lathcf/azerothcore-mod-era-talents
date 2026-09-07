#!/usr/bin/env bash
# fetch-base-dbc.sh — stage the generator's base DBCs into client-patch/base/ (gitignored).
#
# gen_era_talents.py --custom-sql clones era spells from TEMPLATE rows of a Spell.dbc, and the
# client-patch builders append rows onto Spell.dbc / SkillLineAbility.dbc. The base is
# mod-individual-progression's SERVER-side DBC set — the Spell.dbc inside its optional/patch-V.7z
# and the SkillLineAbility.dbc inside optional/dbc.7z — so the templates match what an IP server
# actually runs. Needed only to RUN the pipeline (tools/era-regen.sh); an installed server needs none.
#
# Usage: tools/fetch-base-dbc.sh [<path-to-mod-individual-progression-checkout>]
#   (default: git clone --depth 1 from GitHub into a temp dir). Requires 7z (p7zip).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/client-patch/base"
command -v 7z >/dev/null || { echo "ERROR: 7z (p7zip) required" >&2; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if [[ -n "${1:-}" ]]; then IP="$1"; else
  echo "==> Fetching mod-individual-progression (shallow)"
  git clone -q --depth 1 https://github.com/ZhengPeiRu21/mod-individual-progression.git "$TMP/ip"; IP="$TMP/ip"
fi
[[ -f "$IP/optional/patch-V.7z" && -f "$IP/optional/dbc.7z" ]] || { echo "ERROR: $IP/optional/{patch-V.7z,dbc.7z} not found" >&2; exit 1; }
mkdir -p "$OUT"
7z x -y -o"$TMP/v" "$IP/optional/patch-V.7z" >/dev/null
7z x -y -o"$TMP/d" "$IP/optional/dbc.7z" >/dev/null
PV="$(find "$TMP/v" -type f -iname 'patch-V.mpq' | head -1)"
[[ -n "$PV" ]] || { echo "ERROR: patch-V.mpq not inside patch-V.7z" >&2; exit 1; }
if [[ -x "$ROOT/client-patch/mpqread" ]]; then
  "$ROOT/client-patch/mpqread" "$PV" 'DBFilesClient\Spell.dbc' "$OUT/Spell.dbc"
else
  echo "ERROR: client-patch/mpqread not built (run client-patch/build-mpqpack.sh) — needed to extract Spell.dbc from patch-V.mpq" >&2; exit 1
fi
SLA="$(find "$TMP/d" -type f -iname 'SkillLineAbility.dbc' | head -1)"
[[ -n "$SLA" ]] && cp -f "$SLA" "$OUT/SkillLineAbility.dbc" || echo "NOTE: SkillLineAbility.dbc not in dbc.7z — skipped"
ls -la "$OUT"
echo "==> base DBCs staged in client-patch/base/ (gitignored)"

#!/usr/bin/env bash
# Merge era-talents' custom VISIBLE client spells (the Chilled debuff, etc.) INTO an existing client
# patch MPQ, so both coexist. Use this when another patch already ships a Spell.dbc that loads AFTER
# ours and would otherwise override it — notably the IP mod's patch-V.mpq (V loads after patch-4).
#
# It extracts the TARGET mpq's Spell.dbc, appends our rows onto THAT (so the target's own spell edits
# are preserved), and writes the merged Spell.dbc back into a COPY of the target mpq (all the target's
# other files are kept). The server needs no change.
#
# Usage: client-patch/merge-into-patch.sh <target-patch.mpq> [out.mpq]
#   e.g. client-patch/merge-into-patch.sh client-patch/out/patch-V.mpq
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MPQPACK="$ROOT/client-patch/mpqpack"
MPQREAD="$ROOT/client-patch/mpqread"
# The dataset list comes from era-data/datasets.txt (the single source of truth), in manifest
# order — adding a class needs no edit here. (generation_stamp() sorts its inputs, so the order
# is not itself load-bearing for the stamp; era_audit's cross-dataset id check forbids the
# duplicate-id case where a later dataset could overwrite an earlier one's row.)
DATASETS=()
while read -r rel _d _c || [[ -n "$rel" ]]; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  DATASETS+=("$ROOT/era-data/$rel")
done < "$ROOT/era-data/datasets.txt"

# uv is the dev-box default; a production host has no uv but ships a
# system python3 with PyYAML, so fall back to that rather than hard-failing.
if command -v uv >/dev/null 2>&1; then
  PYRUN=(uv run --with pyyaml python)
elif python3 -c 'import yaml' >/dev/null 2>&1; then
  PYRUN=(python3)
else
  echo "ERROR: need 'uv', or python3 with PyYAML installed" >&2; exit 1
fi

STAMP="$("${PYRUN[@]}" - "$ROOT/tools" "${DATASETS[@]}" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import gen_era_talents as G
print(G.generation_stamp(sys.argv[2:]))
PY
)"
echo "==> Generation stamp: $STAMP"

TARGET="${1:?usage: merge-into-patch.sh <target-patch.mpq> [out.mpq]}"
OUT="${2:-$ROOT/client-patch/out/$(basename "$TARGET")}"

[ -x "$MPQPACK" ] || { echo "ERROR: $MPQPACK missing" >&2; exit 1; }
[ -x "$MPQREAD" ] || { echo "ERROR: $MPQREAD missing" >&2; exit 1; }
[ -f "$TARGET" ]  || { echo "ERROR: target mpq $TARGET not found" >&2; exit 1; }

STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$(dirname "$OUT")"

echo "==> Extracting DBFilesClient\\Spell.dbc from $TARGET"
"$MPQREAD" "$TARGET" 'DBFilesClient\Spell.dbc' "$STAGE/base-spell.dbc"

echo "==> Appending era-talent visible rows onto it"
"${PYRUN[@]}" "$ROOT/tools/build_client_dbc.py" \
  --dataset "${DATASETS[@]}" --base-dbc "$STAGE/base-spell.dbc" --out "$STAGE/merged-spell.dbc" \
  --stamp "$STAMP"

echo "==> Writing merged Spell.dbc back into a copy of the mpq -> $OUT"
cp "$TARGET" "$OUT"
"$MPQPACK" "$OUT" 'DBFilesClient\Spell.dbc' "$STAGE/merged-spell.dbc"

# Same merge for SkillLineAbility.dbc: puts custom CASTABLE spells (PI/VE) in the right spellbook
# tab instead of General. patch-V ships its own SkillLineAbility.dbc, so append onto THAT one.
echo "==> Extracting + merging DBFilesClient\\SkillLineAbility.dbc"
"$MPQREAD" "$TARGET" 'DBFilesClient\SkillLineAbility.dbc' "$STAGE/base-sla.dbc"
"${PYRUN[@]}" "$ROOT/tools/build_client_skilllineability.py" \
  --dataset "${DATASETS[@]}" --base-dbc "$STAGE/base-sla.dbc" --out "$STAGE/merged-sla.dbc"
"$MPQPACK" "$OUT" 'DBFilesClient\SkillLineAbility.dbc' "$STAGE/merged-sla.dbc"

echo "==> Verifying the merged archive"
"$MPQREAD" "$OUT" 'DBFilesClient\Spell.dbc' "$STAGE/verify.dbc" >/dev/null
python3 - "$STAGE/verify.dbc" <<'PY'
import struct, sys
raw = open(sys.argv[1], "rb").read()
_, rc, _, _, _ = struct.unpack("<4siiii", raw[:20])
print(f"    merged Spell.dbc has {rc} records (target + our custom rows)")
PY
echo "==> Done: $OUT"
echo "    Install: replace the target patch in each client's Data/ with this file, then restart WoW."

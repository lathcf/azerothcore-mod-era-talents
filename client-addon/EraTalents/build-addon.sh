#!/usr/bin/env bash
# Regenerate the addon's per-(era,class) Lua from every dataset in era-data/datasets.txt.
# Called by tools/era-regen.sh (the only supported ship path); safe to run alone.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/client-addon/EraTalents/data/generated"
mkdir -p "$OUT"
if command -v uv >/dev/null 2>&1; then PYRUN=(uv run --with pyyaml python); else PYRUN=(python3); fi
while read -r rel _data _custom || [[ -n "$rel" ]]; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  era="$(basename "$(dirname "$rel")")"          # vanilla | tbc
  cls="$(basename "$rel" .yaml)"                 # mage
  Era="$([[ "$era" == tbc ]] && echo TBC || echo "${era^}")"   # Vanilla | TBC
  "${PYRUN[@]}" "$ROOT/tools/gen_era_talents.py" --lua "$ROOT/era-data/$rel" -o "$OUT/${cls^}${Era}.lua"
done < "$ROOT/era-data/datasets.txt"

#!/usr/bin/env bash
# apply-patches.sh — apply this module's source patches to an AzerothCore checkout.
#
# Usage: ./apply-patches.sh <azerothcore-root>
#
# Always:   patches/core/*                   (inert until a character is in an era band)
#           patches/individual-progression/* (IP is REQUIRED — aborts if the module is missing)
# If present: patches/playerbots/*           (<root>/modules/mod-playerbots exists)
#             patches/multibot-bridge/*      (<root>/modules/mod-multibot-bridge exists)
#
# Idempotent: an already-applied patch is skipped; one that no longer applies aborts loudly
# (upstream moved the code — regenerate it with the matching tools/regen-*.sh). Re-run after any
# `git reset`/`git pull` of the core or those modules, and BEFORE building.
# Patches were cut against azerothcore-wotlk 413bea61 (mod-playerbots fork), mod-playerbots b949b50,
# mod-individual-progression 977e200, mod-multibot-bridge 759c100.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AC="${1:?usage: $0 <azerothcore-root>}"
[[ -d "$AC/src/server" ]] && git -C "$AC" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "ERROR: $AC is not an AzerothCore git checkout" >&2; exit 1; }
[[ -d "$AC/modules/mod-individual-progression" ]] || {
  echo "ERROR: $AC/modules/mod-individual-progression is missing — mod-era-talents requires it." >&2
  echo "       git clone https://github.com/ZhengPeiRu21/mod-individual-progression.git $AC/modules/mod-individual-progression" >&2
  exit 1; }

apply_dir () {   # $1 = patches/<target> dir
  local patch name
  for patch in "$1"/*.patch; do
    [[ -e "$patch" ]] || continue
    name="${patch#"$HERE/patches/"}"
    if git -C "$AC" apply --reverse --check "$patch" >/dev/null 2>&1; then
      echo "    already applied: $name"
    elif git -C "$AC" apply --check "$patch" >/dev/null 2>&1; then
      git -C "$AC" apply "$patch"
      echo "    applied:         $name"
    else
      echo "ERROR: $name does not apply to $AC (upstream moved?)." >&2
      echo "       Regenerate it with the matching tools/regen-*.sh, or open an issue with your commit ids." >&2
      exit 1
    fi
  done
}

echo "==> mod-era-talents patches -> $AC"
apply_dir "$HERE/patches/core"
apply_dir "$HERE/patches/individual-progression"
if [[ -d "$AC/modules/mod-playerbots" ]]; then apply_dir "$HERE/patches/playerbots"; else echo "    (mod-playerbots not present — bot patches skipped)"; fi
if [[ -d "$AC/modules/mod-multibot-bridge" ]]; then apply_dir "$HERE/patches/multibot-bridge"; else echo "    (mod-multibot-bridge not present — bridge patch skipped)"; fi
echo "==> done"

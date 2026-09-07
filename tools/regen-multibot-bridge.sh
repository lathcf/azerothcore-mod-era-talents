#!/usr/bin/env bash
# regen-multibot-bridge.sh — re-cut patches/multibot-bridge/01-era-talents.patch from an AzerothCore
# worktree whose modules/mod-multibot-bridge clone already carries the edit.
#
# Usage: tools/regen-multibot-bridge.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch for Unit.cpp)
# This patch needs neither, but accepts both for a uniform interface.
#
# ONE file, touched by NO other patch (verified 2026-08-26) -> baseline = pristine clone HEAD.
# The --src/--dst prefix rewrite makes the output apply from the AC ROOT, exactly how
# apply-patches.sh applies every patch (git -C "$AC" apply).
#
# LITERAL PATHS ONLY on every git/cp line — the shell does not word-split an unquoted $var.
# Re-runnable from the edited working-tree state; leaves the worktree patched, index pristine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AC="${1:?usage: $0 <azerothcore-root> [--extra-baseline P]... [--extra-contaminator P]...}"; shift
EXTRA_BASELINES=(); EXTRA_CONTAMINATORS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --extra-baseline)     EXTRA_BASELINES+=("$(realpath "$2")"); shift 2 ;;
    --extra-contaminator) EXTRA_CONTAMINATORS+=("$(realpath "$2")"); shift 2 ;;
    *) echo "unknown arg $1" >&2; exit 2 ;;
  esac
done
AC="$(realpath "$AC")"
MB="$AC/modules/mod-multibot-bridge"
OUT="$ROOT/patches/multibot-bridge/01-era-talents.patch"
REL="src/MultiBotBridge.cpp"

[[ -d "$MB/.git" ]] || { echo "ERROR: $MB is not a git clone" >&2; exit 1; }

# The edit must actually be present in the worktree.
grep -q "EraTalentBots_SpecTabs" "$MB/$REL" \
  || { echo "ERROR: $REL has no era spec-tab hook — multibot-bridge/01 not applied to the worktree?" >&2; exit 1; }

TMP="$(mktemp -d)"
restore() {
  if [[ -f "$TMP/MultiBotBridge.cpp" ]]; then cp "$TMP/MultiBotBridge.cpp" "$MB/$REL"; fi
  git -C "$MB" reset -q -- "$REL" 2>/dev/null || true
  rm -rf "$TMP"
}
trap restore EXIT

# 1. Save the current (patched) copy.
cp "$MB/$REL" "$TMP/MultiBotBridge.cpp"

# 2. Baseline = pristine; stage it, then restore the patched worktree state.
git -C "$MB" checkout -- "$REL"
if grep -q "EraTalentBots_SpecTabs" "$MB/$REL"; then
  echo "GATE FAIL: pristine baseline already carries the hunk (upstream absorbed it?)" >&2; exit 1
fi
git -C "$MB" add -- "$REL"
cp "$TMP/MultiBotBridge.cpp" "$MB/$REL"

# 3. Index(baseline) vs worktree(patched) == exactly our hunk.
git -C "$MB" diff \
  --src-prefix=a/modules/mod-multibot-bridge/ \
  --dst-prefix=b/modules/mod-multibot-bridge/ \
  -- "$REL" \
  > "$TMP/out.patch"

# 4. Output gates.
[[ -s "$TMP/out.patch" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$TMP/out.patch")" -eq 1 ]] \
  || { echo "GATE FAIL: expected exactly 1 file in the patch" >&2; exit 1; }
grep -q "EraTalentBots_SpecTabs" "$TMP/out.patch" \
  || { echo "GATE FAIL: patch missing the era spec-tab hook" >&2; exit 1; }

cp "$TMP/out.patch" "$OUT"
echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'

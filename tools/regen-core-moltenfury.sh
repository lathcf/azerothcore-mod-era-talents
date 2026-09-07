#!/usr/bin/env bash
# regen-core-moltenfury.sh — re-cut patches/core/06-molten-fury-era-window.patch from an
# AzerothCore worktree that already carries the edit.
#
# Usage: tools/regen-core-moltenfury.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch, which
#                          also edits Unit.cpp and is applied BEFORE ours)
#
# CORE-ONLY patch: touches src/server/game/Entities/Unit/Unit.cpp in the AC checkout itself, so a
# plain `git -C "$AC" diff` with NO prefix rewriting is correct (apply-patches.sh runs
# `git -C "$AC" apply` from the AC root). Do NOT copy --src-prefix/--dst-prefix from module regens.
#
# BASELINE-AWARE: Unit.cpp is ALSO edited by this repo's core/01 (shatter crit vs frozen) and core/05
# (wand-spec leak) — and, in the overlay install, by its core bot-aura-batching patch (pass that as
# --extra-contaminator). Reverse them all newest-first (core/05, core/01, then the extras in reverse
# list order — extras are applied BEFORE this repo's patches in production), diff, then re-apply in
# application order. If a NEW patch starts touching Unit.cpp, add it here AND to the other Unit.cpp
# regen scripts.
#
# WHAT THIS PATCH IS: the `case 4920: case 4919:` Molten Fury arm in Unit::SpellPctDamageModsDone
# gates on AURA_STATE_HEALTHLESS_35_PERCENT (WotLK). TBC's window is 20%. For an
# OVERRIDE_CLASS_SCRIPTS aura whose spell id is in the reserved era band [920000, 950000) the arm
# uses AURA_STATE_HEALTHLESS_20_PERCENT instead; stock auras are unchanged. mod-era-talents TBC node
# 20842.
#
# LITERAL PATHS ONLY on every git line (the shell does not word-split an unquoted $var).
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
OUT="$ROOT/patches/core/06-molten-fury-era-window.patch"
UNIT="src/server/game/Entities/Unit/Unit.cpp"

[[ -d "$AC/.git" ]] || { echo "ERROR: $AC is not a git clone" >&2; exit 1; }
[[ -f "$AC/$UNIT" ]] || { echo "ERROR: missing core Unit.cpp in the AC worktree" >&2; exit 1; }

grep -q "TBC Molten Fury's window is 20%" "$AC/$UNIT" \
  || { echo "ERROR: Unit.cpp has no era Molten Fury hunk — core/06 not applied?" >&2; exit 1; }

CONTAM_01="$ROOT/patches/core/01-shatter-crit-vs-frozen.patch"
CONTAM_05="$ROOT/patches/core/05-wand-spec-era-no-spell-leak.patch"
[[ -f "$CONTAM_01" ]] || { echo "ERROR: missing $CONTAM_01" >&2; exit 1; }
[[ -f "$CONTAM_05" ]] || { echo "ERROR: missing $CONTAM_05" >&2; exit 1; }
for p in ${EXTRA_CONTAMINATORS[@]+"${EXTRA_CONTAMINATORS[@]}"}; do
  [[ -f "$p" ]] || { echo "ERROR: missing --extra-contaminator $p" >&2; exit 1; }
done

# Reverse/re-apply bookkeeping: REVERSED is a stack, re-applied LIFO — which is exactly the
# application order (extras first, then core/01, then core/05) because we reverse newest-first.
REVERSED=(); REAPPLY_FAILED=0
reapply_reversed() {
  local i p
  for (( i=${#REVERSED[@]}-1; i>=0; i-- )); do
    p="${REVERSED[$i]}"
    git -C "$AC" apply "$p" \
      || { echo "ERROR: FAILED to re-apply $p — the worktree is now MISSING it! re-run apply-patches.sh" >&2; REAPPLY_FAILED=1; }
  done
  REVERSED=()
}
reverse_one() {
  git -C "$AC" apply --reverse "$1" \
    || { echo "ERROR: could not reverse $1 to isolate core/06 — resolve overlap first" >&2; reapply_reversed; exit 1; }
  REVERSED+=("$1")
}

reverse_one "$CONTAM_05"
reverse_one "$CONTAM_01"
for (( i=${#EXTRA_CONTAMINATORS[@]}-1; i>=0; i-- )); do reverse_one "${EXTRA_CONTAMINATORS[$i]}"; done

git -C "$AC" diff -- "$UNIT" > "$OUT"

reapply_reversed
[[ "$REAPPLY_FAILED" -eq 0 ]] || exit 1

if grep -q "BOT_AURA_UPDATE_INTERVAL\|_UpdateSpells" "$OUT"; then
    echo "ERROR: patch still contains bot-aura-batching hunks — isolation failed" >&2; exit 1
fi
if grep -q "crit chance vs FROZEN" "$OUT"; then
    echo "ERROR: patch still contains core/01 hunks — isolation failed" >&2; exit 1
fi
if grep -q "a wand SHOT takes the equipped wand" "$OUT"; then
    echo "ERROR: patch still contains core/05 hunks — isolation failed" >&2; exit 1
fi
grep -q "TBC Molten Fury's window is 20%" "$OUT" \
  || { echo "ERROR: patch is empty/missing the Molten Fury hunk" >&2; exit 1; }
echo "wrote $OUT ($(wc -l < "$OUT") lines)"

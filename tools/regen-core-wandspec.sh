#!/usr/bin/env bash
# regen-core-wandspec.sh — re-cut patches/core/05-wand-spec-era-no-spell-leak.patch from an
# AzerothCore worktree that already carries the edit.
#
# Usage: tools/regen-core-wandspec.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch, which
#                          also edits Unit.cpp and is applied BEFORE ours)
#
# CORE-ONLY patch (unlike every module patch): it touches src/server/game/Entities/Unit/Unit.cpp in
# the AC checkout itself. A plain `git -C "$AC" diff` with NO prefix rewriting is therefore correct —
# the a/src/... paths already resolve from the AC root, which is where apply-patches.sh runs
# `git -C "$AC" apply`. Do NOT copy the --src-prefix/--dst-prefix flags from the module regen
# scripts; they would corrupt the paths.
#
# BASELINE-AWARE (this is the regen-contamination trap): Unit.cpp is ALSO edited by this repo's
# core/01 (shatter crit vs frozen, in SpellTakenCritChance) and core/06 (molten-fury era window, also
# in SpellPctDamageModsDone) — and, in the overlay install, by its core bot-aura-batching patch in
# _UpdateSpells (pass that as --extra-contaminator). A naive whole-file `git diff -- Unit.cpp` embeds
# ALL of their hunks into this patch. To emit ONLY our hunk we reverse every contaminator out of the
# worktree first (all hunks are far from ours, so they reverse/re-apply cleanly), diff, then re-apply
# them in application order. Reversal runs newest-first (core/06, core/01, then the extras in reverse
# list order — extras are applied BEFORE this repo's patches in production); re-application is the
# exact mirror. If a NEW patch starts touching Unit.cpp, add it here too.
#
# WHAT THIS PATCH IS: a band-gated core guard for mod-era-talents "Wand Specialization". The era
# passive is aura 79 MOD_DAMAGE_PERCENT_DONE gated to ITEM_SUBCLASS_WEAPON_WAND with a multi-school
# misc (126), because a wand SHOT takes the equipped wand's magic school. The stock weapon guard in
# Unit::SpellPctDamageModsDone only skips a weapon-gated aura for a non-weapon spell when misc ==
# NORMAL, so a misc-126 wand aura slips past it and would boost every same-school SPELL cast while a
# wand is held. This hunk skips such an aura for non-weapon spells when its id is in the reserved era
# band [920000, 950000) and it is wand-subclass gated. Wand shots are unaffected (they go through
# MeleeDamageBonusDone, not this function). Inert for every stock aura.
#
# LITERAL PATHS ONLY on every git line — the shell does not word-split an unquoted $var, so a
# `for f in $FILES` loop would cut an empty patch (this trap has bitten the WG/publish recipes).
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
OUT="$ROOT/patches/core/05-wand-spec-era-no-spell-leak.patch"

[[ -d "$AC/.git" ]] || { echo "ERROR: $AC is not a git clone" >&2; exit 1; }
[[ -f "$AC/src/server/game/Entities/Unit/Unit.cpp" ]] \
  || { echo "ERROR: missing core Unit.cpp in the AC worktree" >&2; exit 1; }

# The edit must actually be present, or we would cut an empty patch over a good one and silently
# drop the wand-leak guard on the next AC reset.
grep -q "a wand SHOT takes the equipped wand" "$AC/src/server/game/Entities/Unit/Unit.cpp" \
  || { echo "ERROR: Unit.cpp has no era wand-leak hunk — core/05 not applied?" >&2; exit 1; }

# In-repo patches that also edit Unit.cpp. LITERAL paths (no $var word-splitting).
CONTAM_01="$ROOT/patches/core/01-shatter-crit-vs-frozen.patch"
CONTAM_06="$ROOT/patches/core/06-molten-fury-era-window.patch"
[[ -f "$CONTAM_01" ]] || { echo "ERROR: missing $CONTAM_01" >&2; exit 1; }
[[ -f "$CONTAM_06" ]] || { echo "ERROR: missing $CONTAM_06" >&2; exit 1; }
for p in ${EXTRA_CONTAMINATORS[@]+"${EXTRA_CONTAMINATORS[@]}"}; do
  [[ -f "$p" ]] || { echo "ERROR: missing --extra-contaminator $p" >&2; exit 1; }
done

# Reverse/re-apply bookkeeping: REVERSED is a stack, re-applied LIFO — which is exactly the
# application order (extras first, then core/01, then core/06) because we reverse newest-first.
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
    || { echo "ERROR: could not reverse $1 to isolate core/05 — resolve overlap first" >&2; reapply_reversed; exit 1; }
  REVERSED+=("$1")
}

reverse_one "$CONTAM_06"
reverse_one "$CONTAM_01"
for (( i=${#EXTRA_CONTAMINATORS[@]}-1; i>=0; i-- )); do reverse_one "${EXTRA_CONTAMINATORS[$i]}"; done

git -C "$AC" diff -- src/server/game/Entities/Unit/Unit.cpp > "$OUT"

# Re-apply everything in application order so the worktree is whole again (build/runtime need it).
reapply_reversed
[[ "$REAPPLY_FAILED" -eq 0 ]] || exit 1

# Guard: the isolated patch must contain ONLY the wand-leak hunk.
if grep -q "BOT_AURA_UPDATE_INTERVAL\|_UpdateSpells" "$OUT"; then
    echo "ERROR: patch still contains bot-aura-batching hunks — isolation failed" >&2
    exit 1
fi
if grep -q "crit chance vs FROZEN" "$OUT"; then
    echo "ERROR: patch still contains core/01 hunks — isolation failed" >&2
    exit 1
fi
if grep -q "TBC Molten Fury's window is 20%" "$OUT"; then
    echo "ERROR: patch still contains core/06 hunks — isolation failed" >&2
    exit 1
fi
grep -q "a wand SHOT takes the equipped wand" "$OUT" \
  || { echo "ERROR: patch is empty/missing the wand-leak hunk" >&2; exit 1; }
echo "wrote $OUT ($(wc -l < "$OUT") lines)"

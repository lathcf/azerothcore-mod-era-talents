#!/usr/bin/env bash
# regen-ip-manual-advance.sh — re-cut patches/individual-progression/01-manual-advance-states.patch
# from an AzerothCore worktree whose modules/mod-individual-progression clone carries the edit.
#
# Usage: tools/regen-ip-manual-advance.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch for Unit.cpp)
# This patch needs neither to rebuild its baseline, but any patch passed via either flag is included
# in the pristine-baseline gate below (a foreign patch that also diffs an IP file would invalidate it).
#
# FOUR files, touched by NO other patch (verified 2026-09-07: core/02 names IP only in a comment
# line, no 'diff --git' for any IP file) -> baseline = pristine clone HEAD for every file.
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
IP="$AC/modules/mod-individual-progression"
OUT="$ROOT/patches/individual-progression/01-manual-advance-states.patch"
REL1="src/IndividualProgression.h"
REL2="src/IndividualProgression.cpp"
REL3="src/IndividualProgressionPlayer.cpp"
REL4="conf/individualProgression.conf.dist"

[[ -d "$IP/.git" ]] || { echo "ERROR: $IP is not a git clone" >&2; exit 1; }

# No other patch — in this repo or handed in via the flags — may diff an IP file (the
# pristine-baseline assumption).
for p in "$ROOT"/patches/*/*.patch \
         ${EXTRA_BASELINES[@]+"${EXTRA_BASELINES[@]}"} \
         ${EXTRA_CONTAMINATORS[@]+"${EXTRA_CONTAMINATORS[@]}"}; do
  [[ -f "$p" ]] || continue
  if [[ "$p" == "$OUT" ]]; then continue; fi
  if grep '^diff --git' "$p" | grep -q "mod-individual-progression"; then
    echo "GATE FAIL: $p also diffs mod-individual-progression — this patch is no longer pristine-baseline; make this script baseline-aware first" >&2
    exit 1
  fi
done

# The edits must actually be present in the worktree.
grep -q "ClampHeldAdvance" "$IP/$REL1" || { echo "ERROR: $REL1 has no ClampHeldAdvance — patch not applied to the worktree?" >&2; exit 1; }
grep -q "LoadManualAdvanceStates(sConfigMgr" "$IP/$REL2" || { echo "ERROR: $REL2 has no ManualAdvanceStates config load" >&2; exit 1; }
[[ "$(grep -c "ClampHeldAdvance(killer" "$IP/$REL2")" -eq 3 ]] || { echo "ERROR: $REL2 must clamp at exactly 3 auto-advance sites" >&2; exit 1; }
[[ "$(grep -c "ClampHeldAdvance(player" "$IP/$REL3")" -eq 3 ]] || { echo "ERROR: $REL3 must clamp all 3 quest cases" >&2; exit 1; }
grep -q "IndividualProgression.ManualAdvanceStates" "$IP/$REL4" || { echo "ERROR: $REL4 lacks the ManualAdvanceStates key" >&2; exit 1; }

TMP="$(mktemp -d)"
restore() {
  if [[ -f "$TMP/IndividualProgression.h" ]]; then cp "$TMP/IndividualProgression.h" "$IP/$REL1"; fi
  if [[ -f "$TMP/IndividualProgression.cpp" ]]; then cp "$TMP/IndividualProgression.cpp" "$IP/$REL2"; fi
  if [[ -f "$TMP/IndividualProgressionPlayer.cpp" ]]; then cp "$TMP/IndividualProgressionPlayer.cpp" "$IP/$REL3"; fi
  if [[ -f "$TMP/individualProgression.conf.dist" ]]; then cp "$TMP/individualProgression.conf.dist" "$IP/$REL4"; fi
  git -C "$IP" reset -q -- "$REL1" "$REL2" "$REL3" "$REL4" 2>/dev/null || true
  rm -rf "$TMP"
}
trap restore EXIT

# 1. Save the current (patched) copies.
cp "$IP/$REL1" "$TMP/IndividualProgression.h"
cp "$IP/$REL2" "$TMP/IndividualProgression.cpp"
cp "$IP/$REL3" "$TMP/IndividualProgressionPlayer.cpp"
cp "$IP/$REL4" "$TMP/individualProgression.conf.dist"

# 2. Baseline = pristine; stage it, then restore the patched worktree state.
git -C "$IP" checkout -- "$REL1" "$REL2" "$REL3" "$REL4"
if grep -q "ClampHeldAdvance" "$IP/$REL1"; then
  echo "GATE FAIL: pristine baseline already carries the hunk (upstream absorbed it?)" >&2; exit 1
fi
git -C "$IP" add -- "$REL1" "$REL2" "$REL3" "$REL4"
cp "$TMP/IndividualProgression.h" "$IP/$REL1"
cp "$TMP/IndividualProgression.cpp" "$IP/$REL2"
cp "$TMP/IndividualProgressionPlayer.cpp" "$IP/$REL3"
cp "$TMP/individualProgression.conf.dist" "$IP/$REL4"

# 3. Index(baseline) vs worktree(patched) == exactly our hunks.
git -C "$IP" diff \
  --src-prefix=a/modules/mod-individual-progression/ \
  --dst-prefix=b/modules/mod-individual-progression/ \
  -- "$REL1" "$REL2" "$REL3" "$REL4" \
  > "$TMP/out.patch"

# 4. Output gates.
[[ -s "$TMP/out.patch" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$TMP/out.patch")" -eq 4 ]] || { echo "GATE FAIL: expected exactly 4 files in the patch" >&2; exit 1; }
grep -q "ManualAdvanceStates" "$TMP/out.patch" || { echo "GATE FAIL: patch missing ManualAdvanceStates" >&2; exit 1; }
if grep -q "^[-+].*UpdateProgressionState(player, static_cast<ProgressionState>(sIndividualProgression->" "$TMP/out.patch"; then
  echo "GATE FAIL: patch touches a login-time starting-progression call — those must stay unclamped" >&2; exit 1
fi

cp "$TMP/out.patch" "$OUT"
echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'

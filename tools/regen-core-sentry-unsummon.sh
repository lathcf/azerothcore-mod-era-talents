#!/usr/bin/env bash
# regen-core-sentry-unsummon.sh — re-cut patches/core/04-sentry-era-unsummon.patch from an
# AzerothCore worktree that already carries the edit.
#
# Usage: tools/regen-core-sentry-unsummon.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch for Unit.cpp)
# This patch needs neither, but accepts both for a uniform interface.
#
# CORE-ONLY patch (the core/02 recipe): it touches src/server/game/Entities/Totem/Totem.cpp in the AC
# checkout itself, so a plain `git -C "$AC" diff` with NO prefix rewriting is correct — the a/src/...
# paths already resolve from the AC root where apply-patches.sh runs `git apply`. Do NOT copy the
# --src-prefix/--dst-prefix flags from the module regen scripts.
#
# NOT baseline-aware: no other patch touches Totem.cpp (verified at authoring time:
#   grep -l "Totem.cpp" patches/*/*.patch  => no match).
# If a FUTURE patch starts touching Totem.cpp, make this baseline-aware (reverse the other patch
# out before diffing) or it will silently embed the other patch's hunks.
#
# WHAT THIS PATCH IS: Totem::UnSummon clears the Sentry camera-bind buff with a HARDCODED 6495
# (TotemSpellIds::SentryTotemSpell). The mod-era-talents Sentry clone 947260 summons the same
# creature entry 3968 but applies its own owner-side buff, which that call never names — so an
# EARLY unsummon (totem killed, replaced, Totemic Recall) left the buff running out its 5-minute
# duration and spell_sha_sentry_totem's bind-sight teardown fired late. The patch adds
# owner->RemoveAurasDueToSpell(947260) inside the same entry-gated block. Inert when the aura is
# absent (any non-era character). Closes shaman-totems-tbc.yaml accepted_gaps id 12.
#
# LITERAL PATHS ONLY on every git line — the shell does not word-split an unquoted $var.
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
OUT="$ROOT/patches/core/04-sentry-era-unsummon.patch"

[[ -d "$AC/.git" ]] || { echo "ERROR: $AC is not a git clone" >&2; exit 1; }
[[ -f "$AC/src/server/game/Entities/Totem/Totem.cpp" ]] \
  || { echo "ERROR: missing core Totem.cpp in the AC worktree" >&2; exit 1; }

grep -q "era-talents (patch 0024)" "$AC/src/server/game/Entities/Totem/Totem.cpp" \
  || { echo "ERROR: Totem.cpp has no era-Sentry hunk — core/04 not applied to the worktree?" >&2; exit 1; }

git -C "$AC" diff -- src/server/game/Entities/Totem/Totem.cpp > "$OUT"

[[ -s "$OUT" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$OUT")" -eq 1 ]] || { echo "GATE FAIL: expected exactly 1 file in the patch" >&2; exit 1; }
grep -q "b/src/server/game/Entities/Totem/Totem.cpp" "$OUT" \
  || { echo "GATE FAIL: patch path is not AC-root relative — did you add --dst-prefix?" >&2; exit 1; }
for needle in "947260" "931390" "SENTRY_TOTEM_ENTRY" "RemoveAurasDueToSpell"; do
  grep -q "$needle" "$OUT" || { echo "GATE FAIL: patch missing expected content: $needle" >&2; exit 1; }
done

echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'

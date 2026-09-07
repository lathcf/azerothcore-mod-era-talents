#!/usr/bin/env bash
# regen-core-corruption-casttime.sh — re-cut patches/core/02-corruption-era-casttime.patch from an
# AzerothCore worktree that already carries the edit.
#
# Usage: tools/regen-core-corruption-casttime.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch for Unit.cpp)
# This patch needs neither, but accepts both for a uniform interface.
#
# CORE-ONLY patch (unlike every module patch): it touches src/server/game/Spells/SpellInfo.cpp in the
# AC checkout itself. A plain `git -C "$AC" diff` with NO prefix rewriting is therefore correct — the
# a/src/... paths already resolve from the AC root, which is where apply-patches.sh invokes
# `git -C "$AC" apply`. Do NOT copy the --src-prefix/--dst-prefix flags from the module regen
# scripts; they would corrupt the paths. The gate below enforces this.
#
# NOT baseline-aware: no other patch in this repo touches SpellInfo.cpp (core/01, core/05 and core/06
# touch Unit.cpp), so a scoped diff of that one path emits exactly this patch's hunk. Verified at
# authoring time:
#   grep -l "SpellInfo.cpp" patches/*/*.patch  => (no match)
# If a FUTURE patch starts touching SpellInfo.cpp, this script MUST become baseline-aware (reverse the
# other patch out before diffing) or it will silently embed the other patch's hunks — the trap that bit
# the WG 0004 regen. See tools/regen-core-shatter.sh for the baseline-aware pattern.
#
# WHAT THIS PATCH IS: restores Corruption's Vanilla 2s base cast time for a Vanilla-era warlock, so the
# Improved Corruption talent (node 18202) cast-time SPELLMOD has something to reduce. The era-talents
# module grants a hidden marker aura 932930 (SPELL_AURA_DUMMY, misc 5 — DUMMY-marker registry #5) to
# Vanilla-era warlocks; SpellInfo::CalcCastTime checks HasAura(932930) — gated on the Corruption spell id
# FIRST so non-Corruption casts pay only a map lookup — and overrides the base cast time to 2000ms before
# ModSpellCastTime. Inert for any non-marked caster or non-Corruption spell.
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
OUT="$ROOT/patches/core/02-corruption-era-casttime.patch"

[[ -d "$AC/.git" ]] || { echo "ERROR: $AC is not a git clone" >&2; exit 1; }
[[ -f "$AC/src/server/game/Spells/SpellInfo.cpp" ]] \
  || { echo "ERROR: missing core SpellInfo.cpp in the AC worktree" >&2; exit 1; }

# The edit must actually be present, or we would cut an empty patch over a good one and silently drop the
# Corruption cast-time restore on the next AC reset.
grep -q "era-talents patch 0019" "$AC/src/server/game/Spells/SpellInfo.cpp" \
  || { echo "ERROR: SpellInfo.cpp has no era-Corruption hunk — core/02 not applied to the worktree?" >&2; exit 1; }

git -C "$AC" diff -- src/server/game/Spells/SpellInfo.cpp > "$OUT"

# Gates.
[[ -s "$OUT" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$OUT")" -eq 1 ]] || { echo "GATE FAIL: expected exactly 1 file in the patch" >&2; exit 1; }
grep -q "b/src/server/game/Spells/SpellInfo.cpp" "$OUT" \
  || { echo "GATE FAIL: patch path is not AC-root relative — did you add --dst-prefix?" >&2; exit 1; }
for needle in "932930" "s_eraVanillaCastTime" "HasAura" "eraBase"; do
  grep -q "$needle" "$OUT" || { echo "GATE FAIL: patch missing expected content: $needle" >&2; exit 1; }
done

echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'

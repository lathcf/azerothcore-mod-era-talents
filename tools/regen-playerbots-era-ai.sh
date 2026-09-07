#!/usr/bin/env bash
# regen-playerbots-era-ai.sh — re-cut patches/playerbots/02-era-ai.patch from an AzerothCore
# worktree whose modules/mod-playerbots clone already carries the edit.
#
# Usage: tools/regen-playerbots-era-ai.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch for Unit.cpp)
#
# This patch = era-aware bot AI: routes the AI's hardcoded stock-spell-id checks (shaman totem
# subsystem, druid Thick Hide bear discriminator + Omen of Clarity, paladin judgement
# fallback + Blessing of Sanctuary / Improved-blessing checks, priest Vampiric Embrace
# targeting, warrior Commanding Presence + Poleaxe Specialization) through mod-era-talents'
# EraTalentBots_ResolveSpellId bridge.
#
# Inside THIS repo none of its 18 files is shared, so a standalone install (no --extra-baseline)
# gets a pristine baseline everywhere and that is correct. In an install that also carries FOREIGN
# mod-playerbots patches, src/Bot/PlayerbotAI.cpp is SHARED — the overlay's WG, perfmon, Sunwell and
# AQ40 patches all edit it — and a pristine-baseline diff there would EMBED their hunks into this
# patch (the regen-contamination trap). Hand those in, in the order the install applies them:
#   tools/regen-playerbots-era-ai.sh <ac-root> \
#     --extra-baseline <overlay-patches>/0003-playerbot-wintergrasp.patch \
#     --extra-baseline <overlay-patches>/0004-playerbot-wintergrasp-siege.patch \
#     --extra-baseline <overlay-patches>/0011-playerbot-perfmon-hotpath.patch \
#     --extra-baseline <overlay-patches>/0014-playerbot-sunwell.patch \
#     --extra-baseline <overlay-patches>/0016-playerbot-aq40-twins.patch
# (<overlay-patches> = the overlay repo's patches/ directory.) Each is applied FILE-SCOPED to
# PlayerbotAI.cpp only; one carrying no PlayerbotAI.cpp hunk is
# skipped (verify a candidate with the file-scoped `diff --git` list, not a loose grep — the
# overlay's Lich King patch only mentions PlayerbotAI.cpp in a comment).
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
PB="$AC/modules/mod-playerbots"
OUT="$ROOT/patches/playerbots/02-era-ai.patch"

[[ -d "$PB/.git" ]] || { echo "ERROR: $PB is not a git clone" >&2; exit 1; }

# The edits must actually be present (spot-check one per class cluster).
grep -q "EraTalentBots_ResolveSpellId" "$PB/src/Ai/Class/Shaman/ShamanTriggers.cpp" \
  || { echo "ERROR: ShamanTriggers.cpp has no era hook — playerbots/02 not applied to the worktree?" >&2; exit 1; }
grep -q "EraTalentBots_ResolveSpellId" "$PB/src/Bot/PlayerbotAI.cpp" \
  || { echo "ERROR: PlayerbotAI.cpp has no era hook — playerbots/02 not applied to the worktree?" >&2; exit 1; }
grep -q "EraTalentBots_ResolveSpellId" "$PB/src/Ai/Class/Priest/PriestTriggers.h" \
  || { echo "ERROR: PriestTriggers.h has no era hook — playerbots/02 not applied to the worktree?" >&2; exit 1; }
grep -q "EraTalentBots_ResolveSpellId" "$PB/src/Ai/Class/Warrior/WarriorTriggers.cpp" \
  || { echo "ERROR: WarriorTriggers.cpp has no era hook — playerbots/02 not applied to the worktree?" >&2; exit 1; }

TMP="$(mktemp -d)"
restore() {
  # Always leave the AC checkout exactly as found: patched worktree state, pristine index.
  if [[ -d "$TMP/save" ]]; then cp -a "$TMP/save/." "$PB/"; fi
  git -C "$PB" reset -q -- \
    src/Bot/PlayerbotAI.cpp \
    src/Ai/Base/Actions/LfgActions.cpp \
    src/Ai/Base/Value/SpellIdValue.cpp \
    src/Ai/Base/Actions/WorldBuffAction.cpp \
    src/Ai/Class/Shaman/ShamanTriggers.cpp \
    src/Ai/Class/Shaman/ShamanActions.cpp \
    src/Ai/Class/Shaman/Strategy/TotemsShamanStrategy.cpp \
    src/Ai/Class/Druid/DruidTriggers.h \
    src/Ai/Class/Druid/Strategy/GenericDruidStrategy.cpp \
    src/Ai/Class/Druid/Strategy/FeralDruidStrategy.cpp \
    src/Ai/Class/Paladin/Actions/PaladinActions.cpp \
    src/Ai/Class/Paladin/Actions/PaladinGreaterBlessingAction.cpp \
    src/Ai/Class/Paladin/Strategy/GenericPaladinStrategyActionNodeFactory.h \
    src/Ai/Class/Priest/PriestActions.h \
    src/Ai/Class/Priest/PriestTriggers.h \
    src/Ai/Class/Priest/Strategy/ShadowPriestStrategy.cpp \
    src/Ai/Class/Warrior/WarriorTriggers.cpp \
    src/Mgr/Item/StatsWeightCalculator.cpp \
    2>/dev/null || true
  rm -rf "$TMP"
}
trap restore EXIT

# 1. Save the current (patched) copies, preserving relative layout.
mkdir -p "$TMP/save"
tar -C "$PB" -cf - \
  src/Bot/PlayerbotAI.cpp \
  src/Ai/Base/Actions/LfgActions.cpp \
  src/Ai/Base/Value/SpellIdValue.cpp \
  src/Ai/Base/Actions/WorldBuffAction.cpp \
  src/Ai/Class/Shaman/ShamanTriggers.cpp \
  src/Ai/Class/Shaman/ShamanActions.cpp \
  src/Ai/Class/Shaman/Strategy/TotemsShamanStrategy.cpp \
  src/Ai/Class/Druid/DruidTriggers.h \
  src/Ai/Class/Druid/Strategy/GenericDruidStrategy.cpp \
  src/Ai/Class/Druid/Strategy/FeralDruidStrategy.cpp \
  src/Ai/Class/Paladin/Actions/PaladinActions.cpp \
  src/Ai/Class/Paladin/Actions/PaladinGreaterBlessingAction.cpp \
  src/Ai/Class/Paladin/Strategy/GenericPaladinStrategyActionNodeFactory.h \
  src/Ai/Class/Priest/PriestActions.h \
  src/Ai/Class/Priest/PriestTriggers.h \
  src/Ai/Class/Priest/Strategy/ShadowPriestStrategy.cpp \
  src/Ai/Class/Warrior/WarriorTriggers.cpp \
  src/Mgr/Item/StatsWeightCalculator.cpp \
  | tar -C "$TMP/save" -xf -

# 2. Rebuild the baselines: pristine everywhere...
git -C "$PB" checkout -- \
  src/Bot/PlayerbotAI.cpp \
  src/Ai/Base/Actions/LfgActions.cpp \
  src/Ai/Base/Value/SpellIdValue.cpp \
  src/Ai/Base/Actions/WorldBuffAction.cpp \
  src/Ai/Class/Shaman/ShamanTriggers.cpp \
  src/Ai/Class/Shaman/ShamanActions.cpp \
  src/Ai/Class/Shaman/Strategy/TotemsShamanStrategy.cpp \
  src/Ai/Class/Druid/DruidTriggers.h \
  src/Ai/Class/Druid/Strategy/GenericDruidStrategy.cpp \
  src/Ai/Class/Druid/Strategy/FeralDruidStrategy.cpp \
  src/Ai/Class/Paladin/Actions/PaladinActions.cpp \
  src/Ai/Class/Paladin/Actions/PaladinGreaterBlessingAction.cpp \
  src/Ai/Class/Paladin/Strategy/GenericPaladinStrategyActionNodeFactory.h \
  src/Ai/Class/Priest/PriestActions.h \
  src/Ai/Class/Priest/PriestTriggers.h \
  src/Ai/Class/Priest/Strategy/ShadowPriestStrategy.cpp \
  src/Ai/Class/Warrior/WarriorTriggers.cpp \
  src/Mgr/Item/StatsWeightCalculator.cpp

# ...then any foreign patch's PlayerbotAI.cpp hunks, file-scoped, in the order given.
BASELINES_APPLIED=0
for p in ${EXTRA_BASELINES[@]+"${EXTRA_BASELINES[@]}"}; do
  [[ -f "$p" ]] || { echo "ERROR: missing --extra-baseline $p" >&2; exit 1; }
  if grep -q "^diff --git .*modules/mod-playerbots/src/Bot/PlayerbotAI\.cpp" "$p"; then
    git -C "$AC" apply --include="modules/mod-playerbots/src/Bot/PlayerbotAI.cpp" "$p"
    BASELINES_APPLIED=$(( BASELINES_APPLIED + 1 ))
  fi
done

# 3. Baseline gates (if-form, not `grep && fail` — the set -e trap the other regens warn about).
if (( ${#EXTRA_BASELINES[@]} > 0 )); then
  if (( BASELINES_APPLIED == 0 )); then
    echo "GATE FAIL: none of the --extra-baseline patches carries a PlayerbotAI.cpp hunk — wrong patches?" >&2; exit 1
  fi
  if git -C "$PB" diff --quiet -- src/Bot/PlayerbotAI.cpp; then
    echo "GATE FAIL: PlayerbotAI baseline is identical to pristine after applying $BASELINES_APPLIED baseline(s)" >&2; exit 1
  fi
fi
if grep -q "EraTalentBots_ResolveSpellId" "$PB/src/Bot/PlayerbotAI.cpp"; then
  echo "GATE FAIL: PlayerbotAI baseline still carries our hunk" >&2; exit 1
fi
if grep -q "EraTalentBots_ResolveSpellId" "$PB/src/Ai/Class/Shaman/ShamanTriggers.cpp"; then
  echo "GATE FAIL: ShamanTriggers baseline still carries our hunk" >&2; exit 1
fi

# 4. Stage the baselines (index = baseline), then restore the patched worktree state.
git -C "$PB" add -- \
  src/Bot/PlayerbotAI.cpp \
  src/Ai/Base/Actions/LfgActions.cpp \
  src/Ai/Base/Value/SpellIdValue.cpp \
  src/Ai/Base/Actions/WorldBuffAction.cpp \
  src/Ai/Class/Shaman/ShamanTriggers.cpp \
  src/Ai/Class/Shaman/ShamanActions.cpp \
  src/Ai/Class/Shaman/Strategy/TotemsShamanStrategy.cpp \
  src/Ai/Class/Druid/DruidTriggers.h \
  src/Ai/Class/Druid/Strategy/GenericDruidStrategy.cpp \
  src/Ai/Class/Druid/Strategy/FeralDruidStrategy.cpp \
  src/Ai/Class/Paladin/Actions/PaladinActions.cpp \
  src/Ai/Class/Paladin/Actions/PaladinGreaterBlessingAction.cpp \
  src/Ai/Class/Paladin/Strategy/GenericPaladinStrategyActionNodeFactory.h \
  src/Ai/Class/Priest/PriestActions.h \
  src/Ai/Class/Priest/PriestTriggers.h \
  src/Ai/Class/Priest/Strategy/ShadowPriestStrategy.cpp \
  src/Ai/Class/Warrior/WarriorTriggers.cpp \
  src/Mgr/Item/StatsWeightCalculator.cpp
cp -a "$TMP/save/." "$PB/"

# 5. Index(baseline) vs worktree(patched) == exactly our hunks, on top of the full stack.
git -C "$PB" diff \
  --src-prefix=a/modules/mod-playerbots/ \
  --dst-prefix=b/modules/mod-playerbots/ \
  -- \
  src/Bot/PlayerbotAI.cpp \
  src/Ai/Base/Actions/LfgActions.cpp \
  src/Ai/Base/Value/SpellIdValue.cpp \
  src/Ai/Base/Actions/WorldBuffAction.cpp \
  src/Ai/Class/Shaman/ShamanTriggers.cpp \
  src/Ai/Class/Shaman/ShamanActions.cpp \
  src/Ai/Class/Shaman/Strategy/TotemsShamanStrategy.cpp \
  src/Ai/Class/Druid/DruidTriggers.h \
  src/Ai/Class/Druid/Strategy/GenericDruidStrategy.cpp \
  src/Ai/Class/Druid/Strategy/FeralDruidStrategy.cpp \
  src/Ai/Class/Paladin/Actions/PaladinActions.cpp \
  src/Ai/Class/Paladin/Actions/PaladinGreaterBlessingAction.cpp \
  src/Ai/Class/Paladin/Strategy/GenericPaladinStrategyActionNodeFactory.h \
  src/Ai/Class/Priest/PriestActions.h \
  src/Ai/Class/Priest/PriestTriggers.h \
  src/Ai/Class/Priest/Strategy/ShadowPriestStrategy.cpp \
  src/Ai/Class/Warrior/WarriorTriggers.cpp \
  src/Mgr/Item/StatsWeightCalculator.cpp \
  > "$TMP/out.patch"

# (index/worktree restoration happens in the EXIT trap)

# 6. Output gates.
[[ -s "$TMP/out.patch" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$TMP/out.patch")" -eq 18 ]] \
  || { echo "GATE FAIL: expected exactly 18 files in the patch, got $(grep -c '^diff --git' "$TMP/out.patch")" >&2; exit 1; }
grep -q "EraTalentBots_ResolveSpellId" "$TMP/out.patch" \
  || { echo "GATE FAIL: patch missing the resolver bridge" >&2; exit 1; }
if grep -q "perfMonEnabled" "$TMP/out.patch"; then
  echo "GATE FAIL: patch contaminated with a foreign perfmon hunk (baseline was wrong)" >&2; exit 1
fi
if grep -q "wg siege" "$TMP/out.patch"; then
  echo "GATE FAIL: patch contaminated with a foreign Wintergrasp hunk (baseline was wrong)" >&2; exit 1
fi

cp "$TMP/out.patch" "$OUT"
echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'

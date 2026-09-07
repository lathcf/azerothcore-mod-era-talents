#!/usr/bin/env bash
# regen-playerbots-factory.sh — re-cut patches/playerbots/01-factory-era-talents.patch from an
# AzerothCore worktree whose modules/mod-playerbots clone already carries the edit.
#
# Usage: tools/regen-playerbots-factory.sh <azerothcore-root> [--extra-baseline <patch>]... [--extra-contaminator <patch>]...
#   <azerothcore-root>     the AC checkout whose worktree carries the edit (modules/ cloned inside it)
#   --extra-baseline P     a patch from ANOTHER repo that also edits a file this patch touches and is
#                          applied BEFORE it (reconstructs the baseline; e.g. the overlay's WG 0003/0004)
#   --extra-contaminator P a patch from another repo that edits the same file and must be reversed
#                          around the diff (e.g. the overlay's core bot-aura-batching patch for Unit.cpp)
#
# FOUR files. Inside THIS repo none of them is shared, so a standalone install (no --extra-baseline)
# gets a pristine baseline for all four and that is correct. In an install that also carries
# FOREIGN mod-playerbots patches, src/Bot/Factory/AiFactory.cpp is SHARED — the overlay's WG patches
# both edit it — and a pristine-baseline diff there would EMBED their hunks into this patch (the
# regen-contamination trap). Hand those in:
#   tools/regen-playerbots-factory.sh <ac-root> \
#     --extra-baseline <overlay-patches>/0003-playerbot-wintergrasp.patch \
#     --extra-baseline <overlay-patches>/0004-playerbot-wintergrasp-siege.patch
# (<overlay-patches> = the overlay repo's patches/ directory.) Each --extra-baseline is applied
# FILE-SCOPED to AiFactory.cpp only, in the order given (which must
# be the order the install applies them). A baseline that carries no AiFactory.cpp hunk is skipped —
# verify a candidate with the file-scoped `diff --git` list, not a loose grep (the overlay's Sunwell
# patch was listed here once and was WRONG: its only 'AiFactory' hit is an #include context line).
#   * src/Bot/Factory/PlayerbotFactory.cpp                        — pristine baseline
#   * src/Ai/Base/Actions/AutoMaintenanceOnLevelupAction.cpp      — pristine baseline. This AI-tick
#     action calls InitAvailableSpells() AFTER the whole factory pass, so it is the last site to
#     re-teach era-illegal trainer spells to a bot.
#   * src/Mgr/Item/RandomItemMgr.cpp                              — pristine baseline
#   * src/Bot/Factory/AiFactory.cpp                               — pristine + any --extra-baseline
#
# The --src/--dst prefix rewrite makes the output apply from the AC ROOT like every other
# mod-playerbots patch.
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
OUT="$ROOT/patches/playerbots/01-factory-era-talents.patch"
REL1="src/Bot/Factory/PlayerbotFactory.cpp"
REL2="src/Bot/Factory/AiFactory.cpp"
REL3="src/Mgr/Item/RandomItemMgr.cpp"
REL4="src/Ai/Base/Actions/AutoMaintenanceOnLevelupAction.cpp"

[[ -d "$PB/.git" ]] || { echo "ERROR: $PB is not a git clone" >&2; exit 1; }

# The edits must actually be present in the worktree.
grep -q "EraTalentBots_FactoryReconcile" "$PB/$REL1" \
  || { echo "ERROR: $REL1 has no era hook — playerbots/01 not applied to the worktree?" >&2; exit 1; }
grep -q "EraTalentBots_SpecTabs" "$PB/$REL2" \
  || { echo "ERROR: $REL2 has no spec-tab hook — playerbots/01 not applied to the worktree?" >&2; exit 1; }
grep -q "maxReqLevel" "$PB/$REL3" \
  || { echo "ERROR: $REL3 GetRandomPotion has no era filter — not applied to the worktree?" >&2; exit 1; }
grep -q "IsEraLegalConsumable" "$PB/$REL1" \
  || { echo "ERROR: $REL1 has no IsEraLegalConsumable — not applied to the worktree?" >&2; exit 1; }
grep -q "EraTalentBots_PostTrainerWalk" "$PB/$REL4" \
  || { echo "ERROR: $REL4 has no post-trainer-walk hook — playerbots/01 not applied to the worktree?" >&2; exit 1; }

TMP="$(mktemp -d)"
restore() {
  # Always leave the AC checkout exactly as found: patched worktree state, pristine index.
  if [[ -f "$TMP/PlayerbotFactory.cpp" ]]; then cp "$TMP/PlayerbotFactory.cpp" "$PB/$REL1"; fi
  if [[ -f "$TMP/AiFactory.cpp" ]]; then cp "$TMP/AiFactory.cpp" "$PB/$REL2"; fi
  if [[ -f "$TMP/RandomItemMgr.cpp" ]]; then cp "$TMP/RandomItemMgr.cpp" "$PB/$REL3"; fi
  if [[ -f "$TMP/AutoMaintenanceOnLevelupAction.cpp" ]]; then cp "$TMP/AutoMaintenanceOnLevelupAction.cpp" "$PB/$REL4"; fi
  git -C "$PB" reset -q -- "$REL1" "$REL2" "$REL3" "$REL4" 2>/dev/null || true
  rm -rf "$TMP"
}
trap restore EXIT

# 1. Save the current (patched) copies.
cp "$PB/$REL1" "$TMP/PlayerbotFactory.cpp"
cp "$PB/$REL2" "$TMP/AiFactory.cpp"
cp "$PB/$REL3" "$TMP/RandomItemMgr.cpp"
cp "$PB/$REL4" "$TMP/AutoMaintenanceOnLevelupAction.cpp"

# 2. Rebuild the baselines: pristine, then any foreign patch's AiFactory.cpp hunks, in the order given.
git -C "$PB" checkout -- "$REL1" "$REL2" "$REL3" "$REL4"
BASELINES_APPLIED=0
for p in ${EXTRA_BASELINES[@]+"${EXTRA_BASELINES[@]}"}; do
  [[ -f "$p" ]] || { echo "ERROR: missing --extra-baseline $p" >&2; exit 1; }
  if grep -q "^diff --git .*modules/mod-playerbots/src/Bot/Factory/AiFactory\.cpp" "$p"; then
    git -C "$AC" apply --include="modules/mod-playerbots/src/Bot/Factory/AiFactory.cpp" "$p"
    BASELINES_APPLIED=$(( BASELINES_APPLIED + 1 ))
  fi
done

# 3. Baseline gates: foreign hunks present (when any were handed in), our hunks absent. (if-form,
#    not `grep && fail` — the && shape is the set -e trap the other regen scripts warn about.)
if (( ${#EXTRA_BASELINES[@]} > 0 )); then
  if (( BASELINES_APPLIED == 0 )); then
    echo "GATE FAIL: none of the --extra-baseline patches carries an AiFactory.cpp hunk — wrong patches?" >&2; exit 1
  fi
  if git -C "$PB" diff --quiet -- "$REL2"; then
    echo "GATE FAIL: AiFactory baseline is identical to pristine after applying $BASELINES_APPLIED baseline(s)" >&2; exit 1
  fi
fi
if grep -q "EraTalentBots_SpecTabs" "$PB/$REL2"; then
  echo "GATE FAIL: AiFactory baseline still carries our hunk" >&2; exit 1
fi
if grep -q "EraTalentBots_FactoryReconcile" "$PB/$REL1"; then
  echo "GATE FAIL: PlayerbotFactory baseline still carries our hunk" >&2; exit 1
fi
# RandomItemMgr baseline is pristine: our tell is the per-band RequiredLevel ceiling (maxReqLevel)
# inside GetRandomPotion, absent from the pristine cache-keyed-on-req-only version.
if awk '/GetRandomPotion/,/^}/' "$PB/$REL3" | grep -q "maxReqLevel"; then
  echo "GATE FAIL: RandomItemMgr baseline still carries our potion hunk" >&2; exit 1
fi
if grep -q "EraTalentBots_PostTrainerWalk" "$PB/$REL4"; then
  echo "GATE FAIL: AutoMaintenanceOnLevelupAction baseline still carries our hunk" >&2; exit 1
fi

# 4. Stage the baselines (index = baseline), then restore the patched worktree state.
git -C "$PB" add -- "$REL1" "$REL2" "$REL3" "$REL4"
cp "$TMP/PlayerbotFactory.cpp" "$PB/$REL1"
cp "$TMP/AiFactory.cpp" "$PB/$REL2"
cp "$TMP/RandomItemMgr.cpp" "$PB/$REL3"
cp "$TMP/AutoMaintenanceOnLevelupAction.cpp" "$PB/$REL4"

# 5. Index(baseline) vs worktree(patched) == exactly our hunks, on top of the full stack.
git -C "$PB" diff \
  --src-prefix=a/modules/mod-playerbots/ \
  --dst-prefix=b/modules/mod-playerbots/ \
  -- "$REL1" "$REL2" "$REL3" "$REL4" \
  > "$TMP/out.patch"

# (index/worktree restoration happens in the EXIT trap)

# 6. Output gates.
[[ -s "$TMP/out.patch" ]] || { echo "GATE FAIL: generated patch is empty" >&2; exit 1; }
[[ "$(grep -c '^diff --git' "$TMP/out.patch")" -eq 4 ]] \
  || { echo "GATE FAIL: expected exactly 4 files in the patch, got $(grep -c '^diff --git' "$TMP/out.patch")" >&2; exit 1; }
for needle in "EraTalentBots_FactoryReconcile" "EraTalentBots_SpecTabs" "EraTalentBots_PostTrainerWalk" "randomClassSpecIndex" "IsEraLegalConsumable" "maxReqLevel" "EraGlyphGate_BotGlyphsAllowed" "Traveler's Backpack"; do
  grep -q -- "$needle" "$TMP/out.patch" \
    || { echo "GATE FAIL: patch missing expected content: $needle" >&2; exit 1; }
done
if grep -q "wg siege" "$TMP/out.patch"; then
  echo "GATE FAIL: patch contaminated with a foreign Wintergrasp hunk (baseline was wrong)" >&2; exit 1
fi

cp "$TMP/out.patch" "$OUT"
echo "OK: wrote $OUT ($(wc -l < "$OUT") lines)"
git -C "$AC" apply --stat "$OUT" | sed 's/^/    /'

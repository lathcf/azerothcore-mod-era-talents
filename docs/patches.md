# Patch inventory

`apply-patches.sh <azerothcore-root>` applies `patches/core/*` and `patches/individual-progression/*`
always, `patches/playerbots/*` when `modules/mod-playerbots` exists and `patches/multibot-bridge/*`
when `modules/mod-multibot-bridge` exists — in lexical order per directory, idempotently. Every
patch's paths resolve from the AzerothCore root. Cut against core `413bea61` (mod-playerbots fork),
mod-playerbots `b949b50`, IP `977e200`, mod-multibot-bridge `759c100`.

Every core patch keys off a spell id in the reserved era band `[920000, 950000)` or a band-gated
DUMMY marker, so it is inert for any character that carries none.

| Patch | Target file(s) | Regen | What / why |
|-------|----------------|-------|------------|
| `core/01-shatter-crit-vs-frozen` | `Entities/Unit/Unit.cpp` (`SpellTakenCritChance`) | `regen-core-shatter.sh` | Shatter: crit% vs `AURA_STATE_FROZEN` targets from a band SPELL_AURA_DUMMY marker (misc 1, amount = %). Vanilla node 18045 (920360-4), TBC node 20857 (942856-60). |
| `core/02-corruption-era-casttime` | `Spells/SpellInfo.cpp` | `regen-core-corruption-casttime.sh` | Restores Corruption's pre-WotLK 2 s cast for a warlock carrying the "Era: Vanilla Cast Times" marker 932930 (misc 5); reused unchanged by TBC. |
| `core/03-hotw-era-bear-stamina` | `Spells/Auras/SpellAuraEffects.cpp` | `regen-core-hotw.sh` | TBC Heart of the Wild: bear Stamina = full Intellect % (WotLK halves it in `HandleShapeshiftBoosts`). Gated on marker 946280 (misc 18); bear 24899 only — cat 24900 deliberately untouched. |
| `core/04-sentry-era-unsummon` | `Entities/Totem/Totem.cpp` | `regen-core-sentry-unsummon.sh` | `Totem::UnSummon` clears the camera-bind buff by hardcoded 6495; also clears the era Sentry clones 947260 (TBC) / 931390 (Vanilla). |
| `core/05-wand-spec-era-no-spell-leak` | `Unit.cpp` (`SpellPctDamageModsDone`) | `regen-core-wandspec.sh` | Wand Specialization: a band aura 79 (misc 126) must boost wand shots only, not same-school spells. |
| `core/06-molten-fury-era-window` | `Unit.cpp` (`SpellPctDamageModsDone`, `case 4920/4919`) | `regen-core-moltenfury.sh` | TBC Molten Fury (942736/942737): 20% health window instead of WotLK's 35% for band OVERRIDE_CLASS_SCRIPTS auras. |
| `individual-progression/01-manual-advance-states` | `IndividualProgression.{h,cpp}`, `IndividualProgressionPlayer.cpp`, `conf/…conf.dist` | `regen-ip-manual-advance.sh` | Adds `IndividualProgression.ManualAdvanceStates`: stages the AUTOMATIC advance may not enter (boss-kill map, achievement backfill, quest turn-in — clamped to `held-1`). `ForceUpdateProgressionState` (`.ip set`, group sync, the module's gossip Accept) untouched; IP's login-time starting progression untouched. |
| `playerbots/01-factory-era-talents` | `Bot/Factory/PlayerbotFactory.cpp`, `Bot/Factory/AiFactory.cpp`, `Mgr/Item/RandomItemMgr.cpp`, `Ai/Base/Actions/AutoMaintenanceOnLevelupAction.cpp` | `regen-playerbots-factory.sh` | `InitTalentsTree` → `EraTalentBots_FactoryReconcile`; `GetPlayerSpecTabs` → `EraTalentBots_SpecTabs`; era item filters (consumables by RequiredLevel ceiling, bags/special spells by id band, glyphs via `EraGlyphGate_BotGlyphsAllowed`); `EraTalentBots_PostTrainerWalk` after each of the three `InitAvailableSpells()` sites. |
| `playerbots/02-era-ai` | 18 files under `Bot/`, `Mgr/Item/`, `Ai/Class/{Shaman,Druid,Paladin,Priest,Warrior}` | `regen-playerbots-era-ai.sh` | Routes the AI's hardcoded stock-spell-id checks through `EraTalentBots_ResolveSpellId` (totems, Thick Hide, judgements/blessings, Vampiric Embrace, Commanding Presence, Poleaxe/Sword Specialization gear weights). |
| `multibot-bridge/01-era-talents` | `MultiBotBridge.cpp` | `regen-multibot-bridge.sh` | `BuildTalentTabPoints` consults `EraTalentBots_SpecTabs` first so BotGrid shows an era-managed character's real spec. |

The four `EraTalentBots_*` bridges and `EraGlyphGate_BotGlyphsAllowed` are plain C++-linkage free
functions declared `extern` inline in the patched files — **signatures must match `src/EraTalentBots.h`
/ `src/EraGlyphGate.h` exactly** or the fork fails to link. They exist only when `MOD_PLAYERBOTS` is
defined (i.e. mod-playerbots is present), which is also the only case the patches are applied.

## Regenerating a patch

```
tools/regen-<name>.sh <azerothcore-root> [--extra-baseline P]... [--extra-contaminator P]...
```
Each script diffs the edit out of the AC working tree at `<azerothcore-root>` (the edit must be
present there) and rewrites the patch file. Three of them (`core/01`, `05`, `06`) all edit
`Unit.cpp`, so each reverses the other two around its diff and re-applies them in order — a naive
whole-file diff would embed the siblings' hunks (**the regen-contamination trap**). The shared-file
map:

| File | Patches in this repo | Typical external patches (pass as flags) |
|------|----------------------|------------------------------------------|
| `src/server/game/Entities/Unit/Unit.cpp` | core/01, core/05, core/06 | `--extra-contaminator` for any other patch you carry on Unit.cpp, applied before ours |
| `modules/mod-playerbots/src/Bot/Factory/AiFactory.cpp` | playerbots/01 | `--extra-baseline` for patches applied before ours that touch it |
| `modules/mod-playerbots/src/Bot/PlayerbotAI.cpp` | playerbots/02 | `--extra-baseline` likewise |

`--extra-baseline` = a patch from another repo applied BEFORE ours on a shared file (reconstructs the
baseline the diff is taken against). `--extra-contaminator` = a patch on the same file that must be
reversed around the diff and re-applied afterwards. With neither flag the baseline is pristine
upstream, which is correct for a standalone install. After regenerating, verify with a full ordered
`apply-patches.sh` on a clean checkout.

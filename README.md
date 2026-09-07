# mod-era-talents

## AzerothCore Module

**Era-authentic talent trees for characters progressing through the expansions.** While a
character is in the Vanilla or TBC era (as decided by
[mod-individual-progression](https://github.com/ZhengPeiRu21/mod-individual-progression)), the
stock WotLK talent window is fenced off and replaced by that era's real trees for its class — and
the talents actually do what their tooltips say.

Individual Progression gives every character its own expansion timeline on a single WotLK realm,
but it does not touch the talent system: a "Vanilla" character still gets WotLK's 71-point trees
and glyphs. This module closes that gap. It depends on IP for a character's era and never edits IP's
data.

> Looking for a complete server instead of a module? This mod was developed for, and is installed
> automatically by, **[azerothcore-playerbots-docker-automated](https://github.com/lathcf/azerothcore-playerbots-docker-automated)**
> — a Docker deployment of AzerothCore + playerbots + Individual Progression with this and several
> other custom mods pre-wired.

### What you get
* **Era trees for all nine original classes, in both Vanilla (51 points) and TBC (61 points)**,
  authored from each era's own data. WotLK-era characters and Death Knights keep the stock trees.
* **Correct talents, not cosmetic ones.** Where WotLK kept a talent's behaviour and numbers the
  stock passive is reused; where WotLK retuned or removed it the module ships its own server-side
  version — restored abilities (the Vanilla seal/judgement system, Bloodthirst, Conflagrate, the
  Vanilla Vampiric Embrace, TBC Mangle, the full Vanilla/TBC totem set, …), procs and per-rank
  passives: about 3,600 custom spell rows in a reserved id band. **Stock spells are never modified**,
  so WotLK-era characters on the same realm are unaffected.
  See **[Era talents — class by class](docs/era-talents-classes.md)**.
* **Era-correct spellbooks and glyphs.** WotLK-only talents and their spells are stripped in earlier
  eras, and glyphs are WotLK-only (`EraTalents.GlyphGate`; Death Knights exempt).
* **Real expansion transitions.** Crossing into TBC or WotLK wipes talents for a full respec into the
  new trees. Because of that, advancing is a **player choice**: when eligible, Anduin Wrynn
  (Alliance) / Thrall (Horde) offer "Progress to the next expansion" with a confirm popup.
* **Bots too (optional).** With mod-playerbots installed and `EraTalents.BotTalents = 1`, bots in
  the Vanilla (1–60) and TBC (61–70) level bands spend authored era builds for their spec, the bot AI
  uses the era versions of its spells, and their consumables/glyphs are era-gated.

## Requirements
* **AzerothCore 3.3.5a** — patches cut against the mod-playerbots fork at `413bea61`
  (2026-09-07); see *Compatibility* below for stock `master`.
* **[mod-individual-progression](https://github.com/ZhengPeiRu21/mod-individual-progression)** —
  **required**. Follow its own install notes (`EnablePlayerSettings = 1`,
  `DBC.EnforceItemAttributes = 0`). Cut against IP `977e200`.
* Optional: **[mod-playerbots](https://github.com/mod-playerbots/mod-playerbots)** (`b949b50`) on
  the playerbots fork of the core, and
  **[mod-multibot-bridge](https://github.com/Wishmaster117/mod-multibot-bridge)** (`759c100`).
  Both are detected automatically at build/patch time.

## How to Install
1. Clone the module (and IP, if you have not already) into your core's `modules/` directory:
   ```bash
   cd /path/to/azerothcore-wotlk
   git clone https://github.com/ZhengPeiRu21/mod-individual-progression.git modules/mod-individual-progression
   git clone https://github.com/lathcf/mod-era-talents.git modules/mod-era-talents
   ```
2. Apply the source patches (core + IP always; playerbots / multibot-bridge only when those
   modules are present):
   ```bash
   modules/mod-era-talents/apply-patches.sh .
   ```
   The script is idempotent — **re-run it after every `git pull`/`reset` of the core or those
   modules** (a reset silently drops the patches), then rebuild.
3. Re-run CMake and build as usual. CMake prints `[mod-era-talents] mod-playerbots found — bot era
   talents compiled in` or `… not found — bot support compiled out (players only)`.
4. Start the worldserver. The core's DB updater applies `data/sql/world/base` and
   `data/sql/characters/base` automatically. The startup log shows
   `[mod-era-talents] startup (enable=1)`.
5. Optional: copy `conf/mod_era_talents.conf.dist` to `<etc>/modules/mod_era_talents.conf` to edit
   the knobs below. Defaults are sensible; the module runs without a copy.

### Client install (each player)
Two pieces, both required for the intended experience:
* **The EraTalents addon** — copy `client-addon/EraTalents/` to
  `World of Warcraft/Interface/AddOns/EraTalents/`. It **is** the talent window in Vanilla/TBC (the
  normal talent button/key opens it).
* **`patch-V.mpq`** — copy to `World of Warcraft/Data/`. This is IP's own client patch with this
  module's custom buff/debuff rows merged in, so custom auras (e.g. the Improved Blizzard "Chilled"
  debuff) show an icon and name. Without it everything still works; those auras just have no icon.
  Build it with `client-patch/build-mpqpack.sh` (once) then `client-patch/build-client-patch.sh`
  (writes `client-patch/out/patch-V.mpq`), or download one from this repo's Releases when attached.
  The addon warns in red chat when a player's `patch-V.mpq` is from a stale generation.

## Configuration (`conf/mod_era_talents.conf.dist`)
| Key | Default | Meaning |
|-----|---------|---------|
| `EraTalents.Enable` | 1 | Master switch. Off = module fully inert. |
| `EraTalents.Debug` | 0 | Log each addon request/reply and every reconcile to the console. |
| `EraTalents.BotTalents` | 0 | Bots in the Vanilla/TBC level bands get era builds (needs mod-playerbots compiled in). |
| `EraTalents.GlyphGate` | 1 | Glyphs are WotLK-only for Vanilla/TBC-era characters (players by IP era, bots by level band; DKs exempt). |
| `EraTalents.AdvanceGossip` | 1 | Anduin/Thrall offer "Progress to the next expansion" when eligible. |
| `EraTalents.AdvanceGossip.TextTBC` / `.TextWotLK` | (see file) | Confirm-popup wording. |

The IP patch adds `IndividualProgression.ManualAdvanceStates` to IP's config. Set it to `"8 13"`
(the module's intended value) so IP's automatic advance can no longer cross the two talent-wiping
stages (7→8 Vanilla→TBC, 12→13 TBC→WotLK); the player advances by choice at the faction leader.
Leave it empty to keep IP's stock automatic progression — talents are then wiped the moment a
boss kill or quest turn-in crosses the stage.

## Playerbots (optional)
When `modules/mod-playerbots` exists the build compiles the bot layer in and `apply-patches.sh`
applies the two playerbots patches (factory era builds + era-aware AI spell resolution) and, if
present, the multibot-bridge patch (era-correct spec display in BotGrid). A bot's era comes from
its **level band** (1–60 Vanilla, 61–70 TBC, 71+ WotLK), never from IP progression. Turn it on with
`EraTalents.BotTalents = 1`. Bots need no client artifact.

## Commands (GM / console)
`.eratalents status|doctor|reset|learn <character>` — **`doctor` is the first stop for any "this
talent doesn't work" report**: it prints the character's era, spent ranks, every expected era spell
and whether it is known, orphaned band spells, and (with playerbots) the AI's spell resolution.

## Authoring and contributing
Read **[docs/era-talents-framework.md](docs/era-talents-framework.md)** first — it is the decision
tree, field-semantics table and verification checklist for every era spell. One YAML per
(era, class) under `era-data/` is the source of truth; `tools/era-regen.sh` is the **only** way to
ship a change (it regenerates SQL, the band allowlist header, the addon Lua and — when the MPQ tools
are built — the client patch under one generation stamp). `tools/era_audit.py` must be clean and
`uv run --with pyyaml --with pytest python -m pytest tools` green. Running the pipeline needs the base
DBCs once: `client-patch/build-mpqpack.sh` then `tools/fetch-base-dbc.sh` (stages IP's server-side
`Spell.dbc`/`SkillLineAbility.dbc` into the gitignored `client-patch/base/`). Patch inventory and regeneration:
[docs/patches.md](docs/patches.md).

## Compatibility
All ten patches were cut against the commit ids under *Requirements*. On 2026-09-07 the six core
patches and the IP patch also applied cleanly to **stock `azerothcore-wotlk` master `c80c4b9`**, and
every module translation unit compiled there without mod-playerbots (`docs/verification.md`). Core
patches are inert
until a character is in an era band, so a stock server behaves identically until then. If a patch
stops applying after an upstream change, `apply-patches.sh` names it; regenerate with the matching
`tools/regen-*.sh` (see `docs/patches.md`) or open an issue with your commit ids.

## License and credits
MIT (see `LICENSE`). The core patches modify AzerothCore (AGPL-3.0) source and carry that licence.
Companion project: [azerothcore-playerbots-docker-automated](https://github.com/lathcf/azerothcore-playerbots-docker-automated)
(the full Docker server this module ships in).
Thanks to AzerothCore, ZhengPeiRu21's mod-individual-progression, the mod-playerbots project,
wago.tools (TBC 2.5.4 talent data) and Daribon's 1.12.1 talent calculator data.

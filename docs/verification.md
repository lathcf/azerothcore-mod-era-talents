# Verification records

## 2026-09-07 — stock-core compile without mod-playerbots
- Stock azerothcore-wotlk master `c80c4b9` + mod-individual-progression `977e200` + this module at `0fb306f`.
- `apply-patches.sh` on stock master:
  ```
  ==> mod-era-talents patches -> <ac-root>
      applied:         core/01-shatter-crit-vs-frozen.patch
      applied:         core/02-corruption-era-casttime.patch
      applied:         core/03-hotw-era-bear-stamina.patch
      applied:         core/04-sentry-era-unsummon.patch
      applied:         core/05-wand-spec-era-no-spell-leak.patch
      applied:         core/06-molten-fury-era-window.patch
      applied:         individual-progression/01-manual-advance-states.patch
      (mod-playerbots not present — bot patches skipped)
      (mod-multibot-bridge not present — bridge patch skipped)
  ==> done
  ```
  exit=0 — all 6 core patches and the IP patch apply cleanly to stock master, unmodified.
- cmake: `[mod-era-talents] mod-playerbots not found — bot support compiled out (players only)`
- 16/16 module translation units compiled (compile_commands.json, MOD_PLAYERBOTS undefined).

## 2026-09-07 — dev-box full build with mod-playerbots (AzerothCore overlay stack)
- Fork `413bea61` + mod-playerbots `b949b50` + IP `977e200` + bridge `759c100`, this module at `e10f859`, consumed as a clone via the overlay's `setup.sh`.
- `apply-patches.sh` after the overlay's own 14 patches: 10/10 applied. cmake: `mod-playerbots found — bot era talents compiled in`. Build exit 0.
- Worldserver: `loaded 1011 talent nodes (generation c8293d48)`; `.eratalents doctor` on a TBC-band rogue bot: 0 orphans, AI resolve working; a shaman bot levelled 40→65 shows the TBC quest-taught totems (947026 / 3599 / 947174).

# Era Talents — what the mod does, class by class

A summary of what `mod-era-talents` restores for each class in each era. It is meant as an
orientation page, not a spell-by-spell reference — every talent, value, and helper spell is
authored in the YAML under [`era-data/`](../era-data/) (`vanilla/<class>.yaml`,
`tbc/<class>.yaml`), and the authoring rules live in
[`docs/era-talents-framework.md`](era-talents-framework.md). For the player-facing overview see
the [Era talents section of the README](../README.md#era-talents-mod-era-talents).

## How to read this page

- **Era** = the character's Individual Progression stage: Vanilla (stages 0–7), TBC (8–12),
  WotLK (13+). WotLK-era characters — and Death Knights — keep the stock talent trees; the mod
  is inert for them.
- **Talent nodes** = the number of talents in the era's three trees for that class.
- **Custom spells** = distinct server-side spell rows the mod authors for that (era, class) in
  its reserved id band: per-rank talent passives, era clones of abilities WotLK changed, proc
  payloads, and helper effects (buffs/debuffs, totem pulses). None of them replace a stock spell —
  stock spell ids are never modified, because eras are per-character while spells are global.
- **The bullets** under each era are the *visible* things that class gets back — abilities, buffs,
  debuffs, procs and systems whose WotLK version differed enough that the mod had to author its
  own — plus anything a core patch carries. Each bullet says briefly how the era version differs.
  Talents that merely retune a stock spell (a passive spell-mod or stat aura) are the bulk of
  every tree and are not itemised, though the two counts above do include them.

The generated Vanilla trees use the 1.12.1 client data as the value reference; the TBC trees use
TBC Classic (2.5.4) values. Where a talent's behaviour lives in core code rather than spell data,
a small band-gated core patch carries it (called out per class below).

## Totals

| | Talent nodes | Custom spells |
|---|---:|---:|
| Vanilla (9 classes) | 432 | 1,681 |
| TBC (9 classes) | 579 | 1,912 |
| **Total** | **1,011** | **3,593** |

## Druid

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 47 | 137 |
| TBC | 62 | 171 |

**Vanilla**

- **Nature's Grasp** — a castable 35%-chance, single-charge root; WotLK's is a free 100%-chance,
  3-charge passive.
- **Omen of Clarity** — a castable 10-minute self buff, not WotLK's hidden always-on passive.
- **Insect Swarm** — five ranks at 1.12 damage values with the -2% attack-hit debuff; WotLK
  retuned both.
- **Nature's Grace** — any spell crit grants a flat -0.5 sec next-cast buff that waits until it's
  used; WotLK made it Nature-only percentage haste.
- **Leader of the Pack** — +3% *party* melee and ranged crit in the cat and bear forms, without
  the heal and mana return WotLK added.
- **Predatory Strikes** — feral attack power from level alone; WotLK added a weapon-AP share and a
  Ravage/Pounce proc.
- **Enrage** — bleeds 20 rage over 10 sec with no instant chunk, so Improved Enrage supplies the
  only up-front rage.

**TBC**

- **Mangle** — the TBC ability in both Bear and Cat, on TBC's 12-second bleed window (WotLK's is
  60 sec) and with Cat at 160% weapon damage instead of 200%.
- **Tree of Life** — the Restoration form; the core's hardcast WotLK raid aura is suppressed for
  era druids and replaced with TBC's 45-yard party aura, healing received equal to 25% of the
  druid's Spirit.
- **Improved Faerie Fire** — TBC's +1/2/3% melee and ranged hit, delivered as a companion debuff
  on the Faerie Fire target.
- **Omen of Clarity** — a 30-minute castable buff, melee-only, with a 10-second internal cooldown
  the Vanilla version doesn't have.
- **Nature's Grasp** — the same 35% / one-charge shape as Vanilla, but free to cast.
- **Nature's Grace** — a 15-second window on the -0.5 sec next-cast buff, where the Vanilla
  version waits indefinitely.
- **Insect Swarm** — six ranks at TBC (2.5.4) values.
- **Leader of the Pack** — +5% party crit inside 45 yards, without WotLK's raid scope or its crit
  heal; Improved Leader of the Pack adds TBC's own 2/4% party heal on crit.
- **Heart of the Wild** — the bear Stamina bonus lives in core code, so core patch 0023 gives
  TBC-era druids the full Intellect-percentage value.

## Hunter

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 46 | 160 |
| TBC | 64 | 172 |

**Vanilla**

- **Aimed Shot** — a 3-second cast on a 6-second cooldown, in place of WotLK's instant shot with a
  healing debuff and a 10-second cooldown.
- **Scorpid Sting** — the 1.12 Strength and Agility debuff, not WotLK's flat hit-chance reduction;
  Improved Scorpid Sting adds the Stamina drain, PvP only.
- **Trueshot Aura** — three ranks of flat +50/75/100 ranged *and* melee attack power to the party
  inside 45 yards; WotLK's is one rank of +10%.
- **Deterrence** — +25% dodge and parry for 10 sec on a 5-minute cooldown, against WotLK's
  near-total avoidance for 5 sec on 90 seconds.
- **Wyvern Sting** — a 12-second sleep and a 300-damage Nature DoT on waking, usable only out of
  combat; WotLK's sleeps for 30 sec and works in combat.
- **Bestial Wrath** — 18 seconds for 12% of base mana, where WotLK's is 10 seconds for 10%.
- **Counterattack** — three ranks at Vanilla damage with the same 5-second root.
- **Pet talents** — Endurance Training, Thick Hide, Unleashed Fury, Ferocity, Bestial Discipline
  and Spirit Bond apply to the pet through the hunter's own talents, at 1.12 magnitudes and
  without the owner-side halves WotLK bolted on.
- **Improved Concussive Shot** — a 4-20% chance to stun for 3 sec, rebuilt because WotLK reduced
  the talent to a duration modifier.
- **Improved Wing Clip** — a 4-20% chance to root for 5 sec, an effect WotLK removed entirely.
- **Entrapment** — five ranks at a 5-25% chance to root for 5 sec, against WotLK's three ranks and
  shorter roots.
- **Improved Aspect of the Hawk** — a pure bonus to the aspect's attack power, without the
  ranged-haste proc that only arrived in TBC.
- **Monster Slaying / Humanoid Slaying** — the damage and crit-damage bonuses against specific
  creature types, absent from WotLK's data altogether.
- **Improved Serpent Sting** — +2-10% Serpent Sting damage, with no WotLK equivalent at all.

**TBC**

- **The Beast Within** — pairs with Bestial Wrath for +10% damage *and* -20% mana cost; WotLK's
  only cuts mana.
- **Readiness** — resets every hunter cooldown, on TBC's 5-minute cooldown rather than the stock 3.
- **Silencing Shot** — restored onto the global cooldown, which WotLK took it off.
- **Expose Weakness** — debuffs the *target* so every attacker gains attack power from the
  hunter's Agility; WotLK reworked it into a self-only buff.
- **Ferocious Inspiration** — pet crits give the party +1/2/3% damage, rebuilt from scratch since
  the payload ids are missing from 3.3.5a.
- **Master Tactician** — a flat 6% proc chance for +2-10% crit; WotLK scales the chance by rank
  instead.
- **Rapid Killing** — authored as its own proc: -1/-2 min off Rapid Fire, and a kill boosts the
  next Aimed, Arcane or Auto Shot.
- **Bestial Swiftness** — the pet speed bonus with TBC's outdoor-only gate, which WotLK's rework
  dropped.
- **Aimed Shot** — a 2.5-second cast on a 6-second cooldown with the 50% healing debuff, across
  seven ranks.
- **Trueshot Aura** — four ranks of flat attack power to the party, free to cast, against WotLK's
  single-rank raid-wide percentage.
- **Deterrence** — the same 10-second dodge-and-parry version, learnable at level 20 with no
  ranged-weapon requirement.
- **Wyvern Sting** — four ranks, and unlike the Vanilla version it can be used in combat.
- **Animal Handler** — mounted speed plus pet hit chance; WotLK swapped both for unrelated effects.
- **Catlike Reflexes** — self dodge *and* pet dodge, where WotLK replaced the pet half.
- **Focused Fire** — nets the damage bonus to the hunter alone while a pet is out.
- **Careful Aim** — converts 15/30/45% of Intellect to ranged attack power; WotLK converts up to
  100%.
- **Combat Experience** — Agility *and* Intellect, which WotLK flattened into one stat.
- **Survival Instincts** — damage reduction plus attack power; WotLK swapped the attack power for
  crit.
- **Concussive Barrage** — a 2/4/6% Auto Shot daze chance off a wider spell set than WotLK's.
- **Improved Stings** — five ranks (WotLK has three) with a wider dispel-resistance scope.
- **Counterattack** — four ranks, one more than WotLK.
- **Entrapment / Improved Wing Clip / Clever Traps** — the era roots and trap bonuses again,
  widened to cover Snake Trap.
- **Scorpid Sting** — TBC's -5% hit debuff rather than WotLK's -3%.

## Mage

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 49 | 159 |
| TBC | 67 | 163 |

**Vanilla**

- **Pyroblast** — back to its authentic 6-second cast; WotLK 3.0 shortened it to 5.
- **Arcane Power** — +30% damage for +30% cost on a 3-minute cooldown, where WotLK retuned it to
  +20% / +20% on 2 minutes.
- **Presence of Mind** — the same instant cast, on a 3-minute cooldown instead of WotLK's 2.
- **Combustion** — a plain stacking-crit passive on a 3-minute cooldown, without WotLK's rebuilt
  +50% crit-damage bonus.
- **Blast Wave** — damage and the 50% daze only; WotLK added a knockback.
- **Ice Barrier** — a flat absorb from base points alone, with none of the spell-power scaling
  WotLK's script adds.
- **Cold Snap** — a 10-minute cooldown, not WotLK's 8.
- **Magic Absorption** — restores 1-5% mana on a fully resisted spell, a rider the WotLK version
  leaves unwired.
- **Improved Counterspell** — silences for the full 4 sec rather than WotLK's 2.
- **Fire Vulnerability** — a real +3% fire-damage-taken debuff stacking five times; WotLK's
  same-named effect is a crit-taken buff instead.
- **Winter's Chill** — +2% crit chance with Frost only, not WotLK's halved +1% across all schools.
- **Improved Blizzard** — the authentic 30/50/65% slow, against WotLK's weaker 25/40/50%.
- **Fire / Frost Ward reflect** — Improved Fire Ward and Frost Warding show a buff icon while the
  ward is up and reflect from it.
- **Wand Specialization** — gated to actual wands (the stock encoding points at crossbows), with
  core patch 0025 stopping the wand bonus from leaking onto ordinary spells.
- **Shatter** — the crit bonus against frozen targets is conditional, which no aura can encode, so
  core patch 0018 carries it.

**TBC**

- **Dragon's Breath** — a 3-second disorient (WotLK's is 5), sharing a cooldown category with Cone
  of Cold as it did in 2.4.3.
- **Slow** — -50% movement, ranged and cast speed at 20% mana; WotLK's is -60/-60/-30 at 12%.
- **Arcane Potency** — a Clearcast crit grants +10/20/30% crit chance for 15 sec; TBC's own
  encoding is inert on this core, so the buffs are authored fresh.
- **Improved Blink** — -13%/-25% chance to be hit for 4 sec after Blink, without WotLK's higher
  values or its mana-cost half.
- **Pyroblast** — the authentic 6-second cast, as in Vanilla.
- **Arcane Power / Presence of Mind / Combustion** — TBC values and 3-minute cooldowns, re-cut as
  their own clones.
- **Blast Wave** — damage and daze without WotLK's knockback.
- **Ice Barrier** — TBC's genuine 0.1 spell-power coefficient in place of WotLK's 0.8068.
- **Magic Absorption** — 1-5% mana on a full resist, on TBC's own resistance mask.
- **Improved Counterspell** — the full 4-second silence.
- **Fire Vulnerability / Winter's Chill / Improved Blizzard** — the same three era debuffs as
  Vanilla, at TBC proc rates and values.
- **Molten Shields / Frost Warding** — a 10/20% ward reflect chance (and, for Frost, +15/30% Frost
  and Ice Armor) while the ward is up.
- **Wand Specialization** — the same wand gating and core patch 0025 leak fix as Vanilla.
- **Shatter** — core patch 0018 again, with TBC's 10-50% ladder across five ranks.
- **Molten Fury** — the damage bonus applies under 20% target health, not WotLK's 35%; core patch
  0026.

## Paladin

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 44 | 249 |
| TBC | 64 | 304 |

**Vanilla**

- **One Judgement button** — a single era Judgement reads whichever Seal is active, casts that
  Seal's own judgement payload, and *consumes* the Seal; WotLK's leaves the Seal up and splits into
  three buttons. It is data-driven, so a new seal only has to name its payload.
- **Seal of Righteousness** — eight ranks; the on-hit Holy damage scales with main-hand weapon
  speed, and its judgement is a separate flat Holy hit.
- **Seal of Command** — the real 70% weapon-damage Holy proc at 7 procs per minute, not WotLK's
  35% cleave, and its judgement is a flat hit rather than a re-fired swing proc.
- **Seal of Justice** — the 2-second stun proc and the fear-immunity judgement debuff, at 5 procs
  per minute.
- **Seal of Light** — a flat self-heal on hit and a flat heal for the attacker on judgement, where
  WotLK made both scale off maximum health.
- **Seal of Wisdom** — flat mana back on hit and on judgement, at 12 procs per minute.
- **Seal of the Crusader** — rebuilt from nothing, since it is absent from 3.3.5a: +attack power
  and +40% attack speed, with a Holy-damage-taken judgement debuff.
- **Holy Shock** — three ranks (WotLK has seven) at true 1.12 heal and damage values, without
  WotLK's bonus scaling.
- **Holy Shield** — +30% block for 10 sec over four charges at 40 Holy per block; WotLK gives
  eight charges and a block-value bonus.
- **Redoubt** — every crit taken grants the block buff, rather than WotLK's 10% roll on any hit,
  and it carries no passive block value.
- **Illumination** — refunds the full base mana cost of a crit heal, not WotLK's 30%.
- **Blessing of Sanctuary** — flat damage reduction plus 14 Holy reflected on a block, sidestepping
  WotLK's scripted mana-and-stat rework.
- **Reckoning** — the extra-attack proc at Vanilla's 20-100% chance on crit; WotLK retuned it to
  2-10%.
- **Repentance** — a 6-second incapacitate on humanoids only; WotLK made it 60 sec and widened the
  creature types.
- **Sanctity Aura** — +10% party Holy damage inside 30 yards, rebuilt because WotLK removed it
  outright.
- **Eye for an Eye** — reflects 15/30% of the spell crit damage you take, above WotLK's 3.0.2
  retune.
- **Vindication** — -5/10/15% Strength and Agility on the target; WotLK reworked it into flat
  attack-power reduction.
- **Vengeance** — five ranks of 3-15% Physical and Holy damage for 8 sec after a crit, where WotLK
  has three ranks.
- **Improved Lay on Hands** — the cooldown reduction, plus a +15/30% armor buff on the target that
  the WotLK talent lacks.

**TBC**

- **Seals and judgements** — the same single-button design, but every standard seal is a fresh
  clone authored at wago 2.5.4 values (including that patch's roughly twofold seal rebalance), with
  each seal's on-hit proc and its judgement payload as cleanly separate spells.
- **Seal of Blood** — Horde only: hits deal Holy damage worth 35% of the swing while costing you
  10% of it in self-damage, and its judgement costs 33%.
- **Seal of Vengeance** — Alliance only: hits stack a Holy DoT up to five times, and Judgement of
  Vengeance gains +10% damage per stack.
- **Seal of Righteousness / Light / Wisdom / the Crusader** — each gains TBC's extra high-level
  rank, with Light and Wisdom moved onto true procs-per-minute rates.
- **Seal of Command** — six ranks at a flat 40% proc chance rather than Vanilla's procs per minute.
- **Seal of Justice** — two ranks at a 25% flat chance, correctly costing 10% of base mana.
- **Crusader Strike** — 110% weapon damage with a scripted judgement refresh; WotLK reworked it
  into a different shape.
- **Avenger's Shield** — TBC's lower 270-330 Holy damage, against WotLK's 439, on the same
  three-target chain.
- **Ardent Defender** — 6-30% damage reduction below 35% health, without the cheat-death absorb
  WotLK added.
- **Holy Shield** — TBC's 59 Holy per block, between Vanilla's 40 and WotLK's 78; Improved Holy
  Shield adds charges and block damage on top.
- **Redoubt** — TBC's 10% chance on any damaging hit, not Vanilla's guarantee on a crit.
- **Holy Shock** — a single rank at TBC damage and healing values.
- **Illumination** — refunds 60% of the base mana cost, between Vanilla's 100% and WotLK's 30%.
- **Repentance** — the same 6-second, humanoid-only fix at TBC's own id.
- **Vindication** — -5/10/15% to *all* attributes for 15 sec, where the Vanilla version hits two
  stats for 10.
- **Vengeance** — 1-5% Physical and Holy damage per stack for 30 sec, stacking three times — a
  different shape from both Vanilla and WotLK.
- **Sanctity Aura, Eye for an Eye and Blessing of Sanctuary** — reuse the Vanilla clones, whose
  values TBC did not change; Improved Sanctity Aura adds +1/2% on top.
- **Reckoning** — the one talent here that takes the stock WotLK proc chain, because TBC's proc
  rate already matches it.

## Priest

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 47 | 143 |
| TBC | 64 | 188 |

**Vanilla**

- **Vampiric Embrace** — cast on an enemy rather than yourself: your party heals for 20% of the
  Shadow damage you deal to that target for 1 min.
- **Power Infusion** — a flat +20% spell damage *and* healing for 15 sec on a 3-minute cooldown,
  where WotLK's grants haste and cheaper casts.
- **Blackout** — Shadow spells gain a 2-10% chance to stun for 3 sec, resistible and visible on the
  client.
- **Inspiration** — crit heals grant the target +8/16/25% armor, using the real armor encoding
  rather than a damage-reduction stand-in.
- **Shadow Weaving** — a shared, priest-pooled five-stack +3% Shadow-damage-taken debuff, so two
  priests no longer overwrite each other.
- **Martyrdom** — Focused Casting comes from any melee or ranged crit, including ability crits, not
  just auto-attacks.
- **Spirit Tap** — +100% Spirit and mana regeneration while casting after an XP-yielding kill,
  excluding grey and honorless kills.
- **Wand Specialization** — +5-25% wand damage, gated to actual wands (the stock encoding points at
  crossbows), with core patch 0025 stopping the bonus from leaking onto ordinary spells.
- **Silent Resolve** — -4 to -20% spell threat plus +10 to +50% resistance to dispels on your own
  buffs.

**TBC**

- **Vampiric Touch** — returns 5% of your Shadow damage as party mana; WotLK replaced that with
  Replenishment.
- **Circle of Healing** — flat mana, no cooldown, and the target's own party only, against WotLK's
  raid-wide percentage-mana version on a 6-second cooldown.
- **Divine Spirit / Prayer of Spirit** — the three-effect chain is restored so Improved Divine
  Spirit has something to modify, and Prayer of Spirit hits one party rather than the raid.
- **Shadowform** — mitigates 15% Physical damage only; WotLK widened it to every school.
- **Misery** — +1-5% magic damage taken on the target, where WotLK repurposed the ids into a
  spell-hit buff.
- **Shadow Weaving** — a debuff on the target, not WotLK's inverted caster-side damage buff.
- **Mind Flay** — TBC's direct periodic damage at 20-yard range; WotLK moved the damage to a
  trigger spell and extended the range.
- **Silence** — 20-yard range and on the global cooldown, both of which WotLK relaxed.
- **Reflective Shield** — the full five-rank 10-50% Power Word: Shield reflect; WotLK kept only two
  ranks.
- **Lightwell** — a 1.5-second cast on a 6-minute cooldown, against WotLK's 0.5 sec and 3 minutes.
- **Pain Suppression** — a 2-minute cooldown, and no use while stunned.
- **Power Infusion** — TBC's 3-minute cooldown rather than WotLK's 2.
- **Surge of Light** — Smite only; WotLK widened the proc to Flash Heal.
- **Holy Concentration** — a flat 2/4/6% clearcasting chance on three heals, not WotLK's
  crit-gated guarantee.
- **Focused Will** — TBC's higher 4/7/10% healing-received bonus, which WotLK retuned down.
- **Martyrdom** — Focused Casting is TBC's interrupt-resistance buff, not WotLK's cast-time cut.
- **Inspiration** — the armor buff again, in place of WotLK's flat physical-damage reduction.
- **Blackout** — rebuilt from scratch, since the TBC spell row is absent from this server's data.
- **Spirit Tap** — +50% mana regeneration while casting; WotLK retuned the same buff to +83%.
- **Wand Specialization** — the same wand gating and core patch 0025 leak fix as Vanilla.

## Rogue

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 51 | 122 |
| TBC | 67 | 133 |

**Vanilla**

- **Riposte** — 150% weapon damage plus a 6-second disarm; WotLK's has no disarm at all, just a
  melee-haste slow.
- **Hemorrhage** — 100% weapon damage, awards a combo point, and leaves a 30-charge / 15-second
  debuff; WotLK's gives no combo point and only 10 charges.
- **Adrenaline Rush** — +100% energy regeneration for 15 sec on a 5-minute cooldown, not WotLK's 3.
- **Preparation** — a 10-minute cooldown that also resets Blind, which WotLK's version dropped.
- **Premeditation** — +2 combo points held for 10 sec on a 2-minute cooldown; WotLK widened the
  window to 20 sec and cut the cooldown to 20 sec.
- **Mace Specialization** — the 1-5% chance to stun for 3 sec; WotLK replaced the whole talent with
  flat armor penetration.
- **Sap** — actually breaks stealth, as it did in Vanilla, and Improved Sap grants the 30/60/90%
  chance to stay hidden anyway.

**TBC**

- **Mutilate** — four ranks with TBC's real +50% damage against poisoned targets and its
  behind-the-target requirement, neither of which exists in the core.
- **Find Weakness** — five finisher-triggered buffs, 2/4/6/8/10% ability damage for 10 sec, rebuilt
  from scratch because the live spell ids are unusable husks.
- **Blade Twisting** — a 10/20% chance to daze for -50% speed over 8 sec; WotLK retuned it to -70%
  over 4 sec off a different trigger.
- **Mace Specialization** — the 1/2/3/4/6% 3-second stun plus TBC's stacking crit-damage bonus, in
  place of WotLK's armor penetration.
- **Setup** — TBC's 15/30/45% chance at a combo point after a dodge or full resist; the core's own
  ladder is 33/66/100%.
- **Riposte** — the same 150% weapon damage and 6-second disarm as the Vanilla version.
- **Adrenaline Rush** — +100% energy regeneration on a 5-minute cooldown, not WotLK's 3.
- **Preparation** — a 10-minute cooldown whose reset list includes Premeditation, which WotLK's
  omits.
- **Premeditation** — +2 combo points held for 10 sec on a 2-minute cooldown, against WotLK's
  20 sec / 20 sec.

## Shaman

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 46 | 307 |
| TBC | 61 | 367 |

Shaman is the largest class because Vanilla and TBC totems were their own summon + creature +
pulse chains that WotLK reworked or removed, so nearly every totem needs rebuilding rather than
retuning.

**Vanilla**

- **Windfury Totem** — three ranks, rebuilt as a party proc plus a C++ script granting the extra
  attack, because the real 1.12 weapon-reapply-enchant chain is dead on 3.3.5a.
- **Flametongue Totem** — the true weapon-enchant chain that adds Fire damage to party weapons, not
  WotLK's unrelated spell-power buff.
- **Fire Nova Totem** — five ranks of the self-destructing version, authored from nothing because
  WotLK repurposed all five summon ids into heal spells.
- **Mana Tide Totem** — three ranks of a flat mana pulse every 3 sec, replacing WotLK's
  percentage-of-maximum script.
- **Grace of Air / Windwall Totems** — both rebuilt from scratch: WotLK folded Grace of Air into
  Strength of Earth and deleted Windwall outright.
- **Strength of Earth Totem** — Strength only, without the Agility that WotLK's merge bundled in.
- **Stoneskin Totem** — six ranks of flat melee-damage reduction; WotLK repurposed the same spell
  into an armor buff, a genuinely different mechanic.
- **Stoneclaw Totem** — the high-threat taunt totem with its 50% stun proc, stripped of WotLK's
  "shield your other totems" absorb.
- **Healing Stream / Mana Spring Totems** — declarative periodic-tick auras, where WotLK uses a
  scripted spell-power heal and a continuous regen aura respectively.
- **Searing / Magma Totems** — retuned damage and mana at every rank.
- **Disease / Poison Cleansing Totems** — split back apart; WotLK merged them into one Cleansing
  Totem.
- **Frost / Fire / Nature Resistance Totems** — the same resistance numbers as WotLK, on flat mana
  costs and a 2-minute duration instead of 5.
- **Earthbind Totem** — the 45-second slow field, on a minted periodic driver so the pulse actually
  re-fires for the full duration.
- **Tremor / Grounding Totems** — the dispel and spell-redirect mechanics are unchanged, retuned to
  flat mana costs.
- **Sentry Totem** — 1.12's flat mana cost and Nature school; core patch 0024 makes its camera bind
  clear when the totem is killed or replaced early.
- **First totems** — Stoneskin, Searing and Healing Stream rank 1 are quest-taught and have no
  trainer row, so each era re-grants its own version to anyone who already earned one, and no
  character is left without a first totem across an era change.
- **Elemental Mastery** — the next Fire, Frost or Nature spell crits and is free, without the
  instant cast and haste WotLK added.
- **Elemental Focus** — Clearcasting off a 10% chance on *any* damage spell, not WotLK's on-crit
  trigger, and it removes the whole mana cost.
- **Stormstrike** — a 20-second cooldown and flat mana cost, against WotLK's 8 seconds and
  percentage cost.
- **Nature's Swiftness** — a 3-minute cooldown; the WotLK shaman version is 2 and shares Elemental
  Mastery's category.
- **Flurry** — 10-30% attack speed across five ranks, where WotLK's ladder starts at 6%.
- **Two-Handed Axes and Maces** — a hidden proficiency passive, since shamans have no baseline
  access and no trainer teaches it.

**TBC**

- **Totem of Wrath** — new: +3% spell hit *and* spell crit for the party inside 30 yards.
- **Wrath of Air Totem** — new: spell damage *and* healing; WotLK dropped the healing half and
  reworked the rest into haste.
- **Tranquil Air Totem** — new: -20% threat for the party, authored fresh from reference data.
- **Earth / Fire Elemental Totems** — new guardian summons on 20-minute cooldowns, with no Vanilla
  counterpart.
- **Mana Tide Totem** — collapsed to a single rank restoring 6% of total mana every 3 sec, and the
  one totem pulse identical enough to reuse verbatim.
- **Windfury Totem** — five ranks, on the same proc-and-script rebuild as Vanilla.
- **Flametongue Totem** — five ranks of the real weapon-enchant chain again.
- **Searing Totem** — the one family that needs almost nothing: ranks 1-6 are granted stock because
  TBC's values already match 3.3.5a, and only rank 7 is cloned.
- **Rank-extended families** — Stoneskin, Strength of Earth, Stoneclaw, Fire Nova, Healing Stream,
  Mana Spring, Grace of Air, Windwall and the three Resistance totems all keep their Vanilla
  mechanic and gain TBC's higher ranks, on the same flat-mana retune.
- **Stoneclaw Totem** — also fixes a threat bug where the taunt pulse added no threat to unengaged
  mobs.
- **Disease / Poison Cleansing Totems** — real 2-minute totems dispelling every 5 sec, still split
  by dispel type because WotLK's merged version is not a usable donor.
- **Earthbind / Magma Totems** — the same minted periodic driver as Vanilla, so their pulses last
  the full duration.
- **Sentry Totem** — TBC's flat mana and Nature school, covered by the same core patch 0024
  unsummon fix.
- **Earth Shield** — three ranks on a flat mana cost, against WotLK's percentage, and TBC's own set
  of proc triggers.
- **Nature's Guardian** — a 10-50% chance to proc by rank, not WotLK's flat certainty with a
  scaling heal.
- **Shamanistic Rage** — returns 30% of attack power as mana, double WotLK's 15%.
- **Spirit Weapons** — Parry proficiency plus a threat reduction that is Physical only; WotLK
  widened it to all schools.
- **Elemental Focus** — TBC's real shape: a crit grants Clearcasting worth -40% cost over two
  charges, not WotLK's flattened always-on version.
- **Elemental Mastery** — its own TBC clone, since the duration and proc-type fields differ even
  where the buff matches.
- **Stormstrike** — TBC's debuff aura, which boosts everyone attacking the target rather than only
  the caster.
- **Nature's Swiftness** — a genuine 3-minute cooldown, where WotLK's shared category resolves to 2.
- **Ancestral Fortitude** — the armor-on-crit-heal proc (Vanilla's Ancestral Healing renamed), and
  TBC's aura scales total armor including gear rather than base armor only.
- **Focused Casting** — the real proc rebuilt: being crit grants 6 sec of pushback immunity, where
  the Vanilla arm had to collapse it into a permanent spell-mod.
- **First totems** — the same quest-taught Stoneskin / Searing / Healing Stream re-grant as Vanilla.

## Warlock

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 50 | 220 |
| TBC | 64 | 177 |

**Vanilla**

- **Conflagrate** — the flat-damage Vanilla nuke that consumes Immolate; WotLK reworked it into an
  instant percentage-of-Immolate hit with a DoT.
- **Siphon Life** — four ranks of castable health drain, 15-45 per tick over 30 sec; the Vanilla
  spell is missing from 3.3.5a entirely.
- **Dark Pact** — drains 150/200/250 pet mana and returns all of it, where the stock id was retuned
  to WotLK's 304.
- **Soul Link** — a 30% damage redirect, rebuilt as a warlock buff plus a hidden pet carrier
  because the core has no handler for the stock spell.
- **Demonic Sacrifice** — the same instant kill, re-cut so the tooltip and the per-demon benefit
  buffs read at Vanilla values.
- **Amplify Curse** — an active, instant, free ability on a 3-minute cooldown; the stock version is
  a hidden passive.
- **Master Demonologist** — the four per-demon bonuses (Imp threat, Voidwalker physical mitigation,
  Succubus damage, Felhunter resistance), applied to both warlock and demon.
- **Pyroclasm** — a real 3-second stun off Rain of Fire and Hellfire; WotLK's trigger is a
  damage-percentage passive.
- **Improved Shadow Bolt** — +4-20% Shadow damage taken over 12 sec, capped at four hits; the stock
  debuff grants crit chance instead.
- **Improved Drain Soul** — +100% mana regeneration for 10 sec on a Drain Soul kill, plus 50%
  regeneration while casting; the WotLK talent has neither.
- **Improved Drain Mana** — each tick also deals a share of the drained mana as Shadow damage, which
  WotLK dropped.
- **Firestone / Spellstone** — the off-hand stones rebuilt as items, since their behaviour spells
  are gone: Firestone gives +10-21 fire damage and a melee proc, Spellstone dispels and absorbs
  400/650/900 magic damage.
- **Pet buffs** — Fel Stamina, Fel Energy, Burning Wish and Touch of Shadow each need an era clone
  because Vanilla's magnitudes differ from the stock ones.
- **Corruption** — a 2-second base cast (WotLK made it instant) so Improved Corruption has something
  to reduce; carried by core patch 0019.

**TBC**

- **Unstable Affliction** — TBC's 18-second, 660-damage DoT on a 1.5-second cast; the stock version
  is 15 sec with a percentage mana cost.
- **Shadowfury** — a 0.5-second cast and 2-second stun, against WotLK's instant cast and 3-second
  stun.
- **Shadow Embrace** — -1 to -5% physical damage done by the target for 12 sec; WotLK repurposed the
  stock ids into a different aura.
- **Nether Protection** — a true 4-second Fire and Shadow immunity, not WotLK's damage-reduction
  payload.
- **Aftermath** — a -50% daze over 5 sec, where WotLK retuned it to -70% in a different mechanic
  group.
- **Fel Domination** — TBC's 15-minute cooldown, not the stock 3.
- **Mana Feed** — TBC splits the mana return across three ranks at 33/66/100% instead of WotLK's
  single 100%.
- **Soul Link** — a 20% redirect plus the +5% damage bonus, split between warlock and demon.
- **Conflagrate** — six ranks of the flat-damage nuke, as in Vanilla.
- **Siphon Life** — six ranks on TBC's own mana curve.
- **Amplify Curse** — the active version again, boosting Curse of Doom or Agony by 50%; TBC's buff
  is dispellable where Vanilla's was not.
- **Master Demonologist** — five branches, adding TBC's Felguard bonus.
- **Improved Shadow Bolt / Pyroclasm / Improved Drain Soul** — the same three reconstructions as
  Vanilla.
- **Firestone / Spellstone** — the Vanilla stones plus TBC's Master tier: +30 fire damage, and a
  Master Spellstone that dispels and grants 20 crit rating with no absorb.
- **Corruption** — also a 2-second cast at every TBC rank, from the same core patch 0019.

## Warrior

| Era | Nodes | Custom spells |
|---|---:|---:|
| Vanilla | 52 | 184 |
| TBC | 66 | 237 |

**Vanilla**

- **Bloodthirst** — a 45% attack-power hit whose next five swings heal, where WotLK's is 50% with
  no heal at all.
- **Shield Slam** — four ranks at Vanilla damage, modified by block value; WotLK's ranks hit
  substantially harder.
- **Death Wish** — +20% physical damage and fear immunity, paid for with -20% armor and
  resistances; WotLK dropped both halves of the trade.
- **Last Stand** — +30% health for 20 sec on a 10-minute cooldown, not WotLK's 3.
- **Concussion Blow** — a pure 5-second stun on a 45-second cooldown; WotLK added damage and halved
  the cooldown.
- **Tactical Mastery** — retains 5/10/15/20/25 rage across a stance change, per rank.
- **Shield Specialization** — block chance plus a chance at rage on an actual block, where WotLK
  grants rage on any hit taken.
- **Deep Wounds** — bleeds 20/40/60% of average weapon damage over 12 sec; WotLK bleeds the
  triggering hit's damage over 6.
- **Flurry** — 10-30% attack speed for three swings after a crit, five points higher per rank than
  WotLK's.
- **Enrage** — 5-25% melee damage for 12 sec or 12 swings after being crit; WotLK halved the
  magnitude and removed the swing cap.
- **Improved Hamstring** — a 5/10/15% chance to immobilize for 5 sec, an effect WotLK's talent no
  longer has.
- **Improved Revenge** — a 15/30/45% chance to stun for 3 sec; WotLK reworked it into a flat damage
  bonus.
- **Mace Specialization** — the 3-second stun proc WotLK dropped for flat armor penetration.
- **Improved Berserker Rage** — Berserker Rage generates 5/10 rage on cast, which WotLK's version
  does not.
- **Stance modifiers** — hidden passives put each stance's damage and threat back at 1.12.1 values
  (Defensive is -10% damage done and taken and +30% threat, against WotLK's -5% / -10% / +45%).

**TBC**

- **Devastate** — 50% weapon damage plus 15/25/35 per Sunder stack, needing a one-handed weapon
  rather than a shield; WotLK's is 120% weapon with far bigger stack bonuses.
- **Rampage** — TBC's active, usable within 5 sec of a crit and stacking +30/40/50 attack power
  five times; WotLK's talent of that name is an unrelated party crit passive.
- **Sweeping Strikes** — cleaves the next 10 swings within 10 sec, where WotLK's is 5 swings over 30.
- **Bloodthirst** — six ranks at 45% attack power for 30 rage on a 6-second cooldown, with no weapon
  requirement; WotLK's is 50% for 20 rage on 4 sec.
- **Shield Slam** — six ranks at TBC damage, again below WotLK's.
- **Death Wish** — +20% damage with fear immunity for +5% damage taken; WotLK kept the drawback and
  dropped the immunity.
- **Last Stand** — an 8-minute cooldown, not WotLK's 3.
- **Concussion Blow** — the same undamaging 5-second stun on a 45-second cooldown.
- **Shield Specialization** — rage on an actual block only, and 1 rage rather than WotLK's 5.
- **Blood Frenzy** — Rend and Deep Wounds add 2/4% physical damage taken, and the debuff is properly
  tagged as a bleed so bleed-immune targets resist it.
- **Blood Craze** — regenerates 1/2/3% health over a full 6 sec; WotLK compresses it into half the
  time.
- **Deep Wounds** — the same weapon-damage bleed as Vanilla, ticking every 3 sec over 12.
- **Enrage** — fires on every crit taken at full magnitude; WotLK's triggers 30% of the time for
  half as much.
- **Improved Shield Bash** — a 50/100% chance to silence for 3 sec, rebuilt because WotLK
  repurposed the payload.
- **Mace Specialization** — the 3-second stun, plus 7 rage.
- **Improved Berserker Rage** and the **stance modifiers** — as Vanilla; 1.12.1 and 2.4.3 stance
  numbers are identical.

## Death Knight

No era trees. Death Knights are a WotLK class and always use the stock talent frame; the glyph
gate also exempts them.

## Where the rest lives

- **Authoring rules and pipeline:** [`docs/era-talents-framework.md`](era-talents-framework.md)
  (read before changing any era spell) and
  [`docs/era-talents-cross-class-gotchas.md`](era-talents-cross-class-gotchas.md).
- **Regenerating artifacts after a YAML change:** `tools/era-regen.sh` (the only supported way);
  `tools/era_audit.py` must be clean.
- **Per-class verification records:** `docs/verification/era-talents-*.md`.
- **Core patches the mod relies on:** 0018 (Shatter), 0019 (Corruption cast time), 0023 (Heart
  of the Wild), 0024 (Sentry Totem), 0025 (Wand Specialization), 0026 (Molten Fury), plus
  0020/0021/0022 (bot and BotGrid integration) and 0027 (manual expansion advance) — see
  [`patches/`](../patches/).

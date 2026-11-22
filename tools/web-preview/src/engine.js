/*
 * NEXORA · Motor de reglas para la vista previa web.
 * Port 1:1 de src/ReplicatedStorage/Shared/Domain (Rng, Stats, ElementChart,
 * Leveling, BattleEngine, BattleAI). Mismo orden de consumo del Rng: con la misma
 * semilla produce exactamente el mismo combate que Luau (tools/web-preview/parity).
 * La fuente de verdad es el código Luau; este archivo solo existe para la vista previa.
 */
(function (root) {
  "use strict";

  function createEngine(CONFIG) {
    const Combat = CONFIG.Combat;
    const Abilities = CONFIG.Abilities;
    const Talents = CONFIG.Talents;
    const Species = CONFIG.Species;
    const Progression = CONFIG.Progression;
    const Elements = CONFIG.Elements;
    const Encounters = CONFIG.Encounters;
    const Rarities = CONFIG.Rarities;
    const Guardians = CONFIG.Guardians || { ById: {} };

    const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
    const round = (x) => Math.floor(x + 0.5);

    // ---------------- Rng (Park–Miller) ----------------
    const MOD = 2147483647, MULT = 48271;
    class Rng {
      constructor(seed) {
        let s = Math.floor(Math.abs(seed)) % MOD;
        if (s === 0) s = 1;
        this.state = s;
      }
      next() { this.state = (this.state * MULT) % MOD; return (this.state - 1) / (MOD - 1); }
      chance(p) { if (p <= 0) return false; if (p >= 1) return true; return this.next() < p; }
      range(min, max) { return min + (max - min) * this.next(); }
      int(min, max) { return min + Math.floor(this.next() * (max - min + 1)); }
    }

    // ---------------- Stats ----------------
    const KEYS = ["VID", "ATQ", "DEF", "ESE", "VEL"];
    const Stats = {
      levelFactor: (level) => Progression.LevelScaleBase + Progression.LevelScalePerLevel * level,
      formFactor: (form) => Progression.FormFactor[form] ?? Progression.FormFactor.Brote,
      scale(form, level) { return Stats.formFactor(form) * Stats.levelFactor(level); },
      effectiveFrom(block, form, level, multipliers) {
        const s = Stats.scale(form, level);
        const out = {};
        for (const k of KEYS) {
          const m = multipliers && multipliers[k] ? multipliers[k] : 1;
          out[k] = block[k] * s * m;
        }
        return out;
      },
      effective(speciesId, form, level, multipliers) { return Stats.effectiveFrom(Species.ById[speciesId].stats, form, level, multipliers); },
      maxHp: (vid) => Math.max(1, round(vid * Progression.HpPerVid)),
      formBase(speciesId, form) {
        const sp = Species.ById[speciesId];
        const f = Stats.formFactor(form);
        const out = {};
        for (const k of KEYS) out[k] = round(sp.stats[k] * f);
        return out;
      },
    };

    // ---------------- ElementChart ----------------
    const ElementChart = {
      single(attack, defend) {
        const a = Elements.ById[attack];
        if (!a) return Combat.Element.Neutral;
        if (a.strongAgainst.includes(defend)) return Combat.Element.Strong;
        if (a.weakAgainst.includes(defend)) return Combat.Element.Weak;
        return Combat.Element.Neutral;
      },
      multiplier(attack, defenderElements, isNexo) {
        if (attack == null || defenderElements.length === 0) return Combat.Element.Neutral;
        let m = 1;
        for (const d of defenderElements) m *= ElementChart.single(attack, d);
        const floor = isNexo ? Math.max(Combat.Element.Floor, Combat.Element.NexoFloor) : Combat.Element.Floor;
        return clamp(m, floor, Combat.Element.Cap);
      },
      classify(m) { return m > 1.0001 ? "Strong" : m < 0.9999 ? "Weak" : "Neutral"; },
    };

    // ---------------- Leveling ----------------
    const Leveling = {
      xpToNext(level) { return level >= Progression.LevelCap ? 0 : round(Progression.XpBase * Math.pow(level, Progression.XpExponent)); },
      addXp(level, xp, amount) {
        let lvl = level, cur = xp + Math.floor(amount), gained = 0;
        while (lvl < Progression.LevelCap) {
          const need = Leveling.xpToNext(lvl);
          if (cur < need) break;
          cur -= need; lvl += 1; gained += 1;
        }
        if (lvl >= Progression.LevelCap) cur = 0;
        return { level: lvl, xp: cur, levelsGained: gained };
      },
      bondHearts(bond) { let h = 0; for (const t of Progression.Bond.Thresholds) if (bond >= t) h++; return h; },
      nextBondThreshold(bond) { for (const t of Progression.Bond.Thresholds) if (bond < t) return t; return null; },
      talladoLevel(speciesId) { return Rarities.ById[Species.ById[speciesId].rarity].talladoLevel; },
      canEvolve(pet) {
        if (pet.form !== "Brote") return [false, "AlreadyTallado"];
        if (pet.level < Leveling.talladoLevel(pet.speciesId)) return [false, "LevelTooLow"];
        if (Leveling.bondHearts(pet.bond) < Progression.Bond.TallarRequiredHearts) return [false, "BondTooLow"];
        return [true, null];
      },
      nextObjective(pet) {
        const sp = Species.ById[pet.speciesId];
        if (pet.form === "Brote") {
          const need = Leveling.talladoLevel(pet.speciesId);
          if (pet.level < need) return { kind: "ReachTalladoLevel", text: `Nivel ${need} para tallarse en ${sp.talladoName}`, current: pet.level, target: need };
          const hearts = Leveling.bondHearts(pet.bond);
          if (hearts < Progression.Bond.TallarRequiredHearts) return { kind: "BondForTallado", text: `${Progression.Bond.TallarRequiredHearts} corazones de Vínculo para tallarse`, current: hearts, target: Progression.Bond.TallarRequiredHearts };
          return { kind: "ReadyToEvolve", text: "¡Listo para tallarse!", current: 1, target: 1 };
        }
        if (pet.level < Progression.NexoUnlockLevel) return { kind: "ReachNexoLevel", text: `Nivel ${Progression.NexoUnlockLevel}: Golpe Nexo`, current: pet.level, target: Progression.NexoUnlockLevel };
        return { kind: "Mastery", text: "Entrena hasta el nivel 50", current: pet.level, target: Progression.LevelCap };
      },
    };

    // ---------------- BattleEngine ----------------
    const NEGATIVE = ["Burn", "Paralysis", "Stun", "Sleep", "Confuse"];
    const INCAP = { Sleep: true, Stun: true, Paralysis: true };
    const INCAP_ORDER = ["Sleep", "Stun", "Paralysis"];
    const talentOf = (c) => (c.talent ? Talents.ById[c.talent] : null);

    const BE = {};
    BE.defaultLoadout = function (speciesId, form, level) {
      const sp = Species.ById[speciesId];
      const moves = [];
      const primary = sp.elements[0];
      if (primary) {
        const rep = Abilities.ByElement[primary];
        for (let i = 0; i < Combat.Loadout.Basics; i++) if (rep.basics[i]) moves.push(rep.basics[i]);
        for (let i = 0; i < Combat.Loadout.Specials; i++) if (rep.specials[i]) moves.push(rep.specials[i]);
      }
      if (sp.signature) moves.push(sp.signature);
      if (primary && form === "Tallado" && level >= Progression.NexoUnlockLevel) moves.push(Abilities.ByElement[primary].nexo);
      return moves;
    };
    BE.createCombatant = function (spec, side, slot) {
      let multipliers = null;
      if (spec.modifier) { const mod = Encounters.Modifiers[spec.modifier]; multipliers = mod ? mod.statMultipliers : null; }
      const g = spec.guardianId ? Guardians.ById[spec.guardianId] : null;
      if (g) {
        const base = Stats.effectiveFrom(g.stats, spec.form, spec.level, multipliers);
        const maxHp = round(Stats.maxHp(base.VID) * g.hpMultiplier);
        return {
          uid: `S${side}C${slot}`, side, slot, petId: null, speciesId: spec.speciesId, form: spec.form,
          level: spec.level, name: spec.isOpaco ? g.shortName + " opacada" : g.shortName, rarity: g.rarity, isOpaco: !!spec.isOpaco,
          elements: g.elements.slice(), base, scale: Stats.scale(spec.form, spec.level), maxHp, hp: maxHp, savia: Combat.Savia.Start,
          nexoUsed: 0, moves: spec.loadout || g.moves.slice(), talent: null, statuses: {}, mods: [], shield: null, block: 0, dodge: 0,
          reflect: null, hot: null, empowerNext: 0, nextSpecialFails: false, damagedThisTurn: false, wasHitLastTurn: false,
          actedThisTurn: false, fainted: false, guardianId: g.id, rootHeal: spec.rootHeal ?? g.rootHeal, phases: g.phases, phaseIndex: 1,
        };
      }
      const sp = Species.ById[spec.speciesId];
      const base = Stats.effective(spec.speciesId, spec.form, spec.level, multipliers);
      const maxHp = Stats.maxHp(base.VID);
      let name = spec.nickname || (spec.form === "Tallado" ? sp.talladoName : sp.broteName);
      if (spec.isOpaco) name = "Opaco de " + name;
      return {
        uid: `S${side}C${slot}`, side, slot, petId: spec.petId, speciesId: spec.speciesId, form: spec.form,
        level: spec.level, name, rarity: sp.rarity, isOpaco: !!spec.isOpaco, elements: sp.elements.slice(),
        base, scale: Stats.scale(spec.form, spec.level), maxHp, hp: maxHp, savia: Combat.Savia.Start, nexoUsed: 0,
        moves: spec.loadout || BE.defaultLoadout(spec.speciesId, spec.form, spec.level), talent: sp.talent || null,
        statuses: {}, mods: [], shield: null, block: 0, dodge: 0, reflect: null, hot: null, empowerNext: 0,
        nextSpecialFails: false, damagedThisTurn: false, wasHitLastTurn: false, actedThisTurn: false, fainted: false,
        guardianId: null, rootHeal: spec.rootHeal ?? null, phases: null, phaseIndex: 1,
      };
    };
    BE.new = function (setup) {
      const sides = setup.sides.map((s, i) => ({
        index: i + 1, controller: s.controller, ai: s.ai, active: 0,
        team: s.team.map((spec, slot) => BE.createCombatant(spec, i + 1, slot + 1)),
      }));
      const state = { battleId: setup.battleId, seed: setup.seed, rng: new Rng(setup.seed), turn: 0,
        maxTurns: setup.maxTurns || Combat.MaxTurns, phase: "Choosing", sides, pending: {}, outcome: null, log: [],
        field: { accuracy: [0, 0] }, tally: { faints: [0, 0], elements: [{}, {}], rootsCut: 0, nexoUsed: [0, 0] } };
      for (const side of sides) {
        const c = side.team[side.active];
        const t = talentOf(c);
        if (t && t.kind === "BattleStartSavia") {
          c.savia = Math.min(Combat.Savia.Max, c.savia + (t.amount ?? 1));
          state.log.push({ t: "Talent", target: c.uid, talent: t.id, savia: c.savia });
        }
      }
      return state;
    };
    BE.active = (state, side) => { const s = state.sides[side - 1]; return s.team[s.active]; };
    const opponentOf = (state, side) => BE.active(state, side === 1 ? 2 : 1);
    BE.moveCost = (m) => (m.kind === "Basic" ? 0 : m.kind === "Nexo" ? Combat.Savia.NexoCost : Combat.Savia.SpecialCost);
    BE.availableMoves = function (state, side) {
      const c = BE.active(state, side);
      const out = [];
      for (const id of c.moves) {
        const m = Abilities.ById[id];
        if (!m) continue;
        const cost = BE.moveCost(m);
        let usable = true, reason = null;
        if (c.savia < cost) { usable = false; reason = "NotEnoughSavia"; }
        else if (m.kind === "Nexo" && c.nexoUsed >= Combat.Savia.NexoUsesPerBattle) { usable = false; reason = "NexoUsed"; }
        out.push({ moveId: id, usable, reason, cost, kind: m.kind });
      }
      return out;
    };
    BE.submit = function (state, side, action) {
      if (state.phase !== "Choosing") return [false, "BattleEnded"];
      if (state.pending[side]) return [false, "AlreadySubmitted"];
      if (action.kind === "Move") {
        const opt = BE.availableMoves(state, side).find((o) => o.moveId === action.moveId);
        if (!opt) return [false, "MoveNotEquipped"];
        if (!opt.usable) return [false, opt.reason];
      }
      state.pending[side] = action;
      return [true, null];
    };
    const modSum = (c, stat) => { let t = 0; for (const m of c.mods) if (m.stat === stat) t += m.amount; return t; };
    BE.stat = (c, stat) => c.base[stat] * Math.max(0.3, 1 + modSum(c, stat));
    const durationFor = (target, turns) => (target.actedThisTurn ? turns + 1 : turns);
    const emit = (state, events, e) => { events.push(e); state.log.push(e); };
    const hasStatus = (c, list) => list.some((s) => (c.statuses[s] || 0) > 0);

    function applyStatus(state, events, target, status, turns) {
      if (target.fainted) return;
      if (status === "Sleep" && target.rarity === "Misterio") { emit(state, events, { t: "Immune", target: target.uid, status }); return; }
      const d = INCAP[status] || status === "Confuse" ? turns : durationFor(target, turns);
      target.statuses[status] = Math.max(target.statuses[status] || 0, d);
      emit(state, events, { t: "Status", target: target.uid, status, turns: target.statuses[status] });
    }
    function applyMod(state, events, target, stat, amount, turns) {
      if (target.fainted) return;
      target.mods.push({ stat, amount, turns: durationFor(target, turns) });
      emit(state, events, { t: "Mod", target: target.uid, stat, amount, turns });
    }
    function heal(state, events, target, percent) {
      if (target.fainted) return;
      const t = talentOf(target);
      const bonus = t && t.kind === "HealingBonus" ? t.percent || 0 : 0;
      const amount = round(target.maxHp * percent * (1 + bonus));
      const before = target.hp;
      target.hp = Math.min(target.maxHp, target.hp + amount);
      emit(state, events, { t: "Heal", target: target.uid, amount: target.hp - before, hp: target.hp });
    }
    function cleanse(state, events, target, onlyOne) {
      const removed = [];
      for (const s of NEGATIVE) {
        if ((target.statuses[s] || 0) > 0) { delete target.statuses[s]; removed.push(s); if (onlyOne) break; }
      }
      if (!onlyOne) target.mods = target.mods.filter((m) => m.amount > 0);
      emit(state, events, { t: "Cleanse", target: target.uid, removed });
    }
    function faintIfNeeded(state, events, c) {
      if (!c.fainted && c.hp <= 0) { c.hp = 0; c.fainted = true; state.tally.faints[c.side - 1] += 1; emit(state, events, { t: "Faint", target: c.uid }); }
    }
    function checkPhase(state, events, c) {
      const phases = c.phases;
      if (!phases || c.fainted) return;
      const next = phases[c.phaseIndex - 1];
      if (!next || c.hp / c.maxHp > next.threshold) return;
      c.phaseIndex += 1;
      emit(state, events, { t: "Phase", target: c.uid, phase: c.phaseIndex, id: next.id, text: next.text });
      for (const e of next.effects) {
        if (e.type === "EndRoots") { if (c.rootHeal != null) { c.rootHeal = null; emit(state, events, { t: "RootsEnd", target: c.uid }); } }
        else if (e.type === "SideAccuracy") { const foe = c.side === 1 ? 2 : 1; state.field.accuracy[foe - 1] += e.amount; emit(state, events, { t: "Field", side: foe, accuracy: state.field.accuracy[foe - 1] }); }
        else if (e.type === "GainSavia") { c.savia = Math.min(Combat.Savia.Max, c.savia + e.amount); emit(state, events, { t: "Savia", target: c.uid, savia: c.savia, delta: e.amount }); }
      }
    }
    function dealDamage(state, events, target, amount, ignoreShields, info) {
      if (target.block > 0) { target.block = 0; emit(state, events, { t: "Block", target: target.uid }); return [0, true]; }
      let remaining = amount;
      if (target.shield && !ignoreShields) {
        const absorbed = Math.min(target.shield.amount, remaining);
        target.shield.amount -= absorbed; remaining -= absorbed;
        if (absorbed > 0) emit(state, events, { t: "ShieldAbsorb", target: target.uid, amount: absorbed });
        if (target.shield.amount <= 0) target.shield = null;
      }
      target.hp -= remaining;
      target.damagedThisTurn = true;
      emit(state, events, Object.assign({ t: "Damage", target: target.uid, amount: remaining, hp: Math.max(0, target.hp), maxHp: target.maxHp }, info));
      faintIfNeeded(state, events, target);
      checkPhase(state, events, target);
      return [remaining, false];
    }
    BE.computeDamage = function (state, attacker, target, move, power) {
      const isBasic = move.kind === "Basic";
      const atkStat = move.useStat || (isBasic ? "ATQ" : "ESE");
      const A = BE.stat(attacker, atkStat);
      let D = isBasic ? BE.stat(target, "DEF") : (BE.stat(target, "DEF") + BE.stat(target, "ESE")) / 2;
      const tt = talentOf(target);
      if (tt && tt.kind === "DefenseVsElements" && move.element) {
        for (const e of tt.elements || []) if (e === move.element) D *= 1 + (tt.percent || 0);
      }
      let dmg = power * (A / (A + D)) * Combat.DamageRatioMultiplier;
      if (Combat.ScaleDamageByAttackerLevel) dmg *= attacker.scale;
      const elem = ElementChart.multiplier(move.element, target.elements, move.kind === "Nexo");
      dmg *= elem;
      if (move.element && attacker.elements.includes(move.element)) dmg *= Combat.Element.Affinity;
      dmg *= state.rng.range(Combat.VarianceMin, Combat.VarianceMax);
      const crit = state.rng.chance(Combat.CritChance + (move.critBonus || 0));
      if (crit) dmg *= Combat.CritMultiplier;
      for (const eff of move.effects) {
        const applies = (eff.type === "BonusIfTargetStatus" && eff.statuses && hasStatus(target, eff.statuses)) ||
          (eff.type === "BonusIfHitLastTurn" && attacker.wasHitLastTurn);
        if (applies) dmg *= 1 + (eff.amount || 0);
      }
      if (attacker.empowerNext > 0) dmg *= 1 + attacker.empowerNext;
      if (isBasic && tt && tt.kind === "ReduceBasicDamageTaken") dmg *= 1 - (tt.percent || 0);
      return { amount: Math.max(1, round(dmg)), effectiveness: ElementChart.classify(elem), crit, multiplier: elem };
    };
    function accuracyFor(state, attacker, target) {
      const acc = Combat.BaseAccuracy * (1 + modSum(attacker, "Precision") + state.field.accuracy[attacker.side - 1]);
      const evasion = clamp(modSum(target, "Evasion"), 0, Combat.MaxEvasion);
      return clamp(acc - evasion, Combat.MinAccuracy, 1);
    }
    function executeMove(state, events, actor, target, move) {
      const cost = BE.moveCost(move);
      if (move.kind === "Basic") actor.savia = Math.min(Combat.Savia.Max, actor.savia + Combat.Savia.BasicGain);
      else { actor.savia -= cost; if (move.kind === "Nexo") { actor.nexoUsed += 1; state.tally.nexoUsed[actor.side - 1] += 1; } }
      state.tally.elements[actor.side - 1][move.element] = true;
      emit(state, events, { t: "Move", actor: actor.uid, move: move.id, savia: actor.savia });
      if ((move.kind === "Special" || move.kind === "Signature") && actor.nextSpecialFails) {
        actor.nextSpecialFails = false; emit(state, events, { t: "Fail", actor: actor.uid, reason: "Sabotage" }); return;
      }
      const ignoreShields = move.effects.some((e) => e.type === "IgnoreShields");
      let totalDamage = 0, landed = true, contactHit = false, strongHit = false;
      const thorns = target.shield && target.shield.thornsStatus ? { status: target.shield.thornsStatus, chance: target.shield.thornsChance ?? 1 } : null;
      if (move.power > 0) {
        const acc = accuracyFor(state, actor, target);
        if (acc < 1 && !state.rng.chance(acc)) { emit(state, events, { t: "Miss", actor: actor.uid, target: target.uid }); landed = false; }
        else if (target.dodge > 0) { target.dodge = 0; emit(state, events, { t: "Dodge", target: target.uid }); landed = false; }
        else {
          const hits = move.hits || 1;
          for (let h = 0; h < hits; h++) {
            if (target.fainted) break;
            const roll = BE.computeDamage(state, actor, target, move, move.power);
            const [dealt, blocked] = dealDamage(state, events, target, roll.amount, ignoreShields, { source: actor.uid, move: move.id, eff: roll.effectiveness, crit: roll.crit });
            totalDamage += dealt;
            if (!blocked) contactHit = true;
            if (dealt > 0 && roll.effectiveness === "Strong") strongHit = true;
            if (target.reflect && dealt > 0) {
              const f = target.reflect.filter;
              if (f === "All" || (f === "Special" && move.kind !== "Basic")) {
                const back = Math.max(1, round(dealt * target.reflect.percent));
                actor.hp -= back;
                emit(state, events, { t: "Reflect", target: actor.uid, amount: back, hp: Math.max(0, actor.hp) });
                faintIfNeeded(state, events, actor);
              }
            }
          }
          actor.empowerNext = 0;
        }
      }
      if (!landed) return;
      if (strongHit && target.rootHeal != null && !target.fainted) {
        target.rootHeal = null; state.tally.rootsCut += 1; emit(state, events, { t: "RootsCut", target: target.uid });
      }
      for (const eff of move.effects) {
        const kind = eff.type;
        const to = eff.target === "Target" ? target : actor;
        if (Abilities.IgnoredIn1v1[kind]) continue;
        if (kind === "Status") {
          let chance = eff.chance ?? 1;
          if (move.kind === "Basic" && eff.status === "Paralysis") { const t = talentOf(actor); if (t && t.kind === "BasicStatusChanceBonus") chance += t.chance || 0; }
          if (!to.fainted && state.rng.chance(chance)) applyStatus(state, events, to, eff.status, eff.turns ?? 1);
        } else if (kind === "StatMod") {
          if (!to.fainted && state.rng.chance(eff.chance ?? 1)) applyMod(state, events, to, eff.stat, eff.amount || 0, eff.turns ?? 1);
        } else if (kind === "Heal") {
          if (eff.target === "Team") { for (const ally of state.sides[actor.side - 1].team) heal(state, events, ally, eff.percent || 0); }
          else heal(state, events, actor, eff.percent || 0);
        }
        else if (kind === "HealOverTime") { actor.hot = { percent: eff.percent || 0, turns: durationFor(actor, eff.turns ?? 1) }; emit(state, events, { t: "Regen", target: actor.uid, turns: eff.turns }); }
        else if (kind === "Shield") {
          const amount = round(actor.maxHp * (eff.percent || 0));
          actor.shield = { amount, turns: durationFor(actor, eff.turns ?? 1), thornsStatus: eff.thornsStatus, thornsChance: eff.thornsChance };
          emit(state, events, { t: "Shield", target: actor.uid, amount });
        } else if (kind === "ShieldFromDamage") {
          if (totalDamage > 0) { const amount = round(totalDamage * (eff.percent || 0)); actor.shield = { amount, turns: durationFor(actor, eff.turns ?? 2) }; emit(state, events, { t: "Shield", target: actor.uid, amount }); }
        } else if (kind === "Block") { actor.block = durationFor(actor, 1); emit(state, events, { t: "Guard", target: actor.uid, kind: "Block" }); }
        else if (kind === "Dodge") { actor.dodge = durationFor(actor, 1); emit(state, events, { t: "Guard", target: actor.uid, kind: "Dodge" }); }
        else if (kind === "Reflect") { actor.reflect = { percent: eff.percent || 0, turns: durationFor(actor, eff.turns ?? 1), filter: eff.filter || "All" }; emit(state, events, { t: "Guard", target: actor.uid, kind: "Reflect" }); }
        else if (kind === "Drain") {
          if (totalDamage > 0 && !actor.fainted) { const amount = Math.max(1, round(totalDamage * (eff.percent || 0))); actor.hp = Math.min(actor.maxHp, actor.hp + amount); emit(state, events, { t: "Heal", target: actor.uid, amount, hp: actor.hp }); }
        } else if (kind === "StealSavia") {
          if (!target.fainted && target.savia > 0 && state.rng.chance(eff.chance ?? 1)) { const n = Math.min(target.savia, eff.amount || 1); target.savia -= n; emit(state, events, { t: "Savia", target: target.uid, savia: target.savia, delta: -n }); }
        } else if (kind === "Cleanse") cleanse(state, events, actor, false);
        else if (kind === "CleanseOne") cleanse(state, events, actor, true);
        else if (kind === "SelfRecoil") { const amount = round(actor.maxHp * (eff.percent || 0)); actor.hp = Math.max(1, actor.hp - amount); emit(state, events, { t: "Recoil", target: actor.uid, amount, hp: actor.hp }); }
        else if (kind === "NullifyBuffs") { target.mods = target.mods.filter((m) => m.amount < 0); emit(state, events, { t: "Nullify", target: target.uid }); }
        else if (kind === "EmpowerNext") { actor.empowerNext = eff.amount || 0; emit(state, events, { t: "Empower", target: actor.uid, amount: actor.empowerNext }); }
        else if (kind === "NextSpecialFails") { if (state.rng.chance(eff.chance ?? 1)) { target.nextSpecialFails = true; emit(state, events, { t: "Sabotage", target: target.uid }); } }
        else if (kind === "CopyBuff") { for (let i = target.mods.length - 1; i >= 0; i--) { const m = target.mods[i]; if (m.amount > 0) { applyMod(state, events, actor, m.stat, m.amount, 2); break; } } }
      }
      if (contactHit) {
        if (thorns && !actor.fainted) { if (state.rng.chance(thorns.chance)) applyStatus(state, events, actor, thorns.status, Combat.Status.Burn.defaultTurns); }
        const tt = talentOf(target);
        if (move.contact && tt && tt.kind === "ContactBurnChance" && !actor.fainted) { if (state.rng.chance(tt.chance || 0)) applyStatus(state, events, actor, "Burn", Combat.Status.Burn.defaultTurns); }
      }
      if (move.kind === "Basic" && totalDamage > 0 && !target.fainted) {
        const t = talentOf(actor);
        if (t && t.kind === "BasicStatusChanceBonus") {
          const hasOwn = move.effects.some((e) => e.type === "Status" && e.status === t.status);
          if (!hasOwn && state.rng.chance(t.chance || 0)) applyStatus(state, events, target, t.status, 1);
        }
      }
    }
    const priorityOf = (a) => { if (a && a.kind === "Move") { const m = Abilities.ById[a.moveId]; return m && m.priority ? m.priority : 0; } return 0; };
    const tieBreaker = (a) => { if (a && a.kind === "Move") { const m = Abilities.ById[a.moveId]; return !!m && m.effects.some((e) => e.type === "TieBreakFirst"); } return false; };
    function finish(state, events, winner, reason) {
      state.phase = "Ended"; state.outcome = { winner, reason };
      if (winner) { const loser = state.sides[winner === 1 ? 1 : 0]; for (const c of loser.team) if (c.isOpaco) emit(state, events, { t: "Restored", target: c.uid }); }
      emit(state, events, { t: "End", winner, reason, turn: state.turn });
    }
    const sideDefeated = (side) => side.team.every((c) => c.fainted);
    function bringInNext(state, events) {
      for (const side of state.sides) {
        const current = side.team[side.active];
        if (!current.fainted) continue;
        const i = side.team.findIndex((c) => !c.fainted);
        if (i < 0) continue;
        const c = side.team[i];
        side.active = i; c.damagedThisTurn = false; c.actedThisTurn = false;
        emit(state, events, { t: "Switch", side: side.index, from: current.uid, to: c.uid });
        const t = talentOf(c);
        if (t && t.kind === "BattleStartSavia") { c.savia = Math.min(Combat.Savia.Max, c.savia + (t.amount ?? 1)); emit(state, events, { t: "Talent", target: c.uid, talent: t.id, savia: c.savia }); }
      }
    }
    const teamHpRatio = (side) => { let hp = 0, max = 0; for (const c of side.team) { hp += Math.max(0, c.hp); max += c.maxHp; } return max > 0 ? hp / max : 0; };
    function endOfTurn(state, events) {
      for (const side of state.sides) {
        const c = side.team[side.active];
        if (!c.fainted) {
          if ((c.statuses.Burn || 0) > 0) {
            const amount = Math.max(1, round(c.maxHp * Combat.Status.Burn.damagePercent));
            c.hp -= amount;
            emit(state, events, { t: "StatusTick", target: c.uid, status: "Burn", amount, hp: Math.max(0, c.hp) });
            faintIfNeeded(state, events, c);
          }
          if (!c.fainted && c.hot) heal(state, events, c, c.hot.percent);
          if (!c.fainted && c.rootHeal != null && c.hp < c.maxHp) { emit(state, events, { t: "Roots", target: c.uid }); heal(state, events, c, c.rootHeal); }
          const t = talentOf(c);
          if (!c.fainted && t && t.kind === "EndTurnHealIfUndamaged" && !c.damagedThisTurn && c.hp < c.maxHp) heal(state, events, c, t.percent || 0);
        }
        if ((c.statuses.Burn || 0) > 0) { c.statuses.Burn -= 1; if (c.statuses.Burn <= 0) delete c.statuses.Burn; }
        c.mods = c.mods.filter((m) => { m.turns -= 1; return m.turns > 0; });
        if (c.shield) { c.shield.turns -= 1; if (c.shield.turns <= 0) c.shield = null; }
        if (c.reflect) { c.reflect.turns -= 1; if (c.reflect.turns <= 0) c.reflect = null; }
        if (c.hot) { c.hot.turns -= 1; if (c.hot.turns <= 0) c.hot = null; }
        if (c.block > 0) c.block -= 1;
        if (c.dodge > 0) c.dodge -= 1;
        c.wasHitLastTurn = c.damagedThisTurn;
      }
    }
    BE.resolveTurn = function (state) {
      if (state.phase !== "Choosing") throw new Error("El combate ya terminó");
      if (!state.pending[1] || !state.pending[2]) throw new Error("Faltan acciones por elegir");
      const events = [];
      state.turn += 1;
      emit(state, events, { t: "Turn", n: state.turn });
      for (const i of [1, 2]) {
        const a = state.pending[i];
        if (a && a.kind === "Forfeit") { state.pending = {}; finish(state, events, i === 1 ? 2 : 1, "Forfeit"); return events; }
      }
      const actors = [1, 2].map((i) => { const c = BE.active(state, i); c.damagedThisTurn = false; c.actedThisTurn = false; return { side: i, c, action: state.pending[i] }; });
      const [a, b] = actors;
      const pa = priorityOf(a.action), pb = priorityOf(b.action);
      let first;
      if (pa !== pb) first = pa > pb ? 1 : 2;
      else {
        const va = BE.stat(a.c, "VEL"), vb = BE.stat(b.c, "VEL");
        if (Math.abs(va - vb) > 1e-9) first = va > vb ? 1 : 2;
        else {
          const ta = tieBreaker(a.action), tb = tieBreaker(b.action);
          if (ta !== tb) first = ta ? 1 : 2;
          else first = state.rng.chance(0.5) ? 1 : 2;
        }
      }
      const order = first === 1 ? [a, b] : [b, a];
      for (const entry of order) {
        const actor = entry.c;
        if (actor.fainted || state.phase === "Ended") continue;
        const target = opponentOf(state, entry.side);
        actor.actedThisTurn = true;
        let skipped = false;
        for (const status of INCAP_ORDER) {
          if ((actor.statuses[status] || 0) > 0) {
            actor.statuses[status] -= 1;
            if (actor.statuses[status] <= 0) delete actor.statuses[status];
            emit(state, events, { t: "Skip", actor: actor.uid, status });
            skipped = true; break;
          }
        }
        if (!skipped && (actor.statuses.Confuse || 0) > 0) {
          actor.statuses.Confuse -= 1;
          if (actor.statuses.Confuse <= 0) delete actor.statuses.Confuse;
          if (state.rng.chance(Combat.Status.Confuse.selfHitChance)) {
            const selfMove = { id: "ConfusionSelfHit", kind: "Basic", power: Combat.Status.Confuse.selfHitPower, effects: [] };
            const roll = BE.computeDamage(state, actor, actor, selfMove, selfMove.power);
            emit(state, events, { t: "Confused", actor: actor.uid });
            dealDamage(state, events, actor, roll.amount, true, { source: actor.uid, move: "ConfusionSelfHit", eff: "Neutral", crit: false });
            skipped = true;
          }
        }
        if (!skipped) executeMove(state, events, actor, target, Abilities.ById[entry.action.moveId]);
        for (const i of [1, 2]) {
          if (sideDefeated(state.sides[i - 1])) { finish(state, events, i === 1 ? 2 : 1, "Defeat"); break; }
        }
        if (state.phase !== "Ended") bringInNext(state, events);
      }
      if (state.phase !== "Ended") {
        endOfTurn(state, events);
        for (const i of [1, 2]) if (state.phase !== "Ended" && sideDefeated(state.sides[i - 1])) finish(state, events, i === 1 ? 2 : 1, "Defeat");
        if (state.phase !== "Ended") bringInNext(state, events);
      }
      if (state.phase !== "Ended" && state.turn >= state.maxTurns) {
        finish(state, events, teamHpRatio(state.sides[0]) > teamHpRatio(state.sides[1]) ? 1 : 2, "TurnLimit");
      }
      state.pending = {};
      return events;
    };

    // ---------------- BattleAI ----------------
    const AI = {};
    function expectedDamage(state, side, moveId) {
      const me = BE.active(state, side), foe = BE.active(state, side === 1 ? 2 : 1);
      const m = Abilities.ById[moveId];
      if (!m || m.power <= 0) return 0;
      const isBasic = m.kind === "Basic";
      const A = BE.stat(me, m.useStat || (isBasic ? "ATQ" : "ESE"));
      const D = isBasic ? BE.stat(foe, "DEF") : (BE.stat(foe, "DEF") + BE.stat(foe, "ESE")) / 2;
      const elem = ElementChart.multiplier(m.element, foe.elements, m.kind === "Nexo");
      const aff = m.element && me.elements.includes(m.element) ? Combat.Element.Affinity : 1;
      return m.power * (m.hits || 1) * A / (A + D) * elem * aff;
    }
    const isHeal = (id) => Abilities.ById[id].effects.some((e) => e.type === "Heal" || e.type === "HealOverTime");
    function pickBest(state, side, ids) { let best = null, bestScore = -1; for (const id of ids) { const s = expectedDamage(state, side, id); if (s > bestScore) { best = id; bestScore = s; } } return best; }
    AI.expectedDamage = expectedDamage;
    AI.choose = function (state, side, profile) {
      const basics = [], specials = []; let nexo = null;
      for (const opt of BE.availableMoves(state, side)) {
        if (!opt.usable) continue;
        if (opt.kind === "Basic") basics.push(opt.moveId); else if (opt.kind === "Nexo") nexo = opt.moveId; else specials.push(opt.moveId);
      }
      const rng = state.rng;
      if (profile === "Tutorial") {
        if (rng.chance(0.7)) return pickBest(state, side, basics);
        return basics[rng.int(1, basics.length) - 1];
      }
      if (nexo) return nexo;
      const me = BE.active(state, side);
      if (specials.length > 0) {
        if (me.hp / me.maxHp < 0.4) { for (const id of specials) if (isHeal(id)) return id; }
        if (rng.chance(0.6)) {
          const damaging = specials.filter((id) => Abilities.ById[id].power > 0);
          if (damaging.length > 0) return pickBest(state, side, damaging);
          return specials[rng.int(1, specials.length) - 1];
        }
      }
      if (rng.chance(0.25)) return basics[rng.int(1, basics.length) - 1];
      return pickBest(state, side, basics);
    };

    return { Rng, Stats, ElementChart, Leveling, BattleEngine: BE, BattleAI: AI };
  }

  const api = { createEngine };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root.NexoraEngine = api;
})(typeof globalThis !== "undefined" ? globalThis : this);

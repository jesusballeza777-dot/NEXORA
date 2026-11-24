/*
 * NEXORA · Reglas del perfil para la vista previa web (Fase 1 + Fase 2).
 * Port 1:1 de src/ServerScriptService/Server/Domain (ProfileSchema, PetRules,
 * SanctuaryRules, OnboardingRules, ShopRules, RewardRules, CollectionRules, EggRules,
 * ChestRules, QuestRules, DecorRules, HistoryRules, EncounterRules y Actions).
 * Mismas cifras (config exportada desde Luau), mismo orden de operaciones y mismas
 * tiradas (Rng). tools/web-preview/profile-parity.mjs comprueba que, con los mismos
 * pasos, el perfil resultante es idéntico al del código Luau.
 *
 * Convenciones del port: las listas de Luau (1-based) son arreglos de JS; las funciones
 * públicas reciben ranuras e índices 1-based como en Luau. nil = clave ausente.
 * La fuente de verdad es el código Luau; este archivo solo existe para la vista previa.
 */
(function (root) {
  "use strict";

  function createDomain(CFG, ENG) {
    const { Rng, Leveling, ElementChart } = ENG;
    const Economy = CFG.Economy, Sanctuary = CFG.Sanctuary, SpeciesCfg = CFG.Species, Rarities = CFG.Rarities;
    const Progression = CFG.Progression, Onboarding = CFG.Onboarding, Encounters = CFG.Encounters;
    const RewardsCfg = CFG.Rewards, Chests = CFG.Chests, Incubation = CFG.Incubation, Quests = CFG.Quests;
    const Decor = CFG.Decor, Achievements = CFG.Achievements;

    const Result = { ok: (data) => ({ ok: true, data: data || {} }), fail: (err) => ({ ok: false, err }) };
    const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
    const copy = (v) => (v === undefined ? undefined : JSON.parse(JSON.stringify(v)));
    const clone = (t) => (Array.isArray(t) ? t.slice() : Object.assign({}, t));
    const isTable = (v) => v !== null && typeof v === "object";
    const nil = (v) => v === undefined || v === null;
    const values = (o) => Object.values(o || {});
    const setOrDelete = (obj, key, v) => { if (nil(v)) delete obj[key]; else obj[key] = v; };

    // =================================================================
    // HistoryRules
    // =================================================================
    const HistoryRules = { LIMIT: 100 };
    HistoryRules.add = function (p, entry) {
      const e = {};
      for (const [k, v] of Object.entries(entry)) if (!nil(v)) e[k] = v;
      p.history.push(e);
      while (p.history.length > HistoryRules.LIMIT) p.history.shift();
    };

    // =================================================================
    // ProfileSchema
    // =================================================================
    const ProfileSchema = { CURRENT_VERSION: 3 };
    function newIncubators() { const s = []; for (let i = 1; i <= Incubation.MaxSlots; i++) s.push({ unlocked: i === 1 }); return s; }
    function newDecorSlots() { const s = []; for (let i = 1; i <= Decor.FreeSlots; i++) s.push(false); return s; }
    function newHabitat(id, now) {
      const slots = []; for (let i = 1; i <= Sanctuary.SlotsPerHabitat; i++) slots.push(false);
      return { id, slots, level: 1, lastCollectAt: now, accrued: 0, bonusCoins: 0 };
    }
    ProfileSchema.new = function (userId, now) {
      const lots = {};
      for (const [lotId, lot] of Object.entries(Sanctuary.Lots)) {
        if (lot.implemented) {
          const habitats = {};
          for (const hid of lot.habitats) habitats[hid] = newHabitat(hid, now);
          lots[lotId] = { unlocked: false, habitats };
        }
      }
      return {
        schemaVersion: ProfileSchema.CURRENT_VERSION, userId, createdAt: now, lastLoginAt: now, loginCount: 0, playSeconds: 0,
        currencies: { Monedas: Economy.StartingBalance.Monedas, Gemas: Economy.StartingBalance.Gemas },
        items: {}, pets: {}, nextPetSerial: 1, team: [], inventoryCapacity: Sanctuary.InventoryCapacity, lots,
        story: { cleared: {}, repeatDay: 0, repeatCount: 0, stars: {}, bestTurns: {}, regionRewards: {}, actRewards: {}, treasureAttempts: {} },
        onboarding: { step: "Intro", completed: false, startedAt: now },
        unlocks: {}, rewards: { pending: {}, ledger: {}, ledgerOrder: [] }, firsts: {}, counters: {},
        collection: {}, eggs: {}, nextEggSerial: 1, incubators: newIncubators(), chests: {}, nextChestSerial: 1, history: [],
        quests: { day: -1, daily: [], dailyBonusClaimed: false, week: -1 },
        codex: {}, decor: { slots: newDecorSlots(), owned: {} }, showcase: [],
        titles: { owned: {} }, frames: { owned: {} }, guardians: {},
        achievements: {},
      };
    };
    function phase1Opponent(data, encounterId) {
      const enc = Encounters.ById[encounterId];
      if (!enc) return undefined;
      const opp = (enc.opponents && enc.opponents[0]) || enc.opponent;
      if (!opp) return undefined;
      if (opp.speciesId) return opp.speciesId;
      if (opp.byStarterElement) {
        for (const pet of values(data.pets)) {
          if (pet.acquired && pet.acquired.kind === "Starter") {
            const sp = SpeciesCfg.ById[pet.speciesId];
            return sp ? opp.byStarterElement[sp.elements[0]] : undefined;
          }
        }
      }
      return undefined;
    }
    ProfileSchema.Migrations = {
      // 1 → 2: colección reconstruida con lo que ya tiene; etapas superadas = ★
      1(data) {
        const collection = {};
        const entry = (id) => (collection[id] = collection[id] || {});
        for (const pet of values(data.pets)) {
          const e = entry(pet.speciesId);
          const at = (pet.acquired && pet.acquired.at) || data.createdAt || 0;
          e.broteAt = Math.min(e.broteAt ?? at, at);
          e.count = (e.count ?? 0) + 1;
          if (pet.form === "Tallado") e.talladoAt = pet.evolvedAt ?? at;
        }
        const story = data.story || {};
        story.stars = story.stars || {};
        for (const [encounterId, cleared] of Object.entries(story.cleared || {})) {
          story.stars[encounterId] = story.stars[encounterId] || [true, false, false];
          const opp = phase1Opponent(data, encounterId);
          if (opp) {
            const e = entry(opp);
            if (nil(e.seenAt)) setOrDelete(e, "seenAt", cleared.firstClearAt);
            if (nil(e.restoredAt)) setOrDelete(e, "restoredAt", cleared.firstClearAt);
          }
        }
        data.story = story;
        data.collection = collection;
        return data;
      },
      // 2 → 3: logros (D-033), con el contador de huevos eclosionados reconstruido
      2(data) {
        data.achievements = data.achievements || {};
        const counters = data.counters || {};
        if (nil(counters.eggsHatched)) {
          let hatched = 0;
          for (const pet of Object.values(data.pets || {})) if (pet.acquired && pet.acquired.kind === "Egg") hatched++;
          counters.eggsHatched = hatched;
        }
        data.counters = counters;
        return data;
      },
    };
    function reconcile(target, template) {
      for (const [k, v] of Object.entries(template)) {
        if (nil(target[k])) target[k] = copy(v);
        else if (isTable(v) && isTable(target[k]) && !Array.isArray(v) && Object.keys(v).length > 0) reconcile(target[k], v);
      }
    }
    ProfileSchema.migrate = function (data, now, migrations) {
      const list = migrations || ProfileSchema.Migrations;
      let version = data.schemaVersion || 0;
      if (version > ProfileSchema.CURRENT_VERSION) throw new Error("Perfil de una versión futura: " + version);
      while (version < ProfileSchema.CURRENT_VERSION) {
        const step = list[version];
        if (step) data = step(data);
        version += 1;
        data.schemaVersion = version;
      }
      reconcile(data, ProfileSchema.new(data.userId || 0, now));
      return data;
    };
    ProfileSchema.validate = function (p) {
      for (const [cur, amount] of Object.entries(p.currencies)) if (typeof amount !== "number" || amount < 0 || amount !== amount) return [false, "BadCurrency:" + cur];
      for (const [item, n] of Object.entries(p.items)) if (typeof n !== "number" || n < 0 || Math.floor(n) !== n) return [false, "BadItem:" + item];
      const placed = {};
      for (const lot of values(p.lots)) for (const h of values(lot.habitats)) for (const id of h.slots) {
        if (id) { if (!p.pets[id]) return [false, "SlotWithUnknownPet"]; if (placed[id]) return [false, "PetInTwoSlots"]; placed[id] = true; }
      }
      for (const [id, pet] of Object.entries(p.pets)) {
        if (pet.id !== id) return [false, "PetIdMismatch"];
        if (!SpeciesCfg.ById[pet.speciesId]) return [false, "UnknownSpecies:" + pet.speciesId];
      }
      if (p.companionPetId && !p.pets[p.companionPetId]) return [false, "CompanionNotOwned"];
      const incubating = {};
      for (let i = 0; i < p.incubators.length; i++) {
        const slot = p.incubators[i];
        if (slot.eggId) {
          const egg = p.eggs[slot.eggId];
          if (!egg) return [false, "SlotWithUnknownEgg"];
          if (egg.state !== "Incubating" || egg.slot !== i + 1) return [false, "EggSlotMismatch"];
          if (incubating[slot.eggId]) return [false, "EggInTwoSlots"];
          incubating[slot.eggId] = i + 1;
        }
      }
      for (const [id, egg] of Object.entries(p.eggs)) {
        if (egg.id !== id) return [false, "EggIdMismatch"];
        if (!SpeciesCfg.ById[egg.speciesId]) return [false, "UnknownEggSpecies:" + egg.speciesId];
        if (egg.state === "Incubating" && nil(incubating[id])) return [false, "IncubatingEggWithoutSlot"];
      }
      for (const petId of p.showcase) if (!p.pets[petId]) return [false, "ShowcaseNotOwned"];
      for (const d of p.decor.slots) if (d && (p.decor.owned[d] ?? 0) <= 0) return [false, "DecorNotOwned"];
      return [true, null];
    };

    // =================================================================
    // PetRules
    // =================================================================
    const PetRules = { MaxCompanions: Sanctuary.MaxCompanions };
    function placedCount(p) { let n = 0; for (const lot of values(p.lots)) for (const h of values(lot.habitats)) for (const id of h.slots) if (id) n++; return n; }
    PetRules.petCount = (p) => Object.keys(p.pets).length;
    PetRules.inventoryUsed = (p) => PetRules.petCount(p) - placedCount(p);
    PetRules.create = function (p, speciesId, source) {
      if (!SpeciesCfg.ById[speciesId]) return Result.fail("UnknownSpecies");
      if (PetRules.inventoryUsed(p) >= p.inventoryCapacity) return Result.fail("InventoryFull");
      const id = `U${p.userId}-${p.nextPetSerial}`;
      if (p.pets[id]) return Result.fail("PetIdCollision");
      p.nextPetSerial += 1;
      p.pets[id] = {
        id, speciesId, form: "Brote", level: 1, xp: 0, bond: 0, acquired: source,
        traits: { veta: "Base", temple: "Neutro", goldVein: false }, lineage: { generation: 0 }, lastPlayedAt: 0,
        stats: { battlesWon: 0, battlesLost: 0, timesFed: 0 },
      };
      return Result.ok({ petId: id });
    };
    PetRules.setCompanion = function (p, petId) {
      if (!nil(petId) && !p.pets[petId]) return Result.fail("PetNotOwned");
      setOrDelete(p, "companionPetId", petId);
      p.team = petId ? [petId] : [];
      return Result.ok({ petId });
    };
    PetRules.setNickname = function (p, petId, filtered) {
      const pet = p.pets[petId];
      if (!pet) return Result.fail("PetNotOwned");
      if (nil(filtered) || filtered === "") { delete pet.nickname; return Result.ok({}); }
      if (Array.from(filtered).length > Onboarding.MaxNicknameLength) return Result.fail("BadNickname");
      pet.nickname = filtered;
      return Result.ok({ nickname: filtered });
    };
    PetRules.addXp = function (pet, amount, ctx) {
      const mult = ctx.xpMultiplier ?? 1;
      const gained = Math.floor(amount * mult);
      const r = Leveling.addXp(pet.level, pet.xp, gained);
      pet.level = r.level; pet.xp = r.xp;
      return { xpGained: gained, level: r.level, levelsGained: r.levelsGained };
    };
    PetRules.addBond = function (pet, amount) { const before = pet.bond; pet.bond = Math.min(Progression.Bond.Max, pet.bond + amount); return pet.bond - before; };
    PetRules.feed = function (p, petId, foodId, ctx) {
      const pet = p.pets[petId];
      if (!pet) return Result.fail("PetNotOwned");
      const food = Economy.Foods[foodId];
      if (!food) return Result.fail("UnknownFood");
      if ((p.items[foodId] ?? 0) < 1) return Result.fail("NoFood");
      if (pet.level >= Progression.LevelCap && food.bond === 0) return Result.fail("MaxLevel");
      p.items[foodId] -= 1;
      if (p.items[foodId] === 0) delete p.items[foodId];
      const xp = PetRules.addXp(pet, food.xp, ctx);
      const bondGained = PetRules.addBond(pet, food.bond);
      pet.stats.timesFed += 1;
      return Result.ok({ petId, foodId, xpGained: xp.xpGained, level: xp.level, levelsGained: xp.levelsGained, bondGained, bond: pet.bond });
    };
    PetRules.play = function (p, petId, ctx) {
      const pet = p.pets[petId];
      if (!pet) return Result.fail("PetNotOwned");
      const wait = Progression.Bond.PlayCooldownSeconds - (ctx.now - pet.lastPlayedAt);
      if (wait > 0 && !ctx.skipCooldowns) return { ok: false, err: "Cooldown", data: { retryIn: Math.ceil(wait) } };
      pet.lastPlayedAt = ctx.now;
      const gained = PetRules.addBond(pet, Progression.Bond.PlayGain);
      return Result.ok({ petId, bondGained: gained, bond: pet.bond, hearts: Leveling.bondHearts(pet.bond) });
    };
    PetRules.evolve = function (p, petId, ctx) {
      const pet = p.pets[petId];
      if (!pet) return Result.fail("PetNotOwned");
      const [ok, reason] = Leveling.canEvolve(pet);
      if (!ok) return Result.fail(reason);
      pet.form = "Tallado"; pet.evolvedAt = ctx.now; delete pet.loadout;
      return Result.ok({ petId, form: "Tallado" });
    };
    PetRules.starterPet = function (p) {
      let best = null;
      for (const pet of values(p.pets)) if (pet.acquired.kind === "Starter" && (best === null || pet.acquired.at < best.acquired.at)) best = pet;
      return best;
    };

    // =================================================================
    // SanctuaryRules
    // =================================================================
    const SanctuaryRules = {};
    function findHabitat(p, habitatId) {
      for (const [lotId, lot] of Object.entries(p.lots)) { const h = lot.habitats[habitatId]; if (h) return [h, lotId]; }
      return [null, null];
    }
    SanctuaryRules.findHabitat = findHabitat;
    SanctuaryRules.locationOf = function (p, petId) {
      for (const lot of values(p.lots)) for (const [hid, h] of Object.entries(lot.habitats)) {
        const i = h.slots.indexOf(petId);
        if (i >= 0) return [hid, i + 1];
      }
      return [null, null];
    };
    SanctuaryRules.petCoinRate = function (p, petId, lotBiome) {
      const pet = p.pets[petId];
      if (!pet) return 0;
      const sp = SpeciesCfg.ById[pet.speciesId];
      let rate = Rarities.ById[sp.rarity].coinsPerHour;
      if (pet.form === "Brote") rate *= Economy.Habitat.BroteProductionFactor;
      if (lotBiome && sp.biome === lotBiome) rate *= 1 + Sanctuary.NativeBonus.coins;
      return rate;
    };
    SanctuaryRules.habitatRate = function (p, habitatId) {
      const [h, lotId] = findHabitat(p, habitatId);
      if (!h) return 0;
      const biome = Sanctuary.Lots[lotId].biome;
      let total = 0;
      for (const id of h.slots) if (id) total += SanctuaryRules.petCoinRate(p, id, biome);
      return total;
    };
    SanctuaryRules.preview = function (p, habitatId, now) {
      const [h] = findHabitat(p, habitatId);
      if (!h) return 0;
      const elapsed = clamp(now - h.lastCollectAt, 0, Economy.Habitat.OfflineCapSeconds);
      const fresh = Math.floor((SanctuaryRules.habitatRate(p, habitatId) * elapsed) / 3600);
      return (h.accrued ?? 0) + fresh + h.bonusCoins;
    };
    function settle(p, habitatId, h, ctx) {
      const elapsed = clamp(ctx.now - h.lastCollectAt, 0, Economy.Habitat.OfflineCapSeconds);
      const rate = SanctuaryRules.habitatRate(p, habitatId);
      const coins = Math.floor((rate * elapsed) / 3600);
      const capAmount = (rate * Economy.Habitat.OfflineCapSeconds) / 3600;
      const before = h.accrued ?? 0;
      h.accrued = Math.min(before + coins, Math.max(capAmount, before));
      const xp = Math.floor((Economy.Habitat.PassiveXpPerMinute * elapsed) / 60);
      if (xp > 0) for (const id of h.slots) if (id && p.pets[id]) PetRules.addXp(p.pets[id], xp, ctx);
      h.lastCollectAt = ctx.now;
      return xp;
    }
    SanctuaryRules.collect = function (p, habitatId, ctx) {
      const [h, lotId] = findHabitat(p, habitatId);
      if (!h) return Result.fail("UnknownHabitat");
      if (!p.lots[lotId].unlocked) return Result.fail("LotLocked");
      const xp = settle(p, habitatId, h, ctx);
      const coins = Math.floor(((h.accrued ?? 0) + h.bonusCoins) * (ctx.coinMultiplier ?? 1));
      h.accrued = 0; h.bonusCoins = 0;
      if (coins > 0) p.currencies.Monedas = Math.min(Economy.MaxBalance.Monedas, p.currencies.Monedas + coins);
      return Result.ok({ habitatId, coins, xpPerPet: xp, balance: p.currencies.Monedas });
    };
    const badSlot = (slot, n) => slot < 1 || slot > n || Math.floor(slot) !== slot;
    SanctuaryRules.place = function (p, petId, habitatId, slot, ctx) {
      if (!p.pets[petId]) return Result.fail("PetNotOwned");
      const [h, lotId] = findHabitat(p, habitatId);
      if (!h) return Result.fail("UnknownHabitat");
      if (!p.lots[lotId].unlocked) return Result.fail("LotLocked");
      if (badSlot(slot, h.slots.length)) return Result.fail("BadSlot");
      if (h.slots[slot - 1]) return Result.fail("SlotOccupied");
      if (SanctuaryRules.locationOf(p, petId)[0]) return Result.fail("AlreadyPlaced");
      settle(p, habitatId, h, ctx);
      h.slots[slot - 1] = petId;
      return Result.ok({ habitatId, slot, petId });
    };
    SanctuaryRules.remove = function (p, habitatId, slot, ctx) {
      const [h] = findHabitat(p, habitatId);
      if (!h) return Result.fail("UnknownHabitat");
      if (badSlot(slot, h.slots.length)) return Result.fail("BadSlot");
      const petId = h.slots[slot - 1];
      if (!petId) return Result.fail("SlotEmpty");
      if (PetRules.inventoryUsed(p) >= p.inventoryCapacity) return Result.fail("InventoryFull");
      settle(p, habitatId, h, ctx);
      h.slots[slot - 1] = false;
      return Result.ok({ habitatId, slot, petId });
    };
    SanctuaryRules.unlockLot = function (p, lotId, ctx, firstCollectBonus) {
      const lot = p.lots[lotId];
      if (!lot) return Result.fail("UnknownLot");
      if (lot.unlocked) return Result.ok({ lotId, already: true });
      lot.unlocked = true;
      for (const h of values(lot.habitats)) { h.lastCollectAt = ctx.now; h.bonusCoins = firstCollectBonus ?? 0; }
      return Result.ok({ lotId });
    };

    // =================================================================
    // OnboardingRules
    // =================================================================
    const OnboardingRules = {};
    const hasStarter = (p) => values(p.pets).some((pet) => pet.acquired.kind === "Starter");
    function anyPlaced(p) {
      const lot = p.lots.Hogar;
      if (!lot) return false;
      return values(lot.habitats).some((h) => h.slots.some(Boolean));
    }
    const Done = {
      Intro: (p) => !nil(p.firsts.intro_finished),
      ChooseEgg: hasStarter,
      Hatch: (p) => !nil(p.firsts.hatch_completed),
      MeetHome: (p) => !nil(p.unlocks.LoteHogar),
      PlaceInHabitat: anyPlaced,
      FirstFeed: (p) => !nil(p.firsts.first_feed),
      FirstBond: (p) => !nil(p.firsts.first_bond_gain),
      FirstBattle: (p) => !nil(p.story.cleared.valle_r1_e1),
      ClaimReward: (p) => !nil(p.firsts.first_reward_claimed),
    };
    OnboardingRules.stepIndex = function (stepId) {
      const i = Onboarding.Steps.findIndex((s) => s.id === stepId);
      return i >= 0 ? i + 1 : Onboarding.Steps.length;
    };
    OnboardingRules.refresh = function (p, now) {
      const completed = [];
      if (p.onboarding.completed) return completed;
      let i = OnboardingRules.stepIndex(p.onboarding.step);
      while (i <= Onboarding.Steps.length) {
        const step = Onboarding.Steps[i - 1];
        if (step.id === "Done") {
          p.onboarding.step = "Done";
          p.onboarding.completed = true;
          if (!p.firsts.tutorial_completed) { p.firsts.tutorial_completed = now; completed.push("tutorial_completed"); }
          break;
        }
        const check = Done[step.id];
        if (check && check(p)) { completed.push(step.id); i += 1; p.onboarding.step = Onboarding.Steps[i - 1].id; }
        else break;
      }
      return completed;
    };
    OnboardingRules.onLoad = function (p, now) {
      if (p.onboarding.step === "Hatch" && hasStarter(p)) p.firsts.hatch_completed = p.firsts.hatch_completed || now;
      if (p.onboarding.step === "Intro" && hasStarter(p)) p.firsts.intro_finished = p.firsts.intro_finished || now;
      return OnboardingRules.refresh(p, now);
    };
    OnboardingRules.finishIntro = function (p, skipped, now) {
      if (!p.firsts.intro_finished) { p.firsts.intro_finished = now; p.onboarding.introSkipped = skipped; }
      return OnboardingRules.refresh(p, now);
    };

    // =================================================================
    // ShopRules
    // =================================================================
    const ShopRules = {};
    ShopRules.buyFood = function (p, foodId, quantity) {
      const food = Economy.Foods[foodId];
      if (!food || !food.sold) return Result.fail("NotForSale");
      if (Math.floor(quantity) !== quantity || quantity < 1 || quantity > Economy.MaxPurchaseQuantity) return Result.fail("BadQuantity");
      if ((p.items[foodId] ?? 0) + quantity > Economy.MaxItemStack) return Result.fail("StackFull");
      for (const [cur, price] of Object.entries(food.price)) if ((p.currencies[cur] ?? 0) < price * quantity) return Result.fail("NotEnough" + cur);
      for (const [cur, price] of Object.entries(food.price)) p.currencies[cur] -= price * quantity;
      p.items[foodId] = (p.items[foodId] ?? 0) + quantity;
      return Result.ok({ foodId, quantity, owned: p.items[foodId], balance: p.currencies });
    };

    // =================================================================
    // CollectionRules
    // =================================================================
    const CollectionRules = {};
    function entry(p, speciesId) { let e = p.collection[speciesId]; if (!e) { e = {}; p.collection[speciesId] = e; } return e; }
    const isDiscovered = (e) => !!e && (!nil(e.seenAt) || !nil(e.restoredAt) || !nil(e.broteAt) || !nil(e.talladoAt));
    CollectionRules.isDiscovered = isDiscovered;
    CollectionRules.see = function (p, speciesId, now) {
      if (!SpeciesCfg.ById[speciesId]) return false;
      const before = isDiscovered(p.collection[speciesId]);
      const e = entry(p, speciesId);
      e.seenAt = e.seenAt ?? now;
      return !before;
    };
    CollectionRules.restore = function (p, speciesId, now) {
      if (!SpeciesCfg.ById[speciesId]) return false;
      const before = isDiscovered(p.collection[speciesId]);
      const e = entry(p, speciesId);
      e.seenAt = e.seenAt ?? now;
      e.restoredAt = e.restoredAt ?? now;
      return !before;
    };
    CollectionRules.obtain = function (p, speciesId, form, now, countIt) {
      const before = isDiscovered(p.collection[speciesId]);
      const e = entry(p, speciesId);
      let newCard;
      if (form === "Tallado") { newCard = nil(e.talladoAt); e.talladoAt = e.talladoAt ?? now; }
      else { newCard = nil(e.broteAt); e.broteAt = e.broteAt ?? now; }
      if (countIt !== false && form !== "Tallado") e.count = (e.count ?? 0) + 1;
      return { newSpecies: !before, newCard };
    };
    CollectionRules.bestiaryTier = function (e) {
      if (!e) return 0;
      if (!nil(e.talladoAt)) return 3;
      if (!nil(e.restoredAt) || !nil(e.broteAt)) return 2;
      if (!nil(e.seenAt)) return 1;
      return 0;
    };
    CollectionRules.progress = function (p) {
      const byBiome = {};
      let discovered = 0, cards = 0, total = 0;
      for (const id of SpeciesCfg.Order) {
        const sp = SpeciesCfg.ById[id];
        const b = (byBiome[sp.biome] = byBiome[sp.biome] || { biome: sp.biome, discovered: 0, cards: 0, total: 0, complete: false });
        total++; b.total++;
        const e = p.collection[id];
        if (isDiscovered(e)) { discovered++; b.discovered++; }
        if (e && !nil(e.broteAt)) { cards++; b.cards++; }
        if (e && !nil(e.talladoAt)) { cards++; b.cards++; }
      }
      for (const b of Object.values(byBiome)) b.complete = b.cards >= b.total * 2;
      return { discovered, cards, totalSpecies: total, totalCards: total * 2, byBiome };
    };

    // =================================================================
    // EggRules
    // =================================================================
    const EggRules = {};
    const standardTraits = () => ({ veta: "Base", temple: "Neutro", goldVein: false });
    EggRules.storedCount = (p) => values(p.eggs).filter((e) => e.state === "Stored").length;
    EggRules.hasRoom = (p, extra) => EggRules.storedCount(p) + (extra ?? 1) <= Incubation.EggStorageCapacity;
    EggRules.grant = function (p, speciesId, source, now, traits) {
      const sp = SpeciesCfg.ById[speciesId];
      if (!sp) return Result.fail("UnknownSpecies");
      if (!EggRules.hasRoom(p)) return Result.fail("EggStorageFull");
      const id = `E${p.userId}-${p.nextEggSerial}`;
      if (p.eggs[id]) return Result.fail("EggIdCollision");
      p.nextEggSerial += 1;
      p.counters.eggsObtained = (p.counters.eggsObtained ?? 0) + 1;
      p.eggs[id] = { id, speciesId, rarity: sp.rarity, traits: traits || standardTraits(), source, obtainedAt: now, state: "Stored" };
      HistoryRules.add(p, { kind: "Egg", ref: id, rarity: sp.rarity, speciesId, at: now, source: source.kind });
      return Result.ok({ eggId: id, speciesId, rarity: sp.rarity });
    };
    EggRules.seconds = (rarity) => Incubation.SecondsByRarity[rarity] ?? Incubation.SecondsByRarity.Comun;
    EggRules.progress = function (egg, now) {
      if (egg.state !== "Incubating" || nil(egg.startedAt) || nil(egg.readyAt)) return 0;
      const total = Math.max(1, egg.readyAt - egg.startedAt);
      return clamp((now - egg.startedAt) / total, 0, 1);
    };
    EggRules.startIncubation = function (p, eggId, slotIndex, now) {
      const egg = p.eggs[eggId];
      if (!egg) return Result.fail("EggNotOwned");
      if (egg.state !== "Stored") return Result.fail("EggAlreadyIncubating");
      const slot = p.incubators[slotIndex - 1];
      if (!slot) return Result.fail("BadSlot");
      if (!slot.unlocked) return Result.fail("SlotLocked");
      if (slot.eggId) return Result.fail("SlotBusy");
      slot.eggId = eggId;
      egg.state = "Incubating"; egg.slot = slotIndex; egg.startedAt = now; egg.readyAt = now + EggRules.seconds(egg.rarity);
      return Result.ok({ eggId, slot: slotIndex, readyAt: egg.readyAt });
    };
    EggRules.hatch = function (p, slotIndex, now) {
      const slot = p.incubators[slotIndex - 1];
      if (!slot || !slot.eggId) return Result.fail("SlotEmpty");
      const egg = p.eggs[slot.eggId];
      if (!egg || egg.state !== "Incubating") return Result.fail("SlotEmpty");
      if (now < egg.readyAt) return Result.fail("NotReady");
      const created = PetRules.create(p, egg.speciesId, { kind: "Egg", ref: egg.id, at: now });
      if (!created.ok) return created;
      const petId = created.data.petId;
      p.pets[petId].traits = clone(egg.traits);
      p.counters.eggsHatched = (p.counters.eggsHatched ?? 0) + 1;
      delete slot.eggId;
      delete p.eggs[egg.id];
      const found = CollectionRules.obtain(p, egg.speciesId, "Brote", now);
      HistoryRules.add(p, { kind: "Hatch", ref: petId, rarity: egg.rarity, speciesId: egg.speciesId, at: now, source: egg.source.kind });
      return Result.ok({ petId, speciesId: egg.speciesId, rarity: egg.rarity, eggId: egg.id, newSpecies: found.newSpecies, newCard: found.newCard });
    };
    EggRules.slotRequirementMet = function (p, rule) {
      if (rule.unlock === "Start") return true;
      if (rule.unlock === "Story") return !nil(rule.ref) && !nil(p.story.regionRewards[rule.ref + ":clear"]);
      return false;
    };
    EggRules.refreshSlots = function (p) {
      const opened = [];
      for (const rule of Incubation.Slots) {
        const slot = p.incubators[rule.slot - 1];
        if (slot && !slot.unlocked && rule.availableInBeta && EggRules.slotRequirementMet(p, rule)) { slot.unlocked = true; opened.push(rule.slot); }
      }
      return opened;
    };
    EggRules.buySlot = function (p, slotIndex) {
      const rule = Incubation.Slots[slotIndex - 1], slot = p.incubators[slotIndex - 1];
      if (!rule || !slot) return Result.fail("BadSlot");
      if (slot.unlocked) return Result.fail("AlreadyUnlocked");
      if (!rule.availableInBeta) return Result.fail("NotAvailable");
      if (rule.unlock !== "Monedas" || !rule.price) return Result.fail("NotPurchasable");
      if (slotIndex > 1 && !p.incubators[slotIndex - 2].unlocked) return Result.fail("PreviousSlotLocked");
      const cost = rule.price.Monedas;
      if ((p.currencies.Monedas ?? 0) < cost) return Result.fail("NotEnoughMonedas");
      p.currencies.Monedas -= cost;
      slot.unlocked = true;
      return Result.ok({ slot: slotIndex, cost });
    };

    // =================================================================
    // ChestRules
    // =================================================================
    const ChestRules = {};
    ChestRules.validateTable = function (rows) {
      const issues = [], seen = {};
      let total = 0;
      for (const row of rows) {
        if (seen[row.prize]) issues.push("Premio duplicado: " + row.prize);
        seen[row.prize] = true;
        if (nil(row.percent)) issues.push("Porcentaje faltante: " + row.prize);
        else if (row.percent < 0) issues.push("Porcentaje negativo: " + row.prize);
        else total += row.percent;
        if (row.status !== "Biblia") issues.push("Dato no aprobado (" + row.status + "): " + row.prize);
      }
      if (Math.abs(total - 100) > 1e-9) issues.push(`La tabla suma ${total.toFixed(2)} %, no 100 %`);
      return { ok: issues.length === 0, total, issues };
    };
    ChestRules.canUseRandom = (t) => { const d = Chests.ById[t]; return !!d && d.approved && ChestRules.validateTable(d.bibleTable).ok; };
    function pickFromPool(p, pool, reserved) {
      const pending = {};
      for (const egg of values(p.eggs)) pending[egg.speciesId] = (pending[egg.speciesId] ?? 0) + 1;
      for (const chest of values(p.chests)) for (const e of chest.contents.eggs) pending[e.speciesId] = (pending[e.speciesId] ?? 0) + 1;
      for (const id of pool) {
        const e = p.collection[id];
        const owned = !!e && !nil(e.broteAt);
        if (!owned && !pending[id] && !reserved[id]) return id;
      }
      let best = pool[0], bestCount = Infinity;
      for (const id of pool) {
        const e = p.collection[id];
        const n = ((e && e.count) ?? 0) + (pending[id] ?? 0) + (reserved[id] ? 1 : 0);
        if (n < bestCount) { best = id; bestCount = n; }
      }
      return best;
    }
    ChestRules.contentsFor = function (p, chestType) {
      const def = Chests.ById[chestType];
      if (!def || !def.fixed) throw new Error("Cofre sin contenido fijo: " + chestType);
      const fixed = def.fixed, eggs = [], reserved = {};
      for (const egg of fixed.eggs) {
        const speciesId = pickFromPool(p, Chests.EggPools[egg.pool], reserved);
        reserved[speciesId] = true;
        eggs.push({ speciesId });
      }
      return { currencies: clone(fixed.currencies), items: clone(fixed.items), eggs, codex: fixed.codex ? clone(fixed.codex) : undefined };
    };
    ChestRules.count = (p) => Object.keys(p.chests).length;
    ChestRules.grant = function (p, chestType, source, now) {
      const def = Chests.ById[chestType];
      if (!def) return Result.fail("UnknownChest");
      if (!def.activeInBeta) return Result.fail("ChestNotActive");
      if (def.mode !== "Fixed") return Result.fail("RandomChestsDisabled");
      if (ChestRules.count(p) >= Chests.MaxStoredChests) return Result.fail("ChestStorageFull");
      const id = `C${p.userId}-${p.nextChestSerial}`;
      p.nextChestSerial += 1;
      p.counters.chestsObtained = (p.counters.chestsObtained ?? 0) + 1;
      const contents = ChestRules.contentsFor(p, chestType);
      p.chests[id] = { id, chestType, contents: { currencies: contents.currencies, items: contents.items, eggs: contents.eggs }, source, obtainedAt: now };
      if (contents.codex) p.chests[id].codex = contents.codex;
      HistoryRules.add(p, { kind: "Chest", ref: id, rarity: chestType, at: now, source: source.kind });
      return Result.ok({ chestId: id, chestType });
    };
    ChestRules.open = function (p, chestId, now) {
      const chest = p.chests[chestId];
      if (!chest) return Result.fail("ChestNotFound");
      const contents = chest.contents;
      if (!EggRules.hasRoom(p, contents.eggs.length)) return Result.fail("EggStorageFull");
      delete p.chests[chestId];
      for (const [cur, v] of Object.entries(contents.currencies)) p.currencies[cur] = Math.min(Economy.MaxBalance[cur] ?? Infinity, (p.currencies[cur] ?? 0) + v);
      for (const [item, v] of Object.entries(contents.items)) p.items[item] = Math.min(Economy.MaxItemStack, (p.items[item] ?? 0) + v);
      const eggIds = [];
      for (const e of contents.eggs) {
        const g = EggRules.grant(p, e.speciesId, { kind: "Chest", ref: chestId, at: now }, now);
        if (g.ok) eggIds.push(g.data.eggId);
      }
      const codex = chest.codex || [];
      for (const entryId of codex) p.codex[entryId] = p.codex[entryId] ?? now;
      HistoryRules.add(p, { kind: "ChestOpened", ref: chestId, rarity: chest.chestType, detail: `${contents.currencies.Monedas ?? 0} Monedas, ${eggIds.length} huevos`, at: now, source: chest.source.kind });
      return Result.ok({ chestId, chestType: chest.chestType, currencies: contents.currencies, items: contents.items, eggIds, eggs: contents.eggs, codex });
    };
    ChestRules.odds = function (p, chestId) {
      const chest = p.chests[chestId];
      if (!chest) return null;
      const def = Chests.ById[chest.chestType];
      return {
        mode: def.mode, contents: chest.contents, bibleTable: def.bibleTable,
        note: def.mode === "Fixed" ? "Contenido fijo: 100 % — lo que ves es lo que te llevas." : "Probabilidades visibles antes de abrir.",
      };
    };

    // =================================================================
    // QuestRules
    // =================================================================
    const QuestRules = {};
    const DAY = 86400;
    QuestRules.dayIndex = (now) => Math.floor((now - Quests.ResetHourUtc * 3600) / DAY);
    QuestRules.weekIndex = (now) => Math.floor((QuestRules.dayIndex(now) + Quests.WeekOffsetDays) / 7);
    QuestRules.nextDailyReset = (now) => (QuestRules.dayIndex(now) + 1) * DAY + Quests.ResetHourUtc * 3600;
    QuestRules.nextWeeklyReset = (now) => ((QuestRules.weekIndex(now) + 1) * 7 - Quests.WeekOffsetDays) * DAY + Quests.ResetHourUtc * 3600;
    function eligible(p, def) {
      if (def.requiresUnlock === "HasEgg") return Object.keys(p.eggs).length > 0 || (p.counters.eggsObtained ?? 0) > 0;
      if (def.requiresUnlock === "HasChest") return Object.keys(p.chests).length > 0 || (p.counters.chestsObtained ?? 0) > 0;
      return true;
    }
    const slotFor = (def) => ({ questId: def.id, progress: 0, target: def.target, coins: def.coins, claimed: false });
    function pickDaily(p, day) {
      const rng = new Rng(p.userId * 7919 + day * 104729 + 17);
      const out = [];
      for (const difficulty of Quests.DailyMix) {
        const options = Quests.Daily.filter((def) => def.difficulty === difficulty && eligible(p, def));
        if (options.length > 0) out.push(slotFor(options[rng.int(1, options.length) - 1]));
      }
      return out;
    }
    function pickWeekly(p, week) {
      const rng = new Rng(p.userId * 3571 + week * 6151 + 29);
      const options = Quests.Weekly.filter((def) => eligible(p, def));
      if (options.length === 0) return undefined;
      return slotFor(options[rng.int(1, options.length) - 1]);
    }
    QuestRules.refresh = function (p, now) {
      let changed = false;
      const day = QuestRules.dayIndex(now), week = QuestRules.weekIndex(now);
      if (p.quests.day !== day) { p.quests.day = day; p.quests.daily = pickDaily(p, day); p.quests.dailyBonusClaimed = false; changed = true; }
      if (p.quests.week !== week) { p.quests.week = week; setOrDelete(p.quests, "weekly", pickWeekly(p, week)); changed = true; }
      return changed;
    };
    QuestRules.def = (questId) => Quests.Daily.find((d) => d.id === questId) || Quests.Weekly.find((d) => d.id === questId) || null;
    QuestRules.track = function (p, event, amount, now) {
      QuestRules.refresh(p, now);
      const completed = [];
      const bump = (slot) => {
        if (!slot || slot.claimed) return;
        const def = QuestRules.def(slot.questId);
        if (!def || def.event !== event || slot.progress >= slot.target) return;
        slot.progress = Math.min(slot.target, slot.progress + amount);
        if (slot.progress >= slot.target) completed.push(slot.questId);
      };
      for (const slot of p.quests.daily) bump(slot);
      bump(p.quests.weekly);
      return completed;
    };
    QuestRules.claim = function (p, kind, index, now) {
      QuestRules.refresh(p, now);
      const slot = kind === "Weekly" ? p.quests.weekly : p.quests.daily[index - 1];
      if (!slot) return Result.fail("UnknownQuest");
      if (slot.claimed) return Result.fail("AlreadyClaimed");
      if (slot.progress < slot.target) return Result.fail("QuestNotComplete");
      let chestType;
      if (kind === "Weekly") chestType = Quests.WeeklyChest;
      else {
        let others = 0;
        p.quests.daily.forEach((s, i) => { if (i !== index - 1 && s.claimed) others++; });
        if (others === p.quests.daily.length - 1 && !p.quests.dailyBonusClaimed) chestType = Quests.DailyBonusChest;
      }
      let chestId;
      if (chestType) {
        const g = ChestRules.grant(p, chestType, { kind: "Quest", ref: slot.questId, at: now }, now);
        if (!g.ok) return g;
        chestId = g.data.chestId;
        if (kind !== "Weekly") p.quests.dailyBonusClaimed = true;
      }
      slot.claimed = true;
      p.currencies.Monedas = (p.currencies.Monedas ?? 0) + slot.coins;
      HistoryRules.add(p, { kind: "Quest", ref: slot.questId, detail: `${slot.coins} Monedas`, at: now, source: kind });
      return Result.ok({ questId: slot.questId, coins: slot.coins, chestId, chestType });
    };

    // =================================================================
    // DecorRules
    // =================================================================
    const DecorRules = {};
    function usedCopies(p, decorId, exceptSlot) { let n = 0; p.decor.slots.forEach((id, i) => { if (id === decorId && i + 1 !== exceptSlot) n++; }); return n; }
    DecorRules.grant = function (p, decorId, amount) {
      if (!Decor.ById[decorId]) return Result.fail("UnknownDecor");
      p.decor.owned[decorId] = (p.decor.owned[decorId] ?? 0) + (amount ?? 1);
      return Result.ok({ decorId });
    };
    DecorRules.place = function (p, slot, decorId) {
      if (badSlot(slot, Decor.FreeSlots)) return Result.fail("BadSlot");
      if (!p.lots.Hogar || !p.lots.Hogar.unlocked) return Result.fail("LotLocked");
      if (nil(decorId) || decorId === "") { p.decor.slots[slot - 1] = false; return Result.ok({ slot }); }
      if (!Decor.ById[decorId]) return Result.fail("UnknownDecor");
      const owned = p.decor.owned[decorId] ?? 0;
      if (usedCopies(p, decorId, slot) >= owned) return Result.fail("DecorNotOwned");
      p.decor.slots[slot - 1] = decorId;
      return Result.ok({ slot, decorId });
    };
    DecorRules.applyTemplate = function (p, templateId) {
      const template = Decor.Templates.find((t) => t.id === templateId);
      if (!template) return Result.fail("UnknownTemplate");
      const placed = [];
      for (const decorId of template.slots) {
        for (let slot = 1; slot <= Decor.FreeSlots; slot++) {
          if (p.decor.slots[slot - 1] === false) { if (DecorRules.place(p, slot, decorId).ok) placed.push(slot); break; }
        }
      }
      if (placed.length === 0) return Result.fail("NothingPlaced");
      return Result.ok({ placed });
    };
    DecorRules.setShowcase = function (p, petIds) {
      if (petIds.length > Sanctuary.VitrinaSlots) return Result.fail("TooManyPets");
      const seen = {};
      for (const id of petIds) { if (!p.pets[id]) return Result.fail("PetNotOwned"); if (seen[id]) return Result.fail("DuplicatePet"); seen[id] = true; }
      p.showcase = petIds.slice();
      return Result.ok({ showcase: p.showcase });
    };
    DecorRules.expandInventory = function (p) {
      if (p.inventoryCapacity >= Sanctuary.InventoryMaxCapacity) return Result.fail("InventoryAtMax");
      const rule = Sanctuary.InventoryExpansion, cost = rule.price.Monedas;
      if ((p.currencies.Monedas ?? 0) < cost) return Result.fail("NotEnoughMonedas");
      p.currencies.Monedas -= cost;
      p.inventoryCapacity = Math.min(Sanctuary.InventoryMaxCapacity, p.inventoryCapacity + rule.step);
      return Result.ok({ capacity: p.inventoryCapacity, cost });
    };

    // =================================================================
    // RewardRules
    // =================================================================
    const RewardRules = { LEDGER_LIMIT: 500 };
    function addInto(dst, src) { if (src) for (const [k, v] of Object.entries(src)) dst[k] = (dst[k] ?? 0) + v; }
    RewardRules.isKnown = (p, id) => !nil(p.rewards.pending[id]) || !nil(p.rewards.ledger[id]);
    RewardRules.create = function (p, rewardId, spec, source, now) {
      if (RewardRules.isKnown(p, rewardId)) return { ok: true, data: { rewardId, duplicate: true } };
      const currencies = {}, items = {}, unlocks = [];
      let title = spec.title;
      if (spec.bundleId) {
        const bundle = RewardsCfg.ById[spec.bundleId];
        if (!bundle) return Result.fail("UnknownBundle");
        addInto(currencies, bundle.currencies); addInto(items, bundle.items);
        for (const u of bundle.unlocks || []) unlocks.push(u);
        title = title || bundle.title;
      }
      addInto(currencies, spec.currencies); addInto(items, spec.items);
      for (const u of spec.unlocks || []) unlocks.push(u);
      for (const [cur, v] of Object.entries(currencies)) if (!Economy.Currencies[cur] || v < 0 || Math.floor(v) !== v) return Result.fail("BadRewardCurrency");
      for (const [item, v] of Object.entries(items)) if (!Economy.Foods[item] || v < 0 || Math.floor(v) !== v) return Result.fail("BadRewardItem");
      for (const c of spec.chests || []) if (!Chests.ById[c]) return Result.fail("BadRewardChest");
      for (const sp of spec.eggs || []) if (!SpeciesCfg.ById[sp]) return Result.fail("BadRewardEgg");
      for (const d of spec.decor || []) if (!Decor.ById[d]) return Result.fail("BadRewardDecor");
      const list = (l) => (l && l.length > 0 ? l.slice() : undefined);
      const reward = {
        id: rewardId, bundleId: spec.bundleId, title: title || "Recompensa", currencies, items,
        petXp: Math.max(0, Math.floor(spec.petXp ?? 0)), petIds: spec.petIds || [], unlocks, source, createdAt: now,
        chests: list(spec.chests), eggs: list(spec.eggs), decor: list(spec.decor), titles: list(spec.titles), frames: list(spec.frames),
      };
      for (const k of Object.keys(reward)) if (reward[k] === undefined) delete reward[k];
      p.rewards.pending[rewardId] = reward;
      return Result.ok({ rewardId, reward });
    };
    function remember(p, rewardId, now) {
      p.rewards.ledger[rewardId] = now;
      p.rewards.ledgerOrder.push(rewardId);
      while (p.rewards.ledgerOrder.length > RewardRules.LEDGER_LIMIT) delete p.rewards.ledger[p.rewards.ledgerOrder.shift()];
    }
    RewardRules.claim = function (p, rewardId, ctx) {
      if (!nil(p.rewards.ledger[rewardId])) return Result.fail("AlreadyClaimed");
      const r = p.rewards.pending[rewardId];
      if (!r) return Result.fail("UnknownReward");
      const eggs = r.eggs || [], chests = r.chests || [];
      if (eggs.length > 0 && !EggRules.hasRoom(p, eggs.length)) return Result.fail("EggStorageFull");
      if (ChestRules.count(p) + chests.length > Chests.MaxStoredChests) return Result.fail("ChestStorageFull");
      for (const [cur, v] of Object.entries(r.currencies)) p.currencies[cur] = Math.min(Economy.MaxBalance[cur] ?? Infinity, (p.currencies[cur] ?? 0) + v);
      for (const [item, v] of Object.entries(r.items)) p.items[item] = Math.min(Economy.MaxItemStack, (p.items[item] ?? 0) + v);
      const petResults = {};
      if (r.petXp > 0) for (const petId of r.petIds) { const pet = p.pets[petId]; if (pet) petResults[petId] = PetRules.addXp(pet, r.petXp, ctx); }
      const newUnlocks = [];
      for (const u of r.unlocks) if (!p.unlocks[u]) { p.unlocks[u] = ctx.now; newUnlocks.push(u); }
      const chestIds = [];
      for (const chestType of chests) {
        const g = ChestRules.grant(p, chestType, { kind: "Reward", ref: rewardId, at: ctx.now }, ctx.now);
        if (g.ok) chestIds.push(g.data.chestId);
      }
      const eggIds = [];
      for (const speciesId of eggs) {
        const g = EggRules.grant(p, speciesId, { kind: "Rescue", ref: rewardId, at: ctx.now }, ctx.now);
        if (g.ok) eggIds.push(g.data.eggId);
      }
      for (const d of r.decor || []) DecorRules.grant(p, d, 1);
      for (const t of r.titles || []) p.titles.owned[t] = p.titles.owned[t] ?? ctx.now;
      for (const f of r.frames || []) p.frames.owned[f] = p.frames.owned[f] ?? ctx.now;
      delete p.rewards.pending[rewardId];
      remember(p, rewardId, ctx.now);
      return Result.ok({ rewardId, reward: r, pets: petResults, newUnlocks, chestIds, eggIds });
    };
    RewardRules.grant = function (p, rewardId, spec, source, ctx) {
      const created = RewardRules.create(p, rewardId, spec, source, ctx.now);
      if (!created.ok) return created;
      if (created.data && created.data.duplicate) return Result.fail("AlreadyGranted");
      return RewardRules.claim(p, rewardId, ctx);
    };

    // =================================================================
    // EncounterRules
    // =================================================================
    const EncounterRules = { DAILY_CONSOLATION_LIMIT: 10, BOSS_TEAM_COST: 12 };
    const starsOf = (p, id) => p.story.stars[id] || [false, false, false];
    const hasAllStars = (p, id) => { const s = p.story.stars[id]; return !!s && s[0] === true && s[1] === true && s[2] === true; };
    EncounterRules.regionDef = (i) => Encounters.Regions[i - 1];
    EncounterRules.regionCleared = function (p, i) {
      const region = Encounters.Regions[i - 1];
      return !!region && region.stages.every((id) => !nil(p.story.cleared[id]));
    };
    EncounterRules.regionAllStars = function (p, i) {
      const region = Encounters.Regions[i - 1];
      return !!region && region.stages.every((id) => hasAllStars(p, id));
    };
    EncounterRules.isUnlocked = function (p, encounterId) {
      const enc = Encounters.ById[encounterId];
      if (!enc) return false;
      for (const req of enc.requires) if (nil(p.story.cleared[req])) return false;
      if (enc.requiresRegionStars && !EncounterRules.regionAllStars(p, enc.requiresRegionStars)) return false;
      return true;
    };
    function resolveSpecies(p, opp) {
      if (opp.speciesId) return opp.speciesId;
      const starter = PetRules.starterPet(p);
      if (!starter || !opp.byStarterElement) return undefined;
      return opp.byStarterElement[SpeciesCfg.ById[starter.speciesId].elements[0]];
    }
    EncounterRules.opponentsFor = function (p, encounterId) {
      const out = [];
      for (const opp of Encounters.ById[encounterId].opponents) { const id = resolveSpecies(p, opp); if (id) out.push(id); }
      return out;
    };
    EncounterRules.opponentSpecies = function (p, encounterId) {
      const enc = Encounters.ById[encounterId];
      if (!enc || enc.opponents.length === 0) return undefined;
      return resolveSpecies(p, enc.opponents[0]);
    };
    EncounterRules.participantsFor = function (p, encounterId) {
      const enc = Encounters.ById[encounterId];
      const limit = enc ? enc.teamSize : 3;
      const out = [];
      for (const petId of p.team) if (p.pets[petId] && out.length < limit) out.push(petId);
      if (out.length === 0 && p.companionPetId && p.pets[p.companionPetId]) out.push(p.companionPetId);
      return out;
    };
    EncounterRules.teamCost = function (p, petIds) {
      let total = 0;
      for (const id of petIds) {
        const pet = p.pets[id];
        if (pet) { const rarity = Rarities.ById[SpeciesCfg.ById[pet.speciesId].rarity]; total += pet.form === "Tallado" ? rarity.teamCost : rarity.teamCost - 1; }
      }
      return total;
    };
    EncounterRules.canStart = function (p, encounterId) {
      const enc = Encounters.ById[encounterId];
      if (!enc) return Result.fail("UnknownEncounter");
      if (enc.stageType === "Tesoro") return Result.fail("NotABattle");
      if (!EncounterRules.isUnlocked(p, encounterId)) return Result.fail("EncounterLocked");
      const team = EncounterRules.participantsFor(p, encounterId);
      if (team.length === 0) return Result.fail("NoCompanion");
      if (enc.stageType === "Jefe" && EncounterRules.teamCost(p, team) > EncounterRules.BOSS_TEAM_COST) return Result.fail("TeamTooCostly");
      if (EncounterRules.opponentsFor(p, encounterId).length !== enc.opponents.length) return Result.fail("NoOpponent");
      return Result.ok();
    };
    EncounterRules.buildSetup = function (p, encounterId, battleId, seed) {
      const enc = Encounters.ById[encounterId];
      const act = Encounters.Acts[enc.act];
      const team = EncounterRules.participantsFor(p, encounterId).map((petId) => {
        const pet = p.pets[petId];
        return { speciesId: pet.speciesId, form: pet.form, level: pet.level, petId: pet.id, nickname: pet.nickname, loadout: pet.loadout };
      });
      const foes = enc.opponents.map((opp, i) => ({
        speciesId: EncounterRules.opponentsFor(p, encounterId)[i], guardianId: opp.guardianId, form: opp.form, level: opp.level,
        isOpaco: true, modifier: opp.modifier, rootHeal: opp.rooted ? act.rootHeal : undefined,
      }));
      return { battleId, seed, sides: [{ controller: "Player", team }, { controller: "AI", ai: enc.ai, team: foes }] };
    };
    const dayIndex = (now) => Math.floor(now / 86400);
    EncounterRules.challengeMet = function (p, enc, summary) {
      const c = enc.challenge;
      if (c.kind === "MaxTurns") return summary.turns <= c.value;
      if (c.kind === "CutRoots") return summary.rootsCut >= c.value;
      if (c.kind === "UseElement") return summary.elements[c.value] === true;
      if (c.kind === "TeamMax") return summary.teamSize <= c.value;
      if (c.kind === "FirstTry") return (p.counters["losses:" + enc.id] ?? 0) === 0;
      return false;
    };
    function awardStars(p, id, earned) {
      const current = starsOf(p, id);
      let fresh = 0;
      const merged = [];
      for (let i = 0; i < 3; i++) { merged[i] = current[i] || earned[i]; if (merged[i] && !current[i]) fresh++; }
      p.story.stars[id] = merged;
      return fresh;
    }
    function milestoneRewards(p, enc, spec, info, now) {
      const region = Encounters.Regions[enc.region - 1];
      const act = Encounters.Acts[enc.act];
      if (region && EncounterRules.regionCleared(p, region.index) && nil(p.story.regionRewards[region.id + ":clear"])) {
        p.story.regionRewards[region.id + ":clear"] = now;
        spec.decor.push(region.clearDecor);
        p.codex[region.clearCodex] = p.codex[region.clearCodex] ?? now;
        info.codex.push(region.clearCodex);
        info.regionCleared = region.index;
        info.slotsOpened = EggRules.refreshSlots(p);
      }
      if (region && EncounterRules.regionAllStars(p, region.index) && nil(p.story.regionRewards[region.id + ":stars"])) {
        p.story.regionRewards[region.id + ":stars"] = now;
        spec.chests.push(act.regionStarsChest);
        info.regionStars = region.index;
      }
      if (enc.stageType === "Jefe" && nil(p.guardians[act.guardian])) {
        p.guardians[act.guardian] = now;
        spec.unlocks.push(act.completeUnlock);
        info.guardianRestored = act.guardian;
      }
      if (nil(p.story.actRewards[act.id + ":stars"])) {
        const all = Encounters.Order.every((id) => Encounters.ById[id].act !== act.id || hasAllStars(p, id));
        if (all) {
          p.story.actRewards[act.id + ":stars"] = now;
          spec.frames.push(act.allStars.frame);
          spec.titles.push(act.allStars.title);
          info.actAllStars = act.id;
        }
      }
    }
    function completeStage(p, enc, earned, participants, rewardId, source, ctx, rescueSeed) {
      const firstClear = nil(p.story.cleared[enc.id]);
      const today = dayIndex(ctx.now);
      const repeatCount = p.story.repeatDay === today ? p.story.repeatCount : 0;
      if (!firstClear && repeatCount >= Encounters.Repeat.DailyRewardedRepeats) {
        p.story.cleared[enc.id].wins += 1;
        const fresh = awardStars(p, enc.id, earned);
        return Result.ok({ won: true, firstClear: false, capped: true, stars: starsOf(p, enc.id), newStars: fresh });
      }
      const spec = { currencies: {}, petXp: 0, petIds: participants, chests: [], eggs: [], decor: [], titles: [], frames: [], unlocks: [] };
      const info = { codex: [] };
      if (firstClear) {
        spec.bundleId = enc.firstClearBonus;
        spec.title = enc.firstClearBonus ? undefined : enc.name;
        spec.currencies.Monedas = enc.baseReward.Monedas;
        spec.petXp = enc.baseReward.petXp;
        if (enc.firstClearChest) spec.chests.push(enc.firstClearChest);
        if (enc.firstClearDecor) spec.decor.push(enc.firstClearDecor);
      } else {
        const scale = Encounters.Repeat.RewardScale;
        spec.title = enc.name + " · repetición";
        spec.currencies.Monedas = Math.floor(enc.baseReward.Monedas * scale);
        spec.petXp = Math.floor(enc.baseReward.petXp * scale);
      }
      if (enc.rescue && rescueSeed) {
        const roll = new Rng(Rng.seedFromString(rescueSeed)).next();
        if (roll < enc.rescue.eggChance) { spec.eggs.push(enc.rescue.speciesId); info.rescueEgg = enc.rescue.speciesId; }
      }
      if (firstClear) {
        p.story.cleared[enc.id] = { firstClearAt: ctx.now, wins: 1 };
        for (const entryId of enc.firstClearCodex || []) { p.codex[entryId] = p.codex[entryId] ?? ctx.now; info.codex.push(entryId); }
      } else {
        p.story.cleared[enc.id].wins += 1;
        p.story.repeatDay = today;
        p.story.repeatCount = repeatCount + 1;
      }
      const fresh = awardStars(p, enc.id, earned);
      milestoneRewards(p, enc, spec, info, ctx.now);
      const created = RewardRules.create(p, rewardId, spec, source, ctx.now);
      if (!created.ok) return created;
      const st = starsOf(p, enc.id);
      HistoryRules.add(p, { kind: "Stage", ref: enc.id, detail: `${(st[0] ? 1 : 0) + (st[1] ? 1 : 0) + (st[2] ? 1 : 0)}★`, at: ctx.now, source: enc.stageType });
      Object.assign(info, { won: true, firstClear, rewardId, stars: starsOf(p, enc.id), newStars: fresh, chests: spec.chests });
      return Result.ok(info);
    }
    EncounterRules.applyResult = function (p, encounterId, battleId, won, participants, ctx, reason, summary) {
      const enc = Encounters.ById[encounterId];
      if (!enc) return Result.fail("UnknownEncounter");
      const rewardId = "battle:" + battleId;
      if (RewardRules.isKnown(p, rewardId)) return Result.fail("ResultAlreadyApplied");
      for (const petId of participants) { const pet = p.pets[petId]; if (pet) { if (won) pet.stats.battlesWon += 1; else pet.stats.battlesLost += 1; } }
      if (!won) {
        if (reason === "Forfeit") return Result.ok({ won: false, forfeited: true });
        p.counters["losses:" + encounterId] = (p.counters["losses:" + encounterId] ?? 0) + 1;
        const today = dayIndex(ctx.now);
        if ((p.counters.lossXpDay ?? 0) !== today) { p.counters.lossXpDay = today; p.counters.lossXpCount = 0; }
        if ((p.counters.lossXpCount ?? 0) >= EncounterRules.DAILY_CONSOLATION_LIMIT) return Result.ok({ won: false, capped: true });
        p.counters.lossXpCount = (p.counters.lossXpCount ?? 0) + 1;
        const results = {};
        for (const petId of participants) { const pet = p.pets[petId]; if (pet) results[petId] = PetRules.addXp(pet, enc.lossPetXp, ctx); }
        return Result.ok({ won: false, pets: results });
      }
      const restored = [];
      for (const speciesId of EncounterRules.opponentsFor(p, encounterId)) {
        if (SpeciesCfg.ById[speciesId] && CollectionRules.restore(p, speciesId, ctx.now)) restored.push(speciesId);
      }
      const sum = summary || { turns: 99, faints: 1, elements: {}, rootsCut: 0, teamSize: 3 };
      const earned = [true, sum.faints === 0, EncounterRules.challengeMet(p, enc, sum)];
      const r = completeStage(p, enc, earned, participants, rewardId, { kind: "Encounter", ref: encounterId, battleId }, ctx, "rescue:" + battleId);
      if (r.ok && r.data) {
        r.data.newSpecies = restored;
        r.data.opponents = enc.opponents.length;
        if (sum.turns < (p.story.bestTurns[encounterId] ?? Infinity)) p.story.bestTurns[encounterId] = sum.turns;
      }
      return r;
    };
    EncounterRules.correctAnswer = function (enc) {
      return enc.riddle.options.find((el) => ElementChart.classify(ElementChart.multiplier(el, [enc.riddle.sealElement], false)) === "Strong");
    };
    EncounterRules.solveTreasure = function (p, encounterId, element, ctx) {
      const enc = Encounters.ById[encounterId];
      if (!enc || enc.stageType !== "Tesoro" || !enc.riddle) return Result.fail("NotATreasure");
      if (!EncounterRules.isUnlocked(p, encounterId)) return Result.fail("EncounterLocked");
      const riddle = enc.riddle;
      if (!riddle.options.includes(element)) return Result.fail("BadOption");
      const attempts = (p.story.treasureAttempts[encounterId] ?? 0) + 1;
      p.story.treasureAttempts[encounterId] = attempts;
      if (ElementChart.classify(ElementChart.multiplier(element, [riddle.sealElement], false)) !== "Strong") {
        p.counters["losses:" + encounterId] = (p.counters["losses:" + encounterId] ?? 0) + 1;
        return Result.ok({ solved: false, attempts });
      }
      const wins = p.story.cleared[encounterId] ? p.story.cleared[encounterId].wins : 0;
      const rewardId = `treasure:${encounterId}:${wins + 1}`;
      const earned = [
        true,
        attempts - (p.counters["treasureBase:" + encounterId] ?? 0) <= 2,
        EncounterRules.challengeMet(p, enc, { turns: 0, faints: 0, elements: {}, rootsCut: 0, teamSize: 0 }),
      ];
      p.counters["treasureBase:" + encounterId] = attempts;
      const r = completeStage(p, enc, earned, EncounterRules.participantsFor(p, encounterId), rewardId, { kind: "Treasure", ref: encounterId }, ctx, null);
      if (r.ok && r.data) r.data.solved = true;
      return r;
    };

    // =================================================================
    // Actions (casos de uso)
    // =================================================================
    const Actions = { HOME_HABITAT: "Hogar_H1", EncounterOrder: Encounters.Order };
    // ── Logros (AchievementRules.luau, D-033) ──
    const AchievementRules = {};
    AchievementRules.rewardId = (id) => "achievement:" + id;
    AchievementRules.metric = function (p, metric) {
      let n = 0;
      if (metric === "SpeciesDiscovered") { for (const e of values(p.collection)) if (isDiscovered(e)) n++; }
      else if (metric === "SpeciesRestored") { for (const e of values(p.collection)) if (!nil(e.restoredAt)) n++; }
      else if (metric === "Tallados") { for (const e of values(p.collection)) if (!nil(e.talladoAt)) n++; }
      else if (metric === "EggsHatched") n = p.counters.eggsHatched ?? 0;
      else if (metric === "Stars") {
        for (const [encId, marks] of Object.entries(p.story.stars || {})) {
          const enc = Encounters.ById[encId];
          if (enc && enc.act === "ActoI") for (const got of marks || []) if (got) n++;
        }
      } else if (metric === "Guardians") n = Object.keys(p.guardians || {}).length;
      return n;
    };
    AchievementRules.refresh = function (p, now) {
      const unlocked = [];
      for (const id of Achievements.Order) {
        const def = Achievements.ById[id];
        if (nil(p.achievements[id]) && AchievementRules.metric(p, def.metric) >= def.goal) {
          const created = RewardRules.create(p, AchievementRules.rewardId(id), {
            title: "Logro: " + def.name, currencies: def.reward.currencies, chests: def.reward.chests, eggs: def.reward.eggs, titles: def.reward.titles,
          }, { kind: "Achievement", ref: id }, now);
          if (created.ok) { p.achievements[id] = now; unlocked.push(id); }
        }
      }
      return unlocked;
    };
    AchievementRules.view = (p) => Achievements.Order.map((id) => {
      const def = Achievements.ById[id];
      return { id, goal: def.goal, progress: Math.min(def.goal, AchievementRules.metric(p, def.metric)), unlockedAt: p.achievements[id], rewardId: AchievementRules.rewardId(id), rewardPending: !nil(p.rewards.pending[AchievementRules.rewardId(id)]) };
    });

    const HOME = "Hogar_H1";
    const FIRST_COLLECT_BONUS = 50;
    function first(p, analytics, name, now, fields) { if (!p.firsts[name]) { p.firsts[name] = now; analytics.push({ name, fields: fields || {} }); } }
    function track(p, analytics, event, amount, now) {
      if (amount <= 0) return;
      for (const questId of QuestRules.track(p, event, amount, now)) analytics.push({ name: "quest_completed", fields: { quest: questId } });
    }
    const secondsSinceStart = (p, now) => now - p.createdAt;
    function discovered(p, analytics, speciesId, via, now) {
      analytics.push({ name: "species_discovered", fields: { species: speciesId, via } });
      track(p, analytics, "SpeciesDiscovered", 1, now);
    }
    function finish(p, r, analytics, now) {
      const steps = OnboardingRules.refresh(p, now);
      const unlocked = AchievementRules.refresh(p, now);
      for (const id of unlocked) analytics.push({ name: "achievement_unlocked", fields: { achievement: id } });
      if (r.ok) { const data = r.data || {}; data.analytics = analytics; data.onboarding = steps; data.onboardingStep = p.onboarding.step; data.achievements = unlocked; r.data = data; }
      for (const s of steps) if (s === "tutorial_completed") analytics.push({ name: "tutorial_completed", fields: {} });
      return r;
    }
    Actions.onLoad = function (p, ctx) {
      p.loginCount += 1; p.lastLoginAt = ctx.now;
      const analytics = [];
      if (p.loginCount === 1) first(p, analytics, "onboarding_started", ctx.now);
      OnboardingRules.onLoad(p, ctx.now);
      if (QuestRules.refresh(p, ctx.now)) for (const q of p.quests.daily) analytics.push({ name: "quest_started", fields: { quest: q.questId, kind: "Daily" } });
      EggRules.refreshSlots(p);
      return finish(p, Result.ok({ step: p.onboarding.step }), analytics, ctx.now);
    };
    Actions.finishIntro = function (p, skipped, ctx) {
      const analytics = [];
      if (!p.firsts.intro_finished) analytics.push({ name: "intro_finished", fields: { skipped } });
      OnboardingRules.finishIntro(p, skipped, ctx.now);
      return finish(p, Result.ok(), analytics, ctx.now);
    };
    Actions.chooseStarter = function (p, eggId, ctx) {
      if (p.onboarding.step !== "ChooseEgg") return Result.fail("NotNow");
      if (PetRules.starterPet(p)) return Result.fail("StarterAlreadyChosen");
      const egg = Onboarding.StarterEggs.find((e) => e.eggId === eggId);
      if (!egg) return Result.fail("UnknownEgg");
      const speciesId = egg.speciesId;
      const created = PetRules.create(p, speciesId, { kind: "Starter", ref: eggId, at: ctx.now });
      if (!created.ok) return created;
      const petId = created.data.petId;
      PetRules.setCompanion(p, petId);
      const analytics = [];
      first(p, analytics, "starter_egg_selected", ctx.now, { egg: eggId, species: speciesId });
      if (CollectionRules.obtain(p, speciesId, "Brote", ctx.now).newSpecies) discovered(p, analytics, speciesId, "Starter", ctx.now);
      return finish(p, Result.ok({ petId, speciesId }), analytics, ctx.now);
    };
    Actions.ackHatch = function (p, ctx) {
      if (!PetRules.starterPet(p)) return Result.fail("NoStarter");
      const analytics = [];
      first(p, analytics, "hatch_completed", ctx.now);
      first(p, analytics, "pet_follow_started", ctx.now);
      return finish(p, Result.ok(), analytics, ctx.now);
    };
    Actions.visitHome = function (p, ctx) {
      const analytics = [{ name: "sanctuary_visit", fields: {} }];
      if (!PetRules.starterPet(p)) return finish(p, Result.ok({ gifted: false }), analytics, ctx.now);
      let gifted = false;
      if (!p.lots.Hogar.unlocked) {
        SanctuaryRules.unlockLot(p, "Hogar", ctx, FIRST_COLLECT_BONUS);
        const g = RewardRules.grant(p, "onboarding:gift", { bundleId: "OnboardingGift" }, { kind: "Onboarding", ref: "Gift" }, ctx);
        gifted = g.ok;
        first(p, analytics, "habitat_opened", ctx.now);
        analytics.push({ name: "unlock_granted", fields: { unlock: "LoteHogar" } });
      }
      return finish(p, Result.ok({ gifted }), analytics, ctx.now);
    };
    Actions.place = (p, petId, slot, ctx) => finish(p, SanctuaryRules.place(p, petId, HOME, slot, ctx), [], ctx.now);
    Actions.remove = (p, slot, ctx) => finish(p, SanctuaryRules.remove(p, HOME, slot, ctx), [], ctx.now);
    Actions.collect = function (p, ctx) {
      const r = SanctuaryRules.collect(p, HOME, ctx);
      const analytics = [];
      if (r.ok && r.data.coins > 0) { analytics.push({ name: "coins_collected", fields: { amount: r.data.coins } }); track(p, analytics, "CollectCoins", 1, ctx.now); }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.feed = function (p, petId, foodId, ctx) {
      const r = PetRules.feed(p, petId, foodId, ctx);
      const analytics = [];
      if (r.ok) {
        first(p, analytics, "first_feed", ctx.now, { food: foodId });
        if (r.data.bondGained > 0) first(p, analytics, "first_bond_gain", ctx.now, { via: "feed" });
        track(p, analytics, "Feed", 1, ctx.now);
        track(p, analytics, "PetXp", r.data.xpGained || 0, ctx.now);
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.play = function (p, petId, ctx) {
      const r = PetRules.play(p, petId, ctx);
      const analytics = [];
      if (r.ok && r.data.bondGained > 0) first(p, analytics, "first_bond_gain", ctx.now, { via: "play" });
      if (r.ok) track(p, analytics, "Play", 1, ctx.now);
      return finish(p, r, analytics, ctx.now);
    };
    Actions.evolve = function (p, petId, ctx) {
      const r = PetRules.evolve(p, petId, ctx);
      const analytics = [];
      if (r.ok) {
        const speciesId = p.pets[petId].speciesId;
        analytics.push({ name: "pet_evolved", fields: { species: speciesId } });
        first(p, analytics, "first_evolution", ctx.now, { seconds: secondsSinceStart(p, ctx.now) });
        const found = CollectionRules.obtain(p, speciesId, "Tallado", ctx.now, false);
        r.data.newCard = found.newCard; r.data.speciesId = speciesId;
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.setCompanion = (p, petId, ctx) => finish(p, PetRules.setCompanion(p, petId), [], ctx.now);
    Actions.setNickname = (p, petId, filtered, ctx) => finish(p, PetRules.setNickname(p, petId, filtered), [], ctx.now);
    Actions.buyFood = function (p, foodId, quantity, ctx) {
      const r = ShopRules.buyFood(p, foodId, quantity);
      const analytics = [];
      if (r.ok) analytics.push({ name: "food_purchased", fields: { food: foodId, quantity } });
      return finish(p, r, analytics, ctx.now);
    };
    Actions.canStartEncounter = function (p, encounterId) {
      if (p.onboarding.step !== "Done" && OnboardingRules.stepIndex(p.onboarding.step) < OnboardingRules.stepIndex("FirstBattle")) return Result.fail("FinishTutorialFirst");
      return EncounterRules.canStart(p, encounterId);
    };
    Actions.markBattleStarted = function (p, encounterId, ctx) {
      const enc = Encounters.ById[encounterId];
      const analytics = [
        { name: "battle_started", fields: { encounter: encounterId } },
        { name: "adventure_stage_started", fields: { stage: encounterId, kind: enc.stageType } },
      ];
      if (enc.stageType === "Jefe") analytics.push({ name: "guardian_battle_started", fields: { stage: encounterId } });
      first(p, analytics, "first_battle_started", ctx.now, { encounter: encounterId });
      for (const speciesId of EncounterRules.opponentsFor(p, encounterId)) if (CollectionRules.see(p, speciesId, ctx.now)) discovered(p, analytics, speciesId, "Seen", ctx.now);
      return analytics;
    };
    function stageCompleted(p, analytics, encounterId, data, ctx) {
      const enc = Encounters.ById[encounterId];
      analytics.push({ name: "adventure_stage_completed", fields: { stage: encounterId, firstClear: data.firstClear === true, kind: enc.stageType } });
      first(p, analytics, "first_stage_completed", ctx.now, { seconds: secondsSinceStart(p, ctx.now) });
      track(p, analytics, "StageCleared", 1, ctx.now);
      if ((data.newStars ?? 0) > 0) {
        for (let i = 0; i < data.newStars; i++) analytics.push({ name: "stage_star_earned", fields: { stage: encounterId } });
        track(p, analytics, "StarEarned", data.newStars, ctx.now);
      }
      for (const entryId of data.codex || []) analytics.push({ name: "codex_entry_unlocked", fields: { entry: entryId } });
      if (data.guardianRestored) analytics.push({ name: "guardian_defeated", fields: { guardian: data.guardianRestored } });
    }
    Actions.finishEncounter = function (p, encounterId, battleId, won, turns, participants, ctx, reason, summary) {
      const r = EncounterRules.applyResult(p, encounterId, battleId, won, participants, ctx, reason, summary);
      const analytics = [{ name: "battle_finished", fields: { encounter: encounterId, won, reason: reason || "Defeat", turns } }];
      if (r.ok) {
        first(p, analytics, "first_battle_completed", ctx.now, { encounter: encounterId, won });
        if (won) {
          const data = r.data, enc = Encounters.ById[encounterId];
          track(p, analytics, "BattleWon", 1, ctx.now);
          analytics.push({ name: "opaco_restored", fields: { stage: encounterId, amount: enc.opponents.length } });
          track(p, analytics, "OpacoRestored", enc.opponents.length, ctx.now);
          for (const speciesId of data.newSpecies || []) discovered(p, analytics, speciesId, "Restored", ctx.now);
          stageCompleted(p, analytics, encounterId, data, ctx);
        }
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.solveTreasure = function (p, encounterId, element, ctx) {
      const r = EncounterRules.solveTreasure(p, encounterId, element, ctx);
      const analytics = [];
      if (r.ok && r.data.solved) stageCompleted(p, analytics, encounterId, r.data, ctx);
      return finish(p, r, analytics, ctx.now);
    };
    Actions.claimReward = function (p, rewardId, ctx) {
      const r = RewardRules.claim(p, rewardId, ctx);
      const analytics = [];
      if (r.ok) {
        const data = r.data;
        first(p, analytics, "first_reward_claimed", ctx.now, { reward: rewardId, secondsSinceStart: ctx.now - p.createdAt });
        for (const u of data.newUnlocks) analytics.push({ name: "unlock_granted", fields: { unlock: u } });
        for (const chestId of data.chestIds || []) analytics.push({ name: "chest_obtained", fields: { chest: p.chests[chestId].chestType } });
        for (const eggId of data.eggIds || []) analytics.push({ name: "egg_obtained", fields: { species: p.eggs[eggId].speciesId } });
        let xp = 0;
        for (const res of Object.values(data.pets || {})) xp += res.xpGained || 0;
        track(p, analytics, "PetXp", xp, ctx.now);
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.openChest = function (p, chestId, ctx) {
      const r = ChestRules.open(p, chestId, ctx.now);
      const analytics = [];
      if (r.ok) {
        const data = r.data;
        analytics.push({ name: "chest_opened", fields: { chest: data.chestType } });
        for (const eggId of data.eggIds) analytics.push({ name: "egg_obtained", fields: { species: p.eggs[eggId].speciesId } });
        for (const entryId of data.codex) analytics.push({ name: "codex_entry_unlocked", fields: { entry: entryId } });
        track(p, analytics, "ChestOpened", 1, ctx.now);
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.startIncubation = function (p, eggId, slot, ctx) {
      const r = EggRules.startIncubation(p, eggId, slot, ctx.now);
      const analytics = [];
      if (r.ok) { analytics.push({ name: "incubation_started", fields: { species: p.eggs[eggId].speciesId } }); track(p, analytics, "IncubationStarted", 1, ctx.now); }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.hatchEgg = function (p, slot, ctx) {
      const r = EggRules.hatch(p, slot, ctx.now);
      const analytics = [];
      if (r.ok) {
        const data = r.data;
        analytics.push({ name: "incubation_completed", fields: { species: data.speciesId } });
        analytics.push({ name: "egg_hatched", fields: { species: data.speciesId, rarity: data.rarity } });
        first(p, analytics, "first_hatch", ctx.now, { seconds: secondsSinceStart(p, ctx.now) });
        if (PetRules.petCount(p) >= 2) first(p, analytics, "second_creature", ctx.now, { seconds: secondsSinceStart(p, ctx.now) });
        if (data.newSpecies) discovered(p, analytics, data.speciesId, "Hatch", ctx.now);
        track(p, analytics, "EggHatched", 1, ctx.now);
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.buyIncubatorSlot = (p, slot, ctx) => finish(p, EggRules.buySlot(p, slot), [], ctx.now);
    Actions.claimQuest = function (p, kind, index, ctx) {
      const r = QuestRules.claim(p, kind, index, ctx.now);
      const analytics = [];
      if (r.ok) {
        analytics.push({ name: "quest_claimed", fields: { quest: r.data.questId, kind } });
        if (r.data.chestType) analytics.push({ name: "chest_obtained", fields: { chest: r.data.chestType } });
      }
      return finish(p, r, analytics, ctx.now);
    };
    Actions.setTeam = function (p, petIds, ctx) {
      if (petIds.length === 0 || petIds.length > Sanctuary.MaxTeamSize) return Result.fail("BadTeamSize");
      const seen = {};
      for (const id of petIds) { if (!p.pets[id]) return Result.fail("PetNotOwned"); if (seen[id]) return Result.fail("DuplicatePet"); seen[id] = true; }
      p.team = petIds.slice();
      return finish(p, Result.ok({ team: p.team }), [], ctx.now);
    };
    const sanctuaryUpdated = (r, what) => (r.ok ? [{ name: "sanctuary_updated", fields: { change: what } }] : []);
    Actions.placeDecor = (p, slot, decorId, ctx) => { const r = DecorRules.place(p, slot, decorId); return finish(p, r, sanctuaryUpdated(r, "Decor"), ctx.now); };
    Actions.applyDecorTemplate = (p, id, ctx) => { const r = DecorRules.applyTemplate(p, id); return finish(p, r, sanctuaryUpdated(r, "Template"), ctx.now); };
    Actions.setShowcase = (p, petIds, ctx) => { const r = DecorRules.setShowcase(p, petIds); return finish(p, r, sanctuaryUpdated(r, "Showcase"), ctx.now); };
    Actions.expandInventory = (p, ctx) => { const r = DecorRules.expandInventory(p); return finish(p, r, sanctuaryUpdated(r, "Inventory"), ctx.now); };
    Actions.equipTitle = function (p, titleId, ctx) {
      if (titleId && !p.titles.owned[titleId]) return Result.fail("TitleNotOwned");
      setOrDelete(p.titles, "equipped", titleId);
      return finish(p, Result.ok({ title: titleId }), [], ctx.now);
    };

    // =================================================================
    // Guardado de la vista previa de la Fase 1 (localStorage v1) → perfil v1 de Luau
    // Después ProfileSchema.migrate aplica la migración 1→2 del servidor.
    // =================================================================
    function fromWebV1(old, now) {
      const t = (x) => Math.floor(x ?? now);
      const pets = {};
      for (const [id, pet] of Object.entries(old.pets || {})) {
        pets[id] = {
          id, speciesId: pet.speciesId, form: pet.form || "Brote", level: pet.level || 1, xp: pet.xp || 0, bond: pet.bond || 0,
          acquired: { kind: pet.source || "Starter", at: t(pet.acquiredAt) }, traits: standardTraits(), lineage: { generation: 0 },
          lastPlayedAt: Math.floor(pet.lastPlayedAt || 0), stats: { battlesWon: pet.wins || 0, battlesLost: 0, timesFed: 0 },
        };
        if (pet.nickname) pets[id].nickname = pet.nickname;
        if (pet.evolvedAt) pets[id].evolvedAt = t(pet.evolvedAt);
      }
      const cleared = {};
      for (const [id, c] of Object.entries(old.cleared || {})) cleared[id] = { firstClearAt: t(c.at), wins: c.wins || 1 };
      const pending = {};
      for (const [id, r] of Object.entries(old.pending || {})) {
        pending[id] = {
          id, title: r.title || "Recompensa", currencies: r.currencies || {}, items: r.items || {}, petXp: r.petXp || 0, petIds: r.petIds || [],
          unlocks: r.unlocks || [], source: { kind: id.startsWith("battle:") ? "Encounter" : "Onboarding", ref: id }, createdAt: t(old.createdAt),
        };
      }
      const ledger = {}, order = Object.entries(old.ledger || {}).sort((a, b) => a[1] - b[1]).map(([id]) => id);
      for (const id of order) ledger[id] = t(old.ledger[id]);
      const h = old.habitat || {};
      const data = {
        schemaVersion: 1, userId: 1, createdAt: t(old.createdAt), lastLoginAt: now, loginCount: old.logins || 0, playSeconds: 0,
        currencies: { Monedas: Math.floor(old.coins || 0), Gemas: Math.floor(old.gems || 0) }, items: Object.assign({}, old.items || {}),
        pets, nextPetSerial: old.serial || 1, team: old.companion ? [old.companion] : [], inventoryCapacity: Sanctuary.InventoryCapacity,
        lots: { Hogar: { unlocked: !!old.lotUnlocked, habitats: { Hogar_H1: { id: HOME, slots: (h.slots || [false, false, false, false]).map((x) => x || false), level: 1, lastCollectAt: t(h.last), accrued: Math.floor(h.accrued || 0), bonusCoins: Math.floor(h.bonus || 0) } } } },
        story: { cleared, repeatDay: (old.repeat && old.repeat.day) || 0, repeatCount: (old.repeat && old.repeat.count) || 0 },
        onboarding: { step: old.step || "Intro", completed: !!old.completed, startedAt: t(old.createdAt) },
        unlocks: {}, rewards: { pending, ledger, ledgerOrder: order }, firsts: {}, counters: {},
      };
      for (const [k, v] of Object.entries(old.items || {})) if (!v) delete data.items[k];
      for (const [k, v] of Object.entries(old.unlocks || {})) data.unlocks[k] = t(v);
      for (const [k, v] of Object.entries(old.firsts || {})) data.firsts[k] = t(v);
      if (old.companion) data.companionPetId = old.companion;
      if (old.introSkipped !== undefined) data.onboarding.introSkipped = !!old.introSkipped;
      return data;
    }
    ProfileSchema.fromWebV1 = fromWebV1;

    return {
      Result, ProfileSchema, PetRules, SanctuaryRules, OnboardingRules, ShopRules, CollectionRules, EggRules, ChestRules,
      QuestRules, DecorRules, HistoryRules, RewardRules, EncounterRules, AchievementRules, Actions,
    };
  }

  const api = { createDomain };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root.NexoraDomain = api;
})(typeof globalThis !== "undefined" ? globalThis : this);

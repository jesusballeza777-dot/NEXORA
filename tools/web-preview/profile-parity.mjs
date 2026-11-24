// Paridad de PERFIL Luau ↔ JS: repite los recorridos de profile_parity.luau con
// src/domain.js + src/engine.js y exige el mismo perfil después de CADA paso
// (monedas, objetos, monstruos, huevos, incubadora, cofres, encargos, estrellas,
// colección, Códice, decoración, recompensas, historial…).
//   lune run tools/web-preview/profile_parity && node tools/web-preview/profile-parity.mjs
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { createEngine } = require("./src/engine.js");
const { createDomain } = require("./src/domain.js");
const { normalizeConfig } = require("./src/normalize.js");

const CFG = normalizeConfig(JSON.parse(readFileSync("build/web/config.json", "utf8")));
const ENG = createEngine(CFG);
const D = createDomain(CFG, ENG);
const { Actions, ProfileSchema, PetRules, EncounterRules } = D;
const { BattleEngine: BE, BattleAI: AI } = ENG;
const scenarios = JSON.parse(readFileSync("build/web/profile_parity_luau.json", "utf8"));

// Forma canónica: sin nil, {} ≡ [] (Lune exporta tablas vacías como {}), claves ordenadas
function canon(v) {
  if (v === null || v === undefined) return undefined;
  if (Array.isArray(v)) return v.length === 0 ? {} : v.map((x) => (x === null || x === undefined ? null : canon(x)));
  if (typeof v === "object") {
    const out = {};
    for (const k of Object.keys(v).sort()) { const c = canon(v[k]); if (c !== undefined) out[k] = c; }
    return out;
  }
  return v;
}
const canonStr = (v) => JSON.stringify(canon(v));
function diff(a, b, path = "", out = []) {
  if (out.length >= 8) return out;
  if (typeof a !== typeof b || (a && b && typeof a === "object" && Array.isArray(a) !== Array.isArray(b))) { out.push(`${path}: Luau=${JSON.stringify(a)} JS=${JSON.stringify(b)}`); return out; }
  if (a && typeof a === "object") {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) diff(a[k], b[k], `${path}.${k}`, out);
  } else if (a !== b) out.push(`${path}: Luau=${JSON.stringify(a)} JS=${JSON.stringify(b)}`);
  return out;
}

const V2_KEYS = ["collection", "eggs", "nextEggSerial", "incubators", "chests", "nextChestSerial", "history", "quests", "codex", "decor", "showcase", "titles", "frames", "guardians", "achievements"];
const tos = (v) => (v === undefined || v === null ? "nil" : String(v));
const res = (r, extra = "") => `${tos(r.ok)}|${tos(r.err)}${extra}`;

function run(sc) {
  let p = null, now = sc.t0;
  const vars = {}, snapshots = [], results = [];
  const ctx = () => ({ now });
  const pet = (ref) => vars[ref] || ref;
  for (const step of sc.steps) {
    let out = "";
    switch (step.op) {
      case "new": p = ProfileSchema.new(step.userId, now); break;
      case "advance": now += step.s; break;
      case "onLoad": out = res(Actions.onLoad(p, ctx())); break;
      case "finishIntro": out = res(Actions.finishIntro(p, step.skipped, ctx())); break;
      case "chooseStarter": { const r = Actions.chooseStarter(p, step.egg, ctx()); if (r.ok) vars.starter = r.data.petId; out = res(r); break; }
      case "ackHatch": out = res(Actions.ackHatch(p, ctx())); break;
      case "visitHome": out = res(Actions.visitHome(p, ctx())); break;
      case "place": out = res(Actions.place(p, pet(step.pet), step.slot, ctx())); break;
      case "collect": { const r = Actions.collect(p, ctx()); out = res(r, r.ok ? "|" + tos(r.data.coins) : ""); break; }
      case "feed": out = res(Actions.feed(p, pet(step.pet), step.food, ctx())); break;
      case "play": out = res(Actions.play(p, pet(step.pet), ctx())); break;
      case "evolve": out = res(Actions.evolve(p, pet(step.pet), ctx())); break;
      case "buyFood": out = res(Actions.buyFood(p, step.food, step.qty, ctx())); break;
      case "devPet": { const r = PetRules.create(p, step.species, { kind: "Dev", at: now }); if (r.ok) vars[step.as] = r.data.petId; out = res(r); break; }
      case "boost": { const pt = p.pets[pet(step.pet)]; pt.level = step.level; pt.xp = 0; if (step.form) pt.form = step.form; if (step.bond) pt.bond = step.bond; break; }
      case "grantCoins": p.currencies.Monedas += step.n; break;
      case "setTeam": out = res(Actions.setTeam(p, step.pets.map(pet), ctx())); break;
      case "encounter": {
        const can = Actions.canStartEncounter(p, step.id);
        if (!can.ok) { out = res(can); break; }
        Actions.markBattleStarted(p, step.id, ctx());
        const state = BE.new(EncounterRules.buildSetup(p, step.id, step.battle, step.seed));
        let guard = 0;
        while (state.phase !== "Ended") {
          if (++guard >= 200) throw new Error("combate sin fin");
          BE.submit(state, 1, step.forfeit ? { kind: "Forfeit" } : { kind: "Move", moveId: AI.choose(state, 1, "Normal") });
          BE.submit(state, 2, { kind: "Move", moveId: AI.choose(state, 2, state.sides[1].ai) });
          BE.resolveTurn(state);
        }
        const won = state.outcome.winner === 1;
        const r = Actions.finishEncounter(p, step.id, step.battle, won, state.turn, EncounterRules.participantsFor(p, step.id), ctx(), state.outcome.reason, BE.summary(state));
        out = res(r, `|${won}|${state.turn}`);
        break;
      }
      case "treasure": { const r = Actions.solveTreasure(p, step.id, step.element, ctx()); out = res(r, r.ok ? "|" + tos(r.data.solved) : ""); break; }
      case "claimAll": out = Object.keys(p.rewards.pending).sort().map((id) => id + ":" + res(Actions.claimReward(p, id, ctx()))).join(","); break;
      case "openChests": out = Object.keys(p.chests).sort().map((id) => id + ":" + res(Actions.openChest(p, id, ctx()))).join(","); break;
      case "incubate": { const eggId = Object.keys(p.eggs).sort().find((id) => p.eggs[id].state === "Stored"); out = eggId ? res(Actions.startIncubation(p, eggId, step.slot, ctx())) : "noegg"; break; }
      case "hatch": out = res(Actions.hatchEgg(p, step.slot, ctx())); break;
      case "buySlot": out = res(Actions.buyIncubatorSlot(p, step.slot, ctx())); break;
      case "claimQuests": {
        const parts = [];
        for (let i = 1; i <= p.quests.daily.length; i++) parts.push(res(Actions.claimQuest(p, "Daily", i, ctx())));
        parts.push(res(Actions.claimQuest(p, "Weekly", 1, ctx())));
        out = parts.join(",");
        break;
      }
      case "placeDecor": out = res(Actions.placeDecor(p, step.slot, step.decor, ctx())); break;
      case "template": out = res(Actions.applyDecorTemplate(p, step.id, ctx())); break;
      case "showcase": out = res(Actions.setShowcase(p, step.pets.map(pet), ctx())); break;
      case "expand": out = res(Actions.expandInventory(p, ctx())); break;
      case "equipTitle": out = res(Actions.equipTitle(p, step.title, ctx())); break;
      case "legacy": {
        for (const k of V2_KEYS) delete p[k];
        p.story = { cleared: p.story.cleared, repeatDay: p.story.repeatDay, repeatCount: p.story.repeatCount };
        p.schemaVersion = 1;
        p = ProfileSchema.migrate(p, now);
        const [ok, why] = ProfileSchema.validate(p);
        out = `${ok}|${tos(why)}`;
        break;
      }
      default: throw new Error("paso desconocido: " + step.op);
    }
    results.push(out);
    snapshots.push(JSON.parse(JSON.stringify(p)));
  }
  return { results, snapshots };
}

let failures = 0, total = 0;
for (const sc of scenarios) {
  const js = run(sc);
  let bad = -1;
  for (let i = 0; i < sc.steps.length; i++) {
    total++;
    const a = canon(JSON.parse(sc.snapshots[i])), b = canon(js.snapshots[i]);
    if (sc.results[i] !== js.results[i] || JSON.stringify(a) !== JSON.stringify(b)) { bad = i; break; }
  }
  if (bad >= 0) {
    failures++;
    const step = sc.steps[bad];
    console.error(`✗ ${sc.name}: difiere en el paso ${bad + 1} (${JSON.stringify(step)})`);
    if (sc.results[bad] !== js.results[bad]) console.error(`  resultado Luau: ${sc.results[bad]}\n  resultado JS:   ${js.results[bad]}`);
    for (const d of diff(canon(JSON.parse(sc.snapshots[bad])), canon(js.snapshots[bad]))) console.error("  " + d);
  } else {
    const last = canonStr(js.snapshots[js.snapshots.length - 1]);
    console.log(`✓ ${sc.name}: ${sc.steps.length} pasos idénticos (perfil final ${Math.round(last.length / 1024)} KB)`);
  }
}
console.log(`Paridad de perfil Luau ↔ JS: ${scenarios.length - failures}/${scenarios.length} recorridos idénticos`);
process.exit(failures === 0 ? 0 : 1);

// Comprueba que el motor JS de la vista previa produce EXACTAMENTE los mismos
// combates que el motor Luau (misma semilla → mismos eventos, daños y ganador).
//   node tools/web-preview/parity.mjs
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { createEngine } = require("./src/engine.js");
const { normalizeConfig } = require("./src/normalize.js");

const config = normalizeConfig(JSON.parse(readFileSync("build/web/config.json", "utf8")));
const cases = JSON.parse(readFileSync("build/web/parity_luau.json", "utf8"));
const { BattleEngine: BE, BattleAI: AI } = createEngine(config);

let failures = 0;
for (const c of cases) {
  const state = BE.new(c.setup);
  const ai = c.setup.sides[1].ai;
  while (state.phase !== "Ended") {
    BE.submit(state, 1, { kind: "Move", moveId: AI.choose(state, 1, "Normal") });
    BE.submit(state, 2, { kind: "Move", moveId: AI.choose(state, 2, ai) });
    BE.resolveTurn(state);
  }
  const str = (v) => (v === undefined || v === null ? "nil" : typeof v === "boolean" ? String(v) : String(v));
  const log = state.log
    .map((e) => `${str(e.t)}:${str(e.target ?? e.actor ?? e.to)}:${str(e.amount ?? e.move ?? e.status ?? e.phase)}:${str(e.hp)}`)
    .join("|");
  if (log !== c.log || state.outcome.winner !== c.winner) {
    failures++;
    if (failures <= 3) {
      const a = log.split("|"), b = c.log.split("|");
      const i = a.findIndex((x, k) => x !== b[k]);
      const who = c.setup.sides.map((sd) => sd.team.map((t) => t.speciesId).join("+")).join(" vs ");
      console.error(`✗ ${who} semilla ${c.setup.seed}: difiere en el evento ${i}\n  JS:   ${a[i]}\n  Luau: ${b[i]}`);
    }
  }
}
console.log(`Paridad Luau ↔ JS: ${cases.length - failures}/${cases.length} combates idénticos`);
process.exit(failures === 0 ? 0 : 1);

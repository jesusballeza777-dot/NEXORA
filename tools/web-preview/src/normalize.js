/*
 * La exportación JSON de Lune convierte tablas vacías de Luau en {} (objeto).
 * Aquí se restauran como listas los campos que el motor recorre como arreglos.
 */
(function (root) {
  "use strict";
  const asArray = (v) => (Array.isArray(v) ? v : v && typeof v === "object" && Object.keys(v).length === 0 ? [] : v || []);
  function normalizeConfig(cfg) {
    for (const m of Object.values(cfg.Abilities.ById)) {
      m.effects = asArray(m.effects);
      for (const e of m.effects) if (e.statuses) e.statuses = asArray(e.statuses);
    }
    for (const s of Object.values(cfg.Species.ById)) s.elements = asArray(s.elements);
    for (const t of Object.values(cfg.Talents.ById)) if (t.elements) t.elements = asArray(t.elements);
    for (const r of Object.values(cfg.Rewards.ById)) r.unlocks = asArray(r.unlocks);
    // Fase 2: etapas sin rivales (Tesoro), sin requisitos (primera) y listas opcionales
    for (const e of Object.values(cfg.Encounters.ById)) {
      e.opponents = asArray(e.opponents);
      e.requires = asArray(e.requires);
      if (e.firstClearCodex) e.firstClearCodex = asArray(e.firstClearCodex);
    }
    if (cfg.Chests) for (const c of Object.values(cfg.Chests.ById)) if (c.fixed) c.fixed.eggs = asArray(c.fixed.eggs);
    return cfg;
  }
  const api = { normalizeConfig };
  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root.NexoraNormalize = api;
})(typeof globalThis !== "undefined" ? globalThis : this);

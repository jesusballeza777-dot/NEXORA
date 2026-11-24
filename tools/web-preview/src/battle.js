
// =====================================================================
// Combate PvE (mismo motor que el servidor; aquí el "servidor" es domain.js)
// Equipos de hasta 3 con sustitución, raíces que curan (y se cortan con golpes
// eficaces) y Copalia con entrada, fase 2 (faroles apagados) y restauración.
// Las etapas del mapa sin marcador se juegan en el marcador de la Linde de su región.
// =====================================================================
let battle = null;
const battleRng = new ENG.Rng(Date.now() % 2147483646);
let battleSerial = 0;
const BASE_LIGHT = { hemi: hemi.intensity, sun: sun.intensity, exposure: renderer.toneMappingExposure };
function arenaFor(enc) {
  if (enc.worldMarker) return { pos: encounterSpots[enc.id].pos.clone(), spot: encounterSpots[enc.id] };
  const marker = "Encounter" + clamp(enc.region, 1, 3);
  const worldId = WORLD_ENCOUNTERS.find((id) => CFG.Encounters.ById[id].worldMarker === marker);
  return { pos: v3(W.Encounters[marker].position), spot: worldId ? encounterSpots[worldId] : null };
}
const sideOf = (uid) => (uid.startsWith("S1") ? 1 : 2);
const combatant = (uid) => [...battle.state.sides[0].team, ...battle.state.sides[1].team].find((c) => c.uid === uid);
function nameOf(uid) { return combatant(uid)?.name || ""; }
// Modelo 3D de un combatiente (se construye al entrar)
function ensureModel(c) {
  if (battle.byUid[c.uid]) return battle.byUid[c.uid];
  let m;
  if (c.side === 1 && c.petId === P.companionPetId && companionModel) m = companionModel;
  else if (c.side === 2 && c.slot === 1 && battle.spot && battle.spot.creature && battle.enc.worldMarker) m = battle.spot.creature;
  else { m = buildCreature(c.speciesId, c.form, c.isOpaco); scene.add(m); m.userData.temp = true; }
  m.visible = true;
  battle.byUid[c.uid] = m; battle.models.push(m);
  if (c.rootHeal != null) addRootRing(c.uid, m);
  return m;
}
function activeModel(side) { return ensureModel(BE.active(battle.state, side)); }
function placeActive(side) {
  const m = activeModel(side), mine = side === 1;
  m.position.copy(mine ? battle.home.me : battle.home.foe);
  const other = mine ? battle.home.foe : battle.home.me;
  faceTo(m, other.x, other.z);
  return m;
}
// Raíces del Valle: anillo de raíces que cura al Opaco hasta que un golpe eficaz lo corta
function addRootRing(uid, model) {
  const g = new THREE.Group();
  const bark = mat(0x6a4a3a, { rough: 0.95 }), leaf = mat(0x6fbf5a, { emissive: 0x2f7a2a, ei: 0.5 });
  mesh(new THREE.TorusGeometry(1.7, 0.18, 6, 28), bark, V(0, 0.15, 0), null, [Math.PI / 2, 0, 0], g);
  for (let k = 0; k < 7; k++) {
    const a = (k / 7) * Math.PI * 2;
    const r = mesh(new THREE.ConeGeometry(0.14, 1.4, 6), bark, V(Math.cos(a) * 1.7, 0.6, Math.sin(a) * 1.7), null, [Math.sin(a) * 0.5, 0, -Math.cos(a) * 0.5], g);
    mesh(GEO.sphereLow, leaf, V(0, 0.75, 0), V(0.22, 0.14, 0.22), null, r, false);
  }
  model.add(g);
  battle.roots[uid] = g;
}
function cutRoots(uid, withered) {
  const g = battle.roots[uid]; if (!g) return;
  delete battle.roots[uid];
  const m = battle.byUid[uid];
  if (m) { const p = m.position.clone().add(V(0, 0.6, 0)); vfx.chunks(p, 0x6a4a3a, 10); vfx.ring(p, withered ? 0x9a8a70 : 0x7bd66a, 7, 0.7); }
  const t0 = performance.now();
  const step = () => { const k = Math.min(1, (performance.now() - t0) / (500 / ANIM)); g.scale.setScalar(1 - k); if (k < 1) requestAnimationFrame(step); else g.parent?.remove(g); };
  step();
}
async function startBattle(encId) {
  if (battle) return;
  const can = DOM.Actions.canStartEncounter(P, encId);
  if (!can.ok) { toast("⚠️", errText(can.err)); return; }
  if (!companionModel && P.firsts.hatch_completed) syncCreatures();
  const enc = CFG.Encounters.ById[encId];
  const seed = 1 + Math.floor(battleRng.next() * 2147483640);
  const battleId = `web-${serverNow()}-${++battleSerial}`;
  DOM.Actions.markBattleStarted(P, encId, ctx()); save();
  const participants = EncounterRules.participantsFor(P, encId);
  const state = BE.new(EncounterRules.buildSetup(P, encId, battleId, seed));
  const arena = arenaFor(enc);
  const foe0 = state.sides[1].team[0];
  const boss = foe0.guardianId ? guardian(foe0.guardianId) : null;
  const center = arena.pos;
  battle = {
    state, encId, enc, participants, center, spot: arena.spot, busy: false, boss, byUid: {}, models: [], roots: {}, light: 1, lightTarget: 1,
    prevStars: (P.story.stars[encId] || [false, false, false]).slice(),
  };
  // Encuadre: en pantallas verticales (móvil) los rivales se escalonan en profundidad
  const tall = innerWidth < innerHeight;
  battle.home = tall
    ? { me: center.clone().add(boss ? V(-2.5, 0, 3) : V(-2, 0, 2.5)), foe: center.clone().add(boss ? V(3, 0, -5) : V(2.2, 0, -3)) }
    : { me: center.clone().add(V(-4.5, 0, 2.5)), foe: center.clone().add(boss ? V(7, 0, -5) : V(4.5, 0, -2)) };
  // El Opaco del marcador (si lo hay) se aparta mientras dura el combate de otra etapa
  if (arena.spot && arena.spot.creature && !enc.worldMarker) arena.spot.creature.visible = false;
  if (companionModel) companionModel.visible = false; // vuelve a verse si entra al combate
  placeActive(1); const foeModel = placeActive(2);
  player.position.copy(center.clone().add(V(-9, 0, 6)));
  heading = Math.atan2(battle.home.foe.x - player.position.x, battle.home.foe.z - player.position.z);
  cineCam = tall
    ? (boss ? { pos: center.clone().add(V(0, 13, 34)), look: center.clone().add(V(0, 2, -3)) } : { pos: center.clone().add(V(0, 13, 30)), look: center.clone().add(V(0, 0, -1)) })
    : (boss ? { pos: center.clone().add(V(-3, 11, 24)), look: center.clone().add(V(1, 5, -1)) } : { pos: center.clone().add(V(-1, 6.5, 13)), look: center.clone().add(V(0, 1.6, 0)) });
  // Corte de cámara al escenario (el jefe entra con un barrido desde lo alto)
  camPos.copy(boss ? center.clone().add(V(-8, 34, 56)) : cineCam.pos); camTarget.copy(cineCam.look);
  if (arena.spot) arena.spot.label.el.innerHTML = "";
  inputLocked = true; cine = true;
  ["#companion", "#objective", "#dock", "#joystick", "#help", "#prompt"].forEach((s) => $(s).classList.add("hidden"));
  $("#battle").classList.remove("hidden");
  if (boss) await guardianEntrance(boss, foeModel);
  const foes = state.sides[1].team;
  renderBattle(boss ? `${esc(boss.shortName)} despierta opacada: ¡devuélvele su color!` : foes.length > 1 ? `¡${foes.length} Opacos aparecen entre la niebla! Uno tras otro.` : `¡Un ${esc(foes[0].name)} aparece entre la niebla!`);
}
// Entrada del Ser Sagrado: sale de la tierra entre raíces, con su cartel
async function guardianEntrance(g, model) {
  battle.busy = true;
  const base = model.position.clone();
  model.position.y = -9;
  $("#battle").innerHTML = `<div class="boss-banner"><div class="bb-kicker">Ser Sagrado · ${esc(g.epithet)}</div><div class="bb-name">${esc(g.name)}</div><div class="bb-text">${esc(g.opacado)}</div><div class="bb-rule">🌱 ${esc(g.talentName)}: ${esc(g.talentText)}</div></div>`;
  const t0 = performance.now(), dur = 2600 / ANIM;
  await new Promise((res) => {
    const step = () => {
      const k = Math.min(1, (performance.now() - t0) / dur), e = 1 - Math.pow(1 - k, 3);
      model.position.y = lerp(-9, 0, e);
      if (Math.random() < 0.5) vfx.burst(base.clone().add(V((Math.random() - 0.5) * 6, 0.5, (Math.random() - 0.5) * 6)), 0x8a6a46, 2, 5, { up: 1, grav: 10, life: 0.8, normal: true });
      if (k < 1) requestAnimationFrame(step); else res();
    };
    step();
  });
  vfx.ring(base.clone().add(V(0, 1, 0)), 0xffc460, 14, 1);
  await sleep(1400);
  battle.busy = false;
}
const cardHtml = (c, mine) => {
  const pct = (c.hp / c.maxHp) * 100, cls = pct < 25 ? "low" : pct < 55 ? "mid" : "";
  const acc = battle.state.field.accuracy[c.side - 1];
  const st = Object.keys(c.statuses).filter((k) => c.statuses[k] > 0).map((k) => `<span>${STATUS_TXT[k] || k}</span>`).join("") +
    c.mods.map((m) => `<span>${STAT_TXT[m.stat] || m.stat} ${m.amount > 0 ? "▲" : "▼"}</span>`).join("") + (c.shield ? `<span>🛡 ${c.shield.amount}</span>` : "") +
    (c.rootHeal != null ? `<span class="root">🌱 Raíces ${Math.round(c.rootHeal * 100)} %</span>` : "") + (acc < 0 ? `<span class="dim">🏮 Precisión ${Math.round(acc * 100)} %</span>` : "");
  return `<div class="nm"><span>${esc(c.name)}</span><span style="font-size:13px;color:var(--muted)">Nv ${c.level}</span></div>${elementBadges(c.elements)}
    <div class="bar hp ${cls}"><i style="width:${pct}%"></i></div><div class="hpnum"><span>${Math.max(0, c.hp)} / ${c.maxHp} PV</span>${mine ? `<span class="savia">Savia ${[0, 1, 2].map((k) => `<i class="${k < c.savia ? "on" : ""}"></i>`).join("")}</span>` : ""}</div><div class="status-row">${st}</div>`;
};
// Equipo restante de cada lado (miniaturas con su vida)
const rosterHtml = (side) => {
  const s = battle.state.sides[side - 1];
  if (s.team.length < 2) return "";
  return `<div class="roster">${s.team.map((c, i) => `<span class="rs ${c.fainted ? "out" : ""} ${i === s.active ? "on" : ""}" title="${esc(c.name)}"><img src="${portrait(c.speciesId, c.form)}" alt=""><i style="width:${Math.max(0, (c.hp / c.maxHp) * 100)}%"></i></span>`).join("")}</div>`;
};
function renderBattle(caption) {
  const s = battle.state, me = BE.active(s, 1), foe = BE.active(s, 2);
  const opts = s.phase === "Ended" ? [] : BE.availableMoves(s, 1);
  $("#battle").innerHTML = `
    <div class="foe panel">${cardHtml(foe, false)}${rosterHtml(2)}</div>
    <div class="me panel">${cardHtml(me, true)}${rosterHtml(1)}</div>
    <button class="btn secondary small flee" id="flee">Huir</button>
    ${battle.stageLabel !== false ? `<div class="stage-tag">${esc(battle.enc.name)}${s.turn ? ` · turno ${s.turn}` : ""}</div>` : ""}
    ${caption ? `<div class="caption panel">${caption}</div>` : ""}
    <div class="moves">${opts.map((o) => { const mv = ability(o.moveId), ec = CFG.Elements.ById[mv.element].color; const eff = mv.power > 0 ? ElementChart.classify(ElementChart.multiplier(mv.element, foe.elements, mv.kind === "Nexo")) : "Neutral"; const kind = { Basic: "Básico · +1 Savia", Special: "Especial", Signature: "Firma", Nexo: "Golpe Nexo" }[mv.kind];
      return `<button class="move" data-move="${o.moveId}" ${o.usable && !battle.busy ? "" : "disabled"} style="background:linear-gradient(180deg, ${css(ec.map((x) => Math.min(255, x + 40)))}, ${css(ec)})" title="${esc(mv.text)}">
      <div class="mn">${ELEMENT_ICON[mv.element]} ${esc(mv.name)}</div><div class="mm">${kind}${mv.power ? " · " + mv.power : ""}</div>${eff === "Strong" ? `<span class="eff">▲ Eficaz${foe.rootHeal != null ? " · corta raíces" : ""}</span>` : eff === "Weak" ? '<span class="eff">▼ Poco</span>' : ""}
      <span class="cost">${"<i></i>".repeat(o.cost)}</span></button>`; }).join("")}</div>`;
  $("#battle").querySelectorAll("[data-move]").forEach((b) => b.addEventListener("click", () => playTurn(b.dataset.move)));
  $("#flee").addEventListener("click", () => playTurn(null));
}
async function lunge(model, toward) {
  const from = model.position.clone(), dir = toward.clone().sub(from).setY(0).normalize();
  for (let k = 0; k <= 10; k++) { model.position.copy(from).addScaledVector(dir, Math.sin((k / 10) * Math.PI) * 3.2); await sleep(16); }
  model.position.copy(from);
}
async function hitShake(model) { const from = model.position.clone(); for (let k = 0; k < 8; k++) { model.position.x = from.x + (k % 2 ? 0.35 : -0.35); await sleep(22); } model.position.copy(from); }
async function swapIn(e) {
  const side = e.side, out = battle.byUid[e.from];
  if (out) {
    const t0 = performance.now(), s0 = out.scale.x;
    await new Promise((res) => { const step = () => { const k = Math.min(1, (performance.now() - t0) / (350 / ANIM)); out.scale.setScalar(s0 * (1 - k * 0.9)); if (k < 1) requestAnimationFrame(step); else res(); }; step(); });
    out.visible = false; out.scale.setScalar(s0);
  }
  const m = placeActive(side);
  m.visible = true;
  const s1 = m.scale.x; m.scale.setScalar(s1 * 0.1);
  vfx.ring(m.position.clone().add(V(0, 1, 0)), side === 1 ? 0xffd27a : 0xb9b9c4, 6, 0.6);
  const t1 = performance.now();
  await new Promise((res) => { const step = () => { const k = Math.min(1, (performance.now() - t1) / (420 / ANIM)); m.scale.setScalar(s1 * (0.1 + 0.9 * (1 - Math.pow(1 - k, 3)))); if (k < 1) requestAnimationFrame(step); else res(); }; step(); });
}
function setLights(f) { battle.lightTarget = f; }
async function phaseTransition(e) {
  const g = battle.boss;
  $("#battle").insertAdjacentHTML("beforeend", `<div class="boss-banner phase"><div class="bb-kicker">Fase ${e.phase}</div><div class="bb-name">Faroles apagados</div><div class="bb-text">${esc(e.text)}</div></div>`);
  setLights(0.42);
  const m = battle.byUid[e.target];
  if (m && m.userData.parts.lanterns) m.userData.parts.lanterns.forEach((lm) => { lm.emissiveIntensity = 0.12; });
  if (m) vfx.burst(m.position.clone().add(V(0, 6, 0)), 0x555566, 30, 6, { life: 1.4, size: 1.6, normal: true });
  await sleep(2600);
  $("#battle .boss-banner.phase")?.remove();
  void g;
}
async function guardianRestored(m) {
  const g = battle.boss;
  setLights(1.15);
  if (m.userData.parts.lanterns) m.userData.parts.lanterns.forEach((lm) => { lm.emissiveIntensity = 2.6; });
  $("#battle").insertAdjacentHTML("beforeend", `<div class="boss-banner restored"><div class="bb-kicker">Ser Sagrado restaurado</div><div class="bb-name">¡${esc(g.shortName)} recupera su color!</div><div class="bb-text">${esc(g.restoreBonus)}</div></div>`);
  const at = m.position.clone();
  for (let k = 0; k < 6; k++) { for (const c of [0xe84a6e, 0xfaba32, 0x40aad6, 0x68be60, 0x9660de, 0xffd27a]) vfx.burst(at.clone().add(V(0, 4 + k, 0)), c, 6, 10, { life: 1.6, size: 1.1, grav: 3 }); vfx.ring(at.clone().add(V(0, 1 + k * 1.5, 0)), 0xffe08a, 10 + k * 2, 1.1); await sleep(260); }
  await sleep(1500);
}
let lastMoveElement = null;
async function playTurn(moveId) {
  if (!battle || battle.busy || battle.state.phase === "Ended") return;
  const s = battle.state;
  battle.busy = true;
  BE.submit(s, 1, moveId ? { kind: "Move", moveId } : { kind: "Forfeit" });
  BE.submit(s, 2, { kind: "Move", moveId: AI.choose(s, 2, s.sides[1].ai) });
  const events = BE.resolveTurn(s);
  renderBattle();
  for (const e of events) {
    let cap = null;
    if (e.t === "Move") {
      const mv = ability(e.move), side = sideOf(e.actor), from = battle.byUid[e.actor] || activeModel(side), to = activeModel(side === 1 ? 2 : 1);
      cap = `${esc(nameOf(e.actor))} usa <b>${esc(mv.name)}</b>`; renderBattle(cap);
      const ec = mv.element ? col(CFG.Elements.ById[mv.element].color).getHex() : 0xffffff;
      if (mv.power > 0 && mv.kind !== "Basic") { vfx.burst(from.position.clone().add(V(0, 2, 0)), ec, 16, 4, { life: 0.6 }); await vfx.projectile(from.position.clone().add(V(0, 2.2, 0)), to.position.clone().add(V(0, 1.8, 0)), ec, 0.45 / ANIM); }
      else if (mv.power > 0) await lunge(from, to.position);
      else { vfx.sparkle(from.position.clone().add(V(0, 2, 0)), ec); await sleep(450); }
      lastMoveElement = mv.element;
      continue;
    }
    const tm = e.target ? battle.byUid[e.target] : null;
    if (e.t === "Damage" && tm) { vfx.element(e.move === "ConfusionSelfHit" ? null : lastMoveElement, tm.position.clone().add(V(0, 1.8, 0))); floater(tm.position.clone().add(V(0, 4, 0)), `-${e.amount}`, e.crit ? "crit" : e.eff === "Strong" ? "strong" : e.eff === "Weak" ? "weak" : ""); hitShake(tm); cap = e.crit ? "¡Golpe crítico!" : e.eff === "Strong" ? "¡Es muy eficaz!" : e.eff === "Weak" ? "No es muy eficaz…" : null; }
    else if (e.t === "Heal" && tm) { floater(tm.position.clone().add(V(0, 4, 0)), `+${e.amount}`, "heal"); vfx.burst(tm.position.clone().add(V(0, 1, 0)), 0x8ff0b4, 18, 3, { up: 1.5, grav: -3, life: 1.1 }); if (!battle.rootTick) cap = `${esc(nameOf(e.target))} recupera vida`; battle.rootTick = false; }
    else if (e.t === "Roots") { battle.rootTick = true; cap = `🌱 Las raíces curan a ${esc(nameOf(e.target))}`; if (tm) vfx.burst(tm.position.clone().add(V(0, 0.4, 0)), 0x7bd66a, 14, 3, { up: 2, grav: -2, life: 1 }); renderBattle(cap); await sleep(450); continue; }
    else if (e.t === "RootsCut") { cutRoots(e.target, false); cap = `✂️ ¡Raíces cortadas! ${esc(nameOf(e.target))} ya no se cura.`; }
    else if (e.t === "RootsEnd") { cutRoots(e.target, true); cap = `Las raíces de ${esc(nameOf(e.target))} se secan`; }
    else if (e.t === "Phase") { renderBattle(); await phaseTransition(e); cap = null; }
    else if (e.t === "Field") cap = e.side === 1 ? `🏮 La luz se apaga: tu equipo pierde ${Math.round(-e.accuracy * 100)} % de precisión` : null;
    else if (e.t === "Switch") { await swapIn(e); cap = e.side === 1 ? `¡Adelante, ${esc(nameOf(e.to))}!` : `Otro Opaco entra: ${esc(nameOf(e.to))}`; }
    else if (e.t === "Status") cap = `${esc(nameOf(e.target))}: ${STATUS_TXT[e.status] || e.status}`;
    else if (e.t === "StatusTick" && tm) { floater(tm.position.clone().add(V(0, 4, 0)), `-${e.amount}`, ""); cap = `${esc(nameOf(e.target))} sufre quemadura`; }
    else if (e.t === "Mod") cap = `${STAT_TXT[e.stat] || e.stat} de ${esc(nameOf(e.target))} ${e.amount > 0 ? "sube" : "baja"}`;
    else if (e.t === "Miss") cap = `${esc(nameOf(e.actor))} falla${battle.state.field.accuracy[sideOf(e.actor) - 1] < 0 ? " en la penumbra" : ""}`;
    else if (e.t === "Skip") cap = `${esc(nameOf(e.actor))} no puede actuar (${STATUS_TXT[e.status]})`;
    else if (e.t === "Block") cap = `¡${esc(nameOf(e.target))} bloquea el golpe!`;
    else if (e.t === "Dodge") cap = `¡${esc(nameOf(e.target))} lo esquiva!`;
    else if (e.t === "Shield") cap = `${esc(nameOf(e.target))} levanta un escudo`;
    else if (e.t === "Savia" && e.delta < 0) cap = `${esc(nameOf(e.target))} pierde Savia`;
    else if (e.t === "Savia" && e.delta > 0) cap = `${esc(nameOf(e.target))} gana ${e.delta} de Savia`;
    else if (e.t === "Faint" && tm) { cap = sideOf(e.target) === 2 ? "¡La niebla gris se debilita!" : `${esc(nameOf(e.target))} está cansado`; tm.rotation.z = 0.4; }
    else if (e.t === "Restored" && tm) {
      if (!tm.visible) continue;
      cap = "✨ ¡El monstruo recupera su color!";
      tm.rotation.z = 0; vfx.ring(tm.position.clone().add(V(0, 1.5, 0)), 0xffffff, 10, 1.0);
      for (const c of [0xe84a6e, 0xfaba32, 0x40aad6, 0x68be60, 0x9660de]) vfx.burst(tm.position.clone().add(V(0, 2, 0)), c, 10, 8, { life: 1.4, size: 0.9 });
      const t0 = performance.now();
      await new Promise((res) => { const step = () => { const t = (performance.now() - t0) / (1200 / ANIM); setOpaco(tm, 1 - Math.min(1, t)); tm.position.y = Math.sin(Math.min(1, t) * Math.PI) * 2; if (t < 1) requestAnimationFrame(step); else res(); }; step(); });
      if (battle.boss && combatant(e.target)?.guardianId) await guardianRestored(tm);
    }
    if (cap) { renderBattle(cap); await sleep(650); }
  }
  battle.busy = false;
  if (s.phase === "Ended") return endBattle();
  renderBattle();
}
function battleTick(t, dt) {
  // La luz cambia en tiempo real (no por fotograma): igual en móviles lentos
  const nowMs = performance.now(), real = Math.min(0.5, (nowMs - (battle.lastMs || nowMs)) / 1000); battle.lastMs = nowMs;
  battle.light = lerp(battle.light, battle.lightTarget, 1 - Math.exp(-real * 2.5 * ANIM));
  hemi.intensity = BASE_LIGHT.hemi * battle.light; sun.intensity = BASE_LIGHT.sun * battle.light;
  renderer.toneMappingExposure = BASE_LIGHT.exposure * (0.75 + 0.25 * battle.light);
  for (const m of battle.models) if (m.visible) animateCreature(m, t, dt, false);
  for (const g of Object.values(battle.roots)) g.rotation.y += dt * 0.2;
}
async function endBattle() {
  const { state: s, encId, enc } = battle;
  const won = s.outcome.winner === 1;
  const lead = companion();
  renderBattle(won ? (battle.boss ? `¡${esc(battle.boss.shortName)} vuelve a ser guardiana del Valle!` : "¡Victoria! Nadie muere en NEXORA: los Opacos fueron restaurados.") : s.outcome.reason === "Forfeit" ? "Te retiras para entrenar." : `${esc(lead ? petName(lead) : "Tu equipo")} necesita descansar. ¡Inténtalo de nuevo!`);
  await sleep(1500);
  const r = runWith((c) => DOM.Actions.finishEncounter(P, encId, s.battleId, won, s.turn, battle.participants, c, s.outcome.reason, BE.summary(s)));
  const prevStars = battle.prevStars;
  // Recoger el escenario: modelos temporales fuera, luces y Opaco del marcador en su sitio
  for (const m of battle.models) {
    m.rotation.z = 0;
    if (m.userData.temp) scene.remove(m);
    else if (m !== companionModel) { setOpaco(m, 1); m.visible = true; }
  }
  for (const g of Object.values(battle.roots)) g.parent?.remove(g);
  if (battle.spot && battle.spot.creature) { battle.spot.creature.visible = true; battle.spot.creature.position.copy(battle.spot.pos); battle.spot.creature.rotation.set(0, Math.PI / 2, 0); setOpaco(battle.spot.creature, 1); }
  if (companionModel) { companionModel.visible = true; companionModel.rotation.z = 0; }
  hemi.intensity = BASE_LIGHT.hemi; sun.intensity = BASE_LIGHT.sun; renderer.toneMappingExposure = BASE_LIGHT.exposure;
  $("#battle").classList.add("hidden"); $("#battle").innerHTML = "";
  battle = null; cine = false; inputLocked = false;
  showWorldUI(); refreshUI();
  if (!r.ok) return toast("⚠️", errText(r.err));
  if (won) {
    // Tutorial: igual que en la Fase 1, directo a la recompensa
    if (!tutorialDone() && r.data.rewardId) return showReward(r.data.rewardId);
    return showStageResult(encId, r.data, prevStars);
  }
  if (r.data.forfeited) return toast("🏳️", "Te retiras: retirarse no da premio.");
  if (r.data.capped) return toast("💤", "Sin XP de consolación por hoy (tope diario).");
  const xp = Object.values(r.data.pets || {}).reduce((a, x) => a + x.xpGained, 0);
  toast("💪", `Derrota en «${esc(enc.name)}»: +${fmt(xp)} XP de consolación. ¡Entrena y vuelve!`);
}

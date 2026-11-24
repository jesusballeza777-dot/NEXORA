
// =====================================================================
// Arranque: equivale a la carga del perfil en el servidor (Actions.onLoad: reconexión,
// rotación del tablón y ranuras del Criadero). Si se cerró la pestaña a mitad de la
// eclosión inicial, no se repite.
// =====================================================================
const firstLoad = P.loginCount === 0;
run("onLoad");
camPos.copy(player.position).add(V(0, 14, -24)); camTarget.copy(treeBase);
$("#loading").classList.add("hidden");
if (step() === "Intro") showIntro();
else {
  inputLocked = false; showWorldUI();
  toast("🌳", migratedFrom ? "Tu partida de la Fase 1 se migró a la Fase 2 sin perder nada." : !firstLoad ? "¡Bienvenido de vuelta! Tu progreso se conservó." : "Bienvenido al Valle Copal");
}
refreshUI();
requestAnimationFrame(tick);
setInterval(() => { if (!battle && !modalOpen && !cine) refreshUI(); }, 5000);

// =====================================================================
// Ganchos para pruebas automatizadas de la vista previa (solo depuración)
// =====================================================================
// Combate sin animación con las mismas reglas (el jugador usa la política "Normal")
function simulateStage(encId, seed = 1 + Math.floor(battleRng.next() * 2147483640)) {
  const e = CFG.Encounters.ById[encId];
  if (e.stageType === "Tesoro") { const r = run("solveTreasure", encId, EncounterRules.correctAnswer(e)); claimAllPending(); return r; }
  const can = DOM.Actions.canStartEncounter(P, encId);
  if (!can.ok) return can;
  DOM.Actions.markBattleStarted(P, encId, ctx());
  const battleId = `sim-${serverNow()}-${++battleSerial}`;
  const s = BE.new(EncounterRules.buildSetup(P, encId, battleId, seed));
  let guard = 0;
  while (s.phase !== "Ended" && guard++ < 200) { BE.submit(s, 1, { kind: "Move", moveId: AI.choose(s, 1, "Normal") }); BE.submit(s, 2, { kind: "Move", moveId: AI.choose(s, 2, s.sides[1].ai) }); BE.resolveTurn(s); }
  const r = runWith((c) => DOM.Actions.finishEncounter(P, encId, battleId, s.outcome.winner === 1, s.turn, EncounterRules.participantsFor(P, encId), c, s.outcome.reason, BE.summary(s)));
  claimAllPending();
  refreshUI();
  return Object.assign(r, { won: s.outcome.winner === 1, turns: s.turn });
}
function claimAllPending() { for (const rw of pendingRewards()) run("claimReward", rw.id); }
window.__nexora = {
  portrait, get P() { return P; }, Actions: DOM.Actions, DOM, run, startBattle, playTurn, refreshUI, endIntro, hatchSequence, player,
  get battle() { return battle; }, get modalOpen() { return modalOpen; }, teleport: (x, z) => player.position.set(x, 0, z),
  openPetSheet, openSanctuary, openNexoMenu, openAlbum, openBestiary, openCriadero, openChests, openQuests, openAdventure, openStage, openTreasure, openCodex, openAchievements, closeModal, evolveSequence,
  // Reloj del "servidor" adelantado (incubadora, encargos): solo para pruebas
  advanceTime(seconds) { DEV.clockOffset = (DEV.clockOffset || 0) + seconds; saveDev(); refreshUI(); return serverNow(); },
  // Equipo fuerte para recorrer el acto: sube a todo el equipo (o a los ids dados)
  boostTeam(level = 22, form = "Tallado", ids = null) { for (const id of ids || (P.team.length ? P.team : [P.companionPetId])) { const p = P.pets[id]; if (p) { p.level = level; p.xp = 0; if (form) p.form = form; } } save(); refreshUI(); },
  devPet(speciesId) { const r = PetRules.create(P, speciesId, { kind: "Dev", at: serverNow() }); save(); refreshUI(); return r.data && r.data.petId; },
  simulateStage, claimAllPending, setAnim: (k) => { ANIM = k; }, serverNow,
  get debug() { return { scene, camera, companionModel, camPos, camTarget, buildCreature, renderer, THREE }; },
  setCam(p, l) { cine = true; cineCam = { pos: V(...p), look: V(...l) }; camPos.copy(cineCam.pos); camTarget.copy(cineCam.look); },
  freeCam() { cine = false; cineCam = null; refreshUI(); },
  // Calidad de render para pruebas en GPU por software: "low" (sin postproceso, ½ resolución) o "high"
  setQuality(q) { qualityChecked = true; usePost = q !== "low"; pixelRatio = q === "low" ? 0.5 : Math.min(devicePixelRatio, isTouch ? 1.5 : 1.75); renderer.setPixelRatio(pixelRatio); renderer.setSize(innerWidth, innerHeight); composer.setPixelRatio(pixelRatio); composer.setSize(innerWidth, innerHeight); },
};


// =====================================================================
// Pantallas: menú del Gran Nexo, ficha y Tallado, santuario, Álbum y Bestiario,
// Criadero, Repisa de Cofres, Tablón de Encargos, mapa del Acto I, etapas,
// tesoros, Códice y recompensas. Todo lee el perfil y llama a Actions (run).
// =====================================================================
const STAGE_ICON = { Combate: "⚔️", Elite: "👑", Tesoro: "💰", Rescate: "🪶", Jefe: "🌳", Secreta: "❔" };
const STAGE_TYPE = { Combate: "Combate", Elite: "Élite", Tesoro: "Tesoro", Rescate: "Rescate", Jefe: "Jefe", Secreta: "Secreta" };
const DECOR_ICON = { Lantern: "🏮", Planter: "🪴", Banner: "🎏", Stone: "🗿", Bench: "🪑", Arch: "🌿" };
const RARITY = (id) => CFG.Rarities.ById[id];
const BIOME_BG = {
  ValleCopal: "linear-gradient(160deg,#7fae6b,#3f6b45)", MareaCoralina: "linear-gradient(160deg,#5fb6c9,#2b5e7a)", CumbreBrasa: "linear-gradient(160deg,#d9855a,#7a3b2a)",
  MesetaFulgor: "linear-gradient(160deg,#e3c35a,#8a6a2a)", VeloAstral: "linear-gradient(160deg,#6a5fb0,#2a2350)", TorreDelNexo: "linear-gradient(160deg,#b08a5a,#4d3427)",
};
const starsHtml = (st, big = false) => `<span class="stars ${big ? "big" : ""}">${[0, 1, 2].map((i) => `<i class="${st && st[i] ? "on" : ""}">★</i>`).join("")}</span>`;
const countStars = (st) => (st ? st.filter(Boolean).length : 0);
const chestIcon = (type, size = 56) => { const d = CFG.Chests.ById[type]; return `<span class="chest-ico" style="--cw:${size}px;--cc:${css(d.color)};--cg:${css(d.glow)}"><i class="lid"></i><i class="box"></i><i class="lock"></i></span>`; };
function durationText(s) {
  s = Math.max(0, Math.floor(s));
  const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60;
  if (d) return `${d} d ${h} h`;
  if (h) return `${h} h ${m} min`;
  if (m) return `${m} min ${String(sec).padStart(2, "0")} s`;
  return `${sec} s`;
}
function itemLines(o) {
  const out = [];
  if (o.currencies?.Monedas) out.push(["🪙", `${fmt(o.currencies.Monedas)} Monedas`]);
  if (o.currencies?.Gemas) out.push(["💎", `${fmt(o.currencies.Gemas)} Gemas`]);
  for (const [k, n] of Object.entries(o.items || {})) out.push([FOOD_ICON[k], `${n} × ${CFG.Economy.Foods[k].name}`]);
  return out;
}

// ---------------- Menú rápido del Gran Nexo (radial) ----------------
function openNexoMenu() {
  const n = notices();
  const lockedTxt = !starterPet() ? "Elige primero tu huevo junto al Gran Nexo." : null;
  const items = [
    { id: "adventure", em: "🗺️", name: "Aventura", badge: tutorialDone() && nextStage() ? "!" : 0, go: () => openAdventure() },
    { id: "criadero", em: "🥚", name: "Criadero", badge: n.readyEggs, go: () => openCriadero() },
    { id: "chests", em: "🧰", name: "Cofres", badge: n.chests, go: () => openChests() },
    { id: "quests", em: "📋", name: "Encargos", badge: n.quests, go: () => openQuests() },
    { id: "album", em: "📖", name: "Álbum", go: () => openAlbum() },
    { id: "codex", em: "📜", name: "Códice", go: () => openCodex() },
    { id: "sanctuary", em: "🏡", name: "Santuario", go: () => openSanctuary() },
    { id: "team", em: "🐾", name: "Monstruos", badge: companion() && Leveling.canEvolve(companion())[0] ? "!" : 0, go: () => openSanctuary("vivero") },
    { id: "travel", em: "🧭", name: "Viajar", go: () => openTravel() },
  ];
  const R = Math.round(Math.min(170, (innerWidth - 130) / 2, (innerHeight - 270) / 2));
  openModal(`<div class="radial" style="--R:${R}px">
      <button class="radial-core" id="rc">${n.rewards ? `<span class="em">🎁</span><b>Reclamar</b><small>${n.rewards} recompensa${n.rewards > 1 ? "s" : ""}</small>` : `<span class="em">🌳</span><b>Gran Nexo</b><small>Toca una rama</small>`}</button>
      ${items.map((it, i) => { const a = (i / items.length) * Math.PI * 2 - Math.PI / 2; return `<button class="radial-item" data-go="${it.id}" style="--x:${Math.cos(a).toFixed(3)};--y:${Math.sin(a).toFixed(3)}"><span class="em">${it.em}</span><span class="lb">${it.name}</span>${it.badge ? `<i class="badge">${it.badge}</i>` : ""}</button>`; }).join("")}
    </div>
    <div class="radial-foot"><button class="btn secondary small" id="settings">⚙️ Ajustes</button><button class="btn secondary small" data-close>Cerrar</button></div>`,
  (m) => {
    m.querySelector("#rc").addEventListener("click", () => { const p = pendingRewards(); if (p.length) showReward(p[0].id); else closeModal(); });
    m.querySelectorAll("[data-go]").forEach((b) => b.addEventListener("click", () => { if (lockedTxt) return toast("🥚", lockedTxt); items.find((x) => x.id === b.dataset.go).go(); }));
    m.querySelector("#settings").addEventListener("click", () => openSettings());
  }, { cls: "radial-modal", noClose: true });
}
function openTravel() {
  const dests = [
    { id: "Plaza", em: "🌳", name: "Plaza del Gran Nexo", sub: "Corazón del valle", pos: v3(W.TravelPoints.Plaza) },
    { id: "LoteHogar", em: "🏡", name: "Lote Hogar", sub: lotUnlocked() ? "Hábitat, incubadora y vitrina" : "Se abre al visitarlo", pos: lotC.clone().add(V(0, 0, 20)) },
    { id: "Linde", em: "🌫️", name: "Linde de las Chinampas", sub: "Opacos y arena de combate", pos: v3(W.TravelPoints.Linde) },
    ...["Despensa", "Criadero", "Tablon", "RepisaCofres", "Mirador"].map((id) => { const st = W.Stations[id], p = v3(st.position); const toTree = treeBase.clone().sub(p).setY(0).normalize(); return { id, em: { Despensa: "🧺", Criadero: "🥚", Tablon: "📋", RepisaCofres: "🧰", Mirador: "🔭" }[id], name: st.label, sub: STATION_SUB[id], pos: p.add(toTree.multiplyScalar(st.radius - 3)) }; }),
  ];
  openScreen("🧭", "Viajar", "El árbol lleva a cada estación; allí se usan en persona.", `<div class="travel-list">${dests.map((d) => `<button class="travel" data-go="${d.id}"><span class="em">${d.em}</span><span>${d.name}<small>${d.sub}</small></span></button>`).join("")}</div>`,
    (m) => m.querySelectorAll("[data-go]").forEach((b) => b.addEventListener("click", () => { const d = dests.find((x) => x.id === b.dataset.go); closeModal(); player.position.set(d.pos.x, 0, d.pos.z); if (companionModel) companionModel.position.copy(player.position).add(V(3, 0, 3)); })), { wide: false });
}
function openSettings() {
  openScreen("⚙️", "Ajustes de la vista previa", "Solo para probar: el balance real no cambia.", `
    <button class="travel" id="dev"><span class="em">⚡</span><span>${DEV.xp ? "Modo prueba: XP ×10 activado" : "Modo prueba: apagado"}<small>Acelera la XP y quita la espera de «Jugar»</small></span></button>
    <button class="travel" id="reset" style="margin-top:8px"><span class="em">🗑️</span><span>Reiniciar partida<small>Borra el progreso guardado en este navegador</small></span></button>
    <div class="note-box">Vista previa web de NEXORA · Fase 2 beta. Modelos provisionales (blockout). Sin compras: todo se gana jugando.</div>`,
  (m) => {
    m.querySelector("#dev").addEventListener("click", () => { DEV.xp = !DEV.xp; saveDev(); openSettings(); });
    const reset = m.querySelector("#reset");
    reset.addEventListener("click", () => {
      if (reset.dataset.armed) { try { localStorage.removeItem(SAVE_KEY); localStorage.removeItem(OLD_SAVE_KEY); } catch (e) { /* sin almacenamiento */ } clearTimeout(saveTimer); P = ProfileSchema.new(WEB_USER_ID, serverNow()); removeEventListener("pagehide", saveNow); location.reload(); return; }
      reset.dataset.armed = "1"; reset.querySelector("span:last-child").firstChild.textContent = "¿Seguro? Toca otra vez para borrar";
    });
  }, { wide: false });
}

// ---------------- Recompensas ----------------
function showReward(rewardId) {
  const r = P.rewards.pending[rewardId]; if (!r) return;
  const items = itemLines(r);
  if (r.petXp) items.push(["⭐", `${fmt(r.petXp * xpMult())} XP para tu equipo`]);
  for (const c of r.chests || []) items.push([chestIcon(c, 34), `${CFG.Chests.ById[c].name} · a la Repisa`]);
  for (const e of r.eggs || []) items.push(["🥚", `Huevo de ${speciesName(e)} · al Criadero`]);
  for (const d of r.decor || []) items.push([DECOR_ICON[CFG.Decor.ById[d].shape], `${CFG.Decor.ById[d].name} · decoración`]);
  for (const t of r.titles || []) items.push(["🎖️", `Título: ${esc(t)}`]);
  for (const f of r.frames || []) items.push(["🖼️", `Marco: ${esc(f)}`]);
  for (const u of r.unlocks || []) if (u.startsWith("Encounter_") && CFG.Encounters.ById[u.replace("Encounter_", "")]) items.push(["🗺️", `Nuevo Opaco: ${CFG.Encounters.ById[u.replace("Encounter_", "")].name}`]); else if (u === "ActoI_Completo") items.push(["🌳", "Acto I completado"]);
  openModal(`<h2>${esc(r.title)}</h2><div class="sub">Recompensa determinista · procedencia registrada</div>
    <div class="reward-list">${items.map(([e, t], i) => `<div class="reward-item" style="animation-delay:${i * 0.12}s"><span class="em">${e}</span>${t}</div>`).join("")}</div>
    <button class="btn" id="claim" style="width:100%">Reclamar</button>`,
  (m) => m.querySelector("#claim").addEventListener("click", () => {
    const res = run("claimReward", rewardId);
    closeModal();
    if (!res.ok) return toast("⚠️", errText(res.err));
    toast("🎁", "Recompensa reclamada");
    if (res.data.chestIds.length) toast("🧰", `${res.data.chestIds.length > 1 ? res.data.chestIds.length + " cofres guardados" : "Cofre guardado"} en la Repisa de Cofres`);
    if (res.data.eggIds.length) toast("🥚", "Huevo guardado en el Criadero");
    refreshUI();
    const more = pendingRewards(); if (more.length) setTimeout(() => !modalOpen && showReward(more[0].id), 350);
  }), { noClose: true });
}

// ---------------- Resultado de etapa (estrellas) ----------------
function showStageResult(encId, data, prevStars) {
  const enc = CFG.Encounters.ById[encId];
  const st = data.stars || [false, false, false];
  const labels = ["Victoria", "Sin perder monstruos", enc.challenge.text];
  const lines = [];
  if (data.capped) lines.push(["💤", "Tope diario de repeticiones: hoy esta victoria no da premio (las estrellas sí cuentan)."]);
  else if (data.firstClear) lines.push(["🏁", "¡Primera victoria en esta etapa!"]);
  else lines.push(["🔁", `Repetición: ${Math.round(CFG.Encounters.Repeat.RewardScale * 100)} % del premio.`]);
  if (data.rescueEgg) lines.push(["🥚", `¡El ${speciesName(data.rescueEgg)} rescatado te deja un huevo!`]);
  for (const sp of data.newSpecies || []) lines.push(["📖", `${speciesName(sp)} entra al Bestiario como restaurado.`]);
  if (data.regionCleared) lines.push(["🗺️", `Región completada: ${CFG.Encounters.Regions[data.regionCleared - 1].name}.${(data.slotsOpened || []).length ? " Se abre una ranura nueva del Criadero." : ""}`]);
  if (data.regionStars) lines.push(["🏆", "¡Tres estrellas en toda la región! Cofre de Oro."]);
  if (data.actAllStars) lines.push(["🖼️", "¡Todas las estrellas del Acto I! Marco y título nuevos."]);
  for (const c of data.codex || []) { const e = CFG.Codex.ById[c]; if (e) lines.push([e.symbol, `Carta del Códice: ${esc(e.title)}`]); }
  const g = data.guardianRestored ? guardian(data.guardianRestored) : null;
  openModal(`${g ? `<div class="act-done"><div class="bb-kicker">Acto I · Valle Copal</div><img src="${portrait("copalia", "Tallado")}" alt=""><div class="bb-name">¡${esc(g.shortName)} restaurada!</div><div class="sub">${esc(g.restoreBonus)}</div></div>` : `<h2>${esc(enc.name)}</h2>`}
    <div class="result-stars">${[0, 1, 2].map((i) => `<div class="rs-star ${st[i] ? "on" : ""} ${st[i] && !prevStars[i] ? "new" : ""}" style="animation-delay:${0.2 + i * 0.35}s"><i>★</i><span>${esc(labels[i])}</span>${st[i] && !prevStars[i] ? "<b>¡Nueva!</b>" : ""}</div>`).join("")}</div>
    <div class="reward-list">${lines.map(([e, t], i) => `<div class="reward-item" style="animation-delay:${1.1 + i * 0.1}s"><span class="em">${e}</span>${t}</div>`).join("")}</div>
    <button class="btn" id="ok" style="width:100%">${data.rewardId ? "Ver recompensa" : "Continuar"}</button>`,
  (m) => m.querySelector("#ok").addEventListener("click", () => { closeModal(); if (data.rewardId && P.rewards.pending[data.rewardId]) showReward(data.rewardId); }), { noClose: true, cls: "result" });
}

// ---------------- Ficha del monstruo ----------------
function openPetSheet(petId = P.companionPetId) {
  const pet = P.pets[petId]; if (!pet) return toast("🥚", "Primero elige tu huevo junto al Gran Nexo.");
  const sp = species(pet.speciesId), fb = Stats.formBase(pet.speciesId, pet.form), obj = Leveling.nextObjective(pet);
  const [canEvo] = Leveling.canEvolve(pet);
  const rar = RARITY(sp.rarity);
  const tal = sp.talent ? CFG.Talents.ById[sp.talent] : null, sig = sp.signature ? ability(sp.signature) : null;
  const lore = CFG.SpeciesLore.ById[pet.speciesId];
  const pct = pet.level >= 50 ? 100 : (pet.xp / Leveling.xpToNext(pet.level)) * 100;
  const foods = CFG.Economy.FoodOrder.filter((f) => CFG.Economy.Foods[f].sold || (P.items[f] || 0) > 0);
  const moves = pet.loadout || BE.defaultLoadout(pet.speciesId, pet.form, pet.level);
  const isComp = pet.id === P.companionPetId;
  openModal(`
    <div class="card monster" style="border-color:${css(rar.frameColor)}">
      <div class="gem" style="color:${css(rar.frameColor)}">◆ ${rar.name}</div><div class="els">${elementBadges(sp.elements)}</div>
      <img class="portrait" src="${portrait(pet.speciesId, pet.form)}" alt=""><div class="pedestal"></div>
      <div class="title">${esc(petName(pet))}</div><div class="species">${pet.form === "Tallado" ? sp.talladoName : sp.broteName} · ${sp.role} · ${pet.form}${isComp ? " · acompañante" : ""}</div>
    </div>
    <div class="kv" style="margin-top:12px"><span>Nivel <b>${pet.level}</b></span><span>XP <b>${fmt(pet.xp)} / ${fmt(Leveling.xpToNext(pet.level))}</b></span></div>
    <div class="bar"><i style="width:${pct}%"></i></div>
    <div class="kv"><span>Vínculo</span><span class="hearts" style="font-size:16px">${hearts(pet)}</span></div>
    <div class="objective-box">🎯 ${obj.text} <span style="float:right">${obj.current}/${obj.target}</span></div>
    ${canEvo ? '<button class="btn" id="evolve" style="width:100%;margin:6px 0 10px">✨ Ceremonia del Tallado: ' + sp.talladoName + "</button>" : ""}
    <div class="food-grid">${foods.map((f) => `<button class="food" data-food="${f}" ${(P.items[f] || 0) < 1 ? "disabled" : ""}><span class="em">${FOOD_ICON[f]}</span>${CFG.Economy.Foods[f].name}<span class="n">×${P.items[f] || 0} · +${CFG.Economy.Foods[f].xp * xpMult()} XP</span></button>`).join("")}</div>
    <div class="row"><button class="btn jade" id="play">❤ Jugar</button><button class="btn secondary" id="rename">✎ Nombre</button></div>
    ${isComp ? "" : '<button class="btn secondary" id="companion-set" style="width:100%;margin-top:8px">🐾 Que me acompañe (rehace el equipo)</button>'}
    <div class="stats">${["VID", "ATQ", "DEF", "ESE", "VEL"].map((k) => `<span>${k}</span><div class="bar"><i style="width:${(fb[k] / 40) * 100}%"></i></div><span>${fb[k]}</span>`).join("")}</div>
    <div class="kv"><span>Ataques</span></div><div class="move-chips">${moves.map((id) => { const mv = ability(id); return mv ? `<span style="background:${css(CFG.Elements.ById[mv.element].color)}">${ELEMENT_ICON[mv.element]} ${esc(mv.name)}</span>` : ""; }).join("")}</div>
    <div class="kv"><span>Talento</span><b>${tal ? tal.name : "Pendiente"}</b></div><div class="sub" style="text-align:left;margin:0 0 6px">${tal ? tal.text : esc(lore?.talentText || "Pendiente (Biblia)")}</div>
    ${sig ? `<div class="kv"><span>Firma</span><b>${sig.name}</b></div><div class="sub" style="text-align:left;margin:0 0 6px">${sig.text}</div>` : ""}
    <div class="kv"><span>Mezcla mítica</span></div><div class="sub" style="text-align:left">${esc(sp.mythicMix || lore?.mythicMix || "Pendiente")}</div>
    <div class="sub" style="font-size:14px">Modelo provisional (blockout). El diseño final pasa por el pipeline de arte y aprobación humana.</div>`,
  (m) => {
    m.querySelectorAll("[data-food]").forEach((b) => b.addEventListener("click", () => {
      const r = run("feed", pet.id, b.dataset.food);
      if (!r.ok) return toast("⚠️", errText(r.err));
      petFx(pet.id, "play"); toast(FOOD_ICON[b.dataset.food], `+${r.data.xpGained} XP${r.data.bondGained ? " · Vínculo +" + r.data.bondGained : ""}`);
      refreshUI(); openPetSheet(pet.id);
    }));
    m.querySelector("#play").addEventListener("click", () => {
      if (isComp) { closeModal(); return playWithCompanion(); }
      const r = run("play", pet.id); toast(r.ok ? "❤️" : "⏳", r.ok ? `Vínculo +${r.data.bondGained}` : errText(r.err)); openPetSheet(pet.id);
    });
    m.querySelector("#rename").addEventListener("click", () => renamePet(pet.id));
    m.querySelector("#companion-set")?.addEventListener("click", () => { run("setCompanion", pet.id); toast("🐾", `${esc(petName(pet))} te acompaña`); closeModal(); });
    m.querySelector("#evolve")?.addEventListener("click", () => { closeModal(); evolveSequence(pet.id); });
  });
}
function renamePet(petId) {
  const pet = P.pets[petId];
  openModal(`<h2>Ponle nombre</h2><div class="sub">En Roblox, el nombre pasa por el filtro de texto del servidor antes de guardarse.</div>
    <input class="input" id="nick" maxlength="${CFG.Onboarding.MaxNicknameLength}" value="${esc(pet.nickname || "")}" placeholder="${species(pet.speciesId).broteName}">
    <div class="row" style="margin-top:12px"><button class="btn secondary" data-close>Cancelar</button><button class="btn" id="ok">Guardar</button></div>`,
  (m) => { const i = m.querySelector("#nick"); setTimeout(() => i.focus(), 50); m.querySelector("#ok").addEventListener("click", () => { run("setNickname", pet.id, i.value.trim().slice(0, CFG.Onboarding.MaxNicknameLength) || null); closeModal(); }); });
}

// ---------------- Ceremonia del Tallado: anuncio → luz → revelación → cambios ----------------
function evolveSequence(petId) {
  const pet = P.pets[petId]; if (!pet) return;
  const sp = species(pet.speciesId);
  openModal(`<div class="ceremony-announce"><div class="bb-kicker">Ceremonia del Tallado</div><img src="${portrait(pet.speciesId, "Brote")}" alt=""><div class="bb-name">${esc(petName(pet))}</div>
    <div class="sub">La gubia del Tallador espera. Tu Brote conservará su cara, su color base y su rasgo firma, y crecerá en presencia.</div></div>
    <div class="row"><button class="btn secondary" data-close>Aún no</button><button class="btn" id="go">✨ Tallar en ${sp.talladoName}</button></div>`,
  (m) => m.querySelector("#go").addEventListener("click", () => { closeModal(); talladoCeremony(petId); }), { cls: "ceremony" });
}
async function talladoCeremony(petId) {
  const pet = P.pets[petId], sp = species(pet.speciesId);
  const before = Stats.formBase(pet.speciesId, "Brote"), movesBefore = BE.defaultLoadout(pet.speciesId, "Brote", pet.level);
  inputLocked = true; cine = true;
  ["#companion", "#objective", "#dock", "#joystick", "#help", "#prompt"].forEach((s) => $(s).classList.add("hidden"));
  let m = pet.id === P.companionPetId ? companionModel : null, temp = false;
  if (!m) { m = buildCreature(pet.speciesId, pet.form); m.position.copy(player.position).add(V(0, 0, -6)); scene.add(m); temp = true; }
  const base = m.position.clone();
  cineCam = { pos: base.clone().add(V(0, 7, 15)), look: base.clone().add(V(0, 2.5, 0)) };
  // Luz: el valle se oscurece y una columna de copal cae sobre el Brote
  const column = mesh(new THREE.CylinderGeometry(2.2, 3.2, 40, 32, 1, true), new THREE.MeshBasicMaterial({ color: 0xffd27a, transparent: true, opacity: 0, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }), base.clone().add(V(0, 20, 0)), null, null, scene, false);
  const t0 = performance.now(), dur = 2600 / ANIM;
  await new Promise((res) => { const step = () => {
    const t = (performance.now() - t0) / dur, k = Math.min(1, t);
    hemi.intensity = lerp(BASE_LIGHT.hemi, BASE_LIGHT.hemi * 0.35, k); sun.intensity = lerp(BASE_LIGHT.sun, BASE_LIGHT.sun * 0.3, k);
    column.material.opacity = k * 0.55;
    m.rotation.y += 0.05 + k * 0.2; m.position.y = Math.sin(k * Math.PI / 2) * 3;
    m.userData.mats.forEach((mm) => mm.emissive.setRGB(k * 0.6, k * 0.42, k * 0.12));
    const a = t * 14; vfx.burst(base.clone().add(V(Math.cos(a) * 3, 0.5 + k * 5, Math.sin(a) * 3)), 0xffc860, 2, 1.5, { life: 0.9, size: 0.8 });
    if (t < 1) requestAnimationFrame(step); else res(); }; step(); });
  // Revelación: destello y el Tallado aparece
  const flash = document.createElement("div"); flash.className = "flash"; document.body.appendChild(flash);
  await sleep(180);
  const r = run("evolve", petId);
  if (temp) scene.remove(m);
  else { refreshUI(); m = companionModel; }
  if (temp && r.ok) { m = buildCreature(pet.speciesId, "Tallado"); m.position.copy(base); scene.add(m); }
  if (m) { m.position.copy(base); m.userData.react = 0.9; m.userData.reactSpin = 1; }
  vfx.ring(base.clone().add(V(0, 2, 0)), 0xffe08a, 14, 1); vfx.burst(base.clone().add(V(0, 3, 0)), 0xffd060, 70, 13, { life: 1.4, size: 1.2 });
  const t1 = performance.now();
  await new Promise((res) => { const step = () => { const k = Math.min(1, (performance.now() - t1) / (1400 / ANIM)); column.material.opacity = 0.55 * (1 - k); hemi.intensity = lerp(BASE_LIGHT.hemi * 0.35, BASE_LIGHT.hemi, k); sun.intensity = lerp(BASE_LIGHT.sun * 0.3, BASE_LIGHT.sun, k); if (k < 1) requestAnimationFrame(step); else res(); }; step(); });
  scene.remove(column); flash.remove();
  if (temp && m) scene.remove(m);
  hemi.intensity = BASE_LIGHT.hemi; sun.intensity = BASE_LIGHT.sun;
  cine = false; inputLocked = false; showWorldUI(); refreshUI();
  if (!r.ok) return toast("⚠️", errText(r.err));
  // Cambios: atributos, ataques y carta nueva
  const after = Stats.formBase(pet.speciesId, "Tallado"), movesAfter = BE.defaultLoadout(pet.speciesId, "Tallado", pet.level);
  const newMoves = movesAfter.filter((id) => !movesBefore.includes(id));
  openModal(`<div class="card monster" style="border-color:${css(RARITY(sp.rarity).frameColor)}"><div class="gem">◆ Tallado</div><div class="els">${elementBadges(sp.elements)}</div><img class="portrait" src="${portrait(pet.speciesId, "Tallado")}" alt=""><div class="pedestal"></div><div class="title">${sp.talladoName}</div><div class="species">${esc(sp.talladoDescription || CFG.SpeciesLore.ById[pet.speciesId]?.talladoLook || "")}</div></div>
    <div class="stat-change">${["VID", "ATQ", "DEF", "ESE", "VEL"].map((k) => `<span>${k}</span><span>${before[k]}</span><span class="arrow">→</span><b>${after[k]}</b><span class="up">+${after[k] - before[k]}</span>`).join("")}</div>
    <div class="reward-list">${r.data.newCard ? '<div class="reward-item"><span class="em">📖</span>Nueva carta Tallado en el Álbum del Nexo</div>' : ""}
      ${newMoves.map((id) => `<div class="reward-item"><span class="em">${ELEMENT_ICON[ability(id).element]}</span>Nuevo ataque: ${esc(ability(id).name)}</div>`).join("")}
      <div class="reward-item"><span class="em">🌟</span>A nivel ${CFG.Progression.NexoUnlockLevel} desbloquea el Golpe Nexo</div></div>
    <button class="btn" data-close style="width:100%">Imponente</button>`, null, { noClose: true });
}

// ---------------- Santuario: hábitat, decoración, vitrina y Vivero ----------------
function openSanctuary(tab = "habitat") {
  if (!lotUnlocked()) return toast("🏡", "Visita tu Lote Hogar al sur del río para abrirlo.");
  const tabs = [["habitat", "🌱 Hábitat"], ["decor", "🏮 Decoración"], ["vitrina", "🏺 Vitrina"], ["vivero", "🐾 Vivero"]];
  const pets = Object.values(P.pets).sort((a, b) => (a.id < b.id ? -1 : 1));
  const h = home(), t = serverNow();
  let body = "";
  if (tab === "habitat") {
    const pend = SanctuaryRules.preview(P, HOME_ID, t);
    const free = pets.filter((p) => !h.slots.includes(p.id));
    body = `<div class="sub">Hábitat de 4 lugares · ${SanctuaryRules.habitatRate(P, HOME_ID).toFixed(1)} Monedas/h · los monstruos del Vivero no producen</div>
      <div class="slots">${h.slots.map((id, s) => id && P.pets[id] ? `<div class="slot filled"><img src="${portrait(P.pets[id].speciesId, P.pets[id].form)}" alt=""><div>${esc(petName(P.pets[id]))}${id === P.companionPetId ? " · paseando" : ""}</div><button class="btn small secondary" data-remove="${s + 1}">Retirar</button></div>` : `<div class="slot"><div style="font-size:26px">＋</div>Lugar ${s + 1}${free.slice(0, 4).map((p) => `<button class="btn small jade" data-place="${s + 1}" data-pet="${p.id}">Colocar ${esc(petName(p))}</button>`).join("")}</div>`).join("")}</div>
      <button class="btn" id="collect" style="width:100%" ${pend < 1 ? "disabled" : ""}>Recoger ${fmt(pend)} Monedas</button>`;
  } else if (tab === "decor") {
    const owned = Object.entries(P.decor.owned).filter(([, n]) => n > 0);
    body = `<div class="sub">6 espacios alrededor del hábitat. Solo se colocan objetos que tienes; cada copia ocupa un espacio.</div>
      <div class="decor-grid">${P.decor.slots.map((d, s) => { const def = d && CFG.Decor.ById[d]; return `<button class="decor-slot ${def ? "filled" : ""}" data-slot="${s + 1}" style="${def ? `--dc:${css(def.color)};--da:${css(def.accent)}` : ""}"><span class="em">${def ? DECOR_ICON[def.shape] : "＋"}</span><span>${def ? esc(def.name) : `Espacio ${s + 1}`}</span></button>`; }).join("")}</div>
      <div class="sec-title">Tus objetos</div>
      ${owned.length ? `<div class="decor-owned">${owned.map(([id, n]) => { const def = CFG.Decor.ById[id], used = P.decor.slots.filter((x) => x === id).length; return `<div class="decor-item"><span class="em" style="background:${css(def.accent)}">${DECOR_ICON[def.shape]}</span><div><b>${esc(def.name)}</b><small>${esc(def.description)} · ${used}/${n} colocado${n > 1 ? "s" : ""}</small></div></div>`; }).join("")}</div>` : '<div class="note-box">Aún no tienes objetos. Se ganan en etapas del Acto I (tesoros, regiones y Copalia).</div>'}
      <div class="sec-title">Plantillas de un toque</div>
      <div class="tpl-list">${CFG.Decor.Templates.map((tp) => { const has = tp.slots.filter((id) => (P.decor.owned[id] || 0) > 0).length; return `<button class="travel" data-tpl="${tp.id}" ${has ? "" : 'style="opacity:.55"'}><span class="em">✨</span><span>${esc(tp.name)}<small>${tp.slots.map((id) => `${DECOR_ICON[CFG.Decor.ById[id].shape]} ${CFG.Decor.ById[id].name}${(P.decor.owned[id] || 0) > 0 ? " ✔" : ""}`).join(" · ")}</small></span></button>`; }).join("")}</div>
      <div id="decor-pick"></div>`;
  } else if (tab === "vitrina") {
    body = `<div class="sub">Exhibe hasta ${CFG.Sanctuary.VitrinaSlots} monstruos tuyos en la vitrina del lote.</div>
      <div class="pick-grid">${pets.map((p) => { const i = P.showcase.indexOf(p.id); return `<button class="pick ${i >= 0 ? "on" : ""}" data-show="${p.id}"><img src="${portrait(p.speciesId, p.form)}" alt=""><span>${esc(petName(p))}</span><small>Nv ${p.level} · ${p.form}</small>${i >= 0 ? `<i class="ord">${i + 1}</i>` : ""}</button>`; }).join("")}</div>`;
  } else {
    const used = PetRules.inventoryUsed(P), exp = CFG.Sanctuary.InventoryExpansion;
    body = `<div class="kv"><span>Vivero</span><b>${used} / ${P.inventoryCapacity}</b></div><div class="bar"><i style="width:${(used / P.inventoryCapacity) * 100}%"></i></div>
      <button class="btn secondary" id="expand" style="width:100%;margin:10px 0" ${P.inventoryCapacity >= CFG.Sanctuary.InventoryMaxCapacity ? "disabled" : ""}>Ampliar +${exp.step} lugares · 🪙 ${fmt(exp.price.Monedas)}</button>
      <div class="pick-grid">${pets.map((p) => `<button class="pick" data-sheet="${p.id}"><img src="${portrait(p.speciesId, p.form)}" alt=""><span>${esc(petName(p))}</span><small>Nv ${p.level} · ${p.form}${p.id === P.companionPetId ? " · 🐾" : ""}${P.team.includes(p.id) ? " · equipo" : ""}</small>${Leveling.canEvolve(p)[0] ? '<i class="ord">!</i>' : ""}</button>`).join("")}</div>`;
  }
  openScreen("🏡", "Lote Hogar", "Tu santuario en el Valle Copal", `<div class="tabs">${tabs.map(([id, n]) => `<button class="tab ${id === tab ? "on" : ""}" data-tab="${id}">${n}</button>`).join("")}</div>${body}`,
  (m) => {
    m.querySelectorAll("[data-tab]").forEach((b) => b.addEventListener("click", () => openSanctuary(b.dataset.tab)));
    m.querySelectorAll("[data-place]").forEach((b) => b.addEventListener("click", () => { const r = run("place", b.dataset.pet, +b.dataset.place); if (!r.ok) toast("⚠️", errText(r.err)); refreshUI(); openSanctuary("habitat"); }));
    m.querySelectorAll("[data-remove]").forEach((b) => b.addEventListener("click", () => { const r = run("remove", +b.dataset.remove); if (!r.ok) toast("⚠️", errText(r.err)); refreshUI(); openSanctuary("habitat"); }));
    m.querySelector("#collect")?.addEventListener("click", () => { closeModal(); collectCoins(); });
    m.querySelectorAll("[data-slot]").forEach((b) => b.addEventListener("click", () => decorPicker(m, +b.dataset.slot)));
    m.querySelectorAll("[data-tpl]").forEach((b) => b.addEventListener("click", () => { const r = run("applyDecorTemplate", b.dataset.tpl); toast(r.ok ? "✨" : "⚠️", r.ok ? `Plantilla aplicada en ${r.data.placed.length} espacio(s)` : errText(r.err)); refreshUI(); openSanctuary("decor"); }));
    m.querySelectorAll("[data-show]").forEach((b) => b.addEventListener("click", () => {
      const id = b.dataset.show, list = P.showcase.includes(id) ? P.showcase.filter((x) => x !== id) : [...P.showcase, id];
      const r = run("setShowcase", list); if (!r.ok) toast("⚠️", errText(r.err)); refreshUI(); openSanctuary("vitrina");
    }));
    m.querySelector("#expand")?.addEventListener("click", () => { const r = run("expandInventory"); toast(r.ok ? "🐾" : "⚠️", r.ok ? `Vivero ampliado a ${r.data.capacity}` : errText(r.err)); refreshUI(); openSanctuary("vivero"); });
    m.querySelectorAll("[data-sheet]").forEach((b) => b.addEventListener("click", () => openPetSheet(b.dataset.sheet)));
  });
}
function decorPicker(m, slot) {
  const cur = P.decor.slots[slot - 1];
  const owned = Object.entries(P.decor.owned).filter(([, n]) => n > 0);
  const box = m.querySelector("#decor-pick");
  box.innerHTML = `<div class="sec-title">Espacio ${slot}</div><div class="decor-owned">${owned.map(([id, n]) => { const def = CFG.Decor.ById[id], used = P.decor.slots.filter((x, i) => x === id && i !== slot - 1).length; return `<button class="decor-item pickable" data-put="${id}" ${used >= n ? "disabled" : ""}><span class="em" style="background:${css(def.accent)}">${DECOR_ICON[def.shape]}</span><div><b>${esc(def.name)}</b><small>${used >= n ? "Sin copias libres" : "Colocar aquí"}</small></div></button>`; }).join("")}
    ${cur ? '<button class="btn secondary" data-put="">Quitar el objeto</button>' : ""}</div>`;
  box.querySelectorAll("[data-put]").forEach((b) => b.addEventListener("click", () => { const r = run("placeDecor", slot, b.dataset.put || null); if (!r.ok) toast("⚠️", errText(r.err)); refreshUI(); openSanctuary("decor"); }));
  box.scrollIntoView({ block: "nearest" });
}

// ---------------- Despensa ----------------
function openShop() {
  const foods = CFG.Economy.FoodOrder.filter((f) => CFG.Economy.Foods[f].sold);
  openModal(`<h2>Despensa del Gabinete</h2><div class="sub">«Lo que ves es lo que te llevas.» Precios fijos en Monedas ganadas jugando. Sin compras reales.</div>
    <div class="travel-list">${foods.map((f) => { const food = CFG.Economy.Foods[f]; return `<button class="travel" data-buy="${f}" ${coins() < food.price.Monedas ? 'style="opacity:.55"' : ""}><span class="em">${FOOD_ICON[f]}</span><span style="flex:1">${food.name}<small>+${food.xp} XP${food.bond ? " · +" + food.bond + " Vínculo" : ""} · tienes ${P.items[f] || 0}</small></span><span>🪙 ${fmt(food.price.Monedas)}</span></button>`; }).join("")}</div>`,
  (m) => m.querySelectorAll("[data-buy]").forEach((b) => b.addEventListener("click", () => { const r = run("buyFood", b.dataset.buy, 1); toast(r.ok ? FOOD_ICON[b.dataset.buy] : "⚠️", r.ok ? "Comprado" : errText(r.err)); refreshUI(); openShop(); })));
}

// ---------------- Álbum del Nexo ----------------
let albumBiome = "Todos";
function openAlbum() {
  const prog = CollectionRules.progress(P);
  const BIOME_ORDER = ["ValleCopal", "MareaCoralina", "CumbreBrasa", "MesetaFulgor", "VeloAstral", "TorreDelNexo"];
  const biomes = [...BIOME_ORDER, ...Object.keys(CFG.Species.Biomes)].filter((b, i, all) => prog.byBiome[b] && all.indexOf(b) === i);
  const list = CFG.Species.Order.filter((id) => albumBiome === "Todos" || species(id).biome === albumBiome);
  const cardFor = (id) => {
    const sp = species(id), e = P.collection[id], tier = CollectionRules.bestiaryTier(e), rar = RARITY(sp.rarity);
    if (tier === 0) return `<button class="acard unknown" data-sp="${id}" aria-label="Especie ${sp.number} sin descubrir"><span class="num">#${String(sp.number).padStart(2, "0")}</span><span class="sil">?</span><span class="nm">???</span></button>`;
    const canShow = !!CFG.Visuals.ById[id];
    const hasB = e.broteAt != null, hasT = e.talladoAt != null;
    return `<button class="acard t${tier} ${hasB ? "owned" : ""}" data-sp="${id}" style="--frame:${css(rar.frameColor)};background:${BIOME_BG[sp.biome]}">
      <span class="num">#${String(sp.number).padStart(2, "0")}</span><span class="gem" style="color:${css(rar.frameColor)}">◆</span>
      ${canShow ? `<img data-lazy="${id}" alt="">` : `<span class="glyph">${ELEMENT_ICON[sp.elements[0]] || "◆"}</span>`}
      <span class="nm">${sp.broteName}</span><span class="els">${sp.elements.map((x) => ELEMENT_ICON[x]).join("")}</span>
      <span class="pair"><i class="${hasB ? "on" : ""}" title="Carta Brote">B</i><i class="${hasT ? "on" : ""}" title="Carta Tallado">T</i></span>
      ${!hasB ? `<span class="tag">${tier === 1 ? "Visto" : "Restaurado"}</span>` : ""}</button>`;
  };
  openScreen("📖", "Álbum del Nexo", `${prog.discovered}/${prog.totalSpecies} especies descubiertas · ${prog.cards}/${prog.totalCards} cartas (Brote y Tallado)`,
    `<div class="bar album-bar"><i style="width:${(prog.cards / prog.totalCards) * 100}%"></i></div>
    <div class="chips">${["Todos", ...biomes].map((b) => { const bp = prog.byBiome[b]; return `<button class="chip-btn ${albumBiome === b ? "on" : ""}" data-biome="${b}">${b === "Todos" ? "Todos" : CFG.Species.Biomes[b].name}${bp ? ` <small>${bp.cards}/${bp.total * 2}</small>` : ""}${bp && bp.complete ? " 🖼️" : ""}</button>`; }).join("")}</div>
    <div class="album-grid">${list.map(cardFor).join("")}</div>
    <div class="note-box">Completar las cartas de un bioma da un marco especial. Las siluetas muestran su número: descúbrelas viéndolas, restaurándolas u obteniéndolas.</div>`,
  (m) => {
    m.querySelectorAll("[data-biome]").forEach((b) => b.addEventListener("click", () => { albumBiome = b.dataset.biome; openAlbum(); }));
    m.querySelectorAll("[data-sp]").forEach((b) => b.addEventListener("click", () => openBestiary(b.dataset.sp)));
    // Retratos 3D bajo demanda: solo las cartas descubiertas que están a la vista
    const io = new IntersectionObserver((entries) => {
      for (const en of entries) {
        if (!en.isIntersecting) continue;
        const img = en.target; io.unobserve(img);
        const id = img.dataset.lazy, e = P.collection[id];
        requestAnimationFrame(() => { img.src = portrait(id, e && e.talladoAt != null && e.broteAt == null ? "Tallado" : "Brote"); img.classList.add("ready"); });
      }
    }, { root: m, rootMargin: "80px" });
    m.querySelectorAll("img[data-lazy]").forEach((img) => io.observe(img));
    modalCleanup = () => io.disconnect();
  });
}
// Bestiario: la ficha se revela por niveles (1 visto · 2 restaurado u obtenido · 3 Tallado)
function openBestiary(id) {
  const sp = species(id), e = P.collection[id], tier = CollectionRules.bestiaryTier(e), lore = CFG.SpeciesLore.ById[id], rar = RARITY(sp.rarity);
  if (tier === 0) return toast("❔", `Especie #${sp.number}: aún sin descubrir. Encuéntrala en el valle, en un cofre o restaurando Opacos.`);
  const canShow = !!CFG.Visuals.ById[id];
  const val = (v) => (!v || v === "Pendiente" ? '<span class="pend">Pendiente (Biblia)</span>' : esc(v));
  const field = (min, label, v) => (tier >= min ? `<div class="lore-f"><b>${label}</b><p>${val(v)}</p></div>` : `<div class="lore-f locked"><b>${label}</b><p>🔒 ${min === 2 ? "Se revela al restaurarlo u obtenerlo" : "Se revela al tallarlo"}</p></div>`);
  const cardImg = (form, has) => (canShow ? `<img src="${portrait(id, form)}" class="${has ? "" : "shade"}" alt="">` : `<span class="glyph">${ELEMENT_ICON[sp.elements[0]] || "◆"}</span>`);
  openModal(`<div class="best-head"><span class="num">#${String(sp.number).padStart(2, "0")}</span><h2>${sp.broteName} <small>→ ${tier >= 2 ? sp.talladoName : "???"}</small></h2>
      <div class="best-tags"><span class="gemtag" style="color:${css(rar.frameColor)}">◆ ${rar.name}</span>${elementBadges(sp.elements)}<span class="biome-tag" style="background:${BIOME_BG[sp.biome]}">${CFG.Species.Biomes[sp.biome].name}</span></div></div>
    <div class="card-pair">
      <div class="mini-card ${e.broteAt != null ? "owned" : ""}" style="--frame:${css(rar.frameColor)};background:${BIOME_BG[sp.biome]}">${cardImg("Brote", tier >= 1)}<span>Brote</span>${e.broteAt != null ? "" : '<i class="tag">Sin carta</i>'}</div>
      <div class="mini-card ${e.talladoAt != null ? "owned" : ""}" style="--frame:${css(rar.frameColor)};background:${BIOME_BG[sp.biome]}">${tier >= 3 ? cardImg("Tallado", true) : '<span class="sil">?</span>'}<span>Tallado</span>${e.talladoAt != null ? "" : '<i class="tag">Sin carta</i>'}</div>
    </div>
    <div class="tier-row">Registro ${starsHtml([tier >= 1, tier >= 2, tier >= 3])} <span>${["", "Visto", "Restaurado u obtenido", "Tallado: ficha completa"][tier]}</span></div>
    <div class="lore">${field(1, "Concepto", lore?.concept)}${field(1, "Hábitat", lore?.habitat)}${field(1, "Brote", lore?.broteLook)}
      ${field(2, "Comportamiento", lore?.behavior)}${field(2, "Anatomía", lore?.anatomy)}${field(2, "Mezcla mítica", lore?.mythicMix)}${field(2, "Obtención", lore?.obtention)}${field(2, "Incubación", lore?.incubation)}${field(2, "Talento", lore?.talentText)}${field(2, "Firma", lore?.signatureText)}
      ${field(3, "Tallado", lore?.talladoLook)}${field(3, "Rasgo distintivo", lore?.distinctiveTrait)}${field(3, "Linaje", lore?.lineage)}${field(3, "Coste y Tallado", lore?.cost)}</div>
    <div class="sub" style="font-size:14px">Textos de la Biblia (SpeciesLore${lore?.page ? ", p. " + lore.page : ""}). ${e.count ? `Ejemplares obtenidos: ${e.count}.` : ""}</div>
    <button class="btn secondary" id="back" style="width:100%">← Volver al Álbum</button>`,
  (m) => m.querySelector("#back").addEventListener("click", () => openAlbum()), { cls: "bestiary" });
}

// ---------------- Criadero (incubadora) ----------------
function eggHtml(rarity, pr, big = false) {
  const c = RARITY(rarity).frameColor, stages = CFG.Incubation.CrackStages;
  return `<div class="egg-stage ${big ? "big" : ""}" style="--ec:${css(c)}"><i class="beam"></i><i class="ring r1"></i><i class="ring r2"></i>
    <div class="egg"><svg viewBox="0 0 60 80" class="cracks">${[["M30 8 L26 20 L33 28 L28 40", 0], ["M14 38 L22 44 L18 54 L26 60", 1], ["M46 30 L38 40 L44 50 L36 62", 2]].map(([d, i]) => `<path d="${d}" class="ck c${i + 1} ${pr >= stages[i] ? "on" : ""}"/>`).join("")}</svg></div></div>`;
}
function openCriadero() {
  if (!starterPet()) return toast("🥚", "Elige primero tu huevo junto al Gran Nexo.");
  const t = serverNow();
  const stored = Object.values(P.eggs).filter((e) => e.state === "Stored").sort((a, b) => (a.id < b.id ? -1 : 1));
  const pods = P.incubators.map((slot, i) => {
    const rule = CFG.Incubation.Slots[i], n = i + 1;
    if (!slot.unlocked) {
      const buy = rule.availableInBeta && rule.unlock === "Monedas";
      return `<div class="pod locked"><span class="em">🔒</span><b>Ranura ${n}</b><small>${esc(rule.label)}</small>${buy ? `<button class="btn small" data-buy="${n}" ${coins() < rule.price.Monedas ? "disabled" : ""}>Abrir · 🪙 ${fmt(rule.price.Monedas)}</button>` : ""}</div>`;
    }
    const egg = slot.eggId ? P.eggs[slot.eggId] : null;
    if (!egg) return `<div class="pod empty"><span class="em">🪺</span><b>Ranura ${n}</b><small>Libre</small>${stored.length ? `<button class="btn small jade" data-inc="${n}">Incubar huevo</button>` : "<small>Sin huevos guardados</small>"}</div>`;
    const pr = EggRules.progress(egg, t), ready = t >= egg.readyAt;
    return `<div class="pod busy ${ready ? "ready" : ""}" data-pod="${n}">${eggHtml(egg.rarity, pr)}<b>${RARITY(egg.rarity).name} · ${speciesName(egg.speciesId)}</b>
      <div class="bar"><i data-bar="${n}" style="width:${pr * 100}%"></i></div><small data-count="${n}">${ready ? "¡Listo para eclosionar!" : "Faltan " + durationText(egg.readyAt - t)}</small>
      ${ready ? `<button class="btn small" data-hatch="${n}">🐣 Eclosionar</button>` : ""}</div>`;
  }).join("");
  openScreen("🥚", "Criadero", `La especie se fija al obtener el huevo. El tiempo corre aunque cierres el juego (reloj del servidor). Sin aceleraciones de pago.`,
    `<div class="pods">${pods}</div>
    <div class="sec-title">Huevos guardados · ${EggRules.storedCount(P)}/${CFG.Incubation.EggStorageCapacity}</div>
    ${stored.length ? `<div class="egg-list">${stored.map((e) => `<div class="egg-row"><span class="egg-dot" style="--ec:${css(RARITY(e.rarity).frameColor)}"></span><div><b>Huevo ${RARITY(e.rarity).name} · ${speciesName(e.speciesId)}</b><small>${durationText(EggRules.seconds(e.rarity))} de incubación · de: ${{ Chest: "cofre", Rescue: "rescate", Test: "prueba" }[e.source.kind] || e.source.kind}</small></div><button class="btn small jade" data-egg="${e.id}">Incubar</button></div>`).join("")}</div>` : '<div class="note-box">No tienes huevos guardados. Llegan en cofres (Repisa de Cofres) y en etapas de Rescate del Acto I.</div>'}`,
  (m) => {
    const freeSlot = () => P.incubators.findIndex((s) => s.unlocked && !s.eggId) + 1;
    const incubate = (eggId, slot) => { if (!slot) return toast("🪺", "No hay ranuras libres"); const r = run("startIncubation", eggId, slot); toast(r.ok ? "🔥" : "⚠️", r.ok ? `Huevo en la ranura ${slot}: ${durationText(r.data.readyAt - serverNow())}` : errText(r.err)); refreshUI(); openCriadero(); };
    m.querySelectorAll("[data-inc]").forEach((b) => b.addEventListener("click", () => incubate(stored[0].id, +b.dataset.inc)));
    m.querySelectorAll("[data-egg]").forEach((b) => b.addEventListener("click", () => incubate(b.dataset.egg, freeSlot())));
    m.querySelectorAll("[data-buy]").forEach((b) => b.addEventListener("click", () => { const r = run("buyIncubatorSlot", +b.dataset.buy); toast(r.ok ? "🔓" : "⚠️", r.ok ? `Ranura ${r.data.slot} abierta` : errText(r.err)); refreshUI(); openCriadero(); }));
    m.querySelectorAll("[data-hatch]").forEach((b) => b.addEventListener("click", () => hatchEgg(+b.dataset.hatch)));
    // Cuenta atrás en vivo con los tiempos absolutos del "servidor"
    const timer = setInterval(() => {
      const now2 = serverNow();
      let changed = false;
      P.incubators.forEach((slot, i) => {
        const egg = slot.eggId && P.eggs[slot.eggId]; if (!egg) return;
        const n = i + 1, pr = EggRules.progress(egg, now2), ready = now2 >= egg.readyAt;
        const c = m.querySelector(`[data-count="${n}"]`), bar = m.querySelector(`[data-bar="${n}"]`);
        if (c && !ready) c.textContent = "Faltan " + durationText(egg.readyAt - now2);
        if (bar) bar.style.width = pr * 100 + "%";
        m.querySelectorAll(`[data-pod="${n}"] .ck`).forEach((ck, k) => ck.classList.toggle("on", pr >= CFG.Incubation.CrackStages[k]));
        if (ready && !m.querySelector(`[data-hatch="${n}"]`)) changed = true;
      });
      if (changed) openCriadero();
    }, 500);
    modalCleanup = () => clearInterval(timer);
  });
}
async function hatchEgg(slot) {
  const egg = P.eggs[P.incubators[slot - 1].eggId];
  if (!egg) return;
  const rarity = egg.rarity;
  openModal(`<div class="hatch-cer">${eggHtml(rarity, 1, true)}<div class="sub" id="hc-txt">El huevo tiembla…</div></div>`, null, { noClose: true, cls: "ceremony" });
  const root = $("#modal-root .egg-stage");
  root.classList.add("shake");
  await sleep(1300);
  root.classList.add("burst");
  const r = run("hatchEgg", slot);
  await sleep(500);
  if (!r.ok) { closeModal(); toast("⚠️", errText(r.err)); return openCriadero(); }
  const pet = P.pets[r.data.petId], sp = species(pet.speciesId), rar = RARITY(sp.rarity);
  if (lotUnlocked()) vfx.sparkle(incPos.clone().add(V(0, 5, 0)), 0xffe08a);
  openModal(`<div class="card monster reveal" style="border-color:${css(rar.frameColor)}"><div class="gem" style="color:${css(rar.frameColor)}">◆ ${rar.name}</div><div class="els">${elementBadges(sp.elements)}</div>
      <img class="portrait" src="${portrait(pet.speciesId, "Brote")}" alt=""><div class="pedestal"></div><div class="title">¡${sp.broteName}!</div><div class="species">${esc(CFG.SpeciesLore.ById[pet.speciesId]?.concept || sp.concept || "")}</div></div>
    <div class="reward-list">${r.data.newSpecies ? '<div class="reward-item"><span class="em">📖</span>¡Especie nueva en el Álbum del Nexo!</div>' : ""}${r.data.newCard ? '<div class="reward-item"><span class="em">🃏</span>Carta Brote nueva</div>' : '<div class="reward-item"><span class="em">🃏</span>Otro ejemplar para tu colección</div>'}
      <div class="reward-item"><span class="em">🧬</span>Rasgos: Veta ${pet.traits.veta} · Temple ${pet.traits.temple}</div></div>
    <div class="row"><button class="btn secondary" id="sheet">Ver ficha</button><button class="btn" id="ok">¡Bienvenido!</button></div>`,
  (m) => { m.querySelector("#ok").addEventListener("click", () => openCriadero()); m.querySelector("#sheet").addEventListener("click", () => openPetSheet(pet.id)); }, { noClose: true, cls: "ceremony" });
  refreshUI();
}

// ---------------- Repisa de Cofres ----------------
function chestContentLines(chest) {
  const c = chest.contents;
  const lines = itemLines(c);
  for (const e of c.eggs) lines.push(["🥚", `Huevo ${RARITY(species(e.speciesId).rarity).name}: ${speciesName(e.speciesId)}`]);
  for (const k of chest.codex || []) { const ce = CFG.Codex.ById[k]; if (ce) lines.push([ce.symbol, `Carta del Códice: ${esc(ce.title)}`]); }
  return lines;
}
function openChests() {
  if (!starterPet()) return toast("🥚", "Elige primero tu huevo junto al Gran Nexo.");
  const chests = Object.values(P.chests).sort((a, b) => a.obtainedAt - b.obtainedAt || (a.id < b.id ? -1 : 1));
  const SRC = { Reward: "recompensa de etapa", Quest: "encargo", Test: "prueba" };
  openScreen("🧰", "Repisa de Cofres", `${chests.length}/${CFG.Chests.MaxStoredChests} cofres · todos se ganan jugando; ninguno se vende`,
    chests.length ? `<div class="chest-list">${chests.map((ch) => { const def = CFG.Chests.ById[ch.chestType], odds = ChestRules.odds(P, ch.id); return `<div class="chest-card" style="--cg:${css(def.glow)}">${chestIcon(ch.chestType, 64)}<div class="cc-body"><b>${def.name}</b><small>De: ${SRC[ch.source.kind] || ch.source.kind}</small>
      <ul>${chestContentLines(ch).map(([e, t]) => `<li><span>${e}</span>${t}</li>`).join("")}</ul><div class="fixed-note">✔ ${esc(odds.note)}</div></div><button class="btn" data-open="${ch.id}">Abrir</button></div>`; }).join("")}</div>`
      : '<div class="note-box">No tienes cofres. Se ganan en primeras victorias de etapa, tesoros, regiones con 3 estrellas, encargos y al restaurar a Copalia.</div>',
  (m) => m.querySelectorAll("[data-open]").forEach((b) => b.addEventListener("click", () => openChestCeremony(b.dataset.open))));
}
async function openChestCeremony(chestId) {
  const ch = P.chests[chestId]; if (!ch) return;
  const def = CFG.Chests.ById[ch.chestType], lines = chestContentLines(ch);
  openModal(`<div class="chest-cer tier${def.tier}" style="--cg:${css(def.glow)};--cc:${css(def.color)}"><i class="rays"></i>${chestIcon(ch.chestType, 120)}<div class="bb-name">${def.name}</div></div><div class="reward-list" id="cc-items"></div><div id="cc-foot"></div>`, null, { noClose: true, cls: "ceremony" });
  const cer = $("#modal-root .chest-cer");
  cer.classList.add("shake");
  await sleep(1100);
  const r = run("openChest", chestId);
  if (!r.ok) { closeModal(); toast("⚠️", errText(r.err)); return openChests(); }
  cer.classList.remove("shake"); cer.classList.add("open");
  await sleep(500);
  const box = $("#cc-items");
  for (const [e, t] of lines) { box.insertAdjacentHTML("beforeend", `<div class="reward-item"><span class="em">${e}</span>${t}</div>`); await sleep(260); }
  $("#cc-foot").innerHTML = `<div class="row">${r.data.eggIds.length ? '<button class="btn secondary" id="to-inc">🥚 Ir al Criadero</button>' : ""}<button class="btn" id="ok">Guardar</button></div>`;
  $("#cc-foot #ok").addEventListener("click", () => (Object.keys(P.chests).length ? openChests() : closeModal()));
  $("#cc-foot #to-inc")?.addEventListener("click", () => openCriadero());
  refreshUI();
}

// ---------------- Tablón de Encargos ----------------
function openQuests() {
  if (!starterPet()) return toast("🥚", "Elige primero tu huevo junto al Gran Nexo.");
  QuestRules.refresh(P, serverNow()); save();
  const t = serverNow(), q = P.quests;
  const DIFF = { Easy: "Fácil", Medium: "Media", Hard: "Difícil" };
  const card = (slot, kind, index) => {
    const def = QuestRules.def(slot.questId), done = slot.progress >= slot.target;
    return `<div class="quest ${slot.claimed ? "claimed" : done ? "done" : ""}"><span class="qd d-${def.difficulty}">${kind === "Weekly" ? "Semanal" : DIFF[def.difficulty]}</span><b>${esc(def.title)}</b><small>${esc(def.description)}</small>
      <div class="bar"><i style="width:${(slot.progress / slot.target) * 100}%"></i></div><div class="kv"><span>${fmt(slot.progress)} / ${fmt(slot.target)}</span><span>🪙 ${fmt(slot.coins)}${kind === "Weekly" ? " + " + CFG.Chests.ById[CFG.Quests.WeeklyChest].name : ""}</span></div>
      ${slot.claimed ? '<div class="q-ok">✔ Reclamado</div>' : `<button class="btn small ${done ? "" : "secondary"}" data-claim="${kind}:${index}" ${done ? "" : "disabled"}>${done ? "Reclamar" : "En curso"}</button>`}</div>`;
  };
  const claimedDaily = q.daily.filter((s) => s.claimed).length;
  openScreen("📋", "Tablón de Encargos", `Torre del Nexo · se renuevan a las 00:00 UTC (hora del servidor). El progreso lo registra el servidor.`,
    `<div class="sec-title">Diarios · se renuevan en ${durationText(QuestRules.nextDailyReset(t) - t)}</div>
    <div class="quest-list">${q.daily.map((s, i) => card(s, "Daily", i + 1)).join("")}</div>
    <div class="bonus ${q.dailyBonusClaimed ? "got" : ""}">${chestIcon(CFG.Quests.DailyBonusChest, 40)}<div><b>Los tres diarios: ${CFG.Chests.ById[CFG.Quests.DailyBonusChest].name}</b><small>${q.dailyBonusClaimed ? "¡Conseguido hoy!" : `${claimedDaily}/${q.daily.length} reclamados`}</small></div></div>
    <div class="sec-title">Semanal · se renueva en ${durationText(QuestRules.nextWeeklyReset(t) - t)}</div>
    ${q.weekly ? `<div class="quest-list">${card(q.weekly, "Weekly", 1)}</div>` : '<div class="note-box">Sin encargo semanal disponible.</div>'}`,
  (m) => m.querySelectorAll("[data-claim]").forEach((b) => b.addEventListener("click", () => {
    const [kind, index] = b.dataset.claim.split(":");
    const r = run("claimQuest", kind, +index);
    if (!r.ok) return toast("⚠️", errText(r.err));
    toast("🪙", `+${fmt(r.data.coins)} Monedas`);
    if (r.data.chestType) toast("🧰", `${CFG.Chests.ById[r.data.chestType].name} a la Repisa de Cofres`);
    refreshUI(); openQuests();
  })));
}

// ---------------- Mapa del Acto I ----------------
function regionBands() {
  return CFG.Encounters.Regions.map((r) => {
    const ids = [...r.stages, r.secret, ...(r.index === 3 ? [CFG.Encounters.Acts.ActoI.boss] : [])];
    const xs = ids.map((id) => CFG.Encounters.ById[id].mapPos[0]);
    return { r, min: Math.min(...xs), max: Math.max(...xs) };
  }).map((b, i, all) => ({ ...b, from: i === 0 ? 0 : (all[i - 1].max + b.min) / 2, to: i === all.length - 1 ? 1 : (b.max + all[i + 1].min) / 2 }));
}
function openAdventure() {
  if (!starterPet()) return toast("🥚", "Elige primero tu huevo junto al Gran Nexo.");
  const act = CFG.Encounters.Acts.ActoI, vertical = innerWidth < 640;
  const pos = (id) => { const [x, y] = CFG.Encounters.ById[id].mapPos; return vertical ? { left: 9 + y * 64, top: x * 100 } : { left: x * 100, top: 12 + y * 76 }; };
  const total = CFG.Encounters.Order.reduce((a, id) => a + countStars(P.story.stars[id]), 0);
  const repeatsLeft = CFG.Encounters.Repeat.DailyRewardedRepeats - (P.story.repeatDay === Math.floor(serverNow() / 86400) ? P.story.repeatCount : 0);
  const next = nextStage();
  const edges = [];
  for (const id of CFG.Encounters.Order) for (const req of CFG.Encounters.ById[id].requires) edges.push([req, id]);
  const pct = (v) => `${v}%`;
  const svg = `<svg class="paths" viewBox="0 0 100 100" preserveAspectRatio="none">${edges.map(([a, b]) => { const pa = pos(a), pb = pos(b); const eb = CFG.Encounters.ById[b]; const cls = P.story.cleared[b] ? "done" : EncounterRules.isUnlocked(P, b) ? "open" : "shut"; return `<line x1="${pa.left}" y1="${pa.top}" x2="${pb.left}" y2="${pb.top}" class="${cls} ${eb.stageType === "Secreta" ? "secret" : ""}" vector-effect="non-scaling-stroke"/>`; }).join("")}</svg>`;
  const bands = regionBands().map(({ r, from, to }) => { const p = r.palette; const cleared = EncounterRules.regionCleared(P, r.index); const st = r.stages.reduce((a, id) => a + countStars(P.story.stars[id]), 0);
    const geo = vertical ? `top:${from * 100}%;height:${(to - from) * 100}%;left:0;right:0` : `left:${from * 100}%;width:${(to - from) * 100}%;top:0;bottom:0`;
    return `<div class="band" style="${geo};background:linear-gradient(${vertical ? "90deg" : "180deg"}, ${css(p.sky)}, ${css(p.ground)});--acc:${css(p.accent)}"><span class="band-art">${CFG.Codex.ById[r.clearCodex]?.symbol || ""}</span><div class="band-name"><b>${r.index}. ${esc(r.name)}</b><small>${esc(r.subtitle)} · nv ${r.levels} · ★ ${st}/12${cleared ? " · ✔" : ""}</small></div></div>`; }).join("");
  const nodes = CFG.Encounters.Order.map((id) => {
    const e = CFG.Encounters.ById[id], unlocked = EncounterRules.isUnlocked(P, id), cleared = !!P.story.cleared[id], st = P.story.stars[id];
    const secretHidden = e.stageType === "Secreta" && !unlocked;
    const p = pos(id);
    return `<button class="node ${e.stageType.toLowerCase()} ${cleared ? "cleared" : unlocked ? "open" : "locked"} ${id === next ? "next" : ""}" data-stage="${id}" style="left:${pct(p.left)};top:${pct(p.top)}" aria-label="${esc(secretHidden ? "Etapa secreta" : e.name)}">
      <span class="ic">${secretHidden ? "?" : STAGE_ICON[e.stageType]}</span>${e.stage ? `<span class="no">${e.stage}</span>` : ""}${!unlocked && !cleared ? '<span class="lk">🔒</span>' : ""}${starsHtml(st)}</button>`;
  }).join("");
  openScreen("🗺️", esc(act.name), `${esc(act.biomeRule)} · ★ ${total}/${CFG.Encounters.Order.length * 3} · repeticiones con premio hoy: ${repeatsLeft}`,
    `<div class="act-map ${vertical ? "vertical" : ""}">${bands}${svg}${nodes}</div>
    <div class="legend"><span>⚔️ Combate</span><span>👑 Élite</span><span>💰 Tesoro</span><span>🪶 Rescate</span><span>❔ Secreta</span><span>🌳 Jefe</span></div>`,
  (m) => {
    m.querySelectorAll("[data-stage]").forEach((b) => b.addEventListener("click", () => openStage(b.dataset.stage)));
    m.querySelector(".node.next")?.scrollIntoView({ block: "center", inline: "center" });
  }, { cls: "adventure" });
}
// ---------------- Ficha de etapa: rivales, reto, premios y equipo ----------------
let teamDraft = null;
function openStage(encId, keepDraft = false) {
  const e = CFG.Encounters.ById[encId];
  // Durante el tutorial el primer Opaco se restaura en persona, sin pantallas extra (Fase 1)
  if (!tutorialDone() && e.worldMarker && step() === "FirstBattle") return startBattle(encId);
  const unlocked = EncounterRules.isUnlocked(P, encId), cleared = P.story.cleared[encId], st = P.story.stars[encId];
  const region = CFG.Encounters.Regions[e.region - 1];
  if (!keepDraft) teamDraft = EncounterRules.participantsFor(P, encId).slice(0, e.teamSize);
  const opps = EncounterRules.opponentsFor(P, encId);
  const lockMsg = () => {
    if (e.requiresRegionStars && e.requires.every((r) => P.story.cleared[r])) return `Consigue las 3 estrellas en todas las etapas de ${CFG.Encounters.Regions[e.requiresRegionStars - 1].name}.`;
    const miss = e.requires.filter((r) => !P.story.cleared[r]).map((r) => `«${CFG.Encounters.ById[r].name}»`);
    return `Supera antes ${miss.join(" y ")}.`;
  };
  const oppHtml = e.opponents.map((o, i) => {
    const sid = opps[i], g = o.guardianId ? guardian(o.guardianId) : null, mod = o.modifier && CFG.Encounters.Modifiers[o.modifier];
    const els = g ? g.elements : sid ? species(sid).elements : [];
    return `<div class="opp"><img src="${sid ? portrait(sid, o.form) : ""}" class="opaco" alt=""><div><b>${g ? esc(g.name) : sid ? "Opaco de " + speciesName(sid, o.form) : "???"}</b><small>Nv ${o.level} · ${o.form}</small><div>${elementBadges(els)}${mod ? `<span class="mod">${mod.name} ${Object.entries(mod.statMultipliers).map(([k, v]) => `+${Math.round((v - 1) * 100)} % ${k}`).join(" ")}</span>` : ""}${o.rooted || g ? `<span class="mod root">🌱 ${g ? g.talentName : "Raíces"}</span>` : ""}</div></div></div>`;
  }).join("");
  const rew = [];
  const fc = !cleared;
  if (fc) {
    rew.push(["🪙", `${fmt(e.baseReward.Monedas)} Monedas`], ["⭐", `${fmt(e.baseReward.petXp * xpMult())} XP al equipo`]);
    if (e.firstClearBonus) for (const [ic, tx] of itemLines(CFG.Rewards.ById[e.firstClearBonus])) rew.push([ic, tx]);
    if (e.firstClearChest) rew.push([chestIcon(e.firstClearChest, 30), CFG.Chests.ById[e.firstClearChest].name]);
    if (e.firstClearDecor) rew.push([DECOR_ICON[CFG.Decor.ById[e.firstClearDecor].shape], CFG.Decor.ById[e.firstClearDecor].name]);
    for (const c of e.firstClearCodex || []) { const ce = CFG.Codex.ById[c]; if (ce) rew.push([ce.symbol, `Carta: ${esc(ce.title)}`]); }
  } else {
    const scale = CFG.Encounters.Repeat.RewardScale;
    rew.push(["🔁", `Repetición: 🪙 ${fmt(Math.floor(e.baseReward.Monedas * scale))} · ⭐ ${fmt(Math.floor(e.baseReward.petXp * scale) * xpMult())} XP`]);
  }
  if (e.rescue) rew.push(["🥚", `${Math.round(e.rescue.eggChance * 100)} % de huevo de ${speciesName(e.rescue.speciesId)} (tirada del servidor)`]);
  const pets = Object.values(P.pets).sort((a, b) => b.level - a.level || (a.id < b.id ? -1 : 1));
  const isBoss = e.stageType === "Jefe";
  const cost = EncounterRules.teamCost(P, teamDraft);
  const avg = teamDraft.length ? Math.round(teamDraft.reduce((a, id) => a + P.pets[id].level, 0) / teamDraft.length) : 0;
  const teamHtml = e.stageType === "Tesoro" ? "" : `<div class="sec-title">Tu equipo · hasta ${e.teamSize} ${isBoss ? `· coste ${cost}/${EncounterRules.BOSS_TEAM_COST}` : ""}</div>
    <div class="pick-grid team">${pets.map((p) => { const i = teamDraft.indexOf(p.id); return `<button class="pick ${i >= 0 ? "on" : ""}" data-team="${p.id}"><img src="${portrait(p.speciesId, p.form)}" alt=""><span>${esc(petName(p))}</span><small>Nv ${p.level} · ${p.form}</small>${i >= 0 ? `<i class="ord">${i + 1}</i>` : ""}</button>`; }).join("")}</div>
    ${avg && avg < e.recommendedLevel ? `<div class="warn">⚠️ Nivel medio ${avg}: se recomienda nivel ${e.recommendedLevel}.</div>` : ""}${isBoss && cost > EncounterRules.BOSS_TEAM_COST ? '<div class="warn">⚠️ El equipo cuesta demasiado para el jefe.</div>' : ""}`;
  openModal(`<div class="stage-head" style="--acc:${css(region.palette.accent)}"><span class="stype">${STAGE_ICON[e.stageType]} ${STAGE_TYPE[e.stageType]}</span><h2>${esc(e.name)}</h2><div class="sub">${esc(region.name)} · nivel recomendado ${e.recommendedLevel}${cleared ? ` · ganada ${cleared.wins} ${cleared.wins === 1 ? "vez" : "veces"}` : ""}</div></div>
    <p class="intro">${esc(e.intro)}</p>
    ${oppHtml ? `<div class="sec-title">Rivales${e.opponents.length > 1 ? ` · ${e.opponents.length}, uno tras otro` : ""}</div><div class="opp-list">${oppHtml}</div>` : ""}
    <div class="sec-title">Estrellas ${starsHtml(st)}</div>
    <ul class="star-list"><li class="${st && st[0] ? "on" : ""}">★ ${e.stageType === "Tesoro" ? "Abrir el cofre" : "Ganar"}</li><li class="${st && st[1] ? "on" : ""}">★★ ${e.stageType === "Tesoro" ? "Acertar en dos intentos o menos" : "Sin perder monstruos"}</li><li class="${st && st[2] ? "on" : ""}">★★★ ${esc(e.challenge.text)}</li></ul>
    <div class="sec-title">${fc ? "Premio de primera victoria" : "Premio"}</div><div class="rew-chips">${rew.map(([i, t]) => `<span>${i} ${t}</span>`).join("")}</div>
    ${teamHtml}
    ${unlocked ? `<button class="btn" id="play" style="width:100%;margin-top:10px">${e.stageType === "Tesoro" ? "💰 Abrir el cofre" : isBoss ? "🌳 Enfrentar a Copalia" : "⚔️ Restaurar"}</button>` : `<div class="warn">🔒 ${lockMsg()}</div>`}
    <button class="btn secondary" id="map" style="width:100%;margin-top:8px">🗺️ Volver al mapa</button>`,
  (m) => {
    m.querySelectorAll("[data-team]").forEach((b) => b.addEventListener("click", () => {
      const id = b.dataset.team;
      if (teamDraft.includes(id)) teamDraft = teamDraft.filter((x) => x !== id);
      else if (teamDraft.length < e.teamSize) teamDraft.push(id);
      else teamDraft = [...teamDraft.slice(0, e.teamSize - 1), id];
      openStage(encId, true);
      $("#modal-root .modal").scrollTop = 99999;
    }));
    m.querySelector("#map").addEventListener("click", () => openAdventure());
    m.querySelector("#play")?.addEventListener("click", () => {
      if (e.stageType === "Tesoro") return openTreasure(encId);
      if (!teamDraft.length) return toast("🐾", "Elige al menos un monstruo");
      const cur = EncounterRules.participantsFor(P, encId);
      if (teamDraft.join() !== cur.join()) { const r = run("setTeam", teamDraft); if (!r.ok) return toast("⚠️", errText(r.err)); }
      const can = DOM.Actions.canStartEncounter(P, encId);
      if (!can.ok) return toast("⚠️", errText(can.err));
      closeModal(); startBattle(encId);
    });
  }, { cls: "stage" });
}
// ---------------- Tesoro: acertijo elemental ----------------
function openTreasure(encId, feedback) {
  const e = CFG.Encounters.ById[encId], rd = e.riddle, seal = CFG.Elements.ById[rd.sealElement];
  const attempts = P.story.treasureAttempts[encId] || 0;
  openModal(`<div class="riddle" style="--seal:${css(seal.color)}"><div class="seal-chest ${feedback ? "shake" : ""}">${chestIcon(e.firstClearChest || "Plata", 110)}<span class="seal">${ELEMENT_ICON[rd.sealElement]}</span></div>
      <div class="bb-kicker">Sello de ${rd.sealElement}</div><h2>${esc(e.name)}</h2><p class="prompt">${esc(rd.prompt)}</p></div>
    ${feedback ? `<div class="warn">${feedback}</div>` : ""}
    <div class="riddle-opts">${rd.options.map((el) => `<button class="ropt" data-el="${el}" style="background:linear-gradient(180deg, ${css(CFG.Elements.ById[el].color.map((x) => Math.min(255, x + 40)))}, ${css(CFG.Elements.ById[el].color)})"><span>${ELEMENT_ICON[el]}</span>${el}</button>`).join("")}</div>
    <div class="sub" style="font-size:14px">Pista: piensa qué elemento es eficaz contra ${rd.sealElement}. Puedes reintentar sin coste${attempts ? ` · intentos: ${attempts}` : ""}.</div>`,
  (m) => m.querySelectorAll("[data-el]").forEach((b) => b.addEventListener("click", async () => {
    const prev = (P.story.stars[encId] || [false, false, false]).slice();
    const r = run("solveTreasure", encId, b.dataset.el);
    if (!r.ok) return toast("⚠️", errText(r.err));
    if (!r.data.solved) return openTreasure(encId, `El sello de ${rd.sealElement} resiste a ${b.dataset.el}. Intento ${r.data.attempts}: prueba otro elemento.`);
    const c = $("#modal-root .seal-chest"); c.classList.add("open");
    m.querySelectorAll(".ropt").forEach((x) => (x.disabled = true));
    await sleep(1200);
    refreshUI();
    showStageResult(encId, r.data, prev);
  })), { cls: "stage" });
}

// ---------------- Códice del Nexo ----------------
function codexHint(id) {
  for (const encId of CFG.Encounters.Order) { const e = CFG.Encounters.ById[encId]; if ((e.firstClearCodex || []).includes(id)) return e.stageType === "Secreta" ? `Etapa secreta «${e.name}»` : `Supera «${e.name}»`; }
  const r = CFG.Encounters.Regions.find((x) => x.clearCodex === id); if (r) return `Completa la región ${r.name}`;
  const c = Object.values(CFG.Chests.ById).find((x) => x.fixed && (x.fixed.codex || []).includes(id)); if (c) return `Abre el ${c.name}`;
  return "Sigue explorando";
}
function openCodex() {
  const KIND = [["Lore", "📜 Cartas de lore"], ["Guardian", "🪶 Guardianes"], ["Velada", "🌘 Pistas Veladas"]];
  const got = CFG.Codex.Order.filter((id) => P.codex[id] != null).length;
  const prog = CollectionRules.progress(P);
  openScreen("📜", "Códice del Nexo", `${got}/${CFG.Codex.Order.length} cartas · cada jefe, región y Opaco deja una`,
    `${KIND.map(([k, title]) => `<div class="sec-title">${title}</div><div class="codex-grid">${CFG.Codex.Order.filter((id) => CFG.Codex.ById[id].kind === k).map((id) => { const c = CFG.Codex.ById[id], has = P.codex[id] != null; return has
      ? `<div class="codex-card k-${k}"><span class="sym">${c.symbol}</span><b>${esc(c.title)}</b><p>${esc(c.text)}</p></div>`
      : `<div class="codex-card locked"><span class="sym">?</span><b>Carta sellada</b><p>🔒 ${esc(codexHint(id))}</p></div>`; }).join("")}</div>`).join("")}
    <button class="travel" id="bestiary" style="width:100%;margin-top:12px"><span class="em">📖</span><span>Bestiario: ${prog.discovered}/${prog.totalSpecies} especies<small>Las fichas se revelan al ver, restaurar y tallar</small></span></button>`,
  (m) => m.querySelector("#bestiary").addEventListener("click", () => openAlbum()));
}

$("#btn-pet").addEventListener("click", () => openPetSheet());
$("#btn-sanctuary").addEventListener("click", () => openSanctuary());
$("#btn-album").addEventListener("click", () => openAlbum());
$("#btn-adventure").addEventListener("click", () => openAdventure());
$("#btn-nexo").addEventListener("click", () => openNexoMenu());
$("#companion").addEventListener("click", () => openPetSheet());

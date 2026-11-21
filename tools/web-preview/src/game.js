// NEXORA · Vista previa web jugable del vertical slice (Valle Copal).
// Reglas: mismas cifras y motor de combate que el proyecto Roblox (config exportada
// desde Luau + engine.js con paridad comprobada). Arte: BLOCKOUTS provisionales.
import * as THREE from "three";

const CFG = NexoraNormalize.normalizeConfig(window.NEXORA_CONFIG);
const ENG = NexoraEngine.createEngine(CFG);
const { Stats, Leveling, BattleEngine: BE, BattleAI: AI, ElementChart } = ENG;
const W = CFG.World;

// =====================================================================
// Utilidades
// =====================================================================
const $ = (s) => document.querySelector(s);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const lerp = (a, b, t) => a + (b - a) * t;
const now = () => Date.now() / 1000;
const v3 = (a) => new THREE.Vector3(a[0], a[1], a[2]);
const col = (rgb) => new THREE.Color(rgb[0] / 255, rgb[1] / 255, rgb[2] / 255);
const css = (rgb) => `rgb(${rgb[0]},${rgb[1]},${rgb[2]})`;
const fmt = (n) => Math.floor(n).toLocaleString("es-MX");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const isTouch = matchMedia("(pointer: coarse)").matches;
const species = (id) => CFG.Species.ById[id];
const ability = (id) => CFG.Abilities.ById[id];
const ELEMENT_ICON = { Agua: "💧", Fuego: "🔥", Aire: "🌀", Tierra: "⛰️", Metal: "⚙️", Flora: "🌿", Rayo: "⚡", Artificio: "🔩", Luz: "✨", Sombra: "🌙", Mente: "🌀", Astral: "⭐" };
const FOOD_ICON = { RacionBasica: "🌽", RacionBioma: "🥗", Festin: "🍲", RacionDorada: "🍯" };
const STATUS_TXT = { Burn: "Quemadura", Paralysis: "Parálisis", Stun: "Aturdido", Sleep: "Dormido", Confuse: "Confusión" };
const STAT_TXT = { ATQ: "ATQ", DEF: "DEF", VEL: "VEL", ESE: "ESE", Precision: "precisión", Evasion: "evasión" };

// =====================================================================
// Perfil (localStorage simula el DataStore: cierra la pestaña y vuelve)
// =====================================================================
const SAVE_KEY = "nexora.preview.profile.v1";
const DEV_KEY = "nexora.preview.dev.v1";
function newProfile() {
  return {
    v: 1, createdAt: now(), coins: 0, gems: 0, items: {}, pets: {}, serial: 1, companion: null,
    lotUnlocked: false, habitat: { slots: [false, false, false, false], last: now(), accrued: 0, bonus: 0 },
    cleared: {}, repeat: { day: 0, count: 0 }, step: "Intro", completed: false,
    firsts: {}, unlocks: {}, pending: {}, ledger: {}, logins: 0,
  };
}
function loadProfile() {
  try { const raw = localStorage.getItem(SAVE_KEY); if (raw) return JSON.parse(raw); } catch (e) { /* almacenamiento no disponible */ }
  return null;
}
let P = loadProfile() || newProfile();
let saveTimer = 0;
function save() { clearTimeout(saveTimer); saveTimer = setTimeout(() => { try { localStorage.setItem(SAVE_KEY, JSON.stringify(P)); } catch (e) { /* sin persistencia */ } }, 150); }
let DEV = { xp: true };
try { DEV = Object.assign(DEV, JSON.parse(localStorage.getItem(DEV_KEY) || "{}")); } catch (e) { /* usar valores por defecto */ }
const saveDev = () => { try { localStorage.setItem(DEV_KEY, JSON.stringify(DEV)); } catch (e) { /* sin persistencia */ } };
const xpMult = () => (DEV.xp ? 10 : 1);

// =====================================================================
// Reglas (espejo de Server/Domain; el servidor de Roblox es la autoridad real)
// =====================================================================
const STEPS = CFG.Onboarding.Steps.map((s) => s.id);
const stepInfo = (id) => CFG.Onboarding.Steps.find((s) => s.id === id);
const starterPet = () => Object.values(P.pets).find((p) => p.source === "Starter");
const companion = () => (P.companion ? P.pets[P.companion] : null);
const anyPlaced = () => P.habitat.slots.some(Boolean);
const DONE = {
  Intro: () => !!P.firsts.intro_finished,
  ChooseEgg: () => !!starterPet(),
  Hatch: () => !!P.firsts.hatch_completed,
  MeetHome: () => P.lotUnlocked,
  PlaceInHabitat: anyPlaced,
  FirstFeed: () => !!P.firsts.first_feed,
  FirstBond: () => !!P.firsts.first_bond_gain,
  FirstBattle: () => !!P.cleared.valle_r1_e1,
  ClaimReward: () => !!P.firsts.first_reward_claimed,
};
function refreshOnboarding() {
  if (P.completed) return;
  let i = STEPS.indexOf(P.step);
  while (i < STEPS.length) {
    const id = STEPS[i];
    if (id === "Done") { P.completed = true; P.firsts.tutorial_completed ??= now(); toast("🌳", "¡Tutorial completado! El valle es tuyo."); break; }
    if (DONE[id] && DONE[id]()) { i++; P.step = STEPS[i]; } else break;
  }
}
function first(name) { if (!P.firsts[name]) P.firsts[name] = now(); }

function petName(pet) { const sp = species(pet.speciesId); return pet.nickname || (pet.form === "Tallado" ? sp.talladoName : sp.broteName); }
function addXp(pet, amount) {
  const r = Leveling.addXp(pet.level, pet.xp, Math.floor(amount * xpMult()));
  const gained = r.level - pet.level;
  pet.level = r.level; pet.xp = r.xp;
  if (gained > 0) { toast("⬆️", `${petName(pet)} sube a nivel ${pet.level}`); petFx(pet.id, "level"); }
  return r;
}
function addBond(pet, n) { const before = pet.bond; pet.bond = Math.min(CFG.Progression.Bond.Max, pet.bond + n); return pet.bond - before; }

function habitatRate() {
  let total = 0;
  for (const id of P.habitat.slots) {
    if (!id || !P.pets[id]) continue;
    const pet = P.pets[id], sp = species(pet.speciesId);
    let r = CFG.Rarities.ById[sp.rarity].coinsPerHour;
    if (pet.form === "Brote") r *= CFG.Economy.Habitat.BroteProductionFactor;
    if (sp.biome === "ValleCopal") r *= 1 + CFG.Sanctuary.NativeBonus.coins;
    total += r;
  }
  return total;
}
function settleHabitat() {
  const h = P.habitat, t = now();
  const elapsed = clamp(t - h.last, 0, CFG.Economy.Habitat.OfflineCapSeconds);
  const rate = habitatRate();
  const coins = Math.floor((rate * elapsed) / 3600);
  h.accrued = Math.min(h.accrued + coins, Math.max((rate * CFG.Economy.Habitat.OfflineCapSeconds) / 3600, h.accrued));
  const xp = Math.floor((CFG.Economy.Habitat.PassiveXpPerMinute * elapsed) / 60);
  if (xp > 0) for (const id of h.slots) if (id && P.pets[id]) addXp(P.pets[id], xp);
  h.last = t;
}
function pendingCoins() {
  const h = P.habitat;
  const elapsed = clamp(now() - h.last, 0, CFG.Economy.Habitat.OfflineCapSeconds);
  return h.accrued + Math.floor((habitatRate() * elapsed) / 3600) + h.bonus;
}

const Actions = {
  finishIntro(skipped) { if (!P.firsts.intro_finished) { first("intro_finished"); P.introSkipped = skipped; } refreshOnboarding(); save(); },
  chooseStarter(eggId) {
    if (P.step !== "ChooseEgg" || starterPet()) return { ok: false, err: "NotNow" };
    const egg = CFG.Onboarding.StarterEggs.find((e) => e.eggId === eggId);
    const id = `U1-${P.serial++}`;
    P.pets[id] = { id, speciesId: egg.speciesId, form: "Brote", level: 1, xp: 0, bond: 0, nickname: null, source: "Starter", acquiredAt: now(), lastPlayedAt: 0, wins: 0 };
    P.companion = id; first("starter_egg_selected"); refreshOnboarding(); save();
    return { ok: true, petId: id };
  },
  ackHatch() { first("hatch_completed"); first("pet_follow_started"); refreshOnboarding(); save(); },
  visitHome() {
    if (!starterPet() || P.lotUnlocked) return false;
    P.lotUnlocked = true; P.habitat.last = now(); P.habitat.bonus = 50;
    grant("onboarding:gift", CFG.Rewards.ById.OnboardingGift);
    first("habitat_opened"); refreshOnboarding(); save();
    return true;
  },
  place(petId, slot) {
    if (P.habitat.slots.includes(petId)) return { ok: false, err: "Ya está en el hábitat" };
    if (P.habitat.slots[slot]) return { ok: false, err: "Lugar ocupado" };
    settleHabitat(); P.habitat.slots[slot] = petId; refreshOnboarding(); save(); return { ok: true };
  },
  remove(slot) { if (!P.habitat.slots[slot]) return { ok: false }; settleHabitat(); P.habitat.slots[slot] = false; refreshOnboarding(); save(); return { ok: true }; },
  collect() {
    settleHabitat();
    const coins = P.habitat.accrued + P.habitat.bonus;
    P.habitat.accrued = 0; P.habitat.bonus = 0; P.coins += coins; save();
    return coins;
  },
  feed(petId, foodId) {
    const pet = P.pets[petId], food = CFG.Economy.Foods[foodId];
    if (!pet || !food || (P.items[foodId] || 0) < 1) return { ok: false, err: "No tienes esa comida" };
    P.items[foodId] -= 1;
    addXp(pet, food.xp);
    const bond = addBond(pet, food.bond);
    first("first_feed"); if (bond > 0) first("first_bond_gain");
    refreshOnboarding(); save();
    return { ok: true, xp: food.xp * xpMult(), bond };
  },
  play(petId) {
    const pet = P.pets[petId];
    const wait = CFG.Progression.Bond.PlayCooldownSeconds - (now() - pet.lastPlayedAt);
    if (wait > 0 && !DEV.xp) return { ok: false, err: `Descansa ${Math.ceil(wait)} s` };
    pet.lastPlayedAt = now();
    const g = addBond(pet, CFG.Progression.Bond.PlayGain);
    if (g > 0) first("first_bond_gain");
    refreshOnboarding(); save();
    return { ok: true, bond: g };
  },
  evolve(petId) {
    const pet = P.pets[petId];
    const [ok, why] = Leveling.canEvolve(pet);
    if (!ok) return { ok: false, err: why };
    pet.form = "Tallado"; pet.evolvedAt = now(); save();
    return { ok: true };
  },
  buyFood(foodId, qty) {
    const food = CFG.Economy.Foods[foodId];
    if (!food.sold) return { ok: false, err: "No está a la venta" };
    const cost = food.price.Monedas * qty;
    if (P.coins < cost) return { ok: false, err: "Te faltan Monedas" };
    P.coins -= cost; P.items[foodId] = (P.items[foodId] || 0) + qty; save();
    return { ok: true };
  },
  claim(rewardId) {
    const r = P.pending[rewardId];
    if (!r || P.ledger[rewardId]) return null;
    P.coins += r.currencies.Monedas || 0; P.gems += r.currencies.Gemas || 0;
    for (const [k, n] of Object.entries(r.items)) P.items[k] = (P.items[k] || 0) + n;
    for (const id of r.petIds) if (P.pets[id] && r.petXp > 0) addXp(P.pets[id], r.petXp);
    for (const u of r.unlocks) P.unlocks[u] = now();
    delete P.pending[rewardId]; P.ledger[rewardId] = now();
    first("first_reward_claimed"); refreshOnboarding(); save();
    return r;
  },
};
function makeReward(id, spec, title) {
  const cur = {}, items = {}, unlocks = [];
  const add = (dst, src) => { for (const [k, n] of Object.entries(src || {})) dst[k] = (dst[k] || 0) + n; };
  let t = title;
  if (spec.bundleId) { const b = CFG.Rewards.ById[spec.bundleId]; add(cur, b.currencies); add(items, b.items); unlocks.push(...b.unlocks); t = t || b.title; }
  add(cur, spec.currencies); add(items, spec.items);
  return { id, title: t || "Recompensa", currencies: cur, items, unlocks, petXp: spec.petXp || 0, petIds: spec.petIds || [] };
}
function grant(id, bundle) {
  if (P.ledger[id]) return;
  P.pending[id] = makeReward(id, { bundleId: bundle.id });
  Actions.claim(id);
}

// =====================================================================
// Escena
// =====================================================================
const canvas = $("#scene");
const renderer = new THREE.WebGLRenderer({ canvas, antialias: !isTouch, powerPreference: "high-performance" });
renderer.setPixelRatio(Math.min(devicePixelRatio, isTouch ? 1.5 : 1.75));
renderer.setSize(innerWidth, innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
const scene = new THREE.Scene();
scene.fog = new THREE.Fog(0xe9c79f, 140, 560);
const camera = new THREE.PerspectiveCamera(55, innerWidth / innerHeight, 0.5, 1500);

const hemi = new THREE.HemisphereLight(0xffe6c0, 0x56704a, 0.95);
scene.add(hemi);
const sun = new THREE.DirectionalLight(0xffd29a, 2.4);
sun.position.set(-140, 160, 110);
sun.castShadow = true;
sun.shadow.mapSize.set(isTouch ? 1024 : 2048, isTouch ? 1024 : 2048);
Object.assign(sun.shadow.camera, { left: -190, right: 190, top: 190, bottom: -190, near: 10, far: 520 });
sun.shadow.bias = -0.0006;
scene.add(sun);
scene.add(sun.target);

// Cielo degradado (atardecer de copal)
{
  const geo = new THREE.SphereGeometry(900, 32, 16);
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, fog: false,
    uniforms: { top: { value: new THREE.Color(0x5f97cf) }, mid: { value: new THREE.Color(0xf3c58f) }, low: { value: new THREE.Color(0xe79a6a) } },
    vertexShader: "varying vec3 vP; void main(){ vP = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }",
    fragmentShader: "uniform vec3 top; uniform vec3 mid; uniform vec3 low; varying vec3 vP; void main(){ float h = vP.y; vec3 c = h > 0.0 ? mix(mid, top, smoothstep(0.0, 0.55, h)) : mix(mid, low, smoothstep(0.0, -0.3, h)); float sunG = pow(max(dot(vP, normalize(vec3(-0.55,0.35,0.45))),0.0), 18.0); c += vec3(1.0,0.75,0.45)*sunG*0.7; gl_FragColor = vec4(c,1.0); }",
  });
  scene.add(new THREE.Mesh(geo, mat));
}

const GEO = {
  sphere: new THREE.SphereGeometry(1, 22, 16),
  sphereLow: new THREE.IcosahedronGeometry(1, 1),
  box: new THREE.BoxGeometry(1, 1, 1),
  cyl: new THREE.CylinderGeometry(1, 1, 1, 20),
  cone: new THREE.ConeGeometry(1, 1, 16),
  torus: new THREE.TorusGeometry(1, 0.08, 8, 40),
  dodeca: new THREE.DodecahedronGeometry(1, 0),
};
const matCache = new Map();
function mat(color, o = {}) {
  const key = `${color}|${JSON.stringify(o)}`;
  if (!o.unique && matCache.has(key)) return matCache.get(key);
  const m = new THREE.MeshStandardMaterial({
    color, roughness: o.rough ?? 0.85, metalness: o.metal ?? 0, flatShading: o.flat ?? false,
    emissive: o.emissive ?? 0x000000, emissiveIntensity: o.ei ?? 1, transparent: o.opacity != null, opacity: o.opacity ?? 1,
  });
  if (!o.unique) matCache.set(key, m);
  return m;
}
function mesh(geo, material, pos, scale, rot, parent = scene, shadows = true) {
  const m = new THREE.Mesh(geo, material);
  if (pos) m.position.copy(pos);
  if (scale) typeof scale === "number" ? m.scale.setScalar(scale) : m.scale.copy(scale);
  if (rot) m.rotation.set(rot[0], rot[1], rot[2]);
  m.castShadow = shadows; m.receiveShadow = shadows;
  parent.add(m);
  return m;
}
const V = (x, y, z) => new THREE.Vector3(x, y, z);
const spinners = [];
const PAL = { copal: 0xe8a848, glow: 0xffc460, stone: 0xc4b6a0, stoneDark: 0x7a6c60, clay: 0xb06240, jade: 0x3e967a, leaf: 0x56965c, leafDeep: 0x36704e, bark: 0x60463a, wood: 0x8c6442, papel: [0xe84a6e, 0xfaba32, 0x40aad6, 0x9660de, 0x68be60] };

// ---------- Suelo, colinas y río ----------
{
  // Anillos concéntricos: elevar el borde (colinas) no inclina el centro del valle
  const g = new THREE.RingGeometry(0.01, 620, 96, 40);
  g.rotateX(-Math.PI / 2);
  const c = new THREE.Color(), colors = [];
  const pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getZ(i);
    const n = Math.sin(x * 0.045) * Math.cos(z * 0.05) * 0.5 + Math.sin(x * 0.013 + z * 0.021) * 0.5;
    c.setRGB(0.42 + n * 0.05, 0.6 + n * 0.06, 0.32 + n * 0.04, THREE.SRGBColorSpace);
    colors.push(c.r, c.g, c.b);
    const d = Math.hypot(x, z);
    if (d > 260) pos.setY(i, Math.pow((d - 260) / 60, 2) * 2.2 + Math.sin(x * 0.03) * 4);
  }
  g.setAttribute("color", new THREE.Float32BufferAttribute(colors, 3));
  g.computeVertexNormals();
  const ground = new THREE.Mesh(g, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.95 }));
  ground.receiveShadow = true;
  scene.add(ground);
  // Montañas lejanas facetadas que enmarcan el valle
  for (let i = 0; i < 22; i++) {
    const a = (i / 22) * Math.PI * 2 + 0.3;
    const r = 420 + (i % 3) * 40;
    const h = 60 + ((i * 37) % 50);
    mesh(GEO.dodeca, mat(i % 2 ? 0x7d8f63 : 0x6c7f5a, { flat: true }), V(Math.cos(a) * r, h * 0.3, Math.sin(a) * r), V(70 + (i % 4) * 14, h, 60), [0, a, 0], scene, false);
  }
}
const riverCurve = new THREE.CatmullRomCurve3(W.River.points.map((p) => V(p[0], 0.25, p[2])));
function ribbon(curve, width, y, material) {
  const pts = curve.getPoints(80), verts = [], idx = [];
  for (let i = 0; i < pts.length; i++) {
    const t = curve.getTangent(i / (pts.length - 1));
    const n = V(-t.z, 0, t.x).normalize().multiplyScalar(width / 2);
    verts.push(pts[i].x + n.x, y, pts[i].z + n.z, pts[i].x - n.x, y, pts[i].z - n.z);
    if (i > 0) { const k = i * 2; idx.push(k - 2, k - 1, k, k - 1, k + 1, k); }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(verts, 3));
  g.setIndex(idx); g.computeVertexNormals();
  const m = new THREE.Mesh(g, material); m.receiveShadow = true; scene.add(m); return m;
}
ribbon(riverCurve, W.River.width + 8, 0.12, mat(0x8a6a48));
const water = ribbon(riverCurve, W.River.width, 0.3, new THREE.MeshStandardMaterial({ color: 0x47a3a6, roughness: 0.12, metalness: 0.2, transparent: true, opacity: 0.88, emissive: 0x0d3b40, emissiveIntensity: 0.4 }));

// ---------- Etiquetas sobre el mundo ----------
const labels = [];
function addLabel(pos, html, opts = {}) {
  const el = document.createElement("div");
  el.className = "wl" + (opts.cls ? " " + opts.cls : "");
  el.innerHTML = html;
  $("#labels").appendChild(el);
  const l = { el, pos: pos.clone(), max: opts.max ?? 110, obj: opts.obj, offset: opts.offset ?? 0, visible: opts.visible ?? (() => true) };
  labels.push(l);
  return l;
}
const tmpV = new THREE.Vector3();
function updateLabels() {
  for (const l of labels) {
    const p = l.obj ? tmpV.copy(l.obj.getWorldPosition(new THREE.Vector3())).add(V(0, l.offset, 0)) : tmpV.copy(l.pos);
    const dist = p.distanceTo(camera.position);
    p.project(camera);
    const show = l.visible() && p.z < 1 && dist < l.max && Math.abs(p.x) < 1.2 && Math.abs(p.y) < 1.2;
    l.el.style.display = show ? "" : "none";
    if (show) { l.el.style.left = `${(p.x * 0.5 + 0.5) * innerWidth}px`; l.el.style.top = `${(-p.y * 0.5 + 0.5) * innerHeight}px`; l.el.style.opacity = String(clamp(1.4 - dist / l.max, 0.25, 1)); }
  }
}
function floater(worldPos, text, cls = "") {
  const p = worldPos.clone().project(camera);
  if (p.z > 1) return;
  const el = document.createElement("div");
  el.className = "floater " + cls;
  el.textContent = text;
  el.style.left = `${(p.x * 0.5 + 0.5) * innerWidth}px`;
  el.style.top = `${(-p.y * 0.5 + 0.5) * innerHeight}px`;
  $("#labels").appendChild(el);
  setTimeout(() => el.remove(), 1150);
}

// ---------- Plaza ----------
const plazaC = v3(W.Plaza.center);
function disc(r, h, pos, color, o = {}, parent = scene) { return mesh(GEO.cyl, mat(color, o), pos, V(r, h, r), null, parent); }
disc(W.Plaza.radius, 0.6, V(plazaC.x, 0.3, plazaC.z), PAL.stone);
[[W.Plaza.radius - 2, PAL.stoneDark], [W.Plaza.radius - 3, PAL.stone], [W.Plaza.radius - 9, PAL.stoneDark], [W.Plaza.radius - 10, PAL.stone], [7, PAL.copal], [6, PAL.stone]].forEach(([r, c], i) => disc(r, 0.62 + i * 0.02, V(plazaC.x, 0.31 + i * 0.01, plazaC.z), c));
mesh(GEO.box, mat(PAL.stone), V(0, 0.32, -18), V(12, 0.6, 30));
// Grecas: escalonados en el anillo exterior
for (let i = 0; i < 36; i++) {
  const a = (i / 36) * Math.PI * 2, r = W.Plaza.radius - 5.5;
  mesh(GEO.box, mat(PAL.copal), V(plazaC.x + Math.cos(a) * r, 0.66, plazaC.z + Math.sin(a) * r), V(1.4, 0.12, 1.4), [0, -a, 0], scene, false);
}
// Papel picado
{
  const posts = [V(-26, 0, 22), V(26, 0, 22), V(-26, 0, -4), V(26, 0, -4)];
  posts.forEach((p) => mesh(GEO.cyl, mat(PAL.wood), V(p.x, 10, p.z), V(0.45, 20, 0.45)));
  [[0, 1], [2, 3], [0, 2], [1, 3]].forEach(([a, b], s) => {
    const A = posts[a].clone().setY(19.5), B = posts[b].clone().setY(19.5), n = Math.floor(A.distanceTo(B) / 2.4);
    for (let i = 1; i < n; i++) {
      const t = i / n, p = A.clone().lerp(B, t); p.y -= Math.sin(t * Math.PI) * 1.8;
      const flag = mesh(new THREE.PlaneGeometry(1.3, 1.5), new THREE.MeshStandardMaterial({ color: PAL.papel[(i + s) % 5], side: THREE.DoubleSide, roughness: 0.9 }), p, null, null, scene, false);
      flag.lookAt(p.clone().add(B.clone().sub(A).cross(V(0, 1, 0))));
    }
  });
}

// ---------- Gran Nexo ----------
const tree = new THREE.Group();
const treeBase = v3(W.GranNexo.position);
tree.position.copy(treeBase);
scene.add(tree);
let nexoHeart;
{
  const H = W.GranNexo.trunkHeight, R = W.GranNexo.trunkRadius;
  const profile = [];
  for (let i = 0; i <= 12; i++) { const t = i / 12; profile.push(new THREE.Vector2(R * (1.55 - t * 0.85 + Math.pow(1 - t, 6) * 0.9), t * H)); }
  const trunkGeo = new THREE.LatheGeometry(profile, 18);
  const tp = trunkGeo.attributes.position;
  for (let i = 0; i < tp.count; i++) { const y = tp.getY(i), a = (y / H) * 1.6; const x = tp.getX(i), z = tp.getZ(i); tp.setX(i, x * Math.cos(a) - z * Math.sin(a) + Math.sin(y * 0.08) * 1.5); tp.setZ(i, x * Math.sin(a) + z * Math.cos(a)); }
  trunkGeo.computeVertexNormals();
  mesh(trunkGeo, mat(PAL.bark, { flat: true }), null, null, null, tree);
  for (let i = 0; i < 9; i++) {
    const a = (i / 9) * Math.PI * 2 + 0.2, len = 14 + (i % 3) * 5;
    const root = mesh(GEO.cyl, mat(PAL.bark, { flat: true }), V(Math.cos(a) * (R + len / 2 - 2), 1, Math.sin(a) * (R + len / 2 - 2)), V(1.6, len, 1.4), null, tree);
    root.rotation.set(Math.PI / 2 - 0.08, 0, 0); root.rotation.order = "YXZ"; root.rotation.y = -a + Math.PI / 2;
  }
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2 + 0.3, start = V(0, H * 0.72, 0);
    const tip = V(Math.cos(a) * W.GranNexo.canopyRadius * 0.6, H * 0.72 + 12 + (i % 2) * 7, Math.sin(a) * W.GranNexo.canopyRadius * 0.6);
    const mid = start.clone().add(tip).multiplyScalar(0.5);
    const br = mesh(GEO.cyl, mat(PAL.bark, { flat: true }), mid, V(1.5, start.distanceTo(tip), 1.5), null, tree);
    br.lookAt(tip.clone().add(tree.position)); br.rotateX(Math.PI / 2);
    for (let k = 0; k < 3; k++) mesh(GEO.dodeca, mat(k % 2 ? PAL.leaf : PAL.leafDeep, { flat: true }), tip.clone().add(V((k - 1) * 6, 4 + (k % 2) * 3, (k % 2) * 5 - 2)), V(11 - k, 8, 11 - k), [k, i, 0], tree);
    if (i % 2 === 0) {
      const lantern = mesh(GEO.sphere, mat(PAL.glow, { emissive: 0xffa640, ei: 1.6 }), tip.clone().add(V(0, -5, 0)), V(1.1, 1.4, 1.1), null, tree, false);
      if (i % 4 === 0) { const pl = new THREE.PointLight(0xffb653, 40, 26, 1.6); lantern.add(pl); }
    }
  }
  mesh(GEO.dodeca, mat(PAL.leaf, { flat: true }), V(0, H + 10, 0), V(24, 14, 24), [0.3, 0.2, 0], tree);
  mesh(GEO.dodeca, mat(PAL.leafDeep, { flat: true }), V(8, H + 4, -6), V(16, 10, 16), [0.6, 0.4, 0], tree);
  nexoHeart = mesh(GEO.sphere, mat(PAL.glow, { emissive: 0xffa030, ei: 2.2, unique: true }), V(0, 9, R * 1.18), V(2.6, 3.3, 1.6), null, tree, false);
  const hl = new THREE.PointLight(0xffb653, 60, 30, 1.5); nexoHeart.add(hl);
  addLabel(treeBase.clone().add(V(0, H + 30, 0)), "Gran Nexo<small>El árbol es el menú: toca su corazón</small>", { max: 260 });
}

// ---------- Huevos iniciales ----------
const eggs = {};
for (const egg of CFG.Onboarding.StarterEggs) {
  const p = v3(W.StarterEggPedestals[egg.eggId]);
  disc(3.2, 1.4, V(p.x, 0.7, p.z), PAL.stone);
  disc(2.5, 1.6, V(p.x, 0.9, p.z), PAL.copal, { opacity: 0.85, rough: 0.2 });
  const g = new THREE.Group(); g.position.set(p.x, 4.3, p.z); scene.add(g);
  const shell = mesh(GEO.sphere, mat(0xe8a848, { rough: 0.35, unique: true }), null, V(1.6, 2.15, 1.6), null, g);
  // Espiral tallada idéntica en los tres huevos (la elección es por intuición)
  const helix = new THREE.CatmullRomCurve3(Array.from({ length: 40 }, (_, i) => { const t = i / 39, a = t * Math.PI * 5, y = -1.7 + t * 3.4, r = 1.62 * Math.sqrt(Math.max(0.05, 1 - (y / 2.15) ** 2)); return V(Math.cos(a) * r, y, Math.sin(a) * r); }));
  mesh(new THREE.TubeGeometry(helix, 120, 0.09, 6), mat(0xb07230, { rough: 0.5 }), null, null, null, g, false);
  const glow = new THREE.PointLight(col(egg.pulseColor), 0, 14, 1.8); g.add(glow);
  eggs[egg.eggId] = { group: g, shell, glow, egg, base: p };
}

// ---------- Estaciones ----------
for (const [id, st] of Object.entries(W.Stations)) {
  const p = v3(st.position), face = Math.atan2(treeBase.x - p.x, treeBase.z - p.z);
  const g = new THREE.Group(); g.position.copy(p); g.rotation.y = face; scene.add(g);
  disc(7, 0.8, V(0, 0.4, 0), PAL.stoneDark, {}, g);
  mesh(GEO.box, mat(st.implemented ? PAL.clay : 0x8d7d70, { flat: true }), V(0, 3.6, 0), V(9, 6.4, 6), null, g);
  const roof = mesh(GEO.cone, mat(PAL.papel[id.length % 5], { flat: true }), V(0, 8.6, 0), V(7.6, 3.6, 7.6), [0, Math.PI / 4, 0], g);
  roof.geometry = new THREE.ConeGeometry(1, 1, 4);
  mesh(GEO.box, mat(0x3a271d), V(0, 3, 3.05), V(5, 3.4, 0.2), null, g);
  addLabel(p.clone().add(V(0, 13, 0)), `${st.label}${st.implemented ? "" : "<small>Próximamente</small>"}`, { max: 120 });
}
// Mirador: puertas selladas a los biomas futuros
for (const gate of W.BiomeGates) {
  const p = v3(gate.position), g = new THREE.Group(); g.position.copy(p); g.lookAt(treeBase.x, 0, treeBase.z); scene.add(g);
  const elementByBiome = { MareaCoralina: "Agua", CumbreBrasa: "Fuego", MesetaFulgor: "Rayo", VeloAstral: "Astral" };
  const c = col(CFG.Elements.ById[elementByBiome[gate.biome]].color);
  [-6, 6].forEach((x) => mesh(GEO.box, mat(PAL.stone, { flat: true }), V(x, 10, 0), V(3, 20, 3), null, g));
  mesh(GEO.box, mat(PAL.stone, { flat: true }), V(0, 21, 0), V(16, 3, 3.2), null, g);
  mesh(GEO.box, new THREE.MeshStandardMaterial({ color: c, transparent: true, opacity: 0.55, emissive: c, emissiveIntensity: 0.35, roughness: 0.1 }), V(0, 10, 0), V(9, 18, 0.5), null, g, false);
  const b = CFG.Species.Biomes[gate.biome];
  addLabel(p.clone().add(V(0, 25, 0)), `${b.name}<small>${b.act} · sellado</small>`, { max: 160 });
}

// ---------- Lote Hogar del jugador (lote 3, centrado al sur) ----------
const LOT_INDEX = 2;
const lotC = v3(W.Lots.positions[LOT_INDEX]);
const slotWorld = W.Lots.slotOffsets.map((o) => lotC.clone().add(v3(o)));
const collectorPos = lotC.clone().add(v3(W.Lots.collectorOffset));
let collectorCoinsLabel;
W.Lots.positions.forEach((pos, i) => {
  const c = v3(pos), mine = i === LOT_INDEX;
  mesh(GEO.box, mat(mine ? 0x83b066 : 0x76a35e), V(c.x, 0.35, c.z), V(W.Lots.size[0], 0.7, W.Lots.size[1]));
  for (const [sx, sz, w, d] of [[0, -1, W.Lots.size[0], 1.4], [0, 1, W.Lots.size[0], 1.4], [-1, 0, 1.4, W.Lots.size[1]], [1, 0, 1.4, W.Lots.size[1]]])
    mesh(GEO.box, mat(PAL.stone, { flat: true }), V(c.x + (sx * W.Lots.size[0]) / 2, 0.9, c.z + (sz * W.Lots.size[1]) / 2), V(w, 1.4, d));
  if (!mine) { addLabel(c.clone().add(V(0, 6, -W.Lots.size[1] / 2)), "Lote libre", { max: 90 }); return; }
  disc(16, 0.3, lotC.clone().add(v3(W.Lots.habitatOffset)).setY(0.75), 0x96be78);
  slotWorld.forEach((p, s) => { disc(3.2, 1.2, V(p.x, 1.3, p.z), PAL.copal, { rough: 0.4 }); addLabel(V(p.x, 2.6, p.z), `<small>Lugar ${s + 1}</small>`, { max: 40 }); });
  const jar = new THREE.LatheGeometry([0, 1.6, 2.1, 2.2, 1.8, 1.0, 1.1].map((r, k) => new THREE.Vector2(r, k * 0.8)), 20);
  mesh(jar, mat(PAL.clay, { rough: 0.7 }), collectorPos.clone().setY(0.7));
  collectorCoinsLabel = addLabel(collectorPos.clone().add(V(0, 7.5, 0)), "", { max: 70 });
  const inc = lotC.clone().add(v3(W.Lots.incubatorOffset));
  disc(2.8, 1.4, V(inc.x, 0.8, inc.z), PAL.stone);
  const ring = mesh(GEO.torus, mat(PAL.glow, { emissive: 0xffa640, ei: 1.2 }), V(inc.x, 4, inc.z), V(2.6, 2.6, 2.6), [Math.PI / 2, 0, 0], scene, false);
  spinners.push(ring);
  addLabel(V(inc.x, 7.5, inc.z), "Incubadora<small>Próximamente</small>", { max: 60 });
  const vit = lotC.clone().add(v3(W.Lots.vitrinaOffset));
  [-1, 0, 1].forEach((k) => mesh(GEO.box, mat(PAL.wood, { opacity: 0.85 }), V(vit.x + k * 5, 3.2, vit.z), V(4, 6, 3)));
  addLabel(V(vit.x, 8, vit.z), "Vitrina<small>3 Tallados · próximamente</small>", { max: 60 });
  addLabel(lotC.clone().add(V(0, 9, -W.Lots.size[1] / 2)), "Tu Lote Hogar", { max: 200, visible: () => P.lotUnlocked });
});
for (const b of W.Bridges) mesh(GEO.box, mat(0x8c6442, { flat: true }), V(b[0], 1, b[2]), V(10, 1, W.River.width + 12));
// Chinampas y flores
[-120, -40, 40, 130].forEach((x, i) => {
  const p = V(x, 0.5, 64 + (i % 2) * 4);
  mesh(GEO.box, mat(PAL.leafDeep), p, V(12, 1.2, 7));
  for (let k = -2; k <= 2; k++) mesh(GEO.sphere, mat(PAL.papel[(k + 5 + i) % 5]), p.clone().add(V(k * 2, 1, 0)), 0.75);
});
// Arbustos y cempasúchil dispersos (determinista)
{
  const rnd = new ENG.Rng(2024);
  for (let i = 0; i < 70; i++) {
    const a = rnd.next() * Math.PI * 2, r = 70 + rnd.next() * 190;
    const p = V(Math.cos(a) * r, 0, Math.sin(a) * r);
    if (Math.abs(p.z - 64) < 14 || (p.z > 85 && p.z < 140 && p.x > -125 && p.x < 175)) continue;
    if (rnd.next() < 0.55) mesh(GEO.dodeca, mat(rnd.next() < 0.5 ? PAL.leaf : PAL.leafDeep, { flat: true }), p.setY(2), V(3 + rnd.next() * 3, 2.5 + rnd.next() * 2, 3 + rnd.next() * 3), [rnd.next(), rnd.next(), 0]);
    else { const t = V(p.x, 0, p.z); mesh(GEO.cyl, mat(PAL.bark), t.clone().setY(4), V(0.7, 8, 0.7)); mesh(GEO.dodeca, mat(PAL.leaf, { flat: true }), t.clone().setY(10), V(5, 5, 5), [rnd.next(), 0, 0]); }
  }
  for (let i = 0; i < 40; i++) { const a = rnd.next() * Math.PI * 2, r = 36 + rnd.next() * 30; mesh(GEO.sphere, mat(0xf0962a), V(Math.cos(a) * r, 0.6, Math.sin(a) * r + 8), 0.55, null, scene, false); }
}
// Sendero a la Linde
for (let k = 0; k <= 9; k++) { const t = k / 9; disc(2.6, 0.3, V(-24 - 96 * t, 0.2, 12 - 52 * t * t), PAL.stone); }

// ---------- Linde de las Chinampas: Opacos ----------
const encounterSpots = {};
for (const encId of CFG.Encounters.Order) {
  const enc = CFG.Encounters.ById[encId], mk = W.Encounters[enc.worldMarker], p = v3(mk.position);
  disc(mk.radius * 0.6, 0.3, V(p.x, 0.2, p.z), 0x7c7c84);
  for (let k = 0; k < 6; k++) { const a = k * 1.05 + 2.2; mesh(GEO.dodeca, mat(0x68686f, { flat: true }), V(p.x + Math.cos(a) * 14, 1.2, p.z + Math.sin(a) * 14), V(1.8, 1.6 + (k % 3), 1.8), [k, a, 0]); }
  const fog = [];
  for (let k = 0; k < 8; k++) { const f = mesh(GEO.sphere, new THREE.MeshBasicMaterial({ color: 0xb4b4bd, transparent: true, opacity: 0.16, depthWrite: false }), V(p.x + Math.cos(k) * 5, 1.5, p.z + Math.sin(k) * 5), V(5, 2.2, 5), null, scene, false); fog.push(f); }
  encounterSpots[encId] = { pos: p, fog, creature: null, label: addLabel(p.clone().add(V(0, 9, 0)), "", { max: 120 }) };
}

// =====================================================================
// Criaturas (BLOCKOUTS provisionales por arquetipo; ver docs/art/STARTERS_REDESIGN.md)
// =====================================================================
function buildCreature(speciesId, form, opaco = false) {
  const vis = CFG.Visuals.ById[speciesId];
  const pal = form === "Tallado" ? vis.tallado : vis.brote;
  const T = form === "Tallado";
  const root = new THREE.Group(), body = new THREE.Group();
  root.add(body);
  const parts = { tail: [], gills: [], legs: [], spin: [], glow: [] };
  const mats = [];
  const M = (rgb, o = {}) => { const m = mat(col(rgb), Object.assign({ rough: 0.6, unique: true }, o)); mats.push(m); return m; };
  const S = (parent, m, pos, sc, rot) => mesh(GEO.sphere, m, pos, sc, rot, parent);
  const bodyM = M(pal.body, { rough: speciesId === "xolumi" ? 0.25 : 0.65 }), bellyM = M(pal.belly), accM = M(pal.accent), glowM = M(pal.emissive, { emissive: col(pal.emissive), ei: T ? 0.75 : 0.45 });
  parts.glow.push(glowM);
  function eyes(parent, at, spread, size) {
    for (const s of [-1, 1]) {
      const e = new THREE.Group(); e.position.copy(at).add(V(s * spread, 0, 0)); parent.add(e);
      if (!T) {
        S(e, M([250, 250, 246], { rough: 0.2 }), V(0, 0, 0), V(size, size * 1.1, size * 0.7));
        S(e, M(pal.eye, { rough: 0.1 }), V(0, -size * 0.05, size * 0.45), V(size * 0.62, size * 0.7, size * 0.4));
        S(e, M([255, 255, 255], { emissive: col([255, 255, 255]), ei: 0.6 }), V(s * -size * 0.2, size * 0.25, size * 0.75), size * 0.18);
      } else {
        S(e, M([248, 240, 222], { rough: 0.2 }), V(0, 0, 0), V(size * 1.1, size * 0.55, size * 0.6), [0, 0, s * 0.28]);
        S(e, M(pal.iris, { emissive: col(pal.iris), ei: 0.7 }), V(0, 0, size * 0.36), V(size * 0.5, size * 0.46, size * 0.3));
        mesh(GEO.box, M([10, 8, 8]), V(0, 0, size * 0.56), V(size * 0.12, size * 0.6, size * 0.08), null, e);
        mesh(GEO.box, accM, V(-s * size * 0.1, size * 0.55, size * 0.1), V(size * 1.3, size * 0.22, size * 0.3), [0, 0, s * 0.42], e);
      }
    }
  }
  const legs = (n, y, xs, zs, r, h, m) => { for (let i = 0; i < n; i++) { const side = i % 2 ? 1 : -1, row = Math.floor(i / 2), z = zs[row]; const l = mesh(GEO.cyl, m, V(side * xs, y - h / 2, z), V(r, h, r), null, body); parts.legs.push(l); } };

  switch (vis.archetype) {
    case "Opossum": {
      S(body, bodyM, V(0, T ? 1.0 : 1.15, 0), T ? V(0.85, 0.62, 1.65) : V(0.95, 0.8, 1.25));
      S(body, glowM, V(0, T ? 0.72 : 0.85, 0.35), V(0.6, 0.45, 0.7));
      if (T) for (let k = -1; k <= 1; k++) mesh(GEO.box, M([30, 24, 22]), V(k * 0.22, 0.72, 0.95), V(0.08, 0.5, 0.1), null, body);
      const head = new THREE.Group(); head.position.set(0, T ? 1.45 : 1.75, T ? 1.65 : 1.2); body.add(head);
      S(head, bodyM, V(0, 0, 0), T ? V(0.6, 0.5, 0.7) : 0.66);
      S(head, bellyM, V(0, -0.12, 0.2), V(0.5, 0.42, 0.55));
      const snout = mesh(GEO.cone, bellyM, V(0, -0.15, T ? 0.95 : 0.82), V(0.28, T ? 1.0 : 0.75, 0.24), [Math.PI / 2, 0, 0], head);
      S(head, M([30, 20, 20]), V(0, -0.15, T ? 1.45 : 1.2), 0.13);
      for (const s of [-1, 1]) { const ear = S(head, accM, V(s * 0.42, T ? 0.42 : 0.55, -0.1), T ? V(0.22, 0.38, 0.1) : V(0.32, 0.32, 0.1), [0, 0, s * -0.3]); S(ear, M([230, 160, 160]), V(0, 0, 0.3), V(0.7, 0.7, 0.5)); }
      eyes(head, V(0, 0.16, T ? 0.5 : 0.52), T ? 0.25 : 0.27, T ? 0.17 : 0.21);
      legs(4, T ? 0.62 : 0.68, 0.5, [0.6, -0.6], 0.16, T ? 0.62 : 0.68, accM);
      let prev = V(0, T ? 0.95 : 1.1, T ? -1.5 : -1.15);
      const n = T ? 11 : 8;
      for (let i = 0; i < n; i++) {
        const t = i / n, a = t * (T ? 2.4 : 3.6);
        const p = V(0, prev.y + (T ? 0.12 : 0.22) * Math.cos(a), prev.z - (T ? 0.32 : 0.22) * Math.cos(a * 0.6));
        const isTip = i >= n - 2, ring = T && i % 2 === 0;
        const seg = S(body, isTip ? glowM : ring ? glowM : M(T ? [70, 64, 62] : [214, 176, 170]), p, (T ? 0.2 : 0.17) * (1 - t * 0.35));
        parts.tail.push(seg); prev = p;
      }
      snout.castShadow = true;
      break;
    }
    case "Axolotl": {
      const tilt = T ? -0.35 : 0;
      const torso = new THREE.Group(); torso.rotation.x = tilt; torso.position.y = T ? 0.4 : 0; body.add(torso);
      S(torso, bodyM, V(0, 0.85, -0.1), T ? V(0.85, 0.62, 1.7) : V(0.95, 0.58, 1.35));
      S(torso, bellyM, V(0, 0.62, 0), T ? V(0.7, 0.4, 1.4) : V(0.75, 0.38, 1.1));
      const head = new THREE.Group(); head.position.set(0, T ? 1.3 : 1.05, T ? 1.65 : 1.35); torso.add(head);
      S(head, bodyM, V(0, 0, 0), T ? V(1.05, 0.65, 0.85) : V(1.15, 0.72, 0.85));
      mesh(GEO.box, M([10, 10, 12]), V(0, -0.22, 0.78), V(0.7, 0.05, 0.08), null, head);
      if (T) for (const s of [-1, 1]) mesh(GEO.cone, M([250, 246, 236]), V(s * 0.22, -0.32, 0.74), V(0.07, 0.18, 0.07), [Math.PI, 0, 0], head);
      eyes(head, V(0, 0.25, 0.62), T ? 0.55 : 0.6, T ? 0.16 : 0.2);
      for (const s of [-1, 1]) for (let k = 0; k < 3; k++) {
        const g = new THREE.Group(); g.position.set(s * (T ? 0.95 : 1.0), 0.2 + k * 0.22, -0.25 - k * 0.1); g.rotation.set(-0.3 + k * 0.3, 0, s * (0.9 + k * 0.15)); head.add(g);
        mesh(GEO.cyl, glowM, V(0, 0.45, 0), V(0.06, 0.9, 0.06), null, g);
        for (let f = 0; f < 4; f++) S(g, glowM, V(0, 0.2 + f * 0.22, 0.06), V(0.16, 0.08, 0.12));
        parts.gills.push(g);
      }
      S(torso, M(T ? [214, 170, 74] : pal.accent, { opacity: 0.85 }), V(0, 1.0, T ? -1.9 : -1.6), V(0.08, 0.55, 1.1));
      const n = T ? 6 : 4;
      for (let i = 0; i < n; i++) { const side = i % 2 ? 1 : -1, z = [0.7, -0.7, 0][Math.floor(i / 2)]; const l = S(torso, bodyM, V(side * 0.85, 0.4, z), V(0.22, 0.38, 0.22)); parts.legs.push(l); }
      if (T) for (let k = 0; k < 5; k++) mesh(GEO.torus, M([226, 186, 80], { metal: 0.7, rough: 0.3, emissive: col([120, 80, 20]), ei: 0.4 }), V(0, 0.95, -0.9 + k * 0.42), V(0.78 - Math.abs(k - 2) * 0.06, 0.55, 0.6), [0.2 * k, Math.PI / 2, 0], torso);
      break;
    }
    case "Tortoise": {
      const shellGeo = new THREE.SphereGeometry(1, 22, 12, 0, Math.PI * 2, 0, Math.PI / 2);
      if (!T) {
        mesh(shellGeo, bodyM, V(0, 0.75, 0), V(1.25, 1.2, 1.45), null, body);
        for (let i = 0; i < 14; i++) { const a = i * 2.4, el = 0.35 + (i % 4) * 0.2; S(body, i % 3 ? bellyM : accM, V(Math.cos(a) * 1.25 * Math.cos(el), 0.75 + Math.sin(el) * 1.15, Math.sin(a) * 1.45 * Math.cos(el)), V(0.32, 0.12, 0.32)); }
      } else {
        [[1.35, 0.55, 0.75], [1.05, 0.5, 1.25], [0.72, 0.45, 1.7]].forEach(([r, h, y], i) => mesh(GEO.cyl, i % 2 ? bellyM : bodyM, V(0, y, 0), V(r * 1.05, h, r * 1.2), null, body));
        mesh(GEO.torus, accM, V(0, 1.0, 0), V(1.4, 1.6, 2.2), [Math.PI / 2, 0, 0], body);
        const ringM = M([236, 196, 96], { metal: 0.6, rough: 0.3, emissive: col(pal.emissive), ei: 0.8 });
        for (let k = 0; k < 2; k++) { const r = mesh(GEO.torus, ringM, V(0, 2.2, 0), 1.6 + k * 0.4, [Math.PI / 2 + k * 0.5, 0, k], body, false); parts.spin.push({ obj: r, axis: k ? "y" : "z", speed: k ? 0.6 : -0.9 }); }
        const discG = new THREE.Group(); discG.position.set(0, 3.1, 0); body.add(discG);
        mesh(GEO.cyl, M([28, 36, 70], { emissive: col([20, 30, 80]), ei: 0.6 }), V(0, 0, 0), V(0.95, 0.08, 0.95), null, discG);
        for (let s = 0; s < 9; s++) { const a = s * 0.7, r = 0.25 + (s % 3) * 0.22; S(discG, M([255, 240, 200], { emissive: col([255, 230, 170]), ei: 2 }), V(Math.cos(a) * r, 0.07, Math.sin(a) * r), 0.05); }
        parts.spin.push({ obj: discG, axis: "y", speed: 0.4 });
      }
      legs(4, 0.55, 0.85, [0.75, -0.75], T ? 0.34 : 0.3, 0.75, bellyM);
      const head = new THREE.Group(); head.position.set(0, T ? 1.05 : 0.9, T ? 1.85 : 1.6); body.add(head);
      mesh(GEO.cyl, bellyM, V(0, -0.15, -0.45), V(0.3, 0.6, 0.3), [Math.PI / 2.6, 0, 0], head);
      S(head, bellyM, V(0, 0, 0), T ? V(0.5, 0.45, 0.6) : 0.5);
      eyes(head, V(0, 0.12, 0.38), 0.22, T ? 0.13 : 0.16);
      break;
    }
    case "Agave": {
      S(body, bodyM, V(0, 0.9, 0), 0.72);
      const n = T ? 10 : 8;
      for (let i = 0; i < n; i++) { const a = (i / n) * Math.PI * 2, leaf = new THREE.Group(); leaf.position.set(0, 0.7, 0); leaf.rotation.set(0, a, 0); body.add(leaf); const l = mesh(GEO.cone, i % 2 ? bodyM : accM, V(0, 0.8, 0.9), V(0.32, T ? 2.2 : 1.6, 0.18), [0.9, 0, 0], leaf); if (T) mesh(GEO.cone, M([60, 160, 120]), V(0, 1.1, 0.12), V(0.05, 0.25, 0.05), null, l); }
      if (T) { mesh(GEO.cyl, M([120, 150, 90]), V(0, 3.2, 0), V(0.12, 4.5, 0.12), null, body); S(body, glowM, V(0, 5.6, 0), V(0.45, 0.7, 0.45)); }
      legs(3, 0.3, 0.35, [0.3, -0.3], 0.12, 0.5, M([120, 90, 60]));
      eyes(body, V(0, 1.05, 0.62), 0.24, T ? 0.13 : 0.17);
      break;
    }
    case "Armadillo": {
      S(body, bodyM, V(0, 1.0, 0), T ? V(1.0, 0.85, 1.45) : V(0.95, 0.85, 1.15));
      for (let k = -2; k <= 2; k++) { mesh(GEO.torus, M([40, 30, 28]), V(0, 1.0, k * (T ? 0.36 : 0.3)), V(0.98, 0.86, 1), [0, 0, 0], body, false); mesh(GEO.torus, glowM, V(0, 1.0, k * (T ? 0.36 : 0.3) + 0.12), V(0.95, 0.83, 0.5), null, body, false); }
      const head = new THREE.Group(); head.position.set(0, 0.85, T ? 1.45 : 1.15); body.add(head);
      S(head, bellyM, V(0, 0, 0), V(0.42, 0.38, 0.55));
      mesh(GEO.cone, bellyM, V(0, -0.05, 0.55), V(0.2, 0.5, 0.2), [Math.PI / 2, 0, 0], head);
      for (const s of [-1, 1]) S(head, bodyM, V(s * 0.25, 0.4, -0.1), V(0.12, 0.25, 0.08));
      if (T) mesh(GEO.cone, M([50, 44, 46]), V(0, 0.45, 0.2), V(0.16, 0.6, 0.16), [0.5, 0, 0], head);
      eyes(head, V(0, 0.15, 0.35), 0.18, 0.12);
      legs(4, 0.45, 0.55, [0.55, -0.55], 0.17, 0.45, accM);
      break;
    }
    case "Cicada": {
      S(body, bodyM, V(0, 1.0, -0.2), V(0.62, 0.6, 1.2));
      for (let k = 0; k < 3; k++) mesh(GEO.torus, accM, V(0, 1.0, -0.6 - k * 0.3), V(0.58 - k * 0.08, 0.56 - k * 0.08, 1), null, body, false);
      const head = new THREE.Group(); head.position.set(0, 1.15, 0.95); body.add(head);
      S(head, bodyM, V(0, 0, 0), V(0.6, 0.5, 0.5));
      eyes(head, V(0, 0.12, 0.3), 0.42, T ? 0.2 : 0.3);
      const wingM = M([210, 240, 250], { opacity: 0.45, rough: 0.1, emissive: col([120, 160, 180]), ei: 0.2 });
      for (const s of [-1, 1]) { const w = S(body, wingM, V(s * 0.55, 1.45, -0.5), T ? V(0.5, 0.06, 1.6) : V(0.4, 0.05, 1.1), [0.3, s * 0.3, s * 0.25]); parts.gills.push(w); }
      legs(6, 0.55, 0.45, [0.4, 0, -0.4], 0.06, 0.55, accM);
      break;
    }
    case "Jar": {
      const pot = new THREE.LatheGeometry([0.5, 0.95, 1.15, 1.1, 0.8, 0.55, 0.6].map((r, k) => new THREE.Vector2(r, k * 0.38)), 22);
      mesh(pot, bodyM, V(0, 0.45, 0), T ? V(1.3, 1.3, 1.3) : 1, null, body);
      mesh(GEO.torus, accM, V(0, T ? 1.6 : 1.25, 0), T ? V(1.4, 1.4, 1.4) : V(1.07, 1.07, 1.07), [Math.PI / 2, 0, 0], body, false);
      mesh(GEO.torus, bodyM, V(1.05, 1.5, 0), V(0.45, 0.45, 2.5), [0, Math.PI / 2, 0], body);
      mesh(GEO.cyl, accM, V(0, T ? 3.25 : 2.5, 0), V(0.75, 0.15, 0.75), null, body);
      S(body, accM, V(0, T ? 3.4 : 2.65, 0), 0.18);
      eyes(body, V(0, T ? 1.95 : 1.5, T ? 1.35 : 1.05), 0.3, T ? 0.14 : 0.18);
      for (const s of [-1, 1]) S(body, M([120, 110, 100]), V(s * 0.45, 0.3, 0), 0.32);
      if (T) for (const s of [-1, 1]) { mesh(GEO.cyl, bodyM, V(s * 1.6, 1.6, 0), V(0.28, 1.4, 0.28), [0, 0, s * 0.5], body); S(body, M([120, 110, 100]), V(s * 1.95, 0.95, 0), 0.45); }
      break;
    }
    case "Beetle": {
      S(body, bellyM, V(0, 0.85, 0), V(0.9, 0.7, 1.15));
      for (const s of [-1, 1]) S(body, bodyM, V(s * 0.42, 1.05, -0.05), V(0.55, 0.55, 1.15), [0, 0, s * (T ? 0.35 : 0.1)]);
      const head = new THREE.Group(); head.position.set(0, 0.95, 1.05); body.add(head);
      S(head, accM, V(0, 0, 0), V(0.48, 0.42, 0.42));
      mesh(GEO.cone, accM, V(0, 0.45, 0.25), V(0.14, T ? 1.2 : 0.6, 0.14), [0.45, 0, 0], head);
      if (T) mesh(GEO.cone, accM, V(0, 0.05, 0.55), V(0.1, 0.7, 0.1), [1.2, 0, 0], head);
      eyes(head, V(0, 0.1, 0.32), 0.2, 0.14);
      for (const s of [-1, 1]) { const a = mesh(GEO.cyl, accM, V(s * 0.2, 0.55, 0.1), V(0.03, 0.6, 0.03), [0.4, 0, s * 0.4], head); S(a, glowM, V(0, 0.55, 0), V(4, 0.25, 2)); }
      legs(6, 0.5, 0.6, [0.4, 0, -0.4], 0.06, 0.5, accM);
      break;
    }
    default: S(body, bodyM, V(0, 1, 0), 1); eyes(body, V(0, 1.2, 0.85), 0.3, 0.2);
  }
  root.scale.setScalar(T ? vis.talladoScale : vis.broteScale);
  root.traverse((o) => { if (o.isMesh) { o.castShadow = true; } });
  root.userData = { speciesId, form, parts, mats, body, phase: Math.random() * 10, opaco: 0, baseColors: mats.map((m) => m.color.clone()), baseEmissive: mats.map((m) => m.emissive.clone()) };
  setOpaco(root, opaco ? 1 : 0);
  return root;
}
const GREY = new THREE.Color(0x8a8a92);
function setOpaco(c, amount) {
  const u = c.userData; u.opaco = amount;
  u.mats.forEach((m, i) => { m.color.copy(u.baseColors[i]).lerp(GREY, amount * 0.85); m.emissive.copy(u.baseEmissive[i]).multiplyScalar(1 - amount * 0.9); });
}
function animateCreature(c, t, dt, moving) {
  const u = c.userData, p = u.parts, ph = t * (moving ? 9 : 2.2) + u.phase;
  u.body.position.y = moving ? Math.abs(Math.sin(ph)) * 0.35 : Math.sin(ph) * 0.06;
  u.body.scale.y = 1 + (moving ? 0 : Math.sin(ph) * 0.025);
  p.tail.forEach((s, i) => { s.position.x = Math.sin(t * 3 + i * 0.6) * 0.06 * i; });
  p.gills.forEach((g, i) => { g.rotation.y = Math.sin(t * 2.5 + i) * 0.25; });
  p.legs.forEach((l, i) => { l.rotation.x = moving ? Math.sin(ph + (i % 2) * Math.PI) * 0.6 : 0; });
  p.spin.forEach((s) => { s.obj.rotation[s.axis] += dt * s.speed; });
  if (u.react > 0) { u.react = Math.max(0, u.react - dt); const k = u.react / 0.9; u.body.position.y += Math.sin(k * Math.PI) * 1.6; u.body.rotation.y = (1 - k) * Math.PI * 2 * (u.reactSpin || 0); }
}

// =====================================================================
// Avatar del jugador (proporciones Roblox, blockout)
// =====================================================================
const player = new THREE.Group();
const avatar = new THREE.Group();
player.add(avatar);
const avParts = {};
{
  const skin = mat(0xe8b98d), shirt = mat(0xc4553a), pants = mat(0x2d2a3a), sash = mat(0xf2d27a);
  avParts.torso = mesh(GEO.box, shirt, V(0, 3.0, 0), V(2, 2, 1), null, avatar);
  mesh(GEO.box, sash, V(0, 2.3, 0.02), V(2.05, 0.35, 1.05), null, avatar);
  avParts.head = mesh(GEO.box, skin, V(0, 4.6, 0), V(1.25, 1.25, 1.25), null, avatar);
  for (const s of [-1, 1]) mesh(GEO.box, mat(0x221814), V(s * 0.25, 4.7, 0.63), V(0.14, 0.24, 0.04), null, avatar, false);
  mesh(GEO.box, mat(0x5a3a26), V(0, 5.3, -0.05), V(1.35, 0.3, 1.35), null, avatar);
  for (const s of [-1, 1]) {
    const arm = new THREE.Group(); arm.position.set(s * 1.5, 3.9, 0); avatar.add(arm); mesh(GEO.box, skin, V(0, -0.9, 0), V(0.95, 2, 0.95), null, arm); avParts[s < 0 ? "armL" : "armR"] = arm;
    const leg = new THREE.Group(); leg.position.set(s * 0.5, 2.0, 0); avatar.add(leg); mesh(GEO.box, pants, V(0, -1, 0), V(0.95, 2, 0.95), null, leg); avParts[s < 0 ? "legL" : "legR"] = leg;
  }
}
scene.add(player);
player.position.copy(v3(W.SpawnPoint)).setY(0);
let heading = Math.PI;

// =====================================================================
// Controles: teclado, joystick táctil y cámara orbital
// =====================================================================
const keys = new Set();
let camYaw = 0, camPitch = 0.42, camDist = isTouch ? 26 : 22, inputLocked = true;
addEventListener("keydown", (e) => { keys.add(e.key.toLowerCase()); if (e.key.toLowerCase() === "e" && !inputLocked) interact(); });
addEventListener("keyup", (e) => keys.delete(e.key.toLowerCase()));
const joy = { x: 0, y: 0, id: null };
{
  const pad = $("#joystick"), knob = pad.querySelector(".knob");
  const update = (cx, cy) => { const r = pad.getBoundingClientRect(); let dx = cx - (r.left + r.width / 2), dy = cy - (r.top + r.height / 2); const m = Math.hypot(dx, dy), max = r.width / 2 - 10; if (m > max) { dx *= max / m; dy *= max / m; } joy.x = dx / max; joy.y = dy / max; knob.style.transform = `translate(${dx}px, ${dy}px)`; };
  pad.addEventListener("pointerdown", (e) => { joy.id = e.pointerId; pad.setPointerCapture(e.pointerId); update(e.clientX, e.clientY); });
  pad.addEventListener("pointermove", (e) => { if (e.pointerId === joy.id) update(e.clientX, e.clientY); });
  const end = () => { joy.id = null; joy.x = joy.y = 0; knob.style.transform = ""; };
  pad.addEventListener("pointerup", end); pad.addEventListener("pointercancel", end);
}
{
  const pts = new Map(); let pinch = 0, downAt = 0, moved = 0;
  canvas.addEventListener("pointerdown", (e) => { pts.set(e.pointerId, { x: e.clientX, y: e.clientY }); downAt = performance.now(); moved = 0; canvas.setPointerCapture(e.pointerId); });
  canvas.addEventListener("pointermove", (e) => {
    const p = pts.get(e.pointerId); if (!p) return;
    if (pts.size === 2) { const [a, b] = [...pts.values()]; const d0 = Math.hypot(a.x - b.x, a.y - b.y); p.x = e.clientX; p.y = e.clientY; const [c, d] = [...pts.values()]; const d1 = Math.hypot(c.x - d.x, c.y - d.y); if (pinch) camDist = clamp(camDist * (d0 / d1), 12, 48); pinch = 1; return; }
    const dx = e.clientX - p.x, dy = e.clientY - p.y; moved += Math.abs(dx) + Math.abs(dy);
    camYaw -= dx * 0.006; camPitch = clamp(camPitch + dy * 0.004, 0.12, 1.15); p.x = e.clientX; p.y = e.clientY;
  });
  const up = (e) => { if (pts.size === 1 && moved < 8 && performance.now() - downAt < 300) tapWorld(e.clientX, e.clientY); pts.delete(e.pointerId); if (pts.size < 2) pinch = 0; };
  canvas.addEventListener("pointerup", up); canvas.addEventListener("pointercancel", up);
  canvas.addEventListener("wheel", (e) => { camDist = clamp(camDist + e.deltaY * 0.02, 12, 48); }, { passive: true });
}
const raycaster = new THREE.Raycaster();
function tapWorld(x, y) {
  if (inputLocked) return;
  raycaster.setFromCamera(new THREE.Vector2((x / innerWidth) * 2 - 1, -(y / innerHeight) * 2 + 1), camera);
  if (companionModel && raycaster.intersectObject(companionModel, true).length) return playWithCompanion();
  if (raycaster.intersectObject(nexoHeart, false).length) return openNexoMenu();
}

// =====================================================================
// Interacciones físicas (mismas anclas y radios que el servidor de Roblox)
// =====================================================================
const interactables = [
  ...CFG.Onboarding.StarterEggs.map((egg) => ({ id: egg.eggId, pos: eggs[egg.eggId].base, radius: W.EggInteractRadius, obj: "Huevo de copal", act: "Elegir este huevo", enabled: () => P.step === "ChooseEgg", run: () => confirmEgg(egg.eggId) })),
  { id: "nexo", pos: treeBase.clone().add(V(0, 0, W.GranNexo.trunkRadius)), radius: W.GranNexo.interactRadius, obj: "Gran Nexo", act: "Abrir el menú del árbol", enabled: () => P.step !== "ChooseEgg", run: () => openNexoMenu() },
  { id: "despensa", pos: v3(W.Stations.Despensa.position), radius: W.Stations.Despensa.radius, obj: "Despensa del Gabinete", act: "Comprar comida", enabled: () => !!starterPet(), run: () => openShop() },
  { id: "collector", pos: collectorPos, radius: 10, obj: "Recolector", act: "Recoger Monedas", enabled: () => P.lotUnlocked, run: () => collectCoins() },
  ...slotWorld.map((p, s) => ({ id: "slot" + s, pos: p, radius: 7, obj: `Hábitat · lugar ${s + 1}`, act: "Gestionar hábitat", enabled: () => P.lotUnlocked, run: () => openSanctuary() })),
  ...CFG.Encounters.Order.map((encId) => ({ id: encId, pos: encounterSpots[encId].pos, radius: W.Encounters[CFG.Encounters.ById[encId].worldMarker].radius, obj: CFG.Encounters.ById[encId].name, act: "Restaurar al Opaco", enabled: () => encounterAvailable(encId), run: () => startBattle(encId) })),
];
let currentPrompt = null;
function interact() { if (currentPrompt) currentPrompt.run(); }
$("#prompt").addEventListener("click", () => interact());
function updatePrompt() {
  let best = null, bd = Infinity;
  for (const it of interactables) { if (!it.enabled()) continue; const d = Math.hypot(player.position.x - it.pos.x, player.position.z - it.pos.z); if (d < it.radius && d < bd) { best = it; bd = d; } }
  const el = $("#prompt");
  if (best !== currentPrompt) {
    currentPrompt = best;
    if (best) { el.querySelector(".obj").textContent = best.obj; el.querySelector(".act").textContent = best.act; el.querySelector("kbd").textContent = isTouch ? "👆" : "E"; }
  }
  el.classList.toggle("hidden", !best || inputLocked);
}

// =====================================================================
// Acompañante y criaturas del santuario
// =====================================================================
let companionModel = null, companionKey = "";
const habitatModels = [null, null, null, null];
function syncCreatures() {
  const pet = companion();
  const key = pet ? `${pet.speciesId}|${pet.form}` : "";
  if (key !== companionKey) {
    if (companionModel) scene.remove(companionModel);
    companionModel = null; companionKey = key;
    if (pet && P.firsts.hatch_completed) { companionModel = buildCreature(pet.speciesId, pet.form); companionModel.position.copy(player.position).add(V(3, 0, 3)); scene.add(companionModel); }
  }
  P.habitat.slots.forEach((id, s) => {
    const want = id && P.pets[id] && id !== P.companion ? `${P.pets[id].speciesId}|${P.pets[id].form}` : "";
    const cur = habitatModels[s];
    if ((cur?.userData.key || "") !== want) {
      if (cur) scene.remove(cur);
      habitatModels[s] = null;
      if (want) { const pet2 = P.pets[id]; const m = buildCreature(pet2.speciesId, pet2.form); m.userData.key = want; m.position.copy(slotWorld[s]).setY(1.9); m.rotation.y = Math.PI; scene.add(m); habitatModels[s] = m; }
    }
  });
  for (const encId of CFG.Encounters.Order) {
    const spot = encounterSpots[encId];
    const spId = opponentSpecies(encId);
    const want = spId && encounterAvailable(encId) ? spId : "";
    if ((spot.creature?.userData.speciesId || "") !== want || (spot.creature && spot.creature.userData.restoredFor !== !!P.cleared[encId])) {
      if (spot.creature) scene.remove(spot.creature);
      spot.creature = null;
      if (want) { const enc = CFG.Encounters.ById[encId]; const m = buildCreature(spId, enc.opponent.form, true); m.userData.restoredFor = !!P.cleared[encId]; m.position.copy(spot.pos); m.rotation.y = Math.PI / 2; scene.add(m); spot.creature = m; }
    }
    spot.fog.forEach((f) => (f.visible = !P.cleared[encId] || !!spot.creature));
    const enc = CFG.Encounters.ById[encId];
    spot.label.el.innerHTML = want ? `${enc.name}<small>${P.cleared[encId] ? "Repetir (25 % de premio)" : "Opaco · nivel " + enc.opponent.level}</small>` : "";
  }
}
function opponentSpecies(encId) {
  const enc = CFG.Encounters.ById[encId];
  if (enc.opponent.speciesId) return enc.opponent.speciesId;
  const st = starterPet(); if (!st) return null;
  return enc.opponent.byStarterElement[species(st.speciesId).elements[0]];
}
function encounterAvailable(encId) {
  const enc = CFG.Encounters.ById[encId];
  if (!starterPet() || STEPS.indexOf(P.step) < STEPS.indexOf("FirstBattle") && !P.completed) return false;
  return !enc.requires || !!P.cleared[enc.requires];
}
function petFx(petId, kind) {
  if (petId !== P.companion || !companionModel) return;
  companionModel.userData.react = 0.9; companionModel.userData.reactSpin = kind === "level" ? 1 : 0;
  floater(companionModel.position.clone().add(V(0, 4, 0)), kind === "level" ? "⬆" : "❤", kind === "level" ? "crit" : "heal");
}
function playWithCompanion() {
  const pet = companion(); if (!pet) return;
  const r = Actions.play(pet.id);
  if (!r.ok) return toast("⏳", r.err);
  petFx(pet.id, "play"); toast("❤️", `${petName(pet)} juega contigo · Vínculo +${r.bond}`); refreshUI();
}

// =====================================================================
// Retratos (segundo renderizador pequeño para cartas y ficha)
// =====================================================================
const portraitR = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
portraitR.setSize(256, 256); portraitR.outputColorSpace = THREE.SRGBColorSpace; portraitR.toneMapping = THREE.ACESFilmicToneMapping;
const pScene = new THREE.Scene();
pScene.add(new THREE.HemisphereLight(0xfff1dc, 0x4c5a40, 1.6));
const pSun = new THREE.DirectionalLight(0xffe2b8, 2.2); pSun.position.set(3, 6, 5); pScene.add(pSun);
const pCam = new THREE.PerspectiveCamera(32, 1, 0.1, 100);
const portraitCache = new Map();
function portrait(speciesId, form, silhouette = false) {
  const key = `${speciesId}|${form}|${silhouette}`;
  if (portraitCache.has(key)) return portraitCache.get(key);
  const c = buildCreature(speciesId, form); c.rotation.y = -0.55; pScene.add(c);
  const box = new THREE.Box3().setFromObject(c), size = box.getSize(new THREE.Vector3()), center = box.getCenter(new THREE.Vector3());
  const d = Math.max(size.x, size.y, size.z) * 1.55;
  pCam.position.set(center.x + d * 0.25, center.y + d * 0.18, center.z + d); pCam.lookAt(center);
  portraitR.render(pScene, pCam);
  const url = portraitR.domElement.toDataURL("image/png");
  pScene.remove(c); portraitCache.set(key, url);
  return url;
}

// =====================================================================
// Interfaz
// =====================================================================
function toast(icon, text) {
  const el = document.createElement("div"); el.className = "toast panel"; el.innerHTML = `<span class="t-ico">${icon}</span><span>${text}</span>`;
  $("#toasts").appendChild(el); setTimeout(() => el.remove(), 3200);
}
let modalOpen = false;
function openModal(html, onMount, opts = {}) {
  const root = $("#modal-root");
  root.innerHTML = `<div class="modal panel greca" style="position:relative">${opts.noClose ? "" : '<button class="close-x" data-close>✕</button>'}${html}</div>`;
  root.classList.remove("hidden"); modalOpen = true; inputLocked = true;
  root.querySelectorAll("[data-close]").forEach((b) => b.addEventListener("click", closeModal));
  if (onMount) onMount(root.firstElementChild);
}
function closeModal() { $("#modal-root").classList.add("hidden"); $("#modal-root").innerHTML = ""; modalOpen = false; inputLocked = !!battle || introActive; refreshUI(); }
function elementBadges(els) { return els.map((e) => `<span class="el-badge" style="background:${css(CFG.Elements.ById[e].color)}">${ELEMENT_ICON[e]} ${e}</span>`).join(""); }
function hearts(pet) { const h = Leveling.bondHearts(pet.bond), max = CFG.Progression.Bond.Thresholds.length; return "❤".repeat(h) + '<span style="opacity:.3">' + "❤".repeat(max - h) + "</span>"; }
function refreshUI() {
  $("#coins").textContent = fmt(P.coins); $("#gems").textContent = fmt(P.gems);
  const info = stepInfo(P.step);
  const ob = $("#objective");
  ob.classList.toggle("hidden", introActive || !!battle);
  ob.querySelector(".title").textContent = P.completed ? "Explora el Valle Copal" : info.objective;
  ob.querySelector(".hint").textContent = P.completed ? nextGoalHint() : info.hint;
  const pet = companion();
  const card = $("#companion");
  card.classList.toggle("hidden", !pet || !P.firsts.hatch_completed || !!battle);
  if (pet) {
    const pct = pet.level >= 50 ? 100 : (pet.xp / Leveling.xpToNext(pet.level)) * 100;
    card.innerHTML = `<img src="${portrait(pet.speciesId, pet.form)}" alt=""><div style="min-width:120px"><div class="nm">${petName(pet)}</div><div class="lv">Nv ${pet.level} · ${pet.form}</div><div class="bar" style="margin:4px 0"><i style="width:${pct}%"></i></div><div class="hearts">${hearts(pet)}</div></div>`;
  }
  if (!cine) for (const e of Object.values(eggs)) e.group.visible = !starterPet();
  const pend = Object.keys(P.pending).length;
  $("#btn-pet").querySelector(".badge")?.remove();
  if (pet && Leveling.canEvolve(pet)[0]) $("#btn-pet").insertAdjacentHTML("beforeend", '<i class="badge">!</i>');
  if (pend) { $("#btn-nexo").querySelector(".badge")?.remove(); $("#btn-nexo").insertAdjacentHTML("beforeend", `<i class="badge">${pend}</i>`); } else $("#btn-nexo").querySelector(".badge")?.remove();
  syncCreatures();
}
function nextGoalHint() {
  const pet = companion(); if (!pet) return "";
  if (Leveling.canEvolve(pet)[0]) return "¡Tu monstruo está listo para tallarse! Abre su ficha.";
  const next = CFG.Encounters.Order.find((id) => encounterAvailable(id) && !P.cleared[id]);
  if (next) return `Restaura a «${CFG.Encounters.ById[next].name}» en la Linde de las Chinampas.`;
  return Leveling.nextObjective(pet).text + ". Alimenta, juega y recoge Monedas.";
}
function objectiveTarget() {
  const s = P.step;
  if (s === "ChooseEgg") return eggs.EggBarro.base;
  if (s === "MeetHome" || s === "PlaceInHabitat") return lotC;
  if (s === "FirstBattle") return encounterSpots.valle_r1_e1.pos;
  if (P.completed) { const next = CFG.Encounters.Order.find((id) => encounterAvailable(id) && !P.cleared[id]); return next ? encounterSpots[next].pos : null; }
  return null;
}
const beacon = addLabel(V(0, 0, 0), "⬇", { cls: "beacon", max: 600, visible: () => !!objectiveTarget() && !battle && !introActive });
function updateObjectiveArrow() {
  const t = objectiveTarget(); const arrow = $("#objective .arrow");
  if (!t) { arrow.style.display = "none"; return; }
  arrow.style.display = "";
  beacon.pos.copy(t).add(V(0, 12, 0));
  const local = t.clone().applyMatrix4(camera.matrixWorldInverse);
  const a = Math.atan2(local.x, -local.z); // 0 = al frente, positivo = a la derecha
  arrow.style.transform = `rotate(${a * (180 / Math.PI) - 90}deg)`;
}

// ---------- Ficha del monstruo ----------
function openPetSheet(petId = P.companion) {
  const pet = P.pets[petId]; if (!pet) return toast("🥚", "Primero elige tu huevo junto al Gran Nexo.");
  const sp = species(pet.speciesId), fb = Stats.formBase(pet.speciesId, pet.form), obj = Leveling.nextObjective(pet);
  const [canEvo, why] = Leveling.canEvolve(pet);
  const rar = CFG.Rarities.ById[sp.rarity];
  const tal = CFG.Talents.ById[sp.talent], sig = ability(sp.signature);
  const pct = pet.level >= 50 ? 100 : (pet.xp / Leveling.xpToNext(pet.level)) * 100;
  const foods = CFG.Economy.FoodOrder.filter((f) => CFG.Economy.Foods[f].sold || (P.items[f] || 0) > 0);
  openModal(`
    <div class="card monster" style="border-color:${css(rar.frameColor)}">
      <div class="gem" style="color:${css(rar.frameColor)}">◆ ${rar.name}</div><div class="els">${elementBadges(sp.elements)}</div>
      <img class="portrait" src="${portrait(pet.speciesId, pet.form)}" alt=""><div class="pedestal"></div>
      <div class="title">${petName(pet)}</div><div class="species">${pet.form === "Tallado" ? sp.talladoName : sp.broteName} · ${sp.role} · ${pet.form}</div>
    </div>
    <div class="kv" style="margin-top:12px"><span>Nivel <b>${pet.level}</b></span><span>XP <b>${fmt(pet.xp)} / ${fmt(Leveling.xpToNext(pet.level))}</b></span></div>
    <div class="bar"><i style="width:${pct}%"></i></div>
    <div class="kv"><span>Vínculo</span><span class="hearts" style="font-size:16px">${hearts(pet)}</span></div>
    <div class="objective-box">🎯 ${obj.text} <span style="float:right">${obj.current}/${obj.target}</span></div>
    ${canEvo ? '<button class="btn" id="evolve" style="width:100%;margin:6px 0 10px">✨ Tallar en ' + sp.talladoName + "</button>" : ""}
    <div class="food-grid">${foods.map((f) => `<button class="food" data-food="${f}" ${(P.items[f] || 0) < 1 ? "disabled" : ""}><span class="em">${FOOD_ICON[f]}</span>${CFG.Economy.Foods[f].name}<span class="n">×${P.items[f] || 0} · +${CFG.Economy.Foods[f].xp * xpMult()} XP</span></button>`).join("")}</div>
    <div class="row"><button class="btn jade" id="play">❤ Jugar</button><button class="btn secondary" id="rename">✎ Nombre</button></div>
    <div class="stats">${["VID", "ATQ", "DEF", "ESE", "VEL"].map((k) => `<span>${k}</span><div class="bar"><i style="width:${(fb[k] / 40) * 100}%"></i></div><span>${fb[k]}</span>`).join("")}</div>
    <div class="kv"><span>Talento</span><b>${tal.name}</b></div><div class="sub" style="text-align:left;margin:0 0 6px">${tal.text}</div>
    <div class="kv"><span>Firma</span><b>${sig.name}</b></div><div class="sub" style="text-align:left;margin:0 0 6px">${sig.text}</div>
    <div class="kv"><span>Mezcla mítica</span></div><div class="sub" style="text-align:left">${sp.mythicMix}</div>
    <div class="sub" style="font-size:12px">Modelo provisional (blockout). El diseño final pasa por el pipeline de arte y aprobación humana.</div>`,
    (m) => {
      m.querySelectorAll("[data-food]").forEach((b) => b.addEventListener("click", () => {
        const r = Actions.feed(pet.id, b.dataset.food);
        if (!r.ok) return toast("⚠️", r.err);
        petFx(pet.id, "play"); toast(FOOD_ICON[b.dataset.food], `+${r.xp} XP${r.bond ? " · Vínculo +" + r.bond : ""}`);
        refreshUI(); openPetSheet(pet.id);
      }));
      m.querySelector("#play").addEventListener("click", () => { closeModal(); playWithCompanion(); });
      m.querySelector("#rename").addEventListener("click", () => renamePet(pet.id));
      m.querySelector("#evolve")?.addEventListener("click", () => { closeModal(); evolveSequence(pet.id); });
    });
  void why;
}
function renamePet(petId) {
  const pet = P.pets[petId];
  openModal(`<h2>Ponle nombre</h2><div class="sub">En Roblox, el nombre pasa por el filtro de texto del servidor antes de guardarse.</div>
    <input class="input" id="nick" maxlength="${CFG.Onboarding.MaxNicknameLength}" value="${pet.nickname || ""}" placeholder="${species(pet.speciesId).broteName}">
    <div class="row" style="margin-top:12px"><button class="btn secondary" data-close>Cancelar</button><button class="btn" id="ok">Guardar</button></div>`,
    (m) => { const i = m.querySelector("#nick"); setTimeout(() => i.focus(), 50); m.querySelector("#ok").addEventListener("click", () => { pet.nickname = i.value.trim().slice(0, CFG.Onboarding.MaxNicknameLength) || null; save(); closeModal(); }); });
}

// ---------- Santuario ----------
function openSanctuary() {
  if (!P.lotUnlocked) return toast("🏡", "Visita tu Lote Hogar al sur del río para abrirlo.");
  const pets = Object.values(P.pets), coins = pendingCoins();
  openModal(`<h2>Lote Hogar</h2><div class="sub">Hábitat de 4 lugares · ${habitatRate().toFixed(1)} Monedas/h · los monstruos del Vivero no producen</div>
    <div class="slots">${P.habitat.slots.map((id, s) => id && P.pets[id] ? `<div class="slot filled"><img src="${portrait(P.pets[id].speciesId, P.pets[id].form)}" alt=""><div>${petName(P.pets[id])}${id === P.companion ? " · paseando" : ""}</div><button class="btn small secondary" data-remove="${s}">Retirar</button></div>` : `<div class="slot"><div style="font-size:26px">＋</div>Lugar ${s + 1}${pets.filter((p) => !P.habitat.slots.includes(p.id)).map((p) => `<button class="btn small jade" data-place="${s}" data-pet="${p.id}">Colocar ${petName(p)}</button>`).join("")}</div>`).join("")}</div>
    <button class="btn" id="collect" style="width:100%" ${coins < 1 ? "disabled" : ""}>Recoger ${fmt(coins)} Monedas</button>
    <div class="sub" style="margin-top:10px;font-size:13px">Vivero ${pets.filter((p) => !P.habitat.slots.includes(p.id)).length}/${CFG.Sanctuary.InventoryCapacity} · Vitrina e incubadora llegan en la Fase 2.</div>`,
    (m) => {
      m.querySelectorAll("[data-place]").forEach((b) => b.addEventListener("click", () => { const r = Actions.place(b.dataset.pet, +b.dataset.place); if (!r.ok) toast("⚠️", r.err); refreshUI(); openSanctuary(); }));
      m.querySelectorAll("[data-remove]").forEach((b) => b.addEventListener("click", () => { Actions.remove(+b.dataset.remove); refreshUI(); openSanctuary(); }));
      m.querySelector("#collect").addEventListener("click", () => { closeModal(); collectCoins(); });
    });
}
function collectCoins() {
  const c = Actions.collect();
  if (c > 0) { toast("🪙", `+${fmt(c)} Monedas`); floater(collectorPos.clone().add(V(0, 6, 0)), `+${fmt(c)}`, "crit"); }
  else toast("🪙", "El recolector aún está vacío. Coloca monstruos en el hábitat.");
  refreshUI();
}
// ---------- Despensa ----------
function openShop() {
  const foods = CFG.Economy.FoodOrder.filter((f) => CFG.Economy.Foods[f].sold);
  openModal(`<h2>Despensa del Gabinete</h2><div class="sub">«Lo que ves es lo que te llevas.» Precios fijos en Monedas ganadas jugando. Sin compras reales en esta fase.</div>
    <div class="travel-list">${foods.map((f) => { const food = CFG.Economy.Foods[f]; return `<button class="travel" data-buy="${f}" ${P.coins < food.price.Monedas ? 'style="opacity:.55"' : ""}><span class="em">${FOOD_ICON[f]}</span><span style="flex:1">${food.name}<small>+${food.xp} XP${food.bond ? " · +" + food.bond + " Vínculo" : ""} · tienes ${P.items[f] || 0}</small></span><span>🪙 ${fmt(food.price.Monedas)}</span></button>`; }).join("")}</div>`,
    (m) => m.querySelectorAll("[data-buy]").forEach((b) => b.addEventListener("click", () => { const r = Actions.buyFood(b.dataset.buy, 1); toast(r.ok ? FOOD_ICON[b.dataset.buy] : "⚠️", r.ok ? "Comprado" : r.err); refreshUI(); openShop(); })));
}
// ---------- Menú del árbol ----------
function openNexoMenu() {
  const pend = Object.values(P.pending);
  const dests = [
    { id: "Plaza", em: "🌳", name: "Plaza del Gran Nexo", sub: "Corazón del valle", pos: v3(W.TravelPoints.Plaza) },
    { id: "LoteHogar", em: "🏡", name: "Lote Hogar", sub: P.lotUnlocked ? "Hábitat y recolector" : "Se abre al visitarlo", pos: lotC.clone().add(V(0, 0, 20)), locked: !starterPet() },
    { id: "Linde", em: "🌫️", name: "Linde de las Chinampas", sub: "Opacos por restaurar", pos: v3(W.TravelPoints.Linde), locked: !starterPet() },
    { id: "Despensa", em: "🧺", name: "Despensa del Gabinete", sub: "Comida a precio fijo", pos: v3(W.TravelPoints.Despensa), locked: !starterPet() },
  ];
  openModal(`<h2>Gran Nexo</h2><div class="sub">El árbol lleva a cada estación; las estaciones se usan en persona.</div>
    ${pend.length ? `<button class="btn" id="rewards" style="width:100%;margin-bottom:10px">🎁 Reclamar ${pend.length} recompensa(s)</button>` : ""}
    <div class="travel-list">${dests.map((d) => `<button class="travel ${d.locked ? "locked" : ""}" data-go="${d.id}"><span class="em">${d.em}</span><span>${d.name}<small>${d.sub}</small></span></button>`).join("")}
    ${["Criadero", "Portal de Arenas", "Tablón de Encargos", "Círculo de Encuentro"].map((n) => `<button class="travel locked"><span class="em">🔒</span><span>${n}<small>Fase 2</small></span></button>`).join("")}</div>
    <div class="row" style="margin-top:12px"><button class="btn secondary small" id="dev">${DEV.xp ? "Modo prueba: XP ×10 ✔" : "Modo prueba: apagado"}</button><button class="btn secondary small" id="reset">Reiniciar partida</button></div>
    <div class="sub" style="font-size:12px;margin-top:8px">El modo prueba solo acelera la XP en esta vista previa; el balance de producción no cambia.</div>`,
    (m) => {
      m.querySelector("#rewards")?.addEventListener("click", () => { closeModal(); showReward(pend[0].id); });
      m.querySelectorAll("[data-go]").forEach((b) => b.addEventListener("click", () => { const d = dests.find((x) => x.id === b.dataset.go); if (d.locked) return toast("🔒", "Elige primero tu huevo."); closeModal(); player.position.set(d.pos.x, 0, d.pos.z); if (companionModel) companionModel.position.copy(player.position).add(V(3, 0, 3)); }));
      m.querySelector("#dev").addEventListener("click", () => { DEV.xp = !DEV.xp; saveDev(); openNexoMenu(); });
      m.querySelector("#reset").addEventListener("click", () => { if (confirm("¿Borrar la partida de esta vista previa?")) { localStorage.removeItem(SAVE_KEY); location.reload(); } });
    });
}
function openAlbum() {
  const owned = new Set(Object.values(P.pets).map((p) => p.speciesId));
  openModal(`<h2>Álbum del Nexo</h2><div class="sub">50 especies · las que faltan se ven como silueta con su número. ${owned.size}/50</div>
    <div class="inv-grid">${CFG.Species.Order.map((id) => { const sp = species(id), has = owned.has(id), canShow = !!CFG.Visuals.ById[id]; return `<div class="inv-item ${has ? "" : "silhouette"}" style="${has ? "border-color:" + css(CFG.Rarities.ById[sp.rarity].frameColor) : ""}">${canShow ? `<img src="${portrait(id, "Brote")}" alt="">` : `<div style="height:76px;display:grid;place-items:center;font-size:30px;opacity:.35">?</div>`}<div>#${sp.number} ${has ? sp.broteName : "???"}</div></div>`; }).join("")}</div>`);
}
$("#btn-pet").addEventListener("click", () => openPetSheet());
$("#btn-sanctuary").addEventListener("click", () => openSanctuary());
$("#btn-album").addEventListener("click", () => openAlbum());
$("#btn-nexo").addEventListener("click", () => openNexoMenu());
$("#companion").addEventListener("click", () => openPetSheet());

// ---------- Recompensas ----------
function showReward(rewardId) {
  const r = P.pending[rewardId]; if (!r) return;
  const items = [];
  if (r.currencies.Monedas) items.push(["🪙", `${fmt(r.currencies.Monedas)} Monedas`]);
  if (r.currencies.Gemas) items.push(["💎", `${fmt(r.currencies.Gemas)} Gemas`]);
  for (const [k, n] of Object.entries(r.items)) items.push([FOOD_ICON[k], `${n} × ${CFG.Economy.Foods[k].name}`]);
  if (r.petXp) items.push(["⭐", `${fmt(r.petXp * xpMult())} XP para tu equipo`]);
  for (const u of r.unlocks) if (u.startsWith("Encounter_")) items.push(["🗺️", `Nuevo Opaco: ${CFG.Encounters.ById[u.replace("Encounter_", "")].name}`]);
  openModal(`<h2>${r.title}</h2><div class="sub">Recompensa determinista · procedencia registrada</div>
    <div class="reward-list">${items.map(([e, t], i) => `<div class="reward-item" style="animation-delay:${i * 0.12}s"><span class="em">${e}</span>${t}</div>`).join("")}</div>
    <button class="btn" id="claim" style="width:100%">Reclamar</button>`,
    (m) => m.querySelector("#claim").addEventListener("click", () => { Actions.claim(rewardId); closeModal(); toast("🎁", "Recompensa reclamada"); refreshUI(); }), { noClose: true });
}

// =====================================================================
// Introducción (el sueño del Tallador) y elección del huevo
// =====================================================================
let introActive = false;
const INTRO = [
  ["🪵", "Una gubia talla una espiral de copal… y la espiral se enciende."],
  ["✨", "Las virutas se vuelven luz y dibujan Brotes que corren por el aire."],
  ["🌳", "El Gran Nexo despierta y los cinco biomas aparecen como un mapa vivo."],
  ["🌫️", "Pero una niebla gris apaga los colores: el Opacamiento."],
  ["🥚", "Un huevo de luz cae en el santuario… y se divide en tres."],
];
function showIntro() {
  introActive = true; inputLocked = true;
  const el = $("#intro"); el.classList.remove("hidden");
  let i = -1;
  const draw = () => {
    if (i < 0) { el.innerHTML = `<button class="btn secondary small skip" id="skip">Saltar</button><div><div class="logo">NEXORA</div><div class="tag">Tierno al nacer. Imponente al tallarse.</div><button class="btn" id="go" style="margin-top:34px;min-width:220px">Comenzar</button></div><div class="note">Vista previa web del vertical slice · modelos provisionales (blockout) · el juego final se construye en Roblox</div>`; }
    else el.innerHTML = `<button class="btn secondary small skip" id="skip">Saltar</button><div><div class="glyph">${INTRO[i][0]}</div><div class="scene-text">${INTRO[i][1]}</div><div class="dots">${INTRO.map((_, k) => `<i class="${k === i ? "on" : ""}"></i>`).join("")}</div><button class="btn" id="go" style="margin-top:28px;min-width:180px">${i === INTRO.length - 1 ? "Despertar" : "Continuar"}</button></div>`;
    el.querySelector("#skip").onclick = () => endIntro(true);
    el.querySelector("#go").onclick = () => { i++; if (i >= INTRO.length) endIntro(false); else draw(); };
  };
  draw();
}
function endIntro(skipped) {
  $("#intro").classList.add("hidden"); introActive = false; inputLocked = false;
  Actions.finishIntro(skipped);
  showWorldUI(); refreshUI();
  toast("🥚", "Tres huevos de copal laten junto al Gran Nexo.");
}
function showWorldUI() { ["#hud", "#dock", "#help"].forEach((s) => $(s).classList.remove("hidden")); if (isTouch) $("#joystick").classList.remove("hidden"); }
function confirmEgg(eggId) {
  openModal(`<h2>¿Este huevo?</h2><div class="sub">Los tres huevos parecen iguales. Este late con un color… confía en tu intuición.</div>
    <div style="display:grid;place-items:center;margin:8px 0 16px"><div style="width:96px;height:124px;border-radius:50%/60% 60% 40% 40%;background:radial-gradient(circle at 40% 30%, #ffe1a6, #e8a848 60%, #9b6324);box-shadow:0 0 40px ${css(CFG.Onboarding.StarterEggs.find((e) => e.eggId === eggId).pulseColor)}"></div></div>
    <div class="row"><button class="btn secondary" data-close>Seguir mirando</button><button class="btn" id="yes">Elegir</button></div>`,
    (m) => m.querySelector("#yes").addEventListener("click", () => { closeModal(); hatchSequence(eggId); }));
}
async function hatchSequence(eggId) {
  const r = Actions.chooseStarter(eggId); if (!r.ok) return;
  inputLocked = true; cine = true;
  const e = eggs[eggId], pet = P.pets[r.petId];
  cineCam = { pos: e.base.clone().add(V(0, 6, 13)), look: e.base.clone().add(V(0, 3.5, 0)) };
  const t0 = performance.now();
  await new Promise((res) => { const step = () => { const t = (performance.now() - t0) / 1000; e.group.position.y = 4.3 + Math.min(t, 1.2) * 2.2; e.group.rotation.z = Math.sin(t * 22) * 0.12 * Math.min(1, t); e.glow.intensity = 40 + t * 60; e.shell.material.emissive.setRGB(t * 0.4, t * 0.25, t * 0.05); if (t < 2.6) requestAnimationFrame(step); else res(); }; step(); });
  e.group.visible = false;
  for (let k = 0; k < 14; k++) floater(e.base.clone().add(V((Math.random() - 0.5) * 6, 6 + Math.random() * 3, (Math.random() - 0.5) * 3)), "✦", "crit");
  Actions.ackHatch();
  refreshUI();
  if (companionModel) { companionModel.position.copy(e.base).setY(0); companionModel.rotation.y = 0; companionModel.userData.react = 0.9; companionModel.userData.reactSpin = 1; }
  await sleep(900);
  cine = false;
  const sp = species(pet.speciesId);
  openModal(`<div class="card monster"><div class="gem">◆ Común</div><div class="els">${elementBadges(sp.elements)}</div><img class="portrait" src="${portrait(pet.speciesId, "Brote")}" alt=""><div class="pedestal"></div><div class="title">¡${sp.broteName}!</div><div class="species">${sp.concept}</div></div>
    <div class="sub" style="margin-top:12px">${CFG.Onboarding.OtherStartersMessage}</div>
    <input class="input" id="nick" maxlength="${CFG.Onboarding.MaxNicknameLength}" placeholder="Ponle nombre (opcional)">
    <button class="btn" id="ok" style="width:100%;margin-top:12px">¡Vamos!</button>`,
    (m) => m.querySelector("#ok").addEventListener("click", () => { const n = m.querySelector("#nick").value.trim(); if (n) pet.nickname = n.slice(0, CFG.Onboarding.MaxNicknameLength); save(); closeModal(); toast("🏡", "Sigue la luz de copal hasta tu Lote Hogar."); }), { noClose: true });
}
async function evolveSequence(petId) {
  const pet = P.pets[petId]; if (!companionModel) return;
  inputLocked = true; cine = true;
  const m = companionModel, base = m.position.clone();
  cineCam = { pos: base.clone().add(V(0, 7, 15)), look: base.clone().add(V(0, 2.5, 0)) };
  const t0 = performance.now();
  await new Promise((res) => { const step = () => { const t = (performance.now() - t0) / 1000; m.rotation.y += 0.05 + t * 0.12; m.position.y = Math.sin(Math.min(t, 2) * Math.PI / 2) * 3; m.userData.mats.forEach((mm) => mm.emissive.setRGB(t * 0.5, t * 0.35, t * 0.1)); if (t < 2.4) requestAnimationFrame(step); else res(); }; step(); });
  const r = Actions.evolve(petId);
  if (r.ok) { for (let k = 0; k < 18; k++) floater(base.clone().add(V((Math.random() - 0.5) * 8, 3 + Math.random() * 6, (Math.random() - 0.5) * 4)), "✦", "crit"); }
  refreshUI();
  if (companionModel) { companionModel.position.copy(base); companionModel.userData.react = 0.9; companionModel.userData.reactSpin = 1; }
  await sleep(1300);
  cine = false; inputLocked = false;
  const sp = species(pet.speciesId);
  openModal(`<div class="card monster"><div class="gem">◆ Tallado</div><div class="els">${elementBadges(sp.elements)}</div><img class="portrait" src="${portrait(pet.speciesId, "Tallado")}" alt=""><div class="pedestal"></div><div class="title">${sp.talladoName}</div><div class="species">${sp.talladoDescription}</div></div>
    <div class="sub" style="margin-top:12px">Mismo monstruo, nueva presencia: conserva su cara, su color base y su rasgo firma. A nivel 20 desbloquea el Golpe Nexo.</div>
    <button class="btn" data-close style="width:100%">Imponente</button>`, null, { noClose: true });
}

// =====================================================================
// Combate PvE (mismo motor que el servidor; aquí el "servidor" es local)
// =====================================================================
let battle = null;
const battleRng = new ENG.Rng(Date.now() % 2147483646);
function startBattle(encId) {
  const pet = companion(); if (!pet || battle || !companionModel) return;
  const enc = CFG.Encounters.ById[encId], spot = encounterSpots[encId];
  const seed = 1 + Math.floor(battleRng.next() * 2147483640);
  const state = BE.new({ battleId: `web-${Date.now()}`, seed, sides: [
    { controller: "Player", team: [{ speciesId: pet.speciesId, form: pet.form, level: pet.level, petId: pet.id, nickname: pet.nickname }] },
    { controller: "AI", ai: enc.ai, team: [{ speciesId: opponentSpecies(encId), form: enc.opponent.form, level: enc.opponent.level, isOpaco: true, modifier: enc.opponent.modifier }] },
  ] });
  first("first_battle_started"); save();
  const center = spot.pos.clone();
  const foeModel = spot.creature || buildCreature(opponentSpecies(encId), enc.opponent.form, true);
  if (!spot.creature) scene.add(foeModel);
  battle = { state, encId, foe: foeModel, me: companionModel, center, busy: false, home: { me: center.clone().add(V(-4.5, 0, 2.5)), foe: center.clone().add(V(4.5, 0, -2)) } };
  player.position.copy(center.clone().add(V(-9, 0, 6)));
  heading = Math.atan2(battle.home.foe.x - player.position.x, battle.home.foe.z - player.position.z);
  battle.me.position.copy(battle.home.me); battle.foe.position.copy(battle.home.foe);
  battle.me.lookAt(battle.home.foe.x, 0, battle.home.foe.z); battle.foe.lookAt(battle.home.me.x, 0, battle.home.me.z);
  cineCam = { pos: center.clone().add(V(-1, isTouch ? 9 : 6.5, isTouch ? 17 : 13)), look: center.clone().add(V(0, 1.6, 0)) };
  inputLocked = true; cine = true;
  ["#companion", "#objective", "#dock", "#joystick", "#help"].forEach((s) => $(s).classList.add("hidden"));
  $("#battle").classList.remove("hidden");
  renderBattle(`¡Un ${state.sides[1].team[0].name} aparece entre la niebla!`);
}
const cardHtml = (c, mine) => {
  const pct = (c.hp / c.maxHp) * 100, cls = pct < 25 ? "low" : pct < 55 ? "mid" : "";
  const st = Object.keys(c.statuses).filter((k) => c.statuses[k] > 0).map((k) => `<span>${STATUS_TXT[k] || k}</span>`).join("") + c.mods.map((m) => `<span>${STAT_TXT[m.stat] || m.stat} ${m.amount > 0 ? "▲" : "▼"}</span>`).join("") + (c.shield ? `<span>🛡 ${c.shield.amount}</span>` : "");
  return `<div class="nm"><span>${c.name}</span><span style="font-size:13px;color:var(--muted)">Nv ${c.level}</span></div>${elementBadges(c.elements)}
    <div class="bar hp ${cls}"><i style="width:${pct}%"></i></div><div class="hpnum"><span>${Math.max(0, c.hp)} / ${c.maxHp} PV</span>${mine ? `<span class="savia">Savia ${[0, 1, 2].map((k) => `<i class="${k < c.savia ? "on" : ""}"></i>`).join("")}</span>` : ""}</div><div class="status-row">${st}</div>`;
};
function renderBattle(caption) {
  const s = battle.state, me = BE.active(s, 1), foe = BE.active(s, 2);
  const opts = s.phase === "Ended" ? [] : BE.availableMoves(s, 1);
  $("#battle").innerHTML = `
    <div class="foe panel">${cardHtml(foe, false)}</div>
    <div class="me panel">${cardHtml(me, true)}</div>
    <button class="btn secondary small flee" id="flee">Huir</button>
    ${caption ? `<div class="caption panel">${caption}</div>` : ""}
    <div class="moves">${opts.map((o) => { const mv = ability(o.moveId), ec = CFG.Elements.ById[mv.element].color; const eff = mv.power > 0 ? ElementChart.classify(ElementChart.multiplier(mv.element, foe.elements, mv.kind === "Nexo")) : "Neutral"; const kind = { Basic: "Básico · +1 Savia", Special: "Especial", Signature: "Firma", Nexo: "Golpe Nexo" }[mv.kind];
      return `<button class="move" data-move="${o.moveId}" ${o.usable && !battle.busy ? "" : "disabled"} style="background:linear-gradient(180deg, ${css(ec.map((x) => Math.min(255, x + 40)))}, ${css(ec)})" title="${mv.text}">
      <div class="mn">${ELEMENT_ICON[mv.element]} ${mv.name}</div><div class="mm">${kind}${mv.power ? " · " + mv.power : ""}</div>${eff === "Strong" ? '<span class="eff">▲ Eficaz</span>' : eff === "Weak" ? '<span class="eff">▼ Poco</span>' : ""}
      <span class="cost">${"<i></i>".repeat(o.cost)}</span></button>`; }).join("")}</div>`;
  $("#battle").querySelectorAll("[data-move]").forEach((b) => b.addEventListener("click", () => playTurn(b.dataset.move)));
  $("#flee").addEventListener("click", () => playTurn(null));
}
function nameOf(uid) { const s = battle.state; return [...s.sides[0].team, ...s.sides[1].team].find((c) => c.uid === uid)?.name || ""; }
function modelOf(uid) { return uid.startsWith("S1") ? battle.me : battle.foe; }
async function lunge(model, toward) {
  const from = model.position.clone(), dir = toward.clone().sub(from).setY(0).normalize();
  for (let k = 0; k <= 10; k++) { model.position.copy(from).addScaledVector(dir, Math.sin((k / 10) * Math.PI) * 3.2); await sleep(16); }
  model.position.copy(from);
}
async function hitShake(model) { const from = model.position.clone(); for (let k = 0; k < 8; k++) { model.position.x = from.x + (k % 2 ? 0.35 : -0.35); await sleep(22); } model.position.copy(from); }
async function playTurn(moveId) {
  if (!battle || battle.busy) return;
  const s = battle.state;
  battle.busy = true;
  BE.submit(s, 1, moveId ? { kind: "Move", moveId } : { kind: "Forfeit" });
  BE.submit(s, 2, { kind: "Move", moveId: AI.choose(s, 2, s.sides[1].ai) });
  const events = BE.resolveTurn(s);
  renderBattle();
  for (const e of events) {
    let cap = null;
    if (e.t === "Move") { const mv = ability(e.move); cap = `${nameOf(e.actor)} usa <b>${mv.name}</b>`; renderBattle(cap); if (mv.power > 0) await lunge(modelOf(e.actor), modelOf(e.actor === "S1C1" ? "S2C1" : "S1C1").position); else await sleep(450); continue; }
    if (e.t === "Damage") { const m = modelOf(e.target); floater(m.position.clone().add(V(0, 4, 0)), `-${e.amount}`, e.crit ? "crit" : e.eff === "Strong" ? "strong" : e.eff === "Weak" ? "weak" : ""); hitShake(m); cap = e.crit ? "¡Golpe crítico!" : e.eff === "Strong" ? "¡Es muy eficaz!" : e.eff === "Weak" ? "No es muy eficaz…" : null; }
    else if (e.t === "Heal") { floater(modelOf(e.target).position.clone().add(V(0, 4, 0)), `+${e.amount}`, "heal"); cap = `${nameOf(e.target)} recupera vida`; }
    else if (e.t === "Status") cap = `${nameOf(e.target)}: ${STATUS_TXT[e.status] || e.status}`;
    else if (e.t === "StatusTick") { floater(modelOf(e.target).position.clone().add(V(0, 4, 0)), `-${e.amount}`, ""); cap = `${nameOf(e.target)} sufre quemadura`; }
    else if (e.t === "Mod") cap = `${STAT_TXT[e.stat] || e.stat} de ${nameOf(e.target)} ${e.amount > 0 ? "sube" : "baja"}`;
    else if (e.t === "Miss") cap = `${nameOf(e.actor)} falla`;
    else if (e.t === "Skip") cap = `${nameOf(e.actor)} no puede actuar (${STATUS_TXT[e.status]})`;
    else if (e.t === "Block") cap = `¡${nameOf(e.target)} bloquea el golpe!`;
    else if (e.t === "Shield") cap = `${nameOf(e.target)} levanta un escudo`;
    else if (e.t === "Savia" && e.delta < 0) cap = `${nameOf(e.target)} pierde Savia`;
    else if (e.t === "Faint") { cap = e.target.startsWith("S2") ? "¡La niebla gris se debilita!" : `${nameOf(e.target)} está cansado`; const m = modelOf(e.target); m.rotation.z = 0.4; }
    else if (e.t === "Restored") { cap = "✨ ¡El monstruo recupera su color!"; const m = battle.foe; m.rotation.z = 0; const t0 = performance.now(); await new Promise((res) => { const step = () => { const t = (performance.now() - t0) / 1200; setOpaco(m, 1 - Math.min(1, t)); m.position.y = Math.sin(Math.min(1, t) * Math.PI) * 2; if (t < 1) requestAnimationFrame(step); else res(); }; step(); }); }
    if (cap) { renderBattle(cap); await sleep(650); }
  }
  battle.busy = false;
  if (s.phase === "Ended") return endBattle();
  renderBattle();
}
async function endBattle() {
  const { state: s, encId } = battle;
  const won = s.outcome.winner === 1;
  const enc = CFG.Encounters.ById[encId], pet = companion();
  renderBattle(won ? "¡Victoria! Nadie muere en NEXORA: el Opaco fue restaurado." : s.outcome.reason === "Forfeit" ? "Te retiras para entrenar." : `${petName(pet)} necesita descansar. ¡Inténtalo de nuevo!`);
  await sleep(1500);
  let rewardId = null;
  if (won) {
    pet.wins = (pet.wins || 0) + 1;
    const firstClear = !P.cleared[encId];
    const day = Math.floor(now() / 86400);
    if (P.repeat.day !== day) P.repeat = { day, count: 0 };
    let spec = null;
    if (firstClear) spec = { bundleId: enc.firstClearBonus, currencies: { Monedas: enc.baseReward.Monedas }, petXp: enc.baseReward.petXp, petIds: [pet.id] };
    else if (P.repeat.count < CFG.Encounters.Repeat.DailyRewardedRepeats) { spec = { currencies: { Monedas: Math.floor(enc.baseReward.Monedas * 0.25) }, petXp: Math.floor(enc.baseReward.petXp * 0.25), petIds: [pet.id] }; P.repeat.count++; }
    if (firstClear) P.cleared[encId] = { at: now(), wins: 1 }; else P.cleared[encId].wins++;
    if (spec) { rewardId = `battle:${s.battleId}`; P.pending[rewardId] = makeReward(rewardId, spec, firstClear ? null : "Opaco restaurado de nuevo"); }
    first("first_battle_completed");
  } else if (s.outcome.reason !== "Forfeit") addXp(pet, enc.lossPetXp);
  refreshOnboarding(); save();
  $("#battle").classList.add("hidden"); $("#battle").innerHTML = "";
  if (battle.me) battle.me.rotation.z = 0;
  battle.foe.rotation.z = 0;
  setOpaco(battle.foe, 1);
  battle = null; cine = false; inputLocked = false;
  showWorldUI(); refreshUI();
  if (rewardId) showReward(rewardId);
}

// =====================================================================
// Bucle principal
// =====================================================================
let cine = false, cineCam = null;
const clock = new THREE.Clock();
const camTarget = new THREE.Vector3(), camPos = new THREE.Vector3();
let homeVisitCheck = 0;
function tick() {
  const dt = Math.min(clock.getDelta(), 0.05), t = clock.elapsedTime;
  // Movimiento
  let mx = 0, mz = 0;
  if (!inputLocked && !modalOpen) {
    if (keys.has("w") || keys.has("arrowup")) mz -= 1;
    if (keys.has("s") || keys.has("arrowdown")) mz += 1;
    if (keys.has("a") || keys.has("arrowleft")) mx -= 1;
    if (keys.has("d") || keys.has("arrowright")) mx += 1;
    mx += joy.x; mz += joy.y;
  }
  const mag = Math.min(1, Math.hypot(mx, mz));
  const moving = mag > 0.08;
  if (moving) {
    const ang = Math.atan2(mx, mz) + camYaw;
    const speed = 18 * mag;
    player.position.x += Math.sin(ang) * speed * dt; player.position.z += Math.cos(ang) * speed * dt;
    const d = Math.hypot(player.position.x - treeBase.x, player.position.z - treeBase.z);
    if (d < W.GranNexo.trunkRadius + 4) { const k = (W.GranNexo.trunkRadius + 4) / d; player.position.x = treeBase.x + (player.position.x - treeBase.x) * k; player.position.z = treeBase.z + (player.position.z - treeBase.z) * k; }
    const r = Math.hypot(player.position.x, player.position.z); if (r > 250) { player.position.x *= 250 / r; player.position.z *= 250 / r; }
    heading = lerpAngle(heading, ang, Math.min(1, dt * 12));
  }
  avatar.rotation.y = heading;
  const sw = moving ? Math.sin(t * 11) * 0.8 * mag : 0;
  avParts.armL.rotation.x = sw; avParts.armR.rotation.x = -sw; avParts.legL.rotation.x = -sw; avParts.legR.rotation.x = sw;
  avatar.position.y = moving ? Math.abs(Math.sin(t * 11)) * 0.25 : 0;

  // Acompañante: sigue con suavidad, mantiene distancia, nunca se teletransporta salvo si se pierde
  if (companionModel && !battle && !cine) {
    const side = V(Math.sin(heading + 2.4), 0, Math.cos(heading + 2.4)).multiplyScalar(5);
    const target = player.position.clone().add(side);
    const to = target.sub(companionModel.position).setY(0), dist = to.length();
    if (dist > 60) companionModel.position.copy(player.position).add(side);
    const cMoving = dist > 1.2;
    if (cMoving) { companionModel.position.addScaledVector(to.normalize(), Math.min(dist, (6 + dist * 1.6) * dt)); companionModel.rotation.y = lerpAngle(companionModel.rotation.y, Math.atan2(to.x, to.z), Math.min(1, dt * 8)); }
    animateCreature(companionModel, t, dt, cMoving);
  } else if (companionModel) animateCreature(companionModel, t, dt, false);
  habitatModels.forEach((m) => m && animateCreature(m, t, dt, false));
  for (const encId of CFG.Encounters.Order) { const c = encounterSpots[encId].creature; if (c) animateCreature(c, t, dt, false); encounterSpots[encId].fog.forEach((f, k) => { f.position.y = 1.5 + Math.sin(t + k) * 0.4; f.material.opacity = 0.12 + Math.sin(t * 0.7 + k) * 0.05; }); }

  // Huevos: laten con su color al acercarse (elección por intuición)
  for (const e of Object.values(eggs)) {
    if (!e.group.visible) continue;
    const d = Math.hypot(player.position.x - e.base.x, player.position.z - e.base.z);
    const near = P.step === "ChooseEgg" && d < W.EggInteractRadius + 4;
    e.glow.intensity = lerp(e.glow.intensity, near ? 30 + Math.sin(t * 5) * 18 : 0, 0.1);
    e.group.position.y = 4.3 + Math.sin(t * 2 + e.base.x) * 0.15;
    e.group.rotation.y += dt * 0.3;
  }
  nexoHeart.scale.setScalar(1 + Math.sin(t * 2.4) * 0.06);
  nexoHeart.scale.x *= 2.6; nexoHeart.scale.y *= 3.3; nexoHeart.scale.z *= 1.6;
  for (const o of spinners) o.rotation.z += dt * 0.8;
  water.material.emissiveIntensity = 0.35 + Math.sin(t * 1.3) * 0.08;

  // Llegada al Lote Hogar (el servidor de Roblox valida la misma proximidad)
  if ((homeVisitCheck += dt) > 0.3) {
    homeVisitCheck = 0;
    if (P.step === "MeetHome" && Math.hypot(player.position.x - lotC.x, player.position.z - lotC.z) < W.Lots.interactRadius) {
      if (Actions.visitHome()) { toast("🎁", "El Gabinete te regala el Lote Hogar: 3 Raciones y 100 Monedas"); refreshUI(); setTimeout(openSanctuary, 600); }
    }
    if (collectorCoinsLabel) collectorCoinsLabel.el.innerHTML = P.lotUnlocked ? `🪙 ${fmt(pendingCoins())}<small>Recolector</small>` : "";
  }

  // Cámara
  if (cine && cineCam) { camPos.lerp(cineCam.pos, 0.06); camTarget.lerp(cineCam.look, 0.08); }
  else {
    camTarget.lerp(player.position.clone().add(V(0, 4, 0)), 0.15);
    const want = V(Math.sin(camYaw) * Math.cos(camPitch) * camDist, Math.sin(camPitch) * camDist + 2, Math.cos(camYaw) * Math.cos(camPitch) * camDist).add(player.position);
    camPos.lerp(want, 0.12);
  }
  camera.position.copy(camPos); camera.lookAt(camTarget);
  sun.position.copy(player.position).add(V(-140, 160, 110)); sun.target.position.copy(player.position);

  updatePrompt(); updateObjectiveArrow(); updateLabels();
  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}
function lerpAngle(a, b, t) { let d = ((b - a + Math.PI) % (Math.PI * 2)) - Math.PI; if (d < -Math.PI) d += Math.PI * 2; return a + d * t; }
addEventListener("resize", () => { camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix(); renderer.setSize(innerWidth, innerHeight); });

// Arranque (si se cerró la pestaña a mitad de la eclosión, no se repite)
P.logins = (P.logins || 0) + 1;
if (P.step === "Hatch" && starterPet()) Actions.ackHatch();
settleHabitat();
refreshOnboarding();
camPos.copy(player.position).add(V(0, 14, -24)); camTarget.copy(treeBase);
$("#loading").classList.add("hidden");
if (P.step === "Intro") showIntro();
else { inputLocked = false; showWorldUI(); toast("🌳", P.logins > 1 ? "¡Bienvenido de vuelta! Tu progreso se conservó." : "Bienvenido al Valle Copal"); }
refreshUI();
requestAnimationFrame(tick);
setInterval(() => { if (!battle && !modalOpen && !cine) refreshUI(); }, 5000);
// Ganchos para pruebas automatizadas de la vista previa
window.__nexora = { get P() { return P; }, Actions, startBattle, playTurn, openPetSheet, openSanctuary, openNexoMenu, refreshUI, endIntro, hatchSequence, player, get battle() { return battle; }, teleport: (x, z) => player.position.set(x, 0, z) };

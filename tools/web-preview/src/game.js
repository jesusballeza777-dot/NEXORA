// NEXORA · Vista previa web jugable del vertical slice (Valle Copal).
// Reglas: mismas cifras y motor de combate que el proyecto Roblox (config exportada
// desde Luau + engine.js con paridad comprobada). Arte: BLOCKOUTS provisionales.
import * as THREE from "three";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";

const CFG = NexoraNormalize.normalizeConfig(window.NEXORA_CONFIG);
// Etapas con Opaco físico en la Linde (las del mapa del Acto I no tienen marcador)
const WORLD_ENCOUNTERS = CFG.Encounters.Order.filter((id) => CFG.Encounters.ById[id].worldMarker);
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
// Escena · hora dorada, postproceso con resplandor y calidad adaptativa
// =====================================================================
const canvas = $("#scene");
const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, powerPreference: "high-performance" });
let pixelRatio = Math.min(devicePixelRatio, isTouch ? 1.5 : 1.75);
renderer.setPixelRatio(pixelRatio);
renderer.setSize(innerWidth, innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.02;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
const scene = new THREE.Scene();
const FOG_COLOR = new THREE.Color(0xf1c9a1);
scene.fog = new THREE.Fog(FOG_COLOR, 170, 680);
const camera = new THREE.PerspectiveCamera(55, innerWidth / innerHeight, 0.5, 2200);

const composer = new EffectComposer(renderer, new THREE.WebGLRenderTarget(innerWidth * pixelRatio, innerHeight * pixelRatio, { type: THREE.HalfFloatType, samples: isTouch ? 0 : 4 }));
composer.setPixelRatio(pixelRatio);
composer.setSize(innerWidth, innerHeight);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.55, 0.5, 0.86);
composer.addPass(bloom);
composer.addPass(new OutputPass());
let usePost = true;

const hemi = new THREE.HemisphereLight(0xffe3c0, 0x4d6a40, 1.15);
scene.add(hemi);
const sun = new THREE.DirectionalLight(0xffcd92, 2.7);
sun.castShadow = true;
sun.shadow.mapSize.set(isTouch ? 1024 : 2048, isTouch ? 1024 : 2048);
Object.assign(sun.shadow.camera, { left: -150, right: 150, top: 150, bottom: -150, near: 10, far: 520 });
sun.shadow.bias = -0.0005;
sun.shadow.normalBias = 0.04;
scene.add(sun, sun.target);
const coolFill = new THREE.DirectionalLight(0x9cc0ff, 0.5);
coolFill.position.set(160, 90, -140);
scene.add(coolFill);

// Cielo: degradado de atardecer, halo del sol y bandas suaves de nubes altas
const skyUniforms = { uTime: { value: 0 } };
{
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, fog: false, uniforms: skyUniforms,
    vertexShader: "varying vec3 vP; void main(){ vP = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }",
    fragmentShader: `uniform float uTime; varying vec3 vP;
      void main(){
        float h = vP.y;
        vec3 top = vec3(0.30,0.52,0.80), mid = vec3(0.98,0.80,0.60), low = vec3(0.93,0.62,0.45);
        vec3 c = h > 0.0 ? mix(mid, top, smoothstep(0.0, 0.6, h)) : mix(mid, low, smoothstep(0.0,-0.25,h));
        vec3 sd = normalize(vec3(-0.55,0.30,0.45));
        float d = max(dot(vP, sd), 0.0);
        c += vec3(1.0,0.78,0.5) * pow(d, 14.0) * 0.55 + vec3(1.0,0.95,0.85) * pow(d, 900.0) * 3.0;
        float band = sin(vP.x*9.0 + uTime*0.02) * sin(vP.z*7.0 - uTime*0.015);
        c = mix(c, vec3(1.0,0.93,0.86), smoothstep(0.55,1.0,band) * smoothstep(0.08,0.3,h) * 0.25);
        gl_FragColor = vec4(c,1.0);
      }`,
  });
  scene.add(new THREE.Mesh(new THREE.SphereGeometry(1500, 40, 20), mat));
}

const GEO = {
  sphere: new THREE.SphereGeometry(1, 32, 24),
  sphereLow: new THREE.IcosahedronGeometry(1, 2),
  box: new THREE.BoxGeometry(1, 1, 1),
  rbox: new RoundedBoxGeometry(1, 1, 1, 3, 0.12),
  cyl: new THREE.CylinderGeometry(1, 1, 1, 32),
  cone: new THREE.ConeGeometry(1, 1, 24),
  torus: new THREE.TorusGeometry(1, 0.08, 10, 48),
  dodeca: new THREE.DodecahedronGeometry(1, 0),
  blob: new THREE.IcosahedronGeometry(1, 3),
};
const matCache = new Map();
function mat(color, o = {}) {
  const key = `${color}|${JSON.stringify(o)}`;
  if (!o.unique && matCache.has(key)) return matCache.get(key);
  const Ctor = o.physical ? THREE.MeshPhysicalMaterial : THREE.MeshStandardMaterial;
  const m = new Ctor({
    color, roughness: o.rough ?? 0.85, metalness: o.metal ?? 0, flatShading: o.flat ?? false, map: o.map ?? null,
    emissive: o.emissive ?? 0x000000, emissiveIntensity: o.ei ?? 1, transparent: o.opacity != null, opacity: o.opacity ?? 1,
    vertexColors: !!o.vc, side: o.side ?? THREE.FrontSide,
  });
  if (o.physical) { m.clearcoat = o.clearcoat ?? 0.6; m.clearcoatRoughness = o.ccr ?? 0.25; if (o.sheen) { m.sheen = o.sheen; m.sheenColor = new THREE.Color(o.sheenColor ?? 0xffffff); } }
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
const plazaCenter = v3(W.Plaza.center);
const PAL = { copal: 0xe8a848, glow: 0xffc460, stone: 0xd2c3a8, stoneDark: 0x8d7a68, clay: 0xc06a44, adobe: 0xe9d2ae, jade: 0x3e967a, leaf: 0x5fa35c, leafDeep: 0x3b7a4e, bark: 0x6a4a3a, wood: 0x96693f, papel: [0xe84a6e, 0xfaba32, 0x40aad6, 0x9660de, 0x68be60] };

// ---------- Texturas procedurales (sin descargas: todo se dibuja aquí) ----------
function canvasTex(w, h, draw, repeat) {
  const c = document.createElement("canvas"); c.width = w; c.height = h;
  draw(c.getContext("2d"), w, h);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 4;
  if (repeat) { t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(repeat[0], repeat[1]); }
  return t;
}
// Greca escalonada (Mitla) para bordes, cántaros y caparazones
function drawGreca(g, x, y, w, h, fg, bg) {
  g.fillStyle = bg; g.fillRect(x, y, w, h);
  g.fillStyle = fg;
  const u = h / 6, step = u * 8;
  for (let sx = x - step; sx < x + w + step; sx += step) {
    g.fillRect(sx, y + u * 5, step, u);
    g.fillRect(sx + u, y + u, u, u * 4);
    g.fillRect(sx + u, y + u, u * 4, u);
    g.fillRect(sx + u * 4, y + u, u, u * 3);
    g.fillRect(sx + u * 3, y + u * 3, u * 2, u);
  }
}
const grecaTex = (fg, bg) => canvasTex(512, 64, (g, w, h) => { drawGreca(g, 0, 0, w, h, fg, bg); }, [1, 1]);
const glowTex = canvasTex(64, 64, (g, w, h) => { const r = g.createRadialGradient(w / 2, h / 2, 0, w / 2, h / 2, w / 2); r.addColorStop(0, "rgba(255,255,255,1)"); r.addColorStop(0.35, "rgba(255,255,255,0.55)"); r.addColorStop(1, "rgba(255,255,255,0)"); g.fillStyle = r; g.fillRect(0, 0, w, h); });
glowTex.colorSpace = THREE.NoColorSpace;
const papelTex = canvasTex(128, 150, (g, w, h) => {
  g.fillStyle = "#fff"; g.fillRect(0, 0, w, h - 18);
  for (let i = 0; i < 6; i++) { g.beginPath(); g.moveTo(i * (w / 6), h - 18); g.lineTo(i * (w / 6) + w / 12, h); g.lineTo((i + 1) * (w / 6), h - 18); g.fill(); }
  g.globalCompositeOperation = "destination-out";
  const hole = (x, y, r) => { g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill(); };
  hole(w / 2, 50, 18); for (let k = 0; k < 8; k++) { const a = (k / 8) * Math.PI * 2; hole(w / 2 + Math.cos(a) * 32, 50 + Math.sin(a) * 32, 6); }
  for (let k = 0; k < 5; k++) { g.save(); g.translate(14 + k * 25, 104); g.rotate(Math.PI / 4); g.fillRect(-6, -6, 12, 12); g.restore(); }
  for (let k = 0; k < 9; k++) hole(8 + k * 14, 12, 3.5);
});

// ---------- Suelo: pasto con matices, senderos de tierra y colinas ----------
const hash2 = (x, z) => { const s = Math.sin(x * 127.1 + z * 311.7) * 43758.5453; return s - Math.floor(s); };
function vnoise(x, z) {
  const xi = Math.floor(x), zi = Math.floor(z), xf = x - xi, zf = z - zi;
  const u = xf * xf * (3 - 2 * xf), v = zf * zf * (3 - 2 * zf);
  return lerp(lerp(hash2(xi, zi), hash2(xi + 1, zi), u), lerp(hash2(xi, zi + 1), hash2(xi + 1, zi + 1), u), v);
}
const fbm = (x, z) => vnoise(x, z) * 0.55 + vnoise(x * 2.1, z * 2.1) * 0.3 + vnoise(x * 4.3, z * 4.3) * 0.15;
const PATHS = [
  [[0, 30], [0, 64], [0, 88]], [[-110, 88], [160, 88]], ...W.Lots.positions.map((p) => [[p[0], 88], [p[0], p[2] - 18]]),
  [[-18, 14], [-50, 16], [-78, 10], [-104, -20], [-122, -56]], [[0, -12], [0, -30]], [[-26, -14], [-34, -20]],
];
function distToSeg(px, pz, a, b) { const dx = b[0] - a[0], dz = b[1] - a[1]; const t = clamp(((px - a[0]) * dx + (pz - a[1]) * dz) / (dx * dx + dz * dz || 1), 0, 1); return Math.hypot(px - (a[0] + dx * t), pz - (a[1] + dz * t)); }
function pathDist(x, z) { let d = Infinity; for (const p of PATHS) for (let i = 0; i < p.length - 1; i++) d = Math.min(d, distToSeg(x, z, p[i], p[i + 1])); return d; }
const riverCurve = new THREE.CatmullRomCurve3(W.River.points.map((p) => V(p[0], 0.25, p[2])));
const riverSamples = riverCurve.getPoints(160);
const riverDist = (x, z) => { let d = Infinity; for (const p of riverSamples) d = Math.min(d, Math.hypot(x - p.x, z - p.z)); return d; };
function heightAt(x, z) { const d = Math.hypot(x, z); return d > 270 ? Math.pow((d - 270) / 55, 2) * 2.4 + fbm(x * 0.02, z * 0.02) * 14 * clamp((d - 270) / 80, 0, 1) : 0; }
{
  const g = new THREE.RingGeometry(0.01, 700, 160, 80);
  g.rotateX(-Math.PI / 2);
  const c = new THREE.Color(), colors = [];
  const grassA = new THREE.Color(0x6fae55), grassB = new THREE.Color(0x4f8c45), dry = new THREE.Color(0xb3b05e), dirt = new THREE.Color(0xc79c6b), sand = new THREE.Color(0xd9c08e);
  const pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getZ(i);
    const n = fbm(x * 0.03, z * 0.03);
    c.copy(grassB).lerp(grassA, n);
    c.lerp(dry, clamp(fbm(x * 0.012 + 40, z * 0.012) - 0.45, 0, 1) * 0.9);
    const pd = pathDist(x, z);
    if (pd < 6) c.lerp(dirt, clamp(1 - (pd - 2.5) / 3.5, 0, 1) * (0.75 + n * 0.25));
    const rd = riverDist(x, z);
    if (rd < W.River.width / 2 + 7) c.lerp(sand, clamp(1 - (rd - W.River.width / 2) / 7, 0, 1));
    colors.push(c.r, c.g, c.b);
    pos.setY(i, heightAt(x, z));
  }
  g.setAttribute("color", new THREE.Float32BufferAttribute(colors, 3));
  g.computeVertexNormals();
  const ground = new THREE.Mesh(g, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.96 }));
  ground.receiveShadow = true;
  scene.add(ground);
}
// Montañas facetadas en capas (perspectiva atmosférica) y nubes lentas
const clouds = [];
{
  const layers = [[440, 0x7f9a6c, 16, 90], [540, 0x9aa98c, 20, 140], [660, 0xc0bba6, 24, 190]];
  for (const [r, colorHex, n, h] of layers) {
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2 + r * 0.01;
      const hh = h * (0.6 + hash2(i, r) * 0.6);
      const geo = new THREE.ConeGeometry(1, 1, 6 + (i % 3), 3);
      const p = geo.attributes.position;
      for (let k = 0; k < p.count; k++) { const y = p.getY(k); if (y < 0.45) { p.setX(k, p.getX(k) * (0.85 + hash2(k, i) * 0.3)); p.setZ(k, p.getZ(k) * (0.85 + hash2(i, k) * 0.3)); } }
      geo.computeVertexNormals();
      const m = mesh(geo, mat(colorHex, { flat: true, rough: 1 }), V(Math.cos(a) * r, hh * 0.45 - 6, Math.sin(a) * r), V(hh * 1.1, hh, hh * 0.9), [0, a, 0], scene, false);
      if (r > 600 && hh > 170) mesh(new THREE.ConeGeometry(0.27, 0.25, 6), mat(0xfff6ea, { flat: true }), V(0, 0.38, 0), null, null, m, false);
    }
  }
  const cloudMat = new THREE.MeshLambertMaterial({ color: 0xfff1e2, emissive: 0x5a3a2a, emissiveIntensity: 0.25 });
  for (let i = 0; i < 14; i++) {
    const g = new THREE.Group(); const a = hash2(i, 9) * Math.PI * 2, r = 200 + hash2(i, 3) * 320;
    g.position.set(Math.cos(a) * r, 130 + hash2(i, 5) * 80, Math.sin(a) * r);
    for (let k = 0; k < 5; k++) mesh(GEO.blob, cloudMat, V((k - 2) * 9, Math.sin(k) * 3, hash2(k, i) * 8), V(10 + hash2(i, k) * 8, 6 + hash2(k, k) * 4, 9), null, g, false);
    scene.add(g); clouds.push({ g, speed: 0.6 + hash2(i, 7) });
  }
}
// Río: lecho de arena + agua animada (franjas de luz, espuma en las orillas)
function ribbon(curve, width, y, material) {
  const pts = curve.getPoints(160), verts = [], uvs = [], idx = [];
  for (let i = 0; i < pts.length; i++) {
    const t = curve.getTangent(i / (pts.length - 1));
    const n = V(-t.z, 0, t.x).normalize().multiplyScalar(width / 2);
    verts.push(pts[i].x + n.x, y, pts[i].z + n.z, pts[i].x - n.x, y, pts[i].z - n.z);
    uvs.push(i / (pts.length - 1), 0, i / (pts.length - 1), 1);
    if (i > 0) { const k = i * 2; idx.push(k - 2, k - 1, k, k - 1, k + 1, k); }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(verts, 3));
  g.setAttribute("uv", new THREE.Float32BufferAttribute(uvs, 2));
  g.setIndex(idx); g.computeVertexNormals();
  const m = new THREE.Mesh(g, material); m.receiveShadow = true; scene.add(m); return m;
}
ribbon(riverCurve, W.River.width + 2, 0.1, mat(0x8a7350, { rough: 1 }));
const waterUniforms = THREE.UniformsUtils.merge([THREE.UniformsLib.fog, { uTime: { value: 0 } }]);
const water = ribbon(riverCurve, W.River.width, 0.32, new THREE.ShaderMaterial({
  transparent: true, fog: true, uniforms: waterUniforms,
  vertexShader: `varying vec2 vUv; varying vec3 vW;
#include <fog_pars_vertex>
    void main(){ vUv = uv; vec4 wp = modelMatrix * vec4(position,1.0); vW = wp.xyz; vec4 mvPosition = viewMatrix * wp; gl_Position = projectionMatrix * mvPosition;
#include <fog_vertex>
    }`,
  fragmentShader: `uniform float uTime; varying vec2 vUv; varying vec3 vW;
#include <fog_pars_fragment>
    void main(){
      float edge = min(vUv.y, 1.0 - vUv.y);
      vec3 deep = vec3(0.13,0.45,0.50), shallow = vec3(0.36,0.72,0.70);
      vec3 c = mix(shallow, deep, smoothstep(0.0, 0.5, edge));
      float flow = sin(vUv.x*520.0 - uTime*1.6 + sin(vW.z*0.3+uTime)*1.5) * sin(vUv.y*24.0 + uTime*0.7);
      c += vec3(0.85,0.95,1.0) * smoothstep(0.82, 1.0, flow) * 0.35;
      float foam = smoothstep(0.09, 0.0, edge + sin(vUv.x*300.0 + uTime*2.0)*0.015);
      c = mix(c, vec3(0.97,0.98,0.95), foam*0.85);
      gl_FragColor = vec4(c, 0.88);
#include <fog_fragment>
    }`,
}));
// Juncos en las orillas (instanciados)
{
  const reeds = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.08, 0.14, 1, 5), mat(0x7a8f43), 260);
  const tops = new THREE.InstancedMesh(new THREE.CapsuleGeometry(0.22, 0.7, 4, 8), mat(0x6b4a2e), 260);
  const m4 = new THREE.Matrix4(), q = new THREE.Quaternion(), s = new THREE.Vector3();
  for (let i = 0; i < 260; i++) {
    const p = riverSamples[Math.floor(hash2(i, 1) * riverSamples.length)];
    const side = hash2(i, 2) > 0.5 ? 1 : -1, off = W.River.width / 2 + 0.5 + hash2(i, 3) * 3;
    const t = riverCurve.getTangentAt(clamp(riverSamples.indexOf(p) / riverSamples.length, 0, 1));
    const h = 3 + hash2(i, 4) * 3;
    const pos = V(p.x - t.z * off * side + (hash2(i, 5) - 0.5) * 2, h / 2, p.z + t.x * off * side + (hash2(i, 6) - 0.5) * 2);
    if (Math.abs(pos.x) < 9 || Math.abs(pos.x - 104) < 9) { s.set(0, 0, 0); } else s.set(1, h, 1);
    q.setFromEuler(new THREE.Euler((hash2(i, 7) - 0.5) * 0.2, 0, (hash2(i, 8) - 0.5) * 0.2));
    reeds.setMatrixAt(i, m4.compose(pos, q, s));
    tops.setMatrixAt(i, m4.compose(pos.clone().setY(h - 0.2), q, s.x ? V(1, 1, 1) : V(0, 0, 0)));
  }
  scene.add(reeds, tops);
}
// Pasto que se mece con el viento (instanciado; menos hojas en móvil)
const grassUniforms = { uTime: { value: 0 } };
{
  const COUNT = isTouch ? 4500 : 11000;
  const blade = new THREE.BufferGeometry();
  blade.setAttribute("position", new THREE.Float32BufferAttribute([-0.13, 0, 0, 0.13, 0, 0, 0.02, 1, 0.05], 3));
  blade.setAttribute("color", new THREE.Float32BufferAttribute([0.42, 0.5, 0.36, 0.42, 0.5, 0.36, 1, 1, 0.92], 3));
  blade.computeVertexNormals();
  const gm = new THREE.MeshLambertMaterial({ vertexColors: true, side: THREE.DoubleSide });
  gm.onBeforeCompile = (sh) => {
    sh.uniforms.uTime = grassUniforms.uTime;
    sh.vertexShader = "uniform float uTime;\n" + sh.vertexShader.replace("#include <begin_vertex>", `#include <begin_vertex>
      vec4 ip = instanceMatrix * vec4(0.0,0.0,0.0,1.0);
      float sway = sin(uTime*1.8 + ip.x*0.12 + ip.z*0.09) * 0.35 + sin(uTime*3.1 + ip.z*0.3) * 0.08;
      transformed.x += sway * position.y; transformed.z += sway * 0.4 * position.y;`);
  };
  const grass = new THREE.InstancedMesh(blade, gm, COUNT);
  const m4 = new THREE.Matrix4(), q = new THREE.Quaternion(), color = new THREE.Color();
  const lotsRect = (x, z) => W.Lots.positions.some((p) => Math.abs(x - p[0]) < W.Lots.size[0] / 2 + 1 && Math.abs(z - p[2]) < W.Lots.size[1] / 2 + 1);
  let n = 0, tries = 0;
  while (n < COUNT && tries < COUNT * 6) {
    tries++;
    const a = hash2(tries, 11) * Math.PI * 2, r = 12 + Math.sqrt(hash2(tries, 12)) * 255;
    const x = Math.cos(a) * r, z = Math.sin(a) * r;
    if (Math.hypot(x - plazaCenter.x, z - plazaCenter.z) < W.Plaza.radius + 1.5 || pathDist(x, z) < 3.2 || riverDist(x, z) < W.River.width / 2 + 2.5 || lotsRect(x, z)) continue;
    if (Math.hypot(x - W.GranNexo.position[0], z - W.GranNexo.position[2]) < W.GranNexo.trunkRadius + 6) continue;
    const h = 0.55 + hash2(tries, 13) * 0.75;
    q.setFromAxisAngle(V(0, 1, 0), hash2(tries, 14) * Math.PI);
    grass.setMatrixAt(n, m4.compose(V(x, 0, z), q, V(1.1, h, 1)));
    color.setHSL(0.24 + hash2(tries, 15) * 0.06, 0.45 + hash2(tries, 16) * 0.15, 0.36 + fbm(x * 0.03, z * 0.03) * 0.14);
    grass.setColorAt(n, color);
    n++;
  }
  grass.count = n;
  grass.receiveShadow = !isTouch;
  scene.add(grass);
  // Flores: cempasúchil, buganvilia y blancas
  const flowers = new THREE.InstancedMesh(new THREE.IcosahedronGeometry(0.42, 0), mat(0xffffff, { rough: 0.7 }), 700);
  const fc = [new THREE.Color(0xf29a22), new THREE.Color(0xf6c234), new THREE.Color(0xd8549e), new THREE.Color(0xf4efe2), new THREE.Color(0x9a6be0)];
  let f = 0;
  for (let i = 0; f < 700 && i < 5000; i++) {
    const cx = (hash2(Math.floor(i / 9), 21) - 0.5) * 480, cz = (hash2(Math.floor(i / 9), 22) - 0.5) * 480;
    const x = cx + (hash2(i, 23) - 0.5) * 12, z = cz + (hash2(i, 24) - 0.5) * 12;
    if (Math.hypot(x, z) > 250 || Math.hypot(x - plazaCenter.x, z - plazaCenter.z) < W.Plaza.radius + 2 || pathDist(x, z) < 3.5 || riverDist(x, z) < W.River.width / 2 + 3 || lotsRect(x, z)) continue;
    flowers.setMatrixAt(f, m4.compose(V(x, 0.55, z), q, V(1, 0.8, 1)));
    flowers.setColorAt(f, fc[Math.floor(hash2(Math.floor(i / 9), 25) * fc.length)]);
    f++;
  }
  flowers.count = f;
  scene.add(flowers);
}

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

// ---------- Plaza de copal: mosaico de piedra con anillos de greca y espiral central ----------
const plazaC = plazaCenter;
function disc(r, h, pos, color, o = {}, parent = scene) { return mesh(GEO.cyl, mat(color, o), pos, V(r, h, r), null, parent); }
{
  const tex = canvasTex(1024, 1024, (g, w) => {
    const c = w / 2;
    g.fillStyle = "#d9c9ab"; g.fillRect(0, 0, w, w);
    // Losas irregulares
    for (let ring = 0; ring < 14; ring++) {
      const r0 = 40 + ring * 34, n = 8 + ring * 4;
      for (let k = 0; k < n; k++) {
        const a0 = (k / n) * Math.PI * 2, a1 = ((k + 1) / n) * Math.PI * 2;
        const shade = 196 + Math.floor(hash2(ring, k) * 30);
        g.fillStyle = `rgb(${shade + 14},${shade},${shade - 26})`;
        g.beginPath(); g.arc(c, c, r0 + 32, a0 + 0.004, a1 - 0.004); g.arc(c, c, r0, a1 - 0.004, a0 + 0.004, true); g.closePath(); g.fill();
      }
    }
    const band = (r, width, fg, bg) => {
      g.save(); g.translate(c, c);
      const n = Math.floor((Math.PI * 2 * r) / (width * 1.33));
      for (let k = 0; k < n; k++) { g.save(); g.rotate((k / n) * Math.PI * 2); g.translate(-width * 0.665, -r - width / 2); drawGreca(g, 0, 0, width * 1.36, width, fg, bg); g.restore(); }
      g.restore();
    };
    band(470, 34, "#e8a848", "#8a6a4e");
    band(330, 26, "#3e967a", "#cdbb9a");
    g.strokeStyle = "#8a6a4e"; g.lineWidth = 6;
    for (const r of [452, 488, 316, 344]) { g.beginPath(); g.arc(c, c, r, 0, Math.PI * 2); g.stroke(); }
    // Espiral de copal (el sello del Tallador)
    g.strokeStyle = "#e8a848"; g.lineWidth = 16; g.lineCap = "round"; g.beginPath();
    for (let t = 0; t < 1; t += 0.004) { const a = t * Math.PI * 6, r = 12 + t * 150; const x = c + Math.cos(a) * r, y = c + Math.sin(a) * r; t === 0 ? g.moveTo(x, y) : g.lineTo(x, y); }
    g.stroke();
  });
  const plaza = new THREE.Mesh(new THREE.CircleGeometry(W.Plaza.radius, 96), new THREE.MeshStandardMaterial({ map: tex, roughness: 0.9 }));
  plaza.rotation.x = -Math.PI / 2; plaza.position.set(plazaC.x, 0.35, plazaC.z); plaza.receiveShadow = true; scene.add(plaza);
  const curb = mesh(new THREE.CylinderGeometry(W.Plaza.radius + 0.8, W.Plaza.radius + 1.2, 0.7, 96, 1, true), mat(0xb7a588, { rough: 0.95, side: THREE.DoubleSide }), V(plazaC.x, 0.1, plazaC.z));
  curb.receiveShadow = true;
}
// Papel picado recortado, colgado alto para no tapar la cámara
const flags = [];
{
  const posts = [V(-26, 0, 22), V(26, 0, 22), V(-26, 0, -4), V(26, 0, -4)];
  posts.forEach((p) => { mesh(GEO.cyl, mat(PAL.wood), V(p.x, 10, p.z), V(0.45, 20, 0.45)); mesh(GEO.sphere, mat(PAL.copal, { emissive: 0xffa640, ei: 1.4 }), V(p.x, 20.4, p.z), 0.7, null, scene, false); });
  const flagGeo = new THREE.PlaneGeometry(1.35, 1.6);
  [[0, 1], [2, 3], [0, 2], [1, 3]].forEach(([a, b], s) => {
    const A = posts[a].clone().setY(19.5), B = posts[b].clone().setY(19.5), n = Math.floor(A.distanceTo(B) / 2.2);
    for (let i = 1; i < n; i++) {
      const t = i / n, p = A.clone().lerp(B, t); p.y -= Math.sin(t * Math.PI) * 1.8;
      const flag = mesh(flagGeo, new THREE.MeshStandardMaterial({ color: PAL.papel[(i + s) % 5], map: papelTex, alphaTest: 0.5, side: THREE.DoubleSide, roughness: 0.9, emissive: PAL.papel[(i + s) % 5], emissiveIntensity: 0.12 }), p, null, null, scene, false);
      flag.lookAt(p.clone().add(B.clone().sub(A).cross(V(0, 1, 0))));
      flag.userData.flutter = hash2(i, s) * 6;
      flags.push(flag);
    }
  });
}

// ---------- Gran Nexo: tronco retorcido, venas de copal que laten y copa con faroles ----------
const tree = new THREE.Group();
const treeBase = v3(W.GranNexo.position);
tree.position.copy(treeBase);
scene.add(tree);
let nexoHeart;
const veinMats = [];
{
  const H = W.GranNexo.trunkHeight, R = W.GranNexo.trunkRadius;
  const radiusAt = (t) => R * (1.55 - t * 0.85 + Math.pow(1 - t, 6) * 0.9);
  const profile = [];
  for (let i = 0; i <= 16; i++) { const t = i / 16; profile.push(new THREE.Vector2(radiusAt(t), t * H)); }
  const trunkGeo = new THREE.LatheGeometry(profile, 28);
  const tp = trunkGeo.attributes.position, colors = [], cc = new THREE.Color();
  for (let i = 0; i < tp.count; i++) {
    const y = tp.getY(i), a = (y / H) * 1.6, x = tp.getX(i), z = tp.getZ(i);
    const ridge = Math.sin(Math.atan2(z, x) * 9 + y * 0.15) * 0.35;
    tp.setX(i, (x * Math.cos(a) - z * Math.sin(a)) * (1 + ridge * 0.06) + Math.sin(y * 0.08) * 1.5);
    tp.setZ(i, (x * Math.sin(a) + z * Math.cos(a)) * (1 + ridge * 0.06));
    cc.setHex(PAL.bark).lerp(new THREE.Color(0x3c2a22), clamp(0.5 - ridge, 0, 1) * 0.6);
    colors.push(cc.r, cc.g, cc.b);
  }
  trunkGeo.setAttribute("color", new THREE.Float32BufferAttribute(colors, 3));
  trunkGeo.computeVertexNormals();
  mesh(trunkGeo, mat(0xffffff, { vc: true, rough: 0.9 }), null, null, null, tree);
  // Venas de copal: espirales luminosas que suben por el tronco (el "nexo")
  for (let v = 0; v < 4; v++) {
    const pts = [];
    for (let i = 0; i <= 40; i++) {
      const t = i / 40, y = t * H * 0.82, a = (y / H) * 1.6 + v * (Math.PI / 2) + t * 2.2;
      const r = radiusAt(t * 0.82) * 1.02 + 0.15;
      pts.push(V(Math.cos(a) * r + Math.sin(y * 0.08) * 1.5, y, Math.sin(a) * r));
    }
    const vm = new THREE.MeshStandardMaterial({ color: 0xffb64a, emissive: 0xff9a2a, emissiveIntensity: 2.2, roughness: 0.4 });
    veinMats.push(vm);
    mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 120, 0.32, 6), vm, null, null, null, tree, false);
  }
  for (let i = 0; i < 9; i++) {
    const a = (i / 9) * Math.PI * 2 + 0.2, len = 14 + (i % 3) * 5;
    const root = mesh(new THREE.CylinderGeometry(0.9, 2.2, 1, 10), mat(PAL.bark, { rough: 0.95 }), V(Math.cos(a) * (R + len / 2 - 2), 0.8, Math.sin(a) * (R + len / 2 - 2)), V(1, len, 0.9), null, tree);
    root.rotation.order = "YXZ"; root.rotation.set(-(Math.PI / 2 - 0.12), -a + Math.PI / 2, 0);
  }
  // Copa: racimos de follaje con degradado (sombra abajo, luz arriba)
  const leafGeo = GEO.blob.clone();
  {
    const p = leafGeo.attributes.position, cols = [], c = new THREE.Color();
    for (let i = 0; i < p.count; i++) { const y = p.getY(i); p.setXYZ(i, p.getX(i) * (1 + hash2(i, 1) * 0.12), y * (1 + hash2(i, 2) * 0.12), p.getZ(i) * (1 + hash2(i, 3) * 0.12)); c.setHex(0x2f6b40).lerp(new THREE.Color(0x9ccf6a), clamp((y + 1) / 2, 0, 1)); cols.push(c.r, c.g, c.b); }
    leafGeo.setAttribute("color", new THREE.Float32BufferAttribute(cols, 3)); leafGeo.computeVertexNormals();
  }
  const leafMat = mat(0xffffff, { vc: true, rough: 0.85 });
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2 + 0.3, start = V(0, H * 0.72, 0);
    const tip = V(Math.cos(a) * W.GranNexo.canopyRadius * 0.62, H * 0.72 + 12 + (i % 2) * 7, Math.sin(a) * W.GranNexo.canopyRadius * 0.62);
    const mid = start.clone().add(tip).multiplyScalar(0.5);
    const br = mesh(new THREE.CylinderGeometry(0.9, 1.8, 1, 10), mat(PAL.bark), mid, V(1, start.distanceTo(tip), 1), null, tree);
    br.lookAt(tip.clone().add(tree.position)); br.rotateX(Math.PI / 2);
    for (let k = 0; k < 4; k++) mesh(leafGeo, leafMat, tip.clone().add(V((k - 1.5) * 6, 3 + (k % 2) * 4, Math.sin(k * 2 + i) * 5)), V(10 - (k % 2) * 2, 7.5, 10 - (k % 3)), [k, i, 0], tree);
    // Faroles colgantes de copal
    for (let k = 0; k < 2; k++) {
      const lp = tip.clone().add(V((k ? 4 : -3), -6 - k * 2, k ? -2 : 3));
      mesh(GEO.cyl, mat(0x3a2a20), lp.clone().add(V(0, 2.4, 0)), V(0.06, 4.6, 0.06), null, tree, false);
      const lantern = mesh(GEO.sphere, mat(PAL.glow, { emissive: 0xffa640, ei: 2.4 }), lp, V(1.0, 1.35, 1.0), null, tree, false);
      if (i % 4 === 0 && k === 0) lantern.add(new THREE.PointLight(0xffb653, 50, 28, 1.6));
    }
  }
  mesh(leafGeo, leafMat, V(0, H + 12, 0), V(22, 13, 22), [0.3, 0.2, 0], tree);
  mesh(leafGeo, leafMat, V(9, H + 5, -7), V(15, 10, 15), [0.6, 0.4, 0], tree);
  mesh(leafGeo, leafMat, V(-10, H + 6, 6), V(14, 9, 14), [0.2, 0.9, 0], tree);
  nexoHeart = mesh(GEO.sphere, mat(PAL.glow, { emissive: 0xffa030, ei: 3.2, unique: true }), V(0, 9, R * 1.18), V(2.6, 3.3, 1.6), null, tree, false);
  nexoHeart.add(new THREE.PointLight(0xffb653, 80, 34, 1.5));
  addLabel(treeBase.clone().add(V(0, H + 32, 0)), "Gran Nexo<small>El árbol es el menú: toca su corazón</small>", { max: 260 });
}
// Luciérnagas de copal alrededor del árbol y la plaza
const motesUniforms = { uTime: { value: 0 }, uTex: { value: glowTex }, uScale: { value: innerHeight * 0.5 } };
{
  const N = isTouch ? 160 : 320, pos = [], seed = [];
  for (let i = 0; i < N; i++) {
    const a = hash2(i, 31) * Math.PI * 2, r = 6 + hash2(i, 32) * 46;
    pos.push(treeBase.x + Math.cos(a) * r, 8 + hash2(i, 33) * 58, treeBase.z + 6 + Math.sin(a) * r);
    seed.push(hash2(i, 34) * 100);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute("seed", new THREE.Float32BufferAttribute(seed, 1));
  const m = new THREE.ShaderMaterial({
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, uniforms: motesUniforms,
    vertexShader: `uniform float uTime; uniform float uScale; attribute float seed; varying float vA;
      void main(){ vec3 p = position; p.x += sin(uTime*0.4 + seed)*2.5; p.y += sin(uTime*0.6 + seed*1.7)*1.8; p.z += cos(uTime*0.35 + seed)*2.5;
        vec4 mv = modelViewMatrix * vec4(p,1.0); gl_Position = projectionMatrix * mv; vA = 0.5 + 0.5*sin(uTime*2.0 + seed*3.0);
        gl_PointSize = (0.35 + vA * 0.55) * uScale / -mv.z; }`,
    fragmentShader: `uniform sampler2D uTex; varying float vA; void main(){ vec4 t = texture2D(uTex, gl_PointCoord); gl_FragColor = vec4(vec3(1.0,0.58,0.18)*1.25, t.a*vA*0.9); }`,
  });
  const pts = new THREE.Points(g, m); pts.frustumCulled = false; scene.add(pts);
}

// ---------- Huevos iniciales: copal pulido con espiral tallada ----------
const eggs = {};
for (const egg of CFG.Onboarding.StarterEggs) {
  const p = v3(W.StarterEggPedestals[egg.eggId]);
  mesh(GEO.cyl, mat(PAL.stone, { map: grecaTex("#a88b62", "#d8c8a6") }), V(p.x, 0.75, p.z), V(3.2, 1.5, 3.2));
  mesh(GEO.cyl, mat(PAL.copal, { physical: true, rough: 0.2, clearcoat: 1, opacity: 0.8, emissive: 0x7a3a00, ei: 0.4 }), V(p.x, 1.6, p.z), V(2.6, 0.3, 2.6));
  const g = new THREE.Group(); g.position.set(p.x, 4.3, p.z); scene.add(g);
  const shell = mesh(GEO.sphere, mat(0xe9a648, { physical: true, rough: 0.28, clearcoat: 1, ccr: 0.1, sheen: 0.6, sheenColor: 0xffe2a0, emissive: 0x5a2600, ei: 0.25, unique: true }), null, V(1.6, 2.15, 1.6), null, g);
  const helix = new THREE.CatmullRomCurve3(Array.from({ length: 40 }, (_, i) => { const t = i / 39, a = t * Math.PI * 5, y = -1.7 + t * 3.4, r = 1.62 * Math.sqrt(Math.max(0.05, 1 - (y / 2.15) ** 2)); return V(Math.cos(a) * r, y, Math.sin(a) * r); }));
  mesh(new THREE.TubeGeometry(helix, 120, 0.09, 6), mat(0x9a5f24, { rough: 0.5 }), null, null, null, g, false);
  const glow = new THREE.PointLight(col(egg.pulseColor), 0, 14, 1.8); g.add(glow);
  eggs[egg.eggId] = { group: g, shell, glow, egg, base: p };
}

// ---------- Estaciones: casitas de adobe con toldo de papel picado ----------
for (const [id, st] of Object.entries(W.Stations)) {
  const p = v3(st.position);
  const g = new THREE.Group(); g.position.copy(p); g.rotation.y = Math.atan2(treeBase.x - p.x, treeBase.z - p.z); scene.add(g);
  const color = PAL.papel[id.length % 5];
  mesh(GEO.cyl, mat(PAL.stoneDark, { map: grecaTex("#e8a848", "#7a6656") }), V(0, 0.4, 0), V(7, 0.8, 7), null, g);
  mesh(GEO.rbox, mat(st.implemented ? PAL.adobe : 0xb9ab98, { rough: 0.95 }), V(0, 3.7, -0.5), V(9, 6.2, 5.5), null, g);
  mesh(GEO.box, mat(0x6a4a3a), V(0, 6.9, -0.5), V(9.6, 0.5, 6.1), null, g);
  [-4.6, 4.6].forEach((x) => mesh(GEO.cyl, mat(PAL.wood), V(x, 3.5, 3.2), V(0.3, 7, 0.3), null, g));
  const roofGeo = new THREE.ConeGeometry(1, 1, 4); roofGeo.rotateY(Math.PI / 4);
  mesh(roofGeo, mat(color, { rough: 0.8 }), V(0, 9.2, -0.5), V(7.6, 3.6, 5.6), null, g);
  // Toldo a rayas
  for (let k = 0; k < 6; k++) mesh(GEO.box, mat(k % 2 ? 0xfff2dc : color), V(-3.75 + k * 1.5, 6.9, 2.3), V(1.5, 0.12, 2.4), [0.35, 0, 0], g);
  mesh(GEO.rbox, mat(0x3a271d), V(0, 2.6, 2.28), V(3.2, 4, 0.2), null, g);
  if (st.implemented) { const l = mesh(GEO.sphere, mat(PAL.glow, { emissive: 0xffa640, ei: 2.5 }), V(3.2, 5.4, 3.3), V(0.6, 0.8, 0.6), null, g, false); l.add(new THREE.PointLight(0xffb653, 25, 14, 1.8)); }
  addLabel(p.clone().add(V(0, 13.5, 0)), `${st.label}${st.implemented ? "" : "<small>Próximamente</small>"}`, { max: 120 });
}
// Mirador: arcos de piedra con greca y vitral del color de cada bioma, sellados
for (const gate of W.BiomeGates) {
  const p = v3(gate.position), g = new THREE.Group(); g.position.copy(p); g.lookAt(treeBase.x, 0, treeBase.z); scene.add(g);
  const elementByBiome = { MareaCoralina: "Agua", CumbreBrasa: "Fuego", MesetaFulgor: "Rayo", VeloAstral: "Astral" };
  const c = col(CFG.Elements.ById[elementByBiome[gate.biome]].color);
  const stone = mat(PAL.stone, { map: grecaTex("#a88b62", "#d8c8a6"), rough: 0.95 });
  [-6, 6].forEach((x) => mesh(GEO.rbox, stone, V(x, 10, 0), V(3, 20, 3), null, g));
  mesh(GEO.rbox, stone, V(0, 21, 0), V(16, 3, 3.2), null, g);
  mesh(GEO.box, new THREE.MeshStandardMaterial({ color: c, transparent: true, opacity: 0.55, emissive: c, emissiveIntensity: 0.9, roughness: 0.1 }), V(0, 10, 0), V(9, 18, 0.5), null, g, false);
  const b = CFG.Species.Biomes[gate.biome];
  addLabel(p.clone().add(V(0, 25, 0)), `${b.name}<small>${b.act} · sellado</small>`, { max: 160 });
}

// ---------- Lotes Hogar (el del jugador es el 3, al sur del río) ----------
const LOT_INDEX = 2;
const lotC = v3(W.Lots.positions[LOT_INDEX]);
const slotWorld = W.Lots.slotOffsets.map((o) => lotC.clone().add(v3(o)));
const collectorPos = lotC.clone().add(v3(W.Lots.collectorOffset));
let collectorCoinsLabel;
const borderMat = mat(PAL.stone, { map: grecaTex("#3e967a", "#d8c8a6"), rough: 0.95 });
W.Lots.positions.forEach((pos, i) => {
  const c = v3(pos), mine = i === LOT_INDEX;
  mesh(GEO.box, mat(mine ? 0x86b86a : 0x7eaa62, { rough: 1 }), V(c.x, 0.35, c.z), V(W.Lots.size[0], 0.7, W.Lots.size[1]));
  for (const [sx, sz, w, d] of [[0, -1, W.Lots.size[0], 1.4], [0, 1, W.Lots.size[0], 1.4], [-1, 0, 1.4, W.Lots.size[1]], [1, 0, 1.4, W.Lots.size[1]]])
    mesh(GEO.rbox, borderMat, V(c.x + (sx * W.Lots.size[0]) / 2, 0.9, c.z + (sz * W.Lots.size[1]) / 2), V(w, 1.4, d));
  if (!mine) { addLabel(c.clone().add(V(0, 6, -W.Lots.size[1] / 2)), "Lote libre", { max: 90 }); return; }
  disc(16, 0.3, lotC.clone().add(v3(W.Lots.habitatOffset)).setY(0.75), 0x9cc77c);
  slotWorld.forEach((p, s) => {
    mesh(GEO.cyl, mat(PAL.stone, { map: grecaTex("#e8a848", "#cdbb9a") }), V(p.x, 0.9, p.z), V(3.3, 0.8, 3.3));
    mesh(GEO.cyl, mat(PAL.copal, { physical: true, rough: 0.25, clearcoat: 1, emissive: 0x6a3200, ei: 0.35 }), V(p.x, 1.45, p.z), V(2.8, 0.3, 2.8));
    addLabel(V(p.x, 2.8, p.z), `<small>Lugar ${s + 1}</small>`, { max: 40 });
  });
  const jar = new THREE.LatheGeometry([0, 1.6, 2.1, 2.2, 1.8, 1.0, 1.1].map((r, k) => new THREE.Vector2(r, k * 0.8)), 32);
  mesh(jar, mat(PAL.clay, { rough: 0.6 }), collectorPos.clone().setY(0.7));
  mesh(new THREE.CylinderGeometry(2.22, 2.22, 0.7, 32, 1, true), mat(0xffffff, { map: grecaTex("#fff4de", "#a8502e"), side: THREE.DoubleSide }), collectorPos.clone().setY(3.2), null, null, scene, false);
  collectorCoinsLabel = addLabel(collectorPos.clone().add(V(0, 7.5, 0)), "", { max: 70 });
  const inc = lotC.clone().add(v3(W.Lots.incubatorOffset));
  mesh(GEO.cyl, mat(PAL.stone, { map: grecaTex("#e8a848", "#cdbb9a") }), V(inc.x, 0.8, inc.z), V(2.8, 1.4, 2.8));
  const ring = mesh(GEO.torus, mat(PAL.glow, { emissive: 0xffa640, ei: 2 }), V(inc.x, 4, inc.z), V(2.6, 2.6, 2.6), [Math.PI / 2, 0, 0], scene, false);
  spinners.push(ring);
  addLabel(V(inc.x, 7.5, inc.z), "Incubadora<small>Próximamente</small>", { max: 60 });
  const vit = lotC.clone().add(v3(W.Lots.vitrinaOffset));
  [-1, 0, 1].forEach((k) => { mesh(GEO.rbox, mat(PAL.wood), V(vit.x + k * 5, 1.1, vit.z), V(4.2, 1.6, 3.2)); mesh(GEO.sphere, new THREE.MeshPhysicalMaterial({ color: 0xdff0ff, transparent: true, opacity: 0.25, roughness: 0.05, clearcoat: 1 }), V(vit.x + k * 5, 2.2, vit.z), V(1.5, 1.7, 1.4), null, scene, false); });
  addLabel(V(vit.x, 5.2, vit.z), "Vitrina<small>3 Tallados · próximamente</small>", { max: 60 });
  addLabel(lotC.clone().add(V(0, 9, -W.Lots.size[1] / 2)), "Tu Lote Hogar", { max: 200, visible: () => P.lotUnlocked });
});
// Puentes de tablones con barandal
for (const b of W.Bridges) {
  const g = new THREE.Group(); g.position.set(b[0], 0, b[2]); scene.add(g);
  const L = W.River.width + 12;
  for (let k = 0; k < 14; k++) mesh(GEO.rbox, mat(k % 2 ? 0x8c6442 : 0x9a7048, { rough: 0.9 }), V(0, 1.1 + Math.sin((k / 13) * Math.PI) * 1.2, -L / 2 + (k + 0.5) * (L / 14)), V(10, 0.5, L / 14 - 0.1), null, g);
  for (const x of [-5, 5]) for (let k = 0; k <= 4; k++) mesh(GEO.cyl, mat(PAL.wood), V(x, 2.6 + Math.sin((k / 4) * Math.PI) * 1.2, -L / 2 + (k / 4) * L), V(0.25, 3, 0.25), null, g);
}
// Chinampas floridas
[-120, -40, 40, 130].forEach((x, i) => {
  const p = V(x, 0.5, 64 + (i % 2) * 4);
  mesh(GEO.rbox, mat(0x5a7a3e), p, V(12, 1.2, 7));
  for (let k = 0; k < 14; k++) {
    const fp = p.clone().add(V((k % 7) * 1.5 - 4.5, 1.0, k < 7 ? -1.6 : 1.6));
    mesh(GEO.cone, mat(0x4f8a3a), fp.clone().add(V(0, -0.1, 0)), V(0.45, 0.8, 0.45), null, scene, false);
    mesh(GEO.dodeca, mat([0xf29a22, 0xf6c234, 0xd8549e, 0xf4efe2][(k + i) % 4], { flat: true }), fp.clone().add(V(0, 0.45, 0)), 0.42, [k, k, 0], scene, false);
  }
});
// Árboles y rocas del valle (estilizados, deterministas)
{
  const trunkMat = mat(PAL.bark, { rough: 0.95 });
  const folGeo = GEO.blob.clone();
  { const p = folGeo.attributes.position, cols = [], c = new THREE.Color(); for (let i = 0; i < p.count; i++) { const y = p.getY(i); c.setHex(0x356b3e).lerp(new THREE.Color(0xa8d474), clamp((y + 1) / 2, 0, 1)); cols.push(c.r, c.g, c.b); } folGeo.setAttribute("color", new THREE.Float32BufferAttribute(cols, 3)); }
  const folMat = mat(0xffffff, { vc: true, rough: 0.85 });
  const rockMat = mat(0x8f8576, { flat: true, rough: 1 });
  const rnd = new ENG.Rng(2024);
  for (let i = 0; i < 90; i++) {
    const a = rnd.next() * Math.PI * 2, r = 60 + rnd.next() * 200;
    const p = V(Math.cos(a) * r, 0, Math.sin(a) * r);
    if (riverDist(p.x, p.z) < W.River.width / 2 + 6 || pathDist(p.x, p.z) < 7 || W.Lots.positions.some((l) => Math.abs(p.x - l[0]) < 26 && Math.abs(p.z - l[2]) < 26) || Object.values(W.Encounters).some((e) => Math.hypot(p.x - e.position[0], p.z - e.position[2]) < 18)) continue;
    const kind = rnd.next();
    if (kind < 0.62) {
      const h = 7 + rnd.next() * 6, g = new THREE.Group(); g.position.copy(p); g.rotation.y = rnd.next() * 6; scene.add(g);
      mesh(new THREE.CylinderGeometry(0.45, 0.9, 1, 8), trunkMat, V(0, h / 2, 0), V(1, h, 1), [0, 0, (rnd.next() - 0.5) * 0.15], g);
      const s = 3.5 + rnd.next() * 2.5;
      for (let k = 0; k < 3; k++) mesh(folGeo, folMat, V((k - 1) * s * 0.5, h + (k === 1 ? s * 0.5 : 0), (rnd.next() - 0.5) * s * 0.6), V(s, s * 0.85, s), [rnd.next(), rnd.next(), 0], g);
    } else if (kind < 0.82) {
      mesh(GEO.dodeca, rockMat, p.clone().setY(1), V(2 + rnd.next() * 3, 1.4 + rnd.next() * 2, 2 + rnd.next() * 3), [rnd.next(), rnd.next(), 0]);
    } else {
      mesh(folGeo, folMat, p.clone().setY(1.2), V(3 + rnd.next() * 2, 2.2, 3 + rnd.next() * 2), [0, rnd.next() * 6, 0]);
    }
  }
}

// ---------- Linde de las Chinampas: Opacos en niebla gris ----------
const encounterSpots = {};
const fogMat = () => new THREE.SpriteMaterial({ map: glowTex, color: 0xb9b9c4, transparent: true, opacity: 0.25, depthWrite: false });
for (const encId of WORLD_ENCOUNTERS) {
  const enc = CFG.Encounters.ById[encId], mk = W.Encounters[enc.worldMarker], p = v3(mk.position);
  const decal = new THREE.Mesh(new THREE.CircleGeometry(mk.radius * 0.75, 48), new THREE.MeshStandardMaterial({ color: 0x77787f, roughness: 1, transparent: true, opacity: 0.85 }));
  decal.rotation.x = -Math.PI / 2; decal.position.set(p.x, 0.08, p.z); decal.receiveShadow = true; scene.add(decal);
  for (let k = 0; k < 6; k++) { const a = k * 1.05 + 2.2; mesh(GEO.dodeca, mat(0x6e6e76, { flat: true, rough: 1 }), V(p.x + Math.cos(a) * 14, 1.2, p.z + Math.sin(a) * 14), V(1.8, 1.6 + (k % 3), 1.8), [k, a, 0]); }
  const fog = [];
  for (let k = 0; k < 9; k++) {
    const s = new THREE.Sprite(fogMat());
    s.position.set(p.x + Math.cos(k * 0.7) * (3 + (k % 3) * 2.5), 1.5, p.z + Math.sin(k * 0.7) * (3 + (k % 3) * 2.5));
    s.scale.set(9, 5, 1); scene.add(s); fog.push(s);
  }
  encounterSpots[encId] = { pos: p, fog, creature: null, label: addLabel(p.clone().add(V(0, 9, 0)), "", { max: 120 }) };
}

// Animación ambiental del mundo (llamada desde el bucle principal)
function worldTick(t, dt) {
  skyUniforms.uTime.value = t;
  grassUniforms.uTime.value = t;
  motesUniforms.uTime.value = t;
  waterUniforms.uTime.value = t;
  const pulse = 1.8 + Math.sin(t * 2.4) * 0.8;
  for (const vm of veinMats) vm.emissiveIntensity = pulse;
  for (const f of flags) f.rotation.x = Math.sin(t * 2.2 + f.userData.flutter) * 0.18;
  for (const c of clouds) { c.g.position.x += c.speed * dt; if (c.g.position.x > 560) c.g.position.x = -560; }
}

// =====================================================================
// Criaturas (BLOCKOUTS provisionales por arquetipo; ver docs/art/STARTERS_REDESIGN.md)
// Estilo: volúmenes suaves, ojos brillantes que parpadean, rubor en los Brotes,
// contorno ilustrado y luz de borde cálida. No son diseños aprobados.
// =====================================================================
const OUTLINE_MAT = new THREE.MeshBasicMaterial({ color: 0x2b1a12, side: THREE.BackSide });
function taperTube(curve, segs, r0, r1, radial = 10) {
  const g = new THREE.TubeGeometry(curve, segs, 1, radial, false);
  const p = g.attributes.position, ring = radial + 1;
  for (let i = 0; i < p.count; i++) {
    const seg = Math.floor(i / ring), t = seg / segs, c = curve.getPointAt(Math.min(1, t)), r = lerp(r0, r1, t);
    p.setXYZ(i, c.x + (p.getX(i) - c.x) * r, c.y + (p.getY(i) - c.y) * r, c.z + (p.getZ(i) - c.z) * r);
  }
  g.computeVertexNormals();
  return g;
}
const mosaicTex = canvasTex(512, 256, (g, w, h) => {
  g.fillStyle = "#8a6a46"; g.fillRect(0, 0, w, h);
  const cols = ["#c9a56c", "#e2c58f", "#3e967a", "#b88a52", "#ead7b0"];
  for (let y = 0; y < h; y += 16) for (let x = (y / 16) % 2 ? 8 : 0; x < w; x += 16) { g.fillStyle = cols[Math.floor(hash2(x, y) * cols.length)]; g.fillRect(x + 1.5, y + 1.5, 13, 13); }
  drawGreca(g, 0, h - 44, w, 40, "#e8a848", "#5e4632");
});
const starTex = canvasTex(256, 256, (g, w, h) => {
  const r = g.createRadialGradient(w / 2, h / 2, 10, w / 2, h / 2, w / 2); r.addColorStop(0, "#2c3a78"); r.addColorStop(1, "#0d1230");
  g.fillStyle = r; g.fillRect(0, 0, w, h);
  for (let i = 0; i < 90; i++) { g.fillStyle = `rgba(255,240,210,${0.4 + hash2(i, 2) * 0.6})`; g.beginPath(); g.arc(hash2(i, 0) * w, hash2(i, 1) * h, 0.6 + hash2(i, 3) * 1.8, 0, 7); g.fill(); }
  g.strokeStyle = "rgba(255,230,170,0.5)"; g.lineWidth = 1.2; g.beginPath(); g.moveTo(60, 80); g.lineTo(110, 70); g.lineTo(150, 120); g.lineTo(190, 100); g.stroke();
});
const wingTex = canvasTex(128, 256, (g, w, h) => {
  g.fillStyle = "rgba(220,245,255,0.35)"; g.beginPath(); g.ellipse(w / 2, h / 2, w / 2 - 2, h / 2 - 2, 0, 0, 7); g.fill();
  g.strokeStyle = "rgba(120,80,40,0.9)"; g.lineWidth = 2;
  for (let k = 0; k < 6; k++) { g.beginPath(); g.moveTo(w / 2, 8); g.quadraticCurveTo(w * (0.15 + k * 0.14), h * 0.5, w * (0.1 + k * 0.16), h - 10); g.stroke(); }
});
wingTex.colorSpace = THREE.SRGBColorSpace;

function buildCreature(speciesId, form, opaco = false) {
  const vis = CFG.Visuals.ById[speciesId];
  const pal = form === "Tallado" ? vis.tallado : vis.brote;
  const T = form === "Tallado";
  const root = new THREE.Group(), body = new THREE.Group();
  root.add(body);
  const parts = { tail: [], gills: [], legs: [], spin: [], glow: [], eyes: [], ears: [] };
  const mats = [];
  const rim = { color: { value: new THREE.Color(0xffe2b0) }, strength: { value: 0.42 } };
  const M = (rgb, o = {}) => {
    const m = mat(Array.isArray(rgb) ? col(rgb) : rgb, Object.assign({ rough: 0.55, unique: true }, o));
    if (!o.noRim) {
      m.onBeforeCompile = (sh) => {
        sh.uniforms.rimColor = rim.color; sh.uniforms.rimStrength = rim.strength;
        sh.fragmentShader = sh.fragmentShader.replace("#include <common>", "#include <common>\nuniform vec3 rimColor; uniform float rimStrength;")
          .replace("#include <emissivemap_fragment>", "#include <emissivemap_fragment>\n{ float rimF = pow(1.0 - clamp(dot(normalize(vViewPosition), normal), 0.0, 1.0), 2.6); totalEmissiveRadiance += rimColor * rimF * rimStrength; }");
      };
      m.customProgramCacheKey = () => "nexo-rim";
    }
    mats.push(m);
    return m;
  };
  const outline = (m, k = 1.05) => { const o = new THREE.Mesh(m.geometry, OUTLINE_MAT); o.scale.setScalar(k); o.castShadow = false; m.add(o); return m; };
  const S = (parent, m, pos, sc, rot, ol = true) => { const x = mesh(GEO.sphere, m, pos, sc, rot, parent); if (ol) outline(x); return x; };
  const bodyM = M(pal.body, speciesId === "xolumi" ? { physical: true, rough: 0.42, clearcoat: 0.55, ccr: 0.35 } : { rough: 0.6 });
  // Luz de borde más tenue en cuerpos oscuros (evita el aspecto de vidrio)
  const lum = (pal.body[0] * 0.299 + pal.body[1] * 0.587 + pal.body[2] * 0.114) / 255;
  rim.strength.value = lum < 0.25 ? 0.16 : 0.42;
  rim.base = rim.strength.value;
  const bellyM = M(pal.belly), accM = M(pal.accent);
  const glowM = M(pal.emissive, { emissive: col(pal.emissive), ei: T ? 0.75 : 0.35, noRim: true });
  const blushM = M([255, 140, 150], { opacity: 0.55, noRim: true });
  const darkM = M([34, 22, 18], { rough: 0.4, noRim: true });
  parts.glow.push(glowM);

  function eyes(parent, at, spread, size) {
    for (const s of [-1, 1]) {
      const e = new THREE.Group(); e.position.copy(at).add(V(s * spread, 0, 0)); parent.add(e);
      if (!T) {
        S(e, M([252, 252, 248], { rough: 0.2, noRim: true }), V(0, 0, 0), V(size, size * 1.12, size * 0.72), null, false);
        S(e, M(pal.eye, { physical: true, rough: 0.1, clearcoat: 1, noRim: true }), V(0, -size * 0.06, size * 0.42), V(size * 0.72, size * 0.8, size * 0.42), null, false);
        S(e, M([255, 255, 255], { emissive: 0xffffff, ei: 1.4, noRim: true }), V(s * -size * 0.22, size * 0.3, size * 0.78), size * 0.2, null, false);
        S(e, M([255, 255, 255], { emissive: 0xffffff, ei: 1.2, noRim: true }), V(s * size * 0.18, -size * 0.2, size * 0.8), size * 0.09, null, false);
        S(parent, blushM, at.clone().add(V(s * (spread + size * 0.35), -size * 1.05, size * 0.35)), V(size * 0.55, size * 0.3, size * 0.15), null, false);
      } else {
        S(e, M([248, 240, 222], { rough: 0.25, noRim: true }), V(0, 0, 0), V(size * 1.15, size * 0.56, size * 0.6), [0, 0, s * 0.3], false);
        S(e, M(pal.iris, { emissive: col(pal.iris), ei: 1.3, noRim: true }), V(0, 0, size * 0.36), V(size * 0.52, size * 0.48, size * 0.3), null, false);
        mesh(GEO.box, darkM, V(0, 0, size * 0.56), V(size * 0.12, size * 0.62, size * 0.08), null, e, false);
        S(e, M([255, 255, 255], { emissive: 0xffffff, ei: 1.4, noRim: true }), V(-s * size * 0.15, size * 0.12, size * 0.6), size * 0.08, null, false);
        mesh(GEO.rbox, accM, V(-s * size * 0.12, size * 0.56, size * 0.12), V(size * 1.45, size * 0.26, size * 0.32), [0, 0, s * 0.44], e);
      }
      parts.eyes.push(e);
    }
  }
  function smile(parent, at, w) {
    const sm = mesh(new THREE.TorusGeometry(w, w * 0.18, 8, 20, Math.PI * 0.8), darkM, at, null, [0, 0, Math.PI * 1.1], parent, false);
    return sm;
  }
  function fangs(parent, at, w) { for (const s of [-1, 1]) mesh(GEO.cone, M([250, 246, 236], { noRim: true }), at.clone().add(V(s * w, 0, 0)), V(0.07, 0.2, 0.07), [Math.PI, 0, 0], parent, false); }
  const legs = (n, y, xs, zs, r, h, m) => {
    for (let i = 0; i < n; i++) {
      const side = i % 2 ? 1 : -1, z = zs[Math.floor(i / 2)];
      const l = new THREE.Group(); l.position.set(side * xs, y, z); body.add(l);
      outline(mesh(new THREE.CapsuleGeometry(r, h, 4, 10), m, V(0, -h / 2, 0), null, null, l));
      S(l, m, V(0, -h - r * 0.3, r * 0.35), V(r * 1.25, r * 0.8, r * 1.5));
      parts.legs.push(l);
    }
  };

  switch (vis.archetype) {
    case "Opossum": {
      S(body, bodyM, V(0, T ? 1.0 : 1.15, 0), T ? V(0.86, 0.64, 1.7) : V(0.96, 0.84, 1.22));
      S(body, bellyM, V(0, T ? 0.86 : 1.0, T ? 0.45 : 0.32), T ? V(0.66, 0.46, 1.2) : V(0.72, 0.62, 0.82), null, false);
      // Bolsa-horno: tibia en el Brote, horno con rejilla al rojo en el Tallado
      S(body, glowM, V(0, T ? 0.72 : 0.86, T ? 0.95 : 0.78), T ? V(0.55, 0.42, 0.42) : V(0.48, 0.38, 0.36), null, false);
      if (T) {
        const ember = M(pal.emissive, { emissive: col(pal.emissive), ei: 1.8, noRim: true });
        S(body, ember, V(0, 0.72, 1.12), V(0.42, 0.32, 0.12), null, false);
        for (let k = -1; k <= 1; k++) mesh(GEO.box, darkM, V(k * 0.2, 0.72, 1.36), V(0.08, 0.66, 0.08), null, body, false);
        // Brasas que brillan en los surcos del lomo
        for (let k = 0; k < 4; k++) mesh(GEO.box, ember, V(0, 1.6, 0.9 - k * 0.6), V(0.5 - k * 0.06, 0.05, 0.08), [0.15, 0, 0], body, false);
      }
      const head = new THREE.Group(); head.position.set(0, T ? 1.45 : 1.86, T ? 1.75 : 1.05); body.add(head);
      S(head, bodyM, V(0, 0, 0), T ? V(0.62, 0.52, 0.72) : V(0.78, 0.7, 0.72));
      S(head, bellyM, V(0, -0.14, T ? 0.62 : 0.55), T ? V(0.3, 0.26, 0.85) : V(0.34, 0.28, 0.55));
      S(head, M([210, 110, 130], { noRim: true }), V(0, -0.08, T ? 1.42 : 1.08), 0.12, null, false);
      for (const s of [-1, 1]) {
        const ear = new THREE.Group(); ear.position.set(s * 0.48, T ? 0.44 : 0.52, -0.12); ear.rotation.z = s * (T ? -0.5 : -0.25); head.add(ear);
        S(ear, accM, V(0, 0, 0), T ? V(0.22, 0.42, 0.08) : V(0.36, 0.38, 0.09));
        S(ear, M([236, 166, 170], { noRim: true }), V(0, 0, 0.05), T ? V(0.14, 0.3, 0.05) : V(0.24, 0.26, 0.05), null, false);
        parts.ears.push(ear);
      }
      eyes(head, V(0, 0.16, T ? 0.5 : 0.58), T ? 0.26 : 0.3, T ? 0.17 : 0.22);
      if (T) fangs(head, V(0, -0.36, 0.95), 0.1); else smile(head, V(0, -0.34, 0.78), 0.1);
      legs(4, T ? 0.62 : 0.7, 0.5, [0.62, -0.62], 0.15, T ? 0.42 : 0.4, accM);
      // Cola pelada enroscada (Brote) → látigo de ceniza con anillos encendidos (Tallado)
      const tailG = new THREE.Group(); tailG.position.set(0, T ? 0.95 : 1.05, T ? -1.55 : -1.1); body.add(tailG);
      const pts = [];
      for (let i = 0; i <= 24; i++) {
        const t = i / 24, a = t * 4.2;
        if (T) pts.push(V(Math.sin(t * 5) * 0.12, 2.3 * Math.sin(t * Math.PI * 0.62), -1.5 * Math.sin(t * Math.PI * 0.9) + t * 0.6));
        else pts.push(V(0, 1.1 * Math.sin(t * Math.PI * 0.9) + t * 0.4 - Math.max(0, t - 0.6) * 0.8, -t * 1.4 + Math.sin(a) * 0.25 * t));
      }
      const curve = new THREE.CatmullRomCurve3(pts);
      outline(mesh(taperTube(curve, 48, T ? 0.24 : 0.2, 0.07), M(T ? [62, 56, 54] : [218, 178, 172]), null, null, null, tailG));
      const tip = curve.getPointAt(1);
      S(tailG, T ? M(pal.emissive, { emissive: col(pal.emissive), ei: 2.2, noRim: true }) : glowM, tip, T ? 0.24 : 0.13, null, false);
      if (T) for (let k = 1; k < 6; k++) { const p = curve.getPointAt(k / 6), tg = curve.getTangentAt(k / 6); const r = mesh(GEO.torus, glowM, p, V(lerp(0.2, 0.08, k / 6) * 1.1, lerp(0.2, 0.08, k / 6) * 1.1, 1), null, tailG, false); r.lookAt(p.clone().add(tg).add(tailG.position)); }
      parts.tail.push(tailG);
      break;
    }
    case "Axolotl": {
      const gillM = M(T ? [70, 214, 206] : pal.accent, { emissive: col(T ? [40, 200, 190] : pal.accent), ei: T ? 0.8 : 0.25, noRim: true });
      const torso = new THREE.Group(); torso.rotation.x = T ? -0.35 : 0; torso.position.y = T ? 0.45 : 0; body.add(torso);
      S(torso, bodyM, V(0, 0.86, -0.1), T ? V(0.86, 0.64, 1.72) : V(0.96, 0.6, 1.3));
      S(torso, M(pal.belly, { physical: true, rough: 0.35, clearcoat: 0.8 }), V(0, 0.64, 0.05), T ? V(0.7, 0.4, 1.4) : V(0.76, 0.38, 1.1), null, false);
      const head = new THREE.Group(); head.position.set(0, T ? 1.3 : 1.08, T ? 1.7 : 1.38); torso.add(head);
      S(head, bodyM, V(0, 0, 0), T ? V(1.08, 0.66, 0.86) : V(1.18, 0.74, 0.88));
      eyes(head, V(0, 0.24, 0.64), T ? 0.5 : 0.48, T ? 0.17 : 0.24);
      if (T) fangs(head, V(0, -0.26, 0.78), 0.24); else smile(head, V(0, -0.2, 0.84), 0.26);
      for (const s of [-1, 1]) for (let k = 0; k < 3; k++) {
        const g = new THREE.Group(); g.position.set(s * (T ? 0.95 : 1.0), 0.18 + k * 0.24, -0.22 - k * 0.12); g.rotation.set(-0.35 + k * 0.32, 0, s * (0.95 + k * 0.12)); head.add(g);
        const len = T ? 1.35 : 0.95;
        const c = new THREE.CatmullRomCurve3([V(0, 0, 0), V(0, len * 0.5, -0.08), V(0, len, 0.06)]);
        mesh(taperTube(c, 12, 0.09, 0.03, 6), gillM, null, null, null, g, false);
        for (let f = 0; f < 6; f++) { const p = c.getPointAt(0.25 + f * 0.13); S(g, gillM, p.add(V(0, 0, 0.07)), V(0.17 - f * 0.012, 0.07, 0.13), [0, 0, 0.3 * (f % 2 ? 1 : -1)], false); }
        parts.gills.push(g);
      }
      S(torso, M(T ? [214, 170, 74] : pal.accent, { opacity: 0.8, metal: T ? 0.6 : 0 }), V(0, 1.0, T ? -1.95 : -1.6), V(0.08, 0.58, 1.15), null, false);
      const n = T ? 6 : 4;
      for (let i = 0; i < n; i++) {
        const side = i % 2 ? 1 : -1, z = [0.72, -0.72, 0][Math.floor(i / 2)];
        const l = new THREE.Group(); l.position.set(side * 0.86, 0.45, z); torso.add(l);
        S(l, bodyM, V(0, -0.1, 0), V(0.24, 0.4, 0.24));
        for (let d = -1; d <= 1; d++) S(l, bodyM, V(d * 0.1, -0.46, 0.14), V(0.06, 0.05, 0.12), null, false);
        parts.legs.push(l);
      }
      if (T) {
        // Cicatrices doradas: reparación de cerámica que sigue las grietas del barro
        const goldM = M([226, 184, 84], { metal: 0.85, rough: 0.25, emissive: col([150, 96, 20]), ei: 0.8 });
        for (let k = 0; k < 4; k++) {
          const pts = []; for (let i = 0; i <= 10; i++) { const t = i / 10, a = -0.9 + t * 1.8 + k * 0.7; pts.push(V(Math.sin(a) * 0.87 * (k % 2 ? 1 : -1), 0.86 + Math.cos(a) * 0.62 * 0.95, -1.2 + k * 0.6 + t * 0.4)); }
          mesh(taperTube(new THREE.CatmullRomCurve3(pts), 20, 0.035, 0.02, 5), goldM, null, null, null, torso, false);
        }
      }
      break;
    }
    case "Tortoise": {
      const shellM = M(0xffffff, { map: mosaicTex, rough: 0.55 });
      if (!T) {
        outline(mesh(new THREE.SphereGeometry(1, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2), shellM, V(0, 0.78, 0), V(1.3, 1.2, 1.5), null, body));
        mesh(GEO.torus, accM, V(0, 0.8, 0), V(1.32, 1.52, 3), [Math.PI / 2, 0, 0], body, false);
      } else {
        const sideM = M(0xffffff, { map: grecaTex("#e8a848", "#7a5c40"), rough: 0.6 });
        [[1.4, 0.55, 0.78], [1.08, 0.5, 1.28], [0.74, 0.45, 1.74]].forEach(([r, h, y]) => { outline(mesh(new THREE.CylinderGeometry(r * 0.96, r * 1.04, h, 32), sideM, V(0, y, 0), V(1, 1, 1.15), null, body), 1.03); mesh(new THREE.CircleGeometry(r * 0.96, 32), shellM, V(0, y + h / 2 + 0.01, 0), V(1, 1.15, 1), [-Math.PI / 2, 0, 0], body, false); });
        const ringM = M([214, 160, 58], { metal: 0.85, rough: 0.3, emissive: col([120, 80, 20]), ei: 0.35 });
        for (let k = 0; k < 2; k++) { const r = mesh(GEO.torus, ringM, V(0, 2.25, 0), 1.6 + k * 0.42, [Math.PI / 2 + k * 0.5, 0, k * 0.4], body, false); parts.spin.push({ obj: r, axis: k ? "y" : "z", speed: k ? 0.6 : -0.9 }); }
        const discG = new THREE.Group(); discG.position.set(0, 3.25, 0.1); discG.rotation.x = 0.35; body.add(discG);
        outline(mesh(new THREE.CylinderGeometry(1, 1, 0.12, 40), M(0xffffff, { map: starTex, emissive: 0xffffff, ei: 0.05, rough: 0.4 }), null, V(0.98, 1, 0.98), null, discG), 1.04);
        mesh(new THREE.CircleGeometry(0.98, 40), M(0xffffff, { map: starTex, emissive: col([120, 130, 220]), ei: 0.35, noRim: true }), V(0, 0.07, 0), null, [-Math.PI / 2, 0, 0], discG, false);
        parts.spin.push({ obj: discG, axis: "y", speed: 0.4 });
      }
      legs(4, 0.62, 0.86, [0.76, -0.76], T ? 0.3 : 0.27, 0.5, bellyM);
      const head = new THREE.Group(); head.position.set(0, T ? 1.05 : 0.92, T ? 1.9 : 1.62); body.add(head);
      outline(mesh(new THREE.CapsuleGeometry(0.24, 0.5, 4, 10), bellyM, V(0, -0.15, -0.42), null, [Math.PI / 2.6, 0, 0], head));
      S(head, bellyM, V(0, 0, 0), T ? V(0.5, 0.44, 0.6) : V(0.54, 0.5, 0.52));
      eyes(head, V(0, 0.12, T ? 0.42 : 0.38), T ? 0.22 : 0.24, T ? 0.13 : 0.16);
      if (!T) smile(head, V(0, -0.2, 0.47), 0.08);
      break;
    }
    case "Agave": {
      S(body, bodyM, V(0, 0.95, 0), 0.74);
      const n = T ? 11 : 8;
      const leafGeo = new THREE.ConeGeometry(0.32, 1, 6, 4); leafGeo.translate(0, 0.5, 0);
      for (let i = 0; i < n; i++) {
        const a = (i / n) * Math.PI * 2, lg = new THREE.Group(); lg.position.set(0, 0.6, 0); lg.rotation.set(0, a, 0); body.add(lg);
        const leaf = outline(mesh(leafGeo, i % 2 ? bodyM : accM, V(0, 0, 0.55), V(1, T ? 2.3 : 1.7, 0.55), [0.95, 0, 0], lg));
        mesh(GEO.cone, darkM, V(0, 1.02, 0), V(0.06, 0.12, 0.06), null, leaf, false);
      }
      if (T) { mesh(GEO.cyl, M([120, 150, 90]), V(0, 3.4, 0), V(0.12, 4.8, 0.12), null, body); S(body, glowM, V(0, 6.0, 0), V(0.5, 0.8, 0.5), null, false); }
      eyes(body, V(0, 1.12, 0.62), 0.25, T ? 0.13 : 0.18);
      if (!T) smile(body, V(0, 0.82, 0.7), 0.09);
      break;
    }
    case "Armadillo": {
      S(body, bodyM, V(0, 1.0, 0), T ? V(1.0, 0.86, 1.45) : V(0.96, 0.86, 1.16));
      for (let k = -2; k <= 2; k++) { mesh(GEO.torus, darkM, V(0, 1.0, k * (T ? 0.36 : 0.3)), V(0.98, 0.86, 1), null, body, false); mesh(GEO.torus, glowM, V(0, 1.0, k * (T ? 0.36 : 0.3) + 0.12), V(0.96, 0.84, 0.6), null, body, false); }
      const head = new THREE.Group(); head.position.set(0, 0.86, T ? 1.46 : 1.16); body.add(head);
      S(head, bellyM, V(0, 0, 0), V(0.44, 0.4, 0.56));
      S(head, bellyM, V(0, -0.06, 0.5), V(0.18, 0.16, 0.4));
      for (const s of [-1, 1]) { const e = S(head, bodyM, V(s * 0.26, 0.42, -0.1), V(0.12, 0.26, 0.08)); parts.ears.push(e); }
      if (T) mesh(GEO.cone, M([60, 52, 54]), V(0, 0.46, 0.22), V(0.16, 0.6, 0.16), [0.5, 0, 0], head);
      eyes(head, V(0, 0.15, 0.36), 0.19, 0.12);
      legs(4, 0.48, 0.55, [0.55, -0.55], 0.15, 0.3, accM);
      break;
    }
    case "Cicada": {
      S(body, bodyM, V(0, 1.0, -0.2), V(0.62, 0.6, 1.2));
      for (let k = 0; k < 3; k++) mesh(GEO.torus, accM, V(0, 1.0, -0.62 - k * 0.3), V(0.58 - k * 0.08, 0.56 - k * 0.08, 1), null, body, false);
      const head = new THREE.Group(); head.position.set(0, 1.18, 0.95); body.add(head);
      S(head, bodyM, V(0, 0, 0), V(0.62, 0.5, 0.5));
      eyes(head, V(0, 0.12, 0.3), 0.42, T ? 0.2 : 0.3);
      const wingM = new THREE.MeshPhysicalMaterial({ map: wingTex, transparent: true, side: THREE.DoubleSide, roughness: 0.1, depthWrite: false, color: T ? 0xffd9a0 : 0xffffff });
      for (const s of [-1, 1]) { const w = new THREE.Mesh(new THREE.PlaneGeometry(T ? 1.1 : 0.8, T ? 2.6 : 1.9), wingM); w.position.set(s * 0.5, 1.55, -0.6); w.rotation.set(-Math.PI / 2 + 0.3, 0, s * 0.35); body.add(w); parts.gills.push(w); }
      legs(6, 0.55, 0.45, [0.4, 0, -0.4], 0.05, 0.4, accM);
      break;
    }
    case "Jar": {
      const pot = new THREE.LatheGeometry([0.5, 0.95, 1.15, 1.1, 0.8, 0.55, 0.6].map((r, k) => new THREE.Vector2(r, k * 0.38)), 32);
      outline(mesh(pot, bodyM, V(0, 0.45, 0), T ? V(1.3, 1.3, 1.3) : 1, null, body), 1.04);
      mesh(new THREE.CylinderGeometry(1.08, 1.08, 0.3, 32, 1, true), M(0xffffff, { map: grecaTex("#fff4de", "#a8502e"), side: THREE.DoubleSide }), V(0, T ? 1.6 : 1.27, 0), T ? V(1.3, 1, 1.3) : null, null, body, false);
      outline(mesh(GEO.torus, bodyM, V(1.05, 1.5, 0), V(0.45, 0.45, 2.5), [0, Math.PI / 2, 0], body));
      mesh(GEO.cyl, accM, V(0, T ? 3.25 : 2.5, 0), V(0.75, 0.15, 0.75), null, body);
      S(body, accM, V(0, T ? 3.4 : 2.66, 0), 0.18);
      eyes(body, V(0, T ? 1.95 : 1.52, T ? 1.35 : 1.06), 0.3, T ? 0.14 : 0.18);
      if (!T) smile(body, V(0, 1.2, 1.12), 0.1);
      for (const s of [-1, 1]) S(body, M([120, 110, 100]), V(s * 0.45, 0.3, 0), 0.32);
      if (T) for (const s of [-1, 1]) { mesh(GEO.cyl, bodyM, V(s * 1.6, 1.6, 0), V(0.28, 1.4, 0.28), [0, 0, s * 0.5], body); S(body, M([120, 110, 100]), V(s * 1.95, 0.95, 0), 0.45); }
      break;
    }
    case "Beetle": {
      S(body, bellyM, V(0, 0.85, 0), V(0.9, 0.7, 1.15));
      const shell = M(pal.body, { physical: true, rough: 0.25, clearcoat: 1 });
      for (const s of [-1, 1]) S(body, shell, V(s * 0.42, 1.06, -0.05), V(0.56, 0.56, 1.16), [0, 0, s * (T ? 0.35 : 0.1)]);
      const head = new THREE.Group(); head.position.set(0, 0.95, 1.05); body.add(head);
      S(head, accM, V(0, 0, 0), V(0.48, 0.42, 0.42));
      mesh(GEO.cone, accM, V(0, 0.45, 0.25), V(0.14, T ? 1.2 : 0.6, 0.14), [0.45, 0, 0], head);
      if (T) mesh(GEO.cone, accM, V(0, 0.05, 0.55), V(0.1, 0.7, 0.1), [1.2, 0, 0], head);
      eyes(head, V(0, 0.1, 0.32), 0.2, 0.14);
      for (const s of [-1, 1]) { const a = mesh(GEO.cyl, accM, V(s * 0.2, 0.55, 0.1), V(0.03, 0.6, 0.03), [0.4, 0, s * 0.4], head); S(a, glowM, V(0, 0.55, 0), V(4, 0.25, 2), null, false); }
      legs(6, 0.5, 0.6, [0.4, 0, -0.4], 0.05, 0.35, accM);
      break;
    }
    default: S(body, bodyM, V(0, 1, 0), 1); eyes(body, V(0, 1.2, 0.85), 0.3, 0.2);
  }
  root.scale.setScalar(T ? vis.talladoScale : vis.broteScale);
  root.traverse((o) => { if (o.isMesh && o.material !== OUTLINE_MAT) o.castShadow = true; });
  root.userData = { speciesId, form, parts, mats, body, rim, phase: Math.random() * 10, opaco: 0, baseColors: mats.map((m) => m.color.clone()), baseEmissive: mats.map((m) => m.emissive.clone()), baseEI: mats.map((m) => m.emissiveIntensity) };
  setOpaco(root, opaco ? 1 : 0);
  return root;
}
const GREY = new THREE.Color(0x8a8a92);
function setOpaco(c, amount) {
  const u = c.userData; u.opaco = amount;
  u.mats.forEach((m, i) => { m.color.copy(u.baseColors[i]).lerp(GREY, amount * 0.85); m.emissive.copy(u.baseEmissive[i]).multiplyScalar(1 - amount * 0.92); });
  u.rim.strength.value = (u.rim.base ?? 0.42) * (1 - amount * 0.8);
  u.rim.color.value.setHex(amount > 0.5 ? 0xb8b8c8 : 0xffe2b0);
}
function animateCreature(c, t, dt, moving) {
  const u = c.userData, p = u.parts, ph = t * (moving ? 9 : 2.2) + u.phase;
  u.body.position.y = moving ? Math.abs(Math.sin(ph)) * 0.35 : Math.sin(ph) * 0.06;
  u.body.scale.y = 1 + (moving ? 0 : Math.sin(ph) * 0.03);
  u.body.scale.x = u.body.scale.z = 1 - (moving ? 0 : Math.sin(ph) * 0.012);
  p.tail.forEach((g) => { g.rotation.y = Math.sin(t * (moving ? 6 : 2.4) + u.phase) * 0.35; g.rotation.x = Math.sin(t * 1.7 + u.phase) * 0.08; });
  p.gills.forEach((g, i) => { g.rotation.y = Math.sin(t * 2.5 + i) * 0.22; });
  p.legs.forEach((l, i) => { l.rotation.x = moving ? Math.sin(ph + (i % 2) * Math.PI) * 0.6 : 0; });
  p.spin.forEach((s) => { s.obj.rotation[s.axis] += dt * s.speed; });
  // Parpadeo y orejas que se mueven
  const blink = ((t + u.phase) % 3.7) < 0.13;
  p.eyes.forEach((e) => { e.scale.y = lerp(e.scale.y, blink ? 0.08 : 1, 0.6); });
  p.ears.forEach((e, i) => { e.rotation.x = Math.max(0, Math.sin(t * 1.3 + u.phase + i)) ** 8 * 0.4; });
  if (u.react > 0) { u.react = Math.max(0, u.react - dt); const k = u.react / 0.9; u.body.position.y += Math.sin(k * Math.PI) * 1.6; u.body.rotation.y = (1 - k) * Math.PI * 2 * (u.reactSpin || 0); }
}

// =====================================================================
// Efectos visuales: chispas, salpicaduras, hojas, rocas, rayos, anillos
// =====================================================================
const heartTex = canvasTex(64, 64, (g) => { g.fillStyle = "#ff7b9c"; g.beginPath(); g.moveTo(32, 56); g.bezierCurveTo(4, 36, 6, 10, 22, 10); g.bezierCurveTo(28, 10, 32, 16, 32, 20); g.bezierCurveTo(32, 16, 36, 10, 42, 10); g.bezierCurveTo(58, 10, 60, 36, 32, 56); g.fill(); });
const vfx = (() => {
  const live = [];
  const MAX = isTouch ? 220 : 420;
  function spawn(pos, o) {
    if (live.length >= MAX) return;
    const m = new THREE.SpriteMaterial({ map: o.map || glowTex, color: o.color, transparent: true, depthWrite: false, blending: o.normal ? THREE.NormalBlending : THREE.AdditiveBlending });
    const s = new THREE.Sprite(m); s.position.copy(pos); s.scale.setScalar(o.size); scene.add(s);
    live.push({ obj: s, vel: o.vel.clone(), life: o.life, max: o.life, grav: o.grav ?? 0, size: o.size, grow: o.grow ?? 0, drag: o.drag ?? 0.985, spin: o.spin ?? 0 });
  }
  const rnd = () => Math.random() - 0.5;
  function burst(pos, color, n, speed, o = {}) {
    for (let i = 0; i < n; i++) {
      const d = V(rnd(), (o.up ?? 0.4) + Math.random() * (o.upRange ?? 0.6), rnd()).normalize().multiplyScalar(speed * (0.35 + Math.random() * 0.8));
      spawn(pos.clone().add(V(rnd() * (o.spread ?? 1), rnd() * (o.spread ?? 1), rnd() * (o.spread ?? 1))), { color, vel: d, life: (o.life ?? 0.8) * (0.6 + Math.random() * 0.6), size: (o.size ?? 0.8) * (0.6 + Math.random() * 0.8), grav: o.grav ?? 0, grow: o.grow ?? 0, map: o.map, normal: o.normal });
    }
  }
  function ring(pos, color, radius = 6, life = 0.6) {
    const m = mesh(GEO.torus, new THREE.MeshBasicMaterial({ color, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false }), pos.clone(), 0.5, [Math.PI / 2, 0, 0], scene, false);
    live.push({ obj: m, ring: radius, life, max: life });
  }
  function chunks(pos, color, n) {
    for (let i = 0; i < n; i++) {
      const m = mesh(GEO.dodeca, mat(color, { flat: true, unique: true }), pos.clone().add(V(rnd(), 0.5, rnd())), 0.25 + Math.random() * 0.3, [Math.random(), Math.random(), 0], scene, false);
      live.push({ obj: m, vel: V(rnd() * 8, 6 + Math.random() * 5, rnd() * 8), life: 1.1, max: 1.1, grav: 22, size: m.scale.x, mesh: true, spin: 6 });
    }
  }
  function bolt(from, to, color) {
    const pts = [];
    for (let i = 0; i <= 10; i++) { const p = from.clone().lerp(to, i / 10); if (i > 0 && i < 10) p.add(V(rnd() * 1.6, rnd() * 1.6, rnd() * 1.6)); pts.push(p); }
    const line = new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), new THREE.LineBasicMaterial({ color, transparent: true }));
    scene.add(line); live.push({ obj: line, life: 0.25, max: 0.25, line: true });
  }
  const EL = {
    Fuego: (p) => { burst(p, 0xff7a2a, 26, 7, { up: 0.8, grav: -6, life: 0.9, size: 1.1 }); burst(p, 0xffd26a, 14, 5, { up: 1, grav: -8, life: 0.7, size: 0.6 }); },
    Agua: (p) => { burst(p, 0x5ad0ff, 30, 10, { up: 0.6, grav: 18, life: 0.8, size: 0.7 }); ring(p, 0x7fe3ff, 5); },
    Tierra: (p) => { chunks(p, 0x9b7a52, 8); burst(p, 0xc9a26a, 16, 6, { up: 0.3, grav: 6, life: 0.9, size: 1.4, normal: true }); },
    Flora: (p) => { burst(p, 0x7bd66a, 22, 6, { up: 0.5, grav: 2, life: 1.2, size: 0.8 }); burst(p, 0xffe27a, 8, 4, { life: 0.8, size: 0.5 }); },
    Rayo: (p) => { bolt(p.clone().add(V(0, 12, 0)), p, 0xfff27a); burst(p, 0xffef6a, 24, 11, { up: 0.2, life: 0.4, size: 0.7 }); ring(p, 0xfff2a0, 4, 0.35); },
  };
  return {
    burst, ring, chunks, bolt,
    element(el, p) { (EL[el] || ((q) => burst(q, 0xffffff, 18, 7)))(p); },
    hearts(p) { burst(p, 0xffffff, 6, 3, { up: 1.5, grav: -2, life: 1.3, size: 0.9, map: heartTex, normal: true }); },
    coins(p) { burst(p, 0xffd35c, 30, 9, { up: 1.2, grav: 14, life: 1.0, size: 0.7 }); ring(p, 0xffd35c, 5); },
    sparkle(p, color = 0xffe08a) { burst(p, color, 28, 7, { up: 0.6, life: 1.0, size: 0.8 }); ring(p, color, 6); },
    projectile(from, to, color, dur = 0.45) {
      return new Promise((res) => {
        const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTex, color, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
        s.scale.setScalar(2.2); scene.add(s);
        const t0 = performance.now();
        const step = () => {
          const k = Math.min(1, (performance.now() - t0) / (dur * 1000));
          s.position.copy(from).lerp(to, k).add(V(0, Math.sin(k * Math.PI) * 3, 0));
          spawn(s.position, { color, vel: V(rnd(), rnd(), rnd()), life: 0.35, size: 0.9 });
          if (k < 1) requestAnimationFrame(step); else { scene.remove(s); s.material.dispose(); res(); }
        };
        step();
      });
    },
    update(dt) {
      for (let i = live.length - 1; i >= 0; i--) {
        const p = live[i]; p.life -= dt;
        const k = Math.max(0, p.life / p.max);
        if (p.ring) { p.obj.scale.setScalar(0.5 + (1 - k) * p.ring); p.obj.material.opacity = k; }
        else if (p.line) p.obj.material.opacity = k;
        else {
          p.vel.y -= p.grav * dt; p.vel.multiplyScalar(p.drag ?? 0.985); p.obj.position.addScaledVector(p.vel, dt);
          if (p.mesh) { p.obj.rotation.x += dt * p.spin; if (p.obj.position.y < 0.2) { p.obj.position.y = 0.2; p.vel.set(0, 0, 0); } }
          else { p.obj.material.opacity = Math.min(1, k * 1.6); p.obj.scale.setScalar(p.size * (1 + p.grow * (1 - k))); }
        }
        if (p.life <= 0) { scene.remove(p.obj); p.obj.material?.dispose?.(); if (p.line) p.obj.geometry.dispose(); live.splice(i, 1); }
      }
    },
  };
})();

// =====================================================================
// Avatar del jugador (proporciones Roblox, blockout)
// =====================================================================
const player = new THREE.Group();
const avatar = new THREE.Group();
player.add(avatar);
const avParts = {};
{
  const skin = mat(0xe8b98d), shirt = mat(0xc4553a), pants = mat(0x2d2a3a), sash = mat(0xf2d27a);
  avParts.torso = mesh(GEO.rbox, shirt, V(0, 3.0, 0), V(2, 2, 1), null, avatar);
  mesh(GEO.box, sash, V(0, 2.3, 0.02), V(2.05, 0.35, 1.05), null, avatar);
  avParts.head = mesh(GEO.rbox, skin, V(0, 4.6, 0), V(1.25, 1.25, 1.25), null, avatar);
  for (const s of [-1, 1]) mesh(new THREE.CapsuleGeometry(0.07, 0.12, 4, 8), mat(0x221814), V(s * 0.25, 4.72, 0.64), null, null, avatar, false);
  mesh(new THREE.TorusGeometry(0.16, 0.035, 6, 16, Math.PI * 0.8), mat(0x221814), V(0, 4.42, 0.64), null, [0, 0, Math.PI * 1.1], avatar, false);
  mesh(GEO.rbox, mat(0x5a3a26), V(0, 5.3, -0.05), V(1.38, 0.34, 1.38), null, avatar);
  for (const s of [-1, 1]) {
    const arm = new THREE.Group(); arm.position.set(s * 1.5, 3.9, 0); avatar.add(arm); mesh(GEO.rbox, skin, V(0, -0.9, 0), V(0.95, 2, 0.95), null, arm); avParts[s < 0 ? "armL" : "armR"] = arm;
    const leg = new THREE.Group(); leg.position.set(s * 0.5, 2.0, 0); avatar.add(leg); mesh(GEO.rbox, pants, V(0, -1, 0), V(0.95, 2, 0.95), null, leg); avParts[s < 0 ? "legL" : "legR"] = leg;
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
  ...WORLD_ENCOUNTERS.map((encId) => ({ id: encId, pos: encounterSpots[encId].pos, radius: W.Encounters[CFG.Encounters.ById[encId].worldMarker].radius, obj: CFG.Encounters.ById[encId].name, act: "Restaurar al Opaco", enabled: () => encounterAvailable(encId), run: () => startBattle(encId) })),
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
  for (const encId of WORLD_ENCOUNTERS) {
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
  const at = companionModel.position.clone().add(V(0, 2.5, 0));
  if (kind === "level") vfx.sparkle(at, 0xffd35c); else vfx.hearts(at);
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
  const d = Math.max(size.x, size.y, size.z) * 1.4;
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
  const next = WORLD_ENCOUNTERS.find((id) => encounterAvailable(id) && !P.cleared[id]);
  if (next) return `Restaura a «${CFG.Encounters.ById[next].name}» en la Linde de las Chinampas.`;
  return Leveling.nextObjective(pet).text + ". Alimenta, juega y recoge Monedas.";
}
function objectiveTarget() {
  const s = P.step;
  if (s === "ChooseEgg") return eggs.EggBarro.base;
  if (s === "MeetHome" || s === "PlaceInHabitat") return lotC;
  if (s === "FirstBattle") return encounterSpots.valle_r1_e1.pos;
  if (P.completed) { const next = WORLD_ENCOUNTERS.find((id) => encounterAvailable(id) && !P.cleared[id]); return next ? encounterSpots[next].pos : null; }
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
  if (c > 0) { toast("🪙", `+${fmt(c)} Monedas`); floater(collectorPos.clone().add(V(0, 6, 0)), `+${fmt(c)}`, "crit"); vfx.coins(collectorPos.clone().add(V(0, 4.5, 0))); }
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
      const reset = m.querySelector("#reset");
      reset.addEventListener("click", () => {
        if (reset.dataset.armed) { try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* sin almacenamiento */ } P = newProfile(); location.reload(); return; }
        reset.dataset.armed = "1"; reset.textContent = "¿Seguro? Toca otra vez";
      });
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
  const burstAt = e.group.position.clone();
  vfx.ring(burstAt, 0xffd27a, 9, 0.8);
  vfx.burst(burstAt, col(e.egg.pulseColor).getHex(), 36, 10, { life: 1.1, size: 1.1 });
  vfx.burst(burstAt, 0xc98a3a, 26, 7, { up: 0.8, grav: 12, life: 1.4, size: 0.7, normal: true });
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
  await new Promise((res) => { const step = () => { const t = (performance.now() - t0) / 1000; m.rotation.y += 0.05 + t * 0.12; m.position.y = Math.sin(Math.min(t, 2) * Math.PI / 2) * 3; m.userData.mats.forEach((mm) => mm.emissive.setRGB(t * 0.5, t * 0.35, t * 0.1)); const a = t * 9; vfx.burst(base.clone().add(V(Math.cos(a) * 3, 0.5 + t * 2.4, Math.sin(a) * 3)), 0xffc860, 2, 1.5, { life: 0.9, size: 0.8 }); if (t < 2.4) requestAnimationFrame(step); else res(); }; step(); });
  const r = Actions.evolve(petId);
  if (r.ok) { vfx.ring(base.clone().add(V(0, 2, 0)), 0xffe08a, 12, 0.9); vfx.burst(base.clone().add(V(0, 3, 0)), 0xffd060, 60, 12, { life: 1.3, size: 1.2 }); }
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
let lastMoveElement = null;
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
    if (e.t === "Move") {
      const mv = ability(e.move), from = modelOf(e.actor), to = modelOf(e.actor === "S1C1" ? "S2C1" : "S1C1");
      cap = `${nameOf(e.actor)} usa <b>${mv.name}</b>`; renderBattle(cap);
      const ec = mv.element ? col(CFG.Elements.ById[mv.element].color).getHex() : 0xffffff;
      if (mv.power > 0 && mv.kind !== "Basic") { vfx.burst(from.position.clone().add(V(0, 2, 0)), ec, 16, 4, { life: 0.6 }); await vfx.projectile(from.position.clone().add(V(0, 2.2, 0)), to.position.clone().add(V(0, 1.8, 0)), ec); }
      else if (mv.power > 0) await lunge(from, to.position);
      else { vfx.sparkle(from.position.clone().add(V(0, 2, 0)), ec); await sleep(450); }
      lastMoveElement = mv.element;
      continue;
    }
    if (e.t === "Damage") { const m = modelOf(e.target); vfx.element(e.move === "ConfusionSelfHit" ? null : lastMoveElement, m.position.clone().add(V(0, 1.8, 0))); floater(m.position.clone().add(V(0, 4, 0)), `-${e.amount}`, e.crit ? "crit" : e.eff === "Strong" ? "strong" : e.eff === "Weak" ? "weak" : ""); hitShake(m); cap = e.crit ? "¡Golpe crítico!" : e.eff === "Strong" ? "¡Es muy eficaz!" : e.eff === "Weak" ? "No es muy eficaz…" : null; }
    else if (e.t === "Heal") { floater(modelOf(e.target).position.clone().add(V(0, 4, 0)), `+${e.amount}`, "heal"); vfx.burst(modelOf(e.target).position.clone().add(V(0, 1, 0)), 0x8ff0b4, 18, 3, { up: 1.5, grav: -3, life: 1.1 }); cap = `${nameOf(e.target)} recupera vida`; }
    else if (e.t === "Status") cap = `${nameOf(e.target)}: ${STATUS_TXT[e.status] || e.status}`;
    else if (e.t === "StatusTick") { floater(modelOf(e.target).position.clone().add(V(0, 4, 0)), `-${e.amount}`, ""); cap = `${nameOf(e.target)} sufre quemadura`; }
    else if (e.t === "Mod") cap = `${STAT_TXT[e.stat] || e.stat} de ${nameOf(e.target)} ${e.amount > 0 ? "sube" : "baja"}`;
    else if (e.t === "Miss") cap = `${nameOf(e.actor)} falla`;
    else if (e.t === "Skip") cap = `${nameOf(e.actor)} no puede actuar (${STATUS_TXT[e.status]})`;
    else if (e.t === "Block") cap = `¡${nameOf(e.target)} bloquea el golpe!`;
    else if (e.t === "Shield") cap = `${nameOf(e.target)} levanta un escudo`;
    else if (e.t === "Savia" && e.delta < 0) cap = `${nameOf(e.target)} pierde Savia`;
    else if (e.t === "Faint") { cap = e.target.startsWith("S2") ? "¡La niebla gris se debilita!" : `${nameOf(e.target)} está cansado`; const m = modelOf(e.target); m.rotation.z = 0.4; }
    else if (e.t === "Restored") { cap = "✨ ¡El monstruo recupera su color!"; const m = battle.foe; m.rotation.z = 0; vfx.ring(m.position.clone().add(V(0, 1.5, 0)), 0xffffff, 10, 1.0); for (const c of [0xe84a6e, 0xfaba32, 0x40aad6, 0x68be60, 0x9660de]) vfx.burst(m.position.clone().add(V(0, 2, 0)), c, 10, 8, { life: 1.4, size: 0.9 }); const t0 = performance.now(); await new Promise((res) => { const step = () => { const t = (performance.now() - t0) / 1200; setOpaco(m, 1 - Math.min(1, t)); m.position.y = Math.sin(Math.min(1, t) * Math.PI) * 2; if (t < 1) requestAnimationFrame(step); else res(); }; step(); }); }
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
  for (const encId of WORLD_ENCOUNTERS) { const c = encounterSpots[encId].creature; if (c) animateCreature(c, t, dt, false); encounterSpots[encId].fog.forEach((f, k) => { f.position.y = 1.8 + Math.sin(t * 0.6 + k) * 0.5; f.material.opacity = 0.24 + Math.sin(t * 0.7 + k) * 0.07; f.material.rotation = t * 0.05 * (k % 2 ? 1 : -1); }); }

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
  worldTick(t, dt);
  vfx.update(dt);

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
  if (usePost) composer.render(); else renderer.render(scene, camera);
  adaptQuality(dt);
  requestAnimationFrame(tick);
}
function lerpAngle(a, b, t) { let d = ((b - a + Math.PI) % (Math.PI * 2)) - Math.PI; if (d < -Math.PI) d += Math.PI * 2; return a + d * t; }
addEventListener("resize", () => { camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix(); renderer.setSize(innerWidth, innerHeight); composer.setSize(innerWidth, innerHeight); motesUniforms.uScale.value = innerHeight * 0.5; });
// Calidad adaptativa: si el dispositivo no mantiene ~30 fps, se apaga el postproceso y baja la resolución
let qualityFrames = 0, qualityTime = 0, qualityChecked = false;
function adaptQuality(dt) {
  if (qualityChecked || introActive) return;
  qualityFrames++; qualityTime += dt;
  if (qualityFrames < 120) return;
  qualityChecked = true;
  if (qualityTime / qualityFrames > 1 / 28) {
    usePost = false; pixelRatio = Math.min(pixelRatio, 1); renderer.setPixelRatio(pixelRatio); renderer.setSize(innerWidth, innerHeight);
  }
}

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
window.__nexora = { portrait, get P() { return P; }, Actions, startBattle, playTurn, openPetSheet, openSanctuary, openNexoMenu, refreshUI, endIntro, hatchSequence, player, get battle() { return battle; }, teleport: (x, z) => player.position.set(x, 0, z) };

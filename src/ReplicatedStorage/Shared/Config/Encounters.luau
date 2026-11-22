--!strict
-- Modo aventura · Acto I — Valle Copal (Biblia compacta p. 111–114; Genesis F2 §12).
--
-- DEFINIDO en la Biblia: niveles 1–15; guardiana Copalia; enemigos Opacos de Flora,
-- Tierra y Aire; regla del bioma "las raíces curan a los Opacos cercanos"; tres regiones
-- de cuatro etapas, un jefe y una etapa secreta por región (con sus 3 estrellas); tipos
-- de etapa (Combate 1–3 rivales, Élite con modificador, Rescate con 10 % de huevo,
-- Tesoro con cofre garantizado, Jefe en fases, Secreta con pistas Veladas); estrellas
-- (ganar / sin perder monstruos / reto de la etapa); recompensas (200–1 500 Monedas,
-- 150–800 XP, Cofre de Madera o Plata; Oro por región a 3 estrellas; Nexo por el jefe);
-- repetición al 25 % con tope de 10 al día; sin energía; Pesadilla tras el acto.
--
-- PROPUESTA de diseño (D-026): qué Opaco va en cada etapa, sus niveles, el reto de cada
-- etapa, las cifras dentro de los rangos de la Biblia, los nombres de las regiones y el
-- corte de raíces con golpes eficaces. Las tres primeras etapas son las de la Fase 1
-- (mismos ids, mismos premios).
--
-- `opponent` = primer rival (alias para el mundo y la interfaz de la Fase 1).

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type StageType = "Combate" | "Elite" | "Tesoro" | "Rescate" | "Jefe" | "Secreta"

export type OpponentDef = {
	speciesId: string?,
	byStarterElement: { [string]: string }?,
	guardianId: string?,
	form: "Brote" | "Tallado",
	level: number,
	modifier: string?,
	rooted: boolean?, -- regla del Valle: sus raíces lo curan al final de cada turno
}

export type ChallengeDef = {
	kind: "MaxTurns" | "CutRoots" | "UseElement" | "FirstTry" | "TeamMax",
	value: any,
	text: string,
}

export type EncounterDef = {
	id: string,
	name: string,
	act: string,
	region: number,
	stage: number, -- 1–12; 0 = jefe o secreta
	stageType: StageType,
	opponents: { OpponentDef },
	opponent: OpponentDef,
	ai: "Tutorial" | "Normal",
	requires: { string },
	requiresRegionStars: number?, -- secreta: 3 estrellas en todas las etapas de esa región
	baseReward: { Monedas: number, petXp: number },
	firstClearBonus: string?, -- id en Config/Rewards (Fase 1)
	firstClearChest: string?, -- tipo de cofre en Config/Chests
	firstClearDecor: string?, -- objeto de Config/Decor
	firstClearCodex: { string }?,
	lossPetXp: number,
	worldMarker: string?, -- marcador físico en la Linde (solo las etapas de la Fase 1)
	mapPos: { number }, -- posición en el mapa del acto (0–1, 0–1)
	challenge: ChallengeDef,
	recommendedLevel: number,
	teamSize: number, -- monstruos del jugador (1–3)
	riddle: { prompt: string, sealElement: string, options: { string } }?,
	rescue: { speciesId: string, eggChance: number }?,
	intro: string,
}

local function stage(def: { [string]: any }): EncounterDef
	def.opponent = def.opponents[1]
	def.requires = def.requires or {}
	def.teamSize = def.teamSize or 3
	return def :: any
end

local Encounters: { [string]: EncounterDef } = {}
local Order: { string } = {}
local function add(def: { [string]: any })
	local s = stage(def)
	Encounters[s.id] = s
	table.insert(Order, s.id)
end

-- ===================== Región 1 · La Linde de las Chinampas (nv 1–8) =====================
add({
	id = "valle_r1_e1",
	name = "El primer Opaco",
	act = "ActoI",
	region = 1,
	stage = 1,
	stageType = "Combate",
	opponents = {
		{ byStarterElement = { Fuego = "agavo", Agua = "comalu", Tierra = "zizi" }, form = "Brote", level = 1 },
	},
	ai = "Tutorial",
	baseReward = { Monedas = 200, petXp = 150 },
	firstClearBonus = "FirstOpacoRestored",
	firstClearCodex = { "opaco:ActoI" },
	lossPetXp = 40,
	worldMarker = "Encounter1",
	mapPos = { 0.07, 0.36 },
	challenge = { kind = "MaxTurns", value = 6, text = "Gana en 6 turnos o menos." },
	recommendedLevel = 2,
	teamSize = 1,
	intro = "Un Opaco tiembla entre los juncos. No es malo: perdió su color.",
})
add({
	id = "valle_r1_e2",
	name = "Opaco del Canal",
	act = "ActoI",
	region = 1,
	stage = 2,
	stageType = "Combate",
	opponents = { { speciesId = "barrock", form = "Brote", level = 4, rooted = true } },
	ai = "Normal",
	requires = { "valle_r1_e1" },
	baseReward = { Monedas = 350, petXp = 250 },
	firstClearBonus = "CanalCleared",
	firstClearChest = "Madera",
	lossPetXp = 60,
	worldMarker = "Encounter2",
	mapPos = { 0.13, 0.68 },
	challenge = { kind = "CutRoots", value = 1, text = "Corta sus raíces con un golpe eficaz." },
	recommendedLevel = 4,
	intro = "Las raíces del canal lo envuelven: lo curarán cada turno hasta que las cortes.",
})
add({
	id = "valle_r1_e3",
	name = "Élite: Opaco de la Vaina",
	act = "ActoI",
	region = 1,
	stage = 3,
	stageType = "Elite",
	opponents = { { speciesId = "vainas", form = "Brote", level = 7, modifier = "Coraza" } },
	ai = "Normal",
	requires = { "valle_r1_e2" },
	baseReward = { Monedas = 600, petXp = 400 },
	firstClearBonus = "EliteVainaCleared",
	firstClearChest = "Madera",
	lossPetXp = 80,
	worldMarker = "Encounter3",
	mapPos = { 0.20, 0.32 },
	challenge = { kind = "MaxTurns", value = 8, text = "Gana en 8 turnos o menos." },
	recommendedLevel = 7,
	intro = "Una Coraza de niebla endurece su caparazón (+15 % DEF).",
})
add({
	id = "valle_r1_e4",
	name = "Tesoro del embarcadero",
	act = "ActoI",
	region = 1,
	stage = 4,
	stageType = "Tesoro",
	opponents = {},
	ai = "Normal",
	requires = { "valle_r1_e3" },
	baseReward = { Monedas = 500, petXp = 300 },
	firstClearChest = "Plata",
	firstClearDecor = "FarolDeCopal",
	lossPetXp = 0,
	mapPos = { 0.27, 0.66 },
	challenge = { kind = "FirstTry", value = true, text = "Abre el cofre al primer intento." },
	recommendedLevel = 7,
	riddle = {
		prompt = "Raíces de Flora sellan el cofre. ¿Qué elemento las abre?",
		sealElement = "Flora",
		options = { "Agua", "Fuego", "Tierra" },
	},
	intro = "Un cofre atrapado por raíces. Piensa en los elementos.",
})
add({
	id = "valle_r1_secret",
	name = "Secreta: huellas de tinta",
	act = "ActoI",
	region = 1,
	stage = 0,
	stageType = "Secreta",
	opponents = {
		{ speciesId = "barrock", form = "Brote", level = 8, rooted = true },
		{ speciesId = "vainas", form = "Brote", level = 8 },
	},
	ai = "Normal",
	requires = { "valle_r1_e4" },
	requiresRegionStars = 1,
	baseReward = { Monedas = 1000, petXp = 600 },
	firstClearChest = "Plata",
	firstClearCodex = { "velada:cartografo" },
	lossPetXp = 80,
	mapPos = { 0.17, 0.10 },
	challenge = { kind = "MaxTurns", value = 7, text = "Gana en 7 turnos o menos." },
	recommendedLevel = 9,
	intro = "Alguien dejó huellas que se secan como tinta…",
})

-- ===================== Región 2 · El Mercado de Copal (nv 7–11) =====================
add({
	id = "valle_r2_e5",
	name = "Rescate: el colibrí sin brillo",
	act = "ActoI",
	region = 2,
	stage = 5,
	stageType = "Rescate",
	opponents = { { speciesId = "zunzi", form = "Brote", level = 7 } },
	ai = "Normal",
	requires = { "valle_r1_e4" },
	baseReward = { Monedas = 700, petXp = 400 },
	lossPetXp = 80,
	mapPos = { 0.36, 0.70 },
	challenge = { kind = "FirstTry", value = true, text = "Rescátalo sin derrotas (al primer intento)." },
	recommendedLevel = 8,
	rescue = { speciesId = "zunzi", eggChance = 0.10 },
	intro = "Un Zunzi silvestre quedó atrapado en la niebla. Libéralo.",
})
add({
	id = "valle_r2_e6",
	name = "Puestos apagados",
	act = "ActoI",
	region = 2,
	stage = 6,
	stageType = "Combate",
	opponents = {
		{ speciesId = "pabilo", form = "Brote", level = 8 },
		{ speciesId = "barrock", form = "Brote", level = 8, rooted = true },
	},
	ai = "Normal",
	requires = { "valle_r2_e5" },
	baseReward = { Monedas = 800, petXp = 450 },
	firstClearChest = "Madera",
	lossPetXp = 90,
	mapPos = { 0.42, 0.34 },
	challenge = { kind = "UseElement", value = "Aire", text = "Usa al menos un ataque de Aire." },
	recommendedLevel = 9,
	intro = "Dos Opacos rondan los puestos del mercado.",
})
add({
	id = "valle_r2_e7",
	name = "Élite: el farol furioso",
	act = "ActoI",
	region = 2,
	stage = 7,
	stageType = "Elite",
	opponents = { { speciesId = "lumbro", form = "Brote", level = 9, modifier = "Furia", rooted = true } },
	ai = "Normal",
	requires = { "valle_r2_e6" },
	baseReward = { Monedas = 950, petXp = 500 },
	firstClearChest = "Plata",
	lossPetXp = 100,
	mapPos = { 0.49, 0.68 },
	challenge = { kind = "TeamMax", value = 1, text = "Gana con un solo monstruo en el equipo." },
	recommendedLevel = 10,
	intro = "La Furia de la niebla aviva su ataque (+15 % ATQ).",
})
add({
	id = "valle_r2_e8",
	name = "La plaza del mercado",
	act = "ActoI",
	region = 2,
	stage = 8,
	stageType = "Combate",
	opponents = {
		{ speciesId = "vainas", form = "Brote", level = 9, rooted = true },
		{ speciesId = "zunzi", form = "Brote", level = 9 },
		{ speciesId = "pabilo", form = "Brote", level = 10 },
	},
	ai = "Normal",
	requires = { "valle_r2_e7" },
	baseReward = { Monedas = 1050, petXp = 550 },
	firstClearChest = "Madera",
	lossPetXp = 100,
	mapPos = { 0.55, 0.30 },
	challenge = { kind = "MaxTurns", value = 10, text = "Gana en 10 turnos o menos." },
	recommendedLevel = 10,
	intro = "Tres Opacos en la plaza. Uno tras otro.",
})
add({
	id = "valle_r2_secret",
	name = "Secreta: la pluma cosida",
	act = "ActoI",
	region = 2,
	stage = 0,
	stageType = "Secreta",
	opponents = {
		{ speciesId = "lumbro", form = "Brote", level = 11, rooted = true },
		{ speciesId = "dienton", form = "Brote", level = 11 },
		{ speciesId = "vainas", form = "Brote", level = 11 },
	},
	ai = "Normal",
	requires = { "valle_r2_e8" },
	requiresRegionStars = 2,
	baseReward = { Monedas = 1000, petXp = 600 },
	firstClearChest = "Plata",
	firstClearCodex = { "velada:bordadora" },
	lossPetXp = 100,
	mapPos = { 0.46, 0.10 },
	challenge = { kind = "UseElement", value = "Luz", text = "Usa al menos un ataque de Luz." },
	recommendedLevel = 12,
	intro = "Entre los puestos brilla un hilo como un rayo…",
})

-- ===================== Región 3 · Las Raíces del Gran Nexo (nv 11–15) =====================
add({
	id = "valle_r3_e9",
	name = "Tesoro de los faroles",
	act = "ActoI",
	region = 3,
	stage = 9,
	stageType = "Tesoro",
	opponents = {},
	ai = "Normal",
	requires = { "valle_r2_e8" },
	baseReward = { Monedas = 1100, petXp = 600 },
	firstClearChest = "Plata",
	firstClearDecor = "PiedraDeGreca",
	lossPetXp = 0,
	mapPos = { 0.64, 0.32 },
	challenge = { kind = "FirstTry", value = true, text = "Abre el cofre al primer intento." },
	recommendedLevel = 11,
	riddle = {
		prompt = "Faroles de Luz custodian el cofre. ¿Qué elemento los vence?",
		sealElement = "Luz",
		options = { "Metal", "Flora", "Agua" },
	},
	intro = "Faroles encendidos rodean un cofre. ¿Qué los apaga?",
})
add({
	id = "valle_r3_e10",
	name = "Rescate: el castor de la presa",
	act = "ActoI",
	region = 3,
	stage = 10,
	stageType = "Rescate",
	opponents = { { speciesId = "dienton", form = "Brote", level = 12, rooted = true } },
	ai = "Normal",
	requires = { "valle_r3_e9" },
	baseReward = { Monedas = 1200, petXp = 650 },
	lossPetXp = 110,
	mapPos = { 0.70, 0.68 },
	challenge = { kind = "CutRoots", value = 1, text = "Corta sus raíces con un golpe eficaz." },
	recommendedLevel = 12,
	rescue = { speciesId = "dienton", eggChance = 0.10 },
	intro = "Un Dientón quedó atrapado en su propia presa de raíces.",
})
add({
	id = "valle_r3_e11",
	name = "Élite: raíces dobles",
	act = "ActoI",
	region = 3,
	stage = 11,
	stageType = "Elite",
	opponents = {
		{ speciesId = "vainas", form = "Brote", level = 12, modifier = "Niebla", rooted = true },
		{ speciesId = "dienton", form = "Brote", level = 13, modifier = "Coraza" },
	},
	ai = "Normal",
	requires = { "valle_r3_e10" },
	baseReward = { Monedas = 1350, petXp = 700 },
	firstClearChest = "Plata",
	lossPetXp = 120,
	mapPos = { 0.77, 0.34 },
	challenge = { kind = "UseElement", value = "Fuego", text = "Usa al menos un ataque de Fuego." },
	recommendedLevel = 13,
	intro = "Niebla y Coraza: dos Opacos de Flora protegen las raíces.",
})
add({
	id = "valle_r3_e12",
	name = "Antesala de la Garza",
	act = "ActoI",
	region = 3,
	stage = 12,
	stageType = "Combate",
	opponents = {
		{ speciesId = "zunzi", form = "Brote", level = 13 },
		{ speciesId = "lumbro", form = "Brote", level = 14, rooted = true },
		{ speciesId = "barrock", form = "Brote", level = 14 },
	},
	ai = "Normal",
	requires = { "valle_r3_e11" },
	baseReward = { Monedas = 1500, petXp = 800 },
	firstClearChest = "Plata",
	lossPetXp = 120,
	mapPos = { 0.83, 0.66 },
	challenge = { kind = "MaxTurns", value = 9, text = "Gana en 9 turnos o menos." },
	recommendedLevel = 14,
	intro = "Los últimos Opacos antes de la Garza de Raíces.",
})
add({
	id = "valle_r3_secret",
	name = "Secreta: el engrane quieto",
	act = "ActoI",
	region = 3,
	stage = 0,
	stageType = "Secreta",
	opponents = {
		{ speciesId = "dienton", form = "Brote", level = 15, rooted = true },
		{ speciesId = "lumbro", form = "Brote", level = 15 },
		{ speciesId = "barrock", form = "Brote", level = 15, modifier = "Furia" },
	},
	ai = "Normal",
	requires = { "valle_r3_e12" },
	requiresRegionStars = 3,
	baseReward = { Monedas = 1000, petXp = 600 },
	firstClearChest = "Plata",
	firstClearCodex = { "velada:relojero" },
	lossPetXp = 120,
	mapPos = { 0.74, 0.10 },
	challenge = { kind = "TeamMax", value = 2, text = "Gana con dos monstruos o menos." },
	recommendedLevel = 15,
	intro = "Un engrane enorme detiene el tiempo por un instante…",
})

-- ===================== Jefe · Copalia, la Garza de Raíces =====================
add({
	id = "valle_boss",
	name = "Copalia, la Garza de Raíces",
	act = "ActoI",
	region = 3,
	stage = 0,
	stageType = "Jefe",
	opponents = { { speciesId = "copalia", guardianId = "copalia", form = "Tallado", level = 10 } },
	ai = "Normal",
	requires = { "valle_r3_e12" },
	baseReward = { Monedas = 1500, petXp = 800 },
	firstClearChest = "Nexo",
	firstClearDecor = "ArcoDeRaices",
	firstClearCodex = { "guardian:copalia" },
	lossPetXp = 150,
	mapPos = { 0.93, 0.48 },
	challenge = {
		kind = "CutRoots",
		value = 1,
		text = "Corta la Raíz Madre antes de que apague los faroles.",
	},
	recommendedLevel = 15,
	intro = "La guardiana del Valle, opacada. Sus raíces la curan; sus faroles te deslumbrarán.",
})

-- Los Opacos en el mundo físico (Fase 1) y en el mapa
local Modifiers = {
	Coraza = { name = "Coraza", statMultipliers = { DEF = 1.15 } },
	Furia = { name = "Furia", statMultipliers = { ATQ = 1.15 } },
	Niebla = { name = "Niebla", statMultipliers = { VEL = 1.10 } },
}

local Regions = {
	{
		index = 1,
		id = "region:ActoI:1",
		name = "La Linde de las Chinampas",
		subtitle = "Canales, juncos y niebla",
		levels = "1–8",
		stages = { "valle_r1_e1", "valle_r1_e2", "valle_r1_e3", "valle_r1_e4" },
		secret = "valle_r1_secret",
		palette = { sky = { 168, 206, 196 }, ground = { 98, 150, 110 }, accent = { 62, 150, 122 } },
		clearDecor = "MacetaDeCempasuchil",
		clearCodex = "region:ActoI:1",
	},
	{
		index = 2,
		id = "region:ActoI:2",
		name = "El Mercado de Copal",
		subtitle = "Faroles apagados y papel picado",
		levels = "7–12",
		stages = { "valle_r2_e5", "valle_r2_e6", "valle_r2_e7", "valle_r2_e8" },
		secret = "valle_r2_secret",
		palette = { sky = { 236, 196, 150 }, ground = { 176, 120, 80 }, accent = { 232, 168, 72 } },
		clearDecor = "EstandarteDePapelPicado",
		clearCodex = "region:ActoI:2",
	},
	{
		index = 3,
		id = "region:ActoI:3",
		name = "Las Raíces del Gran Nexo",
		subtitle = "Raíces gigantes y faroles en penumbra",
		levels = "11–15",
		stages = { "valle_r3_e9", "valle_r3_e10", "valle_r3_e11", "valle_r3_e12" },
		secret = "valle_r3_secret",
		palette = { sky = { 120, 110, 150 }, ground = { 86, 70, 60 }, accent = { 255, 196, 96 } },
		clearDecor = "BancaDeMadera",
		clearCodex = "region:ActoI:3",
	},
}

local Acts = {
	ActoI = {
		id = "ActoI",
		name = "Acto I · Valle Copal",
		levels = "1–15",
		guardian = "copalia",
		boss = "valle_boss",
		biomeRule = "Las raíces curan a los Opacos cercanos.",
		rootHeal = 0.05, -- % de VID por turno (PROPUESTA; Copalia usa su Raíz Madre, 6 %)
		regionStarsChest = "Oro", -- 3 estrellas en todas las etapas de una región
		allStars = { frame = "MarcoValleCopal", title = "Guardián del Valle" },
		completeUnlock = "ActoI_Completo",
		-- Pesadilla: preparada, NO activa hasta probar y equilibrar el modo Normal
		nightmare = { enabled = false, levelBonus = 10, rewardScale = 1.5, eliteModifiers = 2 },
	},
}

return Freeze.deep({
	ById = Encounters,
	Order = Order,
	Modifiers = Modifiers,
	Regions = Regions,
	Acts = Acts,
	Repeat = {
		RewardScale = 0.25, -- p. 111
		DailyRewardedRepeats = 10,
	},
})

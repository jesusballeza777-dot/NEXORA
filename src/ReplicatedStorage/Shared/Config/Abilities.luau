--!strict
-- Repertorio (Biblia v5.0 p. 36–38: 3 básicos + 2 especiales + 1 Golpe Nexo por
-- elemento; Firmas de especie en las fichas p. 49–81).
-- Los efectos se describen como datos; el motor (Domain/Battle) los interpreta.
-- Los efectos que solo aplican en 2v2 o con cambios de monstruo se conservan como
-- datos ("Area2v2", "NoSwitch") y el motor 1v1 los ignora de forma explícita.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type MoveKind = "Basic" | "Special" | "Signature" | "Nexo"

export type Effect = {
	type: string,
	target: ("Self" | "Target" | "Team")?,
	chance: number?,
	status: string?,
	turns: number?,
	stat: string?,
	amount: number?,
	percent: number?,
	statuses: { string }?,
	thornsStatus: string?,
	thornsChance: number?,
	filter: string?,
}

export type MoveDef = {
	id: string,
	name: string,
	element: string?, -- nil = Eco/sin elemento
	kind: MoveKind,
	power: number,
	hits: number?,
	priority: number?,
	useStat: string?, -- "ESE" para básicos que usan Esencia
	contact: boolean?,
	critBonus: number?,
	effects: { Effect },
	text: string,
}

local function eff(t: Effect): Effect
	return t
end

local Moves: { [string]: MoveDef } = {}

local function add(m: MoveDef)
	assert(Moves[m.id] == nil, "Movimiento duplicado: " .. m.id)
	Moves[m.id] = m
end

-- ===================== AGUA =====================
add({
	id = "Chorro",
	name = "Chorro",
	element = "Agua",
	kind = "Basic",
	power = 40,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "OlaCorta",
	name = "Ola Corta",
	element = "Agua",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Self", stat = "VEL", amount = 0.10, turns = 2 }) },
	text = "+10 % VEL propia 2 turnos.",
})
add({
	id = "BurbujaFria",
	name = "Burbuja Fría",
	element = "Agua",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Target", stat = "ATQ", amount = -0.10, turns = 2 }) },
	text = "−10 % ATQ del rival 2 turnos.",
})
add({
	id = "MareaLenta",
	name = "Marea Lenta",
	element = "Agua",
	kind = "Special",
	power = 65,
	effects = { eff({ type = "StatMod", target = "Target", stat = "VEL", amount = -0.20, turns = 2 }) },
	text = "−20 % VEL del rival 2 turnos.",
})
add({
	id = "Manantial",
	name = "Manantial",
	element = "Agua",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "Heal", target = "Self", percent = 0.30 }) },
	text = "Cura 30 % de VID (en 2v2 puede curar al aliado).",
})
add({
	id = "DiluvioDeCantaros",
	name = "Diluvio de Cántaros",
	element = "Agua",
	kind = "Nexo",
	power = 120,
	effects = { eff({ type = "Cleanse", target = "Team" }) },
	text = "Limpia los efectos negativos del equipo.",
})

-- ===================== FUEGO =====================
add({
	id = "Chispazo",
	name = "Chispazo",
	element = "Fuego",
	kind = "Basic",
	power = 40,
	effects = { eff({ type = "Status", target = "Target", status = "Burn", chance = 0.10, turns = 3 }) },
	text = "10 % de quemadura (−5 % VID por turno, 3 turnos).",
})
add({
	id = "ZarpaDeBrasa",
	name = "Zarpa de Brasa",
	element = "Fuego",
	kind = "Basic",
	power = 45,
	contact = true,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "HumoDeCopal",
	name = "Humo de Copal",
	element = "Fuego",
	kind = "Basic",
	power = 30,
	effects = { eff({ type = "StatMod", target = "Target", stat = "Precision", amount = -0.15, turns = 1 }) },
	text = "El rival pierde 15 % de precisión 1 turno.",
})
add({
	id = "ComalArdiente",
	name = "Comal Ardiente",
	element = "Fuego",
	kind = "Special",
	power = 70,
	effects = { eff({ type = "Status", target = "Target", status = "Burn", chance = 0.30, turns = 3 }) },
	text = "30 % de quemadura.",
})
add({
	id = "MuroDeAscuas",
	name = "Muro de Ascuas",
	element = "Fuego",
	kind = "Special",
	power = 0,
	effects = {
		eff({ type = "Shield", target = "Self", percent = 0.25, turns = 2, thornsStatus = "Burn", thornsChance = 1.0 }),
	},
	text = "Escudo del 25 % de VID 2 turnos; quema a quien lo golpee.",
})
add({
	id = "FogataDelTallador",
	name = "Fogata del Tallador",
	element = "Fuego",
	kind = "Nexo",
	power = 120,
	effects = { eff({ type = "Area2v2", percent = 0.75 }) },
	text = "En 2v2 golpea a ambos rivales al 75 %.",
})

-- ===================== AIRE =====================
add({
	id = "Rafaga",
	name = "Ráfaga",
	element = "Aire",
	kind = "Basic",
	power = 40,
	effects = { eff({ type = "TieBreakFirst" }) },
	text = "Actúa primero si empata en VEL.",
})
add({
	id = "PlumaCortante",
	name = "Pluma Cortante",
	element = "Aire",
	kind = "Basic",
	power = 40,
	critBonus = 0.10,
	effects = {},
	text = "+10 % de crítico.",
})
add({
	id = "Remolino",
	name = "Remolino",
	element = "Aire",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StealSavia", target = "Target", chance = 0.30, amount = 1 }) },
	text = "El rival pierde 1 de Savia (30 %).",
})
add({
	id = "CorrienteAscendente",
	name = "Corriente Ascendente",
	element = "Aire",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "StatMod", target = "Team", stat = "VEL", amount = 0.20, turns = 2 }) },
	text = "+20 % VEL al equipo 2 turnos.",
})
add({
	id = "Torbellino",
	name = "Torbellino",
	element = "Aire",
	kind = "Special",
	power = 70,
	effects = { eff({ type = "Area2v2", percent = 0.75 }) },
	text = "En 2v2 golpea a ambos rivales al 75 %.",
})
add({
	id = "VientoDeLosCuatroRumbos",
	name = "Viento de los Cuatro Rumbos",
	element = "Aire",
	kind = "Nexo",
	power = 115,
	priority = 99,
	effects = {},
	text = "Prioridad máxima: siempre actúa primero.",
})

-- ===================== TIERRA =====================
add({
	id = "Pisoton",
	name = "Pisotón",
	element = "Tierra",
	kind = "Basic",
	power = 45,
	contact = true,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "LanzaDeBarro",
	name = "Lanza de Barro",
	element = "Tierra",
	kind = "Basic",
	power = 40,
	effects = { eff({ type = "StatMod", target = "Target", stat = "DEF", amount = -0.10, turns = 2, chance = 0.20 }) },
	text = "20 % de −10 % DEF del rival.",
})
add({
	id = "ArenaEnLosOjos",
	name = "Arena en los Ojos",
	element = "Tierra",
	kind = "Basic",
	power = 30,
	effects = { eff({ type = "StatMod", target = "Target", stat = "Precision", amount = -0.15, turns = 1 }) },
	text = "−15 % precisión del rival 1 turno.",
})
add({
	id = "MurallaDeAdobe",
	name = "Muralla de Adobe",
	element = "Tierra",
	kind = "Special",
	power = 0,
	effects = {
		eff({ type = "Block", target = "Self" }),
		eff({ type = "StatMod", target = "Self", stat = "DEF", amount = 0.20, turns = 2 }),
	},
	text = "Bloquea el siguiente golpe y +20 % DEF 2 turnos.",
})
add({
	id = "Grieta",
	name = "Grieta",
	element = "Tierra",
	kind = "Special",
	power = 75,
	effects = { eff({ type = "Status", target = "Target", status = "Stun", chance = 0.15, turns = 1 }) },
	text = "15 % de aturdir 1 turno.",
})
add({
	id = "CorazonDeMontana",
	name = "Corazón de Montaña",
	element = "Tierra",
	kind = "Nexo",
	power = 125,
	effects = { eff({ type = "StatMod", target = "Team", stat = "DEF", amount = 0.30, turns = 2 }) },
	text = "+30 % DEF al equipo 2 turnos.",
})

-- ===================== METAL =====================
add({
	id = "GolpeDeYunque",
	name = "Golpe de Yunque",
	element = "Metal",
	kind = "Basic",
	power = 45,
	contact = true,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "RemacheRebote",
	name = "Remache Rebote",
	element = "Metal",
	kind = "Basic",
	power = 40,
	effects = { eff({ type = "StatMod", target = "Self", stat = "DEF", amount = 0.10, turns = 2 }) },
	text = "+10 % DEF propia 2 turnos.",
})
add({
	id = "Limadura",
	name = "Limadura",
	element = "Metal",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Target", stat = "DEF", amount = -0.10, turns = 2 }) },
	text = "−10 % DEF del rival 2 turnos.",
})
add({
	id = "EscudoRepujado",
	name = "Escudo Repujado",
	element = "Metal",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "Shield", target = "Self", percent = 0.30, turns = 2 }) },
	text = "Escudo del 30 % de VID 2 turnos.",
})
add({
	id = "CuchillaDeHojalata",
	name = "Cuchilla de Hojalata",
	element = "Metal",
	kind = "Special",
	power = 75,
	critBonus = 0.15,
	effects = {},
	text = "+15 % de crítico.",
})
add({
	id = "FraguaViva",
	name = "Fragua Viva",
	element = "Metal",
	kind = "Nexo",
	power = 120,
	effects = { eff({ type = "ShieldFromDamage", target = "Self", percent = 0.20, turns = 2 }) },
	text = "Gana un escudo igual al 20 % del daño causado.",
})

-- ===================== FLORA =====================
add({
	id = "LatigoDeEnredadera",
	name = "Látigo de Enredadera",
	element = "Flora",
	kind = "Basic",
	power = 40,
	contact = true,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "SemillaDrenante",
	name = "Semilla",
	element = "Flora",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "Drain", target = "Self", percent = 0.10 }) },
	text = "Drena 10 % del daño causado.",
})
add({
	id = "Polen",
	name = "Polen",
	element = "Flora",
	kind = "Basic",
	power = 30,
	effects = { eff({ type = "Status", target = "Target", status = "Sleep", chance = 0.20, turns = 1 }) },
	text = "20 % de adormecer 1 turno.",
})
add({
	id = "RaizProfunda",
	name = "Raíz Profunda",
	element = "Flora",
	kind = "Special",
	power = 0,
	effects = {
		eff({ type = "HealOverTime", target = "Self", percent = 0.08, turns = 3 }),
		eff({ type = "NoSwitch", target = "Self", turns = 3 }),
	},
	text = "Cura 8 % de VID por turno 3 turnos; no puede ser forzado a cambiar.",
})
add({
	id = "EspinasDeMaguey",
	name = "Espinas de Maguey",
	element = "Flora",
	kind = "Special",
	power = 70,
	effects = { eff({ type = "Reflect", target = "Self", percent = 0.15, turns = 2, filter = "All" }) },
	text = "Refleja 15 % del daño recibido 2 turnos.",
})
add({
	id = "FloracionDelValle",
	name = "Floración del Valle",
	element = "Flora",
	kind = "Nexo",
	power = 115,
	effects = { eff({ type = "Heal", target = "Team", percent = 0.25 }) },
	text = "Cura 25 % de VID al equipo.",
})

-- ===================== RAYO =====================
add({
	id = "Chispa",
	name = "Chispa",
	element = "Rayo",
	kind = "Basic",
	power = 40,
	effects = { eff({ type = "Status", target = "Target", status = "Paralysis", chance = 0.20, turns = 1 }) },
	text = "20 % de parálisis (pierde 1 turno).",
})
add({
	id = "Descarga",
	name = "Descarga",
	element = "Rayo",
	kind = "Basic",
	power = 45,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "Estatica",
	name = "Estática",
	element = "Rayo",
	kind = "Basic",
	power = 30,
	effects = { eff({ type = "StealSavia", target = "Target", chance = 0.30, amount = 1 }) },
	text = "30 % de robar 1 de Savia.",
})
add({
	id = "TormentaEncadenada",
	name = "Tormenta Encadenada",
	element = "Rayo",
	kind = "Special",
	power = 70,
	effects = { eff({ type = "Area2v2", percent = 0.50 }) },
	text = "En 2v2 salta al segundo rival al 50 %.",
})
add({
	id = "Sobrecarga",
	name = "Sobrecarga",
	element = "Rayo",
	kind = "Special",
	power = 0,
	effects = {
		eff({ type = "StatMod", target = "Self", stat = "ATQ", amount = 0.25, turns = 2 }),
		eff({ type = "StatMod", target = "Self", stat = "ESE", amount = 0.25, turns = 2 }),
		eff({ type = "SelfRecoil", target = "Self", percent = 0.10 }),
	},
	text = "+25 % ATQ y ESE 2 turnos; pierde 10 % de VID.",
})
add({
	id = "RelampagoFulgurita",
	name = "Relámpago Fulgurita",
	element = "Rayo",
	kind = "Nexo",
	power = 130,
	effects = { eff({ type = "IgnoreShields" }) },
	text = "Ignora escudos.",
})

-- ===================== ARTIFICIO =====================
add({
	id = "Engrane",
	name = "Engrane",
	element = "Artificio",
	kind = "Basic",
	power = 40,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "Resorte",
	name = "Resorte",
	element = "Artificio",
	kind = "Basic",
	power = 35,
	priority = 1,
	effects = {},
	text = "Prioridad +1.",
})
add({
	id = "ChispaDeTaller",
	name = "Chispa de Taller",
	element = "Artificio",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "NextSpecialFails", target = "Target", chance = 0.20 }) },
	text = "20 %: el siguiente especial del rival falla.",
})
add({
	id = "TrampaDeCuerda",
	name = "Trampa de Cuerda",
	element = "Artificio",
	kind = "Special",
	power = 50,
	effects = { eff({ type = "NoSwitch", target = "Target", turns = 2 }) },
	text = "El rival no puede cambiar 2 turnos.",
})
add({
	id = "AjusteFino",
	name = "Ajuste Fino",
	element = "Artificio",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "EmpowerNext", target = "Self", amount = 0.50 }) },
	text = "El siguiente ataque propio hace +50 %.",
})
add({
	id = "GranAutomata",
	name = "Gran Autómata",
	element = "Artificio",
	kind = "Nexo",
	power = 120,
	effects = { eff({ type = "CopyBuff", target = "Self" }) },
	text = "Copia la última mejora activa del rival.",
})

-- ===================== LUZ =====================
add({
	id = "Destello",
	name = "Destello",
	element = "Luz",
	kind = "Basic",
	power = 40,
	effects = {
		eff({ type = "StatMod", target = "Target", stat = "Precision", amount = -0.20, turns = 1, chance = 0.15 }),
	},
	text = "15 % de cegar (−20 % precisión 1 turno).",
})
add({
	id = "RayoDeAlba",
	name = "Rayo de Alba",
	element = "Luz",
	kind = "Basic",
	power = 40,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "Halo",
	name = "Halo",
	element = "Luz",
	kind = "Basic",
	power = 0,
	effects = { eff({ type = "Heal", target = "Self", percent = 0.10 }) },
	text = "Cura 10 % de VID.",
})
add({
	id = "Vitral",
	name = "Vitral",
	element = "Luz",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "Reflect", target = "Self", percent = 0.20, turns = 2, filter = "Special" }) },
	text = "Refleja 20 % de los especiales recibidos 2 turnos.",
})
add({
	id = "LanzaSolar",
	name = "Lanza Solar",
	element = "Luz",
	kind = "Special",
	power = 75,
	effects = {},
	text = "Golpe directo potente.",
})
add({
	id = "AmanecerDelNexo",
	name = "Amanecer del Nexo",
	element = "Luz",
	kind = "Nexo",
	power = 115,
	effects = {
		eff({ type = "Heal", target = "Team", percent = 0.40 }),
		eff({ type = "Cleanse", target = "Team" }),
	},
	text = "Cura 40 % al equipo y elimina estados.",
})

-- ===================== SOMBRA =====================
add({
	id = "ZarpaNocturna",
	name = "Zarpa Nocturna",
	element = "Sombra",
	kind = "Basic",
	power = 45,
	contact = true,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "Niebla",
	name = "Niebla",
	element = "Sombra",
	kind = "Basic",
	power = 30,
	effects = { eff({ type = "StatMod", target = "Self", stat = "Evasion", amount = 0.15, turns = 1 }) },
	text = "+15 % evasión 1 turno.",
})
add({
	id = "Susurro",
	name = "Susurro",
	element = "Sombra",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Target", stat = "ATQ", amount = -0.10, turns = 2 }) },
	text = "−10 % ATQ del rival 2 turnos.",
})
add({
	id = "VeloDeNoche",
	name = "Velo de Noche",
	element = "Sombra",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "Dodge", target = "Self" }) },
	text = "Esquiva el siguiente ataque.",
})
add({
	id = "Pesadilla",
	name = "Pesadilla",
	element = "Sombra",
	kind = "Special",
	power = 70,
	effects = { eff({ type = "BonusIfTargetStatus", statuses = { "Sleep", "Confuse" }, amount = 0.50 }) },
	text = "+50 % si el rival está dormido o confundido.",
})
add({
	id = "EclipseBreve",
	name = "Eclipse Breve",
	element = "Sombra",
	kind = "Nexo",
	power = 120,
	effects = { eff({ type = "NullifyBuffs", target = "Target" }) },
	text = "Anula las mejoras del rival.",
})

-- ===================== MENTE =====================
add({
	id = "PulsoMental",
	name = "Pulso Mental",
	element = "Mente",
	kind = "Basic",
	power = 40,
	useStat = "ESE",
	effects = {},
	text = "Usa ESE.",
})
add({
	id = "Distraccion",
	name = "Distracción",
	element = "Mente",
	kind = "Basic",
	power = 30,
	effects = { eff({ type = "StatMod", target = "Target", stat = "ESE", amount = -0.15, turns = 2 }) },
	text = "−15 % ESE del rival 2 turnos.",
})
add({
	id = "EcoDePensamiento",
	name = "Eco de Pensamiento",
	element = "Mente",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Self", stat = "ESE", amount = 0.10, turns = 2 }) },
	text = "+10 % ESE propia 2 turnos.",
})
add({
	id = "Calma",
	name = "Calma",
	element = "Mente",
	kind = "Special",
	power = 0,
	effects = {
		eff({ type = "Cleanse", target = "Self" }),
		eff({ type = "StatMod", target = "Self", stat = "ESE", amount = 0.20, turns = 2 }),
	},
	text = "Quita estados propios y +20 % ESE 2 turnos.",
})
add({
	id = "Laberinto",
	name = "Laberinto",
	element = "Mente",
	kind = "Special",
	power = 65,
	effects = { eff({ type = "Status", target = "Target", status = "Confuse", chance = 0.30, turns = 1 }) },
	text = "30 % de confundir 1 turno.",
})
add({
	id = "SuenoLucido",
	name = "Sueño Lúcido",
	element = "Mente",
	kind = "Nexo",
	power = 115,
	effects = { eff({ type = "Status", target = "Target", status = "Sleep", chance = 1.0, turns = 1 }) },
	text = "El rival duerme 1 turno (no afecta a Misterio).",
})

-- ===================== ASTRAL =====================
add({
	id = "PolvoDeEstrella",
	name = "Polvo de Estrella",
	element = "Astral",
	kind = "Basic",
	power = 40,
	effects = {},
	text = "Golpe directo.",
})
add({
	id = "Orbita",
	name = "Órbita",
	element = "Astral",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Self", stat = "Evasion", amount = 0.10, turns = 2 }) },
	text = "+10 % evasión 2 turnos.",
})
add({
	id = "Gravedad",
	name = "Gravedad",
	element = "Astral",
	kind = "Basic",
	power = 35,
	effects = { eff({ type = "StatMod", target = "Target", stat = "VEL", amount = -0.15, turns = 2 }) },
	text = "−15 % VEL del rival 2 turnos.",
})
add({
	id = "LluviaDeMeteoros",
	name = "Lluvia de Meteoros",
	element = "Astral",
	kind = "Special",
	power = 35,
	hits = 2,
	effects = {},
	text = "Dos impactos de 35.",
})
add({
	id = "Constelacion",
	name = "Constelación",
	element = "Astral",
	kind = "Special",
	power = 0,
	effects = { eff({ type = "StatMod", target = "Self", stat = "ESE", amount = 0.30, turns = 2 }) },
	text = "+30 % ESE 2 turnos.",
})
add({
	id = "SupernovaTallada",
	name = "Supernova Tallada",
	element = "Astral",
	kind = "Nexo",
	power = 125,
	effects = { eff({ type = "StatMod", target = "Self", stat = "DEF", amount = -0.20, turns = 1 }) },
	text = "Después queda con −20 % DEF 1 turno.",
})

-- ===================== FIRMAS (especies de la Fase 1) =====================
add({
	id = "LatigoDeCeniza",
	name = "Látigo de Ceniza",
	element = "Fuego",
	kind = "Signature",
	power = 65,
	contact = true,
	effects = {
		eff({ type = "BonusIfTargetStatus", statuses = { "Burn" }, amount = 0.20 }),
		eff({ type = "Status", target = "Target", status = "Burn", chance = 0.40, turns = 3 }),
	},
	text = "40 % de quemadura; si el rival ya arde, +20 % de daño.",
})
add({
	id = "CicatrizDorada",
	name = "Cicatriz Dorada",
	element = "Agua",
	kind = "Signature",
	power = 0,
	effects = {
		eff({ type = "Heal", target = "Self", percent = 0.25 }),
		eff({ type = "StatMod", target = "Self", stat = "DEF", amount = 0.15, turns = 2 }),
	},
	text = "Cura 25 % y gana +15 % DEF 2 turnos.",
})
add({
	id = "AstrolabioDePiedra",
	name = "Astrolabio de Piedra",
	element = "Tierra",
	kind = "Signature",
	power = 60,
	effects = {
		eff({ type = "StatMod", target = "Self", stat = "DEF", amount = 0.25, turns = 2 }),
		eff({ type = "StatMod", target = "Target", stat = "VEL", amount = -0.10, turns = 2 }),
	},
	text = "+25 % DEF propia y −10 % VEL del rival 2 turnos.",
})
add({
	id = "RodadaDeBrasa",
	name = "Rodada de Brasa",
	element = "Fuego",
	kind = "Signature",
	power = 70,
	contact = true,
	effects = { eff({ type = "StatMod", target = "Self", stat = "DEF", amount = 0.10, turns = 2 }) },
	text = "Después gana +10 % DEF 2 turnos.",
})
add({
	id = "VertidoDelCantaro",
	name = "Vertido del Cántaro",
	element = "Tierra",
	kind = "Signature",
	power = 0,
	effects = {
		eff({ type = "Heal", target = "Self", percent = 0.20 }),
		eff({ type = "CleanseOne", target = "Self" }),
	},
	text = "Cura 20 % al aliado o a sí mismo y quita 1 estado.",
})
add({
	id = "Quiote",
	name = "Quiote",
	element = "Flora",
	kind = "Signature",
	power = 70,
	contact = true,
	effects = { eff({ type = "BonusIfHitLastTurn", amount = 0.25 }) },
	text = "Si el rival lo golpeó el turno anterior, +25 %.",
})
add({
	id = "SonajaDeVainas",
	name = "Sonaja de Vainas",
	element = "Flora",
	kind = "Signature",
	power = 50,
	effects = { eff({ type = "Status", target = "Target", status = "Sleep", chance = 0.35, turns = 1 }) },
	text = "35 % de adormecer.",
})
add({
	id = "Tamborazo",
	name = "Tamborazo",
	element = "Rayo",
	kind = "Signature",
	power = 70,
	effects = { eff({ type = "StealSavia", target = "Target", chance = 0.25, amount = 1 }) },
	text = "25 % de robar 1 de Savia.",
})

-- Repertorio por elemento (orden = orden de la Biblia).
-- stylua: ignore start
local ByElement: { [string]: { basics: { string }, specials: { string }, nexo: string } } = {
	Agua = { basics = { "Chorro", "OlaCorta", "BurbujaFria" }, specials = { "MareaLenta", "Manantial" }, nexo = "DiluvioDeCantaros" },
	Fuego = { basics = { "Chispazo", "ZarpaDeBrasa", "HumoDeCopal" }, specials = { "ComalArdiente", "MuroDeAscuas" }, nexo = "FogataDelTallador" },
	Aire = { basics = { "Rafaga", "PlumaCortante", "Remolino" }, specials = { "CorrienteAscendente", "Torbellino" }, nexo = "VientoDeLosCuatroRumbos" },
	Tierra = { basics = { "Pisoton", "LanzaDeBarro", "ArenaEnLosOjos" }, specials = { "MurallaDeAdobe", "Grieta" }, nexo = "CorazonDeMontana" },
	Metal = { basics = { "GolpeDeYunque", "RemacheRebote", "Limadura" }, specials = { "EscudoRepujado", "CuchillaDeHojalata" }, nexo = "FraguaViva" },
	Flora = { basics = { "LatigoDeEnredadera", "SemillaDrenante", "Polen" }, specials = { "RaizProfunda", "EspinasDeMaguey" }, nexo = "FloracionDelValle" },
	Rayo = { basics = { "Chispa", "Descarga", "Estatica" }, specials = { "TormentaEncadenada", "Sobrecarga" }, nexo = "RelampagoFulgurita" },
	Artificio = { basics = { "Engrane", "Resorte", "ChispaDeTaller" }, specials = { "TrampaDeCuerda", "AjusteFino" }, nexo = "GranAutomata" },
	Luz = { basics = { "Destello", "RayoDeAlba", "Halo" }, specials = { "Vitral", "LanzaSolar" }, nexo = "AmanecerDelNexo" },
	Sombra = { basics = { "ZarpaNocturna", "Niebla", "Susurro" }, specials = { "VeloDeNoche", "Pesadilla" }, nexo = "EclipseBreve" },
	Mente = { basics = { "PulsoMental", "Distraccion", "EcoDePensamiento" }, specials = { "Calma", "Laberinto" }, nexo = "SuenoLucido" },
	Astral = { basics = { "PolvoDeEstrella", "Orbita", "Gravedad" }, specials = { "LluviaDeMeteoros", "Constelacion" }, nexo = "SupernovaTallada" },
}
-- stylua: ignore end

-- Efectos que el motor 1v1 de la Fase 1 ignora de forma deliberada.
local IgnoredIn1v1 = { Area2v2 = true, NoSwitch = true }

return Freeze.deep({
	ById = Moves,
	ByElement = ByElement,
	IgnoredIn1v1 = IgnoredIn1v1,
})

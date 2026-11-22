--!strict
-- Cofres (Biblia compacta p. 8, 13 y 42; Genesis F2 §9).
--
-- La Biblia define seis cofres: Madera, Plata, Oro, Épico, Diamante y Nexo. Sus tablas de
-- probabilidad completas están en la Biblia v5.0, que NO está en el repositorio. La
-- compacta solo conserva: "Madera: Huevo Común 30 % y Raro 6 %; Oro: Huevo Épico 15 %;
-- Diamante redistribuido; Platino excluido" (HECHO). Con eso las tablas suman 36 % y 15 %:
-- no se pueden activar sin inventar porcentajes (prohibido).
--
-- Decisión para la beta (D-024, PROPUESTA pendiente de aprobación):
-- * Los cofres activos usan CONTENIDO FIJO Y VISIBLE ("Lo que ves es lo que te llevas",
--   regla del Gabinete p. 13). Sin azar: el huevo de un cofre es la siguiente especie del
--   grupo que el jugador aún no tiene (o, si ya las tiene todas, la que menos tiene).
-- * El modo aleatorio existe y se valida (ChestRules.validateTable), pero un cofre solo
--   puede usarlo si su tabla está completa, suma exactamente 100 % y está aprobada.
-- * Todos los cofres activos se ganan jugando (historia, etapas, encargos, logros).
--   Ninguno se vende por Robux ni Gemas.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type OddsRow = { prize: string, percent: number?, status: string } -- status: "Biblia" | "Pendiente"
export type ChestDef = {
	id: string,
	name: string,
	tier: number,
	color: { number },
	glow: { number },
	activeInBeta: boolean,
	mode: "Fixed" | "Random",
	approved: boolean, -- tabla aleatoria aprobada por el equipo
	fixed: {
		currencies: { [string]: number },
		items: { [string]: number },
		eggs: { { pool: string } },
		codex: { string }?,
	}?,
	bibleTable: { OddsRow },
	sources: string,
	status: string,
}

local function rgb(r: number, g: number, b: number): { number }
	return { r, g, b }
end

local Chests: { [string]: ChestDef } = {
	Madera = {
		id = "Madera",
		name = "Cofre de Madera",
		tier = 1,
		color = rgb(150, 104, 64),
		glow = rgb(255, 214, 140),
		activeInBeta = true,
		mode = "Fixed",
		approved = false,
		fixed = {
			currencies = { Monedas = 300 },
			items = { RacionBasica = 2 },
			eggs = { { pool = "Comun" } },
		},
		bibleTable = {
			{ prize = "Huevo Común", percent = 30, status = "Biblia" },
			{ prize = "Huevo Raro", percent = 6, status = "Biblia" },
			{ prize = "Resto del contenido (Monedas, comida…)", percent = nil, status = "Pendiente (Biblia v5)" },
		},
		sources = "Encargos diarios (los tres), primeras victorias de etapa, logros.",
		status = "Activo (contenido fijo)",
	},
	Plata = {
		id = "Plata",
		name = "Cofre de Plata",
		tier = 2,
		color = rgb(176, 188, 204),
		glow = rgb(214, 232, 255),
		activeInBeta = true,
		mode = "Fixed",
		approved = false,
		fixed = {
			currencies = { Monedas = 800 },
			items = { RacionBioma = 1, RacionBasica = 2 },
			eggs = { { pool = "Comun" } },
		},
		bibleTable = {
			{ prize = "Tabla completa", percent = nil, status = "Pendiente (Biblia v5)" },
		},
		sources = "Etapas de Tesoro (garantizado), primeras victorias de etapa, encargo semanal.",
		status = "Activo (contenido fijo)",
	},
	Oro = {
		id = "Oro",
		name = "Cofre de Oro",
		tier = 3,
		color = rgb(236, 184, 64),
		glow = rgb(255, 230, 140),
		activeInBeta = true,
		mode = "Fixed",
		approved = false,
		fixed = {
			currencies = { Monedas = 2000 },
			items = { RacionBioma = 2, Festin = 1 },
			eggs = { { pool = "Raro" } },
		},
		bibleTable = {
			{ prize = "Huevo Épico", percent = 15, status = "Biblia" },
			{ prize = "Resto del contenido", percent = nil, status = "Pendiente (Biblia v5)" },
		},
		sources = "Tres estrellas en todas las etapas de una región.",
		status = "Activo (contenido fijo)",
	},
	Epico = {
		id = "Epico",
		name = "Cofre Épico",
		tier = 4,
		color = rgb(156, 96, 222),
		glow = rgb(214, 170, 255),
		activeInBeta = false,
		mode = "Fixed",
		approved = false,
		fixed = nil,
		bibleTable = { { prize = "Tabla completa", percent = nil, status = "Pendiente (Biblia v5)" } },
		sources = "Arenas y actos posteriores (fuera de la beta).",
		status = "Catálogo (no activo)",
	},
	Diamante = {
		id = "Diamante",
		name = "Cofre Diamante",
		tier = 5,
		color = rgb(140, 230, 240),
		glow = rgb(220, 250, 255),
		activeInBeta = false,
		mode = "Fixed",
		approved = false,
		fixed = nil,
		bibleTable = {
			{ prize = "Tabla redistribuida en la v5", percent = nil, status = "Pendiente (Biblia v5)" },
		},
		sources = "Arena (división Obra Maestra) y temporadas (fuera de la beta).",
		status = "Catálogo (no activo)",
	},
	Nexo = {
		id = "Nexo",
		name = "Cofre Nexo",
		tier = 6,
		color = rgb(255, 196, 96),
		glow = rgb(255, 236, 180),
		activeInBeta = true,
		mode = "Fixed",
		approved = false,
		fixed = {
			currencies = { Monedas = 5000, Gemas = 25 },
			items = { Festin = 2, RacionBioma = 3 },
			eggs = { { pool = "Raro" } },
			codex = { "guardian:copalia" },
		},
		bibleTable = {
			{
				prize = "Ser Sagrado restaurado (una copia por cuenta)",
				percent = nil,
				status = "Pendiente (Biblia v5 y pregunta abierta)",
			},
		},
		sources = "Primera victoria contra un Ser Sagrado (Copalia en el Acto I).",
		status = "Activo (contenido fijo)",
	},
}

return Freeze.deep({
	ById = Chests,
	Order = { "Madera", "Plata", "Oro", "Epico", "Diamante", "Nexo" },
	-- Grupos de huevos de la beta: especies con modelo provisional utilizable, primero las
	-- nativas del Valle Copal. Los otros dos iniciales "vuelven a aparecer" aquí.
	EggPools = {
		Comun = { "barrock", "vainas", "zunzi", "pabilo", "kuachi", "xolumi", "teselo" },
		Raro = { "lumbro", "dienton" },
	},
	-- Historial: cuántas aperturas se recuerdan (HistoryRules guarda el resto)
	MaxStoredChests = 40,
})
